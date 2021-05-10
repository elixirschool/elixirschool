%{
  version: "0.9.1",
  title: "Dokumentasjon",
  excerpt: """
  Dokumentering av elixir kode.
  """
}
---

## Kommentarer

Hvor mye vi kommenterer, og hva som ligger i kvalitetsdokumentasjon er et ofte diskutert tema i programmeringsverden. En ting er ihvertfall
sikkert, dokumentasjon er viktig både for oss selv, og de som jobber med koden vår.

Elixir behandler dokumentasjon som *first-class citizen*, noe som gir oss forskjellige funksjoner vi kan benytte oss av for å generere dokumentasjon i prosjektene våre. Elixir gir oss attributter for å kommentere kode. La oss ta en titt på 3 måter:

  - `#` - For å dokumentere en linje.
  - `@moduledoc` - For å dokumentere en modul.
  - `@doc` - For å dokumentere en funksjon.

### Dokumentere med enkeltlinjer

Den enkleste måten å kommentere kode, er enkeltlinjekommentering. På samme måte som i Ruby og Python, benytter Elixir `#`, eller et *hashtag* om du vil, for enkeltlinjekommentering.

For eksempel (greeting.exs):

```elixir
# Outputs 'Hello, chum.' to the console.
IO.puts("Hello, " <> "chum.")
```

Når du kjører scriptet ditt, vil Elixir ignorere alt fra `#` til slutten av linjen. Enkeltlinjekommentaren påvirker ikke ytelsen av scriptet, og når det ikke er helt klart hva koden din gjør, vil en liten kommentar gjøre det mye lettere for de som leser koden. Vær forsiktig med å ikke misbruke enkeltlinjekommentarer. Ingen liker forsøplet kode.  

### Dokumentere moduler

`@moduledoc` lar oss dokumentere en hel modul. Den skrives vanligvis rett under `defmodule` helt i toppen av fila. Under finner du noen eksempler som viser enkeltlinjekommentarer inne i `@moduledoc`.

```elixir
defmodule Greeter do
  @moduledoc """
  Provides a function `hello/1` to greet a human
  """

  def hello(name) do
    "Hello, " <> name
  end
end
```

Vi (eller andre) får tilgang til modulens dokumentasjon ved å bruke `h` hjelperfunksjonen i IEx.

```elixir
iex> c("greeter.ex", ".")
[Greeter]

iex> h Greeter

                Greeter

Provides a function hello/1 to greet a human
```

### Dokumentere funksjoner

På samme måte som Elixir lar oss dokumentere moduler, kan vi også dokumentere funksjoner. Vi benytter `@doc` for å dokumentere funksjoner, og den skrives rett over selve funksjonen:

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

Hvis vi fyrer opp IEX igjen, og bruker hjelperkommandoen (`h`) på funksjonen vi skrev inn i modulen, ser vi følgende:

```elixir
iex> c("greeter.ex")
[Greeter]

iex> h Greeter.hello

                def hello(name)

Prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"

iex>
```

La du merke til hvordan vi kan designe dokumentasjon med markup, og at terminalen printer det ut? Bortsett fra at at dette er skikkelig kult, og en fantastisk del av Elixir's store økosystem, blir det straks mer interessant når vi utforsker ExDoc, som genererer HTML dokumentasjon for oss!

**Merk:** `@spec` brukes for statistisk analyse av kode. <!-- TODO: Remove this as a comment, once advanced/typespec  is translated
For å lære mer, sjekk ut [Spesifikasjoner og Typer](../../advanced/typespec/). -->

## ExDoc

ExDoc er et offisielt Elixirprosjekt hostet på [GitHub](https://github.com/elixir-lang/ex_doc). ExDoc produserer **HTML (HyperText Markup Language) og online dokumentasjon** for Elixirprosjekter. Først, la oss lage et nytt Mix prosjekt for applikasjonen vår:

```bash
$ mix new greet_everyone

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/greet_everyone.ex
* creating test
* creating test/test_helper.exs
* creating test/greet_everyone_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd greet_everyone
    mix test

Run "mix help" for more commands.

$ cd greet_everyone

```

Kopier og lim inn koden fra `@doc` leksjonen inn i en fil som vi kaller `lib/greeter.ex`, og dobbeltsjekk at alt virker som det skal i terminalen. Nå som vi har et fungerende Mix prosjekt, starter vi IEx med `iex -S mix` kommandoen:

```bash
iex> h Greeter.hello

                def hello(name)

Prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"
```

### Installering

Forutsatt at alt virket som det skal, og at terminalen printet ut riktig, kan vi nå installere ExDoc. Vi behøver to Hex pakker, `:earmark` og `:ex_doc`. Legg de til i `mix.exs` filen inn i funksjonen `deps`:

```elixir
def deps do
  [{:earmark, "~> 0.1", only: :dev}, {:ex_doc, "~> 0.11", only: :dev}]
end
```

Med `only: :dev` spesifiserer vi at pakkene kun benyttes i utvikling, og ikke i produksjon. Men hvorfor Earmark? Earmark er en Markdown parser for Elixir, som ExDoc bruker for å gjøre om dokumentasjonen i `@moduledoc` og `@doc` til HTML.

Det er verdt å merke seg at du ikke MÅ bruke Earmark. Du kan bruke andre verktøy som Pandoc, Hoedown eller Cmark. Men disse behøver noe mer konfigurering. Du kan lese mer om det [her](https://github.com/elixir-lang/ex_doc#changing-the-markdown-tool). Vi bruker kun Earmark i denne leksjonen.

### Generere dokumentasjon

La oss gå videre. Fra terminalen, kjør disse to kommandoene:

```bash
$ mix deps.get # gets ExDoc + Earmark.
$ mix docs # makes the documentation.

Docs successfully generated.
View them at "doc/index.html".
```

Hvis alt gikk som det skal, vil du se en lignende melding i terminalen, som i eksemplet over. Hvis vi nå tar en titt i vårt Mix prosjekt, ser vi en ny mappe som heter **doc/**. I denne mappen ligger vår nygenererte dokumentasjon. Hvis vi besøker index siden i nettleseren ser vi følgende:

![ExDoc Screenshot 1]({% asset documentation_1.png @path %})

Vi kan se at Earmark og ExDoc har tatt dokumentasjonen i koden vår, og generert nydelig HTML dokumentasjon.

![ExDoc Screenshot 2]({% asset documentation_2.png @path %})

Vi kan på dette tidspunktet legge det ut på GitHub, vår egen nettside, eller [HexDocs](https://hexdocs.pm/).

## Beste Praksis

Dokumentasjon burde skrives etter retningslinjer for beste praksis. Siden Elixir er et temmelig nytt språk, er ennå ikke alle standarder satt. Fellesskapet rundt Elixir har forsøkt å lage slike retningslinjer for beste praksis. Du kan lese mer på [The Elixir Style Guide](https://github.com/niftyn8/elixir_style_guide).

  - Alltid dokumenter en modul.

```elixir
defmodule Greeter do
  @moduledoc """
  This is good documentation.
  """

end
```

  - Hvis du ikke ønsker å dokumentere en modul, **ikke** la den være tom. Merk heller modulen `false`, slik som:

```elixir
defmodule Greeter do
  @moduledoc false

end
```

 - Hvis du refererer til funksjoner i moduldokumentasjonen, gjør slik:

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 - Separer all kode en linje under `@moduledoc` slik som dette:

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  alias Goodbye.bye_bye
  # and so on...

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 - Bruk markdown i funksjoner for å gjøre de lettere å lese enten i IEX eller ExDoc.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

 - Forsøk å legge til noen kodeeksempler i dokumentasjonen. Dette vil også gjøre at du kan generere automatiske tester fra kodeeksemplene i en modul, funksjon eller makro med [ExUnit.DocTest][]. For å gjøre det, må du kalle `doctest/1` makroen fra testen, og skrive eksemplene etter retningslinjene i [den offisielle dokumentasjonen][ExUnit.DocTest].

[ExUnit.DocTest]: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html
