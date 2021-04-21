---
version: 0.9.1
title: Funktionen
---

In Elixir und vielen anderen funktionalen Sprachen sind Funktionen "Bürger erster Klasse". Wir werden mehr über die Typen von Funktionen in Elixir lernen, was sie unterscheidet und wie man sie benutzt.

{% include toc.html %}

## Anonyme Funktionen

Wie der Name impliziert hat eine anonyme Funktion keinen Namen. Wie wir bereits in der `Enum`-Lektion gelernt haben, werden diese häufig an andere Funktionen übergeben. Um eine anonyme Funktion in Elixir zu definieren werden wir die keywords `fn` und `end` verwenden. Innerhalb dieser 2 keywords können wir eine beliebige Anzahl an Parametern und Funktionskörper getrennt durch `->` definieren.

Lass uns ein einfaches Beispiel anschauen:

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### Die Abkürzung &

Anonyme Funktionen in Elixir zu benutzen ist so üblich, dass es dafür eine Abkürzung gibt:

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

Wie du bereits wahrscheinlich erraten hast, sind in der verkürzten Version unsere Parameter mit `&1`, `&2`, `&3` und so weiter verfügbar.

## Pattern Matching

Pattern matching ist nicht nur auf Variablen in Elixir beschränkt, es kann genauso gut auf Funktionssignaturen angewandt werden, wie wir in dieser Sektion sehen können.

Elixir nutzt pattern matching, um den Satz an passenden Parametern zu finden und den entsprechenden Funktionskörper aufzurufen:

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
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

## Benannte Funktionen

Wir können Funktionen mit Namen definieren, so dass wir später einfacher auf sie zugreifen können. Benannte Funktionen werden innerhalb eines Moduls mit dem keyword `def` definiert. Wir werden mehr über Module in der nächsten Lektion lernen, momentan reicht es, wenn wir uns auf benannte Funktionen allein konzentrieren.

Funktionen, die innerhalb eines Modules definiert wurden, sind auch für andere Module nutzbar. Das ist ein besonders nützlicher Baustein in Elixir:

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex > Greeter.hello("Sean")
"Hello, Sean"
```

Falls unsere Funktion nur eine Zeile lang ist, können wir sie mit `do:` verkürzen:

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

Mit unserem Wissen über pattern matching bewaffnet, lass uns mit Hilfe von benannten Funktionen Rekursion weiter erkunden:

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

### Benennung von Funktionen und Arity

Wir haben früher erwähnt, dass Funktionen benannt werden mit der Kombination aus vergebenem Namen und der arity (Anzahl Argumente). Das bedeutet du kannst Folgendes tun:

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

Wir haben oben die Funktionsnamen in Kommentaren angegeben. Die erste Implementierung nimmt keine Argumente entgegen, also ist sie bekannt als `hello/0`; die zweite nimmt ein Argument und ist somit `hello/1` und so weiter. Anders wie überladene Funktionen aus anderen Sprachen kann man sich diese als _verschiedene_ Funktionen vorstellen. Pattern matching, wie vorhin erklärt, trifft nur zu, wenn mehrere Definitionen für Funktionsdefinitionen gegeben sind, die alle die _gleiche_ Anzahl Argumente besitzen.


### Private Funktionen

Wenn wir nicht wollen, dass andere Module auf Funktionen zugreifen, können wir diese Funktionen als privat definieren. Private Funktionen können nur innerhalb ihres Moduls aufgerufen werden. Wir definieren sie in Elixir mit `defp`:

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

### Guards

Wir haben guards kurz im Kapitel [Kontrollstrukturen](../control-structures) angeschnitten, jetzt werden wir sehen wie man sie auf benannte Funktionen anwenden kann. Wenn Elixir einmal eine Funktion gematched hat, werden alle vorhandenen guards überprüft.

Im folgenden Beispiel haben wir zwei Funktionen mit der selben Signatur, aber die guards entscheiden anhand der verwendeten Argumenttypen, welche Funktion aufgerufen wird.

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

iex> Greeter.hello(["Sean", "Steve"])
"Hello, Sean, Steve"
```

### Defaultargumente

Falls wir Defaultargumente für Werte verwenden wollen, benutzen wir die `Argument \\ Wert`-Syntax:

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

Wenn wir unser Beispiel mit guards mit Defaultargumenten kombinieren, rennen wir in ein Problem. Lass uns sehen, wie sich das auswirken kann:

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

Elixir kann Defaultargumente in mehreren matchenden Funktionen nicht auseinander halten. Um dieses Problem zu lösen können wir einen Funktionskopf mit Defaultargumenten hinzufügen:

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
