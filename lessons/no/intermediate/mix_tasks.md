%{
  version: "1.0.1",
  title: "Egnedefinerte Mix Tasks",
  excerpt: """
  Å lage egendefinerte Mix tasks for dine Elixir prosjekter.
  """
}
---

## Introduksjon

Det er ikke uvanlig at du har lyst til å utvide Elixir applikasjonene dine med funksjonalitet, dette kan du gjøre ved å lage egne Mix tasks for ditt prosjekt, la oss ta en titt på en Mix task som allerede eksisterer:

```shell
$ mix phx.new my_phoenix_app

* creating my_phoenix_app/config/config.exs
* creating my_phoenix_app/config/dev.exs
* creating my_phoenix_app/config/prod.exs
* creating my_phoenix_app/config/prod.secret.exs
* creating my_phoenix_app/config/test.exs
* creating my_phoenix_app/lib/my_phoenix_app.ex
* creating my_phoenix_app/lib/my_phoenix_app/endpoint.ex
* creating my_phoenix_app/test/views/error_view_test.exs
...
```

Som vi kan se fra shell kommandoen over, så har Phoenix rammeverket en egen Mix task for å lage et nytt prosjekt. Hva om vi kunne lagd noe lignende for vårt prosjekt?
Det er akkurat det vi skal gjøre, og Elixir gjør det veldig enkelt for oss.

## Setup

La oss sette opp en veldig enkel Mix applikasjon.

```shell
$ mix new hello

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/hello.ex
* creating test
* creating test/test_helper.exs
* creating test/hello_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

cd hello
mix test

Run "mix help" for more commands.
```

I vår **lib/hello.ex** fil som Mix lagde for oss, la oss lage en enkel funksjon som vil skrive ut "Hello, World!"

```elixir
defmodule Hello do
  @doc """
  Output's `Hello, World!` everytime.
  """
  def say do
    IO.puts("Hello, World!")
  end
end
```

## Egendefinerte Mix Task

La oss lage en egendefinert Mix task. Lag en ny mappe og fil **hello/lib/mix/tasks/hello.ex** i denne filen, skriv inn dette.

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Simply runs the Hello.say/0 command."
  def run(_) do
    # Kaller vår Hello.say() funksjon fra tidligere
    Hello.say()
  end
end
```

Legg merke til hvordan defmodule er definert med `Mix.Tasks` etterfulgt av navnet vi ønsker og ta i bruk når vi skal ta den i bruk fra terminalen. På andre linje tar vi i bruk `use Mix.Task` som tar med seg `Mix.Task` oppførselen inn i navneområdet. Vi deklarer så run funksjonen som ignorer argumenter. I denne funksjonen, så kaller vi på say `funksjonen` i `Hello` modulen.

## Mix Tasks i Aksjon

La oss prøve ut vår Mix task. Så lenge vi er i samme mappe, så burde det fungere. Fra terminalen, skriv inn `mix hello`, og vi burde se:

```shell
$ mix hello
Hello, World!
```

Mix er veldig vennlig. Den vet at det er vanlig å gjøre stavefeil, så den bruker en teknikk som kalles fuzzy string matching for anbefalinger:

```shell
$ mix hell
** (Mix) The task "hell" could not be found. Did you mean "hello"?
```

La du også merke til at vi introduserte en ny modul attributt, `@shortdoc`? Den kommer godt med når andre brukere skal ta i bruk applikasjonen, et eksempel vil være når brukeren skriver inn `mix help` kommandoen fra terminalen.

```shell
$ mix help

mix app.start         # Starter alle registrerte applikasjoner
...
mix hello             # Kaller Hello.say/0 funksjonen.
...
```
