%{
  version: "0.9.1",
  title: "Custom Mix Tasks",
  excerpt: """
  Wie man custom Mix tasks für ein Elixir-Projekt erstellt.
  """
}
---

## Einleitung

Es ist nicht unüblich die Funktionalität einer Elixir-Anwendung durch hinzufügen eines custom Mix tasks erweitern zu wollen. Bevor wir lernen, wie man einen spezifischen Mix task für ein Projekt erstellt, lass uns erstmal schauen, welche bereits vorhanden sind:

```shell
$ mix phx.new my_phoenix_app

* creating my_phoenix_app/config/config.exs
* creating my_phoenix_app/config/dev.exs
* creating my_phoenix_app/config/prod.exs
* creating my_phoenix_app/config/prod.secret.exs
* creating my_phoenix_app/config/test.exs
* creating my_phoenix_app/lib/my_phoenix_app.ex
* creating my_phoenix_app/lib/my_phoenix_app/endpoint.ex
* creating my_phoenix_app/test/views/error_view_test.exs
...
```

Wie man am Shell-Kommando oben sehen kann, hat das Phoenix Framework einen custom Mix task, um ein neues Projekt zu erstellen. Was, wenn wir etwas Ähnliches für unser Projekt machen wollen? Nun, die gute Nachricht ist, dass wir das können und Elixir das auch noch einfach für uns macht.

## Setup

Lass uns eine ganz einfache Mix-Anwendung anlegen:

```shell
$ mix new hello

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/hello.ex
* creating test
* creating test/test_helper.exs
* creating test/hello_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

cd hello
mix test

Run "mix help" for more commands.
```

In der Datei **lib/hello.ex**, die Mix für uns angelegt hat, lass uns eine einfache Funktion erstellen, die nur "Hello, World!" ausgibt:

```elixir
defmodule Hello do
  @doc """
  Gib jedes Mal `Hello, World!` aus.
  """
  def say do
    IO.puts("Hello, World!")
  end
end
```

## Custom Mix Task

Lass uns unseren custom Mix task anlegen. Erstelle ein neues Verzeichnis und die Datei **hello/lib/mix/tasks/hello.ex**. Füge dieser Datei die folgenden 7 Zeilen Elixir Code hinzu:

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Ruft einfach nur die Hello.say/0-Funktion auf."
  def run(_) do
    # Rufe unsere Hello.say()-Funktion von vorhin auf.
    Hello.say()
  end
end
```

Beachte wir wir das defmodule statement mit `Mix.Tasks` und dem Namen, den wir auf der Kommandozeile zum starten unseres Tasks haben wollen, beginnen. In der zweiten Zeile benutzen wir `use Mix.Task`, was uns das `Mix.Task`-Verhalten in unseren Namespace importiert. Dann definieren wir eine Funktion `run`, die bis jetzt alle Argumente ignoriert. In dieser Funktion rufen wir die Funktion `say` aus dem Modul `Hello` auf.

## Mix Tasks in Aktion

Lass uns unseren Mix task austesten. Solang wir in dem Verzeichnis sind, sollte es funktionieren. Rufe `mix hello` von der Kommandozeile auf und du solltest das Folgende sehen:

```shell
$ mix hello
Hello, World!
```

Mix ist standardmäßig ziemlich freundlich. Es weiß, dass jeder hier und da mal einen Tippfehler machen kann und benutzt eine Technik namens "fuzzy string matching", um Vorschläge zu machen:

```shell
$ mix hell
** (Mix) The task "hell" could not be found. Did you mean "hello"?
```

Ist dir aufgefallen, dass wir ein neues Modulattribut, `@shortdoc`, verwendet haben? Das ist nützlich, wenn wir unsere Anwendung ausrollen und beispielsweise ein Benutzer den Befehl `mix help` in seinem Terminal aufruft.

```shell
$ mix help

mix app.start         # Starte alle registrierten Anwendungen
...
mix hello             # Ruft einfach nur die Hello.say/0-Funktion auf.
...
```
