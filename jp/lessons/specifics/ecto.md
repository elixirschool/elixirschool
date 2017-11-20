---
version: 0.9.1
title: Ecto
---

Ectoは公式のElixirプロジェクトで、データベースのラッパと、総合的なクエリ言語を提供します。Ectoを用いることで、マイグレーションの作成やモデルの定義、レコードの挿入や更新、問合せが行えるようになります。

{% include toc.html %}

## セットアップ

最初に、Ectoとデータベースのアダプタをプロジェクトの`mix.exs`に含める必要があります。対応しているデータベースアダプタの一覧はEctoのREADMEにある[Usage](https://github.com/elixir-lang/ecto/blob/master/README.md#usage)の項で見つけることができます。今回の例ではPostgreSQLを使用します:

```elixir
defp deps do
  [{:ecto, "~> 2.1.4"}, {:postgrex, ">= 0.13.4"}]
end
```

これでEctoとアダプタをapplicationのリストに追加できます:

```elixir
def application do
  [applications: [:ecto, :postgrex]]
end
```

### リポジトリ

最後に、プロジェクトのリポジトリ、すなわちデータベースのラッパを作成する必要があります。これは`mix ecto.gen.repo`タスクで行うことができます。EctoのMixタスクについては次で扱います。作成されたリポジトリ(Repoモジュール)は`lib/<project name>/repo.ex`内に置かれます:

```elixir
defmodule ExampleApp.Repo do
  use Ecto.Repo, otp_app: :example_app
end
```

### スーパーバイザ

Repoを作成したら、スーパーバイザツリーを設定する必要があります。これは通常`lib/<project name>.ex`内にあります。

重要なので注記しておきますと、Repoはスーパーバイザとして、`worker/3` _ではなく_ `supervisor/3`を用いて設定されます。アプリケーションの生成時に`--sup`フラグを付けていれば、この設定はほとんど済んでいます:

```elixir
defmodule ExampleApp.App do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(ExampleApp.Repo, [])
    ]

    opts = [strategy: :one_for_one, name: ExampleApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

スーパーバイザについてのさらなる情報は、[OTPスーパーバイザ](../../advanced/otp-supervisors)レッスンを確認してください。

### 設定

Ectoを設定するには、`config/config.exs`に項目を追加する必要があります。ここで、リポジトリやアダプタ、データベース、アカウント情報を記述します。

```elixir
config :example_app, ExampleApp.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "example_app",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
```

## Mixタスク

Ectoには、データベースと連携するための役に立つMixタスクがいくつかあります:

```shell
mix ecto.create         # リポジトリに記憶域を作成する
mix ecto.drop           # リポジトリの記憶域を削除する
mix ecto.gen.migration  # リポジトリの新しいマイグレーションを生成する
mix ecto.gen.repo       # 新しいリポジトリを生成する
mix ecto.migrate        # リポジトリのマイグレーションを実行する
mix ecto.rollback       # リポジトリのマイグレーションを巻き戻す(ロールバックする)
```

## マイグレーション

マイグレーションを作成する最も良い方法は`mix ecto.gen.migration <name>`タスクです。ActiveRecordを使ったことがあれば、馴染みがあるでしょう。

ユーザテーブルのマイグレーションを見ていくことから始めましょう:

```elixir
defmodule ExampleApp.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:username, :string, unique: true)
      add(:encrypted_password, :string, null: false)
      add(:email, :string)
      add(:confirmed, :boolean, default: false)

      timestamps
    end

    create(unique_index(:users, [:username], name: :unique_usernames))
  end
end
```

初期状態ではEctoは自動でインクリメントする主キー`id`を作成します。この例では標準的な`change/0`コールバックを用いていますが、Ectoはより粒度の細かい制御が必要な場合のために、`up/0`と`down/0`にも対応しています。

思った通りかもしれませんが、`timestamps`をマイグレーションに加えると、`inserted_at`と`updated_at`が作成、管理されます。

この新しいマイグレーションを適用するには`mix ecto.migrate`を実行してください。

マイグレーションのさらなる情報はEctoドキュメントの[Ecto.Migration](http://hexdocs.pm/ecto/Ecto.Migration.html#content)の項を参照してください。

## モデル

マイグレーションが作成されたので、モデルへ移ります。モデルはスキーマ、ヘルパーメソッド、そしてチェンジセットを定義します。チェンジセットについては次の項で扱います。

まずはマイグレーション用のモデルがどういったものかを見てみましょう:

```elixir
defmodule ExampleApp.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:username, :string)
    field(:encrypted_password, :string)
    field(:email, :string)
    field(:confirmed, :boolean, default: false)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)

    timestamps
  end

  @required_fields ~w(username encrypted_password email)
  @optional_fields ~w()

  def changeset(user, params \\ :empty) do
    user
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:username)
  end
end
```

モデル内で定義するスキーマはマイグレーションで記述したものを厳密に表現します。ここではデータベースのフィールドの他に、2つの仮想的なフィールドも加えています。仮想フィールドはデータベースには保存されませんが、バリデーションのような仕組みに役立てることができます。実際の仮想フィールドは[Changeset](#section-8)の項で見ることにします。

## クエリ

リポジトリに問合せができるようになる前に、Query APIをインポートする必要がありますが、今のところは`from/2`をインポートするだけで良いです:

```elixir
import Ecto.Query, only: [from: 2]
```

Query APIの公式ドキュメントは[Ecto.Query](http://hexdocs.pm/ecto/Ecto.Query.html)で見つけることができます。

### 基本

Ectoは素晴らしいQuery DSLを提供しており、問合せをわかりやすく表現することができます。全ての確認済みアカウントのユーザ名を探す場合では、このような感じのクエリを用いることができるでしょう:

```elixir
alias ExampleApp.{Repo, User}

query =
  from(
    u in User,
    where: u.confirmed == true,
    select: u.username
  )

Repo.all(query)
```

`all/2`に加えて、Repoは`one/2`や`get/3`、`insert/2`、`delete/2`を含む多くのコールバックを提供しています。コールバックの全ての一覧は[Ecto.Repo#callbacks](http://hexdocs.pm/ecto/Ecto.Repo.html#callbacks)で見つけることができます。

### Count

確認済みのユーザ数を集計したい場合は、`count/1`を使うことができます:

```elixir
query =
  from(
    u in User,
    where: u.confirmed == true,
    select: count(u.id)
  )
```

重複値を除いて集計したい場合は `count/2` 関数があります:

```elixir
query =
  from(
    u in User,
    where: u.confirmed == true,
    select: count(u.id, :distinct)
  )
```



### Group By

ユーザを確認済みかどうかでグループ化するには`group_by`オプションを加えます:

```elixir
query =
  from(
    u in User,
    group_by: u.confirmed,
    select: [u.confirmed, count(u.id)]
  )

Repo.all(query)
```

### Order By

ユーザを作成日で順序付け:

```elixir
query =
  from(
    u in User,
    order_by: u.inserted_at,
    select: [u.username, u.inserted_at]
  )

Repo.all(query)
```

`DESC`で順序付けするには:

```elixir
query =
  from(
    u in User,
    order_by: [desc: u.inserted_at],
    select: [u.username, u.inserted_at]
  )
```

### Join

ユーザに関連付いたプロフィールがあると仮定して、全ての確認済みアカウントのプロフィールを探しましょう:

```elixir
query =
  from(
    p in Profile,
    join: u in assoc(p, :user),
    where: u.confirmed == true
  )
```

### Fragment

特定のデータベースに用意されている関数を使う必要があるような場合など、Query APIでは事足りない場合もたまにあります。`fragment/1`関数はこうした目的のためにあります:

```elixir
query =
  from(
    u in User,
    where: fragment("downcase(?)", u.username) == ^username,
    select: u
  )
```

さらなるクエリ例については[phoenix-examples/ecto_query_library](https://github.com/phoenix-examples/ecto_query_library)で見つけることができます。

## チェンジセット

前の項ではデータの検索方法を学習しましたが、挿入や更新についてはどうすれば良いでしょうか。このためには、Changesetが必要となります。

Changesetはモデルが変更される際のフィルタやバリデーション、制約の維持を担います。

以下の例では、ユーザアカウントを作成する際のチェンジセットに注目します。始めに、モデルを更新する必要があります:

```elixir
defmodule ExampleApp.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Comeonin.Bcrypt, only: [hashpwsalt: 1]

  schema "users" do
    field(:username, :string)
    field(:encrypted_password, :string)
    field(:email, :string)
    field(:confirmed, :boolean, default: false)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)

    timestamps
  end

  @required_fields ~w(username email password password_confirmation)
  @optional_fields ~w()

  def changeset(user, params \\ :empty) do
    user
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:password, min: 8)
    |> validate_password_confirmation()
    |> unique_constraint(:username, name: :email)
    |> put_change(:encrypted_password, hashpwsalt(params[:password]))
  end

  defp validate_password_confirmation(changeset) do
    case get_change(changeset, :password_confirmation) do
      nil ->
        password_incorrect_error(changeset)

      confirmation ->
        password = get_field(changeset, :password)
        if confirmation == password, do: changeset, else: password_mismatch_error(changeset)
    end
  end

  defp password_mismatch_error(changeset) do
    add_error(changeset, :password_confirmation, "Passwords does not match")
  end

  defp password_incorrect_error(changeset) do
    add_error(changeset, :password, "is not valid")
  end
end
```

`changeset/2`関数を改良し、`validate_password_confirmation/1`と `password_mismatch_error/1`と`password_incorrect_error/1`の3つのヘルパー関数を追加しました。

`changeset/2`の名前から推測されるように、これは新しいチェンジセットを作成します。この中で、`cast/4`を用いて、一連の必要あるいはオプションのフィールドからパラメータをチェンジセットへと変換します。次に、チェンジセットのパスワードの長さと、独自実装した関数を用いてパスワード確認のマッチ、そしてユーザ名が一意であるかを検証します。最後に、実際のデータベースのパスワードフィールドを更新します。ここで、チェンジセットにある値を更新するために、`put_change/3`を使用しています。

`User.changeset/2`は比較的簡単に使用できます:

```elixir
alias ExampleApp.{User, Repo}

pw = "passwords should be hard"

changeset =
  User.changeset(%User{}, %{
    username: "doomspork",
    email: "sean@seancallan.com",
    password: pw,
    password_confirmation: pw
  })

case Repo.insert(changeset) do
  {:ok, model}        -> # Inserted with success
  {:error, changeset} -> # Something went wrong
end
```

おしまいです！これで、いくつかのデータを保存する用意ができました。
