%{
  version: "1.0.1",
  title: "Spustiteľné súbory",
  excerpt: """
  Na to, aby sme mohli vytvoriť spustiteľné súbory v Elixire budeme používať escript. Escript vytvorí spustiteľný súbor, ktorý môže byť spustiteľný na akomkoľvek systéme, kde je nainštalovaný Erlang.
  """
}
---

## Začíname

Predtým, než vytvoríme spustiteľný súbor s pomocou escriptu, musíme implementovať funkciu `main/1` a aktualizovať náš Mixfile.

Začneme vytvorením modulu, ktorý nám bude slúžiť ako vstupná brána nášho spustiteľného súboru. Tu implementujeme `main/1`:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    # Do stuff
  end
end
```

Ďalej potrebujeme aktualizovať náš Mixfile, aby obsahoval možnosť `:escript` pre náš projekt spolu so špecifikovaným hlavným modulom (`:main_module`):

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

## Parsovanie argumentov

S našou vytvorenou aplikáciou môžeme prejsť na parsovanie argumentov z príkazového riadku. Na to použijeme Elixir funkciu `OptionParser.parse/2` s možnosťou `:switches` aby sme označili, že náš flag je boolean:

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

## Vybudovanie

Po dokončení konfigurácie našej aplikácie, tak aby použila escript je vybudovanie spustiteľného súboru hračka s Mixom:

```elixir
$ mix escript.build
```

A teraz našu aplikáciu vyskúšajme:

```elixir
$ ./example_app --upcase Hello
HELLO

$ ./example_app Hi
Hi
```

To je všetko. Vybudovali sme náš prvý spustiteľný súbor v Elixire s pomocou escriptu.
