%{
  author: "Bobby Grayson",
  author_link: "",
  date: ~D[2019-02-21],
  tags: ["OTP", "supervisors"],
  title: "Elixir Supervisor Strategies",
  excerpt: """
  Learn the ins and outs of Elixir's 3 supervisor strategies
  """
}

---

One of the things that makes OTP and Elixir unique is the model of supervisor behaviour that applications can take with different processes they start.
In this post we will examine each of the three available in Elixir by making a supervised app.

To start, we make a supervised application:

```
mix new counter --sup
cd counter
```

Now that we have an app, we are going to create 3 modules.
They will all be GenServers that are started with the application who send themselves a message every second to increment their state by one.
One will always work, one will fail every 6 messages, and one will fail every 20 messages.
To start, it will have the default supervisory strategy of `one_for_one` in `application.ex`.
This strategy says that if one process dies, its siblings should stay working unaffected.

**Note: No matter your supervisory strategy, if the children in your app do not succeed on ```start_link``` and return an ```{:ok, pid}``` tuple, the application as a whole will not start and your supervisory strategy does not matter at all.**

We will stick with that in the beginning.

Let's start with the first module in `lib/counter/one.ex`.
It will fail if its state is 22.

```elixir
defmodule Counter.One do
  use GenServer

  def start_link(_state \\ 0) do
    IO.inspect("starting", label: "Counter.One")
    success = GenServer.start_link(__MODULE__, 0)
    IO.inspect("started", label: "Counter.One")
    success
  end

  @impl true
  def init(state) do
    work(state)
    # Schedule work to be performed on start
    schedule_work()
    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    work(state)
    # Reschedule once more
    schedule_work()
    {:noreply, state + 1}
  end

  defp schedule_work() do
    Process.send_after(self(), :work, 1000)
  end

  def work(state) do
    case state do
      22 -> raise "I'm Counter.One and I'm gonna error now"
      _ -> IO.inspect("working and my state is #{state}", label: "Counter.One")
    end
  end
end
```

Note:
This is slight modification of a [great example from the GenServer docs](https://hexdocs.pm/elixir/GenServer.html#module-receiving-regular-messages).
Also see [this past Elixir School blog post](http://elixirschool.com/blog/til-send-after/) for more on `Process.send_after/3`.

Now, if we open `lib/counter/application.ex` and add it to children, we can get it to start with our app:

```elixir
defmodule Counter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      Counter.One
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Counter.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Now if we start the app, we will see it begin to work and fail at 22:

```
Counter.One: "working and my state is 18"
Counter.One: "working and my state is 19"
Counter.One: "working and my state is 20"
Counter.One: "working and my state is 21"
Counter.One: "starting"
Counter.One: "working and my state is 0"
Counter.One: "started"

18:27:42.566 [error] GenServer #PID<0.119.0> terminating
** (RuntimeError) I'm Counter.One and I'm gonna error now
    (one) lib/counter/one.ex:33: Counter.One.work/1
    (one) lib/counter/one.ex:21: Counter.One.handle_info/2
    (stdlib) gen_server.erl:616: :gen_server.try_dispatch/4
    (stdlib) gen_server.erl:686: :gen_server.handle_msg/6
    (stdlib) proc_lib.erl:247: :proc_lib.init_p_do_apply/3
Last message: :work
State: 22
Counter.One: "working and my state is 0"
Counter.One: "working and my state is 1"
```
This fails because we made a specific clause to coerce failure by raising an error when the state reached `22` in our counter.
It is restarted with a state 0 (the default) after this failure.

Now lets make another module that will never fail:
```elixir
defmodule Counter.Two do
  use GenServer

  def start_link(_state \\ 0) do
    IO.inspect("starting", label: "Counter.Two")
    success = GenServer.start_link(__MODULE__, 0)
    IO.inspect("started", label: "Counter.Two")
    success
  end

  @impl true
  def init(state) do
    work(state)
    # Schedule work to be performed on start
    schedule_work()
    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    work(state)
    # Reschedule once more
    schedule_work()
    {:noreply, state + 1}
  end

  defp schedule_work() do
    Process.send_after(self(), :work, 1000)
  end

  def work(state) do
    IO.inspect("working and my state is #{state}", label: "Counter.Two")
  end
end
```

We can add it to `lib/counter/application.ex` as well.

```elixir
  # ...
  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      Counter.One,
      Counter.Two
    ]
  end
  # ...
```

Now, for our third and final module that will fail if state is `5`.

```elixir
defmodule Counter.Three do
  use GenServer

  def start_link(_state \\ 0) do
    IO.inspect("starting", label: "Counter.Three")
    success = GenServer.start_link(__MODULE__, 0)
    IO.inspect("started", label: "Counter.Three")
    success
  end

  @impl true
  def init(state) do
    work(state)
    # Schedule work to be performed on start
    schedule_work()
    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    work(state)
    # Reschedule once more
    schedule_work()
    {:noreply, state + 1}
  end

  defp schedule_work() do
    Process.send_after(self(), :work, 1000)
  end

  def work(state) do
    case state do
      5 -> raise "I'm Counter.Three and I'm gonna error now"
      _ -> IO.inspect("working and my state is #{state}", label: "Counter.Three")
    end
  end
end
```

We can add it to `lib/counter/application.ex` in the list of children, last after the other two:

```elixir
  # ...
  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      Counter.One,
      Counter.Two,
      Counter.Three
    ]
  end
  # ...
```

## One For One
Now, let's start our application and see the failure behaviour and state for each GenServer.
These logs are truncated to just the interesting parts.

```
Counter.One: "working and my state is 4"
Counter.Two: "working and my state is 4"
Counter.Three: "working and my state is 4"
Counter.One: "working and my state is 5"
Counter.Two: "working and my state is 5"
Counter.Three: "starting"
Counter.Three: "working and my state is 0"
Counter.Three: "started"

18:11:37.495 [error] GenServer #PID<0.130.0> terminating
** (RuntimeError) I'm Counter.Three and I'm gonna error now
    (counter) lib/counter/three.ex:33: Counter.Three.work/1
    (counter) lib/counter/three.ex:21: Counter.Three.handle_info/2
    (stdlib) gen_server.erl:616: :gen_server.try_dispatch/4
    (stdlib) gen_server.erl:686: :gen_server.handle_msg/6
    (stdlib) proc_lib.erl:247: :proc_lib.init_p_do_apply/3
Last message: :work
State: 5
Counter.One: "working and my state is 6"
Counter.Two: "working and my state is 6"
Counter.Three: "working and my state is 0"
Counter.One: "working and my state is 7"
Counter.Two: "working and my state is 7"
Counter.Three: "working and my state is 1"
```

So, we can see our first crash.
The process for `Counter.Three` failed with our raised error, and was restarted.
Because our default strategy in Elixir is `one_for_one`, this is expected.
In the default configuration, we dont want one child processes failure to effect any others.

If we let it continue to 22 with `Counter.One`, we would see the same behaviour (allow a crash without impacting any siblings, as its one for one).

## Rest For One
Now let's try it with `rest_for_one`.
Rest for one as a strategy starts the children in sequence, and if an earlier child fails the ones after it do too.
We want to change our line assigning `opts` in `lib/counter/application.ex` to state that.

```elixir
# ...
    children = [
      Counter.One,
      Counter.Two,
      Counter.Three
    ]

    opts = [strategy: :rest_for_one, name: Counter.Supervisor]
# ...
```

Now, let's start up again.
These logs are also truncated to the interesting part


```
Counter.One: "working and my state is 3"
Counter.Two: "working and my state is 3"
Counter.Three: "working and my state is 3"
Counter.One: "working and my state is 4"
Counter.Two: "working and my state is 4"
Counter.Three: "working and my state is 4"
Counter.One: "working and my state is 5"
Counter.Two: "working and my state is 5"
Counter.Three: "starting"

18:30:56.925 [error] GenServer #PID<0.134.0> terminating
** (RuntimeError) I'm Counter.Three and I'm gonna error now
    (counter) lib/counter/three.ex:33: Counter.Three.work/1
    (counter) lib/counter/three.ex:21: Counter.Three.handle_info/2
    (stdlib) gen_server.erl:616: :gen_server.try_dispatch/4
    (stdlib) gen_server.erl:686: :gen_server.handle_msg/6
    (stdlib) proc_lib.erl:247: :proc_lib.init_p_do_apply/3
Last message: :work
State: 5
Counter.Three: "working and my state is 0"
Counter.Three: "started"
Counter.One: "working and my state is 6"
Counter.Two: "working and my state is 6"
Counter.Three: "working and my state is 0"
Counter.One: "working and my state is 7"
Counter.Two: "working and my state is 7"
```

The key takeaway here is _order matters_.
Because `Counter.One` doesn't fail until `22` is its state, and `Counter.Three` fails with a state of `5`, `Counter.One` will force a restart of all 3 children since its first, but `Counter.Three`'s failures have no effect on its siblings.

## One For All
Now let's enable it with `one_for_all`.
In this supervisory model if one child fails, all must be restarted.
To do this lets change `lib/counter/application.ex` again.

```elixir
    opts = [strategy: :one_for_all, name: Counter.Supervisor]
```

If we start our app again with `iex -S mix` we can see the behaviour as soon as `Counter.Three` reaches a state of 5, but it again will confirm that it works the same again when we reach 22.

```
Counter.Two: "working and my state is 4"
Counter.One: "working and my state is 5"
Counter.Two: "working and my state is 5"
Counter.One: "starting"
Counter.One: "working and my state is 0"
Counter.One: "started"
Counter.Two: "starting"
Counter.Two: "working and my state is 0"
Counter.Two: "started"
Counter.Three: "starting"
Counter.Three: "working and my state is 0"
Counter.Three: "started"

18:34:56.122 [error] GenServer #PID<0.121.0> terminating
** (RuntimeError) I'm Counter.Three and I'm gonna error now
    (counter) lib/counter/three.ex:33: Counter.Three.work/1
    (counter) lib/counter/three.ex:21: Counter.Three.handle_info/2
    (stdlib) gen_server.erl:616: :gen_server.try_dispatch/4
    (stdlib) gen_server.erl:686: :gen_server.handle_msg/6
    (stdlib) proc_lib.erl:247: :proc_lib.init_p_do_apply/3
Last message: :work
State: 5
Counter.One: "working and my state is 0"
Counter.Two: "working and my state is 0"
Counter.Three: "working and my state is 0"
```

We could also change the order in the `children` variable match, and the same thing would happen.

That was a lot to take in, but hopefully the supervisory strategies of Elixir applications are a bit clearer now!
