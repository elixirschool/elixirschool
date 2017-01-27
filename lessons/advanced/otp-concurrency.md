---
layout: page
title: OTP Concurrency
category: advanced
order: 5
lang: en
---

We've looked at the Elixir abstractions for concurrency but sometimes we need greater control and for that we turn to the OTP behaviors that Elixir is built on.

In this lesson we'll focus on GenServers.

{% include toc.html %}

## GenServer

An OTP server is a module with the GenServer behavior that implements a set of callbacks.  At its most basic level a GenServer is a loop that handles one request per iteration passing along an updated state.

To demonstrate the GenServer API we'll implement a basic queue to store and retrieve values.
From there, to show off a creative use of it, we will build a simple cron server to execute tasks.

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

### A Simple Cron Server
Lets say we have a project that needs to regularly run some task then say the work is completed.
We will give a simple example of how to do this without having to worry about dependencies or any large amounts of complexity.

To start, lets make a simple mix project with a supervision tree:

```
$ mix new silly_worker --sup
$ cd silly_worker
$ mix test
```

To start, let's create a simple `CronJob` GenServer in `lib/silly_worker/cron_job.ex`:

```elixir
defmodule SillyWorker.CronJob do
  use GenServer

  def start_link(module, function, args, interval) do
    GenServer.start_link(__MODULE__, {module, function, args, interval})
  end

  def init({module, function, args, interval}) do
    schedule_work(interval)
    {:ok, {module, function, args, interval}}
  end

  def handle_info(:perform_job, {module, function, args, interval}) do
    apply(module, function, args)
    schedule_work(interval)
    {:noreply, {module, function, args, interval}}
  end

  defp schedule_work(interval) do
    Process.send_after(self(), :perform_job, interval)
  end
end
```

There are a few pieces here.
Let's go over them individually.

#### Startup
We want to take in a given module, function, argument list, and interval to run the task in.
From here, we start a GenServer with those are the beginning state:

```elixir
  def start_link(module, function, args, interval) do
    GenServer.start_link(__MODULE__, {module, function, args, interval})
  end
```

#### Scheduling and Performing Job
Next we set up a way to schedule our work and handle the call with [`handle_info/2`](https://hexdocs.pm/elixir/GenServer.html#c:handle_info/2):

```elixir
  def handle_info(:perform_job, {module, function, args, interval}) do
    apply(module, function, args)
    schedule_work(interval)
    {:noreply, {module, function, args, interval}}
  end

  defp schedule_work(interval) do
    Process.send_after(self(), :perform_job, interval)
  end
```

#### Running The Job Indefinitely
And finally, we set up our `init/1` to just call those with the given interval:

```elixir
  def init({module, function, args, interval}) do
    schedule_work(interval)
    {:ok, {module, function, args, interval}}
  end
```

Now, lets create a worker to pass into this worker for once we get it into our tree in `lib/silly_worker.ex`.

#### Making A Worker Task
This is very simple, we aren't going to be doing any real work but we can see the functionality.

```elixir
defmodule SillyWorker do
  def do_work(job_name) do
    # do some work
    # ...
    require Logger
    Logger.log(:info, "#{job_name} Complete!")
    :ok
  end
end
```

#### Setting Up Our Worker
Finally we just set up our worker to run in the given interval we choose in our `application.ex` file:

```elixir
    children = [
      worker(SillyWorker.CronJob, [SillyWorker, :do_work, ["Job Number 1"], 1000]),
    ]
```

Now if we just run IEx the worker will run that function on our module every second in its own process under the supervision tree:

```
$ iex -S mix
iex(1)>
20:39:27.732 [info]  Job Done

20:39:28.232 [info]  Job Done
```

Thats it!
Check out a working example of the CronJob app [here](https://github.com/ybur-yug/genserver_periodic_worker_example).

For more information check out the official [GenServer](http://elixir-lang.org/docs/stable/elixir/GenServer.html#content) documentation.
