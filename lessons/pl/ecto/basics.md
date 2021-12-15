%{
  version: "2.4.0",
  title: "Podstawy",
  excerpt: """
  Ecto jest oficjalnym projektem zespołu Elixira, zapewniającym obsługę baz danych wraz z odpowiednim, zintegrowanym językiem. Za pomocą Ecto możemy tworzyć migracje, definiować schematy, wstawiać, aktualizować oraz wyszukiwać rekordy w bazie.
  """
}
---

### Adaptery

Ecto wspiera różne bazy danych poprzez użycie adapterów. Kilka przykładów spośród nich to:

* PostgreSQL,
* MySQL,
* SQLite.

W tej lekcji skonfigurujemy Ecto tak, by używać go z adapterem PostgreSQL.

### Przygotowanie

W trakcie tej lekcji omówimy trzy części Ecto:

* repozytorium — dostarcza ono interfejs do naszej bazy, w tym połączenie z nią;
* migracje — mechanizm do tworzenia, modyfikowania i usuwania tabel i indeksów w bazie;
* schematy — specjalne struktury reprezentujące wpisy w tabelach bazy danych.

Zacznijmy od stworzenia aplikacji z drzewem nadzoru:

```shell
$ mix new friends --sup
$ cd friends
```

Dodajmy biblioteki `ecto_sql` i `postgrex` jako zależności w pliku `mix.exs`:

```elixir
  defp deps do
    [
      {:ecto_sql, "~> 3.2"},
      {:postgrex, "~> 0.15"}
    ]
  end
```

A na koniec pobierzmy zależności:

```shell
$ mix deps.get
```

#### Tworzenie repozytorium

Repozytorium w Ecto zapewnia interfejs do miejsca, w którym trzymamy dane, na przykład do naszej postgresowej bazy.
Wszelka komunikacja z bazą danych będzie się odbywać właśnie za pośrednictwem repozytorium.

Stwórzmy je zatem:

```shell
$ mix ecto.gen.repo -r Friends.Repo
```

Powyższa komenda wygeneruje konfigurację w pliku `config/config.exs`, konieczną do łączenia się z bazą danych.
Tak wygląda plik konfiguracyjny dla naszej aplikacji `Friends`:

```elixir
config :friends, Friends.Repo,
  database: "friends_repo",
  username: "postgres",
  password: "",
  hostname: "localhost"
```

W ten sposób definiujemy, w jaki sposób Ecto będzie się łączyć z bazą. Możesz potrzebować zmienić konfigurację swojej bazy lub powyższe dane tak, by nazwa użytkownika bazodanowego i hasło w konfiguracji Twojej aplikacji zgadzały się ze stanem faktycznym w bazie.

Uruchomiona przez nas wcześniej komenda tworzy również moduł `Friends.Repo` w pliku `lib/friends/repo.ex`:

```elixir
defmodule Friends.Repo do
  use Ecto.Repo, 
    otp_app: :friends,
    adapter: Ecto.Adapters.Postgres
end
```

Będziemy używać modułu `Friend.Repo` do odpytywania bazy danych. Modułowi temu mówimy również, że informacji konfiguracyjnych powinien szukać w elixirowej aplikacji `:friends` oraz że wybraliśmy adapter `Ecto.Adapters.Postgres`.

Następnie ustawmy `Friends.Repo` jako nadzorcę w drzewie nadzoru naszej aplikacji w pliku `lib/friends/application.ex`.
Dzięki temu proces Ecto będzie startowany podczas uruchamiania naszej aplikacji.

```elixir
  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      Friends.Repo,
    ]

  ...
```

Teraz powinniśmy dodać następującą linię do naszego pliku `config/config.exs`:

```elixir
config :friends, ecto_repos: [Friends.Repo]
```

Pozwoli to naszej aplikacji uruchamiać polecenia Mixa z poziomu wiersza poleceń.

Skończyliśmy konfigurowanie repozytorium!
Teraz możemy stworzyć bazę danych w Postgresie za pomocą następującej komendy:

```shell
$ mix ecto.create
```

Ecto będzie używać informacji z pliku `config/config.exs`, by ustalić, jak łączyć się z Postgresem i jaką nazwę nadać bazie danych.

W razie wystąpienia jakichkolwiek błędów upewnij się, że dane konfiguracyjne są poprawne i że Twoja instancja Postgresa jest uruchomiona.

### Migracje

Abyśmy mogli tworzyć i modyfikować tabele w postgresowej bazie danych, Ecto zapewnia nam odpowiednie narzędzie — migracje.
Każda z migracji określa zestaw akcji do wykonania w naszej bazie, takich jak tworzenie i modyfikowanie tabel.

Jako że nasza baza nie ma jeszcze żadnych tabel, będziemy musieli stworzyć migrację, by taką tabelę dodać.
Konwencja Ecto mówi, że tabele powinny mieć nazwy w liczbie mnogiej, zatem stwórzmy tabelę `people` (_ludzie_) — i tu zacznijmy naszą pracę z migracjami.

Najlepszym sposobem na utworzenie migracji jest użycie zadania Mixa `ecto.gen.migration <name>`, więc w tym przypadku powinniśmy uruchomić następujące polecenie:

```shell
$ mix ecto.gen.migration create_people
```

Wygeneruje ono nowy plik w folderze `priv/repo/migrations`, zawierający w nazwie datę i czas.
Jeśli przejdziemy do wymienionego wyżej katalogu i otworzymy plik z migracją, zobaczymy mniej więcej coś takiego:

```elixir
defmodule Friends.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do

  end
end
```

Zacznijmy od zmodyfikowania funkcji `change/0`, aby stworzyć nową tabelę `people` z kolumnami `name` (_imię_) i `age` (_wiek_):

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

Jak możesz zauważyć, zdefiniowaliśmy także typy danych dla tworzonych przez nas kolumn.
Dodaliśmy ponadto `null: false` i `default: 0` jako opcje.

Wróćmy do wiersza poleceń i uruchommy naszą migrację:

```shell
$ mix ecto.migrate
```

### Schematy

Teraz, gdy stworzyliśmy naszą pierwszą tabelę, musimy powiedzieć Ecto nieco więcej na jej temat, co częściowo zrobimy poprzez schematy (ang. _schema_).
Schemat jest modułem definiującym mapowanie do pól w bazie danych.

Podczas gdy w nazwach tabel Ecto faworyzuje liczbę mnogą, moduł nazywany jest zwykle w liczbie pojedynczej, zatem utwórzmy schemat `Person` (_osoba_), który będzie towarzyszył naszej tabeli.

Stwórzmy nowy schemat w pliku `lib/friends/person.ex`:

```elixir
defmodule Friends.Person do
  use Ecto.Schema

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

Możemy tu zauważyć, że moduł `Friends.Person` mówi Ecto, że ten schemat odnosi się do tabeli `people`, która zawiera dwie kolumny: `name` — z typem danych `string`, a także `age` — liczbę całkowitą z zerem jako wartością domyślną.

Rzućmy okiem na nasz schemat, otwierając `iex -S mix` i tworząc nową osobę:

```elixir
iex> %Friends.Person{}
%Friends.Person{age: 0, name: nil}
```

Zgodnie z oczekiwaniami, jako wynik otrzymaliśmy nową strukturę `Person` z wartością domyślną w polu `age`.
Teraz stwórzmy „prawdziwą” osobę:

```elixir
iex> person = %Friends.Person{name: "Tom", age: 11}
%Friends.Person{age: 11, name: "Tom"}
```

Ponieważ modele są po prostu strukturami, możemy wchodzić z nimi w interakcje tak, jak do tego przywykliśmy:

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

Możemy również zmieniać nasze schematy dokładnie tak, jak w dowolnej mapie czy strukturze w Elixirze:

```elixir
iex> %{person | age: 18}
%Friends.Person{age: 18, name: "Tom"}
iex> Map.put(person, :name, "Jerry")
%Friends.Person{age: 18, name: "Jerry"}
```

W naszej kolejnej lekcji omówimy zestawy zmian — _changesety_ — i zobaczymy, w jaki sposób możemy walidować zmiany w danych i wreszcie jak zapisać je w naszej bazie.
