---
layout: page
title: Kolekcie
category: basics
order: 2
lang: sk
---


Listy, tuples, keywords, mapy, dictionaries a kombinátory.

{% include toc.html %}

## Zoznamy

Zoznamy (lists) sú jednoduché kolekcie hodnôt, ktoré môžu obsahovať viacero dátových typov. Môžu tiež obsahovať neunikátne hodnoty (t.j. prvky sa môžu opakovať):

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

V Elixire sú zoznamy implementované ako lineárne zoznamy (*linked lists*). To znamená, že prístup k prvkom zoznamu je operácia so zložitosťou `O(n)` (lineárna zložitosť). Z tohto dôvodu je zvyčajne rýchlejšie nové prvky pridávať na začiatok zoznamu, než na jeho koniec:

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> ["π"] ++ list
["π", 3.14, :pie, "Apple"]
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```


### Spájanie zoznamov

Na spájanie zoznamov (list concatenation) slúži v Elixire operátor `++`:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

### Odčítavanie zoznamov

Odčítanie zoznamov (list subtraction) sa robí operátorom `--`. Odčítanie hodnoty, ktorá v pôvodnom zozname neexistuje, je v poriadku:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

### Head / Tail

Pri práci so zoznamami je veľmi bežné pristupovanie k tzv. Head a Tail zoznamu. Head (hlava) je prvý element zoznamu, Tail (chvost) je jeho zvyšok. Elixir nám na prístup k týmto častiam poskytuje dve užitočné funkcie `hd` a `tl`:

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

Naviac, ako si ukážeme v neskorších lekciách, sa na tento účel dá krásne použiť operátor `|` (cons):

```elixir
iex> [h|t] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> h
3.14
iex> t
[:pie, "Apple"]
```

## Tuples

Tuples sú podobné zoznamom, no v pamäti sú ulošené ako súvislá oblasť. Vďaka tomu je prístup k ich prvkom veľmi rýchly, rovnako ako zisťovanie ich dĺžky (size). Na duhú stranu, modifikácia tuplov je náročná a pomalá, pretože nový (zmenený) tuple musí byť v pamäti kompletne prekopírovaný. Tuples definujeme pomocou zložených zátvoriek:

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

Veľmi bežne sa tuples používajú ako návratové hodnoty z funkcií - v kapitole o pattern matchingu si ukážeme, ako veľmi užitočný mechanizmus to je:

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Keyword lists

Keyword lists (keywordové zoznamy) a Mapy sú asociatívnymi kolekciami Elixiru. Obe dátové štruktúry implementujú modul `Dict`. Keyword listy sú zoznamami dvojprvkových tuplov, pričom prvým prvkom v každom tuple je vždy Atom. Z hľadiska výkonu sú na tom teda rovnako, ako zoznamy (rýchle čítanie, pomalé modifikácie):

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

Pre keyword listy je charakteristické:

+ Kľúčami sú Atomy
+ Kľúče sú zoradené (ordered)
+ Kľúče nie sú unikátne

Pre tieto vlastnosti sú keyword listy najčastejšie využívané na odovzdávanie options (pomenovaných parametrov) do funkcií.

## Mapy

Na uchovávanie informácií typu kľúč-hodnota (key-value store) slúžia v Elixire Mapy. Na rozdiel od keyword listov Mapy neudržujú poradie prvkov a môžme v nich ako kľúč použiť akýkoľvek dátový typ (t.j. nielen atom). Mapu definujeme syntaxou `%{}`:

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

Keď do mapy pridáme prvok s rovnakým kľúčom, aký už v mape máme, nový prvok prepíše pôvodný.

```elixir
iex> %{:foo => "bar", :foo => "hello world"}
%{foo: "hello world"}
```

Ako je vidno v predošlom príklade, pre mapy, ktorých kľúčami sú výhradne atomy, existuje špeciálna (kratšia) syntax:

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}

iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```

A rovnako existuje skrátená syntax pre prístup k hodnotám v takýchto mapách a pre ich zmenu:

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}

iex> map.hello
"world"

iex> %{map | foo: "baz"}
%{foo: "baz", hello: "world"}
```
