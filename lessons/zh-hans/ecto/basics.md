---
version: 2.4.0
title: Basics
---

Ecto 是 Elixir 官方提供的数据库包装和集成查询语言的项目。 使用Ecto，我们可以创建 migrations，定义 schema，插入和更新记录，以及查询数据。

{% include toc.html %}

### 适配器

Ecto通过使用适配器可以支持不同的数据库。 一些常见的适配器的比如说：

* PostgreSQL
* MySQL
* SQLite

在本课中，我们将使用 PostgreSQL 适配器来配置 Ecto。

### 开始

在本课程中，我们将介绍有关 Ecto 的以下三部分：
* Repository - 提供数据库的接口，包括连接
* Migrations - 一种创建，修改和删除数据库表和索引的机制
* Schemas - 表示数据库表实例的特殊结构

首先，让我们创建一个带有 supervision 树应用程序

```shell
$ mix new friends --sup
$ cd friends
```

将 ecto 和 postgrex 包依赖项添加到 `mix.exs` 文件中

```elixir
  defp deps do
    [
      {:ecto_sql, "~> 3.2"},
      {:postgrex, "~> 0.15"}
    ]
  end
```

使用如下命令安装依赖项

```shell
$ mix deps.get
```

#### 创建一个 Repository


在 Ecto 中，一个 repository 是映射到数据存储区的，例如 Postgres 数据库。所有与数据库的通信都将使用该 repository 完成。

通过运行以下命令创建一个Repository:

```shell
$ mix ecto.gen.repo -r Friends.Repo
```

上述命令会在 `config/config.exs` 文件中生成所需的配置，用来连接到我们要使用的数据库。
这是我们 `Friends` 应用程序的配置文件

```elixir
config :friends, Friends.Repo,
  database: "friends_repo",
  username: "postgres",
  password: "",
  hostname: "localhost"
```

这个配置决定 Ecto 如何连接到数据库。

同时它还在 `lib/friends/repo.ex` 文件中创建了一个 `Friends.Repo` 模块

```elixir
defmodule Friends.Repo do
  use Ecto.Repo,
    otp_app: :friends,
    adapter: Ecto.Adapters.Postgres
end
```

我们将使用 `Friends.Repo` 模块来查询数据库。我们还告诉该模块如何在 `:friends` 应用程序中查找其对应的数据库配置信息，并且指定 `Ecto.Adapters.Postgres` 作为数据库适配器。

接下来，我们将在 `lib/friends/application.ex` 文件中的应用程序的 supervision 树中设置`Friends.Repo`作为 supervisor。
这将在我们的应用程序启动时启动Ecto进程。

```elixir
  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      Friends.Repo,
    ]

  ...
```

之后我们需要在 `config/config.exs` 文件中添加以下代码：

```elixir
config :friends, ecto_repos: [Friends.Repo]
```

这将允许您的应用程序在命令行中运行 ecto mix 命令。

至此，我们就完成了 repository 配置！

我们现在可以使用以下命令在 postgres 中创建数据库：

```shell
$ mix ecto.create
```

Ecto 将使用 `config/config.exs` 文件中的配置信息来确定如何连接到 Postgres 中对应的数据库。

如果收到任何错误，请确保配置信息正确并且您的 postgres 实例正在运行。

### Migrations

要在 postgres 数据库中创建和修改表，Ecto 为我们提供了 migrations。
每个 migration 都描述了我们要对数据库执行的一组操作，比如要创建或更新的表。

由于目前我们的数据库还没有任何表，所以我们需要创建一个 migration 来添加一些表。
Ecto 中的约定是将表格复数化，因此对于应用程序，我们需要一个 `people` 表，所以让我们从 migrations 开始。

创建 migrations 的最佳方法是执行 `mix ecto.gen.migration <name>` 任务，所以在我们的例子中使用如下命令：

```shell
$ mix ecto.gen.migration create_people
```

这将在 `priv/repo/migrations` 文件夹中生成一个文件名中包含一个时间戳的新文件。
如果我们打开该文件，我们可以看到如下内容：

```elixir
defmodule Friends.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do

  end
end
```

让我们首先修改 `change/0` 函数来创建一个带有 `name` 和 `age` 字段的新的 `people` 表：

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

您可以在上面看到我们定义了列的数据类型。另外，还包括 `null:false` 和 `default：0` 作为另外配置选项。

让我们跳转到 shell 并运行我们的 migration：

```shell
$ mix ecto.migrate
```

### Schemas

现在我们已经创建了初始化的表，接下来需要告诉 Ecto 更多关于它的部分内容，我们如何通过 schema 进行操作。
那么什么是 schema 呢？schema 是定义底层数据库表的字段的映射的模块。

虽然 Ecto 支持复数的数据库表名，但 schema 通常是单数的，因此我们将创建一个包含 `Person` 的 schema 来包含我们的表。

让我们在 `lib/friends/person.ex` 文件中创建新的 schema:

```elixir
defmodule Friends.Person do
  use Ecto.Schema

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

在这里我们可以看到 `Friends.Person` 模块告诉 Ecto 这个 schema 与 `people` 表有关，我们有两个字段：一个字符串类型的 `name` 字段和一个`age` 字段，并指定 `age` 的默认值为 `0`。


让我们通过 `iex -S mix` 并创建一个新 person 来看看我们的 schema 是啥样的：

```shell
iex> %Friends.Person{}
%Friends.Person{age: 0, name: nil}
```

正如预期的那样，我们得到一个新的`age` 为 0 的 `Person` 结构，
现在让我们创建一个 “真正“ 的 person：

```shell
iex> person = %Friends.Person{name: "Tom", age: 11}
%Friends.Person{age: 11, name: "Tom"}
```

由于 schemas 只是结构，我们可以像以前一样和我们的数据进行交互：

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

同样，我们可以像在 Elixir 中其他的 map 或 struct 一样去更新我们的 schemas：

```elixir
iex> %{person | age: 18}
%Friends.Person{age: 18, name: "Tom"}
iex> Map.put(person, :name, "Jerry")
%Friends.Person{age: 11, name: "Jerry"}
```

在我们关于 Changesets 的下一课中，我们将学习如何验证我们的数据更改以及最终如何将其保存到数据库中。
