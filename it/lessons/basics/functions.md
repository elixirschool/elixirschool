---
version: 0.9.1
title: Funzioni
---

In Elixir, ed in altri linguaggi funzionali, le funzioni sono oggetti di prima classe. Impareremo i vari tipi di funzioni in Elixir, cosa le rende differenti, e come possiamo usarle.

{% include toc.html %}

## Funzioni anonime

Esattamente come implica il nome, una funzione anonima non ha un nome. Come abbiamo visto nella lezione riguardante `Enum`, le funzioni anonime sono spesso passate come argomenti di altre funzioni. Per definire una funzione anonima in Elixir, occorre usare `fn` e `end`. Al loro interno, possiamo definire una quantità arbitraria di parametri e corpi di funzioni separati da `->`.

Diamo uno sguardo a questa semplice funzione anonima:

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### L'abbreviazione `&`

L'uso delle funzioni anonime è una pratica così comune che in Elixir c'è un'abbreviazione per ottenere lo stesso risultato:

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

Come potrai avere già intuito, nella versione abbreviata i parametri sono disponibili nella forma `&1`, `&2`, `&3`, etc.

## Pattern Matching

Il _pattern matching_ in Elixir, non si limita solo alle variabili, può essere applicato alle definizioni delle funzioni come vedremo in questa sezione.

Elixir usa il pattern matching per identificare il primo insieme di parametri corrispondenti ed invoca il relativo corpo:

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
iex> handle_result.({:ok, some_result})
Handling result...

iex> handle_result.({:error})
An error has occurred!
```

## Funzioni con un nome

Possiamo associare un nome alla definizione di una funzione in modo da poterla richiamare successivamente. Queste funzioni sono definite con la keyword `def` all'interno di un modulo. Approfondiremo i Moduli nelle prossime lezioni, per ora ci concentreremo esclusivamente sulle funzioni con un nome.

Le funzioni definite all'interno di un modulo possono essere usate da altri moduli, questo è uno strumento particolarmente utile in Elixir:

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

Se il corpo della nostra funzione si occupa una sola riga, possiamo abbreviare ulteriormente con `do:`:

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

Dotati delle nozioni sul pattern matching, proviamo ad esplorare la ricorsione usando le funzioni con un nome:

```elixir
defmodule Length do
  def of([]), do: 0
  def of([_ | tail]), do: 1 + of(tail)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### Funzioni private

Quando non vogliamo che altri moduli possano accedere ad una determinata funzione, possiamo usare le funzioni private, le quali possono essere chiamate solo all'interno del loro modulo. Possiamo definirle in Elixir con `defp`:

```elixir
defmodule Greeter do
  def hello(name), do: phrase <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### Guardie

Abbiamo trattato brevemente le guadie (_guards_) nella lezione sulle [Strutture di Controllo](../control-structures), ora vedremo come possiamo applicarle alle funzioni con un nome. Una volta che Elixir ha individuato una funzione, tutte le guardie verranno controllate.

Nell'esempio che segue abbiamo due funzioni con la stessa _signature_ (cioè accettano gli stessi argomenti), ma ci affidiamo alle guardie per determinare quale usare basandoci sul tipo di argomenti:

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase() <> name
  end

  defp phrase, do: "Hello, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello "Sean"
"Hello, Sean"
```

### Argomenti di default

Se vogliamo un valore di default per un argomento, usiamo la sintassi `argomento \\ valore`:

```elixir
defmodule Greeter do
  def hello(name, language_code \\ "en") do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello("Sean", "en")
"Hello, Sean"

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.hello("Sean", "es")
"Hola, Sean"
```

Quando combiniamo il nostro esempio sulle guardie, con gli argomenti di default, ci troviamo di fronte ad un problema. Diamo uno sguardo a cosa potrebbe somigliare:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code \\ "en") when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) iex:31: definitions with multiple clauses and default values require a header. Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b) do ... end

one should write:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end

def hello/2 has multiple clauses and defines defaults in one or more clauses
    iex:31: (module)
```

Elixir non apprezza gli argomenti di default in funzioni che combaciano più volte, può confondere. Per gestire questo problema, dichiariamo una funzione con i nostri argomenti di default:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en")

  def hello(names, language_code) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code) when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "es"
"Hola, Sean, Steve"
```
