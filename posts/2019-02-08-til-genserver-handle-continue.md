%{
  author: "Sophie DeBenedetto",
  author_link: "https://github.com/sophiedebenedetto",
  date: ~D[2019-02-15],
  tags: ["TIL"],
  title: "TIL GenServer's `handle_continue/2`",
  excerpt: """
  Support non-blocking, async GenServer initialization callbacks with OTP 21's nifty `handle_continue/2`!
  """
}

---

What happens when starting up your GenServer requires executing a long-running process? We _don't_ want the execution of that process to block the GenServer from completing start-up. We also don't want to execute that process asynchronously in a way that creates a race condition between the running of the process and other messages arriving in our GenServer's inbox. In this post, we'll take a closer look at these two problems and understand how OTP 21's `GenServer.handle_continue/2` is the perfect solution.

## Starting GenServers without Blocking
Let's say that we are building a GenServer for a shopping list fulfillment application. Our GenServer will hold state describing a grocery shopping list _and_ be aware of the available inventory as it relates to that shopping list. When our GenServer starts up, it will receive a shopping list and put it in state. But wait! Our GenServer initialization process will _then_ need to take that shopping list and retrieve relevant inventory from another source.

Our first attempt at solving this problem could look something like this:

```elixir
defmodule ShoppingListFulfillment do
  use GenServer

  def start_link(shopping_list) do
    GenServer.start_link(__MODULE__, shopping_list)
  end

  def init(shopping_list) do
    state = %{
      shopping_list: shopping_list,
      inventory: get_inventory_for(shopping_list)
    }
    {:ok, state}
  end

  defp get_inventory_for(shopping_list) do
    # something that could be time consuming!
    # like a web request or a database call
    # returns some inventory info for each item on the shopping list
  end
end
```
Here, we're calling our "get inventory for shopping list items" code in the `init/1` callback that gets triggered when `start_link/1` is called.

The problem with this approach is that `start_link/1` will block until `init/1` returns `{:ok, state}`. We won't return from `init/1` until _after_ the inventory-fetching code runs. That _could_ be time consuming. We don't want our GenServer blocked by this.

Let's explore an asynchronous approach.

## Asynchronous Callbacks and Race Conditions
We can use `Kernel.send/2` in our `init` callback to kick off some asynchronous work without blocking `GenServer.start_link/1`. When we use `send/2` and give it a first argument of `self`, i.e. the PID of our GenServer, our GenServer will handle that message with a `handle_info/2` function that matches the message we sent.

```elixir
defmodule ShoppingListFulfillment do
  use GenServer

  def start_link(shopping_list) do
    GenServer.start_link(__MODULE__, shopping_list)
  end

  def init(shopping_list) do
    state = %{
      shopping_list: shopping_list,
      inventory: []
    }
    send(self, :get_inventory)
    {:ok, state}
  end

  def handle_info(:get_inventory, %{shopping_list: shopping_list}) do
    inventory = get_inventory_for(shopping_list)
    state = %{
      shopping_list: shopping_list,
      inventory: inventory
    }
    {:noreply, state}
  end

  defp get_inventory_for(shopping_list) do
    # something that could be time consuming!
    # like a web request or a database call
    # returns some inventory info for each item on the shopping list
  end
end
```

This approach un-blocks `GenServer.start_link/1`. It no longer needs to _wait_ for the work of getting inventory. Now that happens asynchronously and updates state once we have finished fetching inventory info.

There is a downside to this approach though. Just because we send the `:get_inventory` message inside the `init` function, doesn't mean that `:get_inventory` is the first message our GenServer will receive and process. This could lead to a race condition!

What happens if our GenServer receives a message asking for the availability of an item on the shopping list _before_ it receives and finishes processing the message to get the inventory? That could cause a false negative! We would see that `inventory` in state is empty, and tell the sender that their item is not available. Oh no!

If only there was some way to fetch inventory asynchronously, without blocking `start_link/1`, while _still_ ensuring that it executes _before_ any other messages received by our GenServer are responded to...

## Using `handle_continue/2`

The release of OTP 21 a few months back gives us a way to solve this problem. The [`GenServer.handle_continue/2`](https://hexdocs.pm/elixir/GenServer.html#c:handle_continue/2) callback is called by a GenServer process whenever a previous callback returns `{:continue, :message}`.

> `handle_continue/2` is invoked immediately after the previous callback, which makes it useful for performing work after initialization or for splitting the work in a callback in multiple steps, updating the process state along the way. [*](http://erlang.org/doc/man/gen_server.html#Module:handle_continue-2)

This approach ensures that our GenServer won't handle any other messages until `handle_continue/2` is finished. No more race conditions!

Let's take a look:

```elixir
defmodule ShoppingListFulfillment do
  use GenServer

  def start_link(shopping_list) do
    GenServer.start_link(__MODULE__, shopping_list)
  end

  def init(shopping_list) do
    state = %{
      shopping_list: shopping_list,
      inventory: []
    }
    {:ok, state, {:continue, :get_inventory}}
  end

  def handle_continue(:get_inventory, %{shopping_list: shopping_list}) do
    inventory = get_inventory_for(shopping_list)
    state = %{
      shopping_list: shopping_list,
      inventory: inventory
    }
    {:noreply, state}
  end

  defp get_inventory_for(shopping_list) do
    # something that could be time consuming!
    # like a web request or a database call
    # returns some inventory info for each item on the shopping list
  end
end
```

Now, `init/2` returns `{:ok, state, {:continue, :get_inventory}}`. This immediately triggers the callback `handle_continue(:get_inventory, state)`. This callback is guaranteed to finish running before our GenServer moves on to processing any other messages.

## Conclusion

OTP 21's `handle_continue/2` callback allows us to handle expensive GenServer initialization work in a non-blocking, asynchronous manner that avoids race conditions. If you're building a GenServer that needs to handle an initialization callback, consider reaching for `handle_continue/2`.
