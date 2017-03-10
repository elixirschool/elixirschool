---
version: 0.9.0
layout: page
title: Comprehensions
category: basics
order: 13
lang: sk
---

List comprehensions (*komprehenžny?*) sú syntaktickým zjednodučením cyklovania nad dátovými štruktúrami typu enumerable (kolekciami ako zoznamy a podobne). V tento lekcii sa naučíme, ako ich používať na iterovanie a generovanie.

{% include toc.html %}

## Základy

Častým použitím komprehenžnov je stručnejší zápis iterovania nad `Enum` a `Stream`. Pozrime sa na jednoduchý príklad:

```elixir
iex> zoznam = [1, 2, 3, 4, 5]
iex> for x <- zoznam, do: x*x
[1, 4, 9, 16, 25]
```

Vidíme, že je použité kľúčové slovo `for` nasledované generátorom. Čo je generátor? Je to výraz, ktorý generuje vždy ďalší prvok pre každú novú iteráciu. V našom príklade to je `x <- [1, 2, 3, 4]`.

Samozrejme, komprehenžny nie sú limitované na zoznamy, môžeme ich použiť na ľubovoľnú štruktúru typu enumerable:

```elixir
# kľúčované zoznamy
iex> for {_key, val} <- [one: 1, two: 2, three: 3], do: val
[1, 2, 3]

# Mapy
iex> for {k, v} <- %{"a" => "A", "b" => "B"}, do: {k, v}
[{"a", "A"}, {"b", "B"}]

# Reťazce
iex> for <<c <- "hello">>, do: <<c>>
["h", "e", "l", "l", "o"]
```

Ako ste si mohli všimnúť, generátory používajú pattern matching na priraďovanie hodnoty do premennej na ľavej strane. Ak sa nenájde zhoda (match), hodnota je ignorovaná a iterácia sa preskočí:

```elixir
iex> for {:ok, val} <- [ok: "Hello", error: "Unknown", ok: "World"], do: val
["Hello", "World"]
```

Môžeme dokonca použiť viacero generátorov - funguje to podobne, ako vnorené cykly:

```elixir
iex> zoznam = [1, 2, 3, 4]
iex> for n <- zoznam, pocet <- 1..n do
...>   String.duplicate("*", pocet)
...> end
["*", "*", "**", "*", "**", "***", "*", "**", "***", "****"]
```

Na lepšiu ilustráciu použime funkciu `IO.puts` na zobrazenie oboch vygenerovaných hodnôt:

```elixir
iex> for n <- zoznam, pocet <- 1..n, do: IO.puts "#{n} - #{pocet}"
1 - 1
2 - 1
2 - 2
3 - 1
3 - 2
3 - 3
4 - 1
4 - 2
4 - 3
4 - 4
```

Pozor: komprehenžny sú stále len syntaktickým cukrom a mali by sme ich použitie vždy dobre zvážiť.

## Filtre

Filtre môžeme brať ako guard výrazy pre komprehenžny. Keď filtrovací výraz vráti pre niektorú hodnotu `false` alebo `nil`, bude daná hodnota ignorovaná a v `do` bloku preskočená.

V nasledujúcom príklade budeme ignorovať všetky nepárne čísla (využijeme funkciu `is_even` z modulu Integer):

```elixir
import Integer
iex> for x <- 1..10, is_even(x), do: x
[2, 4, 6, 8, 10]
```

Aj filtrov môžee použiť niekoľko naraz - napríklad takto by sme preskočili všetky hodnoty, ktoré nie sú párne a zároveň násobkom čísla 3:

```elixir
iex> for x <- 1..100,
...>   is_even(x),
...>   rem(x, 3) == 0, do: x
[6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 78, 84, 90, 96]
```

## Použitie `:into`

Čo ak chceme v komprehenžne pracovať s niečim iným, než zoznamom? Použijeme parameter `:into`! Tento parameter akceptuje ľubovoľnú štruktúru, ktorá implementuje protokol `Collectable`.

Skúsme takto zmeniť keyword list na mapu:

```elixir
iex> for {k, v} <- [one: 1, two: 2, three: 3], into: %{}, do: {k, v}
%{one: 1, three: 3, two: 2}
```

Keďže bitstringy sú typu enumerable, môžeme ich pomocou komprehenžny s parametrom `:into` zmeniť na normálne reťazce:

```elixir
iex> for c <- [72, 101, 108, 108, 111], into: "", do: <<c>>
"Hello"
```

To je všetko! Komprehenžny sú jednoduchým a stručným spôsobom, ako iterovať cez kolekciue.
