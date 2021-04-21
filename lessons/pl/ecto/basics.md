%{
  version: "0.9.1",
  title: "Basics",
  excerpt: """
  Ecto jest oficjalnym projektem zespołu Elixira zapewniającym obsługę baz danych wraz z odpowiednim, zintegrowanym językiem. Za pomocą Ecto możemy migrować dane, definiować modele, wstawiać, aktualizować i odpytywać bazę danych.
  """
}
---

## Przygotowanie

Zacznijmy od dodania Ecto oraz adaptera bazy do konfiguracji projektu w pliku `mix.exs`.  Lista wszystkich dostępnych adapterów i wspieranych baz danych, w języku angielskim, znajduje się w sekcji [Usage](https://github.com/elixir-lang/ecto/blob/master/README.md#usage) w pliku README projektu Ecto. W naszym przykładzie użyjemy bazy PostgreSQL:

```elixir
defp deps do
  [{:ecto, "~> 2.1.4"}, {:postgrex, ">= 0.13.2"}]
end
```

Teraz możemy dodać Ecto i nasz adapter do listy aplikacji:

```elixir
def application do
  [applications: [:ecto, :postgrex]]
end
```

### Repozytorium

W końcu musimy stworzyć repozytorium dla naszego projektu, które pełni rolę opakowania (ang. _wrapper_) bazy danych.  Możemy to zrobić wykorzystując polecenie `mix ecto.gen.repo -r FriendsApp.Repo`.  Zadania Ecto dla Mixa omówimy za chwilę. Moduł `Repo` znajdziemy w `lib/<projectname>/repo.ex`:

```elixir
defmodule FriendsApp.Repo do
  use Ecto.Repo, otp_app: :example_app
end
```

### Nadzorca

Po stworzeniu repozytorium musimy jeszcze skonfigurować drzewo nadzorców, które znajdziemy w pliku`lib/<project name>.ex`.

Kluczowe jest wykorzystanie do tego funkcji `supervisor/3`, a _nie_ `worker/3`.  Jeżeli wygenerujemy aplikację z flagą `--sup`, to większość konfiguracji będzie już gotowa:

```elixir
defmodule FriendsApp.App do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(FriendsApp.Repo, [])
    ]

    opts = [strategy: :one_for_one, name: FriendsApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Więcej o nadzorcach znajdziesz w lekcji [Nadzorcy OTP](../../advanced/otp-supervisors).

### Konfiguracja

By skonfigurować Ecto musimy dodać odpowiednią sekcję w pliku `config/config.exs`. Zawiera ona informacje o repozytorium, adapterze, bazie danych oraz dane użytkownika:

```elixir
config :example_app, FriendsApp.Repo,
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

Najlepszą metodą do pracy z migracjami jest zadanie `mix ecto.gen.migration <name>`.  Jeżeli spotkałeś się ze wzorcem ActiveRecord, to odkryjesz tu wiele podobieństw.

Na początek przyjrzyjmy się migracji tabeli `users`:

```elixir
defmodule FriendsApp.Repo.Migrations.CreateUser do
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

Ecto tworzy domyślnie przyrostowy klucz główny `id`.  W tej lekcji używamy funkcji `change/0`, ale Ecto  wspiera też operacje `up/0` i `down/0`, pozwalające na większą i dokładniejszą kontrolę.

Jak się domyślasz, dodanie `timestamps` do migracji wygeneruje kolumny `created_at` i `updated_at`..

Możemy teraz uruchomić migrację poleceniem `mix ecto.migrate`.

Więcej na temat migracji znajdziesz w dokumentacji [Ecto.Migration](http://hexdocs.pm/ecto/Ecto.Migration.html#content).

## Modele

Mają gotową migrację możemy przejść do modelu. Modele opisują nasze dane, funkcje pomocnicze oraz zestawy zmian. Tymi ostatnimi zajmiemy się w następnej kolejności.

Załóżmy, że model dla naszej migracji wygląda następująco:

```elixir
defmodule FriendsApp.User do
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

To, co przedstawia powyższa definicja pokrywa się z tym, co mamy w migracji. Dodatkowo do naszej bazy danych dodaliśmy dwa pola wirtualne.  Pola wirtualne nie są składowane w bazie danych, ale czasami przydają się np. w trakcie walidacji. Przyjrzymy im się bliżej w części [aktualizacja danych](#Aktualizacja-danych).

## Zapytania

Zanim zaczniemy odpytywać repozytorium, musimy zaimportować `Ecto.Query`.  Na początek potrzebujemy tylko `from/2`:

```elixir
import Ecto.Query, only: [from: 2]
```

Oficjalną dokumentację, w języku angielskim, znajdziesz na stronie [Ecto.Query](http://hexdocs.pm/ecto/Ecto.Query.html).

### Podstawy

Ecto ma wspaniały DSL (ang. _Domain specific language_ – język domeny) do definiowania zapytań. Przykładowo by pobrać wszystkie pola `username` dla użytkowników, którzy mają zatwierdzone konto, napiszemy:

```elixir
alias FriendsApp.{Repo, User}

query =
  from(
    u in User,
    where: u.confirmed == true,
    select: u.username
  )

Repo.all(query)
```

Poza funkcją `all/2` Repo ma też m.in. `one/2`, `get/3`, `insert/2` i `delete/2`.  Pełną listę znajdziesz na stronie [Ecto.Repo#callbacks](http://hexdocs.pm/ecto/Ecto.Repo.html#callbacks).

### Zliczanie

Jeżeli chcemy policzyć, ilu użytkowników ma zatwierdzone konta, możemy użyć `count/1`:

```elixir
query =
  from(
    u in User,
    where: u.confirmed == true,
    select: count(u.id)
  )
```

Jest też funkcja `count/2`, która zlicza liczbę unikalnych rekordów:

```elixir
query =
  from(
    u in User,
    where: u.confirmed == true,
    select: count(u.id, :distinct)
  )
```


### Grupowanie

Funkcja `group_by` pozwala nam grupować dane wyliczone w funkcjach agregujących. Na przykład policzyć ilu użytkowników ma konta zatwierdzone, a ilu niezatwierdzone:

```elixir
query =
  from(
    u in User,
    group_by: u.confirmed,
    select: [u.confirmed, count(u.id)]
  )

Repo.all(query)
```

### Sortowanie

Sortowanie kont po dacie utworzenia:

```elixir
query =
  from(
    u in User,
    order_by: u.inserted_at,
    select: [u.username, u.inserted_at]
  )

Repo.all(query)
```

W kolejności malejącej `DESC`:

```elixir
query =
  from(
    u in User,
    order_by: [desc: u.inserted_at],
    select: [u.username, u.inserted_at]
  )
```

### Złączenia

Załóżmy, że mamy profil połączony z użytkownikiem, by odszukać wszystkie profile, które mają zatwierdzone konta napiszemy:

```elixir
query =
  from(
    p in Profile,
    join: u in assoc(p, :user),
    where: u.confirmed == true
  )
```

### Fragmenty

Czasami Query API nie wystarcza i musimy użyć funkcji dostępnej w bazie danych. Służy do tego funkcja `fragment/1`:

```elixir
query =
  from(
    u in User,
    where: fragment("downcase(?)", u.username) == ^username,
    select: u
  )
```

Na stronie [Ecto.Query.API](http://hexdocs.pm/ecto/Ecto.Query.API.html) znajdziesz więcej przykładów.

## Aktualizacja danych

W poprzednich częściach dowiedziałeś się jak pobierać dane, ale co ze wstawianiem ich i aktualizacją? Do tego służą zestawy zmian.

Zestawy zmian dbają o zachowanie ograniczeń, filtrowanie oraz walidację w momencie wprowadzania zmian do modelu.

W tym zestawie skupimy się na zestawie zmian potrzebnym do utworzenia konta. Zacznijmy od aktualizacji naszego modelu:

```elixir
defmodule FriendsApp.User do
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

Stworzyliśmy funkcję `changeset/2` oraz trzy funkcje pomocnicze: `validate_password_confirmation/1`, `password_mismatch_error/1` i `password_incorrect_error/1`.

Jak sama nazwa sugeruje, `changeset/2` tworzy nowy zestaw zmian.  W ramach niego wywołujemy `cast/4` by zamienić parametry na zestaw obowiązkowych i opcjonalnych pól, które zostaną zmienione. Następnie walidujemy długość pola `password`. Sprawdzamy, czy pole to jest takie same jak `password_confirmation` oraz, czy `username` nie istnieje już w bazie. Na końcu, na podstawie parametrów, aktualizujemy pole `encrypted_password` za pomocą funkcji `put_change/3` dopisując je do zestawu zmian.

Samo użycie `User.changeset/2` jest stosunkowo proste:

```elixir
alias FriendsApp.{User, Repo}

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

I to wszystko! Możesz zapisać dane do bazy.
