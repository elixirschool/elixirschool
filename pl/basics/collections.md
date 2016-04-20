---
layout: page
title: Kolekcje
category: basics
order: 2
lang: pl
---

Listy, krotki, listy asocjacyjne, mapy i kombinatory funkcyjne.

## Spis treści

- [Listy](#listy)
	- [Łączenie list](#Łączenie-list)
	- [Usuwanie elementów](#Usuwanie-elementów)
	- [Głowa i ogon](#Głowa-i-ogon)
- [Krotki](#Krotki)
- [Listy asocjacyjne](#Listy-asocjacyjne)
- [Mapy](#Mapy)

## Listy

Listy to proste zbiory nieunikalnych wartości różnych typów:

```elixir
iex> [3.41, :pie, "Apple"]
[3.41, :pie, "Apple"]
```

Elixir implementuje listę jako listę wiązaną.  Oznacza to, że obliczenie rozmiaru listy ma złożoność `O(n)`.  Dlatego też szybsze jest dołączanie elementów na początku niż na końcu listy:

```elixir
iex> list = [3.41, :pie, "Apple"]
[3.41, :pie, "Apple"]
iex> ["π"] ++ list
["π", 3.41, :pie, "Apple"]
iex> list ++ ["Cherry"]
[3.41, :pie, "Apple", "Cherry"]
```


### Łączenie list

Do łączenia list służy operator `++/2`:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

### Usuwanie elementów

Usuwanie elementów wykonuje operator `--/2`; operacja jest bezpieczna jeżeli chcemy usunąć nie istniejący element:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

**Uwaga:** Operacja używa [dokładnego porównania](../basics/#comparison) przy wyszukiwaniu wartości.

### Głowa i ogon

Pracując z listami będziemy często używać pojęć głowa i ogon.  Głowa jest to pierwszy element listy, a ogon to pozostałe elementy.  Elixir ma dwie pomocne metody, `hd` i `tl`, które pomagają w pracy z tymi elementami:

```elixir
iex> hd [3.41, :pie, "Apple"]
3.41
iex> tl [3.41, :pie, "Apple"]
[:pie, "Apple"]
```

Poza wyżej wymienionymi funkcjami, możemy też użyć operatora `|`; spotkamy się z nim w kolejnych lekcjach:

```elixir
iex> [h|t] = [3.41, :pie, "Apple"]
[3.41, :pie, "Apple"]
iex> h
3.41
iex> t
[:pie, "Apple"]
```

## Krotki

Krotki są podobne do list, ale zajmują ciągły obszar pamięci.  Powoduje to, że odczyt jest bardzo szybki lecz kodyfikacja kosztowna; zmiana wartości oznacza stworzenie nowej krotki i skopiowanie elementów starej.  Krotki definiujemy za pomocą klamer:

```elixir
iex> {3.41, :pie, "Apple"}
{3.41, :pie, "Apple"}
```

Typowym zastosowaniem krotek jest zwracanie dodatkowych informacji z funkcji; jest to bardzo przydatne i przyjrzymy się temu bliżej przy omawianiu mechanizmu dopasowań:

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Listy asocjacyjne

Keywords and maps are the associative collections of Elixir.  In Elixir, a keyword list is a special list of tuples whose first element is an atom; they share performance with lists:

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

The three characteristics of keyword lists highlight their importance:

+ Keys are atoms.
+ Keys are ordered.
+ Keys are not unique.

For these reasons keyword lists are most commonly used to pass options to functions.

## Mapy

In Elixir maps are the "go-to" key-value store, unlike keyword lists they allow keys of any type and they do not follow ordering.  You can define a map with the `%{}` syntax:

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

As of Elixir 1.2 variables are allowed as map keys:

```elixir
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
```

If a duplicate is added to a map, it will replace the former value:

```elixir
iex> %{:foo => "bar", :foo => "hello world"}
%{foo: "hello world"}
```

As we can see from the output above, there is a special syntax for maps containing only atom keys:

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}

iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```
