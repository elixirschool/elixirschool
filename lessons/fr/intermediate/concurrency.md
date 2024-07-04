%{
  version: "1.1.1",
  title: "Concurrence",
  excerpt: """
  Une caractéristique phare de Elixir est son support de la concurrence.
  Grâce à la machine virtuelle de Erlang, BEAM, la programmation concurrente en Elixir est aisée.
  Le modèle de concurrence repose sur des Acteurs, c'est-à-dire des processus qui communiquent avec d'autres processus en échangeant des messages.
  
  Dans cette lesson, nous passons en revue les modules d'Elixir dédiés à la programmation concurrente. Nous aborderons dans les chapitres suivants OTP, une plateforme qui en tire parti.
  """
}
---

## Processus

Les processus dans la machine virtuel de Erlang, *BEAM*, sont légers, et ils utilisent tous les cœurs du *CPU*.
Bien qu'ils s'apparentent à des fils d'exécutions (en anglais : *Threads*) natifs, ils sont en réalité bien plus simples, et il n'est pas rare qu'une application Elixir compte des milliers de processus en parallèle.

Le moyen le plus simple de créer un processus est la fonction `spawn` ; elle lance une fonction, nommée ou anonyme, en parallèle du fil d'exécution principal. Cette fonction retourne l'identifiant du processus qu'elle crée, ou *PID* (de l'anglais : *Process IDentifier*), qui permet de l'identifier dans l'application.

À titre d'exemple, créons un module avec une fonction :

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

Pour évaluer cette fonction de manière asynchrone, nous utilisons `spawn\3` :

```elixir
iex> spawn(Example, :add, [2, 3])
5
#PID<0.80.0>
```

### Communication par messages

Pour communiquer, les processus échangent des messages. 

Cela repose sur deux composants : `send/2` et `receive`. La fonction `send/2` permet d'envoyer un message à un processus en utilisant son *PID*. Pour écouter les messages, nous utilisons `receive` ; s'il n'y en a pas encore, le processus s'interrompt en attendant le prochain message correspondant à l'une des clauses.

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

Veuillez noter que `listen/0` est récursive : cela permet au processus de traiter plusieurs messages. Sans récursion, le processus se serait achevé après avoir traité le premier message.

### Liaison entre processus

Un problème avec `spawn` est qu'il n'est pas évident de savoir quand un processus s'interrompt. Pour cela, nous avons besoin de relier les processus entre avec `spawn_link`. Deux processus liés reçoivent des notifications d'extinction de l'un et de l'autre.

Par exemple :

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)
end

iex> spawn(Example, :explode, [])
#PID<0.66.0>

iex> spawn_link(Example, :explode, [])
** (EXIT from #PID<0.57.0>) evaluator process exited with reason: :kaboom
```

Parfois, nous ne voulons pas qu'un processus s'interrompt en même temps que celui auquel il est lié. Pour cela, nous devons *piéger* l'ordre d'extinction avec `Process.flag/2`. Cela utilise la fonction [process_flag/2](http://erlang.org/doc/man/erlang.html#process_flag-2) d'Erlang pour le *flag* `trap_exit`. Quand l'ordre d'extinction est piégé (c'est-à-dire que le *flag* `trap_exit` a pour valeur `true`), le signal d'extinction est recy comme un tuple : `{:EXIT, from_pid, reason}`.

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

### Surveillance d'un processus

Comment faire pour qu'un processus soit informé de l'état d'un autre processus sans pour autant les lier ? Nous pouvons utiliser `spawn_monitor`. Cela permet à un processus de surveiller un autre processus, et de recevoir un message quand il s'éteint, sans recevoir lui-même l'ordre de s'éteindre.

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)

  def run do
    spawn_monitor(Example, :explode, [])

    receive do
      {:DOWN, _ref, :process, _from_pid, reason} -> IO.puts("Exit reason: #{reason}")
    end
  end
end

iex> Example.run
Exit reason: kaboom
:ok
```

## Agents

Les agents sont une abstraction de processus permettant de maintenir un état. Nous pouvons accéder au contenu d'un agent depuis d'autres processus.

Nous initialisons et mettons à jour l'état d'un agent comme suit :

```elixir
iex> {:ok, agent} = Agent.start_link(fn -> [1, 2, 3] end)
{:ok, #PID<0.65.0>}

iex> Agent.update(agent, fn (state) -> state ++ [4, 5] end)
:ok

iex> Agent.get(agent, &(&1))
[1, 2, 3, 4, 5]
```

Nous pouvons donner un nom à un agent. Ce nom peut remplacer son *PID* :

```elixir
iex> Agent.start_link(fn -> [1, 2, 3] end, name: Numbers)
{:ok, #PID<0.74.0>}

iex> Agent.get(Numbers, &(&1))
[1, 2, 3]
```

## Tâches

Une tâche est une fonction exécutée en tâche de fond et dont la valeur de retour est consultable ultérieurement. Cela peut être utile pour traiter des opérations longues sans bloquer l'application.

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

# Do some work

iex> Task.await(task)
4000
```
