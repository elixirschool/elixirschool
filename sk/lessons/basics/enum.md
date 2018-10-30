---
version: 1.4.0
title: Enum
---

Sada algoritmov pre iterovanie nad kolekciami.

{% include toc.html %}

## Enum

Modul `Enum` obsahuje viac ako 70 funkcií pre prácu s kolekciami. Všetky kolekcie, o ktoré sme spomínali v [predchádzajúcej lekcii](../collections/), okrem tuples, sú iterovateľné.

Táto lekcia pokrýva len zopár dostupných funkcii, ale môžeme ich preskúmať aj sami.
Spravme malý experiment v IEx.

```elixir
iex> Enum.__info__(:functions) |> Enum.each(fn({function, arity}) ->
...>   IO.puts "#{function}/#{arity}"
...> end)
all?/1
all?/2
any?/1
any?/2
at/2
at/3
...
```

Teraz vidíme, že máme obrovské množstvo funkcionality vďaka veľmi dobrému dôvodu. Iterovanie nad kolekciami je jadrom funkcionálneho programovania a veľmi užitočná vec.
Pri použití s ďalšími výhodami Elixiru, ako je napríklad dokumentácia, ktorá nie je občanom druhej triedy, ako sme mohli vidieť, to môže byť tiež neuveriteľným posilnením pre vývojára.

Kompletný zoznam funkcií nájdete v oficiálnej dokumentácii modulu [`Enum`](https://hexdocs.pm/elixir/Enum.html). Na prácu s "lazy enumeration" môžeme použiť funkcie z modulu [`Stream`](https://hexdocs.pm/elixir/Stream.html).

### all?

Funkcia `all?/2`, rovnako ako väčšina ostatných funkcií z modulu `Enum`, berie ako svoj argument funkciu, ktorú potom postupne aplikuje na všetky prvky kolekcie. V prípade `all?/2`, všetky prvky musia vrátiť `true`, inak funkcia vráti hodnotu `false`:

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

Na rozdiel od predošlej funkcie, `any?/2` vráti `true` vtedy, ak sa *aspoň jeden* prvok kolekcie vyhodnotí ako `true`:

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk_every

Keď potrebujete rozbiť kolekciu do niekoľkých menších skupín, `chunk_every/2` je pravdepodobne funckia, ktorú hľadáte:

```elixir
iex> Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

Táto funkcia má niekoľko možností použitia, ale tu ich nebudeme rozoberať, môžete si ich pozrieť v [oficiálnej dokumentácii tejto funkcie](https://hexdocs.pm/elixir/Enum.html#chunk_every/4).

### chunk_by

Ak potrebujete rozdeliť kolekciu do menších skupín na základe niečoho iného, než ich veľkosť, môžeme použiť funkciu `chunk_by/2`. Ako argumenty funkcia berie kolekciu a funkciu. Ak sa zmení vrátená hodnota funkcie, začne sa vytvárať ďalšia kolekcia:

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
iex> Enum.chunk_by(["one", "two", "three", "four", "five", "six"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"], ["six"]]
```

### map_every

Niekedy rozdeľovanie kolekcie nie je presne to čo potrebujeme. V tomto prípade, môže byť `map_every/3` veľmi užitočná kde vykoná operáciu vo funkcii iba na každom `ntom` prvku, vždy začínajúc prvým:

```elixir
# Vykonaj funkciu na každom treťom prvku
iex> Enum.map_every([1, 2, 3, 4, 5, 6, 7, 8], 3, fn x -> x + 1000 end)
[1001, 2, 3, 1004, 5, 6, 1007, 8]
```

### each

Často sa stretnete s potrebou prechádzať kolekciu bez toho, aby ste vracali nejakú novú hodnotu. V tomto prípade použijeme `each/2`:

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
:ok
```

__Pozn.__: Funkcia `each/2` vracia atóm `:ok`.

### map

Aplikuje našu funkciu na každý prvok kolekcie a vytvorí novú kolekciu s hodnotami, ktoré vrátila funkcia:

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

`min/1` nájde najmenšiu hodnotu v kolekcii:

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

`min/2` vykoná to isté, ale v prípade, že kolekcia je prázdna, dovoľuje nám špecifikovať funkciu, ktorá vráti minimálnu hodnotu.

```elixir
iex> Enum.min([], fn -> :foo end)
:foo
```

### max

`max/1` vráti najväčšiu hodnotu v kolekcii:

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

`max/2` je pre `max/1` to isté, ako je `min/2` pre `min/1`:

```elixir
Enum.max([], fn -> :bar end)
:bar
```

### filter

Funkcia `filter/2` nám umožní filtrovať kolekciu aby sme dostali len tie prvky, pre ktoré sa daná funkcia vyhodnotí ako `true`.

```elixir
iex> Enum.filter([1, 2, 3, 4], fn(x) -> rem(x, 2) == 0 end)
[2, 4]
```

### reduce

S `reduce/3` môžeme našu kolekciu zredukovať na jedinú hodnotu. Spravíme to tým, že poskytneme funkcii počiatočnú hodnotu akumulátora (`10` v príklade nižšie). Ak nedodáme žiadny akumulátor je použitý prvý prvok kolekcie:

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16

iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6

iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
```

### sort

Na triedenie kolekcií máme k dispozícii dve sort funkcie.

`sort/1` používa Erlangovo term ordering (triedenie podľa priority dátových typov) na určenie poradia prvkov:

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

Zatiaľ čo `sort/2` nám umožňuje dodať vlastnú funkciu na určenie poradia prvkov:

```elixir
# s triediacou funkciou
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# bez triediacej funkcie
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq_by

Môžeme použiť `uniq_by/2` na odstránenie duplikátov z našich kolekcii:

```elixir
iex> Enum.uniq_by([1, 2, 3, 2, 1, 1, 1, 1, 1], fn x -> x end)
[1, 2, 3]
```
