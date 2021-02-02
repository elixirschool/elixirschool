%{
  version: "2.3.0",
  title: "Základy",
  excerpt: """
  Ecto je oficiálny Elixir projekt, ktorý poskytuje zaobalenie databázy a integrovaný jazyk na vytváranie dotazov. S Ectom sme schopní vytvárať migrácie, definovať schémy, vkladať/upravovať záznamy a dotazovať ich.
  """
}
---

### Adaptéry

Ecto podporuje rôzne databázy použitím adaptérov. Pár príkladov adaptérov sú:

* PostgreSQL
* MySQL
* SQLite

Pre túto lekciu nakonfigurujeme Ecto, aby používal adaptér PostgreSQL.

### Začíname

V priebehu tejto lekcie pokryjeme tri hlavné časti Ecta:

* Repozitár — poskytuje rozhranie našej databázy, vrátane pripojenia
* Migrácie — mechanizmus na vytváranie, modifikovanie, mazanie tabuliek a indexov v databáze
* Schémy — špeciálne štruktúry, ktoré reprezentujú záznamy v tabuľke

Na začiatok si vytvoríme aplikáciu so supervision stromom supervízorov (_supervision tree_).

```shell
$ mix new friends --sup
$ cd friends
```

Do súboru `mix.exs` pridáme ako závislosti balíčky `ecto` a `postgrex`.

```elixir
  defp deps do
    [
      {:ecto, "~> 2.0"},
      {:postgrex, "~> 0.11"}
    ]
  end
```

Stiahneme závislosti použitím príkazu

```shell
$ mix deps.get
```

#### Vytvorenie Repozitára

Repozitár v Ecte sa pripojí na dátové úložisko ako napríklad našu Postgres databázu.
Všetka komunikácia s databázou bude vykonávaná pomocou tohto repozitára.

Nastavíme repozitár spustením:

```shell
$ mix ecto.gen.repo -r Friends.Repo
```

Príkaz vygeneruje potrebnú konfiguráciu v `config/config.exs` na pripojenie k databáze vrátane adaptéru, ktorý má použiť.
Toto je konfiguračný súbor pre našu aplikáciu `Friends`

```elixir
config :friends, Friends.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "friends_repo",
  username: "postgres",
  password: "",
  hostname: "localhost"
```

Tu je nastavené ako sa Ecto pripojí na databázu.
Všimnite si, že bol ako adaptér zvolený `Ecto.Adapters.Postgres`.

Tiež bol vytvorený modul `Friends.Repo` v súbore `lib/friends/repo.ex`

```elixir
defmodule Friends.Repo do
  use Ecto.Repo, otp_app: :friends
end
```

Modul `Friends.Repo` budeme používať na dotazovanie databázy. Ako parameter dodáme kľúč, pod ktorým sa dá nájsť konfigurácia našej OTP aplikácie.

Ďalej nastavíme `Friends.Repo` ako supervízora v supervision strome našej aplikácie v `lib/friends/application.ex`.
To nám zabezpečí spustenie procesu Ecta, keď sa spustí naša aplikácia.

```elixir
  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      Friends.Repo,
    ]

  ...
```

Potom budeme musieť do nášho súboru `config/config.exs` pridať nasledujúci riadok:

```elixir
config :friends, ecto_repos: [Friends.Repo]
```

Toto umožní našej aplikácii spustiť `ecto mix` príkazy z príkazového riadku.

Práve sme úspešne nakonfigurovali repozitár!
Môžeme vytvoriť Postgres databázu pomocou nasledujúceho príkazu:

```shell
$ mix ecto.create
```

Ecto použije informácie v súbore `config/config.exs` na vytvorenie pripojenia do Postgresu a voľbu mena databázy.

Ak sa zobrazia nejaké chyby, overte, že nakonfigurované informácie sú správne a že inštancia Postgresu beží.

### Migrácie

Na vytváranie a modifikovanie tabuliek v postgres databáze nám Ecto poskytuje migrácie.
Každá migrácia opisuje súbor akcií, ktoré majú byť vykonané na našej databáze, napr. ktoré tabuľky má vytvoriť alebo upraviť.

Keďže naša databáza nemá zatiaľ žiadne tabuľky, vytvoríme migráciu, ktorou nejaké pridáme.
V Ecte je konvenciou voliť názvy tabuliek v množnom čísle - pre našu aplikáciu budeme potrebovať tabuľku `people`.

Najlepší spôsob ako vytvoriť migrácie je mix príkaz `ecto.gen.migration <name>`, čiže v našom prípade:

```shell
$ mix ecto.gen.migration create_people
```

Toto nám vygeneruje nový súbor v zložke `priv/repo/migrations`, ktorý obsahovať v názve súboru timestamp (časovú značku).
Po otvorení vygenerovaního súboru (v adresári `priv/repo/migrations`) by sme mali vidieť niečo takéto:

```elixir
defmodule Friends.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do

  end
end
```

Začnime úpravou funkcie `change/0`, aby sme vytvorili novú tabuľku `people` so stĺpcami `name` a `age`:

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

Ako vidíme vyššie, stĺpcom sme definovali dátový typ, obmedzenie na nenulovú hodnotu (`null: false`) a predvolenú hodnotu (`default: 0`).

Teraz ale poďme do príkazového riadku a spusťme našu migráciu:

```shell
$ mix ecto.migrate
```

### Schémy

Potom ako sme vytvorili našú prvú tabuľku musíme Ectu o nej niečo povedať, čiastočne sa to robí pomocou použitia schém.
Schéma je modul, ktorý definuje mapovanie atribútov na stĺpce danej tabuľky v databáze.

Ecto síce uprednostňuje mená tabuliek v množnom čísle, ale meno schémy je poväčšine v jednotnom čísle, čiže vytvoríme schému `Person` k našej tabuľke.

Vytvoríme našu novú schému v `lib/friends/person.ex`:

```elixir
defmodule Friends.Person do
  use Ecto.Schema

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

Tu môžeme vidieť, že `Friends.Person` hovorí Ectu, že táto schéma popisuje tabuľku `people` a máme v nej dva stĺpce: reťazec `name` a celé číslo`age` s predvolenou hodnotou `0`.

Spustime si príkazom `iex -S mix` konzolu a pozrime sa, ako vyzerá naša schéma. Vyskúšajme si vytvoriť novú osobu:

```shell
iex> %Friends.Person{}
%Friends.Person{age: 0, name: nil}
```

Ako sme očakávali, dostaneme [štruktúru](https://elixirschool.com/sk/lessons/basics/modules/#structs) `Person` s predvolenou hodnotou pre atribút `age`.
Teraz vytvorme "reálnu" osobu:

```shell
iex> person = %Friends.Person{name: "Tom", age: 11}
%Friends.Person{age: 11, name: "Tom"}
```

Keďže schémy sú len štruktúry, môžeme pristupovať k našim dátam ako sme zvyknutí:

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

Podobne, môžeme upravovať naše schémy, ako by sme robili s akoukoľvek inou [mapou](https://elixirschool.com/sk/lessons/basics/collections/#mapy) alebo [štruktúrou](https://elixirschool.com/sk/lessons/basics/modules/#structs) v Elixire:

```elixir
iex> %{person | age: 18}
%Friends.Person{age: 18, name: "Tom"}
iex> Map.put(person, :name, "Jerry")
%Friends.Person{age: 11, name: "Jerry"}
```

V ďalšej lekcii o Changesetoch sa pozrieme na to ako validovať zmeny našich dát a ako ich uložiť do databázy.
