%{
  version: "0.9.0",
  title: "Comprehensions",
  excerpt: """
  List comprehensions sind syntaktischer Zucker, um durch Enums zu iterieren in Elixir. In dieser Lektion werden wir einen Blick darauf werfen, wie wir comprehensions zur Iteration und Erzeugung nutzen können.
  """
}
---

## Grundlagen

Oftmals können comprehensions dazu genutzt werden, um knapperen Code für `Enum` und `Stream` Iterationen zu schreiben. Lass uns damit anfangen einen Blick auf eine einfache comprehension zu werfen, die wir danach aufdröseln:

```elixir
iex> list = [1, 2, 3, 4, 5]
iex> for x <- list, do: x*x
[1, 4, 9, 16, 25]
```

Das Erste, was wir bemerken, ist die Benutzung von `for` und ein generator. Was ist ein generator? Generator sind die `x <- [1, 2, 3, 4]` Ausdrücke in list comprehensions. Sie sind für die Erzeugung des nächstes Wertes verantwortlich.

Glücklicherweise sind comprehensions nicht auf Listen festgelegt, sie funktionieren mit allen enumerables:

```elixir
# Keyword Listen
iex> for {_key, val} <- [one: 1, two: 2, three: 3], do: val
[1, 2, 3]

# Maps
iex> for {k, v} <- %{"a" => "A", "b" => "B"}, do: {k, v}
[{"a", "A"}, {"b", "B"}]

# Binaries
iex> for <<c <- "hello">>, do: <<c>>
["h", "e", "l", "l", "o"]
```

Wie viele Dinge in Elixir stützen sich genereratos auf Pattern Matching, um die reingegebenen Werte mit der Variable auf der linken Seite zu vergleichen. Falls der Match nicht gefunden werden sollte, so wird dieser Wert ignoriert:

```elixir
iex> for {:ok, val} <- [ok: "Hello", error: "Unknown", ok: "World"], do: val
["Hello", "World"]
```

Es ist möglich mehrere generators zu benutzen, ähnlich verschachtelten Schleifen:

```elixir
iex> list = [1, 2, 3, 4]
iex> for n <- list, times <- 1..n do
...>   String.duplicate("*", times)
...> end
["*", "*", "**", "*", "**", "***", "*", "**", "***", "****"]
```

Um die Schleife, die abläuft, besser zu verdeutlichen, lass uns `IO.puts` nutzen, um die zwei erzeugten Werte anzuzeigen:

```elixir
iex> for n <- list, times <- 1..n, do: IO.puts "#{n} - #{times}"
1 - 1
2 - 1
2 - 2
3 - 1
3 - 2
3 - 3
4 - 1
4 - 2
4 - 3
4 - 4
```

List comprehensions sind syntaktischer Zucker und sollten nur im angemessenen Fall benutzt werden.

## Filter

Du kannst dir Filter als eine Art guard für comprehensions vorstellen. Wenn ein gefilterter Wert `false` oder `nil` zurück gibt, wird er in die endgültige Liste nicht aufgenommen. Lass uns über eine range iterieren und nur die geraden Zahlen betrachten. Wir werden die `is_even/1` Funktion aus dem Integer-Modul nutzen, um zu überprüfen, ob ein Wert gerade ist oder nicht.

```elixir
import Integer
iex> for x <- 1..10, is_even(x), do: x
[2, 4, 6, 8, 10]
```

Ähnlich wie generators können wir mehrere Filter benutzen. Lass uns unsere range erweitern und dann die Werte daraufhin aussortieren, dass sowohl gerade Zahlen als auch ungerade, die ohne Rest durch drei teilbar sind, zurück gegeben werden.

```elixir
import Integer
iex> for x <- 1..100,
...>   is_even(x),
...>   rem(x, 3) == 0, do: x
[6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 78, 84, 90, 96]
```

## `:into`

Was, wenn wir etwas anderes als eine Liste herstellen wollen? Mit der `:into` Option können wir genau das tun! Als Faustregel akzeptiert `:into` jede Struktur, die das `Collectable`-Protokoll implementiert.

Lass uns mit Hilfe von `:into` eine Liste aus einer Keyword Liste erzeugen:

```elixir
iex> for {k, v} <- [one: 1, two: 2, three: 3], into: %{}, do: {k, v}
%{one: 1, three: 3, two: 2}
```

Da bitstrings enumerable sind können wir list comprehensions und `:into` dazu nutzen, um Strings zu erzeugen:

```elixir
iex> for c <- [72, 101, 108, 108, 111], into: "", do: <<c>>
"Hello"
```

Das war's schon! List comprehensions sind ein einfacher Weg um auf knappe Art und Weise durch eine collection zu iterieren.
