---
version: 0.9.2
title: Mix
---

Bevor wir in tiefere Gewässer von Elixir eintauchen können, müssen wir erst mix lernen. Falls du mit Ruby vertraut bist, so ist mix wie Bundler, RubyGems und Rake zusammen. Es ist ein elementarer Bestandteil eines Elixir-Projekts und in dieser Lektion werden wir ein paar der tollen Features kennenlernen, die uns mix bietet. Um alles zu sehen, was dir mix bietet, sieh dir doch `mix help` an.

Bis jetzt haben wir ausschließlich innerhalb von `iex` mit dessen Limitierungen gearbeitet. Um etwas Bedeutenderes zu bauen müssen wir unseren Code in mehr Dateien aufteilen, um ihn effektiv zu verwalten. Mix lasst uns genau das für unsere Projekte tun.

{% include toc.html %}

## Neue Projekte

Wenn wir soweit sind, ein neues Elixir-Projekt zu erstellen, macht mix es uns mit dem `mix new`-Befehl einfach. Dieser generiert die Verzeichnisstruktur unseres Projekts und notwendiges Boilerplate. Alles ziemlich unkompliziert, also lass uns loslegen:

```bash
$ mix new example
```

An der Ausgabe können wir sehen, dass mix unser Verzeichnis und eine Sammlung an Boilerplatedateien erstellt hat:

```bash
* creating README.md
* creating .gitignore
* creating .formatter.exs
* creating mix.exs
* creating lib
* creating lib/example.ex
* creating test
* creating test/test_helper.exs
* creating test/example_test.exs
```

In dieser Lektion konzentieren wir uns auf `mix.exs`. Wir konfigurieren unsere Anwendung, Abhängigkeiten, Umgebung und Version. Öffne die Datei mit deinem Editor und du solltest etwas Ähnliches wie hier sehen (Kommentare für die Lesbarkeit entfernt):

```elixir
defmodule Example.Mix do
  use Mix.Project

  def project do
    [
      app: :example,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end
end
```

Die erste Sektion, welche wir anschauen werden ist `project`. Hier definieren wir den Namen unserer Anwendung (`app`), spezifizieren die Version (`version`), Elixir-Version (`elixir`) und am Schluss Abhängigkeiten (`deps`).

Die Sektion `application` wird während der Erstellung unserer Anwendungsdatei wichtig, was wir uns gleich ansehen.

## Interaktiv

Es könnte vonnöten sein `iex` im Kontext unserer Anwendung zu starten. Glücklicherweise macht mix das einfach. Wir können so eine neue `iex`-Sitzung starten:

```bash
$ cd example
$ iex -S mix
```

`iex` auf diese Weise zu starten lädt unsere Anwendung und Abhängigkeiten in die aktuelle Laufzeitumgebung.

## Kompilieren

Mix ist clever und kompiliert Änderungen, falls notwendig. Es kann jedoch immer noch notwendig sein dein Projekt manuell zu kompilieren. In dieser Sektion werden wir uns ansehen, wie man ein Projekt kompiliert und was das alles bedeutet.

Um ein mix-Projekt zu kompilieren brauchen wir nur `mix compile` im Hauptverzeichnis unserer Anwendung aufzurufen:

```bash
$ mix compile
```

Da noch nicht viel in unserem Projekt vorhanden ist, ist die Ausgabe nicht besonders spannend:

```bash
Compiled lib/example.ex
Generated example app
```

Wenn wir ein Projekt kompilieren kreiert mix ein Verzeichnis `_build` für unsere Artefakte. Falls wir dort einen Blick rein werfen, sehen wir unsere kompilierte Anwendung: `example.app`.

## Abhängigkeiten verwalten

Unser Projekt hat noch keine Abhängigkeiten, wird sie aber bald haben und so fahren wir fort und behandeln wie man Abhängigkeiten definiert und herunterlädt.

Um eine neue Abhängigkeit festzulegen müssen wir sie zuerst in die Sektion `deps` der Datei `mix.exs` hinzufügen. Unsere Liste von Abhängigkeiten besteht aus Tupeln mit zwei notwendigen Werten und einem optionalen Wert: Der Paketname als atom, dem Versionsstring und optionalen Optionen.

Für dieses Beispiel lass uns ein Beispiel mit Abhängigkeiten anschauen, etwa [phoenix_slim](https://github.com/doomspork/phoenix_slim):

```elixir
def deps do
  [
    {:phoenix, "~> 1.1 or ~> 1.2"},
    {:phoenix_html, "~> 2.3"},
    {:cowboy, "~> 1.0", only: [:dev, :test]},
    {:slime, "~> 0.14"}
  ]
end
```

Wie du vielleicht schon anhand der Abhängigkeiten oben erkennen kannst ist `cowboy` nur während der Entwicklung und Tests wichtig.

Haben wir einmal unsere Abhängigkeiten definiert, bleibt nur noch eines übrig: Sie herunterladen. Das ist analog zu `bundle install`:

```bash
$ mix deps.get
```

Das war's! Wir haben unsere Abhängigkeiten definiert und heruntergeladen. Nun sind wir darauf vorbereitet mit Abhängigkeiten umzugehen, wenn die Zeit kommt.

## Umgebungen

Mix unterstützt wie Bundler abweichende Umgebungen. Standardmäßig arbeitet mix mit drei Umgebungen:

+ `:dev` — Die Standardumgebung.
+ `:test` — Von `mix test` genutzt. Wird in unserer nächsten Lektion behandelt.
+ `:prod` — Wird benutzt, wenn wir unsere Anwendung in eine Produktionsumgebung bringen.

Die aktuell verwendete Umgebung kann mit `Mix.env` abgefragt werden. Wie erwartet kann die Umgebung mit der `MIX_ENV`-Umgebungsvariable gesetzt werden:

```bash
$ MIX_ENV=prod mix compile
```
