---
version: 0.9.1
title: Concorrência
---

Um dos pontos ofertados pelo Elixir é o suporte a concorrência. Graças à Erlang VM (BEAM), concorrência no Elixir é mais fácil do que esperamos. O modelo de concorrência replica sobre Atores, um processo constante que se comunica com outros processos através de passagem de mensagem. 

Nesta aula nós veremos os módulos de concorrência que vêm com Elixir. No próximo capítulo nós cobriremos os comportamentos OTP que os implementam.

{% include toc.html %}

## Processos

Processos no Erlang VM são leves e executam em todas as CPUs. Enquanto eles podem parecer como threads nativas, eles são bastantes simples e não é incomum ter milhares de processos concorrentes em uma aplicação Elixir.

A forma mais fácil para criar um novo processo é o `spawn` na qual tem tanto uma função nomeada ou anônima. Quando criamos um novo processo ele retorna um _Process Identifier_ ou PID, para exclusivamente identificá-lo dentro de nossa aplicação.

Para iniciar criaremos um módulo e definiremos uma função que gostariamos de executar:

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

Para avaliar a função de forma assíncrona usamos `spawn/3`:

```elixir
iex> spawn(Example, :add, [2, 3])
5
#PID<0.80.0>
```

### Passagem de mensagem

Para comunicar-se, os processos dependem de passagem de mensagens. Há dois componentes principais para isso: `send/2` e` receive`. A função `send/2` nos permite enviar mensagens para PIDs. Para ouvir usamos `receive` para combinar as mensagens, se nenhuma correspondência for encontrada a execução continua ininterrupta.

```elixir
defmodule Example do
  def listen do
    receive do
      {:ok, "hello"} -> IO.puts("World")
    end
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

Derterminados momentos não queremos que nosso processo vinculado falhe o atual. Para isso, precisamos interceptar as saídas. Quando saídas são interceptadas elas serão recebidas como uma mensagem de conjunto de variáveis: `{:EXIT, from_pid, reason}`. 

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)

  def run do
    Process.flag(:trap_exit, true)
    spawn_link(Example, :explode, [])

    receive do
      {:EXIT, from_pid, reason} -> IO.puts("Exit reason: #{reason}")
    end
  end
end

iex> Example.run
Exit reason: kaboom
:ok
```

### Monitorando processos

E se não queremos vincular dois processos, mas continuar a ser informado? Para isso, podemos usar o monitoramento de processos com `spawn_monitor`. Quando monitoramos um processo, pegamos a mensagem, se o processo falha não afetando nosso processo atual ou não necessitando explicitamente interceptar a saída.

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)

  def run do
    {pid, ref} = spawn_monitor(Example, :explode, [])

    receive do
      {:DOWN, ref, :process, from_pid, reason} -> IO.puts("Exit reason: #{reason}")
    end
  end
end

iex> Example.run
Exit reason: kaboom
:ok
```

## Agentes

Agentes são uma abstração acerca de processos em segundo plano em estado de manutenção. Podemos acessa-los de outros processos dentro de nossa aplicação ou nó. O estado do nosso Agente é definido como valor de retorno de nossa função: 

```elixir
iex> {:ok, agent} = Agent.start_link(fn -> [1, 2, 3] end)
{:ok, #PID<0.65.0>}

iex> Agent.update(agent, fn (state) -> state ++ [4, 5] end)
:ok

iex> Agent.get(agent, &(&1))
[1, 2, 3, 4, 5]
```

Quando nomeamos um Agente podemos referi-lo ao invés de seu PID:

```elixir
iex> Agent.start_link(fn -> [1, 2, 3] end, name: Numbers)
{:ok, #PID<0.74.0>}

iex> Agent.get(Numbers, &(&1))
[1, 2, 3]
```

## Tarefas

Tarefas fornecem uma forma para executar uma função em segundo plano e posteriormente recuperar seu valor. Elas podem ser particularmente útil ao manusear operações dispendiosa, sem bloquear a execução do aplicativo.

```elixir
defmodule Example do
  def double(x) do
    :timer.sleep(2000)
    x * 2
  end
end

iex> task = Task.async(Example, :double, [2000])
%Task{pid: #PID<0.111.0>, ref: #Reference<0.0.8.200>}

# Realizar algum trabalho

iex> Task.await(task)
4000
```
