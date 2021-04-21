%{
  version: "0.9.1",
  title: "Kontrollstrukturen",
  excerpt: """
  In dieser Lektion werden wir schauen welche Kontrollstrukturen in Elixir vorhanden sind.
  """
}
---

## `if` und `unless`

Die Chancen stehen gut, dass du bereits über `if/2` gestolpert bist und falls du mit Ruby vertraut bist, kennst du auch schon `unless/2`. In Elixir arbeiten diese beiden Konstrukte ähnlich, sind aber als Makros definiert und nicht wie in Ruby als Sprachkonstrukte. Du kannst ihre Implementierung in der Dokumentation des [Kernel Moduls](https://hexdocs.pm/elixir/Kernel.html) nachschlagen.

Es sollte darauf geachtet werden, dass in Elixir die einzigen "falsey" Werte `nil` und der Boolesche Wert `false` sind.

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

Die Benutzung von `unless/2` ist wie `if/2`, arbeitet jedoch mit negativen Werten:

```elixir
iex> unless is_integer("hello") do
...>   "Not an Int"
...> end
"Not an Int"
```

## `case`

Falls es notwendig ist mehrere patterns zu matchen können wir `case` benutzen:

```elixir
iex> case {:ok, "Hello World"} do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```

Die `_` Variable ist ein wichtiger Teil in `case` statements. Wird es im match nicht gefunden, so tritt ein Fehler auf:

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

Betrachte `_` wie `else`, dass auf "alles andere" zutrifft.

Da `case` auf Pattern Matching basiert, gelten auch dieselben Regeln und Beschränkungen. Falls du vorhast gegen mehrere bereits existierende Variablen zu matchen, so musst du den Pin-Operator `^` benutzen:

```elixir
iex> pie = 3.14
 3.14
iex> case "cherry pie" do
...>   ^pie -> "Not so tasty"
...>   pie -> "I bet #{pie} is tasty"
...> end
"I bet cherry pie is tasty"
```

Ein weiteres nettes Feature von `case` ist die Unterstützung von guard clauses:

_Dieses Beispiel kommt direkt aus dem offiziellen Elixir [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#case) Guide._

```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "Will match"
...>   _ ->
...>     "Won't match"
...> end
"Will match"
```

Schau in die offizielle Dokumentation für [Expressions allowed in guard clauses](https://hexdocs.pm/elixir/guards.html#list-of-allowed-expressions), um mehr über guard clauses zu erfahren.

## `cond`

Wenn man statt Werten conditions matchen muss benutzt man `cond`; es ist ähnlich `else if` oder `elsif`, bekannt aus anderen Sprachen:

_Dieses Beispiel kommt direkt aus dem offiziellen Elixir [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#cond) Guide._

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

Wie `case` wirft `cond` einen Fehler sollte ein match nicht gefunden werden. Um das zu verhindern, können wir eine Bedingung auf `true` definieren:

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```

## `with`

Die Spezialform `with` ist nützlich wenn du ein genestetes `case` statement benutzen würdest oder in Situationen, die nicht so einfach gepiped werden können. Der Ausdruck `with` setzt sich aus keyword, generators und einem Ausdruck zusammen.

Wir werden generators später in der Lektion "List Comprehension" besprechen, aber momentan müssen wir nur wissen, dass sie pattern matching benutzen, um die rechte Seite von `<-` mit der linken zu vergleichen.

Wir starten mit einem einfachen Beispiel von `with` und werden dann einen spezielleren Fall anschauen:

```elixir
iex> user = %{first: "Sean", last: "Callan"}
%{first: "Sean", last: "Callan"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
"Callan, Sean"
```

Im Fall, dass ein Ausdruck keinen match hat, wird der nicht matchende Wert zurück gegeben:

```elixir
iex> user = %{first: "doomspork"}
%{first: "doomspork"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
:error
```

Lass uns nun ein längeres Beispiel ohne `with` anschauen und dann sehen, wie wir es refactoren können:

```elixir
case Repo.insert(changeset) do
  {:ok, user} ->
    case Guardian.encode_and_sign(user, :token, claims) do
      {:ok, jwt, full_claims} ->
        important_stuff(jwt, full_claims)

      error ->
        error
    end

  error ->
    error
end
```

Wenn wir `with` einführen, kommen wir zu Code, der einfach zu verstehen ist und aus weniger Zeilen Code besteht:

```elixir
with {:ok, user} <- Repo.insert(changeset),
     {:ok, jwt, full_claims} <- Guardian.encode_and_sign(user, :token, claims),
     do: important_stuff(jwt, full_claims)
```

Ab Elixir 1.3 unterstützt `with/1` `else` Anweisungen:

```
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
Es hilft bei der Fehlerbehandlung, indem es pattern matching in ihm ermöglicht. Der übergebene Wert ist der erste nicht übereinstimmende Ausdruck.

