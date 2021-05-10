%{
  version: "1.5.0",
  title: "Enumerazioni",
  excerpt: """
  Un insieme di algoritmi per enumerare le collezioni.
  """
}
---

## Enum

Il modulo `Enum` contiene oltre 70 funzioni per lavorare con le collezioni.
Tutte le collezioni di cui abbiamo imparato nella lezione precendente, eccetto le tuple, sono enumerazioni.

Questa lezione tratterà solo una parte delle funzioni disponibili, le rimanenti possono essere oggetto di studio personale.
Facciamo un piccolo esperimento in IEx.

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

Elixir possiede una moltitudine di funzionalità che riguardano enumerazioni. Questo è dovuto al fatto che le Enumerazioni sono al centro della programmazione funzionale e tornano estremamente utili.

Per conoscere tutte le funzioni visita la documentazione ufficiale del modulo [`Enum`](https://hexdocs.pm/elixir/Enum.html); per enumerare gli elementi a richiesta (_lazy enumeration_) puoi usare il modulo [`Stream`](https://hexdocs.pm/elixir/Stream.html).


### all?

Quando si usa `all?/2`, come nella maggior parte delle funzioni di `Enum`, forniamo una funzione che verrà applicata su ciascun elemento della collezione.
Nel caso di `all?/2`, l'intera collezione deve essere valutata come `true`, altrimenti restituirà `false`:

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

Diversamente da quanto visto nelle funzione `all/2`, `any?/2` restituirà `true` se almeno un elemento sul quale viene chiamata la funzione restituisce `true`:

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk_every

Se hai bisogno di dividere la tua collezione in gruppi più piccoli, `chunk_every/2` è probabilmente la funzione di cui hai bisogno:

```elixir
iex> Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

Esistono alcune opzioni per `chunk_every/2` ma non le tratteremo, visita [`chunk_every/4`](https://hexdocs.pm/elixir/Enum.html#chunk_every/4) nella documentazione ufficiale per approfondire.

### chunk_by

Se hai bisogno di raggruppare la tua collezione in base ad un criterio diverso dalle dimensioni, puoi usare la funzione `chunk_by`.
Questa funzione accetta un enumerazione e una funzione come argomenti; un nuovo gruppo viene inizializzato quando la funzione ritorna i valori cambiati, dopodichè la funzione inizia la creazione del prossimo gruppo.

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
iex> Enum.chunk_by(["one", "two", "three", "four", "five", "six"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"], ["six"]]
```

### map_every

A volte raggruppare una collezione non è esattamente quello di cui abbiamo bisogno.
Se questo è il caso, `map_every/3` può essere utile per applicare la funzione fornita ogni n elementi, iniziando sempre dal primo.

```elixir
# Applica la funzione ogni terzo elemento
iex> Enum.map_every([1, 2, 3, 4, 5, 6, 7, 8], 3, fn x -> x + 1000 end)
[1001, 2, 3, 1004, 5, 6, 1007, 8]
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

Per applicare una funzione a ciascun elemento e produrre una nuova collezione, puoi utilizzare la funzione `map/2`:

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

`min/1` trova il valore minore in una collezione:

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

`min/2` fornisce le stesse funzionalità di `min/1`, ma in caso di enumerazione vuota, permette di specificare una funzione per produrre il valore minimo 

```elixir
iex> Enum.min([], fn -> :foo end)
:foo
```

### max

`max/1` restituisce il valore maggiore in una collezione:

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

`max/2` fornisce una funzionalità identita a `min/2` con la differenza che fornisce il valore massimo invence del minimo:

```elixir
Enum.max([], fn -> :bar end)
:bar
```

### filter

La funzione `filter/2` ci permette di filtrare una collezione per includere solo gli elementi che rispettano la funzione fornita.

```elixir
iex> Enum.filter([1, 2, 3, 4], fn(x) -> rem(x, 2) == 0 end)
[2, 4]
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

Ordinare gli elementi di una collezione è reso semplice non da una, bensì due, funzioni.
`sort/1` utilizza [l'ordinamento dei termini di Erlang](http://erlang.org/doc/reference_manual/expressions.html#term-comparisons) per determinare l'ordinamento:

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

Mentre `sort/2` permette di fornire una determinata funzione di ordinamento:

```elixir
# con la funzione
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# senza la funzione
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq

È possibile usare `uniq/1` per rimuovere elementi duplicati in una collezione:

```elixir
iex> Enum.uniq([1, 2, 2, 3, 3, 3, 4, 4, 4, 4])
[1, 2, 3, 4]
```

### uniq_by

Anche `uniq_by/2` rimuove duplicati da una collezione, ma consente di specificare una funzione per determinare l'univocità degli elementi.

```elixir
iex> Enum.uniq_by([%{x: 1, y: 1}, %{x: 2, y: 1}, %{x: 3, y: 3}], fn coord -> coord.y end)
[%{x: 1, y: 1}, %{x: 3, y: 3}]
```
