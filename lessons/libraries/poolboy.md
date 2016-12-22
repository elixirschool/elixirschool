---
layout: page
title: Poolboy
category: libraries
order: 2
lang: en
---

You can easily exhaust your system resources if you allow concurrent processes to run arbitrarily. Poolboy prevents having to incur the overhead by creating a pool of workers to limit the number of concurrent processes.

{% include toc.html %}

## Why use Poolboy?

Let's think of a specific example for a moment. You are tasked to build an application for saving user profile information to the database. If you've created a process for every user registration, you would create unbounded number of connections. At some point those connections start competing for the limited resources available in your database server. Eventually your application gets timeouts and various exceptions due to the overhead from that contention.

The solution to this problem is using set of workers (processes) to limit the number of connections instead of creating a process for every user registration. Then you can easily avoid running out of your system resources.

That's where Poolboy comes in. It creates a pool of workers managed by a `Supervisor` without any effort on your part to do it manually. There are many libraries which use Poolboy under the covers. For example, `postgrex`'s connection pool *(which is leveraged by Ecto when using psql)* and `redis_poolex` *(Redis connection pool)* are some popular libraries which use Poolboy.

## Installation

Installation is a breeze with mix. All we need to do is add Poolboy as a dependency to our `mix.exs`.  

Let's create an application first:

```
$ mix new poolboy_app --sup
$ mix deps.get
```

Add Poolboy as a dependency to our `mix.exs`.  

```elixir
defp deps do
  [{:poolboy, "~> 1.5.1"}]
end
```

And add Poolboy to our OTP application:

```elixir
def application do
  [applications: [:logger, :poolboy]]
end
```

## The configuration options

We need to know a little bit about the various configuration options in order to start using Poolboy.

* `:name` - the pool name. Scope can be `:local`, `:global`, or `:via`.
* `:worker_module` - the module that represents the worker.
* `:size` - maximum pool size.
* `:max_overflow` - maximum number of workers created if pool is empty. (optional)
* `:strategy` - `:lifo` or `:fifo`, determines whether checked in workers should be placed first or last in the line of available workers. Default is `:lifo`. (optional)

## Configuring Poolboy

For this example, we'll create a pool of workers that are responsible for handling requests to calculate the square root of a number. We'll keep the example simple so that we can keep our focus on Poolboy.

Let's define the Poolboy configuration options and add it as a child worker as part of our application start.

```elixir
defmodule PoolboyApp do
  use Application

  defp poolboy_config do
    [{:name, {:local, :worker}},
      {:worker_module, Worker},
      {:size, 5},
      {:max_overflow, 2}]
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

The first thing we defined is the configuration options for the pool. We assigned a unique pool `:name`, set the `:scope` to local, and the `:size` of the pool to have total of five workers. Also, in case all workers are under load, we tell it to create two more workers to help with the load using the `:max_overflow` option. *(`overflow` workers do go away once they complete their work.)*

Next, we added `poolboy.child_spec/3` function to the array of children so that the pool of workers will be started when the application starts.

The `child_spec/3` function takes three arguments; Name of the pool, pool configuration, and the third argument that is passed to the `worker.start_link` function. In our case, it is just an empty list.

## Creating Worker
The worker module will be a simple GenServer calculating the square root of a number, sleeping for one second, and printing out the pid of the worker:

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
    IO.puts "process #{inspect self} calculating square root of #{x}"
    :timer.sleep(1000)
    {:reply, :math.sqrt(x), state}
  end
end
```

## Using Poolboy

Now that we have our `Worker`, we can test Poolboy. Let's create a simple module that creates concurrent processes using `:poolboy.transaction` function:

```elixir
defmodule Test do
  @timeout 60000

  def start do
     tasks = Enum.map(1..20, fn(i) ->
        Task.async(fn -> :poolboy.transaction(:worker,
          &(GenServer.call(&1, {:square_root, i})), @timeout)
        end)
     end)
     Enum.each(tasks, fn(task) -> IO.puts(Task.await(task, @timeout)) end)
  end
end

```
If you do not have available pool workers, Poolboy will timeout after the default timeout period (five seconds) and won't accept any new requests. In our example, we've increased the default timeout to one minute in order to demonstrate how we can change the default timeout value.

Even though we're attempting to create multiple processes *(total of twenty in the example above)* `:poolboy.transaction` function will limit the total of created processes to five *(plus two overflow workers if needed)* as we defined it in our configuration. All requests will be handled by the pool of workers rather than creating a new process for each and every request.
