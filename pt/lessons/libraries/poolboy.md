---
version: 0.9.1
title: Poolboy
---

Você pode facilmente esgotar os recursos do seu sistema se você permitir que os processos concorrentes sejam executados arbitrariamente. Poolboy impede que aconteça uma sobrecarga, criando um pool de gerenciadores para limitar o número de processos simultâneos.

{% include toc.html %}

## Por quê usar Poolboy?

Vamos pensar em um exemplo específico por um momento. Você tem a tarefa de criar um aplicativo para salvar informações de perfil de usuário no banco de dados. Se você criou um processo para cada registro de usuário, você criaria um número ilimitado de conexões. Em algum momento, essas conexões começam a competir pelos recursos limitados disponíveis em seu servidor de banco de dados. Eventualmente seu aplicativo obtém tempos limite e várias exceções devido à sobrecarga dessa contenção.

A solução para esse problema é usar um conjunto de gerenciadores (processos) para limitar o número de conexões em vez de criar um processo para cada registro de usuário. Então você pode facilmente evitar ficar sem seus recursos do sistema.

É aí que entra Poolboy. Ele cria um pool de serviços gerenciados por um `Supervisor` sem nenhum esforço de sua parte para fazê-lo manualmente. Há muitas bibliotecas que usam Poolboy por baixo dos panos. Por exemplo, o pool de conexões do `postgrex` *(que é alavancado pelo Ecto ao usar o PostgreSQL)* e o `redis_poolex` *(Redis connection pool)* são algumas bibliotecas populares que usam o Poolboy.

## Instalação

A instalação é uma brisa com o mix. Tudo o que precisamos fazer é adicionar Poolboy como uma dependência no nosso `mix.exs`.

Primeiro vamos criar um aplicativo:

```bash
$ mix new poolboy_app --sup
$ mix deps.get
```

Adicione o Poolboy como uma dependência do nosso `mix.exs`.

```elixir
defp deps do
  [{:poolboy, "~> 1.5.1"}]
end
```

E adicione Poolboy na nossa aplicação OTP:

```elixir
def application do
  [applications: [:logger, :poolboy]]
end
```

## As opções de configuração

Precisamos saber um pouco sobre as várias opções de configuração para começar a usar o Poolboy.

* `:name` - o nome do pool. O escopo pode ser `:local`, `:global`, ou `:via`.
* `:worker_module` - o módulo que representa o gerenciador.
* `:size` - tamanho máximo de pool.
* `:max_overflow` - número máximo de gerenciadores criados se o pool estiver vazio. (opcional)
* `:strategy` - `:lifo` ou `:fifo`, determina se os gerenciadores registados devem ser colocados primeiro ou último na linha dos gerenciadores disponíveis. O padrão é `:lifo`. (opcional)

## Configurando o Poolboy

Para este exemplo, criaremos um pool de gerenciadores responsáveis pelo processamento de pedidos para calcular a raiz quadrada de um número. Vamos manter o exemplo simples para que possamos manter nosso foco no Poolboy.

Vamos definir as opções de configuração do Poolboy e adicioná-lo como um gerenciador filho como parte do nosso início do aplicativo.

```elixir
defmodule PoolboyApp do
  use Application

  defp poolboy_config do
    [{:name, {:local, :worker}}, {:worker_module, Worker}, {:size, 5}, {:max_overflow, 2}]
  end

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      :poolboy.child_spec(:worker, poolboy_config, [])
    ]

    opts = [strategy: :one_for_one, name: PoolboyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

A primeira coisa que definimos são as opções de configuração para o pool. Atribuímos um pool único `:name`, definimos o `:scope` para local e o `:size` do pool para ter um total de cinco gerenciadores. Além disso, no caso de todos os gerenciadores estarem sob carga, solicitamos que crie mais dois gerenciadores para ajudar com a carga usando a opção `:max_overflow`. *(Os gerenciadores de `overflow` vão embora uma vez que terminam seu trabalho.)*

Em seguida, adicionamos a função `poolboy.child_spec/3` à matriz de filhos para que o pool de gerenciadores seja iniciado quando o aplicativo for iniciado.

A função `child_spec/3` leva três argumentos; Nome do pool, configuração do pool e o terceiro argumento que é passado para a função `worker.start_link`. No nosso caso, é apenas uma lista vazia.

## Criando um Gerenciador
O módulo de gerenciamento será um GenServer simples calculando a raiz quadrada de um número, dormindo por um segundo e imprimindo o pid do gerenciador:

```elixir
defmodule Worker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, [])
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_call({:square_root, x}, _from, state) do
    IO.puts("process #{inspect(self)} calculating square root of #{x}")
    :timer.sleep(1000)
    {:reply, :math.sqrt(x), state}
  end
end
```

## Usando Poolboy

Agora que temos o nosso `Worker`, podemos testar o Poolboy. Vamos criar um módulo simples que cria processos simultâneos usando a função `:poolboy.transaction`:

```elixir
defmodule Test do
  @timeout 60000

  def start do
    tasks =
      Enum.map(1..20, fn i ->
        Task.async(fn ->
          :poolboy.transaction(:worker, &GenServer.call(&1, {:square_root, i}), @timeout)
        end)
      end)

    Enum.each(tasks, fn task -> IO.puts(Task.await(task, @timeout)) end)
  end
end
```
Se você não tiver gerenciadores de pool disponíveis, Poolboy chegará ao tempo limite após o período de tempo limite padrão (cinco segundos) e não aceitará nenhuma nova solicitação. Em nosso exemplo, aumentamos o tempo limite padrão para um minuto para demonstrar como podemos alterar o valor de tempo limite padrão.

Mesmo que estamos tentando criar vários processos *(total de vinte no exemplo acima)* a função `:poolboy.transaction` limitará o total de processos criados a cinco *(mais dois gerenciadores de estouro, se necessário)* como definimos em nossa configuração. Todos os pedidos serão tratados pelo grupo de gerenciadores em vez de criar um novo processo para cada pedido.