%{
  version: "2.4.0",
  title: "Basics",
  excerpt: """
  Ecto ist ein offizielles Elixir-Projekt, das einen Datenbank-Wrapper und eine integrierte Abfragesprache bereitstellt. Mit Ecto sind wir in der Lage, Migrationen zu erstellen, Schemmas zu definieren, Datensätze einzufügen, zu aktualisieren und diese abzufragen.
  """
}
---

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

Wir sagen dem Modul auch, dass es die Konfiguration in der `:friends` Elixir Applikation findet und welchen Adapter wir verwenden: `Ecto.Adapters.Postgres`.

Als Nächstes konfigurieren wir das `Friends.Repo` als einen Supervisor innerhalb unseres Supervisor-Baums in `lib/friends/application.ex`.
Das wird den Ecto Prozess automatisch beim Applikationsstart starten.

```elixir
  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      Friends.Repo,
    ]

  ...
```

Danach müssen wir das Repo noch in unserer `config/config.exs` Datei definieren.

```elixir
config :friends, ecto_repos: [Friends.Repo]
```
Somit erlauben wir unserer Applikation, Ecto mix Kommandos von der Kommandozeile auszuführen.

Nun ist das Repository vollständig konfiguriert.

Jetzt können wir eine Datenbank mit folgendem Kommando erstellen:

```shell
$ mix ecto.create
```

Alle notwendigen Informationen inklusive des Datenbanknamens nimmt Ecto aus der `config/config.exs` Datei.

Wenn Fehler auftreten musst du sicherstellen, dass die Konfiguration korrekt ist und dass deine Postgres-Instanz läuft.

### Migrations

Um Tabellen innerhalb der Postgres-Datenbank zu erstellen und zu modifizieren, stellt uns Ecto Migrationen zur Verfügung.
Jede Migration beschreibt eine Reihe von Aktionen, die mit unserer Datenbank durchgeführt werden müssen, z.B. welche Tabellen erstellt oder aktualisiert werden sollen.

Da unsere Datenbank noch keine Tabellen hat, müssen wir zuerst eine Migration erstellen.
Die Konvention in Ecto ist es, unsere Tabellen zu pluralisieren. Für unsere Anwendung beginnen wir mit der Migration für eine `people`-Tabelle.

Der beste Weg eine Migrationen zu erstellen, ist das Kommando `ecto.gen.migration <name>`:

```shell
$ mix ecto.gen.migration create_people
```

Dadurch wird eine neue Datei im Ordner `priv/repo/migrations` erzeugt, die einen Zeitstempel im Dateinamen enthält.
Wenn wir zu unserem Verzeichnis navigieren und die Migration öffnen, sollten wir so etwas wie folgendes sehen:

```elixir
defmodule Friends.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do

  end
end
```

Lasst uns nun die `change/0` Funktion anpassen um eine neue Tabelle `people` mit einer Spalte `name` und `age` zu erstellen:

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

Nebst dem Datentyp der Spalten haben wir auch `null: false` und `default: 0` als Optionen hinzugefügt.

Lasst uns nun die Migration in der Kommandozeile ausführen:

```shell
$ mix ecto.migrate
```

### Schemas

Nun müssen wir ein Ecto-Schema erstellen. Ein Schema ist ein Modul, das Zuordnungen zu den Feldern der zugrunde liegenden Datenbanktabelle definiert.

Während Ecto die Pluralisierung von Datenbanktabellennamen bevorzugt, ist das Schema typischerweise singulär. Für unser Beispiel erstellen wir ein `Person`-Schema das unsere Tabelle abbildet.

Lass uns unser neues Schema unter `lib/friends/person.ex` erstellen:

```elixir
defmodule Friends.Person do
  use Ecto.Schema

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

Hier kann man sehen, dass das Schema unseres `Friends.Person` Modul zur Tabelle `people` gehört welche aus 2 Spalten besteht: `name` welche ein String ist und `age`, als Integer mit einem Standardwert von `0`.

Werfen wir einen Blick auf unser Schema, indem wir `iex -S mix` ausführen und eine neue Person erstellen:

```elixir
iex> %Friends.Person{}
%Friends.Person{age: 0, name: nil}
```

Wie erwartet erhalten wir eine neue `Person` mit dem Standardwert `age`.

Jetzt lass uns eine "echte" Person erstellen:

```elixir
iex> person = %Friends.Person{name: "Tom", age: 11}
%Friends.Person{age: 11, name: "Tom"}
```

Da Schemas nur Strukturen sind, können wir mit unseren Daten so interagieren, wie wir es gewohnt sind:

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

In ähnlicher Weise können wir unsere Schemas aktualisieren, wie wir es mit jeder anderen Map oder Struct in Elixir tun würden:

```elixir
iex> %{person | age: 18}
%Friends.Person{age: 18, name: "Tom"}
iex> Map.put(person, :name, "Jerry")
%Friends.Person{age: 18, name: "Jerry"}
```

In unserer nächsten Lektion über Changesets werden wir uns ansehen, wie wir unsere Datenänderungen validieren und wie wir sie schließlich in der Datenbank speichern.
