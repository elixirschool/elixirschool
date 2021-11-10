%{
  version: "0.9.0",
  title: "Pattern Matching",
  excerpt: """
  Pattern matching ist ein mächtiger Teil Elixirs.
  Es erlaubt uns einfache Werte, Datenstrukturen und sogar Funktionen zu matchen.
  In dieser Lektion werden wir anfangen zu sehen, wie pattern matching benutzt wird.
  """
}
---

## Match Operator

Bereit für einen Hirnverdreher? In Elixir ist der `=`-Operator eigentlich ein match-Operator. Durch disen können wir Werte zuweisen und matchen:

```elixir
iex> x = 1
1
```

Lass uns nun versuchen etwas einfaches zu matchen:

```elixir
iex> 1 = x
1
iex> 2 = x
** (MatchError) no match of right hand side value: 1
```

Lass uns das mit ein paar der collections probieren, die wir kennen:

```elixir
# Lists
iex> list = [1, 2, 3]
[1, 2, 3]
iex> [1, 2, 3] = list
[1, 2, 3]
iex> [] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

iex> [1 | tail] = list
[1, 2, 3]
iex> tail
[2, 3]
iex> [2|_] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

# Tupel
iex> {:ok, value} = {:ok, "Successful!"}
{:ok, "Successful!"}
iex> value
"Successful!"
iex> {:ok, value} = {:error}
** (MatchError) no match of right hand side value: {:error}
```

## Pin Operator

Wir haben gerade gelernt, dass der match-Operator eine Zuweisung ausführt, wenn die linke Seite des matches eine Variable beinhaltet. In manchen Fällen ist das Verhalten neu zu definieren unerwünscht. Für diese Fälle gibt es den pin-Operator: `^`.

Wenn wir eine Variable pinnen matchen wir auf den vorhandenen Wert statt einen neuen zu definieren. Lass uns sehen, wie das funktioniert:

```elixir
iex> x = 1
1
iex> ^x = 2
** (MatchError) no match of right hand side value: 2
iex> {x, ^x} = {2, 1}
{2, 1}
iex> x
2
```

Elixir 1.2 hat Unterstützung für pins in map keys und Funktionsklauseln eingeführt:

```elixir
iex> key = "hello"
"hello"
iex> %{^key => value} = %{"hello" => "world"}
%{"hello" => "world"}
iex> value
"world"
iex> %{^key => value} = %{:hello => "world"}
** (MatchError) no match of right hand side value: %{hello: "world"}
```

Ein Beispiel von pinning einer Funktionsklausel:

```elixir
iex> greeting = "Hello"
"Hello"
iex> greet = fn
...>   (^greeting, name) -> "Hi #{name}"
...>   (greeting, name) -> "#{greeting}, #{name}"
...> end
#Function<12.54118792/2 in :erl_eval.expr/5>
iex> greet.("Hello", "Sean")
"Hi Sean"
iex> greet.("Mornin'", "Sean")
"Mornin', Sean"
```
