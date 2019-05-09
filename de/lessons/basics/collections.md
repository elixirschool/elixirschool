---
version: 0.9.0
title: Collections
---

Listen, Tupel, Keywords, Maps und funktionale Kombinatoren.

{% include toc.html %}

## Listen

Listen sind einfache Ansammlungen von Werten, die verschiedene Werte beinhalten dürfen. Listen dürfen nicht einzigartige Werte beinhalten:

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir implementiert Listen als verkettete Listen. Das bedeutet der Zugriff auf die Listenlänge ist eine `O(n)` Operation. Aus diesem Grund ist ist meist schneller ein Element vorne hinzuzufügen als anzuhängen:

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> ["π" | list]
["π", 3.14, :pie, "Apple"]
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```


### Listen-Verkettung

Listen-Verkettung benutzt den `++/2` Operator:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

Eine Randnotiz zum Namen (`++/2`), welcher oben benutzt wurde: In Elixir (und Erlang, auf dessen Basis Elixir aufbaut) muss eine Funktion oder Operator zwei Komponenten haben: Den Namen, welcher du ihr/ihm gibst (hier `++`) und die _arity_. Arity ist ein essentielles Konzept, wenn man über Elixir (und Erlang) Code spricht. Es beschreibt die Nummer an Argumenten, die eine Funktion entgegen nimmt (zwei in unserem Fall). Arity und der vergebene Name werden mit einem Slash kombiniert. Wir werden später mehr darüber sprechen; vorerst reicht dein Wissen, um die Schreibweise zu verstehen.

### Listen-Subtraktion

Unterstützung von Subtraktion ist durch den `--/2` Operator gegeben; es ist gefahrlos einen fehlenden Wert zu subtrahieren:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

Gib acht auf doppelte Werte. Für jedes Element auf der rechten Seite wird ein auf der linken Seite vorkommendes Element gelöscht:

```elixir
iex> [1,2,2,3,2,3] -- [1,2,3,2]
[2, 3]
```

**Hinweis:** Es nutzt [strikte Vergleiche](../basics/#comparison) um die Werte zu vergleichen.

### Head / Tail

Wenn man Listen benutzt ist es üblich mit den Elementen `head` und `tail` einer Liste zu arbeiten. `head` ist das erste Element einer Liste, während `tail` alle anderen verbleibenden Elemente der Liste darstellt. Elixir bietet zwei hilfreiche Methoden, `hd` und `tl`, um mit diesen Teilen zu arbeiten:

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

Zusätzlich zu den bereits erwähnten Funktionen kannst du [Pattern Matching](../pattern-matching/) und den Cons-Operator `|` dazu benutzen eine Liste in `head` und `tail` zu teilen; wir werden in späteren Kapiteln mehr über dieses Pattern lernen:

```elixir
iex> [head | tail] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> head
3.14
iex> tail
[:pie, "Apple"]
```

## Tupel

Tupel sind Listen ähnlich, jedoch in angrenzenden Speicheradressen im Speicher abgelegt. Das macht Zugriffe auf ihre Länge schnell, aber Veränderungen kostspielig. Das neue Tupel muss komplett in den Speicher kopiert werden. Sie werden mit geschweiften Klammern geschrieben:

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

Es ist für Tupel üblich, dass sie als Mechanismus genutzt werden, um zusätzliche Informationen aus einer Funktion zu ziehen. Die Nützlichkeit davon wird offensichtlicher wenn wir Pattern Matching behandeln:

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Keyword Listen

Keywords und Maps sind assoziative Collections. In Elixir ist eine Keyword Liste eine spezielle Liste von Tupeln, deren erstes Element ein Atom ist. Sie teilen sich die Performance mit Listen:

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

Die drei Merkmale von Keyword Listen unterstreichen ihre Wichtigkeit:

+ Schlüssel sind Atoms.
+ Schlüssel sind sortiert.
+ Schlüssel sind nicht einzigartig.

Aus diesen Gründen sind Keyword Listen die am meist genutzten, um Optionen an Funktionen zu übergeben.

## Maps

In Elixir sind Maps der Weg um einen Key-Value Store zu implementieren. Im Gegensatz zu Keyword Listen erlauben Maps jeden Typ als Schlüssel und sind nicht sortiert. Listen werden mit der `%{}` Syntax definiert:

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

Ab Elixir 1.2 sind Variablen als Map-Schlüssel erlaubt:

```elixir
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
```

Falls ein Duplikat einer Map hinzugefügt wird, wird der neu gesetzte Wert den vorherigen ersetzen:

```elixir
iex> %{:foo => "bar", :foo => "hello world"}
%{foo: "hello world"}
```

Wie wir in der Ausgabe oben erkennen, gibt es eine spezielle Syntax für Maps, die nur aus Atom-Schlüsseln besteht:

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}

iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```

Eine weitere interessante Eigenschaft von Maps ist, dass sie ihre eigene Syntax zur Aktualisierung und Zugriff von Atom-Schlüsseln bieten:

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{map | foo: "baz"}
%{foo: "baz", hello: "world"}
iex> map.hello
"world"
```
