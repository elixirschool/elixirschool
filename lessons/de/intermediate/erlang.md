%{
  version: "0.9.1",
  title: "Erlang-Interoperabilität",
  excerpt: """
  Einer der Vorteile davon, wenn man auf die Erlang VM (BEAM) aufbaut, ist der große Reichtum an vorhandenen Bibiliotheken, die wir benutzen können.
  Interoperabilität erlaubt uns sowohl diese als auch die Erlang-Standardbibliothek von unserem Elixir Code zu benutzen.
  In dieser Lektion werden wir sehen, wie man auf die Funktionalität der Standardbibliothek und Drittanbieter-Erlang-Pakete zugreift.
  """
}
---

## Standardbibliothek

Erlangs rießige Standardbibliothek kann direkt von Elixir Code in unserer Anwendung benutzt werden. Erlang-Module werden durch atoms in Kleinbuchstaben dargestellt wie etwa `:os` oder `:timer`.

Lass uns `:timer.tc` benutzen, um die Ausführungszeit einer gegebenen Funktion zu messen:

```elixir
defmodule Example do
  def timed(fun, args) do
    {time, result} = :timer.tc(fun, args)
    IO.puts("Time: #{time} μs")
    IO.puts("Result: #{result}")
  end
end

iex> Example.timed(fn (n) -> (n * n) * n end, [100])
Time: 8 μs
Result: 1000000
```

Für eine vollständige Liste an verfügbaren Modulen siehe [Erlang Reference Manual](http://erlang.org/doc/apps/stdlib/).

## Erlang-Pakete

In der vorigen Lektion haben wir Mix und die Verwaltung von Abhängigkeiten besprochen. Erlang-Bibliotheken zu benutzen funktioniert auf die gleiche Weise. Für den Fall, dass die Erlang-Bibliothek nicht auf [Hex](https://hex.pm) veröffentlicht wurde, kannst du direkt auf das git-Repository zurückgreifen:

```elixir
def deps do
  [{:png, github: "yuce/png"}]
end
```

Jetzt können wir unsere Erlang-Bibliothek nutzen:

```elixir
png =
  :png.create(%{:size => {30, 30}, :mode => {:indexed, 8}, :file => file, :palette => palette})
```

## Auffallende Unterschiede

Jetzt da wir wissen, wie man Erlang einbindet, lass uns einige häufig gemachte Fehler anschauen, die in Bezug mit Erlang-Interoperabilität öfters auftreten.

### Atoms

Erlang atoms ähneln denen Elixirs ohne den Doppelpunkt (`:`). Sie werden mit kleingeschriebenen Strings und Unterstrichen dargestellt:

Elixir:

```elixir
:example
```

Erlang:

```erlang
example.
```

### Strings

In Elixir meinen wir UTF-8 codierte binaries, wenn wir von Strings reden. In Erlang werden Strings auch durch doppelte Anführungszeichen gekennzeichnet, sind jedoch char lists:

Elixir:

```elixir
iex> is_list('Example')
true
iex> is_list("Example")
false
iex> is_binary("Example")
true
iex> <<"Example">> === "Example"
true
```

Erlang:

```erlang
1> is_list('Example').
false
2> is_list("Example").
true
3> is_binary("Example").
false
4> is_binary(<<"Example">>).
true
```

Es ist wichtig sich zu merken, dass viele ältere Erlang-Bibliotheken keine binaries unterstützen und wir somit Elixir strings in char lists umwandeln müssen. Glücklicherweise ist das mit der `to_charlist/1`-Funktion kein Problem:

```elixir
iex> :string.words("Hello World")
** (FunctionClauseError) no function clause matching in :string.strip_left/2

    The following arguments were given to :string.strip_left/2:

        # 1
        "Hello World"

        # 2
        32

    (stdlib) string.erl:1661: :string.strip_left/2
    (stdlib) string.erl:1659: :string.strip/3
    (stdlib) string.erl:1597: :string.words/2

iex> "Hello World" |> to_charlist |> :string.words
2
```

### Variablen

Elixir:

```elixir
iex> x = 10
10

iex> x1 = x + 10
20
```

Erlang:

```erlang
1> X = 10.
10

2> X1 = X + 1.
11
```

Das war's! Erlang von unseren Elixir-Anwendungen zu benutzen ist einfach und verdoppelt effektiv die Anzahl an verfügbaren Bibiliotheken.
