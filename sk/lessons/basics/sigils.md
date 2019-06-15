---
version: 1.0.1
title: Sigily
---

Práca so sigilmi a ich vytváranie.

{% include toc.html %}

## Čo sú sigily

Elixir poskytuje alternatívnu syntax na reprezentáciu a prácu s literálmi. Sigil začína znakom `~` (tilda) nasledovaným znakom. Jadro Elixiru má vstavaných niekoľko rôznych druhov sigilov, no ak potrebujeme, môžeme vytvoriť aj svoje vlastné druhy.

Zoznam dostupných sigilov obsahuje:

  - `~C` Vytvorí charlist (zoznam znakov) **bez** escapovania a interpolácie
  - `~c` Vytvorí charlist **s** escapovaním a interpoláciou
  - `~R` Vytvorí regulárny výraz **bez** escapovania a interpolácie
  - `~r` Vytvorí regulárny výraz **s** escapovaním a interpoláciou
  - `~S` Vytvorí reťazec **bez** escapovania a interpolácie
  - `~s` Vytvorí reťazec **s** escapovaním a interpoláciou
  - `~W` Vytvorí zoznam reťazcov  **bez** escapovania a interpolácie
  - `~w` Vytvorí zoznam reťazcov **s** escapovaním a interpoláciou
  - `~N` Vytvorí `NaiveDateTime` struct

Po tilde a znaku určujúcom druh sigilu nasleduje vstup sigilu ohraničený oddeľovačmi. Ako oddeľovače môžeme použiť tieto znaky:

  - `<...>` Pár ostrých zátvoriek
  - `{...}` Pár zložených zátvoriek
  - `[...]` Pár hranatých zátvoriek
  - `(...)` Pár okrúhlych zátvoriek
  - `|...|` Pár pajp
  - `/.../` Pár lomítok (nie spätných!)
  - `"..."` Pár dvojitých úvodzoviek
  - `'...'` Pár jednoduchých úvodzoviek

### Zoznamy znakov

Sigily `~c` a `~C` vytvoria zoznam znakov (character list, charlist):

```elixir
iex> ~c/2 + 7 = #{2 + 7}/
'2 + 7 = 9'

iex> ~C/2 + 7 = #{2 + 7}/
'2 + 7 = \#{2 + 7}'
```

Môžeme si všimnúť, že sigil s malým `~c` aplikuje interpoláciu, sigil s veľkým `~C` však nie. Tento vzor (malé/veľké písmeno) je pri zabudovaných sigiloch pravidlom.

**Poznámka:** zoznam znakov je v Elixire niečo úplne iné, než reťazec!

### Regulárne výrazy

Na reprezentáciu regulárnych výrazov (regexpov) slúžia v Elixire sigily `~r` a `~R`. Vytvorené výrazy môžme použiť buď priamo alebo cez funkcie na prácu s regulárnymi reťazcami:

```elixir
iex> re = ~r/elixir/
~r/elixir/

iex> "Elixir" =~ re
false

iex> "elixir" =~ re
true
```

Prvý test vráti `false`, pretože testovaný reťazec má prvé písmeno veľké, no výraz hľadá slovo `elixir` s malým `e`. Keďže Elixir používa regulárne výrazy podľa štandardu PCRE (Perl Compatible Regular Expressions), môžeme na koniec sigilu pripojiť modifikátor `i`, ktorým vypneme citlivosť na malé/veľké písmená (case sensitivity):

```elixir
iex> re = ~r/elixir/i
~r/elixir/i

iex> "Elixir" =~ re
true

iex> "elixir" =~ re
true
```

Okrem toho Elixir poskytuje [Regex](https://hexdocs.pm/elixir/Regex.html) API postavené na Erlangovej knižnici na prácu s regulárnymi výrazmi. Poďme implementovať `Regex.split/2` spolu s regexovým sigilom:

```elixir
iex> string = "100_000_000"
"100_000_000"

iex> Regex.split(~r/_/, string)
["100", "000", "000"]
```

Ako vidíme, reťazec `"100_000_000"` sme rozdelili podľa podtržníka vďaka nášmu sigilu `~r/_/`. Funkcia `Regex.split` nám vráti zoznam reťazcov.

### Reťazce

Sigily `~s` a `~S` sa používajú na generovanie reťazcov. Napríklad:

```elixir
iex> ~s/the cat in the hat on the mat/
"the cat in the hat on the mat"

iex> ~S/the cat in the hat on the mat/
"the cat in the hat on the mat"
```

V čom je rozdiel? Rozdiel je podobný ako pri sigile zoznamu znakov, ktorý sme si ukázali. Odpoveď je interpolácia a escapovanie reťazca. Ďalší príklad:

```elixir
iex> ~s/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir school"

iex> ~S/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir \#{String.downcase \"SCHOOL\"}"
```

### Zoznamy slov

Sigil na zoznamy slov sa nám môže hodiť z času na čas. Ušetrí nám čas, klávesnicu a hlavne zjednoduší čitateľnosť a zložitosť nášho kódu. Tu máme príklad:

```elixir
iex> ~w/i love elixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love elixir school/
["i", "love", "elixir", "school"]
```

Vidíme, že sigil rozdelil vstup na jednotlivé reťazce podľa prázdnych znakov (whitespace). Pri použití malého sigilu `~w` navyše funguje interpolácia:

```elixir
iex> ~w/i love #{'e'}lixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love #{'e'}lixir school/
["i", "love", "\#{'e'}lixir", "school"]
```

### NaiveDateTime

[NaiveDateTime](https://hexdocs.pm/elixir/NaiveDateTime.html) je užitočný na rýchle vytvorenie structu reprezentujúceho `DateTime` **bez** časového pásma.

Poväčšine by sme sa mali vyhnúť vytváraniu structu `NaiveDateTime` priamo, ale je to veľmi užitočné pri pattern matchovaní. Napríklad:

```elixir
iex> NaiveDateTime.from_iso8601("2015-01-23 23:50:07") == {:ok, ~N[2015-01-23 23:50:07]}
```

## Vytváranie sigilov

Jedným z cieľov jazyka Elixir bola jeho jednoduchá rozšíriteľnosť. Nie je teda prekvapením, že nám umožňuje aj ľahko si vytvoriť vlastné druhy sigilov. V nasledujúcom príklade si vytvoríme špeciálny sigil na konverziu reťazcov na veľké písmená. V Elixire už na tento účel existuje funkcia `String.upcase/1`, takže ju v našom sigile použijeme:

```elixir

iex> defmodule MySigils do
...>   def sigil_u(string, []), do: String.upcase(string)
...> end

iex> import MySigils
nil

iex> ~u/elixir school/
ELIXIR SCHOOL
```

Najprv sme si definovali modul `MySigils` a vňom funkciu `sigil_u`. Použitím `_u` v názve funkcie hovoríme, že sa náš sigil má volať `~u` (vstavaný sigil `~u` neexistuje, takže si ho zaberieme). Funkcia musí akceptovať dva argumenty: vstup a zoznam.
