---
version: 1.2.1
title: 关联关系
---

本课程我们将学习如何使用 Ecto 来定义和使用 schema 之间的关联关系。

{% include toc.html %}

## 配置

我们将基于前面课程搭建的 app, `Friends`，来操作。你可以通过[这里](../basics)来回顾一下。

## 关联的种类

Schema 之间的关联关系有三种。我们将逐个来看他们是什么，并如何实现。

### 属于/一对多

我们需要先往我们的示范项目里添加一些新的模型实例，让我们可以对心爱的电影进行分类。我们先创建两个新的 schemas：`Movie` 和 `Character`。我们先实现这两个 schemas 之间的“属于/一对多”的关系：一部电影拥有多个角色，和一个角色属于一部电影“。

#### “一对多”的 Migration

让我们先创建 `Movie` 的 migration：

```console
mix ecto.gen.migration create_movies
```

打开新创建的 migration 文件，然后定义 `change` 函数来创建 `movies` 表单：

```elixir
# priv/repo/migrations/*_create_movies.exs
defmodule Friends.Repo.Migrations.CreateMovies do
  use Ecto.Migration

  def change do
    create table(:movies) do
      add :title, :string
      add :tagline, :string
    end
  end
end
```

#### “一对多”的 Schema

然后我们添加指定电影和角色之间的“一对多”关系的 schema。

```elixir
# lib/friends/movie.ex
defmodule Friends.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Friends.Character
  end
end
```

`has_many/3` 宏并不会在数据库添加任何东西。它只是用外键关联到相关的 `characters` schema 上，使得一部电影可以获取相应的角色。这就能让我们通过调用 `movie.characters` 来获取相应的数据。

#### “属于”的 Migration

现在，我们就可以打造 `Character` 的 migration 和 schema 了。一个角色属于一部电影，所以我们要相应的 migration 和 schema 来定义这个关系。

首先，我们创建 migration：

```console
mix ecto.gen.migration create_characters
```

为了指明一个角色属于一部电影，我们需要 `characters` 表有一个 `movie_id` 字段。我们希望这个字段作为外键来使用。我们可以通过添加下面一行代码到 `create table/1` 函数来实现：

```elixir
add :movie_id, references(:movies)
```

所以，相应的 migration 应该是这个样子：

```elixir
# priv/migrations/*_create_characters.exs
defmodule Friends.Repo.Migrations.CreateCharacters do
  use Ecto.Migration

  def change do
    create table(:characters) do
      add :name, :string
      add :movie_id, references(:movies)
    end
  end
end
```

#### “属于”的 Schema

我们的 schema 也要相应的定义角色“属于”它的电影的关系。

```elixir
# lib/friends/character.ex

defmodule Friends.Character do
  use Ecto.Schema

  schema "characters" do
    field :name, :string
    belongs_to :movie, Friends.Movie
  end
end
```

让我们仔细看看 `belongs_to/3` 这个宏为我们做了什么。和在 `characters` 表添加 `movie_id` 字段不同，这个宏 _并不会_ 往数据库添加任何东西。它 _只是_ 让我们可以 _通过_ `characters` 来访问关联的 `movies` schema。它利用 `characters` 上面的 `movie_id` 外键，可使得角色相关的电影能在查询的同时可访问。效果就是允许我们调用 `character.movie`。

现在我们就可以运行 migration 命令了：

```console
mix ecto.migrate
```

### 属于/一对一

比如说，一部电影有一个分销商。例如，Netflix 是它们的原创电影“Bright”的分销商。

我们下面来定义 `Distributor` migration 和 schema 以及“一对一”的关系。首先，让我们来生成 migration：

```console
mix ecto.gen.migration create_distributors
```

这个 migration 需要添加一个外键 `movie_id` 到 `distributors` 表里面。同时，再添加一个唯一索引来确保一部电影只有一个发行商。

```elixir
# priv/repo/migrations/*_create_distributors.exs

defmodule Friends.Repo.Migrations.CreateDistributors do
  use Ecto.Migration

  def change do
    create table(:distributors) do
      add :name, :string
      add :movie_id, references(:movies)
    end

    create unique_index(:distributors, [:movie_id])
  end
end
```

然后 `Distributor` schema 应该使用 `belongs_to/3` 宏来使得我们可以调用 `distributor.movie` 来通过外键查找相应的分销商。

```elixir
# lib/friends/distributor.ex

defmodule Friends.Distributor do
  use Ecto.Schema

  schema "distributors" do
    field :name, :string
    belongs_to :movie, Friends.Movie
  end
end
```

接着，我们就可以把“一对一”关系添加到 `Movie` schema：

```elixir
# lib/friends/movie.ex

defmodule Friends.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Friends.Character
    has_one :distributor, Friends.Distributor # I'm new!
  end
end
```

`has_one/3` 宏和 `has_many/3` 宏一样。它不会在数据库添加任何东西，它 _只_ 使用了 schema 中相应的外键来查找电影的分销商。这就使得我们可以调用 `movie.distributor` 来获取数据。

我们现在就可以运行 migration 了：

```console
mix ecto.migrate
```

### 多对多

一部电影可以有多个演员，一个演员可以出演多部电影。我们建立一个关联表来把 movies _和_ actors 两个表关联起来实现这个关系。

首先，让我们生成 `Actors` migration：

```console
mix ecto.gen.migration create_actors
```

定义 migration 内容：

```elixir
# priv/migrations/*_create_actors.ex

defmodule Friends.Repo.Migrations.Actors do
  use Ecto.Migration

  def change do
    create table(:actors) do
      add :name, :string
    end
  end
end
```

让我们来生成关联表的 migration：

```console
mix ecto.gen.migration create_movies_actors
```

我们将定义的 migration 会拥有两个外键。我们还要添加一个唯一索引来加强演员和电影之间的唯一性：

```elixir
# priv/migrations/*_create_movies_actors.ex

defmodule Friends.Repo.Migrations.CreateMoviesActors do
  use Ecto.Migration

  def change do
    create table(:movies_actors) do
      add :movie_id, references(:movies)
      add :actor_id, references(:actors)
    end

    create unique_index(:movies_actors, [:movie_id, :actor_id])
  end
end
```

接着，添加一个 `many_to_many` 宏到 `Movie` schema：

```elixir
# lib/friends/movie.ex

defmodule Friends.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Friends.Character
    has_one :distributor, Friends.Distributor
    many_to_many :actors, Friends.Actor, join_through: "movies_actors" # I'm new!
  end
end
```

最后，使用同样的 `many_to_many` 宏来定义我们的 `Actor` schema。

```elixir
# lib/friends/actor.ex

defmodule Friends.Actor do
  use Ecto.Schema

  schema "actors" do
    field :name, :string
    many_to_many :movies, Friends.Movie, join_through: "movies_actors"
  end
end
```

可以运行 migration 了：

```console
mix ecto.migrate
```

## 保存关联数据

我们保存数据及其关联关系的方式，依赖于数据之间的关系的特性。我们先来看看“属于/一对多”的关系。

### “属于”

#### 通过 `Ecto.build_assoc/3` 来保存

对于"属于"这种关系，我们可以通过 Ecto 的 `build_assoc/3` 函数来处理。

[`build_assoc/3`](https://hexdocs.pm/ecto/Ecto.html#build_assoc/3) 接收三个参数：

* 需要保存的数据的结构体  
* 关系的名字  
* 其它需要保存，并赋值的关系记录属性  

我们来保存一个电影和相关的角色：

首先，我们要创建一个电影记录：

```elixir
iex> alias Friends.{Movie, Character, Repo}
iex> movie = %Movie{title: "Ready Player One", tagline: "Something about video games"}

%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:built, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: nil,
  tagline: "Something about video games",
  title: "Ready Player One"
}

iex> movie = Repo.insert!(movie)
```

现在我们要创建相关的角色和保存到数据库里：

```elixir
character = Ecto.build_assoc(movie, :characters, %{name: "Wade Watts"})
%Friends.Character{
  __meta__: %Ecto.Schema.Metadata<:built, "characters">,
  id: nil,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Wade Watts"
}
Repo.insert!(character)
%Friends.Character{
  __meta__: %Ecto.Schema.Metadata<:loaded, "characters">,
  id: 1,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Wade Watts"
}
```

要注意的是，因为 `Movie` schema 中的 `has_many/3` 宏指定了一部电影拥有多个 `:characters`，我们通过第二个参数传到 `build_assoc/3` 的关系的名字，就是 `:characters`。这样，我们就创建了一个把相应的电影 ID 设置到了 `movie_id` 的角色。

为了使用 `build_assoc/3` 来保存电影相应的分销商，我们用同样的方式，传入电影和分销商的关系 _名称_ 作为 `build_assoc/3` 的第二个参数：

```elixir
iex> distributor = Ecto.build_assoc(movie, :distributor, %{name: "Netflix"})       
%Friends.Distributor{
  __meta__: %Ecto.Schema.Metadata<:built, "distributors">,
  id: nil,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Netflix"
}
iex> Repo.insert!(distributor)
%Friends.Distributor{
  __meta__: %Ecto.Schema.Metadata<:loaded, "distributors">,
  id: 1,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Netflix"
}
```

### 多对多

#### 通过 `Ecto.Changeset.put_assoc/4` 来保存

`build_assoc/3` 的做法是不能用在多对多关系的处理上面的。因为 movie 或者 actor 表本身都不包含相应的外键。我们需要使用 Ecto Changesets 和 `put_assoc/4` 函数来处理。

假定我们已经有了相应的 movie 记录，现在我们来创建 actor 记录：

```elixir
iex> alias Friends.Actor
iex> actor = %Actor{name: "Tyler Sheridan"}
%Friends.Actor{
  __meta__: %Ecto.Schema.Metadata<:built, "actors">,
  id: nil,
  movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
  name: "Tyler Sheridan"
}
iex> actor = Repo.insert!(actor)
%Friends.Actor{
  __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
  id: 1,
  movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
  name: "Tyler Sheridan"
}
```

现在我们已经为通过关联表来关联电影和角色做好准备了。

首先，为了创建 Changesets，我们需要确保 `movie` 记录已经预先加载了关联的 schemas。很快我们就会进一步解释预加载数据。现在，我们只要知道以下代码能够这么做就行了：

```elixir
iex> movie = Repo.preload(movie, [:distributor, :characters, :actors])
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [],
  characters: [],
  distributor: nil,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

然后，我们创建一个电影记录的 changeset：

```elixir
iex> movie_changeset = Ecto.Changeset.change(movie)                                                    
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Movie<>,
 valid?: true>
```

现在我们可以把 changeset 作为第一个参数传入 [`Ecto.Changeset.put_assoc/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#put_assoc/4)：

```elixir
iex> movie_actors_changeset = movie_changeset |> Ecto.Changeset.put_assoc(:actors, [actor])
%Ecto.Changeset<
  action: nil,
  changes: %{
    actors: [
      %Ecto.Changeset<action: :update, changes: %{}, errors: [],
       data: %Friends.Actor<>, valid?: true>
    ]
  },
  errors: [],
  data: %Friends.Movie<>,
  valid?: true
>
```

我们这样就得到了一个 _新的_ changeset。它代表了这个变更：把角色加入到指定 movie 记录的角色列表。

最后，我们通过这个 changeset 来更新指定的 movie 和 actor 记录：

```elixir
iex> Repo.update!(movie_actors_changeset)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Friends.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
      id: 1,
      movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Bob"
    }
  ],
  characters: [],
  distributor: nil,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

我们可以发现，这使得我们的 movie 记录包含了关联上的新的 actor 数据，并预加载的 `movie.actors` 里面。

我们可以使用同样的方式来创建一个新的角色，关联到电影里面。与其传入一个 _保存过的_ 角色结构体到 `put_assoc/4` 里，我们可以传入一个想创建的新角色结构体就行了：

```elixir
iex> changeset = movie_changeset |> Ecto.Changeset.put_assoc(:actors, [%{name: "Gary"}])                      
%Ecto.Changeset<
  action: nil,
  changes: %{
    actors: [
      %Ecto.Changeset<
        action: :insert,
        changes: %{name: "Gary"},
        errors: [],
        data: %Friends.Actor<>,
        valid?: true
      >
    ]
  },
  errors: [],
  data: %Friends.Movie<>,
  valid?: true
>
iex>  Repo.update!(changeset)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Friends.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
      id: 2,
      movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Gary"
    }
  ],
  characters: [],
  distributor: nil,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

一个 ID 为 “2”，连同指定属性的新角色，就这样被创建出来了。

下一章，我们将学习如何查找相关联的记录。
