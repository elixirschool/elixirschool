%{
  version: "0.9.2",
  title: "Dokumentation",
  excerpt: """
  Wie dokumentiert man Elixir Code?
  """
}
---

## Anmerkungen

Wieviel wir kommentieren und was qualitativ hochwertige Dokumentation ausmacht bleibt ein umstrittenes Thema in der Programmierwelt. Wir können uns jedoch alle darauf einigen, dass Dokumentation wichtig für uns selbst und die Leute ist, die mit uns an der gleichen Codebasis arbeiten.

Elixir betrachtet Dokumentation als einen *Bürger erster Klasse* und bietet diverse Funktionen, um Dokumentation für deine Projekte abzurufen und zu generieren. Elixir bietet uns viele verschiedene Attribute, um Codebasen zu kommentieren. Lass uns 3 Möglichkeiten anschauen:

  - `#` - Für Inline-Dokumentation.
  - `@moduledoc` - Für Dokumentation auf Modulebene.
  - `@doc` - Für Dokumentation auf Funktionsebene.

### Inline-Dokumentation

Wahrscheinlich ist der einfachste Weg Code zu kommentieren durch Inline-Dokumentation. Ähnlich wie in Ruby oder Python werden Inline-Kommentare in Elixir durch `#` gekennzeichnet, häufig *Raute* oder *Lattenzaun* genannt.

Nimm etwa dieses Elixirskript (greeting.exs):

```elixir
# Gibt 'Hello, chum.' auf der Konsole aus.
IO.puts("Hello, " <> "chum.")
```

Wenn Elixir dieses Skript ausführt, wird jedes Zeichen hinterhalb von `#` bis zum Ende der Zeile ignorieren. Es ändert nichts an der Ausführung oder Performance des Skripts, falls jedoch nicht klar ist, was an dieser Stelle passiert, so kann ein anderer Programmierer durch Lesen des Kommentars den Code eher verstehen. Sei bedacht bei der Benutzung von einzeiligen Kommentaren! Das "Zumüllen" der Codebasis durch einzeilige Kommentare resultiert in einem Albtraum für Leute, die sich in die Codebasis einarbeiten müssen. Am besten werden sie spärlich eingesetzt.

### Module dokumentieren

Der `@moduledoc` annotator erlaubt es Inline-Dokumentation auf Modulebene zu schreiben. Üblicherweise folgt es direkt auf die `defmodule` Deklaration am Anfang einer Datei. Das untere Beispiel zeigt einen einzeiligen Kommentar innerhalb des `@moduledoc` decorators.

```elixir
defmodule Greeter do
  @moduledoc """
  Bietet eine `hello/1` Funktion, um Menschen zu begrüßen
  """

  def hello(name) do
    "Hello, " <> name
  end
end
```

Wir (oder andere) können diese Moduldokumentation über die `h` Hilfsfunktion in IEx abrufen.

```elixir
iex> c("greeter.ex", ".")
[Greeter]

iex> h Greeter

                Greeter

Bietet eine `hello/1` Funktion, um Menschen zu begrüßen
```

### Funktionen dokumentieren

Genauso wie uns Elixir erlaubt auf Modulebene Dokumentation zu schreiben, so gibt es ähnliche Möglichkeiten, um Funktionen zu dokumentieren. Der `@doc` annotator erlaubt es Inline-Dokumentation auf Funktionsebene zu schreiben. Der `@doc` annotator ist direkt überhalb der Funktion, die er annotiert.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Gibt eine hello-Nachricht aus

  ## Parameter

    - name: String, der den Namen der Person darstellt.

  ## Beispiele

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

Wenn wir nun in IEx gehen und die Hilfsfunktion (`h`) auf der Funktion, mit dem Modulnamen vorangestellt, aufrufen, sehen wir das folgende:

```elixir
iex> c("greeter.ex")
[Greeter]

iex> h Greeter.hello

                def hello(name)

Gibt eine hello-Nachricht aus

Parameters

  • name: String, der den Namen der Person darstellt.

Beispiele

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"

iex>
```

Ist dir aufgefallen, wie du Markup innerhalb unserer Dokumentation nutzen kannst und das Terminal wird es rendern? Nicht nur ist das cool und eine neue Ergänzung zu dem großen Ökosystem von Elixir, es wird noch viel interessanter, wenn wir uns ExDoc anschauen, um HTML-Dokumentation auf die Schnelle zu generieren.

**Note:** Die `@spec` Anmerkung wird dazu genutzt, statische Codeanalyse durchzuführen. Um mehr darüber zu lernen, schau doch in das Kapitel [Spezifikationen und Typen](../../advanced/typespec).

## ExDoc

ExDoc ist ein offizielles Elixirprojekt, welches auf [GitHub](https://github.com/elixir-lang/ex_doc) zu finden ist. Es erzeugt **HTML (HyperText Markup Language) und Onlinedokumentation** für Elixirprojekte. Lass uns als Erstes ein Mix-Projekt für unsere Anwendung anlegen:

```bash
$ mix new greet_everyone

* creating README.md
* creating .gitignore
* creating .formatter.exs
* creating mix.exs
* creating lib
* creating lib/greet_everyone.ex
* creating test
* creating test/test_helper.exs
* creating test/greet_everyone_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd greet_everyone
    mix test

Run "mix help" for more commands.

$ cd greet_everyone

```

Kopiere und füge den Code der `@doc` annotator Lektion nun in eine Datei namens `lib/greeter.ex` ein und geh sicher, dass alles andere immer noch von der Kommandozeile funktioniert. Da wir nun mit einem Mix-Projekt arbeiten, müssen wir IEX etwas anders benutzen. Nimm den `iex -S mix`-Befehl:

```bash
iex> h Greeter.hello

                def hello(name)

Gibt eine hello-Nachricht aus

Parameter

  • name: String, der den Namen der Person darstellt.

Beispiele

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"
```

### Installation

Davon ausgehend, dass soweit alles funktioniert und wir die Ausgabe wie oben sehen, können wir nun ExDoc aufsetzen. In der `mix.exs`-Datei füge zwei Abhängigkeiten hinzu, um zu starten: `:earmark` und `:ex_doc`.

```elixir
def deps do
  [{:earmark, "~> 0.1", only: :dev}, {:ex_doc, "~> 0.11", only: :dev}]
end
```

Wir spezifizieren das `only: :dev` key-value-Paar, da wir diese Abhängigkeiten nicht in einer Produktionsumgebung herunterladen und kompilieren wollen. Aber wieso Earmark? Earmark ist ein Markdown-Parser für Elixir, den ExDoc benutzt, um unsere Dokumentation innerhalb von `@moduledoc` und `@doc` in schönes HTML zu verwandeln.

Es ist an diesem Punkt festzuhalten, dass du nicht unbedingt Earmark nutzen musst. Du kannst genauso gut ein anderes Markuptool wie Pandoc, Hoedown oder Cmark benutzen; jedoch wirst du ein wenig mehr konfigurieren müssen, wie du [hier](https://github.com/elixir-lang/ex_doc#changing-the-markdown-tool) nachlesen kannst. Für dieses Tutorial halten wir uns einfach an Earmark.

### Dokumentation generieren

Lass uns nun die folgenden beiden Befehle auf der Kommandozeile ausführen:

```bash
$ mix deps.get # lädt ExDoc + Earmark.
$ mix docs # erstellt die Dokumentation.

Docs successfully generated.
View them at "doc/index.html".
```

Falls alles nach Plan abläuft solltest du eine ähnliche Meldung wie in der Ausgabe aus obigem Beispiel lesen können. Lass uns nun in's Mix-Projekt schauen, und wir werden sehen, dass es dort einen neuen Ordner namens **doc/** gibt. Darin ist unsere generierte Dokumentation. Falls wir die Indexseite in unserem Browser aufrufen, sollten wir das folgende sehen:

![ExDoc Screenshot 1](/images/documentation_1.png)

Wir können sehen, dass Earmark unser Markdown gerendert hat und ExDoc es in einem sinnvollen Format anzeigt.

![ExDoc Screenshot 2](/images/documentation_2.png)

Jetzt können wir es auf GitHub, unserer eigenen Webseite oder auch wie üblich [HexDocs](https://hexdocs.pm/) hochladen.

## Best Practice

Dokumentation schreiben sollte in die best practices Richtlinien einer Programmiersprache aufgenommen werden. Da Elixir eine recht junge Sprache ist und das Ökosystem noch wächst, können noch viele Standards entdeckt werden. Die Community hat jedoch bereits probiert best practices zu etablieren. Um mehr über diese best practices zu lesen, schau in den [Elixir Style Guide](https://github.com/niftyn8/elixir_style_guide).

  - Dokumentiere ein Modul immer.

```elixir
defmodule Greeter do
  @moduledoc """
  Das ist gute Dokumentation.
  """

end
```

  - Falls du nicht vorhast ein Modul zu dokumentieren, lass es **nicht** einfach leer. Zieh in Erwägung das Modul mit `false` zu annotieren:

```elixir
defmodule Greeter do
  @moduledoc false

end
```

 - Wenn du dich innerhalb einer Moduldokumentation auf eine Funktion beziehst, benutze Backticks wie hier:
```elixir
defmodule Greeter do
  @moduledoc """
  ...

  Dieses Modul hat auch eine `hello/1` Funktion.
  """

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 - Schreibe jeglichen Code getrennt durch eine Leerzeile unter `@moduledoc`:

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  Dieses Modul hat auch eine `hello/1` Funktion.
  """

  alias Goodbye.bye_bye
  # und so weiter...

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 - Benutze Markdown innerhalb von Funktionen, um das Lesen via IEx oder ExDoc einfacher zu machen.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Gibt eine hello-Nachricht aus

  ## Parameter

    - name: String, der den Namen der Person darstellt.

  ## Beispiele

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

 - Versuche ein paar Codebeispiele in deiner Dokumentation zu schreiben. Das erlaubt es dir zudem automatisch Tests aus Codebeispielen zu generieren. Das ist in Modulen, Funktionen oder Makros durch [ExUnit.DocTest][] möglich. Um das zu tun, musst du das `doctest/1`-Makro in deinem Testcode aufrufen und die Beispiele so schreiben, wie es die Richtlinien in der [offiziellen Dokumentation][ExUnit.DocTest] beschreiben.

[ExUnit.DocTest]: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html
