---
version: 1.0.1
title: Comportamentos
---

Aprendemos sobre _Typespecs_ na lição anterior, aqui vamos aprender como exigir que um módulo implemente essas especificações. No Elixir, essa funcionalidade é referenciada como comportamentos.

{% include toc.html %}

## Usos

Às vezes você deseja que módulos compartilhem uma API pública, a solução para isso no Elixir são os comportamentos. Comportamentos desempenham dois papéis primários:

+ Definem um conjunto de funções que devem ser implementadas
+ Verificam se o conjunto foi realmente implementado

Elixir inclui uma série de comportamentos como o GenServer, mas nesta lição vamos focar em criar nossos próprios.

## Definindo um comportamento

Para entender melhor comportamentos, vamos implementar um para um módulo _worker_. Estes _workers_ deverão implementar duas funções: `init/1` e `perform/2`.

A fim de conseguir isso, vamos usar a diretiva `@callback` com uma sintaxe similar ao `@spec`, isso define uma função __necessária__; para macros podemos usar `@macrocallback`. Vamos especificar as funções `init/1` e `perform/2` de nossos _workers_:

```elixir
defmodule Example.Worker do
  @callback init(state :: term) :: {:ok, new_state :: term} | {:error, reason :: term}
  @callback perform(args :: term, state :: term) ::
              {:ok, result :: term, new_state :: term}
              | {:error, reason :: term, new_state :: term}
end
```

Aqui definimos `init/1` como aceitando qualquer valor e retornando uma tupla de `{:ok, state}` ou `{:error, reason}`, esta é uma inicialização bastante padrão. Nossa função `perform/2` receberá alguns argumentos para o _worker_ juntamente com o estado que inicializamos, esperamos `perform/2` retornar `{:ok, result, state}` ou `{:error, reason, state}` de forma muita semelhante aos GenServers.

## Usando comportamentos

Agora que definimos nosso comportamento podemos usá-lo para criar uma variedade de módulos que compartilham a mesma API pública. Adicionar um comportamento no nosso módulo é fácil com o atributo `@behaviour`.

Usando nosso novo comportamento, vamos criar uma tarefa do módulo, que irá baixar um arquivo remoto e salvá-lo localmente:

```elixir
defmodule Example.Downloader do
  @behaviour Example.Worker

  def init(opts), do: {:ok, opts}

  def perform(url, opts) do
    url
    |> HTTPoison.get!()
    |> Map.fetch(:body)
    |> write_file(opts[:path])
    |> respond(opts)
  end

  defp write_file(:error, _), do: {:error, :missing_body}

  defp write_file({:ok, contents}, path) do
    path
    |> Path.expand()
    |> File.write(contents)
  end

  defp respond(:ok, opts), do: {:ok, opts[:path], opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

Ou que tal um _worker_ que comprime um _array_ de arquivos? Isso é possível também:

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

Enquanto o trabalho realizado é diferente, a API pública não é, e qualquer código usando esses módulos pode interagir com elas sabendo que responderão conforme esperado. Isso nos dá a capacidade de criarmos uma série de _workers_, todos realizando tarefas diferentes, mas de acordo com a mesma API pública.

Se acontecer de adicionarmos um comportamento, mas não implementarmos todas as funções necessárias, um _warning_ em tempo de compilação será gerado. Para ver isso em ação vamos modificar o código do nosso `Example.Compressor` removendo a função `init/1`:

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

Agora quando compilamos nosso código devemos ver um _warning_:

```shell
lib/example/compressor.ex:1: warning: undefined behaviour function init/1 (for behaviour Example.Worker)
Compiled lib/example/compressor.ex
```

É isso aí! Agora estamos prontos para construir e compartilhar comportamentos com outros.
