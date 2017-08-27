---
version: 1.0.0
title: Kolekcje
---

Listy, krotki, listy asocjacyjne, mapy i kombinatory funkcyjne.

{% include toc.html %}

## Listy

Listy to proste zbiory nieunikalnych wartości różnych typów:

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir implementuje listę jako listę wiązaną.  Oznacza to, że obliczenie rozmiaru listy ma złożoność `O(n)`.  Dlatego też szybsze jest dołączanie elementów na początku niż na końcu listy:

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> ["π"] ++ list
["π", 3.14, :pie, "Apple"]
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```

### Łączenie list

Do łączenia list służy operator `++/2`:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

Na marginesie należy wspomnieć o formacie nazwy użytym powyżej (`++/2`). W Elixirze, jak i w Erlangu, na którym bazuje Elixir, każda nazwa funkcji lub operatora składa się z dwóch elementów – z nazwy, tu `++` i liczby argumentów (arności, argumentowości). Arność wraz z nazwą funkcji zapisaną z użyciem slasha jest kluczową kwestią, jeżeli chcemy mówić o kodzie Elixira (jak i Erlanga). Będziemy jeszcze o tym mówić, a na chwilę obecną ułatwi nam to zrozumienie używanej notacji.   

### Usuwanie elementów

Usuwanie elementów wykonuje operator `--/2`; operacja jest bezpieczna, jeżeli chcemy usunąć nieistniejący element:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

Jeżeli na liście występują duplikaty, to zostanie usunięty pierwszy z nich:

```elixir
iex> [1,2,2,3,2,3] -- [1,2,3,2]
[2, 3]
```

**Uwaga:** Operacja używa [dokładnego porównania](../basics/#comparison) przy wyszukiwaniu wartości.

### Głowa i ogon

Pracując z listami, będziemy często używać pojęć głowa i ogon.  Głowa jest to pierwszy element listy, a ogon to pozostałe elementy.  Elixir ma dwie pomocne metody, `hd` i `tl`, które pomagają w pracy z tymi elementami:

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

Poza wyżej wymienionymi funkcjami możemy też użyć operatora `|`; spotkamy się z nim w kolejnych lekcjach:

```elixir
iex> [head | tail] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> head
3.14
iex> tail
[:pie, "Apple"]
```

_Uwaga_: znak `|` w tym przypadku oznacza operator _cons_ (od ang. _construct_) – tworzenia, a nie operator _pipe_ – łączenia.  

## Krotki

Krotki są podobne do list, ale zajmują ciągły obszar pamięci.  Powoduje to, że odczyt jest bardzo szybki, lecz modyfikacja kosztowna; zmiana wartości oznacza stworzenie nowej krotki i skopiowanie elementów starej.  Krotki definiujemy za pomocą klamer:

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

Typowym zastosowaniem krotek jest zwracanie dodatkowych informacji z funkcji; jest to bardzo przydatne i przyjrzymy się temu bliżej przy omawianiu mechanizmu dopasowań:

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Listy asocjacyjne

Listy asocjacyjne i mapy są to dwa rodzaje kolekcji asocjacyjnych w Elixirze.  W Elixirze lista asocjacyjna jest to specjalna lista krotek, których pierwszym elementem jest atom; zachowują się one jak zwykłe listy:

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

Trzy cechy list asocjacyjnych podkreślają ich znaczenie: 

+ Klucze są atomami.
+ Klucze zachowują kolejność.
+ Klucze mogą nie być unikalne.

Z tej właśnie przyczyny listy asocjacyjne są zazwyczaj używane do przekazywania opcji do funkcji.

## Mapy

W Elixirze mapy to dobrze znane kontenery przechowujące pary klucz-wartość. W przeciwieństwie do list asocjacyjnych pozwalają by, klucz był dowolnego typu i nie muszą zachowywać kolejności.  Mapę definiujemy za pomocą `%{}`:

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

Od wersji 1.2 Elixira zmienne mogą być użyte jako klucz:

```elixir
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
```

Jeżeli dodamy do mapy duplikat, to zastąpi on już istniejącą wartość:

```elixir
iex> %{:foo => "bar", :foo => "hello world"}
%{foo: "hello world"}
```

Na powyższym przykładzie zastosowaliśmy specjalną konwencję zapisu dostępną tylko wtedy gdy wszystkie klucze są atomami:

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}

iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```

Mapy posiadają też własną składnię służącą do dostępu i aktualizacji kluczy:

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{map | foo: "baz"}
%{foo: "baz", hello: "world"}
iex> map.hello
"world"
```
