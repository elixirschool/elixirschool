---
version: 1.2.1
title: アソシエーション
---

このセクションでは、スキーマ間のアソシエーションを定義し、扱うためにEctoを使用する方法について学びます。

{% include toc.html %}

## セットアップ

前回のレッスンの `Friends` アプリから始めましょう。 [ここ](../basics) のセットアップを見るとすぐに思い出せます。

## アソシエーションの種類

スキーマ間で定義することができるアソシーションは3つあります。それらがどういうものか、そして各種類の関係をどのように実装するのかを見ていきます。

### 従属/1対多

私たちのお気に入りの映画をカタログを作れるように、デモアプリのドメインモデルにいくつかの新しいエンティティを追加します。まずは `Movie` と `Character` という2つのスキーマから始めます。これらのスキーマの間に "1対多/従属" の関係を実装して、映画(movie)は複数のキャラクター(character)を持ち、キャラクターは映画に従属するようにします。

#### 1対多マイグレーション

`Movie` のマイグレーションを作ってみましょう:

```console
mix ecto.gen.migration create_movies
```

新しく作られたマイグレーションファイルを開き、いくつか属性を持った `movies` テーブルを作るために `change` 関数を定義しましょう:

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

#### 1対多スキーマ

映画とキャラクターとの間に"1対多"の関係を指定するスキーマを追加します。

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

`has_many/3` マクロはデータベースそのものには何も追加しません。これは関連付けられたスキーマである `characters` の外部キーを使用し、映画に関連するキャラクターを利用可能にします。これによって `movie.characters` が使用可能となります。

#### 従属マイグレーション

これで `Character` マイグレーションとスキーマを構築する準備ができました。キャラクターは映画に従属するので、この関係を示すマイグレーションとスキーマを定義します。

まずは、マイグレーションを生成します:

```console
mix ecto.gen.migration create_characters
```

映画に従属するキャラクターを定義するためには、 `movie_id` を持つ `characters` テーブルが必要です。このカラムは外部キーとして機能させたいです。これは、 `create_table/1` 関数に次の行を追加することで実現できます:

```elixir
add :movie_id, references(:movies)
```

つまりマイグレーションファイルはこのようになります:

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

#### 従属 スキーマ

スキーマもまたキャラクターと映画の間に"従属"の関係を定義する必要があります。

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

`belongs_to/3` マクロが何をするのか詳しく見てみましょう。 スキーマへの外部キーの `movie_id` の追加に加えて、これは `characters` を通して関連した `movies` スキーマにアクセスする機能を _提供します_ 。これは外部キーを使用してキャラクターのクエリを実行する際に、キャラクターに関連した映画を参照できるようにします。これによって `character.movie` を使えるようになります。

これでマイグレーションを実行する準備ができました:

```console
mix ecto.migrate
```

### 従属/1対1

映画は1つの配信者(distributor)を持っているとしましょう。例えばNetflixは彼らのオリジナル映画 "Bright" の配信者です。

"従属"の関係を使って `Distributor` のマイグレーションとスキーマを定義します。まずは、マイグレーションを生成しましょう:

```console
mix ecto.gen.migration create_distributors
```

生成した `distributors` テーブルのマイグレーションに、外部キーの `movie_id` と、映画の配信者が1人であることを示すユニークインデックスを追加する必要があります。

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

そして `Distributor` スキーマは `belongs_to/3` マクロを使うことで、 `distributor.movie` を使用可能にし、また外部キーによって配信者に関連した映画を見つけられるようにします。

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

次に、"1対1"の関係を `Movie` スキーマに追加します:

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

`has_one/3` マクロは `has_many/3` マクロのように機能します。これは、映画の配信者を探してアクセスできるようにするために関連したスキーマの外部キーを _使用します_ 。これによって `movie.distributor` が使えるようになります。

マイグレーション実行の準備ができました:

```console
mix ecto.migrate
```

### 多対多

映画は多くの俳優(actor)を持っていて、俳優は1つ以上の映画に従属することができるとしましょう。この関係を実装するために、映画 _と_ 俳優 の _両方_ を参照する中間テーブルを構築します。

はじめに、 `Actors` マイグレーションを生成しましょう:

```console
mix ecto.gen.migration create_actors
```

マイグレーションを定義します:

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

中間テーブルのマイグレーションを生成しましょう:

```console
mix ecto.gen.migration create_movies_actors
```

2つの外部キーを持つテーブルをマイグレーションで定義します。また、俳優と映画の組み合わせが一意となるようにユニークインデックスを追加します:

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

次に、 `many_to_many` マクロを `Movie` スキーマに追加しましょう:

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

最後に、 同じ `many_to_many` マクロで `Actor` スキーマを定義します。

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

マイグレーション実行の準備ができました:

```console
mix ecto.migrate
```

## 関連データの保存

レコードを関連するデータと一緒に保存する方法は、レコード間の関係性によって異なります。"従属/1対多"という関係から始めましょう。

### 従属

#### `Ecto.build_assoc/3` による保存

"従属"の関係では、 `build_assoc/3` 関数を利用できます。

[`build_assoc/3`](https://hexdocs.pm/ecto/Ecto.html#build_assoc/3) は3つの引数をとります:

- 保存したいレコードの構造体
- アソシエーションの名前
- 保存する関連レコードにアサインしたい属性

映画と関連するキャラクターを保存してみましょう。はじめに、映画のレコードを作ります:

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

次に、関連するキャラクターを作ってデータベースに挿入します:

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

`Movie` スキーマの `has_many/3` マクロは 映画が複数の `:characters` を持つことを示すので、 `build_assoc/3` の2つ目の引数として渡したアソシエーションの名前は `:characters` そのものだと気がつくでしょう。私たちが作ったキャラクターは、関連する映画のIDが正しくセットされた `movie_id` を持っていることがわかります。

`build_assoc/3` を使って映画の関連した配信者を保存するために、 `build_assoc/3` の2つ目の引数として映画に関連する配信者の_name_を渡すという同様のアプローチを取ります。

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

### 多対多

#### `Ecto.Changeset.put_assoc/4` による保存

`build_assoc/3` のアプローチは多対多の関係では使えません。映画テーブルも俳優テーブルも外部キーを持たないためです。代わりに、Ectoのチェンジセットと `put_assoc/4` 関数を利用する必要があります。

上で作った映画のレコードを既に持っているとして、俳優レコードを作ってみましょう:

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

これで中間テーブルを通して映画と俳優を関連付ける準備ができました。

まず、チェンジセットを扱うためには、 `movie` の構造体に関連するデータを確実に事前ロードしている必要があります。データの事前ロードについてはの後に話します。今のところは、次のようにアソシエーションを事前ロードできるということだけ理解していれば十分です:

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

次に、映画レコードのためにチェンジセットを作ります:

```elixir
iex> movie_changeset = Ecto.Changeset.change(movie)
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Movie<>,
 valid?: true>
```

そして [`Ecto.Changeset.put_assoc/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#put_assoc/4) の第１引数としてチェンジセットを渡します:

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

これにより、次の変更を表す _新しい_ チェンジセットが作られます: 俳優リストの俳優を映画レコードに追加する。

最後に、最新のチェンジセットを使用して映画と俳優のレコードを更新します:

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

これによって映画レコードが俳優と適切に関連付けられて、 `movie.actors` に事前ロードされていることがわかります。

同じアプローチを使って、映画に関連する新しい俳優を追加できます。 _保存された_ 俳優の構造体を `put_assoc/4` に渡す代わりに、単純に作成したい俳優を表す構造体を渡します:

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

"2"というIDと割り当てた値を持った俳優が作られたことを確認できました。

次のセクションでは、関連付けたレコードにクエリを実行する方法を学びます。
