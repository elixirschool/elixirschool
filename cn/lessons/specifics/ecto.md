---
version: 0.9.1
title: Ecto
---

Ecto 是 Elixir 官方维护的一个项目，它提供了对数据库的封装以及一个自带的查询语言。通过 Ecto 我们可以创建迁移，定义模型，添加／更新或查询记录。

{% include toc.html %}

## 安装

首先我们将 Ecto 和所需的数据库适配器加入 `mix.exs` 中。你可以在 Ecto 的 README 中找到其[支持的数据库适配器](https://github.com/elixir-lang/ecto/blob/master/README.md#usage)。在这个例子中我们使用 PostgreSQL：

```elixir
defp deps do
  [{:ecto, "~> 2.1.4"}, {:postgrex, ">= 0.13.2"}]
end
```

然后将 Ecto 和适配器加入应用列表：

```elixir
def application do
  [applications: [:ecto, :postgrex]]
end
```

### Repository

最后我们需要创建这个项目的 repository，或者说数据库封装。这可以通过 `mix ecto.gen.repo` 来完成。我们稍后会讨论 Ecto 的 mix 命令集。Repo 的代码常见于 `lib/<project name>/repo.ex`：

```elixir
defmodule ExampleApp.Repo do
  use Ecto.Repo, otp_app: :example_app
end
```

### Supervisor

创建了 Repo 后我们需要设置 supervisor 树，通常位于 `lib/<project name>.ex`。

值得注意的是我们通过 `supervisor/3` 将 Repo 配置为一个 supervisor 而不是 `worker/3`。如果附加 `--sup` 参数，那么生成应用时这部分代码基本都生成好了。

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

关于 Supervisor 可以参阅 [OTP Supervisors](../../advanced/otp-supervisors) 的课程。

### 配置

Ecto 的配置需要写在 `config/config.exs` 中。需要指定使用了哪个 repository，哪个 adapter，哪个数据库以及用户信息等等：

```elixir
config :example_app, ExampleApp.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "example_app",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
```

## Mix 任务

Ecto 包含了一些便于管理数据库的 mix 任务：

```shell
mix ecto.create         # Create the storage for the repo
mix ecto.drop           # Drop the storage for the repo
mix ecto.gen.migration  # Generate a new migration for the repo
mix ecto.gen.repo       # Generate a new repository
mix ecto.migrate        # Run migrations up on a repo
mix ecto.rollback       # Rollback migrations from a repo
```

## Migrations

创建 migration 最好是使用 `mix ecto.gen.migration <name>` 任务。如果你熟悉 ActiveRecord 那么这些用起来都差不多。

我们先来看看创建用户表时的 migration：

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

Ecto 默认会创建一个自动增长的主键 `id`。这里我们使用了默认的 `change/0` 回调函数，同时 Ecto 也支持通过 `up/0` 和 `down/0` 更好地控制粒度。

你可能已经猜到了，调用 `timestamps` 会自动创建和管理 `inserted_at` 以及 `updated_at`。

运行 `mix ecto.migrate` 来执行新的 migration。

参阅 [Ecto.Migration](http://hexdocs.pm/ecto/Ecto.Migration.html#content) 的文档来了解更多 migration 的细节。

## 模型

有了 migration 之后我们继续来看模型 (model)。模型里可以定义我们的 schema，辅助函数以及变更集 (changeset)。我们将在下一章节更详细地讲解变更集的内容。

现在先看看刚刚的 migration 对应的模型是怎样的：

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

我们在模型中定义的 schema 和 migration 中声明的很相似。除了数据库中的字段我们还附加了两个虚拟字段。虚拟字段 (virtual field) 不会写入数据库但可以帮助验证等等。在下面关于变更集的章节中我们会看到虚拟字段的应用。

## 查询

首先我们需要引入 Query API。目前只要引入 `from/2` 就可以了：

```elixir
import Ecto.Query, only: [from: 2]
```

官方的文档请查阅 [Ecto.Query](http://hexdocs.pm/ecto/Ecto.Query.html)。

### 基础

Ecto 提供了一套功能强大同时语法清晰的查询用 DSL。比如要找到所有已经确认过的用户的用户名，我们可以这样写：

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

除了 `all/2`，Repo 还提供了一系列回调函数，如 `one/2`、`get/3`、`insert/2` 和 `delete/2`。完整的列表见于 [Ecto.Repo#callbacks](http://hexdocs.pm/ecto/Ecto.Repo.html#callbacks)

### Count

如果我们要统计已经确认账户信息的用户个数，可以使用 `count/1`：

```elixir
query =
  from(
    u in User,
    where: u.confirmed == true,
    select: count(u.id)
  )
```

`count/2` 函数可以统计不同元素的个数：

```elixir
query =
  from(
    u in User,
    where: u.confirmed == true,
    select: count(u.id, :distinct)
  )
```

### Group By

要按照确认状态分组我们使用 `group_by`：

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

根据创建时间排序也很直观：

```elixir
query =
  from(
    u in User,
    order_by: u.inserted_at,
    select: [u.username, u.inserted_at]
  )

Repo.all(query)
```

降序排序：

```elixir
query =
  from(
    u in User,
    order_by: [desc: u.inserted_at],
    select: [u.username, u.inserted_at]
  )
```

### Joins

假如我们的用户有关联的档案，我们可以这样来查询所有已确认的用户的档案：

```elixir
query =
  from(
    p in Profile,
    join: u in assoc(p, :user),
    where: u.confirmed == true
  )
```

### 片段 (Fragments)

有时候我们需要某个数据库的特殊函数，而 Query 又不提供这个函数时我们可以使用 `fragment/1`：

```elixir
query =
  from(
    u in User,
    where: fragment("downcase(?)", u.username) == ^username,
    select: u
  )
```

在 [Ecto.Query.API](http://hexdocs.pm/ecto/Ecto.Query.API.html) 的模块文档中可以找到更多查询的例子。

## 变更集 (Changeset)

上一章节我们学习了如何获取数据，那么如何插入和更新数据呢？这就要用到变更集 (changeset) 了。

变更集可以帮助我们进行数据的过滤，模型的验证以及约束的维护。

这个例子里我们看看如何为账户创建实现一个变更集。首先我们更新模型：

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

我们改善了 `changeset/2` 函数并添加了三个新的辅助函数：`validate_password_confirmation/1`、`password_mismatch_error/1` 和 `password_incorrect_error/1`。

如同函数名，`changeset/2` 可以为我们创建一个新的变更集。首先我们用 `cast/4` 将参数转换成一个有若干必要字段和可选字段的变更集。接下来我们验证了密码的长度，并通过新编写的函数验证用户输入的(两个)密码是否吻合，我们还约束了用户名的唯一性。最后我们使用 `put_change/3` 更新了变更集中的一个值。

使用 `User.changeset/2` 还比较直观：

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

现在你应该已经准备好和数据（库）打交道了！
