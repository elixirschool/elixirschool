---
layout: page
title: Sigily
category: basics
order: 10
lang: sk
---

Práca so sigilmi a ich vytváranie.

{% include toc.html %}

## Čo sú sigily

Sigily predstavujú alternatívnu syntax pre reprezentáciu a prácu s literálmi. Každý sigil začína znakom `~` (tilda) nasledovaným iným znakom, ktorý určuje druh sigilu. Jazyk Elixir má vstavaných niekoľko rôznych druhov sigilov, no ak potrebujeme, môžeme vytvoriť aj svoje vlastné druhy.

Zoznam vstavaných sigilov:

  - `~C` Vytvorí charlist (zoznam znakov) **bez** escapovania a interpolácie
  - `~c` Vytvorí charlist **s** escapovaním a interpoláciou
  - `~R` Vytvorí regulárny výraz **bez** escapovania a interpolácie
  - `~r` Vytvorí regulárny výraz **s** escapovaním a interpoláciou
  - `~S` Vytvorí reťazec **bez** escapovania a interpolácie
  - `~s` Vytvorí reťazec **s** escapovaním a interpoláciou
  - `~W` Vytvorí zoznam reťazcov  **bez** escapovania a interpolácie
  - `~w` Vytvorí zoznam reťazcov **s** escapovaním a interpoláciou

Po tilde a znaku určujúcom druh sigilu nasleduje vstup sigilu ohraničený oddeľovačmi. Ako oddeľovače môžeme použiť tieto znaky:

  - `<...>` Pár ostrých zátvoriek
  - `{...}` Pár zložených zátvoriek
  - `[...]` Pár hranatých zátvoriek
  - `(...)` Pár okrúhlych zátvoriek
  - `|...|` Pár pajp
  - `/.../` Pár pár lomítok (nie spätných!)
  - `"..."` Pár dvojitých úvodzoviek
  - `'...'` Pár jednoduchých úvodzoviek

Po uzatváracom oddeľovači môžy ešte nasledovať modifikátory (ak ich daný sigil podporuje).

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

Prvý test vráti `false`, pretože testovaný reťazec má prvé písmeno veľké, no výraz hľadá slovo `elixir` s malým `e`. Keďže Elixir používa regulárne výrazy podľa štandardu PCRE (Perl Complatible Regular Expressions), môžeme na koniec sigilu pripojiť modifikátor `i`, ktorým vypneme citlivosť na malé/veľké písmená (case sensitivity):

```elixir
iex> re = ~r/elixir/i
~r/elixir/i

iex> "Elixir" =~ re
true

iex> "elixir" =~ re
true
```

Okrem toho Elixir poskytuje [Regex](http://elixir-lang.org/docs/stable/elixir/Regex.html) API postavené na Erlangovej knižnici na prácu s regulárnymi výrazmi. V nasledujúcom príklade použijeme z tohto API funkciu `Regex.split/2` (rozdelí reťazec podľa regulárneho výrazu), ktorej ako argumenty posunieme `~r` sigil a reťazec, ktorý chceme rozdeliť:

```elixir
iex> string = "100_000_000"
"100_000_000"

iex> Regex.split(~r/_/, string)
["100", "000", "000"]
```

Ako vidíme, z reťazca `"100_000_000"` sme jeho rozdelením podľa `_` dostali zoznam podreťazcov.

### Reťazce

Sigily `~s` a `~S` sa používajú na generovanie reťazcov. Napríklad:

```elixir
iex> ~s/the cat in the hat on the mat/
"the cat in the hat on the mat"

iex> ~S/the cat in the hat on the mat/
"the cat in the hat on the mat"
```

Aký to má význam? Tento sigil nám napríklad umožňuje v prípade potreby použiť na ohraničenie reťazca iné oddeľovače, než štandardné `"`.

```elixir
iex> ~s/Hello "world"/
"Hello \"world\""

iex> ~s/welcome to elixir #{String.downcase "school"}/
"welcome to elixir school"

iex> ~S/welcome to elixir #{String.downcase "school"}/
"welcome to elixir \#{String.downcase \"school\"}"
```

### Zoznamy slov

Občas sa nám môže hodiť jednoduché vytvorenie zoznamu jednoslovných reťazcov pomocou sigilu `~w`. Ušetríme čas, klávesnicu a kód bude o kúsok čitateľnejší:

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

## Vlastné sigily

Jedeným z cieľov pri návrhu jazyka Elixir bola jeho jednoduchá rozšíriteľnosť. Nie je teda prekvapujúce, že nám umožňuje aj ľahko si vytvoriť vlastné druhy sigilov. V nasledujúcom príklade si vytvoríme špeciálny sigil na konverziu reťazcov na veľké písmená. V Elixire už na tento účel existuje funkcia `String.upcase/1`, takže ju v našom sigile použijeme:

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
