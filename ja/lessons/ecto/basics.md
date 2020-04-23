---
version: 2.4.0
title: 基本
---

Ectoはデータベースラッパーと統合クエリ言語を提供するElixirの公式なプロジェクトです。Ectoによりマイグレーション、スキーマの定義、レコードの挿入や更新、そしてそれらに対するクエリが可能になります。

{% include toc.html %}

### アダプタ

Ectoアダプタを使用することで異なるデータベースをサポートします。アダプタの例として以下のものがあります:

- PostgreSQL
- MySQL
- SQLite

このレッスンではPostgreSQLアダプタを使用するようにEctoを設定します。

### はじめに

このレッスンのコースを通して、私たちはEctoの3つの機能を学びます:

- レポジトリ - 接続を含むデータベースのインターフェースを提供します
- マイグレーション - データベースのテーブルとインデックスを作成、変更、そして削除するメカニズムを提供します
- スキーマ - データベースのテーブルのエントリーを表現する特別な構造体です

まずはスーパーバイザーツリーを持つアプリケーションを作ります。

```shell
$ mix new friends --sup
$ cd friends
```

`mix.exs` ファイルにectoとpostgrexパッケージの依存を追加します。

```elixir
  defp deps do
    [
      {:ecto_sql, "~> 3.2"},
      {:postgrex, "~> 0.15"}
    ]
  end
```

次のコマンドで依存を取得します。

```shell
$ mix deps.get
```

#### レポジトリの作成

EctoのレポジトリはPostgresデータベースのようなデータストアをマップします。
データベースとの全ての通信はこのレポジトリを使用して行われます。

次のコマンドを実行してレポジトリをセットアップしましょう:

```shell
$ mix ecto.gen.repo -r Friends.Repo
```

これは、使用するアダプタを含むデータベースとの接続にの中に必要な設定を `config/config.exs` の中に生成します。
これが `Friends` アプリケーションのための設定ファイルとなります。

```elixir
config :friends, Friends.Repo,
  database: "friends_repo",
  username: "postgres",
  password: "",
  hostname: "localhost"
```

これはEctoがどのようにデータベースと接続するかを構成します。

またこれは `lib/friends/repo.ex` の中に `Friends.Repo` を作ります。

```elixir
defmodule Friends.Repo do
  use Ecto.Repo, 
    otp_app: :friends,
    adapter: Ecto.Adapters.Postgres
end
```

データベースにクエリを発行するには `Friends.Repo` を使います。また、このモジュールに対してElixirアプリ `:friends` 内のデータベース接続情報を見つけるように指示を出し、adapterは `Ecto.Adapters.Postgres` を選択します。

次に、 `lib/friends/application.ex` の中で `Friends.Repo` をアプリケーションのスーパーバイザーツリーにおけるスーパーバイザーとして設定します。  
これによって、アプリケーション開始時にEctoプロセスを開始します。

```elixir
  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      Friends.Repo,
    ]

  ...
```

その後、 `config/config.exs` ファイルに次の行を追加する必要があります:

```elixir
config :friends, ecto_repos: [Friends.Repo]
```

これにより、アプリケーションがコマンドラインからEctoのmixコマンドを実行できるようになります。

レポジトリの設定は全て終わりました！
次のコマンドでPostgresの中にデータベースを作ることができます:

```shell
$ mix ecto.create
```

Ectoは `config/config.exs` ファイルの中の情報を使って、Postgresへの接続方法、そしてデータベースに与える名前を決定します。

もし何らかのエラーがあれば、接続情報が正しいこと、Postgresのインスタンスが実行されていることを確認してください。

### マイグレーション

Postgresデータベース内のテーブルの作成と更新をするために、Ectoはマイグレーションを提供しています。
それぞれのマイグレーションは、どのテーブルが作成されたり更新されるのかというような、データベースで実行されるアクションの集合を定義します。

私たちのデータベースはまだテーブルを持っていないので、何かを追加するマイグレーションを作る必要があります。
Ectoの慣習ではテーブルを複数形にすることから、私たちのアプリケーションでは `people` テーブルが必要なので、そこからマイグレーションを始めましょう。

マイグレーションを作るベストな方法は、mixの `ecto.gen.migration <name>` タスクなので、私たちの場合は次のように使いましょう:

```shell
$ mix ecto.gen.migration create_people
```

これは `priv/repo/migrations` フォルダの中にタイムスタンプを名前に含んだ新しいファイルを生成します。
ディレクトリに移動してマイグレーションを開くと、次のようなものが確認できるはずです:

```elixir
defmodule Friends.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do

  end
end
```

`name` と `age` を持った `people` テーブルを新たに作るために、 `change/0` 関数を修正することから始めましょう:

```elixir
defmodule Friends.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do
    create table(:people) do
      add :name, :string, null: false
      add :age, :integer, default: 0
    end
  end
end
```

上のコードではカラムのデータの型も定義していることが確認できるでしょう。
さらに、 `null: false` と `default: 0` をオプションとして加えました。

シェルに移動してマイグレーションを実行してみましょう:

```shell
$ mix ecto.migrate
```

### スキーマ

最初のテーブルを作成したところで、スキーマを通してどうするのかについて、Ectoにさらに詳細を伝える必要があります。
スキーマは、データベーステーブルのフィールドをマップするモジュールです。

Ectoはデータベーステーブルの名前を複数形とするのに対して、スキーマは通常単数形であるため、テーブルに合わせて `Person` というスキーマを作ります。

それでは新しいスキーマを `lib/friends/person.ex` に作ってみましょう。

```elixir
defmodule Friends.Person do
  use Ecto.Schema

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

この `Friends.Person` は、それが `people` テーブルと関連するものであることをEctoに伝え、stringの `name` とintegerでデフォルトが0の `age` という2つのカラムを持っていることがわかります。

`iex -S mix` を開いて新しい人を作ることで、このスキーマを覗いてみましょう:

```elixir
iex> %Friends.Person{}
%Friends.Person{age: 0, name: nil}
```

期待通りデフォルト値が適用された `age` を持つ `Person` ができました。
それでは"本当の"人を作ってみましょう:

```elixir
iex> person = %Friends.Person{name: "Tom", age: 11}
%Friends.Person{age: 11, name: "Tom"}
```

スキーマはただの構造体なので、これまでのようにデータを扱うことができます:

```elixir
iex> person.name
"Tom"
iex> Map.get(person, :name)
"Tom"
iex> %{name: name} = person
%Friends.Person{age: 11, name: "Tom"}
iex> name
"Tom"
```

同じように、Elixirの他のマップや構造体に対して行ったようにスキーマを更新できます:

```elixir
iex> %{person | age: 18}
%Friends.Person{age: 18, name: "Tom"}
iex> Map.put(person, :name, "Jerry")
%Friends.Person{age: 11, name: "Jerry"}
```

次のチェンジセットのレッスンでは、データの変更をバリデーションする方法と、最終的にそれらをデータベースに永続化する方法について見ていきます。
