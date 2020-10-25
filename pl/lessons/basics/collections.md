---
version: 1.3.1
title: Kolekcje
---

Listy, krotki, listy asocjacyjne i mapy.

{% include toc.html %}

## Listy

Listy to proste zbiory nieunikalnych wartości różnych typów:

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir implementuje listę jako listę wiązaną.
Oznacza to, że obliczenie rozmiaru listy ma złożoność `O(n)`.
Z tego powodu dodawanie elementów na początku jest zwykle szybsze niż dołączanie na koniec listy:

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
# Poprzedzanie (szybko)
iex> ["π" | list]
["π", 3.14, :pie, "Apple"]
# Dołączanie na koniec (wolne)
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```

### Łączenie list

Do łączenia list służy operator `++/2`:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

Na marginesie należy wspomnieć o formacie nazwy użytym powyżej (`++/2`).
W Elixirze, jak i w Erlangu, na którym bazuje Elixir, każda nazwa funkcji lub operatora składa się z dwóch elementów – z nazwy, tu `++` i liczby argumentów (arności, argumentowości).
Arność wraz z nazwą funkcji zapisaną z użyciem slasha jest kluczową kwestią, jeżeli chcemy mówić o kodzie Elixira (jak i Erlanga).
Będziemy jeszcze o tym mówić, a na chwilę obecną ułatwi nam to zrozumienie używanej notacji.   

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

```elixir
iex> [2] -- [2.0]
[2]
iex> [2.0] -- [2.0]
[]
```

### Głowa i ogon listy

Pracując z listami, będziemy często używać pojęć głowa i ogon.
Głowa jest to pierwszy element listy, a ogon to pozostałe elementy.
Elixir ma dwie pomocne metody, `hd` i `tl`, które pomagają w pracy z tymi elementami:

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

Oprócz wyżej wymienionych funkcji, możesz użyć [dopasowywania wzorców](../pattern-matching/) i operatora `|`, aby podzielić listę na początek i koniec.
Dowiemy się więcej o tym schemacie w kolejnych lekcjach:

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

Krotki są podobne do list, ale zajmują ciągły obszar pamięci.
Powoduje to, że odczyt jest bardzo szybki, lecz modyfikacja kosztowna; zmiana wartości oznacza stworzenie nowej krotki i skopiowanie elementów starej.
Krotki definiujemy za pomocą klamer:

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

Typowym zastosowaniem krotek jest zwracanie dodatkowych informacji z funkcji.
Jest to bardzo przydatne, przez co przyjrzymy się temu bliżej przy omawianiu mechanizmu [dopasowywania wzorców](../pattern-matching/):

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Listy asocjacyjne

Listy asocjacyjne i mapy są to dwa rodzaje kolekcji asocjacyjnych w Elixirze.
W Elixirze lista asocjacyjna jest to specjalna lista krotek, których pierwszym elementem jest atom; zachowują się one jak zwykłe listy:

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

W Elixirze mapy to dobrze znane kontenery przechowujące pary klucz-wartość.
W przeciwieństwie do list asocjacyjnych pozwalają by klucz był dowolnego typu i nie muszą zachowywać kolejności.
Mapę definiujemy za pomocą `%{}`:

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

**Uwaga:** ta składnia działa tylko w przypadku aktualizacji klucza, który już istnieje w mapie!
Jeśli klucz nie istnieje, zostanie zgłoszony błąd `KeyError`.
Aby utworzyć nowy klucz, zamiast tego użyj [`Map.put/3`](https://hexdocs.pm/elixir/Map.html#put/3).

```elixir
iex> map = %{hello: "world"}
%{hello: "world"}
iex> %{map | foo: "baz"}
** (KeyError) key :foo not found in: %{hello: "world"}
    (stdlib) :maps.update(:foo, "baz", %{hello: "world"})
    (stdlib) erl_eval.erl:259: anonymous fn/2 in :erl_eval.expr/5
    (stdlib) lists.erl:1263: :lists.foldl/3
iex> Map.put(map, :foo, "baz")
%{foo: "baz", hello: "world"}
```
