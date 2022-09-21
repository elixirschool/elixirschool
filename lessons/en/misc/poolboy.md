%{
  version: "1.2.1",
  title: "Poolboy",
  excerpt: """
  You can easily exhaust your system resources if you do not limit the maximum number of concurrent processes that your program can spawn.
  [Poolboy](https://github.com/devinus/poolboy) is a widely used lightweight, generic pooling library for Erlang that addresses this issue.
  """
}
---

## Why use Poolboy?

Let's think of a specific example for a moment.
You are tasked to build an application for saving user profile information to the database.
If you've created a process for every user registration, you would create an unbounded number of connections.
At some point the number of those connections can exceed the capacity of your database server.
Eventually your application can get timeouts and various exceptions.

The solution is to use a set of workers (processes) to limit the number of connections instead of creating a process for every user registration.
Then you can easily avoid running out of your system resources.

That's where Poolboy comes in.
It allows you to easily set up a pool of workers managed by a `Supervisor` without much effort on your part.
There are many libraries which use Poolboy under the covers.
For example,`redis_poolex` *(Redis connection pool)* is a popular library which uses Poolboy.

## Installation

Installation is a breeze with mix.
All we need to do is add Poolboy as a dependency to our `mix.exs`.

Let's create an application first:

```shell
mix new poolboy_app --sup
```

Add Poolboy as a dependency to our `mix.exs`.

```elixir
defp deps do
  [{:poolboy, "~> 1.5.1"}]
end
```

Then fetch dependencies, including Poolboy.

```shell
mix deps.get
```

## The configuration options

We need to know a little bit about the various configuration options in order to start using Poolboy.

* `:name` - the pool name.
Scope can be `:local`, `:global`, or `:via`.
* `:worker_module` - the module that represents the worker.
* `:size` - maximum pool size.
* `:max_overflow` - maximum number of temporary workers created when the pool is empty.
(optional)
* `:strategy` - `:lifo` or `:fifo`, determines whether the workers that return to the pool should be placed first or last in the line of available workers.
Default is `:lifo`.
(optional)

## Configuring Poolboy

For this example, we'll create a pool of workers responsible for handling requests to calculate the square root of a number.
We'll keep the example simple so that we can keep our focus on Poolboy.

Let's define the Poolboy configuration options and add the Poolboy worker pool as a child worker of our application.
Edit `lib/poolboy_app/application.ex`:

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

The first thing we defined is the configuration options for the pool.
We named our pool `:worker` and set the `:scope` to `:local`.
Then we designated `PoolboyApp.Worker` module as the `:worker_module` that this pool should use.
We also set the `:size` of the pool to have total of `5` workers.
Also, in case all workers are under load, we tell it to create `2` more workers to help with the load using the `:max_overflow` option.
*(`overflow` workers do go away once they complete their work.)*

Next, we added `:poolboy.child_spec/2` function to the array of children so that the pool of workers will be started when the application starts.
It takes two arguments: name of the pool, and pool configuration.

## Creating Worker

The worker module will be a simple `GenServer` that calculates the square root of a number, sleeps for one second, and prints out the pid of the worker.
Create `lib/poolboy_app/worker.ex`:

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

## Using Poolboy

Now that we have our `PoolboyApp.Worker`, we can test Poolboy.
Let's create a simple module that creates concurrent processes using Poolboy.
`:poolboy.transaction/3` is the function that you can use to interface with the worker pool.
Create `lib/poolboy_app/test.ex`:

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
        fn pid -> 
          # Let's wrap the genserver call in a try - catch block. This allows us to trap any exceptions
          # that might be thrown and return the worker back to poolboy in a clean manner. It also allows
          # the programmer to retrieve the error and potentially fix it.
          try do
            GenServer.call(pid, {:square_root, i})
          catch
            e, r -> IO.inspect("poolboy transaction caught error: #{inspect(e)}, #{inspect(r)}")
            :ok
          end
        end,
        @timeout
      )
    end)
  end

  defp await_and_inspect(task), do: task |> Task.await(@timeout) |> IO.inspect()
end
```

Run the test function to see the result.

```shell
iex -S mix
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

If no worker is available in the pool, Poolboy will timeout after the default timeout period (five seconds) and won't accept any new requests.
In our example, we've increased the default timeout to one minute in order to demonstrate how we can change the default timeout value.
In case of this app, you can observe the error if you change the value of `@timeout` to less than 1000.

Even though we're attempting to create multiple processes *(total of twenty in the example above)* `:poolboy.transaction/3` function will limit the maximum number of created processes to five *(plus two overflow workers if needed)* as we have defined in our configuration.
All requests will be handled using the pool of workers rather than creating a new process for every request.
