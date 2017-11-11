---
version: 1.0.1
title: OTP Supervisors
redirect_from:
  - /lessons/advanced/otp-supervisors/
---

Supervisors are specialized processes with one purpose: monitoring other processes. These supervisors enable us to create fault-tolerant applications by automatically restarting child processes when they fail.

{% include toc.html %}

## Configuration

The magic of Supervisors is in the `Supervisor.start_link/2` function.  In addition to starting our supervisor and children, it allows us to define the strategy our supervisor uses for managing child processes.

Children are defined using a list and the `worker/3` function we imported from `Supervisor.Spec`.  The `worker/3` function takes a module, arguments, and a set of options.  Under the hood `worker/3` calls `start_link/3` with our arguments during initialization.

Using the SimpleQueue from the [OTP Concurrency](../../advanced/otp-concurrency) lesson let's get started:

```elixir
import Supervisor.Spec

children = [
  worker(SimpleQueue, [], name: SimpleQueue)
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

If our process were to crash or be terminated our Supervisor would automatically restart it as if nothing had happened.

### Strategies

There are currently four different restart strategies available to supervisors:

+ `:one_for_one` - Only restart the failed child process.

+ `:one_for_all` - Restart all child processes in the event of a failure.

+ `:rest_for_one` - Restart the failed process and any process started after it.

+ `:simple_one_for_one` - Best for dynamically attached children. Supervisor spec is required to contain only one child, but this child can be spawned multiple times. This strategy is intended to be used when you need to dynamically start and stop supervised children.

### Restart values

There are several approaches for handling child process crashes:

+ `:permanent` - Child is always restarted.

+ `:temporary` - Child process is never restarted.

+ `:transient` - Child process is restarted only if it terminates abnormally.

It's not a required option, by default it's `:permanent`.

### Nesting

In addition to worker processes, we can also supervise supervisors to create a supervisor tree.  The only difference to us is swapping `supervisor/3` for `worker/3`:

```elixir
import Supervisor.Spec

children = [
  supervisor(ExampleApp.ConnectionSupervisor, [[name: ExampleApp.ConnectionSupervisor]]),
  worker(SimpleQueue, [[], [name: SimpleQueue]])
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

## Task Supervisor

Tasks have their own specialized Supervisor, the `Task.Supervisor`.  Designed for dynamically created tasks, the supervisor uses `:simple_one_for_one` under the hood.

### Setup

Including the `Task.Supervisor` is no different than other supervisors:

```elixir
import Supervisor.Spec

children = [
  supervisor(Task.Supervisor, [[name: ExampleApp.TaskSupervisor, restart: :transient]])
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

The major difference between `Supervisor` and `Task.Supervisor` is that its default restart strategy is `:temporary` (tasks would never be restarted).

### Supervised Tasks

With the supervisor started we can use the `start_child/2` function to create a supervised task:

```elixir
{:ok, pid} = Task.Supervisor.start_child(ExampleApp.TaskSupervisor, fn -> background_work end)
```

If our task crashes prematurely it will be re-started for us.  This can be particularly useful when working with incoming connections or processing background work.
