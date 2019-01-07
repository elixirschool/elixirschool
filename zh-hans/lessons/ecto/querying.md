---
version: 1.0.0
title: 查询
---

{% include toc.html %}

本章节，我们将基于[前面课程](./associations)完成的电影分类领域做的 `Example` 应用继续我们的课程和实践。

## 使用 `Ecto.Repo` 来获取记录

在 Ecto 里面，一个 “repository” 对应了一个数据存储空间，比如我们的 Postgres 数据库。所有和此数据库打交道的操作都是经过这个 repository 来实现的。

我们可以通过好一些函数的帮助，直接对 `Example.Repo` 进行数据库查询。

### 通过 ID 获取记录

给定数据记录 ID 的情况下，我们可以使用 `Repo.get/3` 函数来从数据库获取记录。这个函数需要两个参数：一个“可查询”的数据结构，和要从数据获取的记录的 ID。如果 ID 对应的记录存在，它返回的是描述了记录详情的结构体。如果不存在，返回 `nil`。

让我们看看下面利用电影 ID 获取记录 ID 值为 1 的例子：

```elixir
iex> alias Example.{Repo, Movie}
iex> Repo.get(Movie, 1)
%Example.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

可见我们传入 `Repo.get/3` 函数的第一个参数是 `Movie` 模块。`Movie` 是一个“可查询”的，因为它使用了 `Ecto.Schema` 模块并且根据它的数据结构定义了一个 schema。这使得 `Movie` 拥有了 `Ecto.Queryable` 协议。这个协议把数据结构转换成 `Ecto.Query`。Ecto 查询对象的作用就是从 repository 中获取数据。后面会有更多关于查询对象的介绍。

### 根据对象属性值获取记录

我们也可以使用 `Repo.get_by/3` 函数来获取满足一定条件的数据。这个函数需要两个参数：一个“可查询”的数据结构，和我们查询的条件。`Repo.get_by/3` 返回的是单条记录。请看以下例子：

```elixir
iex> alias Example.Repo
iex> alias Example.Movie
iex> Repo.get_by(Movie, title: "Ready Player One")
%Example.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

如果我们需要编写更复杂的查询，或者获得 _所有的_ 满足条件的记录，我们则需要使用 `Ecto.Query` 模块。

## 使用 `Ecto.Query` 编写查询语句

`Ecto.Query` 模块提供了查询 DSL。我们可以使用它来从应用的 repository 查询和获取数据。

### 通过 `Ecto.Query.from/2` 创建查询语句

我们可以使用 `Ecto.Query.from/2` 函数来创建查询。这个函数接收两个参数：一个是表达式，和一个关键字列表。让我们创建一个从 repository 获取所有的电影的查询语句：

```elixir
import Ecto.Query
query = from(m in Movie, select: m)
#Ecto.Query<from m in Example.Movie, select: m>
```

我们可以使用 `Repo.all/2` 函数来执行这个查询语句。这个函数必须接收一个 Ecto 查询语句参数，兵解返回满足查询条件的所有记录。

```elixir
iex> Repo.all(query)

14:58:03.187 [debug] QUERY OK source="movies" db=1.7ms decode=4.2ms
[
  %Example.Movie{
    __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
    actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

#### 使用 `from` 构建关键字查询语句

上面的例子给 `from/2` 传入一个 *关键字查询* 参数来构造查询语句。当使用 `from` 来构造关键字查询语句是，第一个参数可以是以下两种情况的任一种：

* 一个 `in` 表达式（比如：`m in Movie`）  
* 一个实现了 `Ecto.Queryable` 协议的模块（比如：`Movie`）  

第二个参数则是我们的 `select` 关键字查询语句。

#### 使用 `from` 构建查询表达式

当把 `from` 使用于查询表达式的时候，第一个参数必须是实现了 `Ecto.Queryable` 协议的模块（比如：`Movie`）。第二个参数则是一个表达式。让我们来看一个例子：

```elixir
iex> query = select(Movie, [m], m)
#Ecto.Query<from m in Example.Movie, select: m>
iex> Repo.all(query)

06:16:20.854 [debug] QUERY OK source="movies" db=0.9ms
[
  %Example.Movie{
    __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
    actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

我们可以在 _不需要_ 一个 `in` 语句（`m in Movie`）的时候使用查询表达式。当我们不需要使用某个数据结构的引用时，我们可以不使用这个 `in` 语句。我们的查询语句，因为不需要说根据某种特定的条件来选择电影，所以不需要提供一个数据结构的引用。那么，我们就不需要使用 `in` 表达式和关键字查询语句。

### 使用 `select` 表达式

我们使用 `Ecto.Query.select/3` 函数来指定查询语句中的 select 部分。如果我们只想获取其中某些字段，我们可以使用一个原子列表来指定那些字段，或者是引用结构体中的某些键。我们来看看第一种方式：

```elixir
iex> query = from(Movie, select: [:title])                                            
#Ecto.Query<from m in Example.Movie, select: [:title]>
iex> Repo.all(query)

15:15:25.842 [debug] QUERY OK source="movies" db=1.3ms
[
  %Example.Movie{
    __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
    actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: nil,
    tagline: nil,
    title: "Ready Player One"
  }
]
```

请留意，我们并 _没有_ 使用一个 `in` 表达式作为第一个参数传入 `from` 函数。那时因为我们没有在 `select` 中使用关键字列表，所以并不需要为数据结构创建一个引用。

这种方式返回的结构体，只包含了 `title` 键值。

第二种方式的表现行为则有点不同。这次，我们 *确实* 需要使用一个 `in` 表达式。这是因为我们使用了数据结构的引用，来指明电影结构体中的 `title` 键：

```elixir
iex(15)> query = from(m in Movie, select: m.title)   
#Ecto.Query<from m in Example.Movie, select: m.title>
iex(16)> Repo.all(query)                             

15:06:12.752 [debug] QUERY OK source="movies" db=4.5ms queue=0.1ms
["Ready Player One"]
```

不同的是，这种使用 `select` 的方式，返回的是包含了指定值的列表。

### 使用 `where` 表达式

我们可以使用 `where` 表达式来包含查询语句的 “where” 部分。多个 `where` 表达式则会被合成为 `WHERE AND` 的 SQL 语句。

```elixir
iex> query = from(m in Movie, where: m.title == "Ready Player One")                   
#Ecto.Query<from m in Example.Movie, where: m.title == "Ready Player One">
iex> Repo.all(query)

15:18:35.355 [debug] QUERY OK source="movies" db=4.1ms queue=0.1ms
[
  %Example.Movie{
    __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
    actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

我们可以同时使用 `where` 和 `select`：

```elixir
iex> query = from(m in Movie, where: m.title == "Ready Player One", select: m.tagline)
#Ecto.Query<from m in Example.Movie, where: m.title == "Ready Player One", select: m.tagline>
iex> Repo.all(query)

15:19:11.904 [debug] QUERY OK source="movies" db=4.1ms
["Something about video games"]
```

### 在 `where` 中使用插值

为了在 where 语句中使用 Elixir 表达式或者插值，我们需要使用 `^`，或者叫 pin 操作符。它允许我们把一个值 _钉_ 到一个变量上，避免重新绑定。

```elixir
iex> title = "Ready Player One"
"Ready Player One"
iex> query = from(m in Movie, where: m.title == ^title, select: m.tagline)            
#Ecto.Query<from m in Example.Movie, where: m.title == ^"Ready Player One",
 select: m.tagline>
iex> Repo.all(query)

15:21:46.809 [debug] QUERY OK source="movies" db=3.8ms
["Something about video games"]
```

### 获取首条或末尾记录

我们可以使用 `Ecto.Query.first/2` 和 `Ecto.Query.last/2` 函数从 repository 中获取首条或末尾记录。

首先，我们使用 `first/2` 函数来写查询表达式：

```elixir
iex> first(Movie)
#Ecto.Query<from m in Example.Movie, order_by: [desc: m.id], limit: 1>
```

然后我们把这个查询语句传给 `Repo.one/2` 函数来获取结果：

```elixir
iex> Movie |> first() |> Repo.one()

06:36:14.234 [debug] QUERY OK source="movies" db=3.7ms
%Example.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

`Ecto.Query.last/2` 函数的使用方式是一样的：

```elixir
iex> Movie |> last() |> Repo.one()
```

## 查询关联数据

### 预加载

为了访问那些通过 `belongs_to`，`has_many` 和 `has_one` 宏暴露给我们的关联记录，我们需要 _预加载_ 想关联的 schemas。

让我们看看当尝试获取电影想关联的角色时，情况会怎么样：

```elixir
iex> movie = Repo.get(Movie, 1)
iex> movie.actors
#Ecto.Association.NotLoaded<association :actors is not loaded>
```

我们 _无法_ 访问那些关联的角色除非我们预加载它们。有几种不同的使用 Ecto 预加载记录的方式。

#### 使用两条查询语句来预加载

下面的查询语句将使用另一条 _独立的_ 查询语句来预加载相关联的记录。

```elixir
iex> import Ecto.Query
Ecto.Query
iex> Repo.all(from m in Movie, preload: [:actors])
[
  %Example.Movie{
    __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Example.Actor{
        __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Bob"
      },
      %Example.Actor{
        __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
        id: 2,
        movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Gary"
      }
    ],
    characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

我们可以看到，上面的那行代码，运行了 _两条_ 数据库查询语句。一条获取所有的电影，另一条获取了各电影 ID 相关联的所有角色。

#### 使用一条查询语句来预加载

我们可以使用以下方式来减少数据库查询：

```elixir
iex> query = from(m in Movie, join: a in assoc(m, :actors), preload: [actors: a])
iex> Repo.all(query)  
[
  %Example.Movie{
    __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Example.Actor{
        __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Bob"
      },
      %Example.Actor{
        __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
        id: 2,
        movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Gary"
      }
    ],
    characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

这种做法允许我们只执行一次数据调用。它的额外好处就是可以让我们在一条查询语句中选择过滤电影和相关的角色。比如它可以让我们使用 `join` 语句，查询相关角色满足特定条件的某一些电影。比如：

```elixir
Repo.all from m in Movie,
  join: a in assoc(m, :actors),
  where: a.name == "John Wayne"
  preload: [actors: a]
```

后面会有更多关于 join 语句的介绍。

#### 预加载已经查询出来的记录的关联数据

我们还可以预加载那些已经从数据库中查询出来的记录的关联数据。

```elixir
iex> movie = Repo.get(Movie, 1)
%Example.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: #Ecto.Association.NotLoaded<association :actors is not loaded>, # actors are NOT LOADED!!
  characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
iex> movie = Repo.preload(movie, :actors)
%Example.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Example.Actor{
      __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
      id: 1,
      movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Bob"
    },
    %Example.Actor{
      __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
      id: 2,
      movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Gary"
    }
  ], # actors are LOADED!!
  characters: [],
  distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

现在我们就可以从这个电影中获取它的角色了：

```elixir
iex> movie.actors
[
  %Example.Actor{
    __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
    id: 1,
    movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Bob"
  },
  %Example.Actor{
    __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
    id: 2,
    movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Gary"
  }
]
```

### 使用 Join 语句

我们可以通过 `Ecto.Query.join/5` 函数的帮助来执行包含 join 语句的查询。

```elixir
iex> query = from m in Movie,
              join: c in Character,
              on: m.id == c.movie_id,
              where: c.name == "Video Game Guy",
              select: {m.title, c.name}
iex> Repo.all(query)
15:28:23.756 [debug] QUERY OK source="movies" db=5.5ms
[{"Ready Player One", "Video Game Guy"}]
```

`on` 表达式也可以接收一个关键字列表：

```elixir
from m in Movie,
  join: c in Character,
  on: [id: c.movie_id], # keyword list
  where: c.name == "Video Game Guy",
  select: {m.title, c.name}
```

在上面的例子，我们连接了 Ecto schema，`m in Movie`。我们其实也可以连接一个 Ecto 查询语句。假设说我们的电影表格有一个 `stars` 字段。那里保存的是一部电影的“评价”，数字 1 至 5。

```elixir
movies = from m in Movie, where: [stars: 5]
from c in Character,
  join: ^movies,
  on: [id: c.movie_id], # keyword list
  where: c.name == "Video Game Guy",
  select: {m.title, c.name}
```

Ecto 查询语句 DSL 是一个强大的工具。它提供了我们需要的所有用于生成复杂数据库查询语句的东西。通过本次介绍，希望你能具备开始查询的基本知识。
