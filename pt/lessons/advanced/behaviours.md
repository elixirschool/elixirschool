---
version: 1.0.0
layout: page
title: Comportamentos
category: advanced
order: 10
lang: pt
---

Nós aprendemos sobre Tipos e Especificações na lição passada, agora vamos aprender como requisitamos um módulo para implementar essas especificações. No Elixir, essa funcionalidade é referida como comportamentos.

{% include toc.html %}

## Utilizações

Algumas vezes você quer que módulos sejam compartilhados com uma API pública, a solução para isso em Elixir são os comportamentos. Comportamentos desempenham dois papéis principais:

+ Definindo um conjunto de funções que podem ser implementadas
+ Verificando se esse conjunto foi realmente implementado

Elixir inclui um número de comportamentos tal como GenServer, mas nessa lição, vamos nos concentrar em criar nossos próprios comportamentos.

## Definindo um comportamento

Para entendermos melhor comportamentos, vamos implementar um para um módulo de trabalho. Espera-se que esses módulos de trabalho implementem duas funções: `init/1` e `perform/2`.

Nessa ordem, vamos utilizar a diretiva `@callback` com uma sintaxe similar ao `@spec`, isto define um método __required__; para macros podemos utilizar `@macrocallback`. Vamos especificar os métodos `init/1` e `perform/2` para nossos trabalhos:

```elixir
defmodule Example.Worker do
  @callback init(state :: term) :: {:ok, new_state :: term} | {:error, reason :: term}
  @callback perform(args :: term, state :: term) :: {:ok, result :: term, new_state :: term} | {:error, reason :: term, new_state :: term}
end
```

Aqui definimos `init/1` para aceitar qualquer valor e retornar uma tupla de `{:ok, state}` ou `{:error, reason}`, esta é uma inicialização bastante padrão. Nosso método `perform/2` irá receber alguns argumentos para o trabalho junto com o estado que inicializamos, esperamos `perform/2` retornar `{:ok, result, state}` ou `{:error, reason, state}` muito parecido com GenServers.

## Usando comportamentos

Agora que definimos nosso comportamento, podemos utiliza-lo para criar uma variedade de módulos que serão compartilhados na mesma API pública. Adicionar comportamentos em nosso módulo é fácil com o atributo `@behaviour`.

Utilizando nosso novo comportamento, vamos criar um módulo que terá a tarefa de realizar o download de um arquivo remoto e salva-lo localmente:

```elixir
defmodule Example.Downloader do
  @behaviour Example.Worker

  def init(opts), do: {:ok, opts}

  def perform(url, opts) do
    url
    |> HTTPoison.get!
    |> Map.fetch(:body)
    |> write_file(opts[:path])
    |> respond(opts)
  end

  defp write_file(:error, _), do: {:error, :missing_body}
  defp write_file({:ok, contents}, path) do
    path
    |> Path.expand
    |> File.write(contents)
  end

  defp respond(:ok, opts), do: {:ok, opts[:path], opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

Um trabalho pode comprimir um array de arquivos?  Isso também é possível:

```elixir
defmodule Example.Compressor do
  @behaviour Example.Worker

  def init(opts), do: {:ok, opts}

  def perform(payload, opts) do
    payload
    |> compress
    |> respond(opts)
  end

  defp compress({name, files}), do: :zip.create(name, files)

  defp respond({:ok, path}, opts), do: {:ok, path, opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

Enquanto o trabalho realizado é diferente, a parte pública da API não é, e qualquer código alavancado nesses módulos, podem interagir com eles, sabendo que eles vão responder como esperado. Isso nos dá a capacidade para criar vários trabalhos, todos desempenhando tarefas diferentes, mas em conformidade com a mesma API pública.

Se acontecer de adicionar um comportamento, mas falhar para implementar todas as funções necessárias, um aviso em tempo de compilação será mostrado. Para ver isso em funcionamento, vamos modificar nosso código `Example.Compressor` para remover a função `init/1`:

```elixir
defmodule Example.Compressor do
  @behaviour Example.Worker

  def perform(payload, opts) do
    payload
    |> compress
    |> respond(opts)
  end

  defp compress({name, files}), do: :zip.create(name, files)

  defp respond({:ok, path}, opts), do: {:ok, path, opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

Agora, quando compilamos nosso código, podemos ver a informação:

```shell
lib/example/compressor.ex:1: warning: undefined behaviour function init/1 (for behaviour Example.Worker)
Compiled lib/example/compressor.ex
```

É isso ! Agora estamos pronto para criar e compartilhar comportamentos com outros.
