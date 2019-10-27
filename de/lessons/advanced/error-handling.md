---
version: 0.9.0
title: Fehlerbehandlung
---

Obwohl es üblich ist das `{:error, reason}`-Tupel zurückzugeben, unterstützt Elixir Exceptions und in dieser Lektion werden wir lernen, wie man Fehler behandelt und welche verschiedenen Möglichkeiten wir haben.

Üblicherweise ist die Konvention in Elixir eine Funktion (`example/1`) zu schreiben, welche `{:ok, result}` oder `{:error, reason}` zurückgibt und eine separate Funktion (`example!/1`), die das "rohe" `result` zurückgibt oder einen Fehler wirft.

Diese Lektion wird sich auf den zweiten Fall konzentrieren.

{% include toc.html %}

## Fehlerbehandlung

Bevor wir Fehler behandeln können, müssen wir sie erzeugen und der einfachste Weg dies zu tun ist mit `raise/1`:

```elixir
iex> raise "Oh no!"
** (RuntimeError) Oh no!
```

Falls wir den Typ und eine Nachricht angeben wollen, müssen wir `raise/2` benutzen:

```elixir
iex> raise ArgumentError, message: "the argument value is invalid"
** (ArgumentError) the argument value is invalid
```

Wenn wir wissen, dass ein Fehler auftreten kann, können wir diesen mit `try/rescue` und pattern matching behandeln:

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> end
An error occurred: Oh no!
:ok
```

Es ist möglich mehrere Fehler in einem einzelnen rescue zu behandeln:

```elixir
try do
  opts
  |> Keyword.fetch!(:source_file)
  |> File.read!
rescue
  e in KeyError -> IO.puts "missing :source_file option"
  e in File.Error -> IO.puts "unable to read source file"
end
```

## After

Manchmal kann es notwendig sein, eine bestimmte Aktion nach unserem `try/rescue` auszuführen, unabhängig vom Fehler. Dafür haben wir `try/after`.  Falls du mit Ruby vertraut bist, ist dir das als `begin/rescue/ensure` bekannt oder aus Javas `try/catch/finally`:

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> after
...>   IO.puts "The end!"
...> end
An error occurred: Oh no!
The end!
:ok
```

Das wird meistens mit Dateien oder Verbindungen eingesetzt, welche geschlossen werden müssen:

```elixir
{:ok, file} = File.open "example.json"
try do
   # Tue etwas gefährliches
after
   File.close(file)
end
```

## Neue Fehler

Während Elixir bereits eine große Zahl an eingebauten Fehlertypen wie `RuntimeError` bietet, haben wir dennoch die Möglichkeit unsere eigenen zu erstellen, falls wir etwas spezielles brauchen. Einen neuen Fehler zu erstellen ist einfach mit dem `defexception/1`-Makro, welches praktischerweise eine `:message`-Option bietet, um die Standardnachricht festzulegen:

```elixir
defmodule ExampleError do
  defexception message: "an example error has occurred"
end
```

Lass uns unseren neuen Fehler ausprobieren:

```elixir
iex> try do
...>   raise ExampleError
...> rescue
...>   e in ExampleError -> e
...> end
%ExampleError{message: "an example error has occurred"}
```

## Throws

Ein weiterer Mechanismus, um mit Fehlern in Elixir zu arbeiten, ist `throw` und `catch`. In der Praxis treten diese selten in neuerem Elixir Code auf, aber es ist dennoch wichtig sie zu kennen und zu verstehen.

Die `throw/1`-Funktion erlaubt uns die Ausführung mit einem bestimmten Wert zu verlassen, den wir mit `catch` auffangen und weiter benutzen können:

```elixir
iex> try do
...>   for x <- 0..10 do
...>     if x == 5, do: throw(x)
...>     IO.puts(x)
...>   end
...> catch
...>   x -> "Caught: #{x}"
...> end
0
1
2
3
4
"Caught: 5"
```

Wie bereits erwähnt wurde, ist `throw/catch` ziemlich selten und existiert als Lückenbüßer, wenn Bibliotheken keine passende bessere API bieten.

## Exit

Der letzte Fehler-Mechanismus in Elixir ist `exit`. Exit-Signale treten in Elixir auf, wenn ein Prozess stirbt und ist ein wichtiger Teil der Fehlertoleranz in Elixir.

Um explizit auszusteigen, können wir `exit/1` benutzen:

```elixir
iex> spawn_link fn -> exit("oh no") end
** (EXIT from #PID<0.101.0>) evaluator process exited with reason: "oh no"
```

Während es möglich ist einen Austieg durch `try/catch` zu behandeln, ist es _extrem_ selten dies zu tun. In fast allen Fällen ist es besser den supervisor den Prozess-exit handhaben zu lassen:

```elixir
iex> try do
...>   exit "oh no!"
...> catch
...>   :exit, _ -> "exit blocked"
...> end
"exit blocked"
```
