---
version: 0.9.1
title: Pipe Operator
---

Der pipe-Operator `|>` gibt das Resultat des vorherigen Ausdrucks als ersten Parameter an den neuen Ausdrucks weiter.

{% include toc.html %}

## Einführung

Programmieren kann chaotisch sein. Tatsächlich so chaotisch, dass Funktionsaufrufe so eingebetten sind, dass es schwierig wird den Code zu lesen. Nimm zum Beispiel diese verschachtelten Funktionen:

```elixir
foo(bar(baz(new_function(other_function()))))
```

Hier übergeben wir den Wert `other_function/0` an `new_function/1` und `new_function/1` an `baz/1`, `baz/1` an `bar/1` und abschließend das Ergebnis von `bar/1` an `foo/1`. Elixir wählt einen pragmatischen Ansatz, um dieses syntaktische Chaos zu beseitigen, indem es uns den pipe-Operator an die Hand gibt. Der pipe-Operator, der `|>` aussieht *nimmt das Ergebnis eines Ausdrucks und gibt es weiter*. Lass uns nochmal einen Blick auf das Codebeispiel von oben werfen, diesmal jedoch mit dem pipe-Operator umgeschrieben.

```elixir
other_function() |> new_function() |> baz() |> bar() |> foo()
```

Die pipe nimmt das Ergebnis von links und gibt es an die rechte Seite weiter. Falls du mit Unix vertraut bist, kennst du dieses Verhalten von der Shell und `|`.

## Beispiele

Für die folgenden Beispielen wählen wir Elixirs Stringmodul.

- String trennen

```elixir
iex> "Elixir rocks" |> String.split()
["Elixir", "rocks"]
```

- Alle Zeichen in Großbuchstaben umwandeln

```elixir
iex> "Elixir rocks" |> String.upcase() |> String.split()
["ELIXIR", "ROCKS"]
```

- Überprüfe Endung

```elixir
iex> "elixir" |> String.ends_with?("ixir")
true
```

## Best Practices

Falls die arity einer Funktion größer als 1 ist, stell sicher, Anführungszeichen zu benutzen. Es ist für Elixir nicht so wichtig, aber für andere Programmierer, die deinen Code falsch interpretieren könnten. Wenn wir nochmal unser drittes Beispiel nehmen und die Klammern von `String.ends_with?/2` entfernen, werden wir mit der folgenden Warnung konfrontiert.

```shell
iex> "elixir" |> String.ends_with? "ixir"
warning: parentheses are required when piping into a function call. For example:

  foo 1 |> bar 2 |> baz 3

is ambiguous and should be written as

  foo(1) |> bar(2) |> baz(3)

true
```
