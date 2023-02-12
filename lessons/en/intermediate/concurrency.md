%{
  version: "1.1.1",
  title: "Concurrency",
  excerpt: """
  One of the selling points of Elixir is its support for concurrency.
  Thanks to the Erlang VM (BEAM), concurrency in Elixir is easier than expected.
  The concurrency model relies on Actors, a contained process that communicates with other processes through message passing.

  In this lesson we'll look at the concurrency modules that ship with Elixir.

  In the following chapter we cover the OTP behaviors that implement them.
  """
}
---

## Processes

Processes in the Erlang VM are lightweight and run across all CPUs.
While they may seem like native threads, they're simpler and it's not uncommon to have thousands of concurrent processes in an Elixir application.

The easiest way to create a new process is `spawn`, which takes either an anonymous or named function.
When we create a new process it returns a _Process Identifier_, or PID, to uniquely identify it within our application.

To start we'll create a module and define a function we'd like to run:

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

To evaluate the function asynchronously we use `spawn/3`:

```elixir
iex> spawn(Example, :add, [2, 3])
5
#PID<0.80.0>
```

### Message Passing

To communicate, processes rely on message passing.
There are two main components to this: `send/2` and `receive`.
The `send/2` function allows us to send messages to PIDs.
To listen we use `receive` to match messages.
If no match is found the execution continues uninterrupted.

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

You may notice that the `listen/0` function is recursive, this allows our process to handle multiple messages.
Without recursion our process would exit after handling the first message.

### Process Linking

One problem with `spawn` is knowing when a process crashes.
For that we need to link our processes using `spawn_link`.
Two linked processes will receive exit notifications from one another:

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)
end

iex> spawn(Example, :explode, [])
#PID<0.66.0>

iex> spawn_link(Example, :explode, [])
** (EXIT from #PID<0.57.0>) evaluator process exited with reason: :kaboom
```

Sometimes we don't want our linked process to crash the current one.
For that we need to trap the exits using `Process.flag/2`.
It uses erlang's [process_flag/2](http://erlang.org/doc/man/erlang.html#process_flag-2) function for the `trap_exit` flag. When trapping exits (`trap_exit` is set to `true`), exit signals will be received as a tuple message: `{:EXIT, from_pid, reason}`.

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

### Process Monitoring

What if we don't want to link two processes but still be kept informed? For that we can use process monitoring with `spawn_monitor`.
When we monitor a process we get a message if the process crashes without our current process crashing or needing to explicitly trap exits.

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

Agents are an abstraction around background processes maintaining state.
We can access them from other processes within our application and node.
The state of our Agent is set to our function's return value:

```elixir
iex> {:ok, agent} = Agent.start_link(fn -> [1, 2, 3] end)
{:ok, #PID<0.65.0>}

iex> Agent.update(agent, fn (state) -> state ++ [4, 5] end)
:ok

iex> Agent.get(agent, &(&1))
[1, 2, 3, 4, 5]
```

When we name an Agent we can refer to it by that instead of its PID:

```elixir
iex> Agent.start_link(fn -> [1, 2, 3] end, name: Numbers)
{:ok, #PID<0.74.0>}

iex> Agent.get(Numbers, &(&1))
[1, 2, 3]
```

## Tasks

Tasks provide a way to execute a function in the background and retrieve its return value later.
They can be particularly useful when handling expensive operations without blocking the application execution.

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
