%{
  version: "1.0.1",
  title: "Operatore Pipe",
  excerpt: """
  L'operatore pipe `|>` inoltra il risultato di un'espressione come primo parametro di un'altra espressione.
  """
}
---

## Introduzione

La programmazione può diventare caotica. Così caotica che le chiamate alle funzioni possono essere innestate al punto da renderne difficile la comprensione.
Consideriamo le seguenti funzioni innestate:

```elixir
foo(bar(baz(new_function(other_function()))))
```

In questo caso, stiamo passando il valore `other_function/0` a `new_function/1`, e `new_function/1` a `baz/1`, `baz/1` a `bar/1`, ed infine il risultato di `bar/1` a `foo/1`. Elixir adotta un approccio pragmatico a questo caos sintattico offrendo l'operatore pipe. L'operatore pipe, che viene rappresentato con `|>` _prende il risultato di un'espressione, e la inoltra_. Diamo un altro sguardo al pezzo di codice precedente riscritto con l'operatore pipe:

```elixir
other_function() |> new_function() |> baz() |> bar() |> foo()
```

Il pipe prende il risultato sulla sinistra, e lo passa al lato destro.

## Esempi

In questa serie di esempi, useremo il modulo String di Elixir.

- Separare una stringa in singole parole (genericamente)

```elixir
iex> "Elixir rocks" |> String.split()
["Elixir", "rocks"]
```

- Trasformare in maiuscolo ciascuna parola

```elixir
iex> "Elixir rocks" |> String.upcase() |> String.split()
["ELIXIR", "ROCKS"]
```

- Verificare il suffisso di una parola

```elixir
iex> "elixir" |> String.ends_with?("ixir")
true
```

## Best Practices

Se il numero di parametri accettati da una funzione (_arity_) è maggiore di 1, assicurati di usare le parentesi. Questo non ha a che fare con Elixir, ma è importante per altri programmatori che potrebbero confondersi con il tuo codice. Se prendiamo il nostro terzo esempio, e rimuoviamo le parentesi da `String.ends_with?/2`, riceveremo il seguente avviso:

```elixir
iex> "elixir" |> String.ends_with? "ixir"
warning: parentheses are required when piping into a function call. For example:

  foo 1 |> bar 2 |> baz 3

is ambiguous and should be written as

  foo(1) |> bar(2) |> baz(3)

true
```
