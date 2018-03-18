---
version: 0.9.0
title: Enumerazioni
---

Un insieme di algoritmi per enumerare le collezioni.

{% include toc.html %}

## Enum

Il modulo `Enum` contiene oltre un centinaio di funzioni per lavorare con le collezioni di cui abbiamo parlato nella scorsa lezione.

Questa lezione tratterà solo una parte delle funzioni disponibili, per conoscere tutte le funzioni visita la documentazione ufficiale del modulo [`Enum`](https://hexdocs.pm/elixir/Enum.html); per enumerare gli elementi a richiesta (_lazy enumeration_) puoi usare il modulo [`Stream`](https://hexdocs.pm/elixir/Stream.html).


### all?

Quando si usa `all?`, come nella maggior parte delle funzioni di `Enum`, forniamo una funzione che verrà applicata su ciascun elemento della collezione. Nel caso di `all?`, la funzione che sarà chiamata sugli elmenti dell'intera collezione deve restituire `true`, altrimenti restituirà `false`:

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

Diversamente da quanto visto, `any?` restituirà `true` se almeno un elemento sul quale viene chiamata la funzione restituisce `true`:

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk_every/2

Se hai bisogno di dividere la tua collezione in gruppi più piccoli, `chunk_every/2` è la funzione di cui hai bisogno:

```elixir
iex> Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

Esistono alcune opzioni per `chunk_every/2` ma non le tratteremo, visita [`chunk_every/4`](https://hexdocs.pm/elixir/Enum.html#chunk_every/4) nella documentazione ufficiale per approfondire.

### chunk_by

Se hai bisogno di raggruppare la tua collezione in base ad un criterio diverso dalle dimensioni, puoi usare la funzione `chunk_by`:

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
```

### each

A volte, potresti aver bisogno di iterare una collezione senza produrre un nuovo valore, in questo caso è possibile usare `each`:

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
:ok
```

__Nota__: La funzione `each` non restituisce l'atom `:ok`.

### map

Per applicare una funzione a ciascun elemento e produrre una nuova collezione, c'è la funzione `map`:

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

Trova il valore minore (`min`) in una collezione:

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

### max

Restituisce il valore maggiore (`max`) in una collezione:

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

### reduce

Con `reduce` è possibile ridurre una collezione ad un singolo valore. Per fare questo viene fornito un _accumulatore_ opzionale (`10` in questo esempio) alla funzione; se non viene fornito nessun accumulatore, viene usato il primo valore della collezione:

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16
iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6
iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
```

### sort

Ordinare gli elementi di una collezione è reso semplice non da una, bensì due, funzioni `sort`. La prima opzione disponibile usa l'ordinamento dei termini di Elixir per determinare la posizione di ordinamento:

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

La seconda opzione permette di fornire una funzione di ordinamento:

```elixir
# con la funzione
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# senza la funzione
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq

È possobile usare `uniq` per rimuovere elementi duplicati in una collezione:

```elixir
iex> Enum.uniq([1, 2, 2, 3, 3, 3, 4, 4, 4, 4])
[1, 2, 3, 4]
```
