---
version: 0.9.0
layout: page
title: Riadiace štruktúry
category: basics
order: 5
lang: sk
---

In this lesson we will look at the control structures available to us in Elixir.
V tejto lekcii sa pozrieme na riadiace štruktúry jazyka Elixir.

{% include toc.html %}

## `if` a `unless`

Na funkciu `if` ste už pravdepodobne narazili a ak ste pracovali s Ruby, poznáte aj `unless`. V Elixire fungujú úplne rovnako, no sú implementované ako makrá, nie sú to skutočné jazykové konštrukty. Ich implementáciu si môžete pozrieť v dokumentácii [modulu Kernel](https://hexdocs.pm/elixir/#!Kernel.html).

Len pre pripomenutie: je dôležité si uvedomiť, že jediné hodnoty, ktoré Elixir vyhodnotí ako `false` (v angličtine sa používa výraz *falsey*), sú hodnoty `nil` a `false`. Všetko ostatné sa vyhodnotí ako `true` (*truthy*).

```elixir
iex> if String.valid?("Hello") do
...>   "Valid string!"
...> else
...>   "Invalid string."
...> end
"Valid string!"

iex> if "a string value" do
...>   "Truthy"
...> end
"Truthy"
```

Použitie `unless` je analogické k `if` - pracuje opačne, t.j. ako *if not*:

```elixir
iex> unless is_integer("hello") do
...>   "Not an Int"
...> end
"Not an Int"
```

## `case`

Ak potrebujeme hodnotu porovnať s viacerými možnosťami (vzormi), môžeme použiť `case`:

```elixir
iex> case {:ok, "Hello World"} do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```

Špeciálna premenná `_` má v `case` význam *žolíka*, teda matchne čokoľvek. Používa sa podobne, ako *else* alebo *default* vetva v iných jazykoch. Bez nej nám `case` vyhodí chybu, ak sa mu nepodarí matchnúť hodnotu do niektorej zo svojich vetiev:

```elixir
iex> case :even do
...>   :odd -> "Odd"
...> end
** (CaseClauseError) no case clause matching: :even

iex> case :even do
...>   :odd -> "Odd"
...>   _ -> "Not Odd"
...> end
"Not Odd"
```

Keďže výraz `case` je založený na pattern matchingu, platia preň všetky jeho pravidlá a obmedzenia. Ak chceme matchovať oproti existujúcim premenným (t.j. nepriraďovať do nich), musíme použiť operátor *pin* (`^`):

```elixir
iex> pie = 3.14 
3.14
iex> case "cherry pie" do
...>   ^pie -> "Not so tasty"
...>   pie -> "I bet #{pie} is tasty"
...> end
"I bet cherry pie is tasty"
```

Výborná vec, ktorú nám `case` umožňuje použiť, sú tzv. *guard clauses* (hraničné podmienky):

_Nasledujúci príklad pochádza priamo z oficiálnej príručky Elixiru [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#case)._

```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "Will match"
...>   _ ->
...>     "Won't match"
...> end
"Will match"
```

Pozrite si príslušnú kapitolu v oficiálnej dokumentácii [Expressions allowed in guard clauses](http://elixir-lang.org/getting-started/case-cond-and-if.html#expressions-in-guard-clauses).


## `cond`

Keď potrebujeme vetviť na základe podmienok, nie hodnôt, použijeme `cond` - funguje to podobne ako séria `else if` v iných jazykoch:

_Nasledujúci príklad pochádza priamo z oficiálnej príručky Elixiru [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#cond)._

```elixir
iex> cond do
...>   2 + 2 == 5 ->
...>     "Do tejto vetvy sa nedostaneme"
...>   2 * 2 == 3 ->
...>     "Ani do tejto"
...>   1 + 1 == 2 ->
...>     "No do tejto áno"
...> end
"No do tejto áno"
```

Podobne ako `case` aj `cond` vyhodí chybu, ak nenájde použiteľnú vetvu. V tom prípade musíme vytvoriť vetvu s podmienkou `true`, ktorá takéto prípady odchytí:

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```
