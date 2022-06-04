%{
  version: "1.1.2",
  title: "OTP Supervisors",
  excerpt: """
  Supervisors are specialized processes with one purpose: monitoring other processes.
  These supervisors enable us to create fault-tolerant applications by automatically restarting child processes when they fail.
  """
}
---

## Configuration

The magic of Supervisors is in the `Supervisor.start_link/2` function.
In addition to starting our supervisor and children, it allows us to define the strategy our supervisor uses for managing child processes.

Using the `SimpleQueue` from the [OTP Concurrency](/en/lessons/advanced/otp_concurrency) lesson, let's get started:

Create a new project using `mix new simple_queue --sup` to create a new project with a supervisor tree.
The code for the `SimpleQueue` module should go in `lib/simple_queue.ex` and the supervisor code we'll be adding will go in `lib/simple_queue/application.ex`

Children are defined using a list, either a list of module names:

```elixir
defmodule SimpleQueue.Application do
  use Application

  def start(_type, _args) do
    children = [
      SimpleQueue
    ]

    opts = [strategy: :one_for_one, name: SimpleQueue.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

or a list of tuples if you want to include configuration options:

```elixir
defmodule SimpleQueue.Application do
  use Application

  def start(_type, _args) do
    children = [
      {SimpleQueue, [1, 2, 3]}
    ]

    opts = [strategy: :one_for_one, name: SimpleQueue.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

If we run `iex -S mix` we'll see that our `SimpleQueue` is automatically started:

```elixir
iex> SimpleQueue.queue
[1, 2, 3]
```

If our `SimpleQueue` process were to crash or be terminated our Supervisor would automatically restart it as if nothing had happened.

### Strategies

There are currently three different supervision strategies available to supervisors:

+ `:one_for_one` - Only restart the failed child process.

+ `:one_for_all` - Restart all child processes in the event of a failure.

+ `:rest_for_one` - Restart the failed process and any process started after it.

## Child Specification

After the supervisor has started it must know how to start/stop/restart its children.
Each child module should have a `child_spec/1` function to define these behaviors.
The `use GenServer`, `use Supervisor`, and `use Agent` macros automatically define this method for us (`SimpleQueue` has `use GenServer`, so we do not need to modify the module), but if you need to define it yourself `child_spec/1` should return a map of options:

```elixir
def child_spec(opts) do
  %{
    id: SimpleQueue,
    start: {__MODULE__, :start_link, [opts]},
    shutdown: 5_000,
    restart: :permanent,
    type: :worker
  }
end
```

+ `id` - Required key.
  Used by the supervisor to identify the child specification.

+ `start` - Required key.
  The Module/Function/Arguments to call when started by the supervisor

+ `shutdown` - Optional key.
  Defines child's behavior during shutdown.

  Options are:

  + `:brutal_kill` - Child is stopped immediately

  + `0` or a positive integer - time in milliseconds supervisor will wait before killing child process.

    If the process is a `:worker` type, `shutdown` defaults to `5000`.

  + `:infinity` - Supervisor will wait indefinitely before killing child process.

    Default for `:supervisor` process type.

    Not recommended for `:worker` type.

+ `restart` - Optional key.

  There are several approaches for handling child process crashes:

  + `:permanent` - Child is always restarted.
    Default for all processes

  + `:temporary` - Child process is never restarted.

  + `:transient` - Child process is restarted only if it terminates abnormally.

+ `type` - Optional key.
  Processes can be either `:worker` or `:supervisor`.
  Defaults to `:worker`.

## DynamicSupervisor

Supervisors normally start with a list of children to start when the app starts.
However, sometimes the supervised children will not be known when our app starts up (for example, we may have a web app that starts a new process to handle a user connecting to our site).
For these cases we will want a supervisor where the children can be started on demand.
The DynamicSupervisor is used to handle this case.

Since we will not specify children, we only need to define the runtime options for the supervisor.
The DynamicSupervisor only supports the `:one_for_one` supervision strategy:

```elixir
options = [
  name: SimpleQueue.Supervisor,
  strategy: :one_for_one
]

DynamicSupervisor.start_link(options)
```

Then, to start a new SimpleQueue dynamically we'll use `start_child/2` which takes a supervisor and the child specification (again, `SimpleQueue` uses `use GenServer` so the child specification is already defined):

```elixir
{:ok, pid} = DynamicSupervisor.start_child(SimpleQueue.Supervisor, SimpleQueue)
```

## Task Supervisor

Tasks have their own specialized Supervisor, the `Task.Supervisor`.
Designed for dynamically created tasks, the supervisor uses `DynamicSupervisor` under the hood.

### Setup

Including the `Task.Supervisor` is no different than other supervisors:

```elixir
children = [
  {Task.Supervisor, name: ExampleApp.TaskSupervisor, restart: :transient}
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

The major difference between `Supervisor` and `Task.Supervisor` is that its default restart strategy is `:temporary` (tasks would never be restarted).

### Supervised Tasks

With the supervisor started we can use the `start_child/2` function to create a supervised task:

```elixir
{:ok, pid} = Task.Supervisor.start_child(ExampleApp.TaskSupervisor, fn -> background_work end)
```

If our task crashes prematurely it will be re-started for us.
This can be particularly useful when working with incoming connections or processing background work.
