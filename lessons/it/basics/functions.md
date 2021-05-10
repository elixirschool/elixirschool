%{
  version: "1.2.0",
  title: "Funzioni",
  excerpt: """
  In Elixir, ed in altri linguaggi funzionali, le funzioni sono oggetti di prima classe. Impareremo i vari tipi di funzioni in Elixir, cosa le rende differenti, e come possiamo usarle.
  """
}
---

## Funzioni anonime

Esattamente come implica il nome, una funzione anonima non ha un nome. Come abbiamo visto nella lezione riguardante `Enum`, le funzioni anonime sono spesso passate come parametri di altre funzioni. Per definire una funzione anonima in Elixir, occorre usare `fn` e `end`. Al loro interno, possiamo definire una quantità arbitraria di parametri e corpi di funzioni separati da `->`.

Diamo uno sguardo a questa semplice funzione anonima:

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### L'abbreviazione &

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
...>   {:ok, _} -> IO.puts "This would be never run as previous will be matched beforehand."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
1
iex> handle_result.({:ok, some_result})
Handling result...
:ok
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

### Nomi di funzioni e _Arity_

Abbiamo accennato in precedenza che le funzioni vengono definite dal nome della funzione e dalla _arity_ (numero di parametri della funzione).
Questo significa che possiamo fare:

```elixir
defmodule Greeter2 do
  def hello(), do: "Hello, anonymous person!"   # hello/0
  def hello(name), do: "Hello, " <> name        # hello/1
  def hello(name1, name2), do: "Hello, #{name1} and #{name2}"
                                                # hello/2
end

iex> Greeter2.hello()
"Hello, anonymous person!"
iex> Greeter2.hello("Fred")
"Hello, Fred"
iex> Greeter2.hello("Fred", "Jane")
"Hello, Fred and Jane"
```

Abbiamo elencato i nomi delle funzioni nei commenti accanto ad ogni funzione.
La prima implementazione non accetta parametri, quindi si chiama `hello/0`; la seconda accetta un parametro, quindi si chiama `hello/1`, e così via.
A differenza del _function overloading_ in altri linguaggi di programmazione, in Elixir, queste sono funzioni _diverse_ l'una dall'altra.
(Pattern matching, descritta qui sopra, può essere applicata solo quando vengono fornite piú definizioni di funzioni con lo _stesso_ numero di parametri.)

### Funzioni e Pattern Matching

Dietro le quinte, le funzioni eseguono automaticatemente il _pattern-matching_ sui parametri con cui vengono chiamate.

Per esempio, abbiamo bisogno di una funzione che accetti una _map_ ma siamo interessati solo in una chiave in particolare; possiamo applicare il _patter-match_ sul parametro così:

```elixir
defmodule Greeter1 do
  def hello(%{name: person_name}) do
    IO.puts "Hello, " <> person_name
  end
end
```

E se abbiamo una _map_ che descrive una persona chiamata Fred:

```elixir
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"
...> }
```

Questo è il risultato che otterremo quando chiamiamo `Greeter1.hello/1` con la mappa `fred`.

```elixir
# chiamata con l'intera mappa
...> Greeter1.hello(fred)
"Hello, Fred"
```

Cosa succede quando chiamiamo la funzione con una mappa che _non_ contiente la chiave `:name`?

```elixir
# call without the key we need returns an error
...> Greeter1.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter1.hello/1

    The following arguments were given to Greeter1.hello/1:

        # 1
        %{age: "95", favorite_color: "Taupe"}

    iex:12: Greeter1.hello/1

```

La ragione di questo comportamento è che Elixir esegue il _patter-matching_ dei parametri con cui la funzione è stata chiamata contro la funzione della stessa _arity_.

Pensiamo a come i dati appaiono quando arrivano a `Greeter1.hello/1`:

```Elixir
# mappa in arrivo
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"
...> }
```

`Greeter1.hello/1` si aspetta un parametro come questo:

```elixir
%{name: person_name}
```

In `Greeter1.hello/1`, la mappa passata (`fred`) viene valutata contro il nostro parametro (`%{name: person_name}`):

```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Questo trova che che c'è una chiave che corrisponde a `name` nella mappa in arrivo.
E come risultato di questa corrispondenza, il valore della chiave `:name` nella mappa sulla destra (per esempio, la mappa `fred`) viene associato alla variable sulla sinistra (`person_name`).

E se volessimo assegnare il nome di Fred a `person_name` ma ANCHE conservare il valore dell'intera mappa? Per esempio, per eseguire un `IO.inspect(fred)` dopo il saluto.

Per mantenerlo, dobbiamo assegnare il valore dell'intera mappa ad una variabile.

Partiamo con una nuova funzione:

```elixir
defmodule Greeter2 do
  def hello(%{name: person_name} = person) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

Ricorda che Elixir farà il _pattern match_ subito all'inizio.
In questo caso quindi, ogni lato dovrà "combaciare" contro il parametro in entrata e associarlo a qualsiasi dato che corrispondi.
Diamo un'occhiata al lato destro prima:

```elixir
person = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Ora, `person` è stato valutato ed assegnato alla mappa `fred`.
Passiamo all prossimo `pattern-match`:

```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Questa funzione è uguale a quella originale nel module `Greeter1`, dove il `pattern match` viene applicato solamente sul nome.
Quello che abbiamo ottenuto sono due variabili invece di una:

1. `person`, si riferische a `%{name: "Fred", age: "95", favorite_color: "Taupe"}`
2. `person_name`, si riferische a `"Fred"`

Quindi ora, quando `Greeter2.hello/1` viene invocata, possiamo usare tutte le informazioni possibili su Fred.

```elixir
# chiamata con la mappa della persona intera
...> Greeter2.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}
# chiamata con una mappa contenente solo la chiave :name
...> Greeter2.hello(%{name: "Fred"})
"Hello, Fred"
%{name: "Fred"}
# chiamata con una mappa senza la chiave :name
...> Greeter2.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter2.hello/1

    The following arguments were given to Greeter2.hello/1:

        # 1
        %{age: "95", favorite_color: "Taupe"}

    iex:15: Greeter2.hello/1
```

Abbiamo visto che Elixir può eseguire il _pattern match_ a più profondità in quanto ogni parametro deve "combaciare" contro i dati in arrivo indipendentemente, lasciandoci con le variabili da chiamare separatamente nella nostra funzione.

Se cambiamo l'ordine di `%{name: person_name}` e `person` nella lista, otterremo lo stesso risultato in quanto ognuno di essi corrisponde a `fred` per conto proprio.

Scambiamo l'ordine della variabile e della mappa:

```elixir
defmodule Greeter3 do
  def hello(person = %{name: person_name}) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

Ed invochiamo la funzione con lo stesso argomento usato in `Greeter2.hello/1`:

```elixir
...> Greeter3.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}
```

Ricorda che anche se sembra che `%{name: person_name} = person` stia eseguendo il _pattern match_ tra `%{name: person_name}` e `person`, questo non è giusto! Tutt'e due i lati vengono usati per eseguire il pattern match contro il parametro in entrata.

**Riepilogo** Le funzioni eseguono il pattern match dei parametri in entrata contro ogni argomento indipendentemente.
Questo può essere usato per assegnare valori a diverse variabili all'interno della funzione.

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

Nell'esempio che segue abbiamo due funzioni con la stessa _signature_ (cioè accettano gli stessi parametri), ma ci affidiamo alle guardie per determinare quale usare basandoci sul tipo di parametri:

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

### Parametri di default

Se vogliamo un valore di default per un parametro, usiamo la sintassi `parametro \\ valore`:

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

Quando combiniamo il nostro esempio sulle guardie, con gli parametro di default, ci troviamo di fronte ad un problema. Diamo uno sguardo a cosa potrebbe somigliare:

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

Elixir non apprezza gli parametri di default in funzioni che combaciano più volte, può confondere. Per gestire questo problema, dichiariamo una funzione con i nostri parametri di default:

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
