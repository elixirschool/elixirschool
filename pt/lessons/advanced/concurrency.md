---
version: 1.1.1
title: Concorrência
---

Um dos pontos ofertados pelo Elixir é o suporte a concorrência. Graças à Erlang VM (BEAM), concorrência no Elixir é mais fácil do que esperamos. O modelo de concorrência depende de Atores, um processo contido (isolado) que se comunica com outros processos por meio de passagem de mensagem.

Nesta aula nós veremos os módulos de concorrência que vêm com Elixir. No próximo capítulo, cobriremos os comportamentos OTP que os implementam.

{% include toc.html %}

## Processos

Processos no Erlang VM são leves e executam em todas as CPUs. Enquanto eles podem parecer como threads nativas, eles são bastantes simples e não é incomum ter milhares de processos concorrentes em uma aplicação Elixir.

A forma mais fácil para criar um novo processo é o `spawn`, que pode receber tanto uma função nomeada quanto anônima. Quando criamos um novo processo ele retorna um _Process Identifier_ ou PID, para exclusivamente identificá-lo dentro de nossa aplicação.

Para iniciar criaremos um módulo e definiremos uma função que gostaríamos de executar:

```elixir
defmodule Example do
  def add(a, b) do
    IO.puts(a + b)
  end
end

iex> Example.add(2, 3)
5
:ok
```

Para executar a função de forma assíncrona usamos `spawn/3`:

```elixir
iex> spawn(Example, :add, [2, 3])
5
#PID<0.80.0>
```

### Passagem de mensagem

Para comunicar-se, os processos dependem de passagem de mensagens. Há dois componentes principais para isso: `send/2` e `receive`. A função `send/2` nos permite enviar mensagens para PIDs. Para recebê-las, usamos a função `receive` com pattern matching para selecionar as mensagens. Se nenhum padrão coincidir com a mensagem recebida, a execução continua ininterrupta.

```elixir
defmodule Example do
  def listen do
    receive do
      {:ok, "hello"} -> IO.puts("World")
    end

    listen()
  end
end

iex> pid = spawn(Example, :listen, [])
#PID<0.108.0>

iex> send pid, {:ok, "hello"}
World
{:ok, "hello"}

iex> send pid, :ok
:ok
```

Você pode notar que a função `listen/0` é recursiva, isso permite que nosso processo receba múltiplas mensagens. Sem recursão nosso processo teria saído depois de receber a primeira mensagem.

### Vinculando Processos

Um problema com `spawn` é saber quando um processo falha. Para isso, precisamos vincular nossos processos usando `spawn_link`. Dois processos vinculados receberão notificações de saída um do outro:

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)
end

iex> spawn(Example, :explode, [])
#PID<0.66.0>

iex> spawn_link(Example, :explode, [])
** (EXIT from #PID<0.57.0>) evaluator process exited with reason: :kaboom
```

Em determinados momentos não queremos que nosso processo vinculado falhe o atual. Para isso nós precisamos interceptar as saídas usando `Process.flag/2`. Ela usa a função do erlang [process_flag/2](http://erlang.org/doc/man/erlang.html#process_flag-2) para a flag `trap_exit`. Quando interceptando saídas (`trap_exit` é definida como `true`), sinais de saída são recebidos como uma tupla de mensagem: `{:EXIT, from_pid, reason}`.

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)

  def run do
    Process.flag(:trap_exit, true)
    spawn_link(Example, :explode, [])

    receive do
      {:EXIT, _from_pid, reason} -> IO.puts("Exit reason: #{reason}")
    end
  end
end

iex> Example.run
Exit reason: kaboom
:ok
```

### Monitorando processos

E se não queremos vincular dois processos, mas continuar a sermos informados? Para isso, podemos usar o monitoramento de processos com `spawn_monitor`. Quando monitoramos um processo, nós recebemos uma mensagem informando se o processo falhou, sem afetar nosso processo atual nem necessitar explicitamente interceptar a saída.

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)

  def run do
    {pid, ref} = spawn_monitor(Example, :explode, [])

    receive do
      {:DOWN, _ref, :process, _from_pid, reason} -> IO.puts("Exit reason: #{reason}")
    end
  end
end

iex> Example.run
Exit reason: kaboom
:ok
```

## Agentes

Agentes são uma abstração acerca de processos em segundo plano que mantêm estado. Podemos acessá-los de outros processos dentro de nossa aplicação ou nó. O estado do nosso Agente é definido como valor de retorno de nossa função:

```elixir
iex> {:ok, agent} = Agent.start_link(fn -> [1, 2, 3] end)
{:ok, #PID<0.65.0>}

iex> Agent.update(agent, fn (state) -> state ++ [4, 5] end)
:ok

iex> Agent.get(agent, &(&1))
[1, 2, 3, 4, 5]
```

Quando nomeamos um Agente podemos referenciar seu nome ao invés de seu PID:

```elixir
iex> Agent.start_link(fn -> [1, 2, 3] end, name: Numbers)
{:ok, #PID<0.74.0>}

iex> Agent.get(Numbers, &(&1))
[1, 2, 3]
```

## Tarefas

Tarefas fornecem uma forma para executar uma função em segundo plano e posteriormente recuperar seu valor. Elas podem ser particularmente úteis ao manusear operações custosas, sem bloquear a execução do aplicativo.

```elixir
defmodule Example do
  def double(x) do
    :timer.sleep(2000)
    x * 2
  end
end

iex> task = Task.async(Example, :double, [2000])
%Task{
  owner: #PID<0.105.0>,
  pid: #PID<0.114.0>,
  ref: #Reference<0.2418076177.4129030147.64217>
}

# Realizar algum trabalho

iex> Task.await(task)
4000
```
