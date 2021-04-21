---
version: 1.0.3
title: Spezifikationen und Typen
---

In dieser Lektion werden wir die `@spec`- und `@type`-Syntax kennen lernen. Die Erste ist eine Ergänzung um Dokumentation zu schreiben, die von Tools ausgewertet werden kann. Die Zweite hilft uns lesbareren und einfacheren Code zu schreiben.

{% include toc.html %}

## Einführung

Es ist nicht ungewöhnlich, dass du das Interface deiner Funktionen beschreiben möchtest. Natürlich kannst du die [@doc Annotation](../../basics/documentation) benutzen, aber das ist nur Information für andere Entwickler, welche nicht während der Kompiliervorgangs überprüft wird. Aus diesem Grund bietet Elixir `@spec`-Annotation, um Spezifikationen von Funktionen zu beschreiben, die vom Compiler überprüft werden.

Jedoch sind Spezifikationen in manchen Fällen ziemlich groß und umständlich. Falls du Komplexität reduzieren möchtest, möchtest du benutzerdefinierte Typdefinitionen einführen. Elixir hat dafür `@type`-Annotationen. Andererseits ist Elixir immer noch eine dynamische Sprache. Das bedeutet jegliche Information über Typen wird vom Compiler ignoriert, kann jedoch von anderen Tools benutzt werden.

## Spezifikationen

Falls du bereits Erfahrung mit Java hast, sind dir Spezifikationen als `interface` vertraut. Spezifikationen definieren welche Typen Funktionsparameter und Rückgabewerte haben.

Um Eingabe- und Ausgabewerte zu definieren benutzen wir die `@spec`-Direktive direkt vor der Funktionsdefinition und nehmen den Funktionsnamen, die Liste der Parametertypen, sowie nach `::` die Typen der Rückgabewerte.

Schau dir das folgende Beispiel an:

```elixir
@spec sum_product(integer) :: integer
def sum_product(a) do
  [1, 2, 3]
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
end
```

Das sieht auf den ersten Blick alles OK aus, jedoch gibt die Funktion `Enum.sum` eine `number` und nicht einen `integer` wie in `@spec` angegeben zurück. Das könnte Bugs verursachen! Es gibt Tools wie Dialyzer zur statischen Analyse, die uns helfen solche Art Bugs zu finden. Wir werden sie in einer anderen Lektion besprechen.

## Benutzerdefinierte Typen

Spezifikationen schreiben ist ganz nett, aber manchmal arbeiten unsere Funktionen mit komplexeren Datenstrukturen als einfache Nummern oder collections. In diesem Fall wäre die Definition in `@spec` schwer für andere Entwickler zu verstehen oder zu ändern. Manchmal müssen Funktionen eine große Zahl Parameter entgegennehmen oder komplexe Daten zurückgeben. Eine lange Parameterliste ist eine der vielen Möglichkeiten für code smells im Code. In objektorientieren Sprachen wie Ruby oder Java könnten wir einfach Klassen definieren, die uns dabei helfen, dieses Problem zu lösen. Elixir kennt keine Klassen, ist aber einfach zu erweitern, so dass wir unsere Typen definieren können.
Standardmäßig bietet Elixir einfache Typen wie `integer` oder `pid`. Du findest eine Liste aller Typen in der [Dokumentation](https://hexdocs.pm/elixir/typespecs.html#types-and-their-syntax).

### Typen definieren

Lass uns unsere `sum_times`-Funktion verändern und ein paar extra Parameter einfügen:

```elixir
@spec sum_times(integer, %Examples{first: integer, last: integer}) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

Wir haben ein struct im `Examples`-Modul hinzugefügt, das die beiden Felder `first` und `last` beinhaltet. Das ist die einfachere Version des structs aus dem `Range`-Modul. Wir sprechen noch über `structs`, wenn wir [Module](../../basics/modules/#structs) besprechen. Lass uns davon ausgehen, dass wir das `Examples`-struct an vielen Stellen brauchen und es nervtötend ist lange, komplexe Spezifikationen zu schreiben, die Bugs herbeiführen könnten. Eine Lösung für dieses Problem ist `@type`.

Elixir hat drei Direktiven für Typen:

  - `@type` – einfacher, öffentlicher Typ. Interne Struktur des Typen ist öffentlich.
  - `@typep` – Typ ist privat und kann nur innerhalb des Moduls genutzt werden, in dem es definiert wurde.
  - `@opaque` – Typ ist öffentlich, aber interne Struktur ist privat.

Lass uns unseren Typ definieren:

```elixir
defmodule Examples do
  defstruct first: nil, last: nil

  @type t(first, last) :: %Examples{first: first, last: last}

  @type t :: %Examples{first: integer, last: integer}
end
```

Wir haben den Typ `t(first, last)` bereits definiert, welcher eine Repräsentation des structs `%Examples{first: first, last: last}` ist. An diesem Punkt sehen wir, dass Typen Parameter entgegen nehmen können, aber wir haben den Typ `t` ebenfalls definiert und diesmal ist er eine Repräsentation des structs `%Examples{first: integer, last: integer}`.   

Wo ist der Unterschied? Der erste Fall repräsentiert das struct `Examples`, bei dem die zwei keys von jedem Typ sein könnten. Im zweiten Fall repräsentiert ein struct dessen keys `integer` sind. Das bedeutet Code wie:

```elixir
@spec sum_times(integer, Examples.t()) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

Ist gleichbedeutend zu:

```elixir
@spec sum_times(integer, Examples.t(integer, integer)) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

### Dokumentation von Typen

Der letzte Punkt, über den wir reden sollten, ist wie man Typen dokumentiert. Wie wir bereits aus der  [Dokumentation](../../basics/documentation)-Lektion wissen gibt es `@doc`- und `@moduledoc`-Annotationen, um Dokumentation für Funktionen und Module zu schreiben. Um Typen zu dokumentieren können wir `@typedoc` nutzen:

```elixir
defmodule Examples do
  @typedoc """
      Type that represents Examples struct with :first as integer and :last as integer.
  """
  @type t :: %Examples{first: integer, last: integer}
end
```

Die Direktive `@typedoc` ist ähnlich zu `@doc` und `@moduledoc`.
