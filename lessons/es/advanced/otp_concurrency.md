%{
  version: "1.0.3",
  title: "Concurrencia en OTP",
  excerpt: """
  Hemos visto las abstracciones de Elixir para manejar concurrencia pero a veces necesitamos mayor control, para eso podemos usar los comportamientos OTP sobre los que está construido Elixir.

En este lección nos enfocaremos en el componente mas grande: GenServers
  """
}
---

## GenServer

Un servidor OTP es un módulo con el comportamiento GenServer que implementa un conjunto de *callbacks*. En el nivel mas básico un GenServer es un proceso único que ejecuta un ciclo que maneja un mensaje por iteración pasando a lo largo un estado actualizado.

Para demostrar el API de GenServer implementaremos una cola básica para almacenar y recuperar valores.

Para empezar nuestro GenServer necesitamos empezar y manejar la iniciación. En la mayoría de los casos vamos a querer enlazar un proceso entonces usamos `GenServer.start_link/3`. Cuando iniciamos el GenServer le pasamos argumentos iniciales y un conjunto de opciones. Los argumentos serán pasados a `GenServer.init/1` el cual establece el estado inicial. En nuestro ejemplo los argumentos serán nuestro estado inicial:

```elixir
defmodule SimpleQueue do
  use GenServer

  @doc """
  Start our queue and link it.  This is a helper function
  """
  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @doc """
  GenServer.init/1 callback
  """
  def init(state), do: {:ok, state}
end
```

### Funciones síncronas

Frecuentemente es necesario interactuar con GenServers de un modo síncrono, llamando a una función y esperando su respuesta. Para manejar peticiones síncronas necesitamos implementar el *callback* `GenServer.handle_call/3` el cual toma la petición, el PID de quien llama a la función y el estado existente. Este espera responder con una tupla de la siguiente forma `{:reply, response, state}`.

Con concurrencia de patrones podemos definir *callbacks* para diferentes peticiones y estados. Una lista completa de valores aceptados puede encontrarse en la documentación [`GenServer.handle_call/3`](https://hexdocs.pm/elixir/GenServer.html#c:handle_call/3).

Para demostrar las peticiones síncronas vamos a agregar la habilidad de mostrar nuestra cola y eliminar valores:

```elixir
defmodule SimpleQueue do
  use GenServer

  ### GenServer API

  @doc """
  GenServer.init/1 callback
  """
  def init(state), do: {:ok, state}

  @doc """
  GenServer.handle_call/3 callback
  """
  def handle_call(:dequeue, _from, [value | state]) do
    {:reply, value, state}
  end

  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  ### Client API / Helper functions

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```

Vamos a iniciar nuestra `SimpleQueue` y probar la funcionalidad `dequeue`:

```elixir
iex> SimpleQueue.start_link([1, 2, 3])
{:ok, #PID<0.90.0>}
iex> SimpleQueue.dequeue
1
iex> SimpleQueue.dequeue
2
iex> SimpleQueue.queue
[3]
```

### Funciones asíncronas

Las peticiones asíncronas son manejadas con el *callback* `handle_cast/2`. Este trabaja de forma similar a `handle_call/3` pero no recibe a quien hace la llamada y no se espera que haya una respuesta.

Implementaremos nuestra funcionalidad de desencolado para que sea asíncrona, actualizando la cola pero no bloqueando la ejecución actual.

```elixir
defmodule SimpleQueue do
  use GenServer

  ### GenServer API

  @doc """
  GenServer.init/1 callback
  """
  def init(state), do: {:ok, state}

  @doc """
  GenServer.handle_call/3 callback
  """
  def handle_call(:dequeue, _from, [value | state]) do
    {:reply, value, state}
  end

  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  @doc """
  GenServer.handle_cast/2 callback
  """
  def handle_cast({:enqueue, value}, state) do
    {:noreply, state ++ [value]}
  end

  ### Client API / Helper functions

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def enqueue(value), do: GenServer.cast(__MODULE__, {:enqueue, value})
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```

Vamos a probar nuestra nueva funcionalidad:

```elixir
iex> SimpleQueue.start_link([1, 2, 3])
{:ok, #PID<0.100.0>}
iex> SimpleQueue.queue
[1, 2, 3]
iex> SimpleQueue.enqueue(20)
:ok
iex> SimpleQueue.queue
[1, 2, 3, 20]
```

Para mas información revisa la documentación oficial [GenServer](https://hexdocs.pm/elixir/GenServer.html#content).
