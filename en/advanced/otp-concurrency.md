---
layout: page
title: OTP Concurrency
category: advanced
order: 5
lang: en
---

We've looked at the Elixir abstractions for concurrency but sometimes we need greater control and for that we turn to the OTP behaviors that Elixir is built on.

In this lesson we'll focus on two important pieces: GenServers and GenEvents.

{% include toc.html %}

## GenServer

An OTP server is a module with the GenServer behavior that implements a set of callbacks.  At its most basic level a GenServer is a loop that handles one request per iteration passing along an updated state.

To demonstrate the GenServer API we'll implement a basic queue to store and retrieve values.

To begin our GenServer we need to start it and handle the initialization. In most cases we'll want to link processes so we use `GenServer.start_link/3`.  We pass in the GenServer module we're starting, initial arguments, and a set of GenServer options.  The arguments will be passed to `GenServer.init/1` which sets the initial state through its return value.  In our example the arguments will be our initial state:

```elixir
defmodule SimpleQueue do
  use GenServer

  @doc """
  Start our queue and link it.  This is a helper method
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

### Synchronous Functions

It's often necessary to interact with GenServers in a synchronous way, calling a function and waiting for its response.  To handle synchronous requests we need to implement the `GenServer.handle_call/3` callback which takes: the request, the caller's PID, and the existing state; it is expected to reply by returning a tuple: `{:reply, response, state}`.

With pattern matching we can define callbacks for many different requests and states. A complete list of accepted return values can be found in the [`GenServer.handle_call/3`](http://elixir-lang.org/docs/stable/elixir/GenServer.html#c:handle_call/3) docs.

To demonstrate synchronous requests let's add the ability to display our current queue and to remove a value:

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
  def handle_call(:dequeue, _from, [value|state]) do
    {:reply, value, state}
  end
  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  ### Client API / Helper methods

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end

```

Let's start our SimpleQueue and test out our new dequeue functionality:

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

### Asynchronous Functions

Asynchronous requests are handled with the `handle_cast/2` callback.  This works much like `handle_call/3` but does not receive the caller and is not expected to reply.

We'll implement our enqueue functionality to be asynchronous, updating the queue but not blocking our current execution:

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
  def handle_call(:dequeue, _from, [value|state]) do
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

  ### Client API / Helper methods

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end
  def queue, do: GenServer.call(__MODULE__, :queue)
  def enqueue(value), do: GenServer.cast(__MODULE__, {:enqueue, value})
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```

Let's put our new functionality to use:

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

For more information check out the official [GenServer](http://elixir-lang.org/docs/stable/elixir/GenServer.html#content) documentation.

## GenEvent

We learned that GenServers are processes that can maintain state and handle synchronous and asynchronous requests.  So what is a GenEvent?  GenEvents are generic event managers that receive incoming events and notify subscribed consumers.  They provide a mechanism for dynamically adding and removing handlers to flows of events.

### Handling Events

The most important callback in GenEvents as you can imagine is `handle_event/2`.  This receives the event and the handler's current state and is expected to return a tuple: `{:ok, state}`.

To demonstrate the GenEvent functionality let's start by creating two handlers, one to keep a log of messages and the other to persist them (theoretically):

```elixir
defmodule LoggerHandler do
  use GenEvent

  def handle_event({:msg, msg}, messages) do
    IO.puts "Logging new message: #{msg}"
    {:ok, [msg|messages]}
  end
end

defmodule PersistenceHandler do
  use GenEvent

  def handle_event({:msg, msg}, state) do
    IO.puts "Persisting log message: #{msg}"

    # Save message

    {:ok, state}
  end
end
```

### Calling Handlers

In addition to `handle_event/2` GenEvents also support `handle_call/2` among other callbacks.  With `handle_call/2` we can handle specific synchronous messages with our handler.

Let's update our `LoggerHandler` to include a method for retrieving the current message log:

```elixir
defmodule LoggerHandler do
  use GenEvent

  def handle_event({:msg, msg}, messages) do
    IO.puts "Logging new message: #{msg}"
    {:ok, [msg|messages]}
  end

  def handle_call(:messages, messages) do
    {:ok, Enum.reverse(messages), messages}
  end
end
```

### Using GenEvents

With our handlers ready to go we need to familiarize ourselves with a few of GenEvent's functions.  The three most important functions are: `add_handler/3`, `notify/2`, and `call/4`.  These allow us to add handlers, broadcast new messages, and call specific handler functions respectively.

If we put it all together we can see our handlers in action:

```elixir
iex> {:ok, pid} = GenEvent.start_link([])
iex> GenEvent.add_handler(pid, LoggerHandler, [])
iex> GenEvent.add_handler(pid, PersistenceHandler, [])

iex> GenEvent.notify(pid, {:msg, "Hello World"})
Logging new message: Hello World
Persisting log message: Hello World

iex> GenEvent.call(pid, LoggerHandler, :messages)
["Hello World"]
```

See the official [GenEvent](http://elixir-lang.org/docs/stable/elixir/GenEvent.html#content) documentation for a complete list of callbacks and GenEvent functionality.
