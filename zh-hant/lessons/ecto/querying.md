---
version: 1.0.2
title: 查詢
---

{% include toc.html %}

在本課程中，將基於 `Example` 應用程式和在 [上一課](./associations) 中設定的電影目錄域來繼續構建。

## 使用 `Ecto.Repo` 提取記錄

回想一下，Ecto 中的 "存放庫" 映射到資料儲存區，例如 Postgres 資料庫。
所有與資料庫的通訊都將使用此存放庫完成。

可以藉助一些函數直接對 `Example.Repo` 執行簡單的查詢。

### 藉由 ID 提取記錄

可以使用 `Repo.get/3` 函數經由給定 ID 從資料庫中提取記錄。此函數需要兩個參數：一個 "可查詢" 的資料結構和要從資料庫中檢索記錄的 ID。如果有的話，它回傳一個描述所找到記錄的結構體。如果沒有找到這樣的記錄，它回傳 `nil`。

來看一個範例吧。下面，將取得 ID 為 1 的電影：

```elixir
iex> alias Example.{Repo, Movie}
iex> Repo.get(Movie, 1)
%Example.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

請注意，給 `Repo.get/3` 的第一個參數是 `Movie` 模組。`Movie` 是 "可查詢" 的，因為該模組使用 `Ecto.Schema` 模組並為其資料結構定義結構描述。這使得 `Movie` 能使用 `Ecto.Queryable` 協定。該協定將資料結構轉換為 `Ecto.Query`。Ecto 查詢是用於從存放庫中檢索資料。之後將有關於查詢的更多資訊。

### 藉由屬性提取記錄

還可以使用 `Repo.get_by/3` 函數提取符合給定條件的記錄。此函數需要兩個參數："可查詢" 的資料結構和要查詢的子句。`Repo.get_by/3` 會從存放庫回傳單一結果。現在來看一個例子：

```elixir
iex> alias Example.Repo
iex> alias Example.Movie
iex> Repo.get_by(Movie, title: "Ready Player One")
%Example.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

如果想編寫更複雜的查詢，或者想要回傳滿足特定條件的 _所有_ 記錄，則需要使用 `Ecto.Query` 模組。

## 使用 `Ecto.Query` 編寫查詢

`Ecto.Query` 模組提供了查詢 DSL，可以用它編寫查詢來從應用程式的存放庫中檢索資料。

### 使用 `Ecto.Query.from/2` 建立查詢

可以使用 `Ecto.Query.from/2` 函數建立一個查詢。此函數包含兩個參數：表達式和關鍵字列表。現在建立一個查詢來從存放庫中選取所有電影：

```elixir
import Ecto.Query
query = from(m in Movie, select: m)
#Ecto.Query<from m in Example.Movie, select: m>
```

使用 `Repo.all/2` 函數執行查詢。此函數接收 Ecto 查詢的必需參數，並回傳滿足查詢條件的所有記錄。

```elixir
iex> Repo.all(query)

14:58:03.187 [debug] QUERY OK source="movies" db=1.7ms decode=4.2ms
[
  %Example.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

#### 使用 `from` 建立關鍵字查詢

上面的範例給了 `from/2` *關鍵字查詢* 一個參數。當使用 `from` 編寫關鍵字查詢時，第一個參數可以是以下兩種情況之一：

* 一個 `in` 表達式 (例如：`m in Movie`)
* 一個實現 `Ecto.Queryable` 協定的模組 (例如：`Movie`)

第二個參數是 `select` 查詢關鍵字。

#### 使用 `from` 建立查詢表達式

當在查詢表達式使用 `from` 時，第一個參數必須是實現 `Ecto.Queryable` 協定的值 (例如：`Movie`)。第二個參數則是表達式。現在來看一個例子：

```elixir
iex> query = select(Movie, [m], m)
#Ecto.Query<from m in Example.Movie, select: m>
iex> Repo.all(query)

06:16:20.854 [debug] QUERY OK source="movies" db=0.9ms
[
  %Example.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

當 _不_ 需要 `in` 陳述式 (`m in Movie`) 時，可以使用查詢表達式。而當不需要資料結構的參考時，則不需要 `in` 陳述式。上面的查詢不需要參考資料結構 - 此例來說，因為不選擇滿足給定條件的電影，所以不需要使用 `in` 表達式和關鍵字查詢。

### 使用 `select` 表達式

使用 `Ecto.Query.select/3` 函數來指定查詢的 select 陳述式部分。如果只想選擇某些欄位，可以將這些欄位指定為 atom 列表或參考結構體的鍵。現在來看看第一種方法：

```elixir
iex> query = from(Movie, select: [:title])
#Ecto.Query<from m in Example.Movie, select: [:title]>
iex> Repo.all(query)

15:15:25.842 [debug] QUERY OK source="movies" db=1.3ms
[
  %Example.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: nil,
    tagline: nil,
    title: "Ready Player One"
  }
]
```

注意到，我們 _沒有_ 使用 `in` 表達式來為 `from` 函數提供第一個參數。這是因為使用 `select` 關鍵字列表不需要建立資料結構的參考。

這種方法回傳的結構體，只有被指定的欄位 `title`。

第二種方法略有不同。這一次，*需要* 使用 `in` 表達式。這是因為需要建立一個資料結構的參考，以指定 movie 結構體的 `title` 鍵：

```elixir
iex(15)> query = from(m in Movie, select: m.title)
#Ecto.Query<from m in Example.Movie, select: m.title>
iex(16)> Repo.all(query)

15:06:12.752 [debug] QUERY OK source="movies" db=4.5ms queue=0.1ms
["Ready Player One"]
```

請注意，這種使用 `select` 的方法會回傳包含所選值的列表。

### 使用 `where` 表達式

可以使用 `where` 表達式在查詢中包含 "where" 子句。多個 `where` 表達式則組合成 `WHERE AND` SQL 陳述式。

```elixir
iex> query = from(m in Movie, where: m.title == "Ready Player One")
#Ecto.Query<from m in Example.Movie, where: m.title == "Ready Player One">
iex> Repo.all(query)

15:18:35.355 [debug] QUERY OK source="movies" db=4.1ms queue=0.1ms
[
  %Example.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

可以將 `where` 表達式與 `select` 一起使用：

```elixir
iex> query = from(m in Movie, where: m.title == "Ready Player One", select: m.tagline)
#Ecto.Query<from m in Example.Movie, where: m.title == "Ready Player One", select: m.tagline>
iex> Repo.all(query)

15:19:11.904 [debug] QUERY OK source="movies" db=4.1ms
["Something about video games"]
```

### 在 `where` 中使用插值

為了在 where 子句中使用插值或 Elixir 表達式，需要使用 `^` 或 pin 運算子。這允許將一個值 _釘_ 在變數上並引用該被固定的值，而不是重新綁定該變數。

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

### 取得第一筆和最後一筆記錄

可以使用 `Ecto.Query.first/2` 和 `Ecto.Query.last/2` 函數從存放庫中提取第一筆或最後一筆記錄。

首先，使用 `first/2` 函數編寫一個查詢表達式：

```elixir
iex> first(Movie)
#Ecto.Query<from m in Example.Movie, order_by: [desc: m.id], limit: 1>
```

然後將查詢傳遞給 `Repo.one/2` 函數以獲得結果：

```elixir
iex> Movie |> first() |> Repo.one()

06:36:14.234 [debug] QUERY OK source="movies" db=3.7ms
%Example.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

`Ecto.Query.last/2` 函數也是以相同的方式使用：

```elixir
iex> Movie |> last() |> Repo.one()
```

## 查詢關聯記錄

### 預載

為了能夠存取 `belongs_to`、`has_many` 和 `has_one` 巨集向我們公開的關聯記錄，需要 _預載_ 關聯結構描述。

現在來看看嘗試對一部電影尋找相關演員時會發生什麼：

```elixir
iex> movie = Repo.get(Movie, 1)
iex> movie.actors
#Ecto.Association.NotLoaded<association :actors is not loaded>
```

_不能_ 存取那些相關的角色，除非預載它們。而使用 Ecto 預載記錄有幾種不同的方法。

#### 使用 2 個查詢來預載

以下查詢將在 _分別的_ 查詢中預載關聯記錄。

```elixir
iex> import Ecto.Query
Ecto.Query
iex> Repo.all(from m in Movie, preload: [:actors])
[
  %Example.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Example.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Bob"
      },
      %Example.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
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

可以看到上面程式碼執行了 _2_ 次資料庫查詢。一次用於所有電影，另一次用於具有給定電影 ID 的所有演員。


#### 使用 1 個查詢預載
可以通過以下方式減少資料庫查詢次數：

```elixir
iex> query = from(m in Movie, join: a in assoc(m, :actors), preload: [actors: a])
iex> Repo.all(query)
[
  %Example.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Example.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Bob"
      },
      %Example.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
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

這允許只執行一次資料庫呼用。它還具有允許在同一查詢中同時選定與過濾電影和其相關演員的額外好處。例如，這種方法允許使用 `join` 陳述式查詢相關演員滿足特定條件的所有電影。就像是：

```elixir
Repo.all from m in Movie,
  join: a in assoc(m, :actors),
  where: a.name == "John Wayne"
  preload: [actors: a]
```

之後將會有 join 陳述式的更多資訊。

#### 預載提取過的記錄

還可以預載已經從資料庫查詢過記錄的關聯結構描述。

```elixir
iex> movie = Repo.get(Movie, 1)
%Example.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: #Ecto.Association.NotLoaded<association :actors is not loaded>, # actors are NOT LOADED!!
  characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
iex> movie = Repo.preload(movie, :actors)
%Example.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Example.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
      id: 1,
      movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Bob"
    },
    %Example.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
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

現在可以請求關於一部電影的演員：

```elixir
iex> movie.actors
[
  %Example.Actor{
    __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
    id: 1,
    movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Bob"
  },
  %Example.Actor{
    __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
    id: 2,
    movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Gary"
  }
]
```

### 使用 Join 陳述式

可以在 `Ecto.Query.join/5` 函數幫助下執行包含 join 陳述式的查詢。

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

`on` 表達式也可以使用關鍵字列表：

```elixir
from m in Movie,
  join: c in Character,
  on: [id: c.movie_id], # keyword list
  where: c.name == "Video Game Guy",
  select: {m.title, c.name}
```

在上面的例子中，join 了一個 Ecto 結構描述，`m in Movie`。也可以 join Ecto 查詢。假設電影表格中有一欄 `stars`，它儲存電影的 "星級"，數字從 1-5。

```elixir
movies = from m in Movie, where: [stars: 5]
from c in Character,
  join: ^movies,
  on: [id: c.movie_id], # keyword list
  where: c.name == "Video Game Guy",
  select: {m.title, c.name}
```

Ecto Query DSL 是一個功能強大的工具，它提供了進行複雜資料庫查詢所需的一切。而通過此介紹則希望給了你開始查詢的基本知識。