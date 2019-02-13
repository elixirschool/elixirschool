---
version: 1.0.1
title: アソシエーション
---

このセクションでは、スキーマ間のアソシエーションを定義し、扱うためにEctoを使用する方法について学びます。

{% include toc.html %}

## セットアップ

前回のレッスンに続いて `Example` というアプリを構築します。 [ここ](../basics) のセットアップを見るとすぐに思い出せます。

## アソシエーションの種類

スキーマ間で定義することができるアソシーションは3つあります。それらがどういうものか、そして各種類の関係をどのように実装するのかを見ていきます。

### Belongs To/Has Many

私たちのお気に入りの映画をカタログを作れるように、デモアプリのドメインモデルにいくつかの新しいエンティティを追加します。まずは `Movie` と `Character` という2つのスキーマから始めます。これらのスキーマの間に "has many/belongs to" の関係を実装して、movieは複数のcharacterを持ち、characterはmovieに所属するようにします。

#### Has Many マイグレーション

`Movie` のマイグレーションを作ってみましょう:

```console
mix ecto.gen.migration create_movies
```

新しく作られたマイグレーションファイルを開き、いくつか属性を持った `movies` テーブルを作るために `change` 関数を定義しましょう:

```elixir
# priv/repo/migrations/*_create_movies.exs
defmodule Example.Repo.Migrations.CreateMovies do
  use Ecto.Migration

  def change do
    create table(:movies) do
      add :title, :string
      add :tagline, :string
    end
  end
end
```

#### Has Many スキーマ

movieとcharacterのと間に"has many"の関係を指定するスキーマを追加します。

```elixir
# lib/example/movie.ex
defmodule Example.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Example.Character
  end
end
```

`has_many/3` マクロはデータベースそのものには何も追加しません。これは関連付けられたスキーマである `characters` の外部キーを使用し、movieに関連するcharacterを利用可能にします。これによって `movie.characters` が使用可能となります。

#### Belongs To マイグレーション

これで `Character` マイグレーションとスキーマを構築する準備ができました。characterはmovieに所属するので、この関係を示すマイグレーションとスキーマを定義します。

まずは、マイグレーションを生成します:

```console
mix ecto.gen.migration create_characters
```

movieに所属するcharacterを定義するためには、 `movie_id` を持つ `characters` テーブルが必要です。このカラムは外部キーとして機能させたいです。これは、 `create_table/1` 関数に次の行を追加することで実現できます:

```elixir
add :movie_id, references(:movies)
```
つまりマイグレーションファイルはこのようになります:

```elixir
# priv/migrations/*_create_characters.exs
defmodule Example.Repo.Migrations.CreateCharacters do
  use Ecto.Migration

  def change do
    create_table(:characters) do
      add :name, :string
      add :movie_id, references(:movies)
    end
  end
end
```

#### Belongs To スキーマ

スキーマもまたcharacterとmovieの間に"belongs to"の関係を定義する必要があります。

```elixir
# lib/example/character.ex

defmodule Example.Character do
  use Ecto.Schema

  schema "characters" do
    field :name, :string
    belongs_to :movie, Example.Movie
  end
end
```

`belongs_to/3` マクロが何をするのか詳しく見てみましょう。 `characters` への `movie_id` カラムの追加とは違って、このマクロはデータベースに何も追加 _しません_。これは `characters` を通して関連した `movies` スキーマにアクセスする機能を _提供します_ 。これは　`characters` テーブルにある `movie_id` の外部キーを使用して、characterのクエリを実行する際にcharacterに関連したmovieを利用できるようにします。これによって `character.movie` を使えるようになります。

これでマイグレーションを実行する準備ができました:

```console
mix ecto.migrate
```

### Belongs To/Has One

movieは1つのdistributorを持っているとしましょう。例えばNetflixは彼らのオリジナル映画 "Bright" のdistributorです。

"belongs to"の関係を使って `Distributor` のマイグレーションとスキーマを定義します。まずは、マイグレーションを生成しましょう:

```console
mix ecto.gen.migration create_distributors
```

マイグレーションでは `movie_id` の外部キーを `distributors` テーブルに追加します:

```elixir
# priv/repo/migrations/*_create_distributors.exs

defmodule Example.Repo.Migrations.CreateDistributors do
  use Ecto.Migration

  def change do
    create table(:distributors) do
      add :name, :string
      add :movie_id, references(:movies)
    end
  end
end
```

そして `Distributor` スキーマは `belongs_to/3` マクロを使うことで、 `distributor.movie` を使用可能にし、また外部キーによってdistributorに関連したmovieを見つけられるようにします。

```elixir
# lib/example/distributor.ex

defmodule Example.Distributor do
  use Ecto.Schema

  schema "distributors" do
    field :name, :string
    belongs_to :movie, Example.Movie
  end
end
```

次に、"has one"の関係を `Movie` スキーマに追加します:

```elixir
# lib/example/movie.ex

defmodule Example.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Example.Character
    has_one :distributor, Example.Distributor # I'm new!
  end
end
```

`has_one/3` マクロは `has_many/3` マクロのように機能します。これはデータベースに何も追加しませんが、movieのdistributorを探してアクセスできるようにするために関連したスキーマの外部キーを _使用します_ 。これによって `movie.distributor` が使えるようになります。

マイグレーション実行の準備ができました:

```console
mix ecto.migrate
```

### Many To Many

movieは多くのactorを持っていて、actorは1つ以上のmovieに所属することができるとしましょう。この関係を実装するために、movie _と_ actor の _両方_ を参照する中間テーブルを構築します。

はじめに、 `Actors` マイグレーションを生成しましょう:

マイグレーションを作ります:

```console
mix ecto.gen.migration create_actors
```

マイグレーションを定義します:

```elixir
# priv/migrations/*_create_actors.ex

defmodule Example.Repo.Migrations.Actors do
  use Ecto.Migration

  def change do
    create table(:actors) do
      add :name, :string
    end
  end
end
```

中間テーブルのマイグレーションを生成しましょう:

```console
mix ecto.gen.migration create_movies_actors
```

2つの外部キーを持つテーブルをマイグレーションで定義します。また、actorとmovieの組み合わせが一意となるようにユニークインデックスを追加します:

```elixir
# priv/migrations/*_create_movies_actors.ex

defmodule Example.Repo.Migrations.CreateMoviesActors do
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

次に、 `many_to_many` マクロを `Movie` スキーマに追加しましょう:

```elixir
# lib/example/movie.ex

defmodule Example.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Example.Character
    has_one :distributor, Example.Distributor
    many_to_many :actors, Example.Actor, join_through: "movies_actors" # I'm new!
  end
end
```

最後に、 同じ `many_to_many` マクロで `Actor` スキーマを定義します。

```elixir
# lib/example/actor.ex

defmodule Example.Actor do
  use Ecto.Schema

  schema "actors" do
    field :name, :string
    many_to_many :movies, Example.Movie, join_through: "movies_actors"
  end
end
```

マイグレーション実行の準備ができました:

```console
mix ecto.migrate
```

## 関連データの保存

レコードを関連するデータと一緒に保存する方法は、レコード間の関係性によって異なります。"Belongs to/has many"という関係から始めましょう。

### Belongs To

#### `Ecto.build_assoc/3` による保存

"belongs to"の関係では、 `build_assoc/3` 関数を利用できます。

[`build_assoc/3`](https://hexdocs.pm/ecto/Ecto.html#build_assoc/3) は3つの引数をとります:

* 保存したいレコードの構造体
* アソシエーションの名前
* 保存する関連レコードにアサインしたい属性

movieと関連するcharacterを保存してみましょう:

はじめに、movieのレコードを作ります:

```elixir
iex> alias Example.{Movie, Character, Repo}
iex> movie = %Movie{title: "Ready Player One", tagline: "Something about video games"}

%Example.Movie{
  __meta__: #Ecto.Schema.Metadata<:built, "movies">,
  actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: nil,
  tagline: "Something about video games",
  title: "Ready Player One"
}

iex> movie = Repo.insert!(movie)
```

次に、関連するcharacterを作ってデータベースに挿入します:

```elixir
character = Ecto.build_assoc(movie, :characters, %{name: "Wade Watts"})
%Example.Character{
  __meta__: #Ecto.Schema.Metadata<:built, "characters">,
  id: nil,
  movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Wade Watts"
}
Repo.insert!(character)
%Example.Character{
  __meta__: #Ecto.Schema.Metadata<:loaded, "characters">,
  id: 1,
  movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Wade Watts"
}
```

`Movie` スキーマの `has_many/3` マクロは movieが複数の `:characters` を持つことを示すので、 `build_assoc/3` の2つ目の引数として渡したアソシエーションの名前は `:characters` そのものだと気がつくでしょう。私たちが作ったcharacterは、関連するmovieのIDが正しくセットされた `movie_id` を持っていることがわかります。

`build_assoc/3` を使ってmovieの関連したdistributorを保存するために、 `build_assoc/3` の2つ目の引数としてmovieに関連するdistributorの _name_ を渡すという同様のアプローチを取ります。

```elixir
iex> distributor = Ecto.build_assoc(movie, :distributor, %{name: "Netflix"})       
%Example.Distributor{
  __meta__: #Ecto.Schema.Metadata<:built, "distributors">,
  id: nil,
  movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Netflix"
}
iex> Repo.insert!(distributor)
%Example.Distributor{
  __meta__: #Ecto.Schema.Metadata<:loaded, "distributors">,
  id: 1,
  movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Netflix"
}
```

### Many to Many

#### `Ecto.Changeset.put_assoc/4` による保存

`build_assoc/3` のアプローチはmany-to-manyの関係では使えません。movieテーブルもactorテーブルも外部キーを持たないためです。代わりに、Ectoのチェンジセットと `put_assoc/4` 関数を利用する必要があります。

上で作ったmovieのレコードを既に持っているとして、actorレコードを作ってみましょう:

```elixir
iex> alias Example.Actor
iex> actor = %Actor{name: "Tyler Sheridan"}
%Example.Actor{
  __meta__: #Ecto.Schema.Metadata<:built, "actors">,
  id: nil,
  movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
  name: "Tyler Sheridan"
}
iex> actor = Repo.insert!(actor)
%Example.Actor{
  __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
  id: 1,
  movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
  name: "Tyler Sheridan"
}
```

これで中間テーブルを通してmovieとactorを関連付ける準備ができました。

まず、チェンジセットを扱うためには、 `movie` レコードに関連するスキーマを確実に事前ロードしている必要があります。データの事前ロードについてはの後に話します。今のところは、次のようにアソシエーションを事前ロードできるということだけ理解していれば十分です:

```elixir
iex> movie = Repo.preload(movie, [:distributor, :characters, :actors])
%Example.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [],
  characters: [],
  distributor: nil,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

次に、movieレコードのためにチェンジセットを作ります:

```elixir
iex> movie_changeset = Ecto.Changeset.change(movie)                                                    
#Ecto.Changeset<action: nil, changes: %{}, errors: [], data: #Example.Movie<>,
 valid?: true>
```

そして [`Ecto.Changeset.put_assoc/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#put_assoc/4) の第１引数としてチェンジセットを渡します:

```elixir
iex> movie_actors_changeset = movie_changeset |> Ecto.Changeset.put_assoc(:actors, [actor])
#Ecto.Changeset<
  action: nil,
  changes: %{
    actors: [
      #Ecto.Changeset<action: :update, changes: %{}, errors: [],
       data: #Example.Actor<>, valid?: true>
    ]
  },
  errors: [],
  data: #Example.Movie<>,
  valid?: true
>
```

これにより、次の変更を表す _新しい_ チェンジセットが作られます: actorsリストのactorをmovieレコードに追加する。

最後に、最新のチェンジセットを使用してmovieとactorのレコードを更新します:

```elixir
iex> Repo.update!(movie_actors_changeset)
%Example.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Example.Actor{
      __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
      id: 1,
      movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
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

これによってmovieレコードがactorと適切に関連付けられて、 `movie.actors` に事前ロードされていることがわかります。

同じアプローチを使って、movieに関連する新しいactorを追加できます。 _保存された_ actorの構造体を `put_assoc/4` に渡す代わりに、単純に作成したいactorを表す構造体を渡します:

```elixir
iex> changeset = movie_changeset |> Ecto.Changeset.put_assoc(:actors, [%{name: "Gary"}])                      
#Ecto.Changeset<
  action: nil,
  changes: %{
    actors: [
      #Ecto.Changeset<
        action: :insert,
        changes: %{name: "Gary"},
        errors: [],
        data: #Example.Actor<>,
        valid?: true
      >
    ]
  },
  errors: [],
  data: #Example.Movie<>,
  valid?: true
>
iex>  Repo.update!(changeset)
%Example.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Example.Actor{
      __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
      id: 2,
      movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
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

"2"というIDと割り当てた値を持ったactorが作られたことを確認できました。

次のセクションでは、関連付けたレコードにクエリを実行する方法を学びます。
