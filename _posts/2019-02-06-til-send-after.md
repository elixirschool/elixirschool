---
author: Sean Callan
author_link: https://github.com/doomspork
categories: til
date: 2019-02-07
layout: post
title:  TIL about `Process.send_after/4`
excerpt: >
  Want to schedule something to run later? Need a reoccurring task? Today we learn how!
---

Executing code later or creating reoccurring tasks can be tricky but did you know we can accomplish this in Elixir with just a process?
With a GenServer, `Process.send_after/4`, and the `handle_info/2` callback we have everything we need.

Let's look at `Process.send_after/4` and the expected arguments:

```elixir
send_after(dest, msg, time, opts \\ [])
```

- The `dest` argument takes the `pid` or name of our process, we'll use a named GenServer for our example.
- The `msg` we want sent to the process, this can be just about any data structure but we'll stick with a simple atom.
- Provided as milliseconds, `time` is how long until we want our message sent.
- Last but not least, options.

That's all well and good but where exactly does the `msg` go after `time` has elapsed?
Great question!

The less often used `handle_info/2` callback is how these messages are handled.
Just like `handle_cast/2`, `handle_info/2` takes two parmeters: the first will be our `msg` from above and second the current state.

That's enough to get us going but if you're interested to learn more about `Process.send_after/4` be sure to check out the [official documentation](https://hexdocs.pm/elixir/Process.html#send_after/4).

For the sake of demonstrating how to use our aforementioned tools to perform reoccurring work let's build a simple module to output the current time every 10 seconds.
Since we'll be working with a GenServer, we can rely on `init/1` as a good place to kick off our the reoccurring work using `Process.send_after/4` and a message of `:tick`:

```elixir
@ten_seconds 10000

def init(opts) do
  Process.send_after(self(), :tick, @ten_seconds)

  {:ok, opts}
end
```

Next we'll need to define our `handle_info/2` callback for our `:tick` message.
For this function we'll get and format the current time, output it, and mostly importantly trigger another `:tick` 10 seconds from now using `Process.send_after/4`:

```elixir
def handle_info(:tick, state) do
  time =
    DateTime.utc_now()
    |> DateTime.to_time()
    |> Time.to_iso8601()

  IO.puts("The time is now: #{time}")

  Process.send_after(self(), :tick, @ten_seconds)

  {:noreply, state}
end
```

When we bring it all together in our `Example` module we should have something like this:

```elixir
defmodule Example do
  use GenServer

  @ten_seconds 10000

  def init(opts) do
    Process.send_after(self(), :tick, @ten_seconds)

    {:ok, opts}
  end

  def handle_info(:tick, state) do
    time =
      DateTime.utc_now()
      |> DateTime.to_time()
      |> Time.to_iso8601()

    IO.puts("The time is now: #{time}")

    Process.send_after(self(), :tick, @ten_seconds)

    {:noreply, state}
  end
end
```

Without further delay let us put our new code to work!
Open `iex` and copy and paste our new module in.
Now we start everything with `GenServer.start/3` which will in turn start our clock messages:

```shell
iex> GenServer.start(Example, [])
{:ok, #PID<0.134.0>}
iex>
The time is now: 02:22:04.900603
The time is now: 02:22:14.904617
The time is now: 02:22:24.905600
The time is now: 02:22:34.906790
The time is now: 02:22:44.907672
The time is now: 02:22:54.908688
The time is now: 02:23:04.909642
The time is now: 02:23:14.910623
```

Tada!
Every 10 seconds we see an updated time.
No CRON, no background job framework, no external dependencies, just Elixir.
