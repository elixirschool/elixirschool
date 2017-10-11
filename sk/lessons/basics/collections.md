---
version: 1.2.1
title: Kolekcie
---


Listy, tuples, keyword listy a mapy.

{% include toc.html %}

## Zoznamy

Zoznamy (lists) sú jednoduché kolekcie hodnôt, ktoré môžu obsahovať viacero dátových typov. Môžu tiež obsahovať neunikátne hodnoty (t.j. prvky sa môžu opakovať):

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir implementuje zoznamy ako lineárne zoznamy (*linked lists*). To znamená, že prístup k dĺžke zoznamu je operácia so zložitosťou `O(n)`. Z tohto dôvodu je zvyčajne rýchlejšie nové prvky pridávať na začiatok zoznamu, než na jeho koniec:

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> ["π"] ++ list
["π", 3.14, :pie, "Apple"]
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```


### Spájanie zoznamov

Spájanie zoznamov využíva operátor `++/2`:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

### Odčítavanie zoznamov

Podporu odčítania zoznamov (list subtraction) poskytuje operátor `--/2`, pričom je bezpečné odčítať aj chýbajúcu hodnotu:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

Musíme však dbať na duplicitné hodnoty. Pre každý prvok na pravej strane operácie sa vymaže prvý výskyt na ľavej strane:

```elixir
iex> [1,2,2,3,2,3] -- [1,2,3,2]
[2, 3]
```

*Pozn.:* Odčítanie zoznamov používa striktné porovnanie hodnôt.

### Head / Tail

Pri používaní zoznamov je bežné pracovať s hlavou a chvostom zoznamu. Hlava (head) je prvý element zoznamu a chvost (tail) je zoznam, ktorý obsahuje zvyšok prvkov. Elixir poskytuje dve užitočné funkcie, `hd` a `tl`, pre prácu s týmito časťami:

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

Naviac môžeme použiť pattern matching a operátor `|` (cons), čo rozdelí zoznam na hlavu a chvost. O tomto vzore si povieme v neskorších lekciách:

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

Veľmi bežne sa tuples používajú ako návratové hodnoty z funkcií - v kapitole o pattern matchingu si ukážeme, ako veľmi užitočný mechanizmus to je:

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... obsah ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Keyword lists

Keyword lists (zoznamy kľúčových slov) a Mapy sú asociatívnymi kolekciami Elixiru. Keyword listy sú zoznamami dvojprvkových tuplov, pričom prvým prvkom v každom tuple je vždy atóm. Výkonom sú na tom rovnako ako zoznamy:

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

Pre keyword listy je charakteristické:

+ Kľúčami sú Atomy.
+ Kľúče sú zoradené.
+ Kľúče nie sú unikátne.

Z týchto dôvodov sú keyword listy najčastejšie využívané na odovzdanie možností (options) do funkcií.

## Mapy

Na uchovávanie informácií typu kľúč-hodnota (key-value store) slúžia v Elixire Mapy. Na rozdiel od keyword listov v Mapách sú prvky nezoradené a môžme v nich ako kľúč použiť akýkoľvek dátový typ (t.j. nielen atom). Mapu definujeme syntaxou `%{}`:

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}

iex> map[:foo]
"bar"

iex> map["hello"]
:world
```

Od verzie 1.2 povoľuje Elixir použiť ako kľúče aj premenné:

```elixir
iex> key = "hello"
"hello"

iex> %{key => "world"}
%{"hello" => "world"}
```

Keď do mapy pridáme prvok už s existujúcim kľúčom, nový prvok prepíše pôvodnú hodnotu.

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

Navyše, existuje špeciálna syntax pre prístup ku kľúčom, ktoré sú atómy:

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
