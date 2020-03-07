---
version: 1.0.2
title: Executáveis
---

Para criar executáveis em Elixir nós utilizaremos escript. Escript produz um executável que pode rodar em qualquer sistema que tenha Erlang instalado.

{% include toc.html %}

## Começando

Para criar um executável com escript há poucas coisas que precisamos fazer: implementar uma função `main/1` e atualizar nosso Mixfile.

Vamos começar criando um módulo que servirá como ponto de entrada para nosso executável, é aí que vamos implementar `main/1`:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    # Do stuff
  end
end
```

A seguir nós precisamos atualizar nosso Mixfile incluindo a opção `:escript` para nosso projeto além de especificar nosso `:main_module`:

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

## Fazendo Parsing dos Argumentos

Com nossa aplicação configurada podemos começar a parsear os argumentos da linha de comando. Para fazer isso vamos utilizar a função `OptionParser.parse/2` do Elixir e a opção `:switches` para indicar que nossa flag é booleana.

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

## Criando o Executável

Quando terminamos de configurar nossa aplicação para usar escript, criar o executável é muito simples usando Mix:

```bash
$ mix escript.build
```

Vamos testar:

```bash
$ ./example_app --upcase Hello
HELLO

$ ./example_app Hi
Hi
```

É isso. Nós fizemos nosso primeiro executável em Elixir usando escript.
