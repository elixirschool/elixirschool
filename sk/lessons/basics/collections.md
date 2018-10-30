---
version: 1.2.3
title: Kolekcie
---

Zoznamy, tuples, keyword listy a mapy.

{% include toc.html %}

## Zoznamy

Zoznamy (lists) sú jednoduché kolekcie hodnôt, ktoré môžu obsahovať viacero dátových typov. Prvky sa v zozname môžu aj opakovať:

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir implementuje zoznamy ako lineárne zoznamy (*linked lists*). To znamená, že prístup k dĺžke zoznamu je operácia s lineárnou časovou zložitosťou (`O(n)`). Z tohto dôvodu je zvyčajne rýchlejšie nové prvky pridávať na začiatok zoznamu, než na jeho koniec:

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
# Prepending (fast)
iex> ["π"] ++ list
["π", 3.14, :pie, "Apple"]
# Appending (slow)
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```

### Spájanie zoznamov

Spájanie zoznamov využíva operátor `++/2`:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

Poznámka k formátu zápisu funkcií a operátorov, ktorý je použitý v príkladoch: v Elixire má názov funkcie dve časti: meno funkcie (v tomto prípade `++`) a početnosť parametrov (_arity_ - v tomto prípade `2`). Operátor `++` teda vyžaduje, aby sme mu dodali 2 parametre pri jeho volaní. Pri popise väčšiny funkcii je uvedené jej meno a počet parametrov, ktoré sú spojené lomítkom. O tomto si povieme detailnejšie neskôr, táto poznámka ti zatiaľ pomôže pochopiť túto notáciu.

### Odčítavanie zoznamov

Podporu odčítania zoznamov (list subtraction) poskytuje operátor `--/2`, kde je bezpečné odčítať aj chýbajúcu hodnotu:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

Musíme však dbať na duplicitné hodnoty. Pre každý prvok na pravej strane operácie sa vymaže prvý výskyt na ľavej strane:

```elixir
iex> [1,2,2,3,2,3] -- [1,2,3,2]
[2, 3]
```

*Pozn.:* Odčítanie zoznamov používa [striktné porovnanie](../basics/#comparison) na nájdenie zhodných hodnôt.

### Head / Tail

Pri používaní zoznamov je bežné pracovať s hlavou a chvostom zoznamu. Hlava (_head_) je prvý element zoznamu a chvost (_tail_) je zoznam, ktorý obsahuje zvyšok prvkov. Elixir poskytuje dve užitočné funkcie, `hd` a `tl`, pre prácu s týmito časťami:

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

Naviac môžeme použiť [pattern matching](../pattern-matching/) a operátor `|` (cons), ktorý rozdelí zoznam na hlavu a chvost. O tomto vzore si povieme v neskorších lekciách:

```elixir
iex> [head | tail] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> head
3.14
iex> tail
[:pie, "Apple"]
```

## Tuples

Tuples sú podobné zoznamom, no v pamäti sú uložené ako súvislá oblasť. Vďaka tomu je prístup k dĺžke rýchly ale modifikácia je nákladná, keďže celý zmenený tuple musí byť prekopírovaný do pamäte. Tuples definujeme pomocou zložených zátvoriek:

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

Bežne sa tuples používajú ako mechanizmus pre návratové hodnoty z funkcií - v kapitole o [pattern matchingu](../pattern-matching/) si ukážeme, ako užitočné to skutočne je:

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... obsah ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Zoznamy kľúčových slov

Zoznamy kľúčových slov (keyword lists) a mapy sú asociatívnymi kolekciami Elixiru. Zoznamy kľúčových slov sú zoznamy dvojprvkových tuplov, pričom prvým prvkom v každom tuple je vždy atóm. Výkonom sú na tom rovnako ako zoznamy:

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

Pre keyword listy je charakteristické:

+ Kľúčmi sú Atomy.
+ Kľúče sú zoradené.
+ Kľúče nemusia byť unikátne.

Z týchto dôvodov sú zoznamy kľúčových slov najčastejšie využívané na odovzdanie možností (options) do funkcií.

## Mapy

Na uchovávanie informácií typu kľúč-hodnota (key-value store) slúžia v Elixire Mapy. Na rozdiel od zoznamov kľúčových slov umožňujú ako kľúč akýkoľvek dátový typ a nie sú zoradené. Mapu môžeme definovať syntaxou `%{}`:

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}

iex> map[:foo]
"bar"

iex> map["hello"]
:world
```

Od verzie 1.2 dovolí Elixir použiť ako kľúče aj premenné:

```elixir
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
```

Keď do mapy pridáme prvok už s existujúcim kľúčom, prepíše pôvodnú hodnotu.

```elixir
iex> %{:foo => "bar", :foo => "hello world"}
%{foo: "hello world"}
```

Ako môžeme vidieť z výstupu vyššie, mapy, ktoré používajú ako kľúče iba atómy majú špeciálnu syntax:

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```

Navyše existuje špeciálna syntax pre prístup ku kľúčom, ktoré sú atómy:

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> map.hello
"world"
```

Ďalšia zaujímavá vlastnosť máp je, že poskytujú vlastnú syntax na ich zmenu:

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{map | foo: "baz"}
%{foo: "baz", hello: "world"}
```
