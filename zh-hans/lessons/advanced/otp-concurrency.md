---
version: 1.1.3
title: OTP 并发
---

我们已经看过了 Elixir 层的并发抽象机制，但有时候我们需要更多的控制，那就要了解 Elixir 底层的东西：OTP 行为（behaviors）。

在这一课中，我们将专注于最大的一块：Genservers。

{% include toc.html %}

# GenServer
OTP server 是一个模块，包含了 Genserver 的主要行为，外加一系列的 callbacks。Genserver 最核心的内容是这样一个循环：每次迭代处理一个带有目标状态的请求。

为了演示 Genserver 的 API，我们将实现一个简单的 queue，来存储和获取值。

最开始，我们要先启动和初始化 Genserver，一般情况下，我们需要链接进程，所以还要使用 `Genserver.start_link/3`。传递给 Genserver 的参数包括：我们所在的模块，初始状态，以及其他 Genserver 参数。`Genserver.init/1` 的参数用来设置初始的状态，比如在下面的例子中，初始状态为 []:

```elixir
defmodule SimpleQueue do
  use GenServer

  @doc """
  Start our queue and link it.  This is a helper function
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

## 同步函数

有时候需要和 Genservers 进行同步的交互：调用一个函数，然后等待它的响应返回。要处理同步请求，我们需要实现 `Genserver.handle_call/3` 函数，接受的参数是：请求、调用者的 PID，初始的状态，期望的返回值是 `{:reply, response, state}` 三元组。

使用模式匹配，我们可以为不同的请求和状态定义不同的 callbacks，能够接受的所有返回值列表可以前往 [`Genserver.handle_call/3`](https://hexdocs.pm/elixir/GenServer.html#c:handle_call/3) 文档处查看。

为了演示同步请求，我们添加这样的功能：返回现在队列的状态以及删除队列中的一个值：

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
  def handle_call(:dequeue, _from, [value | state]) do
    {:reply, value, state}
  end

  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  ### Client API / Helper functions

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```

我们来测试一下 SimpleQueue 刚完成的 dequeue 功能：

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

## 异步函数

`handle_cast/2` 是处理异步函数的，  这个函数和 `handle_call/3` 的用法一样，除了它不接受调用者作为参数而且没有返回值。

我们把 enqueue 功能设计成异步的：更新 queue 的内容，但并不阻塞当前程序的运行：

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
  def handle_call(:dequeue, _from, [value | state]) do
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

  ### Client API / Helper functions

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def enqueue(value), do: GenServer.cast(__MODULE__, {:enqueue, value})
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```

现在使用一下这个新功能：

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

可以前往官方的 [`GenServer`](https://hexdocs.pm/elixir/GenServer.html#content) 文档了解更多的信息。
