---
layout: page
title: Ecto
category: specifics
order: 2
lang: pl
---

Ecto jest oficjalnym projektem zespołu Elixira zapewniającym obsługę baz danych wraz z odpowiednim, zintegrowanym 
językiem. Za pomocą Ecto możemy migrować dane, definiować modele, wstawiać, aktualizować i odpytywać bazę danych.

{% include toc.html %}

## Przygotowanie

Zacznijmy od dodania Ecto oraz adaptera bazy do konfiguracji projektu w pliku `mix.exs`.  Lista wszystkich 
dostępnych adapterów i wspieranych baz danych, w języku angielskim, znajduje się w sekcji 
[Usage](https://github.com/elixir-lang/ecto/blob/master/README.md#usage) w pliku README projektu Ecto. W naszym 
przykładzie użyjemy bazy PostgreSQL:

```elixir
defp deps do
  [{:ecto, "~> 1.0"},
   {:postgrex, ">= 0.0.0"}]
end
```

Teraz możemy dodać Ecto i nasz adapter do listy aplikacji:

```elixir
def application do
  [applications: [:ecto, :postgrex]]
end
```

### Repozytorium

W końcu musimy stworzyć repozytorium dla naszego projektu, które pełni rolę opakowania (ang. _wrapper_) bazy danych.  
Możemy to zrobić wykorzystując polecenie `mix ecto.gen.repo`.  Zadania Ecto dla Mixa omówimy za chwilę. Moduł `Repo` 
znajdziemy w `lib/<projectname>/repo.ex`:

```elixir
defmodule ExampleApp.Repo do
  use Ecto.Repo,
    otp_app: :example_app
end
```

### Nadzorca

Po stworzeniu repozytorium musimy jeszcze skonfigurować drzewo nadzorców, które znajdziemy w pliku`lib/<project name>.ex`.

Kluczowe jest wykorzystanie do tego funkcji `supervisor/3`, a _nie_ `worker/3`.  Jeżeli wygenerujemy aplikację z 
flagą `--sup`, to większość konfiguracji będzie już gotowa:

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

Więcej o nadzorcach znajdziesz w lekcji [Nadzorcy OTP](/lessons/advanced/otp-supervisors).

### Konfiguracja

By skonfigurować Ecto musimy dodać odpowiednią sekcję w pliku `config/config.exs`. Zawiera ona informacje o 
repozytorium, adapterze, bazie danych oraz dane użytkownika:

```elixir
config :example_app, ExampleApp.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "example_app",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
```

## Zadnie Mix

Ecto zawiera wiele przydatnych zadań mix by wspomagać nas w pracy z bazą danych:

```shell
mix ecto.create         # Create the storage for the repo
mix ecto.drop           # Drop the storage for the repo
mix ecto.gen.migration  # Generate a new migration for the repo
mix ecto.gen.repo       # Generate a new repository
mix ecto.migrate        # Run migrations up on a repo
mix ecto.rollback       # Rollback migrations from a repo
```

## Migracja

Najlepszą metodą do pracy z migracjami jest zadanie `mix ecto.gen.migration <name>`.  Jeżeli spotkałeś się ze wzorcem
 ActiveRecord, to odkryjesz tu wiele podobieństw.

Na początek przyjrzyjmy się migracji tabeli `users`:

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

Ecto tworzy domyślnie przyrostowy klucz główny `id`.  W tej lekcji używamy funkcji `change/0`, ale Ecto  wspiera 
też operacje `up/0` i `down/0`, pozwalające na większą i dokładniejszą kontrolę.

Jak się domyślasz, dodanie `timestamps` do migracji wygeneruje kolumny `created_at` i `updated_at`..

Możemy teraz uruchomić migrację poleceniem `mix ecto.migrate`.

Więcej na temat migracji znajdziesz w dokumentacji [Ecto.Migration](http://hexdocs.pm/ecto/Ecto.Migration.html#content).

## Modele

Mają gotową migrację możemy przejść do modelu. Modele opisują nasze dane, funkcje pomocnicze oraz zmiany. Tymi 
ostatnimi zajmiemy się w następnej kolejności.

Załóżmy, że model dla naszej migracji wygląda nastepujaco:

```elixir
defmodule ExampleApp.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string
    field :encrypted_password, :string
    field :email, :string
    field :confirmed, :boolean, default: false
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

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

The schema we define in our model closely represents what we specified in our migration.  In addition to our database fields we're also including two virtual fields.  Virtual fields are not saved to the database but can be useful for things like validation.  We'll see the virtual fields in action in the [Changesets](#changesets) section.
To co przedstawia powyższa definicja pokrywa się z tym co mamy w migracji. Dodatkowo do naszej bazy danych dodaliśmy 
dwa pola wirtualne.  Pola wirtualne nie są składowane w bazie danych, ale czasami przydają się np. w trakcie 
walidacji. Przyjrzymy im się bliżej w części [aktualizacja danych](#Aktualizacja-danych).

## Zapytania

Before we can query our repository we need to import the Query API.  For now we only need to import `from/2`:

```elixir
import Ecto.Query, only: [from: 2]
```

The official documentation can be found at [Ecto.Query](http://hexdocs.pm/ecto/Ecto.Query.html).

### Podstawy

Ecto provides an excellent Query DSL that allows us to express queries clearly.  To find the usernames of all confirmed accounts we could use something like this:

```elixir
alias ExampleApp.{Repo,User}

query = from u in User,
    where: u.confirmed == true,
    select: u.username

Repo.all(query)
```

In addition to `all/2`, Repo provides a number of callbacks including `one/2`, `get/3`, `insert/2`, and `delete/2`.  A complete list of callbacks can be found at [Ecto.Repo#callbacks](http://hexdocs.pm/ecto/Ecto.Repo.html#callbacks).

### Zliczanie

```elixir
query = from u in User,
    where: u.confirmed == true,
    select: count(u.id)
```

### Grupowanie

To group users by their confirmation status we can include the `group_by` option:

```elixir
query = from u in User,
    group_by: u.confirmed,
    select: [u.confirmed, count(u.id)]

Repo.all(query)
```

### Sortowanie

Ordering users by their creation date:

```elixir
query = from u in User,
    order_by: u.inserted_at,
    select: [u.username, u.inserted_at]

Repo.all(query)
```

To order by `DESC`:

```elixir
query = from u in User,
    order_by: [desc: u.inserted_at],
    select: [u.username, u.inserted_at]
```

### Złączenia

Assuming we had a profile associated with our user, let's find all confirmed account profiles:

```elixir
query = from p in Profile,
    join: u in assoc(profile, :user),
    where: u.confirmed == true
```

### Fragmenty

Sometimes, like when we need specific database functions, the Query API isn't enough.  The `fragment/1` function exists for this purpose:

```elixir
query = from u in User,
    where: fragment("downcase(?)", u.username) == ^username
    select: u
```

Additional query examples can be found in the [Ecto.Query.API](http://hexdocs.pm/ecto/Ecto.Query.API.html) module description.

## Aktualizacja danych

In the previous section we learned how to retrieve data, but how about inserting and updating it?  For that we need Changesets.

Changesets take care of filtering, validating, and maintaining constraints when changing a model.

For this example we'll focus on the changeset for user account creation.  To start we need to update our model:

```elixir
defmodule ExampleApp.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Comeonin.Bcrypt, only: [hashpwsalt: 1]

  schema "users" do
    field :username, :string
    field :encrypted_password, :string
    field :email, :string
    field :confirmed, :boolean, default: false
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

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
        password_mismatch_error(changeset)
      confirmation ->
        password = get_field(changeset, :password)
        if confirmation == password, do: changeset, else: password_incorrect_error(changeset)
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

We've improved our `changeset/2` function and added three new helper functions: `validate_password_confirmation/1`, `password_mismatch_error/1`, and `password_incorrect_error/1`.

As its name suggests, `changeset/2` creates a new changeset for us.  In it we use `cast/4` to convert our parameters to a changeset from a set of required and optional fields.  Next we validate the changeset's password length, we use our own function to validate the password confirmation matches, and we validate username uniqueness.  Finally we update our actual password database field.  For this we use `put_change/3` to update a value in the changeset.

Using `User.changeset/2` is relatively straightforward:

```elixir
alias ExampleApp.{User,Repo}

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
