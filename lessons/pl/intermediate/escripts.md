%{
  version: "0.9.1",
  title: "Uruchamianie programów",
  excerpt: """
  Do stworzenia pliku wykonywalnego w Elixirze służy escript. Escript generuje plik wykonywalny, który może zostać uruchomiony na każdym komputerze, na którym zainstalowano Erlanga.
  """
}
---

## Na początek

By utworzyć plik, który można uruchomić, za pomocą escriptu musimy zrobić tylko kilka drobnych rzeczy: zaimplementować funkcję `main/1` oraz zaktualizować konfigurację mixa.

Na początek stwórzmy moduł, który będzie punktem startowym programu. W nim zaimplementujemy funkcję `main/1`:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    # Do stuff
  end
end
```

Następnie w pliku mixa dodajemy sekcję `:escript`, która zawiera opcję `:main_module`:

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

## Parsowanie argumentów

Do naszej aplikacji możemy przekazać pewne argumenty z linii poleceń. By je sparsować, użyjemy Elixirowego modułu `OptionParser.parse/2` z opcją `:switches`, która zawiera informacje, iż nasza flaga jest typu logicznego:

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

  defp response({opts, "Hello"}), do: response({opts, "World"})

  defp response({opts, word}) do
    if opts[:upcase], do: String.upcase(word), else: word
  end
end
```

## Tworzenie plików wykonywalnych

Jak już skonfigurujemy aplikację by używała escript, stworzenie pliku wykonywalnego z Mixem jest banalne:

```elixir
$ mix escript.build
```

Zobaczmy jak to działa:

```elixir
$ ./example_app --upcase Hello
WORLD

$ ./example_app Hi
Hi
```
I to wszystko! Właśnie stworzyliśmy nasz pierwszy program z użyciem escriptu.  
