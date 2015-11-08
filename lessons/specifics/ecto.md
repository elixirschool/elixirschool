# Ecto

Ecto is an official Elixir project providing a database wrapper and integrated query language.  While Ecto accomplished the same goals as ActiveRecord they do so in very different ways, try not to look for similarities. 

## Table of Contents

- [Setup](#setup)
	- [Repository](#repository)
	- [Configuration](#configuration)
- [Mix Tasks](#mix-tasks)
- [Migrations](#migrations)
- [Models](#models)
- [Querying](#querying)
	- [Basics](#basic-querying)
	- [Group By](#group-by)
	- [Order By](#order-by)
	- [Joins](#joins)	 
	- [Fragments](#fragments)
- [Changesets](#changesets)

## Setup

To get started we need to include Ecto and a database adapter in our project's `mix.exs`.  You can find a list of supported database adapters in the [Usage](https://github.com/elixir-lang/ecto/blob/master/README.md#usage) section of the Ecto README.  For our example we'll use PostgreSQL:

```elixir
defp deps do
  [{:ecto, "~> 1.0"},
   {:postgrex, ">= 0.0.0"}]
end
```

Now we can add Ecto and our adapter to the application list:

```elixir
def application do
  [applications: [:ecto, :postgrex]]
end
```

Finally we need to create our project's respository, the database wrapper.  This can be done via the `mix ecto.gen.repo` task, we'll cover Ecto mix tasks next.  The Repo can be found in `lib/<project name>/repo.ex`:

```elixir
defmodule ExampleApp.Repo do
  use Ecto.Repo,
    otp_app: :example_app
end
```

### Configuration

To configure ecto we need to add a section to our `config/config.exs`.  Here we'll specify the repository, adapter, database, account information:

```elixir
config :example_app, ExampleApp.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "example_app",
  username: "postgres",
  password: "postgres"
```

## Mix Tasks

Ecto includes a number of helpful mix tasks for working with our database:

```shell
mix ecto.create         # Create the storage for the repo
mix ecto.drop           # Drop the storage for the repo
mix ecto.gen.migration  # Generate a new migration for the repo
mix ecto.gen.repo       # Generate a new repository
mix ecto.migrate        # Run migrations up on a repo
mix ecto.rollback       # Rollback migrations from a repo
```

## Migrations

The best way to a create migrations is the `mix ecto.gen.migration <name>` task.  If you're acquainted with ActiveRecord these will look familiar.

Let's start by taking a look at a migration for a users table:

```elixir
defmodule ExampleApp.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string, unique: true
      add :encrypted_password, :string, null: false
      add :email, :string
      add :confirmed, :boolean, default: false

      timestamps
    end

    create unique_index(:users, [:username], name: :unique_usernames)
  end
end
```

By default Ecto creates an `id` auto incrementing primary key.  Here we're using the default `change/0` callback but Ecto also supports `up/0` and `down/0` in the event you need more granular control.

As you might have guessed adding `timestamps` to your migration will create and manage `created_at` and `updated_at` for you.

To apply our new migration run `mix ecto.migrate`.

For more on migrations take a look at the [Ecto.Migration](http://hexdocs.pm/ecto/Ecto.Migration.html#content) section of the docs.

## Models

Now that we have our migration we can move on to the model.  Models define our schema, helper methods, and our changesets, we'll cover changesets more in the next sections.

For now let's look at what the model for our migration might look like:

```elixir
defmodule ExampleApp.User do
  use ExampleApp.Web, :model

  schema "users" do
    field :username, :string, unique: true
    field :encrypted_password, :string
    field :email, :string
    field :confirmed, :boolean, default: false
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

    timestamps
  end

  @required_fields ~w(username encrypted_password email confirmed)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
```

The schema we define in our model closely represents what we specified in our migration.  In addition to our database fields we're also including two virtual fields.  Virtual fields are not saved to the database but can be useful for things like validation.  We'll see the virtual fields in action in the [Changeset](#changeset) section.

## Querying

Before we can query our repository we need to import the Query API, for now we only need to import `from/2`:

```elixir
import Ecto.Query, only: [from: 2]
```

The official documentation can be found at [Ecto.Query](http://hexdocs.pm/ecto/Ecto.Query.html).

### Basics

Ecto provides an excellent Query DSL that allows us to express query clearly.  To find the usernames of all confirmed accounts we could use something like this:

```elixir
query = from u in User,
		where: u.confirmed == true,
		select: u.username

Repo.all(User, query)
```

In addition to `all/2` Repo provides a number of callbacks including `one/2`, `get/3`, `insert/2`, and `delete/2`.  A complete list of callbacks can be found at [Ecto.Repo#callbacks](http://hexdocs.pm/ecto/Ecto.Repo.html#callbacks).

### Count
 
```elixir
query = from u in User,
		where: u.confirmed == true,
		select: count(u.id)
```

### Group By

To group usernames by their creation date we can include the `group_by` option:

```elixir
query = from u in User,
		group_by: u.created_at,
		select: [u.username, u.created_at]
		

Repo.all(User, query)
```

### Order By

Ordering users by their creation date:

```elixir
query = from u in User,
		order_by: u.created_at,
		select: [u.username, u.created_at]
		

Repo.all(User, query)
```

To order by `DESC`:

```elixir
query = from u in User,
		order_by: [desc: u.created_at],
		select: [u.username, u.created_at]
```

### Joins

Assuming we had a profile associated with our user, let's find all confirmed account profiles:

```elixir
query = from p in Profile,
		join: u in assoc(profile, :user),
		where: u.confirmed == true
```

### Fragments

Sometimes the Query API isn't enough, like when we need specific database functions.  The `fragment/1` function exists for this purpose:

```elixir
query = from u in User,
		where: fragment("downcase(?)", u.username) == ^username
		select: u
```

Additional query examples can be found at [phoenix-examples/ecto_query_library](https://github.com/phoenix-examples/ecto_query_library).

## Changeset

In the previous section we learned how to retrieve data but how about inserting and updating it?  For that we need Changesets.

Changesets take care of filtering, validating, mantaining contraints when changing a model.

For this example we'll focus on the changeset for user account creation.  To start we need to update our model:

```elixir
defmodule ExampleApp.User do
  use ExampleApp.Web, :model

  schema "users" do
    field :username, :string, unique: true
    field :encrypted_password, :string
    field :email, :string
    field :confirmed, :boolean, default: false
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

    timestamps
  end
  
  @required_fields ~w(username encrypted_password email)
  @optional_fields ~w()
  
  def changeset(model, params) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:password, min: 8)
    |> validate_password_confirmation
    |> unique_constraint(:username, name: :email)
    |> put_change(:encrypted_password, Comeonin.Bcrypt.hashpwsalt(params[:password]))
  end
  
  defp validate_password_confirmation(changeset) do
    case Ecto.Changeset.get_change(changeset, :password_confirmation) do
      nil -> password_mismatch_error(changeset)
      confirmation ->
        password = Ecto.Changeset.get_field(changeset, :password)
        if confirmation == password, do: changeset, else: password_incorrect_error(changeset)
    end
  end
end
```

We've added two new functions `changeset/2` and `validate_password_confirmation/1`.  

As its name suggests `changeset/2` creates a new changeset for us.  In it we use `cast/4` to convert our parameters to a changeset from a set of required and optional fields.  Next we validate the changeset's password length, password confirmation match using our own function, and username uniqueness.  Finally we update our actual password database field.  For this we use `put_change/3` to update a value in the changeset.

Using `User.changeset/2` is relatively straightforward:

```elixir
pw = "passwords should be hard"
changeset = User.changeset(%User{}, %{username: "doomspork", 
									  email: "sean@seancallan.com", 
									  password: pw, 
									  password_confirmation: pw})

case Repo.insert(changeset) do
  {:ok, model}        -> # Inserted with success
  {:error, changeset} -> # Something went wrong
end
```

That's it!  Now you're ready to save some data.