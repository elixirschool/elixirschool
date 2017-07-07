---
version: 0.9.0
title: Strutture di Controllo
---

In questa lezione affronteremo alle strutture di controllo disponibili in Elixir.

{% include toc.html %}

## `if` e `unless`

È probabile che hai già incontrato `if/2` prima di ora e, se sei abituato a Ruby, anche `unless/2` ti è familiare. In Elixir funzionano allo stesso modo, tuttavia sono definite come _macro_, non come costrutti del linguaggio. Puoi verificare la loro implementazione nel [modulo Kernel](https://hexdocs.pm/elixir/Kernel.html).

Va ricordato che in Elixir, gli unici valori falsi sono `nil` ed il booleano `false`.

```elixir
iex> if String.valid?("Hello") do
...>   "Valid string!"
...> else
...>   "Invalid string."
...> end
"Valid string!"

iex> if "a string value" do
...>   "Truthy"
...> end
"Truthy"
```

Usare `unless/2` somiglia a `if/2`, l'unica differenza è che funziona con una condizione negativa:

```elixir
iex> unless is_integer("hello") do
...>   "Not an Int"
...> end
"Not an Int"
```

## `case`

Se c'è bisogno di verificare una moltitudine di match, è possibile usare `case`:

```elixir
iex> case {:ok, "Hello World"} do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```

La variabile `_` è un elemento importante nel costrutto `case`. Se non viene usato, in caso non ci siano match, verrà sollevato un errore:

```elixir
iex> case :even do
...>   :odd -> "Odd"
...> end
** (CaseClauseError) no case clause matching: :even

iex> case :even do
...>   :odd -> "Odd"
...>   _ -> "Not Odd"
...> end
"Not Odd"
```

Considera `_` come un `else` che verificherà "qualsiasi altra" condizione.
Dal momento che `case` sfrutta il pattern matching, valgono le sue stesse regole e restrizioni. Se hai intenzione di verificare il valore di una variabile esistente, devi usare l'operatore pin `^`:

```elixir
iex> pie = 3.14 
 3.14
iex> case "cherry pie" do
...>   ^pie -> "Not so tasty"
...>   pie -> "I bet #{pie} is tasty"
...> end
"I bet cherry pie is tasty"
```

Un'altra funzionalità interessante di `case` è il suo supporto alle clausole di controllo (_guard clauses_):

_Questo esempio è tratto direttamente dalla guida ufficiale di Elxir [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#case)._

```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "Will match"
...>   _ ->
...>     "Won't match"
...> end
"Will match"
```

Leggi la documentazione ufficiale per [Expressions allowed in guard clauses](http://elixir-lang.org/getting-started/case-cond-and-if.html#expressions-in-guard-clauses).


## `cond`

Quando abbiamo bisogno di verificare condizioni, a non valori, possiamo usare `cond`; è simile a `else if` o `elsif` in altri linguaggi:

_Questo esempio è tratto direttamente dalla guida ufficiale di Elxir [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#cond)._

```elixir
iex> cond do
...>   2 + 2 == 5 ->
...>     "This will not be true"
...>   2 * 2 == 3 ->
...>     "Nor this"
...>   1 + 1 == 2 ->
...>     "But this will"
...> end
"But this will"
```

Analogamente a `case`, `cond` solleverà un errore se non c'è corrispondenza. Per gestire questa eventualità, possiamo definire una condizione impostata a `true`:

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```
