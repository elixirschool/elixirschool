%{
  version: "0.9.1",
  title: "Strings",
  excerpt: """
  Strings, Characterlisten, Graphemes und Codepoints.
  """
}
---

## Strings

Elixir Strings sind nichts weiter als eine Bytesequenz. Nimm zum Beispiel:

```elixir
iex> string = <<104,101,108,108,111>>
"hello"
```

>NOTE: Die << >> Syntax sagt dem Compiler, dass die Elemente zwischen diesen Zeichen bytes sind.

## Characterlisten

Intern werden Elixir Strings als Sequenz von bytes repräsentiert, statt ein Array an Charactern. Elixir hat auch einen Typ Characterlisten. Elixir Strings werden in doppelten Anführungszeichen geschrieben, während Characterlisten in einfachen Anführungszeichen geschrieben werden.

Wo ist der Unterschied? Jeder Wert einer Characterliste ist der ASCII-Wert des Characters. Lass uns nachsehen:

```elixir
iex> char_list = 'hello'
'hello'

iex> [hd|tl] = char_list
'hello'

iex> {hd, tl}
{104, 'ello'}

iex> Enum.reduce(char_list, "", fn char, acc -> acc <> to_string(char) <> "," end)
"104,101,108,108,111,"
```

Wenn wir in Elixir programmieren benutzen wir Strings, keine Characterlisten. Die Unterstützung für Characterlisten ist hauptsächlich vorhanden, da es für einige Erlangmodule benötigt wird.

## Graphemes und Codepoints

Codepoints sind nur einfache Unicode-characters, die als ein oder mehrere bytes repräsentiert werden, abhängig von der UTF-8-Kodierung. Characters außerhalb des ASCII-Zeichensatzes werden immer mit mehr als einem byte repräsentiert. Zum Beispiel werden Latin-Buchstaben mit einer Tilde oder Akzent (`á, ñ, è`) üblicherweise als zwei bytes encoded. Characters aus asiatischen Sprachen werden oft mit drei oder vier bytes encoded. Graphemes bestehen aus mehreren codepoints, die als einzelner Character gerendert werden.

Das Stringmodul bietet bereits zwei Methoden, um sie zu erhalten, `graphemes/1` und `codepoints/1`. Lass uns ein Beispiel anschauen:

```elixir
iex> string = "\u0061\u0301"
"á"

iex> String.codepoints string
["a", "́"]

iex> String.graphemes string
["á"]
```

## Stringfunktionen

Lass uns nochmal ein paar der wichtisten und nützlichsten Funktionen des Stringmoduls anschauen. Diese Lektion wird nur einen Teil der verfügbaren Funktionen behandeln. Um eine komplette Liste an Funktionen zu sehen besuche die offizielle [`String`](https://hexdocs.pm/elixir/String.html)-Dokumentation.

### `length/1`

Gibt die Anzahl der Graphemes im String zurück.

```elixir
iex> String.length "Hello"
5
```

### `replace/3`

Gibt einen neuen String zurück, in dem das zu ersetzende pattern im String durch einen neuen String ersetzt wurde.

```elixir
iex> String.replace("Hello", "e", "a")
"Hallo"
```

### `duplicate/2`

Gibt einen neuen String n-mal zurück.

```elixir
iex> String.duplicate("Oh my ", 3)
"Oh my Oh my Oh my "
```

### `split/2`

Gibt eine Liste an Strings zurück, geteilt anhand eines patterns.

```elixir
iex> String.split("Hello World", " ")
["Hello", "World"]
```

## Übungen

Lass uns ein paar einfache Übungen durchgehen, um zu zeigen, dass wir Strings verstehen!

### Anagramme

A und B werden als Anagramme betrachtet, wenn man sie so umwandeln kann, dass sie gleich lauten. Zum Beispiel:

+ A = super
+ B = perus

Wenn wir die Buchstaben von String A umtauschen, können wir String B erhalten und andersrum.

Aber wie können wir nun überprüfen, ob zwei Strings Anagramme in Elixir sind? Die einfachste Lösung ist die Grapheme alphabetisch zu sortieren und dann zu überprüfen, ob beide Listen gleich sind. Lass uns das probieren:

```elixir
defmodule Anagram do
  def anagrams?(a, b) when is_binary(a) and is_binary(b) do
    sort_string(a) == sort_string(b)
  end

  def sort_string(string) do
    string
    |> String.downcase()
    |> String.graphemes()
    |> Enum.sort()
  end
end
```

Lass uns zuerst `anagrams?/2` anschauen. Wir überprüfen, ob die Parameter, die wir erhalten, binär sind oder nicht. So überprüfen wir in Elixir, ob ein Parameter ein String ist.

Danach rufen wir einfach nur eine Funktion auf, die die Strings in alphabetischer Reihenfolge sortiert. Als erstes wird der String nur mit Kleinbuchstaben geschrieben und dann `String.graphemes` aufgerufen, was eine Liste der Grapheme des Strings zurück gibt. Ziemlich einfach, was?

Lass uns die Ausgabe in IEx anschauen:

```elixir
iex> Anagram.anagrams?("Hello", "ohell")
true

iex> Anagram.anagrams?("María", "íMara")
true

iex> Anagram.anagrams?(3, 5)
** (FunctionClauseError) no function clause matching in Anagram.anagrams?/2

    The following arguments were given to Anagram.anagrams?/2:

        # 1
        3

        # 2
        5

    iex:11: Anagram.anagrams?/2
```

Wie du sehen kannst resultiert der Aufruf von `anagrams?` in einem FunctionClauseError. Dieser Fehler sagt uns, dass es keine Funktion in unserem Modul gibt, welche auf das pattern zutrifft, zwei nicht-binäre Argumente zu erhalten. Das ist genau das, was wir wollen, um nur zwei Strings zu erhalten und nichts anderes.
