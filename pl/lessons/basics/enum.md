---
version: 1.0.1
title: Enum
---

Algorytmy pomagające przetwarzać kolekcje.

{% include toc.html %}

## Enum

Moduł `Enum` zawiera ponad sto funkcji wspomagających pracę z kolekcjami, które omawialiśmy w poprzedniej lekcji.

W tej lekcji przyjrzymy się tylko niektórym z funkcji. Pełna lista jest dostępna w dokumentacji modułu [`Enum`](https://hexdocs.pm/elixir/Enum.html); do leniwego przetwarzania kolekcji służy moduł [`Stream`](https://hexdocs.pm/elixir/Stream.html).

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

### chunk_every/2

Jeżeli chcesz podzielić kolekcję na mniejsze grupy to `chunk_every/2` jest funkcją, której zapewne szukasz:

```elixir
iex> Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

Jest dostępne kilka wersji `chunk_every/2`, ale nie będziemy ich zgłębiać. By dowiedzieć się więcej, zajrzyj do oficjalnej dokumentacji [`chunk_every/4`](https://hexdocs.pm/elixir/Enum.html#chunk_every/4).

### chunk_by

Jeżeli chcemy pogrupować elementy kolekcji inaczej niż po wielkości, możemy użyć funkcji `chunk_by`. Jako argumenty przyjmuje ona kolekcję oraz funkcję. Grupy tworzone są na podstawie wyniku działania funkcji. Jeżeli wynik zmienia się, to tworzona jest nowa grupa, nawet jeżeli wcześniej istniała grupa dla danego wyniku funkcji:

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five", "six"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"], ["six"]]
```

### map_every

Czasami grupowanie elementów kolekcji nie jest dokładnie tym, o co nam chodzi. W takim przypadku funkcja `map_every/3` pozwoli nam na pracę z konkretnymi elementami kolekcji. Jeżeli nasza kolekcja jest w jakiś sposób uporządkowana, to funkcja ta może być bardzo przydatna:

```elixir
iex> Enum.map_every([1, 2, 3, 4], 2, fn x -> x * 2 end)
[2, 2, 6, 4]
```  

### each

Jeżeli chcemy przejść przez kolekcję bez zwracania nowej wartości, to używamy funkcji `each`:

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
:ok
```

__Uwaga__: Funkcja `each` zwraca atom `:ok`.

### map

By wywołać naszą funkcję na każdym elemencie kolekcji i uzyskać nową kolekcję używamy funkcji `map`:

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

```exliir
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

```exliir
iex> Enum.max([], fn -> :bar end)
:bar  

```


### reduce

Funkcja `reduce` pozwala na zredukowanie kolekcji do pojedynczej wartości. By tego dokonać, możemy opcjonalnie podać akumulator (przykładowo `10`), by został przekazany do naszej funkcji. Jeżeli nie podamy akumulatora, to zostanie zastąpiony przez pierwszy element kolekcji:

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16
iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6
iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
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
# z naszą funkcją
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# bez naszej funkcji
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq_by

Jeżeli chcemy usunąć duplikaty z kolekcji możemy użyć funkcji `uniq_by/2`:

```elixir
iex> Enum.uniq_by([1, 2, 3, 2, 1, 1, 1, 1, 1], fn x -> x end)
[1, 2, 3]
```

Funkcja `uniq/1`, która miała takie samo działanie, została oznaczona jako przestarzała w Elixirze 1.4, a jej użycie wygeneruje ostrzeżenie kompilatora.
