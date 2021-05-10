---
version: 1.6.1
title: Enum
---

Algorytmy pomagające przetwarzać kolekcje.

{% include toc.html %}

## Enum

Moduł `Enum` zawiera ponad siedemdziesiąt funkcji wspomagających pracę z kolekcjami, które omawialiśmy w [poprzedniej lekcji](./collections/). W tej lekcji przyjrzymy się tylko niektórym z funkcji. Innym sposobem na zapoznanie się z dostępnymi funkcjami jest wykorzystanie `iex`:

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

Mamy do dyspozycji ogromną ilość funkcji. Nie bez powodu. Programowanie funkcyjne opiera się na przetwarzaniu różnego typu kolekcji. W połączeniu z innymi funkcjonalnościami Elixira, jak wykonywalna dokumentacja, otrzymujemy jako programiści bardzo efektywne narzędzia.

Pełna lista jest dostępna w dokumentacji modułu [`Enum`](https://hexdocs.pm/elixir/Enum.html). Do leniwego przetwarzania kolekcji służy moduł [`Stream`](https://hexdocs.pm/elixir/Stream.html).

### all?

Gdy chcemy użyć funkcji `all?`, jak i wielu innych z modułu `Enum`, musimy jako parametr przekazać funkcję, którą wywołamy na elementach kolekcji. Funkcja `all?` zwróci `true`, jeżeli dla wszystkich elementów nasza funkcja zwróci prawdę, w przeciwnym wypadku otrzymamy `false`:

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

W przeciwieństwie do poprzedniej funkcja `any?` zwróci `true`, jeżeli choć dla jednego elementu nasza funkcja zwróci `true`:

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk_every

Jeżeli chcesz podzielić kolekcję na mniejsze grupy to `chunk_every/2` jest funkcją, której zapewne szukasz:

```elixir
iex> Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

Jest dostępne kilka wersji `chunk_every/4`, ale nie będziemy ich zgłębiać. By dowiedzieć się więcej, zajrzyj do oficjalnej dokumentacji [`chunk_every/4`](https://hexdocs.pm/elixir/Enum.html#chunk_every/4).

### chunk_by

Jeżeli chcemy pogrupować elementy kolekcji inaczej niż po wielkości, możemy użyć funkcji `chunk_by/2`. Jako argumenty przyjmuje ona kolekcję oraz funkcję. Grupy tworzone są na podstawie wyniku działania funkcji. Jeżeli wynik zmienia się, to tworzona jest nowa grupa, nawet jeżeli wcześniej istniała grupa dla danego wyniku funkcji:

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
iex> Enum.chunk_by(["one", "two", "three", "four", "five", "six"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"], ["six"]]
```

### map_every

Czasami grupowanie elementów kolekcji nie jest dokładnie tym, o co nam chodzi. W takim przypadku funkcja `map_every/3` pozwoli nam na pracę z konkretnymi elementami kolekcji. Jeżeli nasza kolekcja jest w jakiś sposób uporządkowana, to funkcja ta może być bardzo przydatna:

```elixir
# Funkcja zostanie wywołana dla co trzeciego elementu
iex> Enum.map_every([1, 2, 3, 4, 5, 6, 7, 8], 3, fn x -> x + 1000 end)
[1001, 2, 3, 1004, 5, 6, 1007, 8]
```  

### each

Jeżeli chcemy przejść przez kolekcję bez zwracania nowej wartości, to używamy funkcji `each/2`:

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
:ok
```

__Uwaga__: Funkcja `each/2` zwraca atom `:ok`.

### map

By wywołać naszą funkcję na każdym elemencie kolekcji i uzyskać nową kolekcję używamy funkcji `map/2`:

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

Funkcja `min/1` znajduje najmniejszą wartość w kolekcji:

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

Funkcja `min/2` robi dokładnie to samo, ale jako drugi argument przyjmuje funkcję anonimową zwracającą wartość domyślną dla `Enum`:

```elixir
iex> Enum.min([], fn -> :foo end)
:foo  
```

### max

Funkcja `max/1` znajduje największą wartość w kolekcji:

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

Funkcja `max/2` działa na tej samej zasadzie co `min/2`, czyli jako drugi argument przyjmuje funkcję anonimową, która zwróci wartość domyślną:

```elixir
iex> Enum.max([], fn -> :bar end)
:bar  
```

### filter

Funkcja `filter/2` pozwala nam na filtrowanie kolekcji w celu uwzględnienia tylko tych elementów, dla których funkcja anonimowa zwróci wartość `true`.

```elixir
iex> Enum.filter([1, 2, 3, 4], fn(x) -> rem(x, 2) == 0 end)
[2, 4]
```

### reduce

Funkcja `reduce/3` pozwala na zredukowanie kolekcji do pojedynczej wartości. By tego dokonać, możemy opcjonalnie podać akumulator (przykładowo `10`), by został przekazany do naszej funkcji. Jeżeli nie podamy akumulatora, to zostanie zastąpiony przez pierwszy element kolekcji:

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16

iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6

iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
```

### sort

Sortowanie kolekcji jest bardzo proste dzięki funkcjom `sort`.

Funkcja `sort/1` wykorzystuje Erlangowe [porównanie typów](http://erlang.org/doc/reference_manual/expressions.html#term-comparisons) aby ustalić kolejność:

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

Natomiast `sort/2` pozwala na przekazanie jako parametr funkcji określającej kolejność:

```elixir
# z naszą funkcją
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# bez naszej funkcji
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq

Jeżeli chcemy usunąć duplikaty z kolekcji możemy użyć funkcji `uniq/1`:

```elixir
iex> Enum.uniq([1, 2, 3, 2, 1, 1, 1, 1, 1])
[1, 2, 3]
```

### uniq_by

Jeżeli chcemy usunąć duplikaty z kolekcji możemy użyć funkcji `uniq_by/2`:

`uniq_by/2` również pozwoli na usunięcie duplikatów z kolekcji, jednocześnie umożliwiając przekazanie funkcji, która zostanie wykorzystana do porównania unikalności.

```elixir
iex> Enum.uniq_by([%{x: 1, y: 1}, %{x: 2, y: 1}, %{x: 3, y: 3}], fn coord -> coord.y end)
[%{x: 1, y: 1}, %{x: 3, y: 3}]
```

### Enum przy użyciu operatora przechwytywania (&)
Wiele funkcji w module Enum w Elixir przyjmuje anonimowe funkcje jako argument do pracy z każdym elementem kolekcji.

Te anonimowe funkcje są często zapisywane w skrócie przy użyciu operatora przechwytywania (&).

Oto kilka przykładów, które pokazują, jak operator przechwytywania może zostać wykorzystany do pracy z funkcjami z modułu `Enum`.
Każda wersja jest funkcjonalnie równoważna.

#### Używanie operatora przechwytywania z funkcją anonimową

Poniżej znajduje się typowy przykład standardowej składni podczas przekazywania funkcji anonimowej do `Enum.map/2`.

```elixir
iex> Enum.map([1,2,3], fn number -> number + 3 end)
[4, 5, 6]
```

Teraz wykorzystując operator przechwytywania (&); każda liczba z listy ([1, 2, 3]) zostaje przypisana do zmiennej &1, w momencie gdy jest ona wykorzystywana przez funkcję mapującą.

```elixir
iex> Enum.map([1,2,3], &(&1 + 3))
[4, 5, 6]
```

Można to dalej refaktoryzować, przypisując poprzednią funkcję anonimową zawierającą operator & do zmiennej aby wykorzystać ją w funkcji `Enum.map/2`.

```elixir
iex> plus_three = &(&1 + 3)
iex> Enum.map([1,2,3], plus_three)
[4, 5, 6]
```

#### Używanie operatora przechwytywania z funkcją nazwaną
Najpierw tworzymy nazwaną funkcję i wywołujemy ją w ramach funkcji anonimowej zdefiniowanej w `Enum.map/2`.

```elixir
defmodule Adding do
  def plus_three(number), do: number + 3
end

iex>  Enum.map([1,2,3], fn number -> Adding.plus_three(number) end)
[4, 5, 6]
```

Następnie możemy dokonać refaktoryzacji, aby użyć operatora przechwytywania.

```elixir
iex> Enum.map([1,2,3], &Adding.plus_three(&1))
[4, 5, 6]
```

Aby uzyskać najbardziej zwięzłą składnię, możemy bezpośrednio wywołać nazwaną funkcję bez jawnego przechwytywania zmiennej.

```elixir
iex> Enum.map([1,2,3], &Adding.plus_three/1)
[4, 5, 6]
```
