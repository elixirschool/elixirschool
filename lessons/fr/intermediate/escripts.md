%{
  version: "1.0.2",
  title: "Fichier exécutable",
  excerpt: """
  Pour construire un fichier exécutable avec Elixir, nous utilisons escript.
  Escript produit un fichier qui peut être exécuté sur n'importe quel système disposant d'une installation Erlang.
  """
}
---

## Démarrage

Pour créer un fichier exécutable avec *escript*, peu de choses est requis : nous devons implémenter une fonction `main/1` et mettre à jour le *Mixfile*.

Créons un module. Il doit contenir une fonction `main/1` :

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    # Do stuff
  end
end
```

Ensuite, nous devons ajouter l'option `:escript` dans *Mixfile*, pour indiquer le point d'entrée du fichier exécutable (via `:main_module`) :

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

## Analyse des arguments

Le fichier peut être exécuté avec des arguments supplémentaires. Pour analyser ces arguments, nous pouvons utiliser `OptionParser.parse/2`.

Dans l'exemple ci-suit, nous utilisons l'option `:switches` pour indiquer que l'argument que nous attendons, `--upcase`, est un booléen (`true` s'il est trouvé, `false` sinon).

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

## Construction du fichier exécutable

Une fois l'application configurée avec *escript*, nous pouvons construire le fichier exécutable avec `mix` :

```bash
mix escript.build
```

Reste à l'utiliser :

```bash
$ ./example_app --upcase Hello
HELLO

$ ./example_app Hi
Hi
```
