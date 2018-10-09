---
version: 1.3.0
title: Ecto
---

Ecto is an official Elixir project providing a database wrapper and integrated query language. With Ecto we're able to create migrations, define schemas, insert and update records, and query them.

{% include toc.html %}

### Adapters

Ecto supports different databases through the use of adapters.  A few examples of adapters are:

* PostgreSQL
* MySQL
* SQLite

In this tutorial, we'll configure Ecto to use a PostgresQL adapter.

### Working with Ecto

We'll cover 3 parts of Ecto in this tutorial:

* Repository
    * Connects to the database
* Migration
    * Describes how to create or update tables in the database
* Schema
    * Maps information in database tables to structs

To start, create an application with a supervision tree.  
```shell
$ mix new friends --sup
$ cd friends
```

This creates an elixir application named `Friends`.

Add the ecto and postgrex package dependencies to your `mix.exs` file.

```elixir
  defp deps do
    [
      {:ecto, "~> 2.0"},
      {:postgrex, "~> 0.11"}
    ]
  end
```

Fetch the dependencies using

```shell
$ mix deps.get
```

#### Creating a Repository

A repository in Ecto maps to a datastore such as our Postgres database.  All communication to the database will be done using this repository.

Set up a repository by running:
```shell
$ mix ecto.gen.repo -r Friends.Repo
```

This will generate the configuration required in `config/config.exs` to connect to a database including the adapter to use.  This is the configuration file for our `Friends` application

```elixir
config :friends, Friends.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "friends_repo",
  username: "postgres",
  password: "",
  hostname: "localhost"
```

This configures how Ecto will connect to the database.  Note how we chose the `Ecto.Adapters.Postgres` adapter.

It also creates a `Friends.Repo` module inside `lib/friends/repo.ex`

```elixir
defmodule Friends.Repo do
  use Ecto.Repo, otp_app: :friends
end
```

We'll use the `Friends.Repo` module to query the database. We also tell this module to find its database configuration information in the `:friends` Elixir application.

Next, we'll setup the `Friends.Repo` as a supervisor within our application's supervision tree in `lib/friends/application.ex`.  This will start the Ecto process when our application starts.

```elixir
  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      Friends.Repo,
    ]

  ...
```

After that we'll need to add the following line to our `config/config.exs` file:
```elixir
config :friends, ecto_repos: [Friends.Repo]
```

This will allow our application to run ecto mix commands from the commandline.

We're all done configuring the repository!  We can now create the database inside of postgres with this command:
```shell
$ mix ecto.create
```

Ecto will use the information in the `config/config.exs` file to determine how to connect to postgres and what name to give the database.  

If you receive any errors, make sure that the configuration information is correct and that your instance of postgres is running.

### Migrations

To create and modify tables inside the postgres database, Ecto has *migrations*.  Each migration describes how the database tables should change.

Our database doesn't have any tables yet.  To get started we'll create a migration that will create a *people* table.  Note that when naming a migration or table in ecto you should use the plural form of the word.

We can use the following command to create a migration
```shell
$ mix ecto.gen.migration create_people
```

This will generate a new file in the `priv/repo/migrations` folder with the following contents.

```elixir
defmodule Friends.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do

  end
end
```

We can edit the change function to tell Ecto to create a table called *people* with a *name* column and *age* column.  You can also see that we define the data type of *name* to be a *string* and *age* to be an *int*.

```elixir
defmodule Friends.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do
    create table(:people) do
      add :name, :string
      add :age, :integer
    end
  end
end
```

If we run this migration, then a *people* table will be created with a *name* and *age* column:

```shell
mix ecto.migrate
```

### Schemas

Schemas define how data from a database table or view maps to an elixir struct.  Tables are created using the plural form of the word but schemas should use the singular form.

We'll create a *person* schema to match our people table.  This way, when we query our database, we can receive a collection of *person* elixir structs back.

Let's create the schema at `lib/friends/person.ex`:

```elixir
defmodule Friends.Person do
  use Ecto.Schema

  schema "people" do
    field :name, :string
    field :age, :integer
  end
end
```

Here you can see that the `Friends.Person` schema maps to the `people` table and the *name* and *age* fields inside of it.

If we open the mix console we can take a look at our `Friends.Person` schema:
```shell
$ iex -S mix
```

We can create an instance of our schema with the following:
```elixir
person = %Friends.Person{name: "Tom", age: 11}
```

Then, we can retrieve the name from the schema like any other struct in Elixir:
```elixir
person.name
```
