---
version: 1.1.0
title: Comprehensions
---

List comprehensions sú syntaktickým zjednodušením prechádzania kolekciami v Elixire. V tejto lekcii sa naučíme, ako ich používať na iterovanie a generovanie.

{% include toc.html %}

## Základy

Častým použitím comprehensions je stručnejší zápis iterovania nad `Enum` a `Stream`. Pozrime sa na jednoduchý príklad:

```elixir
iex> list = [1, 2, 3, 4, 5]
iex> for x <- list, do: x*x
[1, 4, 9, 16, 25]
```

Vidíme, že je použité kľúčové slovo `for` nasledované generátorom. Čo je generátor? Je to výraz, ktorý generuje vždy ďalší prvok pre každú novú iteráciu. V našom príklade to je `x <- [1, 2, 3, 4, 5]`.

Samozrejme, comprehensions nie sú limitované na zoznamy, môžeme ich použiť s ľubovoľnou kolekciou:

```elixir
# Zoznamy kľúčových slov
iex> for {_key, val} <- [one: 1, two: 2, three: 3], do: val
[1, 2, 3]

# Mapy
iex> for {k, v} <- %{"a" => "A", "b" => "B"}, do: {k, v}
[{"a", "A"}, {"b", "B"}]

# Binárne zoznamy
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
iex> list = [1, 2, 3, 4]
iex> for n <- list, times <- 1..n do
...>   String.duplicate("*", times)
...> end
["*", "*", "**", "*", "**", "***", "*", "**", "***", "****"]
```

Na lepšiu ilustráciu použime funkciu `IO.puts` na zobrazenie oboch vygenerovaných hodnôt:

```elixir
iex> for n <- list, times <- 1..n, do: IO.puts "#{n} - #{times}"
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

Comprehensions sú stále len syntaktickým zjednodušením a mali by sme ich použitie vždy dobre zvážiť.

## Filtre

Filtre môžeme brať ako guard výrazy pre comprehensions. Keď filtrovací výraz vráti pre niektorú hodnotu `false` alebo `nil`, bude daná hodnota ignorovaná a v `do` bloku preskočená. Poďme iterovať cez rozsah čísel od 1 do 10 a extrahovať iba párne čísla. Použijeme funkciu `is_even/1` z modulu Integer na kontrolu, či je číslo párne alebo nie.

```elixir
import Integer
iex> for x <- 1..10, is_even(x), do: x
[2, 4, 6, 8, 10]
```

Ako pri generátoroch, aj filtrov môžeme použiť naraz niekoľko - rozšírme rozsah čísel a potom filtrujme iba párne čísla ktoré sú zároveň deliteľné číslom 3.

```elixir
iex> for x <- 1..100,
...>   is_even(x),
...>   rem(x, 3) == 0, do: x
[6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 78, 84, 90, 96]
```

## Použitie `:into`

Čo ak chceme, aby výsledkom comprehension bolo niečo iné ako zoznam? Použijeme parameter `:into`! Tento parameter akceptuje ľubovoľnú štruktúru, ktorá implementuje protokol `Collectable`.

S pomocou `:into` skúsme zmeniť zoznam kľúčových slov na mapu:

```elixir
iex> for {k, v} <- [one: 1, two: 2, three: 3], into: %{}, do: {k, v}
%{one: 1, three: 3, two: 2}
```

Keďže bitstringy implementujú protokol `Collectable`, môžeme ich pomocou comprehension s parametrom `:into` zmeniť na normálne reťazce:

```elixir
iex> for c <- [72, 101, 108, 108, 111], into: "", do: <<c>>
"Hello"
```

To je všetko! Comprehensions sú jednoduchým a stručným spôsobom, ako iterovať cez kolekcie.
