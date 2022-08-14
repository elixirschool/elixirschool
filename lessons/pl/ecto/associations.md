%{
  version: "1.2.2",
  title: "Relacje",
  excerpt: """
  W tej lekcji nauczymy się, jak korzystać z Ecto do definiowania relacji między schematami i pracy z nimi.
  """
}
---

## Przygotowanie

Będziemy pracować z tą samą aplikacją `Friends`, której używaliśmy w poprzednich lekcjach. Możesz zajrzeć [tutaj](/pl/lessons/ecto/basics), jeśli potrzebujesz przypomnienia.

## Rodzaje relacji

Istnieją trzy rodzaje relacji, które możemy zdefiniować między naszymi schematami. Przyjrzymy się każdemu z nich i nauczymy się, jak je zaimplementować.

### Jeden do wielu

Dodamy kilka nowych encji do aplikacji Friends, by móc katalogować nasze ulubione filmy. Zaczniemy od schematów: `Movie` (_film_) i `Character` (_postać_). Zaimplementujmy między nimi relację „jeden do wielu”: w każdym filmie będzie wiele postaci, a każda postać będzie związana z jakimś filmem.

#### Migracja „has many” — „posiada wiele”

Wygenerujmy migrację dla tabeli `Movie`:

```console
mix ecto.gen.migration create_movies
```

Otwórz nowo utworzony plik z migracją i zdefiniuj funkcję `change`, by stworzyć tabelę `movies` z kilkoma atrybutami:

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

#### Schemat dla relacji „posiada wiele”

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

Makro `has_many/3` nie dodaje niczego do samej bazy danych, pozwala jednak na użycie klucza obcego z powiązanego schematu — `characters` — by umożliwić nam dostęp do postaci występujących w danym filmie. Pozwoli nam to na wywołanie `movie.characters`.

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

Cała nasza migracja będzie zatem wyglądała tak:

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

#### Schemat „należy do”

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

Załóżmy, że film ma jednego dystrybutora — na przykład Netflix jest dystrybutorem filmu „Bright”.

Zdefiniujmy migrację i schemat `Distributor` (_dystrybutor_) z relacją „należy do”. Zacznijmy od wygenerowania migracji:

```console
mix ecto.gen.migration create_distributors
```

Powinniśmy dodać klucz obcy `movie_id` do migracji dla tabeli `distributors`, jak również stworzyć indeks unikalny, który zapewni, że film będzie miał tylko jednego dystrybutora:

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
    has_one :distributor, Friends.Distributor # Nowa linijka!
  end
end
```

Makro `has_one/3` działa tak, jak makro `has_many/3`. Używa klucza obcego powiązanego schematu, aby wyszukać i udostępnić nam dystrybutora filmu. Umożliwi to wywołanie `movie.distributor`.

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

Zaimplementujemy migrację tak, by tabela zawierała dwa klucze obce. Dodamy również indeks unikalny, by zapewnić, że dany aktor z danym filmem będzie połączony tylko raz:

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
    many_to_many :actors, Friends.Actor, join_through: "movies_actors" # Nowa linijka!
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

Możemy uruchomić migracje:

```console
mix ecto.migrate
```

## Zapisywanie powiązanych danych

Sposób, w jaki będziemy zapisywać rekordy wraz z ich powiązanymi danymi zależy od rodzaju relacji między tymi rekordami. Zacznijmy od relacji „jeden do wielu”.

### „Należy do”

#### Zapisywanie z użyciem Ecto.build_assoc/3

W relacji „należy do” możemy skorzystać z funkcji Ecto `build_assoc/3`.

[`build_assoc/3`](https://hexdocs.pm/ecto/Ecto.html#build_assoc/3) przyjmuje trzy argumenty:

* strukturę rekordu, który chcemy zapisać,
* nazwę relacji,
* wszelkie atrybuty, które chcemy przypisać do powiązanego rekordu, który zapisujemy.

Zapiszmy więc film wraz ze związaną z nim postacią. Najpierw utwórzmy odpowiedni rekord dla filmu:

```elixir
iex> alias Friends.{Movie, Character, Repo}
iex> movie = %Movie{title: "Ready Player One", tagline: "Something about video games"}

%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:built, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: nil,
  tagline: "Something about video games",
  title: "Ready Player One"
}

iex> movie = Repo.insert!(movie)
```

Teraz zbudujemy strukturę dla postaci występującej w tym filmie i dodamy ją do bazy danych:

```elixir
iex> character = Ecto.build_assoc(movie, :characters, %{name: "Wade Watts"})
%Friends.Character{
  __meta__: %Ecto.Schema.Metadata<:built, "characters">,
  id: nil,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Wade Watts"
}
iex> Repo.insert!(character)
%Friends.Character{
  __meta__: %Ecto.Schema.Metadata<:loaded, "characters">,
  id: 1,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Wade Watts"
}
```

Zauważ, że skoro makro `has_many/3` w schemacie `Movie` mówi, że film ma wiele _postaci_ — `:characters` (liczba mnoga!) — nazwa relacji, którą przekazujemy jako drugi argument funkcji `build_assoc/3` jest właśnie taka: `:characters`. Możesz zobaczyć, że postać, którą właśnie utworzyliśmy, w polu `movie_id` ma poprawnie przypisane ID powiązanego z nią filmu.

Aby użyć `build_assoc/3` do zapisania zwiazanego z filmem dystrybutora, zastosujemy to samo podejście, podając nazwę relacji film-dystrybutor jako drugi argument funkcji `build_assoc/3`:

```elixir
iex> distributor = Ecto.build_assoc(movie, :distributor, %{name: "Netflix"})
%Friends.Distributor{
  __meta__: %Ecto.Schema.Metadata<:built, "distributors">,
  id: nil,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Netflix"
}
iex> Repo.insert!(distributor)
%Friends.Distributor{
  __meta__: %Ecto.Schema.Metadata<:loaded, "distributors">,
  id: 1,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Netflix"
}
```

### Wiele do wielu

#### Zapisywanie z użyciem Ecto.Changeset.put_assoc/4

Sposób z `build_assoc/3` nie zadziała dla relacji „wiele do wielu”. Wynika to z prostego faktu, że ani tabela filmów, ani tabela aktorów nie zawierają kluczy obcych. Zamiast tego będziemy musieli więc użyć zastawów zmian Ecto (_changesetów_) i funkcji `put_assoc/4`.

Załóżmy, że mamy już w bazie rekord z filmem, który utworzyliśmy wyżej, teraz dodajmy rekord aktora:

```elixir
iex> alias Friends.Actor
iex> actor = %Actor{name: "Tyler Sheridan"}
%Friends.Actor{
  __meta__: %Ecto.Schema.Metadata<:built, "actors">,
  id: nil,
  movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
  name: "Tyler Sheridan"
}
iex> actor = Repo.insert!(actor)
%Friends.Actor{
  __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
  id: 1,
  movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
  name: "Tyler Sheridan"
}
```

Teraz jesteśmy gotowi, by powiązać nasz film z aktorem poprzez tabelę łączącą.

Zauważ najpierw, że — skoro pracujemy z changesetami — musimy mieć pewność, iż nasza struktura `movie` będzie miała wcześniej załadowane powiązane dane. O ładowaniu takich danych powiemy nieco więcej w późniejszym czasie — teraz wystarczy wiedzieć, że możemy ładować powiązane rekordy w następujący sposób:

```elixir
iex> movie = Repo.preload(movie, [:distributor, :characters, :actors])
%Friends.Movie{
 __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [],
  characters: [
    %Friends.Character{
      __meta__: #Ecto.Schema.Metadata<:loaded, "characters">,
      id: 1,
      movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
      movie_id: 1,
      name: "Wade Watts"
    }
  ],
  distributor: %Friends.Distributor{
    __meta__: #Ecto.Schema.Metadata<:loaded, "distributors">,
    id: 1,
    movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
    movie_id: 1,
    name: "Netflix"
  },
  id: 1,
  tagline: "Something about video game",
  title: "Ready Player One"
}
```

Teraz utwórzmy changeset dla rekordu naszego filmu:

```elixir
iex> movie_changeset = Ecto.Changeset.change(movie)
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Movie<>,
 valid?: true>
```

Nasz changeset przekażemy jako pierwszy argument do funkcji [`Ecto.Changeset.put_assoc/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#put_assoc/4):

```elixir
iex> movie_actors_changeset = movie_changeset |> Ecto.Changeset.put_assoc(:actors, [actor])
%Ecto.Changeset<
  action: nil,
  changes: %{
    actors: [
      %Ecto.Changeset<action: :update, changes: %{}, errors: [],
       data: %Friends.Actor<>, valid?: true>
    ]
  },
  errors: [],
  data: %Friends.Movie<>,
  valid?: true
>
```

To daje nam _nowy_ changeset, reprezentujący następującą zmianę: dodaj aktorów z tej listy do danego filmu.

Na koniec zaktualizujemy rekordy filmu i aktora, używając ostatniego zestawu zmian:

```elixir
iex> Repo.update!(movie_actors_changeset)
%Friends.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Friends.Actor{
      __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
      id: 1,
      movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Tyler Sheridan"
    }
  ],
  characters: [
    %Friends.Character{
      __meta__: #Ecto.Schema.Metadata<:loaded, "characters">,
      id: 1,
      movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
      movie_id: 1,
      name: "Wade Watts"
    }
  ],
  distributor: %Friends.Distributor{
    __meta__: #Ecto.Schema.Metadata<:loaded, "distributors">,
    id: 1,
    movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
    movie_id: 1,
    name: "Netflix"
  },
  id: 1,
  tagline: "Something about video game",
  title: "Ready Player One"
}
```

Możesz zauważyć, że uzyskaliśmy w ten sposób rekord filmu z aktorem, poprawnie powiązanym i załadowanym dla nas pod `movie.actors`.

Możemy użyć tego samego sposobu, aby dodać zupełnie nowego aktora, który ma być powiązany z danym filmem. Zamiast przekazywać _zapisaną_ już strukturę z danymi aktora do `put_assoc/4`, możemy po prostu przekazać strukturę opisującą aktora, którego chcemy stworzyć w naszej bazie:

```elixir
iex> changeset = movie_changeset |> Ecto.Changeset.put_assoc(:actors, [%{name: "Gary"}])
%Ecto.Changeset<
  action: nil,
  changes: %{
    actors: [
      %Ecto.Changeset<
        action: :insert,
        changes: %{name: "Gary"},
        errors: [],
        data: %Friends.Actor<>,
        valid?: true
      >
    ]
  },
  errors: [],
  data: %Friends.Movie<>,
  valid?: true
>
iex>  Repo.update!(changeset)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Friends.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
      id: 2,
      movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Gary"
    }
  ],
  characters: [],
  distributor: nil,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Jak możesz zauważyć, nowy aktor został stworzony z ID "2" i atrybutami, które mu przypisaliśmy.

W następnej lekcji dowiemy się, jak można tworzyć zapytania, by wyszukiwać powiązane ze sobą rekordy.
