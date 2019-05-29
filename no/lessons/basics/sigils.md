---
version: 0.9.0
title: Sigiler
---

Bruke og lage sigiler.

{% include toc.html %}

## Sigil Oversikt

Elixir har en alternativ syntaks for å representere og jobbe med literaler. En sigil starter med en tilde `~` etterfulgt av en bokstav. Elixir inkluderer et par standard sigiler, men det er også mulig å opprette sine egne sigiler.

En liste av tilgjengelige sigiler:

  - `~C` Lager en enkel karakterliste **uten** avsnitt eller tekst interpolasjon
  - `~c` Lager en enkel karakterliste **med** avsnitt eller tekst interpolasjon
  - `~R` Lager et regulært uttrykk **uten** avsnitt og tekst interpolasjon
  - `~r` Lager et regulært uttrykk **med** avsnitt og tekst interpolasjon
  - `~S` Lager en streng **uten** avsnitt og tekst interpolasjon
  - `~s` Lager en streng **med** avsnitt eller tekst interpolasjon
  - `~W` Lager en liste av ord **uten** avsnitt og tekst interpolasjon
  - `~w` Lager en liste av ord **med** avsnitt og tekst interpolasjon

Skilletegn i Elixir:

  - `<...>` Et par av vinkelparenteser
  - `{...}` Et par av krøllete parenteser
  - `[...]` Et par av firkant parenteser
  - `(...)` Et par av parenteser
  - `|...|` Et par av loddrett strek
  - `/.../` Et par av skråstrek
  - `"..."` Et par av dobbelt anførselstegn
  - `'...'` Et par av enkelte anførselstegn

### Enkel karakterliste

Sigilet `~c` og `~C` lager en enkel karakterliste, eksempel:


```elixir
iex> ~c/2 + 7 = #{2 + 7}/
'2 + 7 = 9'

iex> ~C/2 + 7 = #{2 + 7}/
'2 + 7 = \#{2 + 7}'
```

Vi kan se at `~c` tekst interpolerer regnestykket, mens ~`C` ikke gjør det. Slike forskjeller mellom små og store bokstaver er ganske vanlig med de innebygde sigilene.

### Regulære Uttrykk

Sigilene `~r` og `~R` er brukt til å representere regulære uttrykk. Vi kan enten lage de på sparket, eller benytte de i funksjonene som tar i bruk Regex. For eksempel:

```elixir
iex> re = ~r/elixir/
~r/elixir/

iex> "Elixir" =~ re
false

iex> "elixir" =~ re
true
```

I den første testen tester vi for ekvalitet, og vi ser at Elixir ikke er ekvivalent med det regulære uttrykket. Dette er fordi E-en i `Elixir` har stor forbokstav, mens det regulære uttrykket kun sjekker for små bokstaver. Elixir støtter regulære uttrykk som er kompatible med Perl. Vi kan legge til en `i` i enden av sigilet for å unngå at den skiler mellom stor og liten bokstav:

```elixir
iex> re = ~r/elixir/i
~r/elixir/i

iex> "Elixir" =~ re
true

iex> "elixir" =~ re
true
```

Elixir har en innebygd Regex modul [Regex](https://hexdocs.pm/elixir/Regex.html) som bygger videre på Erlang sitt regulære uttrykk bibliotek. La oss implementere Regex.split/2 ved å bruke en regex sigil

```elixir
iex> string = "100_000_000"
"100_000_000"

iex> Regex.split(~r/_/, string)
["100", "000", "000"]
```

Strengen `"100_000_000"` er splittet på understreken takket være `~r/_/` sigilet, og Regex.split returnerer en liste.

### Streng

`~s` og `~S` sigilene er brukt for å lage en større mengde med tekst, for eksempel:

```elixir
iex> ~s/Katten i hatten på matta/
"Katten i hatten på matta"

iex> ~S/Katten i hatten på matta/
"Katten i hatten på matta"
```

Forskjellen er likt med karakter liste sigilet som vi så på tidligere. Det som er forskjellig er bruken av avsnitt og slike sekvenser. For eksempel:

```elixir
iex> ~s/Velkommen til elixir #{String.downcase "SKOLEN"}/
"velkommen til elixir skolen"

iex> ~S/velkommen til elixir #{String.downcase "SKOLEN"}/
"velkommen til elixir \#{String.downcase \"SKOLEN\"}"
```

### Ordlister

Ordlistesigilet kan spare både tid og antall tastetrykk. For eksempel:

```elixir
iex> ~w/jeg elsker elixir skolen/
["jeg", "elsker", "elixir", "skolen"]

iex> ~W/jeg elsker elixir skolen/
["jeg", "elsker", "elixir", "skolen"]
```

Vi kan se at det som er skilt med skilletegn er separert med mellomrom til en liste. Men, det er ingen forskjell mellom disse to eksemplene. Forskjellen kommer med tekstinterpolering og avsnittssekvenser. Ta det følgende eksempelet:

```elixir
iex> ~w/jeg elsker #{'e'}lixir skolen/
["i", "love", "elixir", "school"]

iex> ~W/jeg elsker #{'e'}lixir skolen/
["jeg", "elsker", "\#{'e'}lixir", "skolen"]
```

## Å Lage Sigiler

Et av målene til Elixir er å være et utvidtbart programmeringsspråk. I dette eksempelet, så vil vi lage et sigil for å konverterer en tekststreng i små bokstaver til store bokstaver. Etter som det allerede er en funksjon for dette i standard biblioteket (`String.upcase/1`), så vil vi lage en sigil som tar i bruk denne funksjonen.

```elixir

iex> defmodule MineSigiler do
...>   def sigil_u(string, []), do: String.upcase(string)
...> end

iex> import MineSigiler
nil

iex> ~u/elixir skolen/
ELIXIR SKOLEN
```

Først definerer vi en modul med navnet `MineSigiler`. Vi lager så en funksjon med navnet `sigil_u`. Siden Elixir ikke har en standard `~u` sigil, kan vi bruke dette tegnet. `_u` endelsen i funksjonen indikerer at vi ønsker å benytte bokstaven `u` etter tilde ~ tegnet for å benytte sigilen. Når man lager en egen funksjon som skal fungere som en sigil, kreves det to argumenter - et input, og en liste.
