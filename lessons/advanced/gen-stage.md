---
layout: page
title: GenStage
category: specifics
order:
lang: en
---

In this lesson we're going to take a closer look at the GenStage, what role it serves, and how we can leverage it in our applications. 

{% include toc.html %}

## Introduction

So what is GenStage?  From the official documentation, it is a "specification and computational flow for Elixir", but what does that mean to us?  

What it means is that GenStage provides a way for us to define a pipeline of work to be carried out by independent steps (or stages) in a separate processes; if you've worked with pipelines before then some of these concepts should be familiar.

We could go into the technical and theoretical implications of this, but instead lets try a pragmatic approach to really just get it to work.

First, Let's imagine we have a server that constantly emits numbers.
It starts at the state of the number we give it, then counts up in one from there onward.
This is what we would call our producer.
Each time it emits a number, this is an event, and we want to handle it with a consumer.
A consumer simply takes what a producer emits and does something to it.
In our case, we will display the count.
There is a lot more to GenStage at a technical and applied level, but we will build up on the specifics and definitions further in later lessons, for now we just want a running example we can build up on.

## Getting Started: A Sample GenStage Project
We'll begin by generating a simple project that has a supervision tree:

```shell
$ mix new genstage_example --sup
$ cd genstage_example
```

Let's set up some basic things for the future of our application.
Since GenStage is generally used as a transformation pipeline, lets imagine we have a background worker of some sort.
This worker will need to persist whatever it changes, so we should get a database set up, but we can worry about that in a later lesson.
To start, all we need to do is add `gen_stage` to our deps.

```elixir
. . .
  defp deps do
    [
      {:gen_stage, "~> 0.7},
    ]
  end
. . .
```

Now, we should fetch our dependencies and compile before we start setup:

```shell
$ mix do deps.get, compile
```

Lets build a producer, our simple beginning building block to help us utilize this new tool!

## Building A Producer
To get started what we want to do is create a producer that emits a constant stream of events for our consumer to handle.
This is quite simple with the rudimentary example of a counter.
Let's create a namespaced directory under `lib` and then go from there, this way our module naming matches our names of the modules themselves:

```shell
$ mkdir lib/genstage_example
$ touch lib/genstage_example/producer.ex
```

Now we can add the code:

```elixir
defmodule GenstageExample.Producer do
  alias Experimental.GenStage
  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, 0, name: __MODULE__)
                                       # naming allows us to handle failure
  end

  def init(counter) do
    {:producer, counter}
  end

  def handle_demand(demand, state) do
    events = Enum.to_list(state..state + demand - 1)
    {:noreply, events, (state + demand)}
  end
end
```
[working commit](https://github.com/ybur-yug/genstage_example/commit/57418160a1e5cbb408e32184d913a12e207166f8)

Let's break this down line by line.
To begin with, we have our initial declarations:

```elixir
defmodule GenstageExample.Producer do
  alias Experimental.GenStage
  use GenStage
. . .
```

What this does is a couple simple things.
First, we declare our module, and soon after we alias `Experimental.GenStage`.
This is simply because we will be calling it more than once and makes it more convenient.
The `use GenStage` line is much akin to `use GenServer`.
This line allows us to import the default behaviour and functions to save us from a large amount of boilerplate.

If we go further, we see the first two primary functions for startup:

```elixir
. . .
  def start_link do
    GenStage.start_link(__MODULE__, :the_state_doesnt_matter)
  end

  def init(counter) do
    {:producer, counter}
  end
. . .
```

These two functions offer a very simple start.
First, we have our standard `start_link/0` function.
Inside here, we use`GenStage.start_link/` beginning with our argument `__MODULE__`, which will give it the name of our current module.
Next, we set a state, which is arbitrary in this case, and can be any value.
The `__MODULE__` argument is used for name registration like any other module.
The second argument is the arguments, which in this case are meaningless as we do not care about it.
In `init/1` we simply set the counter as our state, and label ourselves as a producer.

Finally, we have where the real meat of our code's functionality is:

```elixir
. . .
  def handle_demand(demand, state) do
    events = Enum.to_list(state..state + demand - 1)
    {:noreply, events, (state + demand)}
  end
. . .
```

`handle_demand/2` must be implemented by all producer type modules that utilize GenStage.
In this case, we are simply sending out an incrementing counter.
This might not make a ton of sense until we build our consumer, so lets move on to that now.

## Building A Consumer
The consumer will handle the events that are broadcasted out by our producer.
For now, we wont worry about things like broadcast strategies, or what the internals are truly doing.
We'll start by showing all the code and then break it down.

```elixir
defmodule GenstageExample.Consumer do
  alias Experimental.GenStage
  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, :state_doesnt_matter)
  end

  def init(state) do
    {:consumer, state, subscribe_to: [GenstageExample.Producer]}
  end

  def handle_events(events, _from, state) do
    for event <- events do
      IO.inspect {self(), event, state}
    end
    {:noreply, [], state}
  end
end
```
[working commit](https://github.com/ybur-yug/genstage_example/commit/472a136229e5926294babe10a5bab307ed7c1f54)

To start, let's look at the beginning functions just like last time:

```elixir
defmodule GenstageExample.Consumer do
  alias Experimental.GenStage
  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, :state_doesnt_matter)
  end

  def init(state) do
    {:consumer, state, subscribe_to: [GenstageExample.Producer]}
  end
. . .
```

To begin, much like in our producer, we set up our `start_link/0` and `init/1` functions.
In `start_link` we simple register the module name like last time, and set a state.
The state is arbitrary for the consumer, and can be literally whatever we please, in this case `:state_doesnt_matter`.

In `init/1` we simply take the state and set up our expected tuple.
It expected use to register our `:consumer` atom first, then the state given.
Our `subscribe_to` clause is optional.
What this does is subscribe us to our producer module.
The reason for this is if something crashes, it will simply attempt to re-subscribe and then resume receiving emitted events.

```elixir
. . .
  def handle_events(events, _from, state) do
    for event <- events do
      IO.inspect {self(), event, state}
    end
    {:noreply, [], state}
  end
. . .
```

This is the meat of our consumer, `handle_events/3`.
`handle_events/3` must be implemented by any `consumer` or `producer_consumer` type of GenStage module.
What this does for us is quite simple.
We take a list of events, and iterate through these.
From there, we inspect the `pid` of our consumer, the event (in this case the current count), and the state.
After that, we don't reply because we are a consumer and do not handle anything, and we don't emit events to the second argument is empty, then we simply pass on the state.

## Wiring It Together
To get all of this to work we only have to make one simple change.
Open up `lib/genstage_example.ex` and we can add them as workers and they will automatically start with our application:

```elixir
. . .
    children = [
      worker(GenstageExample.Producer, []),
      worker(GenstageExample.Consumer, []),
    ]
. . .
```

With this, if things are all correct, we can run IEx and we should see everything working:

```elixir
iex(1)> {#PID<0.205.0>, 0, :state_doesnt_matter}
{#PID<0.205.0>, 1, :state_doesnt_matter}
{#PID<0.205.0>, 2, :state_doesnt_matter}
{#PID<0.205.0>, 3, :state_doesnt_matter}
{#PID<0.205.0>, 4, :state_doesnt_matter}
{#PID<0.205.0>, 5, :state_doesnt_matter}
{#PID<0.205.0>, 6, :state_doesnt_matter}
{#PID<0.205.0>, 7, :state_doesnt_matter}
{#PID<0.205.0>, 8, :state_doesnt_matter}
{#PID<0.205.0>, 9, :state_doesnt_matter}
{#PID<0.205.0>, 10, :state_doesnt_matter}
{#PID<0.205.0>, 11, :state_doesnt_matter}
{#PID<0.205.0>, 12, :state_doesnt_matter}
. . .
```

## Tinkering: For Science and Understanding
From here, we have a working flow.
There is a producer emitting our counter, and our consumber is displaying all of this and continuing the flow.
Now, what if we wanted multiple consumers?
Right now, if we examine the `IO.inspect/1` output, we see that every single event is handled by a single PID.
This isn't very Elixir-y.
We have massive concurrency built-in, we should probably leverage that as much as possible.
Let's make some adjustments so that we can have multiple workers by modifying `lib/genstage_example.ex`

```elixir
. . .
    children = [
      worker(GenstageExample.Producer, []),
      worker(GenstageExample.Consumer, [], id: 1),
      worker(GenstageExample.Consumer, [], id: 2),
    ]
. . .
```
[working commit](https://github.com/ybur-yug/genstage_example/commit/eb2e3a66254c9af053150996f4e9657363624b04)

Now, let's fire up IEx again:

```elixir
$ iex -S mix
iex(1)> {#PID<0.205.0>, 0, :state_doesnt_matter}
{#PID<0.205.0>, 1, :state_doesnt_matter}
{#PID<0.205.0>, 2, :state_doesnt_matter}
{#PID<0.207.0>, 3, :state_doesnt_matter}
. . .
```

As you can see, we have multiple PIDs now, simply by adding a line of code and giving our consumers IDs.
But we can take this even further:

```elixir
. . .
    children = [
      worker(GenstageExample.Producer, []),
    ]
    consumers = for id <- 1..(System.schedulers_online * 12) do
                              # helper to get the number of cores on machine
                  worker(GenstageExample.Consumer, [], id: id)
                end

    opts = [strategy: :one_for_one, name: GenstageExample.Supervisor]
    Supervisor.start_link(children ++ consumers, opts)
. . .
```
[working commit](https://github.com/ybur-yug/genstage_example/commit/981ace6631fb7c8a83f0e482d6d2a21b01f48612)

What we are doing here is quite simple.
First, we get the number of core on the machine with `System.schedulers_online/0`, and from there we simply create a worker just like we had.
Now we have 12 workers per core. This is much more effective.

```elixir
. . .
{#PID<0.229.0>, 63697, :state_doesnt_matter}
{#PID<0.224.0>, 53190, :state_doesnt_matter}
{#PID<0.223.0>, 72687, :state_doesnt_matter}
{#PID<0.238.0>, 69688, :state_doesnt_matter}
{#PID<0.196.0>, 62696, :state_doesnt_matter}
{#PID<0.212.0>, 52713, :state_doesnt_matter}
{#PID<0.233.0>, 72175, :state_doesnt_matter}
{#PID<0.214.0>, 51712, :state_doesnt_matter}
{#PID<0.227.0>, 66190, :state_doesnt_matter}
{#PID<0.234.0>, 58694, :state_doesnt_matter}
{#PID<0.211.0>, 55694, :state_doesnt_matter}
{#PID<0.240.0>, 64698, :state_doesnt_matter}
{#PID<0.193.0>, 50692, :state_doesnt_matter}
{#PID<0.207.0>, 56683, :state_doesnt_matter}
{#PID<0.213.0>, 71684, :state_doesnt_matter}
{#PID<0.235.0>, 53712, :state_doesnt_matter}
{#PID<0.208.0>, 51197, :state_doesnt_matter}
{#PID<0.200.0>, 61689, :state_doesnt_matter}
. . .
```

Though we lack any ordering like we would have with a single core, but every increment is being hit and processed.

We can take this a step further and change our broadcasting strategy from the default in our producer:

```elixir
. . .
  def init(counter) do
    {:producer, counter, dispatcher: GenStage.BroadcastDispatcher}
  end
. . .
```
[working commit](https://github.com/ybur-yug/genstage_example/commit/87c5f96c74e8fa90cd5b5fd108cd9ba104f78a65)

What this does is it accumulates demand from all consumers before broadcasting its events to all of them.
If we fire up IEx we can see the implication:

```elixir
. . .
{#PID<0.200.0>, 1689, :state_doesnt_matter}
{#PID<0.230.0>, 1690, :state_doesnt_matter}
{#PID<0.196.0>, 1679, :state_doesnt_matter}
{#PID<0.215.0>, 1683, :state_doesnt_matter}
{#PID<0.237.0>, 1687, :state_doesnt_matter}
{#PID<0.205.0>, 1682, :state_doesnt_matter}
{#PID<0.206.0>, 1695, :state_doesnt_matter}
{#PID<0.216.0>, 1682, :state_doesnt_matter}
{#PID<0.217.0>, 1689, :state_doesnt_matter}
{#PID<0.233.0>, 1681, :state_doesnt_matter}
{#PID<0.223.0>, 1689, :state_doesnt_matter}
{#PID<0.193.0>, 1194, :state_doesnt_matter}
. . .
```

Note that some numbers are showing twice now, this is why.


## Setting Up Postgres to Extend Our Producer 
To go further we'll need to bring in a database to store our progress and status.
This is quite simple using [Ecto](LINKTOLESSON).
To get started let's add it and the Postgresql adapter to `mix.exs`:

```elixir
. . .
  defp deps do
    [
     {:gen_stage, "~> 0.7"},
     {:ecto, "~> 2.0"},
     {:postgrex, "~> 0.12.1"},
    ]
  end
. . .

```

Fetch the dependencies and compile:

```shell
$ mix do deps.get, compile
```

And now we can add a repo for setup in `lib/repo.ex`:

```elixir
defmodule GenstageExample.Repo do
  use Ecto.Repo,
    otp_app: :genstage_example
end
```

and with this we can set up our config next in `config/config.exs`:

```elixir
use Mix.Config

config :genstage_example, ecto_repos: [GenstageExample.Repo]

config :genstage_example, GenstageExample.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "genstage_example",
  username: "your_username",
  password: "your_password",
  hostname: "localhost",
  port: "5432"
```

And if we add a supservisor to `lib/genstage_example.ex` we can now start working with the DB:

```elixir
. . .
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(GenstageExample.Repo, []),
      worker(GenstageExample.Producer, []),
    ]
  end
. . .
```

But we should also make an interface to do that, so let's import our query interface and repo to the producer:

```elixir
. . .
  import Ecto.Query
  import GenstageExample.Repo
. . .
```

Now we need to create our migration:

```shell
$ mix ecto.gen.migration setup_tasks status:text payload:binary
```

Now that we have a functional database, we can start storing things.
Let's remove our change in Broadcaster, as we only were doing that to demonstrate that there are others outside the normal default in our Producer.

```elixir
. . .
  def init(counter) do
    {:producer, counter}
  end
. . .
```

### Modelling the Rest of the Functionality

Now that we have all this boilerplate work completed we should come up with a model to run all of this now that we have a simple wired-together producer/consumer model.
At the end of the day we are trying to make a task runner.
To do this, we probably want to abstract the interface for tasks and DB interfacing into their own modules.
To start, let's create our `Task` module to model our actual tasks to be run:

```elixir
defmodule GenstageExample.Task do
  def enqueue(status, payload) do
    GenstageExample.TaskDBInterface.insert_tasks(status, payload)
  end

  def take(limit) do
    GenstageExample.TaskDBInterface.take_tasks(limit)
  end
end
```

This is a _really_ simple interface to abstract a given task's functionality.
We only have 2 functions.
Now, the module they are calling doesn't exist yet, it gives us the ideas we need to build a very simple interface. 
These can be broken down as follows:

1. `enqueue/2` - Enqueue a task to be run
3. `take/1` - Take a given number of tasks to run from the database

Now this gives us the interface we need: we can set things to be run, and grab tasks to be run and we can define the rest of the interface.
Let's create an interface with our database in its own module:

```elixir
defmodule GenstageExample.TaskDBInterface do
  import Ecto.Query

  def take_tasks(limit) do
    {:ok, {count, events}} =
      GenstageExample.Repo.transaction fn ->
        ids = GenstageExample.Repo.all waiting(limit)
        GenstageExample.Repo.update_all by_ids(ids), [set: [status: "running"]], [returning: [:id, :payload]]
      end
    {count, events}
  end

  def insert_tasks(status, payload) do
    GenstageExample.Repo.insert_all "tasks", [
      %{status: status, payload: payload}
    ]
  end

  def update_task_status(id, status) do
    GenstageExample.Repo.update_all by_ids([id]), set: [status: status]
  end

  defp by_ids(ids) do
    from t in "tasks", where: t.id in ^ids
  end

  defp waiting(limit) do
    from t in "tasks",
      where: t.status == "waiting",
      limit: ^limit,
      select: t.id,
      lock: "FOR UPDATE SKIP LOCKED"
  end
end
```

This one is a bit more complex, but we'll break it down piece by piece.
We have 3 main functions, and 2 private helpers:

#### Main Functions
1. `take_tasks/1`
2. `insert_tasks/2`
3. `update_task_status/2`

With `take_tasks/1` we have the bulk of our logic.
This function will be called to grab tasks we have queued to run them.
Let's look at the code:

```elixir
. . .
  def take_tasks(limit) do
    {:ok, {count, events}} =
      GenstageExample.Repo.transaction fn ->
        ids = GenstageExample.Repo.all waiting(limit)
        GenstageExample.Repo.update_all by_ids(ids), [set: [status: "running"]], [returning: [:id, :payload]]
      end
    {count, events}
  end
. . .
```

We do a few things here.
First, we go in and we wrap everything in a transaction.
This maintains state in the database so we avoid race conditions and other bad things.
Inside here, we get the ids of all tasks waiting to be executed up to some limit, and set them to `running` as their status.
We return the `count` of total tasks and the events to be run in the consumer.

Next we have `insert_tasks/2`:

```elixir
. . .
  def insert_tasks(status, payload) do
    GenstageExample.Repo.insert_all "tasks", [
      %{status: status, payload: payload}
    ]
  end
. . .
```

This one is a bit more simple.
We just insert a task to be run with a given payload binary.

Finally, we have `update_task_status/2`, which is also quite simple:

```elixir
. . .
  def update_task_status(id, status) do
    GenstageExample.Repo.update_all by_ids([id]), set: [status: status]
  end
. . .
```

Here we simple update tasks to the status we want using a given id.

#### Helpers
Our helpers are all called primarily inside of `take_tasks/1`, but also used elsewhere in the main public API.

```elixir
. . .
  defp by_ids(ids) do
    from t in "tasks", where: t.id in ^ids
  end

  defp waiting(limit) do
    from t in "tasks",
      where: t.status == "waiting",
      limit: ^limit,
      select: t.id,
      lock: "FOR UPDATE SKIP LOCKED"
  end
. . .
```

Neither of these has a ton of complexity.
`by_ids/1` simply grabs all tasks that match in a given list of IDs.

`waiting/1` finds all tasks that have the status waiting up to a given limit.
However, there is one note to make on `waiting/1`.
We leverage a lock on all tasks being updated so we skip those, a feature available in psql 9.5+.
Outside of this, it is a very simple `SELECT` statement.

Now that we have our DB interface defined as it is used in the primary API, we can move onto the producer, consumer, and last bits of configuration.

### Producer, Consumer, and Final Configuration

#### Final Config
We will need to do a bit of configuration in `lib/genstage_example.ex` to clarify things as well as give us the final functionalities we will need to run jobs.
This is what we will end up with:

```elixir
. . .
  def start(_type, _args) do
    import Supervisor.Spec, warn: false
                          # 12 workers / system core
    consumers = for id <- (0..System.schedulers_online * 12) do
                  worker(GenstageExample.Consumer, [], id: id)
                end
    producers = [
                 worker(Producer, []),
                ]

    supervisors = [
                    supervisor(GenstageExample.Repo, []),
                    supervisor(Task.Supervisor, [[name: GenstageExample.TaskSupervisor]]),
                  ]
    children = supervisors ++ producers ++ consumers

    opts = [strategy: :one_for_one, name: GenstageExample.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def start_later(module, function, args) do
    payload = {module, function, args} |> :erlang.term_to_binary
    Repo.insert_all("tasks", [
                              %{status: "waiting", payload: payload}
                             ])
    notify_producer
  end

  def notify_producer do
    send(Producer, :data_inserted)
  end

  defdelegate enqueue(module, function, args), to: Producer
. . .
```

Let's tackle this from the top down.
First, `start/2`:

```elixir
. . .
  def start(_type, _args) do
    import Supervisor.Spec, warn: false
                          # 12 workers / system core
    consumers = for id <- (0..System.schedulers_online * 12) do
                  worker(GenstageExample.Consumer, [], id: id)
                end
    producers = [
                 worker(Producer, []),
                ]

    supervisors = [
                    supervisor(GenstageExample.Repo, []),
                    supervisor(Task.Supervisor, [[name: GenstageExample.TaskSupervisor]]),
                  ]
    children = supervisors ++ producers ++ consumers

    opts = [strategy: :one_for_one, name: GenstageExample.Supervisor]
    Supervisor.start_link(children, opts)
  end
. . .
```
First of all, you will notice we are now defining producers, consumers, and supervisors separately.
I find this convention to work quite well to illustrate the intentions of various processes and trees we are starting here.
In these 3 lists we set up 12 consumers / CPU core, set up a single producer, and then our supervisors for the Repo, as well as one new one.

This new supervisor is run through `Task.Supervisor`, which is built into Elixir.
We give it a name so it is easily referred to in our GenStage code, `GenstageExample.TaskSupervisor`.
Now, we define our children as the concatenation of all these lists.

Next, we have `start_later/3`:

```elixir
. . .
  def start_later(module, function, args) do
    payload = {module, function, args} |> :erlang.term_to_binary
    Repo.insert_all("tasks", [
                              %{status: "waiting", payload: payload}
                             ])
    notify_producer
  end
. . .
```
This function takes a module, a function, and an argument.
It then encodes them as a binary using some built-in erlang magic.
From here, we then insert the task as `waiting`, and we notify a producer that a task has been inserted to run.

Now let's check out `notify_producer/0`:

```elixir
. . .
  def notify_producer do
    send(Producer, :data_inserted)
  end
. . .
```

This method is quite simple.
We send our producer a message, `:data_inserted`, simply so that it knows what we did.
The message here is arbitrary, but I chose this atom to make the meaning clear.

Last, but not least we do some simple delegation:

```
. . .
  defdelegate enqueue(module, functions, args), to : Producer
. . .
```
This simply makes it so if we call `GenstageExample.enqueue(module, function, args)` that it will be delegated to the same method in our producer.

### Producer Setup
Our producer doesn't need a ton of work.
first, we'll alter our `handle_demand/2` to actually do something with our events:

```elixir
. . .
  def handle_demand(demand, state) when demand > 0 do
    serve_jobs(demand + state)
  end
. . .
```

We haven't defined `serve_jobs/2` yet, but we'll get there.
The concept is simple, when we get a demand and demand is > 0, we do some work to the tune of demand + the current state's number of jobs.

Now that we will be sending a message to the producer when we run `start_later/3`, we will want to respond to it with a `handle_info/2` call:

```elixir
. . .
  def handle_info(:enqueued, state) do
    {count, events} = GenstageExample.Task.take(state)
    {:noreply, events, state - count}
  end
. . .
```

With this, we simply respond by taking the number of tasks we are told to get ready to run.

Now let's define `serve_jobs/1`:

```elixir
. . .
  def serve_jobs limit do
    {count, events} = GenstageExample.Task.take(limit)
    Process.send_after(@name, :enqueued, 60_000)
    {:noreply, events, limit - count}
  end
. . .
```

Now, we are sending a process in one minute that to our producer telling it that it should respond to `:enqueued`.
Note that we call the process module with `@name`, which we will need to add at the top as a module attribute:

```elixir
. . .
  @name __MODULE__
. . .
```

Let's define that last function to handle the `:enqueued` message now, too:

```elixir
. . .
  def handle_cast(:enqueued, state) do
    serve_jobs(state)
  end
. . .
```

This will simply serve jobs when we tell the producer they have `state` number of enqueued and to respond.

## Setting Up the Consumer for Real Work
Our consumer is where we do the work.
Now that we have our producer storing tasks, we want to have the consumer handle this as well.
There is a good bit of work to be done here tying into our work so far.
The core of the consumer is `handle_events/3`, lets flesh out the functionality we wish to have there and define it as we go further:


```elixir
. . .
  def handle_events(events, _from, state) do
    for event <- events do
      %{id: id, payload: payload} = event
      {module, function, args} = payload |> deconstruct_payload
      task = start_task(module, function, args)
      yield_to_and_update_task(task, id)
    end
    {:noreply, [], state}
  end
. . .
```

At its core, this setup simple just wants to run a task we decode the binary of.
To do this we get the data from the event, deconstruct it, and then start and yield to a task.
These functions aren't defined yet, so let's create them:


```elixir
. . .
  def deconstruct_payload payload do
    payload |> :erlang.binary_to_term
  end
. . .
```
We can use Erlang's built-in inverse of our other `term_to_binary/1` function to get our module, function, and args back out.
Now we need to start the task:

```elixir
. . .
  def start_task(mod, func, args) do
    Task.Supervisor.async_nolink(TaskSupervisor, mod, func, args)
  end
. . .
```

Here we leverage the supervisor we created at the beginning to run this in a task.
Now we need to define `yield_to_and_update_task/2`:

```elixir
. . .
  def yield_to_and_update_task(task, id) do
    task
    |> Task.yield(1000)
    |> yield_to_status(task)
    |> update(id)
  end
. . .
```

Now this brings in more pieces we've yet to define, but the core is simple.
We wait 1 second for the task to run.
From here, we respond to the status it returns (which will either be `:ok`, `:exit`, or `nil`) and handle it as such.
After that we update our task via our DB interface to get things current.
Let's define `yield_to_status/2` for each of the scenarios we mentioned:

```elixir
. . .
  def yield_to_status({:ok, _}, _) do
    "success"
  end

  def yield_to_status({:exit, _}, _) do
    "error"
  end

  def yield_to_status(nil, task) do
    Task.shutdown(task)
    "timeout"
  end
. . .
```
These simple handle the atom being returned from the process and respond appropriately.
If it takes more than a second, we need to shut it down because otherwise it would just hang forever.

From this, we can see our finalized consumer:

```elixir
defmodule GenstageExample.Consumer do
  alias Experimental.GenStage
  use GenStage
  alias GenstageExample.{Producer, TaskSupervisor}

  def start_link do
    GenStage.start_link(__MODULE__, :state_doesnt_matter)
  end

  def init(state) do
    {:consumer, state, subscribe_to: [Producer]}
  end

  def handle_events(events, _from, state) do
    for event <- events do
      %{id: id, payload: payload} = event
      {module, function, args} = payload |> deconstruct_payload
      task = start_task(module, function, args)
      yield_to_and_update_task(task, id)
    end
    {:noreply, [], state}
  end

  defp yield_to_and_update_task(task, id) do
    task
    |> Task.yield(1000)
    |> yield_to_status(task)
    |> update(id)
  end

  defp start_task(mod, func, args) do
    Task.Supervisor.async_nolink(TaskSupervisor, mod  , func, args)
  end

  defp yield_to_status({:ok, _}, _) do
    "success"
  end

  defp yield_to_status({:exit, _}, _) do
    "error"
  end

  defp yield_to_status(nil, task) do
    Task.shutdown(task)
    "timeout"
  end

  defp update(status, id) do
    GenstageExample.TaskDBInterface.update_task_status(id, status)
  end

  defp deconstruct_payload payload do
    payload |> :erlang.binary_to_term
  end
end
```

Now, if we go into IEx:

```elixir
$ iex -S mix
iex> GenstageExample.enqueue(IO, :puts, ["wuddup"])
#=> 
16:39:31.014 [debug] QUERY OK db=137.4ms
INSERT INTO "tasks" ("payload","status") VALUES ($1,$2) [<<131, 104, 3, 100, 0, 9, 69, 108, 105, 120, 105, 114, 46, 73, 79, 100, 0, 4, 112, 117, 116, 115, 108, 0, 0, 0, 1, 109, 0, 0, 0, 6, 119, 117, 100, 100, 117, 112, 106>>, "waiting"]
:ok

16:39:31.015 [debug] QUERY OK db=0.4ms queue=0.1ms
begin []

16:39:31.025 [debug] QUERY OK source="tasks" db=9.6ms
SELECT t0."id" FROM "tasks" AS t0 WHERE (t0."status" = 'waiting') LIMIT $1 FOR UPDATE SKIP LOCKED [49000]

16:39:31.026 [debug] QUERY OK source="tasks" db=0.8ms
UPDATE "tasks" AS t0 SET "status" = $1 WHERE (t0."id" = ANY($2)) RETURNING t0."id", t0."payload" ["running", [5]]

16:39:31.040 [debug] QUERY OK db=13.5ms
commit []
iex(2)> wuddup

16:39:31.060 [debug] QUERY OK source="tasks" db=1.3ms
UPDATE "tasks" AS t0 SET "status" = $1 WHERE (t0."id" = ANY($2)) ["success", [5]]
```

It works and we are storing and running tasks!

## TODO publish to hex

[Here](https://github.com/ybur-yug/genstage_example/tree/87c5f96c74e8fa90cd5b5fd108cd9ba104f78a65) is a link to all code thus far.

