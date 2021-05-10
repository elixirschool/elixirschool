%{
  version: "1.2.0",
  title: "クエリ",
  excerpt: """
  """
}
---

このレッスンでは、 `Friends` アプリと [前のレッスン](./associations) で設定した映画ドメインを引き続き作成します。

## Ecto.Repo によるレコードのフェッチ

Postgresデータベースのようなデータストアに対してマップするEctoの "レポジトリ" を思い出してください。
データベースに対する全てのコミュニケーションは、このレポジトリを使用して行われます。

いくつかの関数の助けを借りることで、 `Friends.Repo` に対してシンプルなクエリを直接実行することができます。

### IDによるレコードのフェッチ

`Repo.get/3` 関数を使って与えられたIDを持つレコードをデータベースからフェッチすることができます。この関数には2つの引数が必要です。 "クエリ可能な" データ構造体とデータベースから取得するレコードのIDです。これは、レコードを見つけた場合、そのレコードを表す構造体を返します。レコードが見つからない場合には `nil` を返します。

例を見てみましょう。下のコードは、1のIDを持つ映画(movie)を取得します:

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

`Repo.get/3` に渡した1つ目の引数は `Movie` モジュールです。 `Movie` は `Ecto.Schema` モジュールを使い、自身のデータ構造体のためにスキーマを定義しているので "クエリ可能" です。これによって `Movie` は `Ecto.Queryable` プロトコルにアクセスすることができます。このプロトコルはデータ構造体を `Ecto.Query` へと変換します。Ectoクエリはレポジトリからデータを取得するために使用されます。クエリの詳細は後に説明します。

### 属性によるレコードのフェッチ

`Repo.get_by/3` 関数で与えられた条件を満たすレコードをフェッチすることもできます。この関数は2つの引数を必要とします。 "クエリ可能な" データ構造体とクエリをしたい条件です。 `Repo.get_by/3` はレポジトリから1つの結果を返します。例を見てみましょう:

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

より複雑なクエリを書きたい、あるいは特定の条件を満たす _全ての_ レコードを取得したい場合は、 `Ecto.Query` が必要です。

## Ecto.Query によるクエリの作成

`Ecto.Query` モジュールはクエリDSLを提供しており、これによってアプリケーションのレポジトリからデータを取り出すクエリを書くことができます。

### Ecto.Query.from/2 を使用したKeyword-basedクエリの作成

`Ecto.Query.from/2` マクロを使用してクエリを作ることができます。この関数は2つの引数を取ります。式と任意のキーワードリストです。レポジトリから全ての映画を選択する最も簡単なクエリを作ってみましょう。

```elixir
iex> import Ecto.Query
iex> query = from(Movie)
#Ecto.Query<from m0 in Friends.Movie>
```

クエリを実行するためには、 `Repo.all/2` 関数を使用します。この関数はEctoクエリの必須の引数を取り、クエリの条件を満たす全てのレコードを返します。

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

#### from によるBindinglessなクエリの作成

上の例では、SQLステートメントの最も楽しい部分がありません。特定のフィールドのみを参照したり、何らかの条件でレコードをフィルタリングしたりすることがよくあります。タイトルが `"Ready Player One"` である全ての映画の `title` と `tagline` を取得してみましょう。

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

返ってくる構造体には `tagline` と `title` フィールドのみが設定されていることに注意してください - これは `select:` の結果です。

このようなクエリは、bindingを必要としないほど単純であるため、 *bindingless* と呼ばれます。

#### クエリでのBinding

これまで、 `from` マクロの最初の引数として `Ecto.Queryable` プロトコル（例： `Movie`）を実装するモジュールを使用しました。しかしながら、このような `in` 式も利用することができます。

```elixir
iex> query = from(m in Movie)
#Ecto.Query<from m0 in Friends.Movie>
```

このような場合には、 `m` を *binding* と呼びます。クエリの他の部分からモジュールが参照できるため、Bindingは非常に便利です。 `id` が `2` より小さい全ての映画のタイトルを選択してみましょう:

```elixir
iex> query = from(m in Movie, where: m.id < 2, select: m.title)
#Ecto.Query<from m0 in Friends.Movie, where: m0.id < 2, select: m0.title>

iex> Repo.all(query)
SELECT m0."title" FROM "movies" AS m0 WHERE (m0."id" < 2) []
["Ready Player One"]
```

ここで非常に重要なことは、クエリの出力がどのように変化したかです。`select:` 部分のbindingで *式* を使用すると、選択したフィールドが返される方法を正確に指定できます。例えば、タプルを指定できます。

```elixir
iex> query = from(m in Movie, where: m.id < 2, select: {m.title})

iex> Repo.all(query)
[{"Ready Player One"}]
```

データ構造を参照する必要がある場合は、常に単純なbindinglessクエリから始めて、bindingを導入することをお勧めします。クエリのbindingの詳細については、[Ecto documentation](https://hexdocs.pm/ecto/Ecto.Query.html#module-query-expressions) を参照してください。

### マクロクエリ

上記の例では、 `from` マクロ内でキーワード `select:` と `where:` を使用してクエリを作成しました。これらは、*keyword-basedのクエリ* と呼ばれます。ただし、クエリを作成する別の方法もあります。マクロベースのクエリです。Ectoは、`select/3` や `where/3` のような全てのキーワードに対してマクロを提供します。各マクロは、*queryable* な値、*明示的なbindingのリスト*、およびアナログなキーワードに提供するのと同じ式を受け入れます:

```elixir
iex> query = select(Movie, [m], m.title)
#Ecto.Query<from m0 in Friends.Movie, select: m0.title>

iex> Repo.all(query)
SELECT m0."title" FROM "movies" AS m0 []
["Ready Player One"]
```

マクロの良いところは、パイプで非常にうまく機能することです。

```elixir
iex> Movie \
...>  |> where([m], m.id < 2) \
...>  |> select([m], {m.title}) \
...>  |> Repo.all
[{"Ready Player One"}]
```

改行後も書き込みを続けるには、 `\` を使用することに注意してください。

### 埋め込み値による where の使用

where句において埋め込み値やElixirの式を使うためには、 `^` 、つまりピン演算子を使う必要があります。これによって値を再束縛するのではなく、変数に値を _固定する_ ことで、その固定された値を参照することが可能になります。

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

### 最初と最後のレコードの取得

`Ecto.Query.first/2` と `Ecto.Query.last/2` 関数を使って、レポジトリの最初と最後のレコードをフェッチすることができます。

まずは、 `first/2` 関数を使ったクエリ式を書いてみます:

```elixir
iex> first(Movie)
#Ecto.Query<from m0 in Friends.Movie, order_by: [asc: m0.id], limit: 1>
```

次に、そのクエリを `Repo.one/2` 関数に渡して結果を取得します:

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
%Ecto.Association.NotLoaded<association :actors is not loaded>
```

プリロードしない限り、それらの関連したデータにアクセスすることはできません。Ectoを使ってレコードをプリロードするにはいくつかの方法があります。

#### 2つのクエリによるプリロード

次のクエリは _独立した_ クエリで関連したレコードをプリロードします。

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

上のコードでは_2つの_データベースクエリが実行されることがわかります。1つは全ての映画を、もう1つは全ての俳優を映画IDとともに取得しています。

#### 1つのクエリによるプリロード

私たちは次のようにデータベースクエリを削減することができます。

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

これによって、データベースへの問い合わせを1回にすることができます。また、同じクエリで映画と関連する俳優の両方を選択してフィルタ処理できるという利点もあります。例えば次のように、このアプローチによって `join` ステートメントを使用して特定の条件を満たす俳優を持つ全ての映画を取得することができます:

```elixir
Repo.all from m in Movie,
  join: a in assoc(m, :actors),
  where: a.name == "John Wayne",
  preload: [actors: a]
```

joinステートメントについて、もっと詳細を見てみましょう。

#### フェッチされたレコードのプリロード

データベースから取得したレコードの関連スキーマをプリロードすることもできます。

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

これで映画の俳優を参照することができます:

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

### joinステートメントの使用

`Ecto.Query.join/5` 関数によってjoinステートメントを含むクエリを実行することができます。

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

`on` 式にはキーワードリストを使うこともできます:

```elixir
from m in Movie,
  join: c in Character,
  on: [id: c.movie_id], # keyword list
  where: c.name == "Wade Watts",
  select: {m.title, c.name}
```

上の例では、Ectoスキーマを `m in Movie` で結合しています。また、Ectoクエリについても結合することができます。映画テーブルが、1から5の範囲の評価を格納するカラム `stars` を持っているとしましょう。

```elixir
movies = from m in Movie, where: [stars: 5]
from c in Character,
  join: ^movies,
  on: [id: c.movie_id], # keyword list
  where: c.name == "Wade Watts",
  select: {m.title, c.name}
```

EctoクエリDSLは、複雑なデータベースクエリを作るために必要な全てを提供する強力なツールです。このイントロダクションでは、クエリを始めるための基本的な構成要素を提供しています。
