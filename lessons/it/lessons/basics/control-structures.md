%{
  version: "1.1.1",
  title: "Strutture di Controllo",
  excerpt: """
  In questa lezione affronteremo le strutture di controllo disponibili in Elixir.
  """
}
---

## `if` e `unless`

È probabile che hai già incontrato `if/2` prima d'ora e, se sei abituato a Ruby, anche `unless/2` ti è familiare.
In Elixir funzionano allo stesso modo, tuttavia sono definite come _macro_, non come costrutti del linguaggio. Puoi verificare la loro implementazione nel [modulo Kernel](https://hexdocs.pm/elixir/Kernel.html).

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

La variabile `_` è un elemento importante nel costrutto `case/2`. Se non viene usato, verrà sollevato un errore nel caso non ci siano match:

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

Leggi la documentazione ufficiale per [Expressions allowed in guard clauses](https://hexdocs.pm/elixir/guards.html#list-of-allowed-expressions).


## `cond`

Quando abbiamo bisogno di verificare condizioni, non valori, possiamo usare `cond`; è simile a `else if` o `elsif` in altri linguaggi:

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

Analogamente a `case/2`, `cond/1` solleverà un errore se non c'è corrispondenza. Per gestire questa eventualità, possiamo definire una condizione impostata a `true`:

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```

## `with`

`with/1` è un'espressione speciale utile quando abbiamo dei `case/2` nidificati o situazioni in cui non puoi elegantemente usare l'operatore _pipe_ (`|>`). L'espressione `with/1` è composta da keywords, generators e una espressione.

Parleremo dei generators nella lezione sulle [Comprensione delle liste](../comprehensions/), ma per ora dobbiamo solo sapere utilizzare il [pattern matching](../pattern-matching/) per paragornare il valore sulla destra di `<-` a quello sulla sinistra.

Iniziamo con una semplice espressione `with/1` ed in seguito vedremo qualcosa di più complesso.

```elixir
iex> user = %{first: "Sean", last: "Callan"}
%{first: "Sean", last: "Callan"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
"Callan, Sean"
```

Nel caso in cui l'espressione fallisca, il valore non corrispondente verrà ritornato.

```elixir
iex> user = %{first: "doomspork"}
%{first: "doomspork"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
:error
```

Ora, diamo un'occhiata ad un esempio più grande senza l'uso di `with/1` e dopodichè vedremo come possiamo migliorare il codice con l'uso di `with/1`:

```elixir
case Repo.insert(changeset) do
  {:ok, user} ->
    case Guardian.encode_and_sign(user, :token, claims) do
      {:ok, token, full_claims} ->
        important_stuff(token, full_claims)

      error ->
        error
    end

  error ->
    error
end
```

Introducendo l'uso di `with/1`, il codice è facile da capire e contiene meno righe:

```elixir
with {:ok, user} <- Repo.insert(changeset),
     {:ok, token, full_claims} <- Guardian.encode_and_sign(user, :token, claims) do
  important_stuff(token, full_claims)
end
```

A partire da Elixir 1.3, dichiarazioni `with/1` supportano l'`else`:

```elixir
import Integer

m = %{a: 1, c: 3}

a =
  with {:ok, number} <- Map.fetch(m, :a),
    true <- is_even(number) do
      IO.puts "#{number} divided by 2 is #{div(number, 2)}"
      :even
  else
    :error ->
      IO.puts("We don't have this item in map")
      :error

    _ ->
      IO.puts("It is odd")
      :odd
  end
```

Quest'ultimo aiuta a gestire errori fornendo patter matching simile al `case`. Il valore passato all'`else` è il primo valore non corrispondente nell'espressione.
