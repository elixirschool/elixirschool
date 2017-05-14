---
version: 0.9.0
layout: page
title: Enum
category: basics
order: 3
lang: sk
---

Sada algoritmov pre iterovanie nad kolekciami.

{% include toc.html %}

## Enum

Modul `Enum` obsahuje vyše stovku funkcií pre prácu s kolekciami, o ktorých sme sa dozvedeli v minulej lekcii.

Táto lekcia pokrýva len malú podmnožinu týchto funkcií - kompletný zoznam aj s príkladmi použitia nájdete v oficiálnej dokumentácii modulu [`Enum`](https://hexdocs.pm/elixir/Enum.html). Zaujímať vás môžu aj funkcie na prácu s "lazy enumeration" z modulu [`Stream`](https://hexdocs.pm/elixir/Stream.html).

### all?

Funkcia `all?`, rovnako ako väčšina ostatných funkcii z modulu `Enum`, berie ako svoj argument funkciu, ktorú potom aplikuje na všetky prvky kolekcie. Ak táto funkcia vráti pre *všetky prvky* `true`, funkcia `all?` vráti hodnotu `true`, inak `false`:

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

Na rozdiel od predošlej, vráti funkcia `any?` hodnotu `true` vtedy, ak sa *aspoň jeden* prvok kolekcie vyhodnotí ako `true`.

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk

Keď potrebujete rozbiť kolekciu do niekoľkých menších, hodí sa vám funckia `chunk`:

```elixir
iex> Enum.chunk([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

Táto funckia má niekoľko možností použitia, pozrite sa do oficiálnej dokumentácie: [`chunk/2`](https://hexdocs.pm/elixir/Enum.html#chunk/2).

### chunk_by

Ak potrebujete rozdeliť kolekciu do menších na základe niečoho iného, než ich veľkosť, použite funkciu `chunk_by`. Ako argumenty funkcia berie kolekciu (Enum) a funkciu - ak sa zmení jej výstup, ukončí sa aktuálna podkolekcia a začne sa vytvárať ďalšia:

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
iex> Enum.chunk_by(["one", "two", "three", "four", "five", "six"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"], ["six"]]
```

### each

Často sa stretnete s potrebou cyklovať nad kolekciu bez toho, aby ste vracali nejakú novú hodnotu. Na tento účel je ideálna funckia `each`:

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
:ok
```

__Poznámka__: Funkcia `each` vracia atom `:ok`.

### map

Aplikuje poskutnutú funkciu na každý prvok kolekcie a vráti novú kolekciu s výsledkami týchto aplikácií:

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x * 2 end)
[0, 2, 4, 6]
```

### min

Nájde a vráti najmenšiu hodnotu v kolekcii:

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

### max

Nájde a vráti najväčšiu hodnotu v kolekcii:

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

### reduce

Postupne zredukuje kolekciu na jedinú hodnotu. Na vstupe očakáva kolekciu, počiatočnú hodnotu akumulátora (ak žiadna nie je poskytnutá, použije sa prvý prvok kolekcie) a funkciu. Táto funkcia dostane ako argumenty vždy ďalší prvok kolekcie a aktuálnu hodnotu akumulátora. Vráti novú hodnotu akumulátora, ktorá sa zasa použije v ďalšom kole cyklu:

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16
iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6
iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
```

### sort

Na triedenie kolekcií máme k dispozícii dve `sort` funkcie. Prvá používa na určenie poradia prvkov *term ordering* jazyka Elixir (t.j. triedi podľa priority dátových typov):

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

Druhá možnosť je poskytnúť ako druhý argument triediacu funkciu:

```elixir
# s triediacou funkciou
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# bez triediacej funkcie
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq

Odstráni z kolekcie duplikáty:

```elixir
iex> Enum.uniq([1, 2, 2, 3, 3, 3, 4, 4, 4, 4])
[1, 2, 3, 4]
```
