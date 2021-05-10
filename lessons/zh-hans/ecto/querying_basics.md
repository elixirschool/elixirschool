%{
  version: "1.2.0",
  title: "查询",
  excerpt: """
  
  """
}
---

本章节，我们将基于[前面课程](./associations)完成的电影分类领域做的 `Friends` 应用继续我们的课程和实践。

## 使用 Ecto.Repo 来获取记录

在 Ecto 里面，一个 “repository” 对应了一个数据存储空间，比如我们的 Postgres 数据库。所有和此数据库打交道的操作都是经过这个 repository 来实现的。

我们可以通过好一些函数的帮助，直接对 `Friends.Repo` 进行数据库查询。

### 通过 ID 获取记录

给定数据记录 ID 的情况下，我们可以使用 `Repo.get/3` 函数来从数据库获取记录。这个函数需要两个参数：一个“可查询”的数据结构，和要从数据获取的记录的 ID。如果 ID 对应的记录存在，它返回的是描述了记录详情的结构体。如果不存在，返回 `nil`。

让我们看看下面利用电影 ID 获取记录 ID 值为 1 的例子：

```elixir
iex> alias Friends.{Repo, Movie}
iex> Repo.get(Movie, 1)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

可见我们传入 `Repo.get/3` 函数的第一个参数是 `Movie` 模块。`Movie` 是一个“可查询”的，因为它使用了 `Ecto.Schema` 模块并且根据它的数据结构定义了一个 schema。这使得 `Movie` 拥有了 `Ecto.Queryable` 协议。这个协议把数据结构转换成 `Ecto.Query`。Ecto 查询对象的作用就是从 repository 中获取数据。后面会有更多关于查询对象的介绍。

### 根据对象属性值获取记录

我们也可以使用 `Repo.get_by/3` 函数来获取满足一定条件的数据。这个函数需要两个参数：一个“可查询”的数据结构，和我们查询的条件。`Repo.get_by/3` 返回的是单条记录。请看以下例子：

```elixir
iex> Repo.get_by(Movie, title: "Ready Player One")
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

如果我们需要编写更复杂的查询，或者获得 _所有的_ 满足条件的记录，我们则需要使用 `Ecto.Query` 模块。

## 使用 Ecto.Query 编写查询语句

`Ecto.Query` 模块提供了查询 DSL。我们可以使用它来从应用的 repository 查询和获取数据。

### 通过 Ecto.Query.from/2 创建基于关键字的查询语句

我们可以使用 `Ecto.Query.from/2` 宏来创建查询。这个函数接收两个参数：一个是表达式，和可选的一个关键字列表。让我们创建一个最简单的从 repository 获取所有的电影的查询语句：

```elixir
iex> import Ecto.Query
iex> query = from(Movie)
#Ecto.Query<from m0 in Friends.Movie>
```

我们可以使用 `Repo.all/2` 函数来执行这个查询语句。这个函数必须接收一个 Ecto 查询语句参数，兵解返回满足查询条件的所有记录。

```elixir
iex> Repo.all(query)

14:58:03.187 [debug] QUERY OK source="movies" db=1.7ms decode=4.2ms
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

#### 使用 from 的简单无绑定查询

上面的样例丧失了 SQL 语句最有趣的部分。我们通常纸箱查询某几个特定的字段，或者根据一些条件来过滤数据。当我们希望只获取标题为 `"Ready Player One"` 的所有电影的 `title` 和 `tagline` 字段时：

```elixir
iex> query = from(Movie, where: [title: "Ready Player One"], select: [:title, :tagline])
#Ecto.Query<from m0 in Friends.Movie, where: m0.title == "Ready Player One",
 select: [:title, :tagline]>

iex> Repo.all(query)                                                                    
SELECT m0."title", m0."tagline" FROM "movies" AS m0 WHERE (m0."title" = 'Ready Player One') []
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    id: nil,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

请注意到返回的结构体只包含 `tagline` 和 `title` - 这是通过 `select:` 部分设置的结果。

以上那些查询被称为 *无绑定（bindingless）*，它们足够简单。

#### 查询的绑定

目前为止，我们通过使用一个实现了 `Ecto.Queryable` 协议（比如：`Movie`）的模块来作为 `from` 宏的第一个参数。但是，我们也可以使用 `in` 表达式：

```elixir
iex> query = from(m in Movie)                                                           
#Ecto.Query<from m0 in Friends.Movie>
```

这样的情况，我们把 `m` 称为一个 *绑定（binding）*。绑定非常有用，因为它们允许我们在查询的其它部分中引用这些模块。当我们想找出所有 `id` 小于 `2` 的电影的标题时：

```elixir
iex> query = from(m in Movie, where: m.id < 2, select: m.title)
#Ecto.Query<from m0 in Friends.Movie, where: m0.id < 2, select: m0.title>

iex> Repo.all(query)                                           
SELECT m0."title" FROM "movies" AS m0 WHERE (m0."id" < 2) []
["Ready Player One"]
```

在这里，最重要的一点就是，查询语句的输出是如何改变的。通过在 `select:` 部分使用绑定和*表达式*，我们可以精确指定要返回字段的结构。比如说，我们想返回一个元组：

```elixir
iex> query = from(m in Movie, where: m.id < 2, select: {m.title})             

iex> Repo.all(query)                                                          
[{"Ready Player One"}]
```

比较好的做法是，通过简单的无绑定查询开始，等需要引用你的数据结构时，再引入绑定的用法。对于查询中的绑定使用方法，可参见 [Ecto 文档](https://hexdocs.pm/ecto/Ecto.Query.html#module-query-expressions)


### 基于宏的查询

上面的例子里，我们使用的是在 `from` 宏里面添加 `select:` 和 `where:` 关键字来打造查询语句 - 这些也被称为*基于关键字的查询语句*。但是，还有另一种组装查询语句的方式 - 基于宏的查询语句。Ecto 为每一个关键字都提供了宏，比如 `select/3` 或者 `where/3`。每一个宏都接收一个 *queryable* 值，一个*显式声明的绑定列表*，和提供给关键字查询语句类似的表达式：

```elixir
iex> query = select(Movie, [m], m.title)                           
#Ecto.Query<from m0 in Friends.Movie, select: m0.title>

iex> Repo.all(query)                    
SELECT m0."title" FROM "movies" AS m0 []
["Ready Player One"]
```

使用宏的一个好处就是可以很好的结合管道来使用：

```elixir
iex> Movie
     |> where([m], m.id < 2)
     |> select([m], {m.title})
     |> Repo.all

[{"Ready Player One"}]
```

注意，如果要在换行符之后继续输入，请使用 `\`

### 使用 where 表达式

我们可以使用 `where` 表达式来包含查询语句的 “where” 部分。多个 `where` 表达式则会被合成为 `WHERE AND` 的 SQL 语句。

```elixir
iex> query = from(m in Movie, where: m.title == "Ready Player One")                   
%Ecto.Query<from m in Friends.Movie, where: m.title == "Ready Player One">
iex> Repo.all(query)

15:18:35.355 [debug] QUERY OK source="movies" db=4.1ms queue=0.1ms
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

我们可以同时使用 `where` 和 `select`：

```elixir
iex> query = from(m in Movie, where: m.title == "Ready Player One", select: m.tagline)
%Ecto.Query<from m in Friends.Movie, where: m.title == "Ready Player One", select: m.tagline>
iex> Repo.all(query)

15:19:11.904 [debug] QUERY OK source="movies" db=4.1ms
["Something about video games"]
```

### 在 where 中使用插值

为了在 where 语句中使用 Elixir 表达式或者插值，我们需要使用 `^`，或者叫 pin 操作符。它允许我们把一个值 _钉_ 到一个变量上，避免重新绑定。

```elixir
iex> title = "Ready Player One"
"Ready Player One"
iex> query = from(m in Movie, where: m.title == ^title, select: m.tagline)            
%Ecto.Query<from m in Friends.Movie, where: m.title == ^"Ready Player One",
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
#Ecto.Query<from m0 in Friends.Movie, order_by: [asc: m0.id], limit: 1>
```

然后我们把这个查询语句传给 `Repo.one/2` 函数来获取结果：

```elixir
iex> Movie |> first() |> Repo.one()

SELECT m0."id", m0."title", m0."tagline" FROM "movies" AS m0 ORDER BY m0."id" LIMIT 1 []
%Friends.Movie{
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
%Ecto.Association.NotLoaded<association :actors is not loaded>
```

我们 _无法_ 访问那些关联的角色除非我们预加载它们。有几种不同的使用 Ecto 预加载记录的方式。

#### 使用两条查询语句来预加载

下面的查询语句将使用另一条 _独立的_ 查询语句来预加载相关联的记录。

```elixir
iex> import Ecto.Query
Ecto.Query
iex> Repo.all(from m in Movie, preload: [:actors])
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Tyler Sheridan"
      },
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 2,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Gary"
      }
    ],
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
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
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Tyler Sheridan"
      },
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 2,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Gary"
      }
    ],
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
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
  where: a.name == "John Wayne",
  preload: [actors: a]
```

后面会有更多关于 join 语句的介绍。

#### 预加载已经查询出来的记录的关联数据

我们还可以预加载那些已经从数据库中查询出来的记录的关联数据。

```elixir
iex> movie = Repo.get(Movie, 1)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>, # actors are NOT LOADED!!
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
iex> movie = Repo.preload(movie, :actors)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Friends.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
      id: 1,
      movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Tyler Sheridan"
    },
    %Friends.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
      id: 2,
      movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Gary"
    }
  ], # actors are LOADED!!
  characters: [],
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

现在我们就可以从这个电影中获取它的角色了：

```elixir
iex> movie.actors
[
  %Friends.Actor{
    __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
    id: 1,
    movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Tyler Sheridan"
  },
  %Friends.Actor{
    __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
    id: 2,
    movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Gary"
  }
]
```

### 使用 Join 语句

我们可以通过 `Ecto.Query.join/5` 函数的帮助来执行包含 join 语句的查询。

```elixir
iex> alias Friends.Character
iex> query = from m in Movie,
              join: c in Character,
              on: m.id == c.movie_id,
              where: c.name == "Wade Watts",
              select: {m.title, c.name}
iex> Repo.all(query)
15:28:23.756 [debug] QUERY OK source="movies" db=5.5ms
[{"Ready Player One", "Wade Watts"}]
```

`on` 表达式也可以接收一个关键字列表：

```elixir
from m in Movie,
  join: c in Character,
  on: [id: c.movie_id], # keyword list
  where: c.name == "Wade Watts",
  select: {m.title, c.name}
```

在上面的例子，我们连接了 Ecto schema，`m in Movie`。我们其实也可以连接一个 Ecto 查询语句。假设说我们的电影表格有一个 `stars` 字段。那里保存的是一部电影的“评价”，数字 1 至 5。

```elixir
movies = from m in Movie, where: [stars: 5]
from c in Character,
  join: ^movies,
  on: [id: c.movie_id], # keyword list
  where: c.name == "Wade Watts",
  select: {m.title, c.name}
```

Ecto 查询语句 DSL 是一个强大的工具。它提供了我们需要的所有用于生成复杂数据库查询语句的东西。通过本次介绍，希望你能具备开始查询的基本知识。
