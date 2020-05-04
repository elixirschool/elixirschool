---
version: 1.2.0
title: Poolboy
---

Você pode esgotar facilmente os recursos do sistema se não limitar o número máximo de processos simultâneos que seu programa pode gerar.
[Poolboy](https://github.com/devinus/poolboy) é uma biblioteca de pool genérica leve e amplamente usada para Erlang que resolve esse problema.

{% include toc.html %}

## Por quê usar Poolboy?

Vamos pensar em um exemplo específico por um momento.
Você tem a tarefa de criar um aplicativo para salvar informações de perfil de usuário no banco de dados.
Se você criou um processo para cada registro de usuário, você criaria um número ilimitado de conexões.
Em algum momento, essas conexões começam a competir pelos recursos limitados disponíveis em seu servidor de banco de dados.
Eventualmente seu aplicativo obtém tempos limite e várias exceções devido à sobrecarga dessa contenção.

A solução para esse problema é usar um conjunto de gerenciadores (processos) para limitar o número de conexões em vez de criar um processo para cada registro de usuário.
Então você pode facilmente evitar ficar sem seus recursos do sistema.

É aí que entra Poolboy.
Ele cria um pool de serviços gerenciados por um `Supervisor` sem nenhum esforço de sua parte para fazê-lo manualmente.
Há muitas bibliotecas que usam Poolboy por baixo dos panos.
Por exemplo, o pool de conexões do `postgrex` *(que é alavancado pelo Ecto ao usar o PostgreSQL)* e o `redis_poolex` *(Redis connection pool)* são algumas bibliotecas populares que usam o Poolboy.

## Instalação

A instalação é simples com o mix.
Tudo o que precisamos fazer é adicionar Poolboy como uma dependência no nosso `mix.exs`.

Primeiro vamos criar uma aplicação:

```shell
$ mix new poolboy_app --sup
```

Adicione o Poolboy como uma dependência do nosso `mix.exs`.

```elixir
defp deps do
  [{:poolboy, "~> 1.5.1"}]
end
```

Então baixe as dependências, incluindo o Poolboy.
```shell
$ mix deps.get
```

## As opções de configuração

Precisamos saber um pouco sobre as várias opções de configuração para começar a usar o Poolboy.

* `:name` - o nome do pool.
O escopo pode ser `:local`, `:global`, ou `:via`.
* `:worker_module` - o módulo que representa o gerenciador.
* `:size` - tamanho máximo de pool.
* `:max_overflow` - número máximo de gerenciadores criados se o pool estiver vazio.
(opcional)
* `:strategy` - `:lifo` ou `:fifo`, determina se os gerenciadores registados devem ser colocados primeiro ou último na linha dos gerenciadores disponíveis.
O padrão é `:lifo`.
(opcional)

## Configurando o Poolboy

Para este exemplo, criaremos um pool de gerenciadores responsáveis pelo processamento de pedidos para calcular a raiz quadrada de um número.
Vamos manter o exemplo simples para que possamos manter nosso foco no Poolboy.

Vamos definir as opções de configuração do Poolboy e adicioná-lo como um gerenciador filho como parte do nosso início do aplicativo.
Edite `lib/poolboy_app/application.ex`:

```elixir
defmodule PoolboyApp.Application do
  @moduledoc false

  use Application

  defp poolboy_config do
    [
      name: {:local, :worker},
      worker_module: PoolboyApp.Worker,
      size: 5,
      max_overflow: 2
    ]
  end

  def start(_type, _args) do
    children = [
      :poolboy.child_spec(:worker, poolboy_config())
    ]

    opts = [strategy: :one_for_one, name: PoolboyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

A primeira coisa que definimos são as opções de configuração para o pool.
Nós nomeamos nosso pool `:worker` e definimos o `:scope` para `:local`.
Então nós designamos o módulo `PoolboyApp.Worker` como o `:worker_module` que esse pool deve usar.
Nós também definimos o `:size` do pool para um total de `5` gerenciadores.
Também, caso todos os gerenciadores estejam sob carga, nós dizemos para ele criar mais `2` gerenciadores para ajudar na carga usando a opção `:max_overflow`.
*(Os gerenciadores de `overflow` vão embora uma vez que terminam seu trabalho.)*

Em seguida, adicionamos a função `:poolboy.child_spec/2` à matriz de filhos para que o pool de gerenciadores seja iniciado quando a aplicação for iniciada.
Ele recebe dois argumentos: o nome do pool e a configuração do pool.

## Criando um Gerenciador
O módulo de gerenciamento será um `GenServer` simples calculando a raiz quadrada de um número, dormindo por um segundo e imprimindo o pid do gerenciador.
Crie `lib/poolboy_app/worker.ex`:

```elixir
defmodule PoolboyApp.Worker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_call({:square_root, x}, _from, state) do
    IO.puts("process #{inspect(self())} calculating square root of #{x}")
    Process.sleep(1000)
    {:reply, :math.sqrt(x), state}
  end
end
```

## Usando Poolboy

Agora que temos o nosso `PoolboyApp.Worker`, podemos testar o Poolboy.
Vamos criar um módulo simples que cria processos simultâneos usando o Poolboy.
`:poolboy.transaction/3` é a função que usamos para interagir com o poll de gerenciadores.
Crie `lib/poolboy_app/test.ex`:

```elixir
defmodule PoolboyApp.Test do
  @timeout 60000

  def start do
    1..20
    |> Enum.map(fn i -> async_call_square_root(i) end)
    |> Enum.each(fn task -> await_and_inspect(task) end)
  end

  defp async_call_square_root(i) do
    Task.async(fn ->
      :poolboy.transaction(
        :worker,
        fn pid -> GenServer.call(pid, {:square_root, i}) end,
        @timeout
      )
    end)
  end

  defp await_and_inspect(task), do: task |> Task.await(@timeout) |> IO.inspect()
end
```

Execute a função de teste para ver o resultado.

```shell
$ iex -S mix
```

```elixir
iex> PoolboyApp.Test.start()
process #PID<0.182.0> calculating square root of 7
process #PID<0.181.0> calculating square root of 6
process #PID<0.157.0> calculating square root of 2
process #PID<0.155.0> calculating square root of 4
process #PID<0.154.0> calculating square root of 5
process #PID<0.158.0> calculating square root of 1
process #PID<0.156.0> calculating square root of 3
...
```

Se você não tiver gerenciadores de pool disponíveis, Poolboy chegará ao tempo limite após o período de tempo limite padrão (cinco segundos) e não aceitará nenhuma nova solicitação.
Em nosso exemplo, aumentamos o tempo limite padrão para um minuto para demonstrar como podemos alterar o valor de tempo limite padrão.
No caso desse app, você pode observar o erro se você mudar o `@timeout` para menos de 1000.

Mesmo que estamos tentando criar vários processos *(total de vinte no exemplo acima)* a função `:poolboy.transaction/3` limitará o total de processos criados a cinco *(mais dois gerenciadores de estouro, se necessário)* como definimos em nossa configuração.
Todos os pedidos serão tratados pelo grupo de gerenciadores em vez de criar um novo processo para cada pedido.
