---
version: 1.3.0
title: Collezioni
---

Liste, tuple, liste di keywords e mappe.

{% include toc.html %}

## Liste

Le Liste sono semplici collezioni di valori, possono includere diversi tipi di dato; le liste possono includere valori ripetuti:

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir implementa le liste come liste linkate (_linked lists_).
Questo significa che l'accesso ad un elemento di una lista è un'operazione eseguita in tempo lineare (`O(n)`).
Per questa ragione, è solitamente più veloce inserire un elemento in testa alla lista rispetto ad appenderlo in coda:

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
# Veloce
iex> ["π" | list]
["π", 3.14, :pie, "Apple"]
# Lento
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```

### Concatenazione di Liste

Per concatenare le liste si una l'operatore `++/2`:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

Nota riguardo al formato del nome (`++/2`) usato qui sopra: In Elixir (e Erlang, sul quale Elixir è construito), il nome di una funzione o di un operatore ha due componenti: il nome da noi dato (in questo caso `++`) ed il suo _arity_. L'arity è una parte principale di Elixir (ed Erland), è il numero di argomenti di una data funzione (in questo caso due). L'arity e il nome della funzione sono separati da uno slash. Ne parleremo di più tardi, per ora questa conoscenza ti aiuterà a capire questa notazione.

### Sottrazione tra Liste

Il supporto alla sottrazione è fornito dall'operatore `--/2`; è possibile sottrarre un valore mancante:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

Fate attenzione a valori duplicati. Per ogni elemento nella lista di destra, solo la prima occorrenza nella lista di sinistra viene rimossa.

```elixir
iex> [1,2,2,3,2,3] -- [1,2,3,2]
[2, 3]
```

**Nota:** La sottrazione usa la [strict comparison](../basics#confronto) per controllare i valori. Per esempio:
```elixir
iex> [2] -- [2.0]
[2]
iex> [2.0] -- [2.0]
[]
```

### Head / Tail

Quando si usano le liste, è comune lavorare con la _testa_ (head) e la _coda_ (tail) della lista. La testa è il primo elemento della lista e la coda rappresenta gli elementi rimanenti. Elixir fornisce due metodi utili, `hd` e `tl`, per lavorare con queste parti:

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

Oltre alle funzioni menzionate in precedenza, puoi usare [pattern matching](../pattern-matching/) e l'operatore _pipe_ `|` per dividere la lista; vedremo questo operatore nelle lezioni successive:

```elixir
iex> [head | tail] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> head
3.14
iex> tail
[:pie, "Apple"]
```

## Tuple

Le tuple sono simili alle liste, ma sono conservate in memoria in modo adiancente. Ciò permette di accedere agli elementi in modo rapido, ma rende le modifiche più dispendiose; la nuova tupla deve essere interamente copiata in memoria. Le tuple sono rappresentate con le parentesi graffe:

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

È comune usare le tuple come meccanismo per ricevere informazioni addizionali dalle funzioni; l'utilità di questo sarà più evidente quando parleremo di [pattern matching](../pattern-matching/).

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Liste di Keywords

Le liste di keyword e le mappe sono collezioni associative di Elixir.
In Elixir, una lista di keywords è una speciale lista di tuple che hanno un atom come primo elemento; condividono le performance con le liste:

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

Le tre caratteristiche delle liste di keywords sottolineano la loro importanza:

+ Le _chiavi_ (keys) sono atoms.
+ Le chiavi sono ordinate.
+ Le chiavi non sono uniche.

Per queste ragioni, le liste di keywords sono comunemente utilizzate per passare opzioni alle funzioni.

## Mappe

In Elixir, le mappe sono il punto di riferimento per organizzare le coppie chiave-valore.
Diversamente dalle liste di keywords, le mappe consentono di utilizzare qualsiasi tipo di dato come chiave e non seguono nessun ordinamento. Puoi definire una mappa con la sintassi `%{}`:

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

Dalla versione 1.2 di Elixir, è possibile usare le variabli come chiavi per le mappe:

```elixir
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
```

Se una chiave duplicata è aggiunta ad una mappa, il suo valore precedente verrà sostituito:

```elixir
iex> %{:foo => "bar", :foo => "hello world"}
%{foo: "hello world"}
```

Come possiamo notare dal risultato ottenuto sopra, c'è una sintassi speciale per le mappe che contengono solo chiavi di tipo atom:

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```

Inoltre, c'è una sintassi speciale che ci aiuta ad accedere chiavi di tipo atom:

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> map.hello
"world"
```

Un'altra proprietà interessante delle mappe è il fatto che le _mappe_ forniscono la propria sintassi per eseguire aggiornamenti (nota: questa sintassi crea una nuova mappa):

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{map | foo: "baz"}
%{foo: "baz", hello: "world"}
```

**Nota**: questa sintassi funziona esclusivamente per aggiornare una chiave che esiste già nella mappa! Nel caso in cui una chiave non esista, un errore di tipo `KeyError` verrà sollevato.

Per creare una nuova chiave, utilizza invece [`Map.put/3`](https://hexdocs.pm/elixir/Map.html#put/3)

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
