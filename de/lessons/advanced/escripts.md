---
version: 0.9.1
title: Ausführbare Dateien
---

Um ausführbare Dateien in Elixir zu erstellen werden wir escript benutzen. Escript erzeugt eine ausführbare Datei, welche auf jedem System lauffähig ist, auf dem Erlang installiert ist.

{% include toc.html %}

## Einstieg

Um eine ausführbare Datei mit escript zu erzeugen gibt es nur wenige Dinge zu tun: Eine `main/1` Methode erzeugen und das Mixfile anpassen.

Wir starten mit der Erzeugung eines Moduls, welches als Einstiegspunkt für unsere ausführbare Datei dienen soll. Dort werden wir `main/1` implementieren:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    # Mache irgendetwas
  end
end
```

Als nächstes müssen wir für unser Projekt in unserem Mixfile die `:escript` Option aufnehmen. Dazu müssen wir noch ein `:main_module` festlegen:

```elixir
defmodule ExampleApp.Mixfile do
  def project do
    [app: :example_app, version: "0.0.1", escript: escript()]
  end

  defp escript do
    [main_module: ExampleApp.CLI]
  end
end
```

## Argumente parsen

Mit unserer erstellten Anwendung können wir dazu übergehen Kommandozeilenargumente zu parsen. Um das zu tun werden wir Elixirs `OptionParser.parse/2` mit der `:switches` Option nutzen, um darauf hinzuweisen, dass unser flag boolean ist:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    args
    |> parse_args
    |> response
    |> IO.puts()
  end

  defp parse_args(args) do
    {opts, word, _} =
      args
      |> OptionParser.parse(switches: [upcase: :boolean])

    {opts, List.to_string(word)}
  end

  defp response({opts, word}) do
    if opts[:upcase], do: String.upcase(word), else: word
  end
end
```

## Erstellen

Sobald wir die Konfiguration unserer Anwendung mit escript abgeschlossen haben ist die Erzeugung einer ausführbaren Datei mit der Hilfe von Mix einfach:

```elixir
$ mix escript.build
```

Let's take it for a spin:

```elixir
$ ./example_app --upcase Hello
HELLO

$ ./example_app Hi
Hi
```

Das wars. Wir haben unsere erste ausführbare Datei in Elixir mit escript erzeugt.
