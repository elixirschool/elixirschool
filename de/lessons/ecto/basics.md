---
version: 2.4.0
title: Basics
---

Ecto ist ein offizielles Elixir-Projekt, das einen Datenbank-Wrapper und eine integrierte Abfragesprache bereitstellt. Mit Ecto sind wir in der Lage, Migrationen zu erstellen, Schemmas zu definieren, Datensätze einzufügen, zu aktualisieren und diese abzufragen.

{% include toc.html %}

### Adapter

Durch den Einsatz von Adaptern unterstützt Ecto verschiedene Datenbanken. Hier ein unvollständiger Auszug der Adapter:

* PostgreSQL
* MySQL
* SQLite

Für diese Lektion konfigurieren wir Ecto mit dem PostgreSQL Adapter.

### Erste Schritte

Im Laufe dieser Lektion werden wir drei Teile behandeln:

* Das Repository - bietet die Schnittstelle zu unserer Datenbank, einschließlich der Verbindung
* Migrationen - ein Mechanismus zum Erstellen, Ändern und Löschen von Datenbanktabellen und Index
* Schemas - spezialisierte Structs, die Datenbanktabelleneinträge repräsentieren

Zu Beginn erstellen wir eine Anwendung mit einem Supervisor-Baum.

```shell
$ mix new friends --sup
$ cd friends
```

Füge die Ecto und Postgrex Paket-Abhängigkeit zu deiner `mix.exs` Datei hinzu.

```elixir
  defp deps do
    [
      {:ecto_sql, "~> 3.2"},
      {:postgrex, "~> 0.15"}
    ]
  end
```

Lade die Pakete herunter.

```shell
$ mix deps.get
```

#### Ein Repository erstellen

In Ecto repräsentiert ein Repository einen Datenspeicher wie unsere Postgres-Datenbank.
Die gesamte Kommunikation mit der Datenbank wird über dieses Repository abgewickelt.

So erstellst du ein neues Repository:

```shell
$ mix ecto.gen.repo -r Friends.Repo
```

Dies erzeugt die Konfiguration, welche für um eine Verbindung zu einer Datenbank notwendig ist. Einschließlich des zu verwendenden Adapters.
So sieht Konfigurationsdatei für unsere Anwendung `Friends` aus.


```elixir
config :friends, Friends.Repo,
  database: "friends_repo",
  username: "postgres",
  password: "",
  hostname: "localhost"
```

Auf diese weise verbindet sich Ecto mit der Datenbank. Möglicherweise müssen Sie Ihre Datenbank so konfigurieren, dass die Zugangsdaten übereinstimmen.

Zusätzlich wird das `Friends.Repo` Modul erstellt unter `lib/friends/repo.ex`.

```elixir
defmodule Friends.Repo do
  use Ecto.Repo, 
    otp_app: :friends,
    adapter: Ecto.Adapters.Postgres
end
```

We'll use the `Friends.Repo` module to query the database. We also tell this module to find its database configuration information in the `:friends` Elixir application and we chose the `Ecto.Adapters.Postgres` adapter.

Next, we'll setup the `Friends.Repo` as a supervisor within our application's supervision tree in `lib/friends/application.ex`.
This will start the Ecto process when our application starts.

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

We're all done configuring the repository!
We can now create the database inside of postgres with this command:

```shell
$ mix ecto.create
```

Ecto will use the information in the `config/config.exs` file to determine how to connect to Postgres and what name to give the database.

If you receive any errors, make sure that the configuration information is correct and that your instance of postgres is running.

### Migrations

To create and modify tables inside the postgres database Ecto provides us with migrations.
Each migration describes a set of actions to be performed on our database, like which tables to create or update.

Since our database doesn't have any tables yet, we'll need to create a migration to add some.
The convention in Ecto is to pluralize our tables so for application we'll need a `people` table, so let's start there with our migrations.

The best way to create migrations is the mix `ecto.gen.migration <name>` task, so in our case let's use:

```shell
$ mix ecto.gen.migration create_people
```

This will generate a new file in the `priv/repo/migrations` folder containing timestamp in the filename.
If we navigate to our directory and open the migration we should see something like this:

```elixir
defmodule Friends.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do

  end
end
```

Let's start by modifying the `change/0` function to create a new table `people` with `name` and `age`:

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

You can see above we've also defined the column's data type.
Additionally, we've included `null: false` and `default: 0` as options.

Let's jump to the shell and run our migration:

```shell
$ mix ecto.migrate
```

### Schemas

Now that we've created our initial table we need to tell Ecto more about it, part of how we do that is through schemas.
A schema is a module that defines mappings to the underlying database table's fields.

While Ecto favors pluralize database table names, the schema is typically singular, so we'll create a `Person` schema to accompany our table.

Let's create our new schema at `lib/friends/person.ex`:

```elixir
defmodule Friends.Person do
  use Ecto.Schema

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

Here we can see that the `Friends.Person` module tells Ecto that this schema relates to the `people` table and that we have two columns: `name` which is a string and `age`, an integer with a default of `0`.

Let's take a peek at our schema by opening `iex -S mix` and creating a new person:

```elixir
iex> %Friends.Person{}
%Friends.Person{age: 0, name: nil}
```

As expected we get a new `Person` with the default value applied to `age`.
Now let's create a "real" person:

```elixir
iex> person = %Friends.Person{name: "Tom", age: 11}
%Friends.Person{age: 11, name: "Tom"}
```

Since schemas are just structs, we can interact with our data like we're used to:

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

Similarly, we can update our schemas just as we would any other map or struct in Elixir:

```elixir
iex> %{person | age: 18}
%Friends.Person{age: 18, name: "Tom"}
iex> Map.put(person, :name, "Jerry")
%Friends.Person{age: 18, name: "Jerry"}
```

In our next lesson on Changesets, we'll look at how to validate our data changes and finally how to persist them to
our database.
