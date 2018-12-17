---
version: 2.1.0
title: Basics
---

Ecto是Elixir官方提供的数据库包装和集成查询语言的项目。 使用Ecto，我们可以创建迁移，定义schema，插入和更新记录，以及查询数据。

{% include toc.html %}

### 适配器

Ecto supports different databases through the use of adapters.  A few examples of adapters are:
Ecto通过使用适配器可以支持不同的数据库。 适配器的一些示例是：

* PostgreSQL
* MySQL
* SQLite

For this lesson we'll configure Ecto to use the PostgreSQL adapter.
在本课中，我们将使用PostgreSQL适配器来配置Ecto。

### 开始

Through the course of this lesson we'll cover three parts to Ecto:
在本课程中，我们将介绍Ecto的以下三个部分：
* The Repository — provides the interface to our database, including the connection
* Repository - 提供数据库的接口，包括连接
* Migrations — a mechanism to create, modify, and destroy database tables and indexes
* Migrations - 一种创建，修改和销毁数据库表和索引的机制
* Schemas — specialized structs that represent database table entries
* Schemas - 表示数据库表实例的特殊结构

To start we'll create an application with a supervision tree.
首先，让我们创建一个应用程序

```shell
$ mix new friends --sup
$ cd friends
```

Add the ecto and postgrex package dependencies to your `mix.exs` file.

将ecto和postgrex包依赖项添加到 `mix.exs` 文件中

```elixir
  defp deps do
    [
      {:ecto, "~> 2.0"},
      {:postgrex, "~> 0.11"}
    ]
  end
```

Fetch the dependencies using
使用下述命令安装依赖项

```shell
$ mix deps.get
```

#### 创建一个Repository

A repository in Ecto maps to a datastore such as our Postgres database.
All communication to the database will be done using this repository.

Ecto中的存储库映射到数据存储区，例如Postgres数据库。
所有与数据库的通信都将使用此存储库完成。

通过运行以下命令创建一个Repository:

```shell
$ mix ecto.gen.repo -r Example.Repo
```

This will generate the configuration required in `config/config.exs` to connect to a database including the adapter to use.
This is the configuration file for our `Example` application

上述命令会生成 `config/config.exs` 所需的配置，用来连接到我们要使用的数据库。
这是我们 `Example` 应用程序的配置文件

```elixir
config :friends, Example.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "friends_repo",
  username: "postgres",
  password: "",
  hostname: "localhost"
```

This configures how Ecto will connect to the database.
Note how we chose the `Ecto.Adapters.Postgres` adapter.
这个配置决定Ecto如何连接到数据库。
注意我们为什么选择 `Ecto.Adapters.Postgres` 适配器。

It also creates a `Example.Repo` module inside `lib/friends/repo.ex`
同时它还在 `lib/friends/repo.ex` 中创建了一个 `Example.Repo` 模块

```elixir
defmodule Example.Repo do
  use Ecto.Repo, otp_app: :friends
end
```

We'll use the `Example.Repo` module to query the database. We also tell this module to find its database configuration information in the `:friends` Elixir application.
我们将使用 `Example.Repo` 模块来查询数据库。 我们还告诉该模块在 `:friends` 应用程序中查找其对应的数据库配置信息。

Next, we'll setup the `Example.Repo` as a supervisor within our application's supervision tree in `lib/friends/application.ex`.
This will start the Ecto process when our application starts.

接下来，我们将在 `lib/friends/application.ex` 中的应用程序 supervision 树中设置`Example.Repo`作为 supervisor。
这将在我们的应用程序启动时启动Ecto进程。

```elixir
  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      Example.Repo,
    ]

  ...
```

After that we'll need to add the following line to our `config/config.exs` file:

之后我们需要在 `config/config.exs` 文件中添加以下代码：

```elixir
config :friends, ecto_repos: [Example.Repo]
```

This will allow our application to run ecto mix commands from the commandline.
这将允许您的应用程序从命令行运行ecto mix命令。

We're all done configuring the repository!
我们都完成了配置存储库！
We can now create the database inside of postgres with this command:

我们现在可以使用以下命令在postgres中创建数据库：

```shell
$ mix ecto.create
```

Ecto will use the information in the `config/config.exs` file to determine how to connect to Postgres and what name to give the database.
Ecto将使用 `config/config.exs` 文件中的信息来确定如何连接到配置信息终提供名称的Postgres数据库。
If you receive any errors, make sure that the configuration information is correct and that your instance of postgres is running.

如果收到任何错误，请确保配置信息正确并且您的postgres实例正在运行。

### Migrations

To create and modify tables inside the postgres database Ecto provides us with migrations.
Each migration describes a set of actions to be performed on our database, like which tables to create or update.

要在postgres数据库中创建和修改表，Ecto为我们提供了migrations。
每个migration都描述了我们要对数据库执行的一组操作，比如要创建或更新的表。

Since our database doesn't have any tables yet, we'll need to create a migration to add some.
The convention in Ecto is to pluralize our tables so for application we'll need a `people` table, so let's start there with our migrations.

由于目前我们的数据库还没有任何表，所以我们需要创建一个migration来添加一些。
Ecto中的约定是将表格复数化，因此对于应用程序，我们需要一个 `people` 表，所以让我们从migrations开始。

The best way to create migrations is the mix `ecto.gen.migration <name>` task, so in our case let's use:

创建migration的最佳方法是执行 `mix ecto.gen.migration <name>` 任务，所以在我们的例子中使用如下命令：

```shell
$ mix ecto.gen.migration create_people
```

This will generate a new file in the `priv/repo/migrations` folder containing timestamp in the filename.
If we navigate to our directory and open the migration we should see something like this:

这将在 `priv/repo/migrations` 文件夹中生成一个新文件，其中文件名中包含一个时间戳。
如果我们打开该文件，我们应该看到如下内容：

```elixir
defmodule Example.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do

  end
end
```

Let's start by modifying the `change/0` function to create a new table `people` with `name` and `age`:
让我们首先修改 `change/0` 函数来创建一个带有 `name` 和 `age` 字段的新的 `people` 表：

```elixir
defmodule Example.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do
    create table(:people) do
      add :name, :string, null: false
      add :age, :integer, default: 0
    end
  end
end
```

You can see above we've also defined the column's data type.
Additionally, we've included `null: false` and `default: 0` as options.

您可以在上面看到我们还定义了列的数据类型。
另外，我们还包括 `null:false` 和 `default：0` 作为另外配置项。

Let's jump to the shell and run our migration:
让我们跳转到shell并运行我们的migration：

```shell
$ mix ecto.migrate
```

### Schemas

Now that we've created our initial table we need to tell Ecto more about it, part of how we do that is through schemas.
A schema is a module that defines mappings to the underlying database table's fields.

现在我们已经创建了初始化了表，接下来需要告诉Ecto更多关于它的部分内容，我们如何通过schema进行操作。
什么是schema呢？schema是定义底层数据库表的字段的映射的模块。

While Ecto favors pluralize database table names, the schema is typically singular, so we'll create a `Person` schema to accomplany our table.

虽然Ecto支持复数的数据库表名，但schema通常是单数的，因此我们将创建一个包含 `Person` 的schema来包含我们的表。

让我们在 `lib/friends/person.ex` 文件中创建新的 schema:

```elixir
defmodule Example.Person do
  use Ecto.Schema

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

Here we can see that the `Example.Person` module tells Ecto that this schema relates to the `people` table and that we have two columns: `name` which is a string and `age`, an integer with a default of `0`.

在这里我们可以看到 `Example.Person` 模块告诉Ecto这个schema与 `people` 表有关，我们有两列：`name` 是一个字符串和一个默认值为整数 `0` 的 `age` 列。

Let's take a peek at our schema by opening `iex` and creating a new person:

让我们通过`iex`并创建一个新person来看看我们的schema长啥样：

```shell
iex> %Example.Person{}
%Example.Person{age: 0, name: nil}
```

As expected we get a new `Person` with the default value applied to `age`.
Now let's create a "real" person:

正如预期的那样，我们得到一个新的默认值应用于 `age` 的 `Person`，。
现在让我们创建一个 “真正“ 的 person：

```shell
iex> person = %Example.Person{name: "Tom", age: 11}
%Example.Person{age: 11, name: "Tom"}
```

Since schemas are just structs, we can interact with our data like we're used to:
由于schemas只是结构，我们可以像以前一样与我们的数据进行交互：

```elixir
iex> person.name
"Tom"
iex> Map.get(person, :name)
"Tom"
iex> %{name: name} = person
%Example.Person{age: 11, name: "Tom"}
iex> name
"Tom"
```

Similarly, we can update our schemas just as we would any other map or struct in Elixir:

同样，我们可以像在Elixir中的其他map或结构一样去更新我们的schema：

```elixir
iex> %{person | age: 18}
%Example.Person{age: 18, name: "Tom"}
iex> Map.put(person, :name, "Jerry")
%Example.Person{age: 11, name: "Jerry"}
```

In our next lesson on Changesets, we'll look at how to validate our data changes and finally how to persist them to
our database.

在我们关于Changesets的下一课中，我们将研究如何验证我们的数据更改以及最终如何将其保存到数据库中。
