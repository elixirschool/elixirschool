---
version: 0.9.1
title: Concurrencia
---

Una de las características más llamativas de Elixir es su soporte para concurrencia. Gracias a la Erlang VM (BEAM), la concurrencia en Elixir es más fácil de lo esperado. El modelo de concurrencia se basa en Actores, un proceso contenido que se comunica con otro proceso por medio de paso de mensajes.

En esta lección revisaremos los módulos de concurrencia incluidos en Elixir. En el siguiente capítulo cubriremos los comportamientos de OTP que los implementan.

{% include toc.html %}

## Procesos

Los procesos en la Erlang VM (BEAM) son ligeros y se ejecutan usando todos los CPUs. Pese a que pueden parecer hilos nativos, son más simples y no es raro tener miles de procesos concurrentes en una aplicación de Elixir.

La manera más fácil de crear un nuevo proceso es `spawn`, el cual recibe una función anónima o una función con nombre. Cuando creamos un nuevo proceso se devuelve un _Identificador de Proceso_ o PID, para identificarlo de manera única dentro de nuestra aplicación.

Para comenzar, crearemos un módulo y definiremos una función que queramos ejecutar:

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

Para evaluar la función de manera asíncrona usamos `spawn/3`:

```elixir
iex> spawn(Example, :add, [2, 3])
5
#PID<0.80.0>
```

### Paso de mensajes

Para comunicarse, los procesos se basan en paso de mensajes. Hay dos principales componentes para esto: `send/2` y `receive`. La función `send/2` nos permite enviar mensajes a PID's. Para escuchar utilizamos `receive` para coincidir mensajes. Si no se encuentra una coincidencia, la ejecución continúa ininterrumpida.

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

### Enlace de procesos

Un problema con `spawn` es saber cuando un proceso falla. Para ello necesitamos enlazar nuestros procesos usando `spawn_link`. Dos procesos enlazados recibirán notificaciones de salida uno del otro:

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)
end

iex> spawn(Example, :explode, [])
#PID<0.66.0>

iex> spawn_link(Example, :explode, [])
** (EXIT from #PID<0.57.0>) evaluator process exited with reason: :kaboom
```

A veces no queremos que nuestro proceso enlazado termine el proceso actual. Para ello necesitamos atrapar las salidas. Cuando atrapamos las salidas se recibirán como una tupla en un mensaje: `{:EXIT, from_pid, reason}`.

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

### Monitoreo de procesos

¿Qué se puede hacer si no queremos enlazar dos procesos pero aún así mantenerlos informados? Para ello podemos usar monitoreo de procesos con `spawn_monitor`. Cuando monitoreamos un proceso obtenemos un mensaje si el procesos falla sin terminar nuestro proceso actual y sin necesidad de atrapar las salidas de manera explícita.

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

Los agentes (Agents) son una abstracción de procesos de fondo que mantienen un estado. Podemos accesarlos de otros procesos dentro de nuestra aplicación y nodo. El estado de nuestro agente es el valor de retorno de nuestra función.

```elixir
iex> {:ok, agent} = Agent.start_link(fn -> [1, 2, 3] end)
{:ok, #PID<0.65.0>}

iex> Agent.update(agent, fn (state) -> state ++ [4, 5] end)
:ok

iex> Agent.get(agent, &(&1))
[1, 2, 3, 4, 5]
```

Cuando nombramos un agente lo podemos referenciar por nombre en lugar de su PID:

```elixir
iex> Agent.start_link(fn -> [1, 2, 3] end, name: Numbers)
{:ok, #PID<0.74.0>}

iex> Agent.get(Numbers, &(&1))
[1, 2, 3]
```

## Tareas

Las tareas (Tasks) proveen una manera de ejecutar una función en el fondo y obtener su valor de retorno después. Esto puede ser particularmente útil cuando se manejan operaciones costosas sin bloquear la ejecución de la aplicación.

```elixir
defmodule Example do
  def double(x) do
    :timer.sleep(2000)
    x * 2
  end
end

iex> task = Task.async(Example, :double, [2000])
%Task{pid: #PID<0.111.0>, ref: #Reference<0.0.8.200>}

# Do some work

iex> Task.await(task)
4000
```
