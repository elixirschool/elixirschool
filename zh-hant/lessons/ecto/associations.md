---
version: 1.2.1
title: 關聯關係
---

在本章節中，將學習如何使用 Ecto 來定義和處理結構描述(schema)之間的關聯關係。

{% include toc.html %}

## 設定

將從上一課的 `Friends` 應用程式開始。 可以參考 [這裡](../basics) 的設定來快速復習。

## 關聯關係的種類

可以在結構描述之間定義三種類型的關聯關係。接著將看看它們是什麼以及如何實現每種類型的關係。

### 屬於/一對多 (Belongs To/Has Many)

將在範例應用程式的域(domain)模型中加入一些新實體，以便可以為喜愛的電影編制目錄。會從兩個結構描述開始：`Movie` 和 `Character`。將實現這兩種結構描述之間的 "屬於/一對多" 關係：一部電影有很多角色，而一個角色屬於一部電影。

#### 一對多 Migration

現在替 `Movie` 產生成一個 migration：

```console
mix ecto.gen.migration create_movies
```

打開新產生的 migration 檔案並定義 `change` 函數以建立帶有一些屬性的 `movies` 表格：

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

#### 一對多 Schema

現在將加入一個結構描述，指定電影及其角色之間的 "一對多" 關係。

```elixir
# lib/example/movie.ex
defmodule Friends.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Friends.Character
  end
end
```

`has_many/3` 巨集不會向資料庫本身加入任何內容。它的作用是使用關聯結構描述上的外鍵 `characters` 來使一部電影的相關角色可用。這將允許呼用 `movie.characters`。

#### 屬於 Migration

現在準備建立 `Character` 的 migration 和結構描述。一個角色屬於一部電影，因此將定義具體指定此關係的 migration 和結構描述。

首先，產生 migration：

```console
mix ecto.gen.migration create_characters
```

要聲明一個角色屬於一個電影，需要 `characters` 表格中有一個 `movie_id` 欄。我們希望此欄函數用作外鍵。可以使用以下這行再 `create table/1` 函數中完成此操作：

```elixir
add :movie_id, references(:movies)
```
所以我們的 migration 應該如下所示：

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

#### 屬於 Schema

我們的結構描述同樣需要定義角色與其電影之間的 "屬於" 關係。

```elixir
# lib/example/character.ex

defmodule Friends.Character do
  use Ecto.Schema

  schema "characters" do
    field :name, :string
    belongs_to :movie, Friends.Movie
  end
end
```

現在仔細看看 `belongs_to/3` 巨集做了些什麼。除了將外鍵 `movie_id` 加入到結構描述之外，它還使我們能夠 _通過_ `characters` 存取關聯的 `movies` 結構描述。當查詢角色時，它使用外鍵讓角色的關聯電影可用。這將允許我們呼用 `character.movie`。 

現在準備好執行 migrations：

```console
mix ecto.migrate
```

### 屬於/一對一 (Belongs To/Has One)

比方說一部電影有一個發行商，例如 Netflix 是原創電影 "Bright" 的發行商。

現在將使用 "屬於" 關係定義 `Distributor` migration 和結構描述。首先，來產生 migration：

```console
mix ecto.gen.migration create_distributors
```

現在應該將 `movie_id` 的外鍵加入到剛產生的 `distributors` 表格 migration 中，並加入唯一索引以強制一部電影只有一個發行商：

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

`Distributor` 結構描述應該使用 `belongs_to/3` 巨集來允許我們呼用 `distributor.movie` 並使用這個外鍵查找發行商關聯的電影。

```elixir
# lib/example/distributor.ex

defmodule Friends.Distributor do
  use Ecto.Schema

  schema "distributors" do
    field :name, :string
    belongs_to :movie, Friends.Movie
  end
end
```

接下來，將為 `Movie` 結構描述加入 "一對一" 關係：

```elixir
# lib/example/movie.ex

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

`has_one/3` 巨集函數就像 `has_many/3` 巨集一樣。它使用關聯的結構描述外鍵來查找並公開(expose)電影的發行商。這將允許呼用 `movie.distributor`。

現在已準備好執行 migrations：

```console
mix ecto.migrate
```

### 多對多 (Many To Many)

假定一部電影有很多演員，一個演員可以屬於不止一部電影。現在將構建一個參考 movies _和_ actors 這 _兩者_ 的連接(join)表格來實現這種關係。

首先，現在產生 `Actors` migration：

```console
mix ecto.gen.migration create_actors
```

接著定義這個 migration：

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

現在產生所需的連接表格 migration：

```console
mix ecto.gen.migration create_movies_actors
```

現在將定義 migration，使表格具有兩個外鍵。接著還將加入一個唯一的索引來強制 actors 和 movies 的唯一配對：

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

接下來，將 `many_to_many` 巨集加入到 `Movie` 結構描述中：

```elixir
# lib/example/movie.ex

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

最後，使用相同的 `many_to_many` 巨集定義 `Actor` 結構描述。

```elixir
# lib/example/actor.ex

defmodule Friends.Actor do
  use Ecto.Schema

  schema "actors" do
    field :name, :string
    many_to_many :movies, Friends.Movie, join_through: "movies_actors"
  end
end
```

現在已經準備好執行 migrations：

```console
mix ecto.migrate
```

## 儲存關聯資料

儲存記錄及其關聯資料的方式取決於記錄之間關係的性質。現在從 "屬於/一對多" 的關係開始吧。

### 屬於 (Belongs To)

#### 經由 `Ecto.build_assoc/3` 儲存

對於 "屬於" 關係，可以利用 Ecto 的 `build_assoc/3` 函數。

[`build_assoc/3`](https://hexdocs.pm/ecto/Ecto.html#build_assoc/3) 接收三個參數：

* 想要儲存記錄的結構體。
* 關聯關係的名稱。
* 指定給要儲存關聯記錄的任何屬性。

現在來儲存一部電影和一個相關角色。首先，建立一個電影記錄：

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

現在將建立關聯角色並將其插入資料庫：

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

請注意，由於 `Movie` 結構描述的 `has_many/3` 巨集指定了一個電影有很多 `:characters`，那作為第二個參數傳遞給 `build_assoc/3` 的關聯名稱就是： `:characters`。可以看到已經建立了一個角色，其 `movie_id` 被正確設定為關聯電影的 ID。

為了使用 `build_assoc/3` 來儲存電影的關聯發行商，我們採用相同的方法將電影和發行商關係的 _名稱_ 作為第二個參數傳遞給 `build_assoc/3`：

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

### 多對多 (Many to Many)

#### 經由 `Ecto.Changeset.put_assoc/4` 儲存

`build_assoc/3` 方法對多對多關係不起作用。這是因為 movie 和 actor 表格都沒有包含外鍵。作為替代，需要利用 Ecto 變更集 和 `put_assoc/4` 函數。

假設已經有了上面建立的 movie 記錄，那麼現在來建立一個 actor 記錄：

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

現在已準備好經由連接表格將電影與演員關聯起來。

首先，請注意，為了使用變更集，需要確保 `movie` 結構預先載入了關聯資料。很快將詳細介紹預載資料。但目前，讓我們了解可以像這樣預載關聯就夠了：

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

接下來，將為電影記錄建立一個變更集：

```elixir
iex> movie_changeset = Ecto.Changeset.change(movie)
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Movie<>,
 valid?: true>
```

現在將把變更集作為第一個參數傳遞給 [`Ecto.Changeset.put_assoc/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#put_assoc/4)：

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

這提供了一個表示以下更改的 _新_ 變更集：將此演員列表中的演員加入到指定的電影記錄中。

最後，將使用最新的變更集更新指定的電影和演員記錄：

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

可以看到，這給了我們一個有新的 actor 正確關聯的電影記錄，並已經在 `movie.actors` 中預載。

可以使用相同的方法來建立與指定電影相關聯的全新演員。不必將 _已儲存_ 的 actor 結構體傳遞給`put_assoc/4`，只要傳入一個描述想建立新 actor 的 actor 結構體：

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

可以看到建立了一個 ID 為 "2" 的新 actor 和所賦予它的屬性。

在下一章節中，將學習如何查詢關聯記錄。