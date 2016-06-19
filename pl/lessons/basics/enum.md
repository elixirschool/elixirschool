---
layout: page
title: Enum
category: basics
order: 3
lang: pl
---

Algorytmy pomagające przetwarzać kolekcje.

{% include toc.html %}

## Enum

Moduł `Enum` zawiera ponad sto funkcji wspomagających pracę z kolekcjami, które omawialiśmy w poprzedniej lekcji.

W tej lekcji przyjrzymy się tylko niektórym z funkcji. Pełna lista jest dostępna w dokumentacji modułu [`Enum`](http://elixir-lang.org/docs/stable/elixir/Enum.html); do leniwego przetwarzania kolekcji służy moduł [`Stream`](http://elixir-lang.org/docs/stable/elixir/Stream.html).

### all?

Gdy chcemy użyć funkcji `all?`, jak i wielu innych z modułu `Enum`, musimy jako parametr przekazać funkcję, którą wywołamy na elementach kolekcji. Funkcja `all?` zwróci `true`, jeżeli dla wszystkich elementów nasza funkcja zwróci prawdę, w przeciwnym wypadku otrzymamy `false`:

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

W przeciwieństwie do poprzedniej funkcja `any?` zwróci `true`, jeżeli choć dla jednego elementu nasza funkcja zwróci`true`:

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk

Jeżeli chcesz podzielić kolekcję na mniejsze grupy to `chunk` jest funkcją, której zapewne szukasz:

```elixir
iex> Enum.chunk([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

Jest dostępne kilka wersji `chunk`, ale nie będziemy ich zgłębiać. By dowiedzieć się więcej, zajrzyj do oficjalnej dokumentacji [`chunk/2`](http://elixir-lang.org/docs/stable/elixir/Enum.html#chunk/2).

### chunk_by

Jeżeli chcemy pogrupować elementy kolekcji inaczej niż po wielkości możemy użyć funkcji `chunk_by`:

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
```

### each

Jeżeli chcemy przejść przez kolekcję bez zwracania nowej wartości, to używamy funkcji `each`:

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
```

__Uwaga__: Funkcja `each` zwraca atom `:ok`.

### map

By wywołać naszą funkcję na każdym elemencie kolekcji i uzyskać nową kolekcję używamy funkcji `map`:

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

Funkcja `min` znajduje najmniejszą wartość w kolekcji:

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

### max

Funkcja `max` znajduje największą wartość w kolekcji:

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

### reduce

Funkcja `reduce` pozwala na zredukowanie kolekcji do pojedynczej wartości. By tego dokonać, możemy opcjonalnie podać akumulator (przykładowo `10`), by został przekazany do naszej funkcji; Jeżeli nie podamy akumulatora, to zostanie zastąpiony przez pierwszy element kolekcji:

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16
iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6
```

### sort

Sortowanie kolekcji jest bardzo proste dzięki nie jednej a dwóm funkcjom `sort`.  Pierwsza z nich porządkuje elementy zgodnie ze specyfikacją Elixira:

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

Druga pozwala na przekazanie jako parametr funkcji określającej kolejność:

```elixir
# with our function
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# without
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq

Jeżeli chcemy usunąć duplikaty z kolekcji możemy użyć funkcji `uniq`:

```elixir
iex> Enum.uniq([1, 2, 2, 3, 3, 3, 4, 4, 4, 4])
[1, 2, 3, 4]
```
