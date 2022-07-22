%{
  version: "1.0.2",
  title: "Uruchamianie programów",
  excerpt: """
  Do stworzenia pliku wykonywalnego w Elixirze służy escript.
  Escript generuje plik wykonywalny, który może zostać uruchomiony na każdym komputerze z zainstalowanym Erlangiem.
  """
}
---

## Na początek

Do utworzenia pliku, który można uruchomić za pomocą escriptu, potrzebujemy zrobić tylko kilka drobnych rzeczy: zaimplementować funkcję `main/1` oraz zaktualizować konfigurację Mixa.

Zaczniemy od stworzenia modułu, który będzie punktem startowym programu.
To w nim zaimplementujemy funkcję `main/1`:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    # Rób swoje rzeczy
  end
end
```

Następnie potrzebujemy zaktualizować nasz Mixfile, by zawierał opcję `:escript` oraz wskazywał główny moduł — `:main_module`:

```elixir
defmodule ExampleApp.Mixproject do
  def project do
    [app: :example_app, version: "0.0.1", escript: escript()]
  end

  defp escript do
    [main_module: ExampleApp.CLI]
  end
end
```

## Parsowanie argumentów

Kiedy nasza aplikacja jest już skonfigurowana, możemy przejść do przetwarzania argumentów z wiersza poleceń.
By to zrobić, użyjemy Elixirowego modułu `OptionParser.parse/2` z opcją `:switches`, by wskazać, że nasza flaga jest zmienną typu logicznego:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    args
    |> parse_args()
    |> response()
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

## Budowanie plików wykonywalnych

Kiedy już skonfigurujemy aplikację tak, by używała escriptu, stworzenie pliku wykonywalnego z Mixem jest banalne:

```bash
$ mix escript.build
```

Zobaczmy jak to działa:

```bash
$ ./example_app --upcase Hello
HELLO

$ ./example_app Hi
Hi
```

I to wszystko!
Właśnie stworzyliśmy nasz pierwszy program z użyciem escriptu.
