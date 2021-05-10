%{
  version: "1.0.2",
  title: "Metaprogrammierung",
  excerpt: """
  Metaprogrammierung ist die Vorgehensweise Code zu benutzen, um Code zu schreiben.
  In Elixir gibt uns das die Möglichkeit die Sprache zu erweitern, so dass sie unseren Anforderungen eher entspricht und dynamisch den Code zu verändern.
  Wir starten mit einem Blick darauf, wie Elixir unter der Haube repräsentiert wird; dann wie man es verändert und schlussendlich können wir dieses Wissen dazu nutzen, um es zu erweitern.

  Vorsicht: Metaprogrammierung ist kniffelig und sollte nur falls wirklich notwendig eingesetzt werden.
  Zuviel benutzt wird sie unweigerlich zu komplexem Code führen, der schwierig zu verstehen und debuggen ist.
  """
}
---

## Quote

Der erste Schritt für Metaprogrammierung ist zu verstehen, wie Ausdrücke repräsentiert werden. In Elixir besteht der abstract syntax tree (AST), die interne Repräsentation unseres Codes, aus Tupeln. Diese Tupel beinhalten drei Teile: Funktionsname, Metadaten und Funktionsargumente.

Um diese internen Strukturen zu betrachen, bietet uns Elixir die Funktion `quote/2`. Mit `quote/2` können wir Elixir Code in die darunterliegende Repräsentation verwandeln:

```elixir
iex> quote do: 42
42
iex> quote do: "Hello"
"Hello"
iex> quote do: :world
:world
iex> quote do: 1 + 2
{:+, [context: Elixir, import: Kernel], [1, 2]}
iex> quote do: if value, do: "True", else: "False"
{:if, [context: Elixir, import: Kernel],
 [{:value, [], Elixir}, [do: "True", else: "False"]]}
```

Ist dir aufgefallen, dass die ersten drei Aufrufe keine Tupel zurück gegeben haben? Es gibt fünf Literale, die sich selbst zurück geben, falls sie gequoted werden:

```elixir
iex> :atom
:atom
iex> "string"
"string"
iex> 1 # All numbers
1
iex> [1, 2] # Lists
[1, 2]
iex> {"hello", :world} # 2 element tuples
{"hello", :world}
```

## Unquote

Nun, da wir jetzt die interne Struktur unseres Codes erhalten können, wie verändern wir sie? Um neuen Code oder auch Werte zu injizieren benutzen wir `unquote/1`. Wenn wir einen Ausdruck unquoten, wird er ausgewertet und in den AST injiziert. Um `unquote/1` zu demonstrieren, lass uns ein paar Beispiele anschauen:

```elixir
iex> denominator = 2
2
iex> quote do: divide(42, denominator)
{:divide, [], [42, {:denominator, [], Elixir}]}
iex> quote do: divide(42, unquote(denominator))
{:divide, [], [42, 2]}
```

Im ersten Beispiel wird unsere Variable `denominator` gequoted, so dass der resultierende AST ein Tupel beinhaltet, um auf die Variable zugreifen zu können. Im `unquote/1`-Beispiel enthält der resultierende Code dagegen den Wert von `denominator`.

## Makros

Wenn wir erst mal `quote/2` und `unquote/1` verstanden haben, sind wir bereit dazu in Makros abzutauchen. Es ist wichtig sich zu merken, dass Makros wie jede Metaprogrammierung nur spärlich eingesetzt werden sollte.

In ihrer einfachsten Form sind Makros nur besondere Funktionen, die entworfen wurden, um einen gequoteten Ausdruck in unseren Anwendungscode zu injizieren. Stell dir vor, dass das Makro mit dem gequoteten Ausdruck ersetzt wird, anstatt wie eine Funktion aufgerufen zu werden. Mit Makros haben wir alles an der Hand, um Elixir zu erweitern und unserer Anwendung dynamisch Code hinzuzufügen.

Wir beginnen mit `defmacro/2` ein Makro zu definieren, welches, wie vieles in Elixir, selbst ein Makro ist (lass das erst mal ins Bewusstein dringen). Als Beispiel werden wir `unless` als Makro implementieren. Erinner dich daran, dass ein Makro einen gequoteten Ausdruck zurückgeben muss:

```elixir
defmodule OurMacro do
  defmacro unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end
```

Lass uns unser Modul requiren und unser Makro benutzen:

```elixir
iex> require OurMacro
nil
iex> OurMacro.unless true, do: "Hi"
nil
iex> OurMacro.unless false, do: "Hi"
"Hi"
```

Da Makros Code in unserer Anwendung ersetzen, können wir kontrollieren, was und wann etwas kompiliert wird. Ein Beispiel dafür kann im `Logger`-Modul gefunden werden. Wenn das Logging deaktiviert ist, wird kein Code injiziert und der so resultierende Code beinhaltet keine Referenzen oder Funktionsaufrufe auf das Logging. Das ist unterschiedlich zu anderen Sprachen, in denen das Overhead durch einen Funktionsaufruf darstellt wird, selbst wenn die Implementierung NOP ist.

Um dies zu demonstrieren, lass uns einen einfachen Logger erstellen, der entweder aktiviert oder deaktivert werden kann.

```elixir
defmodule Logger do
  defmacro log(msg) do
    if Application.get_env(:logger, :enabled) do
      quote do
        IO.puts("Logged message: #{unquote(msg)}")
      end
    end
  end
end

defmodule Example do
  require Logger

  def test do
    Logger.log("This is a log message")
  end
end
```

Wenn das Logging aktiviert ist, würde unsere `test`-Funktion im Code etwa so aussehen:

```elixir
def test do
  IO.puts("Logged message: #{"This is a log message"}")
end
```

Wenn wir das Logging deaktivieren, sieht der resultierende Code so aus:

```elixir
def test do
end
```

## Debugging

Okay, jetzt wissen wir, wie man `quote/2` und `unquote/1` benutzt und Makros schreibt. Aber was, wenn du einen großen Haufen gequoteten Code hast und diesen verstehen möchtest? In diesem Fall kannst du `Macro.to_string/2` benutzen. Sieht dir dieses Beispiel an:

```elixir
iex> Macro.to_string(quote(do: foo.bar(1, 2, 3)))
"foo.bar(1, 2, 3)"
```

Wenn du den Code anschauen möchtest, der durch die Makros erzeugt wird, kannst du sie mit `Macro.expand/2` und `Macro.expand_once/2` kombinieren. Diese Funktionen dehnen Makros in ihren gequoteten Code aus. Die erste Funktion dehnt sie eventuell mehrere Male aus, während die letztere dies nur einmal macht.
Lass uns zum Beispiel unser `unless`-Beispiel aus der vorherigen Sektion anschauen:

```elixir
defmodule OurMacro do
  defmacro unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end

require OurMacro

quoted =
  quote do
    OurMacro.unless(true, do: "Hi")
  end
```

```elixir
iex> quoted |> Macro.expand_once(__ENV__) |> Macro.to_string |> IO.puts
if(!true) do
  "Hi"
end
```

Falls wir den selben Code mit `Macro.expand/2` aufrufen, ist es faszinierend:

```elixir
iex> quoted |> Macro.expand(__ENV__) |> Macro.to_string |> IO.puts
case(!true) do
  x when x in [false, nil] ->
    nil
  _ ->
    "Hi"
end
```

Du kannst dich vielleicht daran erinnern, dass wir erwähnt hatten, dass `if` ein Makro in Elixir ist. Hier sieht du es ausgedehnt, in die darunter liegende `case`-Aussage.

### Private Makros

Obwohl sie nicht so häufig sind, unterstützt Elixir private Makros. Ein privates Makro wird mit `defmacrop` definiert und kann nur innerhalb des Moduls aufgerufen werden, in dem es definiert wurde. Ein Privates Makro muss vor dem Code definiert werden, der es aufruft.

### Makrohygiene

In welcher Weise Makros mit dem Kontext des Aufrufers interagieren, nachdem sie ausgedehnt wurden, ist als Makrohygiene bekannt. Standardmäßig sind Makros in Elixir hygienisch und erzeugen keine Konflikte in unserem Kontext:

```elixir
defmodule Example do
  defmacro hygienic do
    quote do: val = -1
  end
end

iex> require Example
nil
iex> val = 42
42
iex> Example.hygienic
-1
iex> val
42
```

Was, wenn wir den Wert von `val` manipulieren möchten? Um eine Variable als unhygienisch zu markieren, können wir `var!/2` benutzen. Lass uns das obige Beispiel aktualisieren und ein anderes Makro mit `var!/2` benutzen:

```elixir
defmodule Example do
  defmacro hygienic do
    quote do: val = -1
  end

  defmacro unhygienic do
    quote do: var!(val) = -1
  end
end
```

Lass uns vergleichen, wie sie mit unserem Kontext umgehen:

```elixir
iex> require Example
nil
iex> val = 42
42
iex> Example.hygienic
-1
iex> val
42
iex> Example.unhygienic
-1
iex> val
-1
```

Indem wir `var!/2` in unser Makro inkludiert haben, können wir den Wert von `val` verändern, ohne ihn an das andere Makro zu übergeben. Der Gebrauch von unhygienischen Makros sollte auf ein Minimum reduziert werden. Durch das Inkludieren von `var!/2` erhöhen wir das Risiko eines Auflösungskonflikts einer Variablen.

### Bindung

Wir haben bereits die Nützlichkeit von `unquote/1` besprochen, aber es gibt noch einen weiteren Weg Werte in unseren Code zu injizieren: Bindung. Durch Variablenbindung ist es uns möglich mehrere Variablen in unser Makro zu inkludieren und sicherzustellen, dass sie nur einmal unquoted werden, um so versehentliche Neuevaluierung zu umgehen. Um gebundene Variablen zu benutzen, müssen wir der Option `bind_quoted` in `quote/2` eine Liste an Keywords übergeben.

Um den Vorteil von `bind_quote` zu sehen und das Problem mit Neuevaluierung zu demonstrieren lass uns ein Beispiel erstellen. Wir starten mit der Erstellung eines Makros, das einen Ausdruck zweimal ausgeben soll:

```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote do
      IO.puts(unquote(expr))
      IO.puts(unquote(expr))
    end
  end
end
```

Wir testen unser neu erstelltes Makro, indem wir ihm die aktuelle Systemzeit übergeben. Wir erwarten, diese zweimal ausgegeben zu sehen:

```elixir
iex> Example.double_puts(:os.system_time)
1450475941851668000
1450475941851733000
```

Die Zeiten sind unterschiedlich! Was ist passiert? `unquote/1` mehrmals auf dem gleichen Ausdruck zu benutzen resultiert in Neuevaluierung, was unerwartete Konsequenzen bergen kann. Lass uns unser Beispiel so aktualisieren, dass es `bind_quoted` benutzt und dann nochmal sehen, was wir bekommen:

```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote bind_quoted: [expr: expr] do
      IO.puts(expr)
      IO.puts(expr)
    end
  end
end

iex> require Example
nil
iex> Example.double_puts(:os.system_time)
1450476083466500000
1450476083466500000
```

Mit `bind_quoted` bekommen wir das Ergebnis, das wir erwartet haben: Dieselbe Zeit zweimal ausgegeben.

Nun, da wir `quote/2`, `unquote/1` und `defmacro/2` behandelt haben, haben wir all die notwendigen Werkzeuge, um Elixir auf unsere Bedürfnisse anzupassen.
