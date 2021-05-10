%{
  version: "1.1.1",
  title: "查詢",
  excerpt: """
  
  """
}
---

在本課程中，將基於 `Friends` 應用程式和在 [上一課](./associations) 中設定的電影目錄域來繼續構建。

## 使用 Ecto.Repo 提取記錄

回想一下，Ecto 中的 "存放庫" 映射到資料儲存區，例如 Postgres 資料庫。
所有與資料庫的通訊都將使用此存放庫完成。

可以藉助一些函數直接對 `Friends.Repo` 執行簡單的查詢。

### 藉由 ID 提取記錄

可以使用 `Repo.get/3` 函數經由給定 ID 從資料庫中提取記錄。此函數需要兩個參數：一個 "可查詢" 的資料結構和要從資料庫中檢索記錄的 ID。如果有的話，它回傳一個描述所找到記錄的結構體。如果沒有找到這樣的記錄，它回傳 `nil`。

來看一個範例吧。下面，將取得 ID 為 1 的電影：

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

請注意，給 `Repo.get/3` 的第一個參數是 `Movie` 模組。`Movie` 是 "可查詢" 的，因為該模組使用 `Ecto.Schema` 模組並為其資料結構定義結構描述。這使得 `Movie` 能使用 `Ecto.Queryable` 協定。該協定將資料結構轉換為 `Ecto.Query`。Ecto 查詢是用於從存放庫中檢索資料。之後將有關於查詢的更多資訊。

### 藉由屬性提取記錄

還可以使用 `Repo.get_by/3` 函數提取符合給定條件的記錄。此函數需要兩個參數："可查詢" 的資料結構和要查詢的子句。`Repo.get_by/3` 會從存放庫回傳單一結果。現在來看一個例子：

```elixir
iex> alias Friends.Repo
iex> alias Friends.Movie
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

如果想編寫更複雜的查詢，或者想要回傳滿足特定條件的 _所有_ 記錄，則需要使用 `Ecto.Query` 模組。

## 使用 Ecto.Query 編寫查詢

`Ecto.Query` 模組提供了查詢 DSL，可以用它編寫查詢來從應用程式的存放庫中檢索資料。

### 使用 Ecto.Query.from/2 進行基於關鍵字查詢

可以使用 `Ecto.Query.from/2` 巨集建立一個查詢。此函數包含兩個參數：表達式和一個可選的關鍵字列表。現在建立一個最簡易的查詢來從存放庫中選取所有電影：

```elixir
iex> import Ecto.Query
iex> query = from(Movie)                
%Ecto.Query<from m in Friends.Movie>
```

使用 `Repo.all/2` 函數執行查詢。此函數接收 Ecto 查詢的必需參數，並回傳滿足查詢條件的所有記錄。

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

#### 使用 from 的無綁定查詢

上面的範例缺少 SQL 語句中最有趣的部分。我們通常只想查詢特定欄位或按照某種條件來過濾記錄。現在來擷取所有具有 `"Ready Player One"` 標題電影的 `title` 和 `tagline`：

```elixir
iex> query = from(Movie, where: [title: "Ready Player One"], select: [:title, :tagline])
%Ecto.Query<from m in Friends.Movie, where: m.title == "Ready Player One",
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

請注意，回傳的結構體僅有 `tagline` 和 `title` 欄位 — 這是 `select:` 部​​分的結果。

這樣的查詢稱為 *無綁定（bindingless）*，因為它們非常簡單，不需要綁定。

#### 查詢中的綁定

到目前為止，使用了一個模組，該模組實現了 `Ecto.Queryable` 協定（例如： `Movie`）作為 `from` 巨集的第一個參數。但是，也可以使用 `in` 表達式，如下所示：

```elixir
iex> query = from(m in Movie)                                                           
%Ecto.Query<from m in Friends.Movie>
```

在這種情況下，稱 `m` 為一個 *綁定*。綁定非常有用，因為它能夠在查詢的其他部分參照模組。現在選擇所有 `id` 小於 `2` 電影的標題：

```elixir
iex> query = from(m in Movie, where: m.id < 2, select: m.title)
%Ecto.Query<from m in Friends.Movie, where: m.id < 2, select: m.title>

iex> Repo.all(query)                                           
SELECT m0."title" FROM "movies" AS m0 WHERE (m0."id" < 2) []
["Ready Player One"]
```

這裡非常重要的是如何改變查詢的輸出。通過在 `select:` 中使用帶有綁定的 *表達式* ，可以明確指定回傳選定欄位的方式。例如，可以要求一個元組：

```elixir
iex> query = from(m in Movie, where: m.id < 2, select: {m.title})             

iex> Repo.all(query)                                                          
[{"Ready Player One"}]
```

始終從簡單的無綁定查詢出發，並在需要參照資料結構時導入綁定是一個好主意。有關查詢中使用綁定的更多資訊，請參考 [Ecto 文件](https://hexdocs.pm/ecto/Ecto.Query.html#module-query-expressions)


### 基於巨集的查詢

上面的範例，在 `from` 巨集中使用了關鍵字 `select:` 和 `where:` 來建立查詢 — 這就是所謂 *基於關鍵字的查詢*。但是，還有另一種組合查詢的方式 — 基於巨集的查詢。Ecto 為每個關鍵字提供巨集，例如 `select/3` 或 `where/3`。每個巨集都接受一個 *可查詢（queryable）* 的值，一個顯式的綁定串列以及需提供相同類似關鍵字的表達式：

```elixir
iex> query = select(Movie, [m], m.title)                           
%Ecto.Query<from m in Friends.Movie, select: m.title>
iex> Repo.all(query)                    
SELECT m0."title" FROM "movies" AS m0 []
["Ready Player One"]
```

巨集的好處是可以與管線很好地配合使用：

```elixir
iex> query = Movie |> where([m], m.id < 2) |> select([m], {m.title})

iex> Repo.all(query)
[{"Ready Player One"}]
```


### 在 where 中使用插值

為了在 where 子句中使用插值或 Elixir 表達式，需要使用 `^` 或 pin 運算子。這允許將一個值 _釘_ 在變數上並引用該被固定的值，而不是重新綁定該變數。

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

### 取得第一筆和最後一筆記錄

可以使用 `Ecto.Query.first/2` 和 `Ecto.Query.last/2` 函數從存放庫中提取第一筆或最後一筆記錄。

首先，使用 `first/2` 函數編寫一個查詢表達式：

```elixir
iex> first(Movie)
%Ecto.Query<from m in Friends.Movie, order_by: [desc: m.id], limit: 1>
```

然後將查詢傳遞給 `Repo.one/2` 函數以獲得結果：

```elixir
iex> Movie |> first() |> Repo.one()

06:36:14.234 [debug] QUERY OK source="movies" db=3.7ms
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
%Ecto.Association.NotLoaded<association :actors is not loaded>
```

_不能_ 存取那些相關的角色，除非預載它們。而使用 Ecto 預載記錄有幾種不同的方法。

#### 使用 2 個查詢來預載

以下查詢將在 _分別的_ 查詢中預載關聯記錄。

```elixir
iex> Repo.all(from m in Movie, preload: [:actors])

13:17:28.354 [debug] QUERY OK source="movies" db=2.3ms queue=0.1ms
13:17:28.357 [debug] QUERY OK source="actors" db=2.4ms
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Bob"
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

可以看到上面程式碼執行了 _2_ 次資料庫查詢。一次用於所有電影，另一次用於具有給定電影 ID 的所有演員。


#### 使用 1 個查詢預載
可以通過以下方式減少資料庫查詢次數：

```elixir
iex> query = from(m in Movie, join: a in assoc(m, :actors), preload: [actors: a])
iex> Repo.all(query)

13:18:52.053 [debug] QUERY OK source="movies" db=3.7ms
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Bob"
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

這允許只執行一次資料庫呼用。它還具有允許在同一查詢中同時選定與過濾電影和其相關演員的額外好處。例如，這種方法允許使用 `join` 表達式查詢相關演員滿足特定條件的所有電影。就像是：

```elixir
Repo.all from m in Movie,
  join: a in assoc(m, :actors),
  where: a.name == "John Wayne",
  preload: [actors: a]
```

之後將會有 join 表達式的更多資訊。

#### 預載提取過的記錄

還可以預載已經從資料庫查詢過記錄的關聯結構描述。

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
      name: "Bob"
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

現在可以請求關於一部電影的演員：

```elixir
iex> movie.actors
[
  %Friends.Actor{
    __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
    id: 1,
    movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Bob"
  },
  %Friends.Actor{
    __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
    id: 2,
    movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Gary"
  }
]
```

### 使用 Join 表達式

可以在 `Ecto.Query.join/5` 函數幫助下執行包含 join 表達式的查詢。

```elixir
iex> query = from m in Movie,
              join: c in Character,
              on: m.id == c.movie_id,
              where: c.name == "Wade Watts",
              select: {m.title, c.name}
iex> Repo.all(query)
15:28:23.756 [debug] QUERY OK source="movies" db=5.5ms
[{"Ready Player One", "Wade Watts"}]
```

`on` 表達式也可以使用關鍵字列表：

```elixir
from m in Movie,
  join: c in Character,
  on: [id: c.movie_id], # keyword list
  where: c.name == "Wade Watts",
  select: {m.title, c.name}
```

在上面的例子中，join 了一個 Ecto 結構描述，`m in Movie`。也可以 join Ecto 查詢。假設電影表格中有一欄 `stars`，它儲存電影的 "星級"，數字從 1-5。

```elixir
movies = from m in Movie, where: [stars: 5]
from c in Character,
  join: ^movies,
  on: [id: c.movie_id], # keyword list
  where: c.name == "Wade Watts",
  select: {m.title, c.name}
```

Ecto Query DSL 是一個功能強大的工具，它提供了進行複雜資料庫查詢所需的一切。而通過此介紹則希望給了你開始查詢的基本知識。