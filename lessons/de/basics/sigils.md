%{
  version: "0.9.0",
  title: "Sigils",
  excerpt: """
  Arbeiten mit sigils und erstellen dieser.
  """
}
---

## Überblick über Sigils

Elixir bietet eine alternative Syntax, um Literale darzustellen und damit zu arbeiten. Ein sigil startet mit der Tilde `~`, gefolgt von einem Zeichen. Der Kern von Elixir bietet uns einige eingebaute sigils, jedoch ist es auch möglich eigene zu erstellen, falls wir die Sprache erweitern möchten.

Die Liste vorhandener sigils beinhaltet:

  - `~C` Erstellt eine Characterliste **ohne** escaping und Interpolation
  - `~c` Erstellt eine Characterliste **mit** escaping oder Interpolation
  - `~R` Erstellt einen regulären Ausdruck **ohne** escaping oder Interpolation
  - `~r` Erstellt eine regulären Ausdruck **mit** escaping und Interpolation
  - `~S` Erstellt eine String **ohne** escaping oder Interpolation
  - `~s` Erstellt einen String **mit** escaping oder Interpolation
  - `~W` Erstellt eine Wörterliste **ohne** escaping oder Interpolation
  - `~w` Erstellt eine Wörterliste **mit** escaping und Interpolation
  - `~N` Erstellt ein `NaiveDateTime` struct

Eine Liste an Trennzeichen beinhaltet:

  - `<...>` Ein Paar spitze Klammern
  - `{...}` Ein Paar geschweifte Klammern
  - `[...]` Ein Paar eckige Klammern
  - `(...)` Ein Paar runde Klammern
  - `|...|` Ein Paar pipes
  - `/.../` Ein Paar Slashes
  - `"..."` Ein Paar doppelte Anführungszeichen
  - `'...'` Ein Paar einfache Anführungszeichen

### Characterlisten

Die `~c` und `~C` sigils erstellen jeweils Characterlisten. Zum Beispiel

```elixir
iex> ~c/2 + 7 = #{2 + 7}/
'2 + 7 = 9'

iex> ~C/2 + 7 = #{2 + 7}/
'2 + 7 = \#{2 + 7}'
```

Wir können sehen, dass das kleingeschriebene `~c` die Berechnung interpoliert, wohingegen das großgeschriebene `~C` sigil dieses nicht tut. Wir werden sehen, dass diese Großschreibung/Kleinschreibung ein oft verwendetes Motiv bei eingebauten sigils ist.

### Reguläre Ausdrücke

Die `~r` und `~R` sigils werden für reguläre Ausdrücke benutzt. Wir erstellen sie entweder spontan oder für den Gebrauch innerhalb von `Regex`-Funktionen. Beispielsweise:

```elixir
iex> re = ~r/elixir/
~r/elixir/

iex> "Elixir" =~ re
false

iex> "elixir" =~ re
true
```

Wir können im ersten Test auf Gleichheit sehen, dass `Elixir` nicht auf den regulären Ausdruck matched. Das liegt daran, dass der Anfang ein Großbuchstabe ist. Da Elixir Perl Compatible Regular Expressions (PCRE) unterstützt, können wir `i` an das Ende unseres sigils anhängen, um die Beachtung von Groß- und Kleinschreibung auszuschalten.

```elixir
iex> re = ~r/elixir/i
~r/elixir/i

iex> "Elixir" =~ re
true

iex> "elixir" =~ re
true
```

Des Weiteren bietet Elixir die [Regex](https://hexdocs.pm/elixir/Regex.html) API, welche auf die reguläre Ausdrücke-Bibliothek von Erlang aufbaut. Lass uns `Regex.split/2` mit Hilfe eines regex sigils implementieren:

```elixir
iex> string = "100_000_000"
"100_000_000"

iex> Regex.split(~r/_/, string)
["100", "000", "000"]
```

Wie wir sehen können wird der String `"100_000_000"` an dessen Unterstrichen getrennt dank des `~r/_/` sigils. Die `Regex.split`-Funktion gibt eine Liste zurück.

### String

Die `~s` und `~S` sigils werden dafür genutzt Strings zu generieren. Zum Beispiel:

```elixir
iex> ~s/the cat in the hat on the mat/
"the cat in the hat on the mat"

iex> ~S/the cat in the hat on the mat/
"the cat in the hat on the mat"
```

Wo ist der Unterschied? Der Unterschied ist ähnlich zum Characterliste-sigil, das wir bereits gesehen haben. Die Antwort ist Interpolation und der Gebrauch von Escapesequenzen. Wenn wir nochmal einen Blick darauf werfen:

```elixir
iex> ~s/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir school"

iex> ~S/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir \#{String.downcase \"SCHOOL\"}"
```

### Wörterlisten

Das Wortlisten-sigil kann von Zeit zu Zeit praktisch sein. Es kann sowohl Zeit als auch Tastenanschläge sparen, sowie die Komplexität der Codebasis verringern. Nimm dieses simple Beispiel:

```elixir
iex> ~w/i love elixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love elixir school/
["i", "love", "elixir", "school"]
```

Wir können sehen, dass das zwischen den Abgrenzern anhand der Whitespaces in eine Liste geteilt wird. Jedoch gibt es keinen Unterschied zwischen den beiden Beispielen. Um es nochmal zu sagen: Der Unterschied kommt erst bei Interpolation und Escapesequenzen, wie etwa hier:

```elixir
iex> ~w/i love #{'e'}lixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love #{'e'}lixir school/
["i", "love", "\#{'e'}lixir", "school"]
```

### NaiveDateTime

[NaiveDateTime](https://hexdocs.pm/elixir/NaiveDateTime.html) kann nützlich sein, um schnell **ohne** Zeitzone ein struct zu erstellen, das `DateTime` repräsentiert.

In den meisten Fällen werden wir es vermeiden ein `NaiveDateTime` struct direkt zu benutzen. Für pattern matching ist es jedoch sinnvoll. Zum Beispiel:

```elixir
iex> NaiveDateTime.from_iso8601("2015-01-23 23:50:07") == {:ok, ~N[2015-01-23 23:50:07]}
```

## Sigils erstellen

Eines der Ziele von Elixir ist eine erweiterbare Programmiersprache zu sein. Es sollte daher nicht überraschen, dass du deine eigenen sigils erstellen kannst. In diesem Beispiel werden wir ein sigil erstellen, dass einen String in Großbuchstaben umwandelt. Da es dafür bereits im Kern von Elixir eine Funktion gibt (`String.upcase/1`), werden wir unser sigil darum wickeln.

```elixir

iex> defmodule MySigils do
...>   def sigil_u(string, []), do: String.upcase(string)
...> end

iex> import MySigils
nil

iex> ~u/elixir school/
ELIXIR SCHOOL
```

Zuerst definieren wir ein Modul namens `MySigils` und innerhalb dieses Moduls erstellen wir eine Funktion `sigil_u`. Da es kein existierendes `~u` sigil im vorhandenen sigil space gibt, können wir es benutzen. Das `_u` gibt an, dass wir `u` als das Zeichen nach der Tilde benutzen wollen. Die Funktionsdefinition muss zwei Argumente aufnehmen, den Input und eine Liste.
