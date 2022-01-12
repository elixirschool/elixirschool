%{
  version: "1.2.2",
  title: "Relacje",
  excerpt: """
  W tej lekcji nauczymy się, jak korzystać z Ecto do definiowania i pracy z relacjami między schematami.
  """
}
---

## Przygotowanie

Będziemy pracować z tą samą aplikacją `Friends`, której używaliśmy w poprzednich lekcjach. Możesz zajrzeć [tutaj](/pl/lessons/ecto/basics), jesli potrzebujesz przypomnienia.

## Rodzaje relacji

Istnieją trzy rodzaje relacji, które możemy zdefiniować między naszymi schematami. Przyjrzymy się każdemu z nich i nauczymy się, jak je zaimplementować.

### Jeden do wielu

Dodamy kilka nowych encji do aplikacji Friends, by móc katalogować nasze ulubione filmy. Zaczniemy od schematów: `Movie` (_film_) i `Character` (_postać_). Zaimplementujmy między nimi relację „jeden do wielu”: w każdym filmie będzie wiele postaci, a każda postać będzie związana z jakimś filmem.

#### Migracja „has many” — „ma wiele”

Wygenerujmy migrację dla tabeli `Movie`:

```console
mix ecto.gen.migration create_movies
```

Otwórz nowo utworzony plik z migracją i zdefiniuj funkcję `change`, by utworzyć tabelę `movies` z kilkoma atrybutami:

```elixir
# priv/repo/migrations/*_create_movies.exs
defmodule Friends.Repo.Migrations.CreateMovies do
  use Ecto.Migration

  def change do
    create table(:movies) do
      add :title, :string
      add :tagline, :string
    end
  end
end
```

#### Schemat dla relacji „ma wiele”

Dodamy schemat, który określi relację między filmem a jego postaciami.

```elixir
# lib/friends/movie.ex
defmodule Friends.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Friends.Character
  end
end
```

Makro `has_many/3` nie dodaje niczego do samej bazy danych. Pozwala nam jednak na użycie klucza obcego z powiązanego schematu — `characters` — by umożliwić nam dostęp do postaci występujących w danym filmie. Pozwoli nam to na wywołanie `movie.characters`.

#### Migracja „belongs to” — „należy do”

Teraz jesteśmy gotowi, by zbudować migrację i schemat `Character`. Postać należy do filmu, więc stworzymy migrację i schemat opisujące tę zależność.

Najpierw wygenerujmy migrację:

```console
mix ecto.gen.migration create_characters
```

Aby zadeklarować, że postać należy do filmu, potrzebujemy, aby tabela `characters` zawierała kolumnę `movie_id`, która będzie kluczem obcym. Możemy to uczynić poprzez dodanie następującej linii w funkcji `create table/1`:

```elixir
add :movie_id, references(:movies)
```
Nasza migracja będzie zatem wyglądała tak:

```elixir
# priv/migrations/*_create_characters.exs
defmodule Friends.Repo.Migrations.CreateCharacters do
  use Ecto.Migration

  def change do
    create table(:characters) do
      add :name, :string
      add :movie_id, references(:movies)
    end
  end
end
```

#### Schamat „należy do”

Również nasz schemat powinien definiować relację „należy do” między postacią i jej filmem.

```elixir
# lib/friends/character.ex

defmodule Friends.Character do
  use Ecto.Schema

  schema "characters" do
    field :name, :string
    belongs_to :movie, Friends.Movie
  end
end
```

Przyjrzyjmy się bliżej temu, co dokładniej robi dla nas makro `belongs_to/3`. Poza dodaniem klucza obcego `movie_id`, pozwala nam również na dostęp do schematu `movies` _poprzez_ schemat `characters`. Używa klucza obcego, by umożliwić nam dostęp do filmu związanego z daną postacią. Pozwoli nam to wywoływać `character.movie`.

Jesteśmy już gotowi, by uruchomić nasze migracje:

```console
mix ecto.migrate
```

### Jeden do jednego

Załóżmy, że film ma jednego dystrybutora, na przykład Netflix jest dystrybutorem filmu „Bright”.

Zdefiniujmy migrację i schemat `Distributor` (_dystrybutor_) z relacją „należy do” the "belongs to". Zacznijmy od wygenerowania migracji:

```console
mix ecto.gen.migration create_distributors
```

Powinniśmy dodać klucz obcy `movie_id` do migracji dla tabeli `distributors`, jak również stworzyć indeks typu „unique”, zapewniający, że film będzie miał tylko jednego dystrybutora:

```elixir
# priv/repo/migrations/*_create_distributors.exs

defmodule Friends.Repo.Migrations.CreateDistributors do
  use Ecto.Migration

  def change do
    create table(:distributors) do
      add :name, :string
      add :movie_id, references(:movies)
    end

    create unique_index(:distributors, [:movie_id])
  end
end
```

Z kolei schemat `Distributor` powinien używać makra `belongs_to/3`, które pozwoli na wywoływanie `distributor.movie` i dostęp do filmu danego dystrybutora przy użyciu klucza obcego.

```elixir
# lib/friends/distributor.ex

defmodule Friends.Distributor do
  use Ecto.Schema

  schema "distributors" do
    field :name, :string
    belongs_to :movie, Friends.Movie
  end
end
```

Następnie dodamy relację „posiada jeden” do schematu `Movie`:

```elixir
# lib/friends/movie.ex

defmodule Friends.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Friends.Character
    has_one :distributor, Friends.Distributor # I'm new!
  end
end
```

Makro `has_one/3` działa tak, jak makro `has_many/3`. Używa klucza obcego powiązanego schematu, aby wyszukać i udostępnić dystrybutora filmu. Pozwoli nam to na wywołanie `movie.distributor`.

Jesteśmy gotowi, by uruchomić nasze migracje:

```console
mix ecto.migrate
```

### Wiele do wielu

Możemy założyć, że w filmie występuje wielu aktorów, a każdy aktor może wystąpić w więcej niż jednym filmie. Stworzymy tabelę łączącą, odwołującą się zarówno do filmów, jak i aktorów, by zaimplementować tę relację.

Najpierw wygenerujmy migrację `Actors` (_aktorzy_):

```console
mix ecto.gen.migration create_actors
```

Zdefiniujmy, co migracja ma zrobić:

```elixir
# priv/migrations/*_create_actors.ex

defmodule Friends.Repo.Migrations.CreateActors do
  use Ecto.Migration

  def change do
    create table(:actors) do
      add :name, :string
    end
  end
end
```

Wygenerujmy migrację dla tabeli łączącej:

```console
mix ecto.gen.migration create_movies_actors
```

Zaimplementujemy migrację tak, by tabela miała dwa klucze obce.
Dodany również indeks unikalny, by zapewnić, że dany aktor z danym filmem będzie połączony tylko raz:

```elixir
# priv/migrations/*_create_movies_actors.ex

defmodule Friends.Repo.Migrations.CreateMoviesActors do
  use Ecto.Migration

  def change do
    create table(:movies_actors) do
      add :movie_id, references(:movies)
      add :actor_id, references(:actors)
    end

    create unique_index(:movies_actors, [:movie_id, :actor_id])
  end
end
```

Teraz dodajmy makro `many_to_many` do naszego schematu `Movie`:

```elixir
# lib/friends/movie.ex

defmodule Friends.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Friends.Character
    has_one :distributor, Friends.Distributor
    many_to_many :actors, Friends.Actor, join_through: "movies_actors" # I'm new!
  end
end
```

Na koniec zdefiniujmy schemat `Actor`, używając tego samego makra `many_to_many`.

```elixir
# lib/friends/actor.ex

defmodule Friends.Actor do
  use Ecto.Schema

  schema "actors" do
    field :name, :string
    many_to_many :movies, Friends.Movie, join_through: "movies_actors"
  end
end
```

Mozemy uruchomić migracje:

```console
mix ecto.migrate
```
