---
version: 1.0.1
title: クエリ
---

{% include toc.html %}

このレッスンでは、 `Example` アプリと [前のレッスン](./associations) で設定した映画ドメインを作成します。

## `Ecto.Repo` によるレコードのフェッチ

Postgresデータベースのようなデータストアに対してマップするEctoの "レポジトリ" を思い出してください。
データベースに対する全てのコミュニケーションは、このレポジトリを使用して行われます。

いくつかの関数の助けを借りることで、 `Example.Repo` に対してシンプルなクエリを直接実行することができます。

### IDによるレコードのフェッチ

`Repo.get/3` 関数を使って与えられたIDを持つレコードをデータベースからフェッチすることができます。この関数には2つの引数が必要です。 "クエリ可能な" データ構造体とデータベースから取得するレコードのIDです。これは、レコードを見つけた場合、そのレコードを表す構造体を返します。レコードが見つからない場合には `nil` を返します。

例を見てみましょう。下のコードは、1のIDを持つ映画(movie)を取得します:

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

`Repo.get/3` に渡した1つ目の引数は `Movie` モジュールです。 `Movie` は `Ecto.Schema` モジュールを使い、自身のデータ構造体のためにスキーマを定義しているので "クエリ可能" です。これによって `Movie` は `Ecto.Queryable` プロトコルにアクセスすることができます。このプロトコルはデータ構造体を `Ecto.Query` へと変換します。Ectoクエリはレポジトリからデータを取得するために使用されます。クエリの詳細は後に説明します。

### 属性によるレコードのフェッチ

`Repo.get_by/3` 関数で与えられた条件を満たすレコードをフェッチすることもできます。この関数は2つの引数を必要とします。 "クエリ可能な" データ構造体とクエリをしたい条件です。 `Repo.get_by/3` はレポジトリから1つの結果を返します。例を見てみましょう:

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

より複雑なクエリを書きたい、あるいは特定の条件を満たす _全ての_ レコードを取得したい場合は、 `Ecto.Query` が必要です。

## `Ecto.Query` によるクエリの作成

`Ecto.Query` モジュールはクエリDSLを提供しており、これによってアプリケーションのレポジトリからデータを取り出すクエリを書くことができます。

### `Ecto.Query.from/2` によるクエリの作成

`Ecto.Query.from/2` 関数を使用してクエリを作ることができます。この関数は2つの引数を取ります。式とキーワードリストです。レポジトリから全ての映画を選択するクエリを作ってみましょう。

```elixir
import Ecto.Query
query = from(m in Movie, select: m)
#Ecto.Query<from m in Example.Movie, select: m>
```

クエリを実行するためには、 `Repo.all/2` 関数を使用します。この関数はEctoクエリの必須の引数を取り、クエリの条件を満たす全てのレコードを返します。

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

#### キーワードクエリによる `from` の使用

上の例では `from/2` に *キーワードクエリ* の引数を与えています。 `from` をキーワードクエリとともに使う場合、第１引数は次の2つのうちいずれかになります:

* `in` 式 (例: `m in Movie`)
* `Ecto.Queryable` プロトコルを実装したモジュール (例: `Movie`)

第２引数は `select` キーワードクエリになります。

#### クエリ式による `from` の使用

クエリ式とともに `from` を使う場合、第１引数は `Ecto.Queryable` プロトコルを実装した値でなければいけません (例: `Movie`)。第２引数は式となります。例を見てみましょう:

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

`in` ステートメント (`m in Movie`) が _必要ない_ 場合にはクエリ式を使うことができます。データ構造への参照を必要としない場合には `in` ステートメントは必要ありません。上のクエリはデータ構造の参照を必要とません。例えば、特定の条件を満たす映画を選択することはない場合がそれにあたります。そのため `in` 式とキーワードクエリを使う必要はありません。

### `select` 式の使用

クエリのselectステートメントの部分を指定するために `Ecto.Query.select/3` 関数を使います。特定のフィールドだけ選択したい場合は、アトムのリスト、もしくは構造体のキーの参照でそれを指定することができます。1つ目のアプローチを見てみましょう:

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

`from` 関数に渡された第１引数では `in` 式を _使わなかった_ ことがわかります。これは、 `select` とともにキーワードリストを使うためにデータ構造への参照を作る必要が無かったためです。

このアプローチでは、指定されたフィールドである `title` の値のみが格納された構造体が返されます。

2つ目のアプローチでは動きが少しが異なります。この場合は `in` 式を _使う必要があります_ 。これは、映画構造体の `title` キーを指定するためにデータ構造体への参照を作る必要があるためです:

```elixir
iex(15)> query = from(m in Movie, select: m.title)   
#Ecto.Query<from m in Example.Movie, select: m.title>
iex(16)> Repo.all(query)                             

15:06:12.752 [debug] QUERY OK source="movies" db=4.5ms queue=0.1ms
["Ready Player One"]
```

`select` を使うこのアプローチでは、選択した値を含むリストが返されることがわかります。

### `where` 式の使用

"where" 句をクエリに含めるために `where` 式を使うことができます。複数の `where` 式は `WHERE AND` のSQLステートメントへとまとめられます。

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

`where` 式は `select` とともに使うことができます。

```elixir
iex> query = from(m in Movie, where: m.title == "Ready Player One", select: m.tagline)
#Ecto.Query<from m in Example.Movie, where: m.title == "Ready Player One", select: m.tagline>
iex> Repo.all(query)

15:19:11.904 [debug] QUERY OK source="movies" db=4.1ms
["Something about video games"]
```

### 埋め込み値による `where` の使用

where句において埋め込み値やElixirの式を使うためには、 `^` 、つまりピン演算子を使う必要があります。これによって値を再束縛するのではなく、変数に値を _固定する_ ことで、その固定された値を参照することが可能になります。

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

### 最初と最後のレコードの取得

`Ecto.Query.first/2` と `Ecto.Query.last/2` 関数を使って、レポジトリの最初と最後のレコードをフェッチすることができます。

まずは、 `first/2` 関数を使ったクエリ式を書いてみます:

```elixir
iex> first(Movie)
#Ecto.Query<from m in Example.Movie, order_by: [desc: m.id], limit: 1>
```

次に、そのクエリを `Repo.one/2` 関数に渡して結果を取得します:

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

`Ecto.Query.last/2` 関数も同じように使います:

```elixir
iex> Movie |> last() |> Repo.one()
```

## 関連したデータのクエリ

### プリロード

`belongs_to` 、 `has_many` 、そして `has_one` マクロからの公開する関連レコードにアクセスできるようにするために、関連したスキーマを _プリロード_ する必要があります。

関連する俳優を映画に問い合わせるとどうなるかを見てみましょう。

```elixir
iex> movie = Repo.get(Movie, 1)
iex> movie.actors
#Ecto.Association.NotLoaded<association :actors is not loaded>
```

プリロードしない限り、それらの関連したデータにアクセスすることはできません。Ectoを使ってレコードをプリロードするにはいくつかの方法があります。

#### 2つのクエリによるプリロード

次のクエリは _独立した_ クエリで関連したレコードをプリロードします。

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

上のコードでは _2つの_ データベースクエリが実行されることがわかります。1つは全ての映画を、もう1つは全ての俳優を映画IDとともに取得しています。


#### 1つのクエリによるプリロード
私たちは次のようにデータベースクエリを削減することができます。

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

これによって、データベースへの問い合わせを1回にすることができます。また、同じクエリで映画と関連する俳優の両方を選択してフィルタ処理できるという利点もあります。例えば次のように、このアプローチによって `join` ステートメントを使用して特定の条件を満たす俳優を持つ全ての映画を取得することができます:

```elixir
Repo.all from m in Movie,
  join: a in assoc(m, :actors),
  where: a.name == "John Wayne"
  preload: [actors: a]
```

joinステートメントについて、もっと詳細を見てみましょう。

#### フェッチされたレコードのプリロード

データベースから取得したレコードの関連スキーマをプリロードすることもできます。

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

これで映画の俳優を参照することができます:

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

### joinステートメントの使用

`Ecto.Query.join/5` 関数によってjoinステートメントを含むクエリを実行することができます。

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

`on` 式にはキーワードリストを使うこともできます:

```elixir
from m in Movie,
  join: c in Character,
  on: [id: c.movie_id], # keyword list
  where: c.name == "Video Game Guy",
  select: {m.title, c.name}
```

上の例では、Ectoスキーマを `m in Movie` で結合しています。また、Ectoクエリについても結合することができます。映画テーブルが、1から5の範囲の評価を格納するカラム `stars` を持っているとしましょう。

```elixir
movies = from m in Movie, where: [stars: 5]
from c in Character,
  join: ^movies,
  on: [id: c.movie_id], # keyword list
  where: c.name == "Video Game Guy",
  select: {m.title, c.name}
```

EctoクエリDSLは、複雑なデータベースクエリを作るために必要な全てを提供する強力なツールです。このイントロダクションでは、クエリを始めるための基本的な構成要素を提供しています。
