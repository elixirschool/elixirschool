%{
  version: "1.1.1",
  title: "并发",
  excerpt: """
  Elixir 的一大卖点就是对并发的支持。得益于 Erlang VM (BEAM)，Elixir 的并发要比预期中简单得多。这个并发模型的基础是 Actors：通过消息传递来交互的进程（译者注：这个进程不是通常所说的操作系统级别的进程，可以理解为 Erlang VM (BEAM) 自己管理的轻量级进程）。

这节课，我们会讲 Elixir 自带的并发模型。在后面的章节中，我们还会介绍底层的实现机制：OTP 行为（behaviors）。
  """
}
---

## 进程

Erlang VM (BEAM) 的进程很轻量级，可以运行在所有 CPU 上。看起来有点像原生的线程，但是它们更简单，而且同时运行几千个 Elixir 进程也是常事。

创建一个新进程最简单的方法是 `spawn`：它接受匿名函数或者命名函数作为参数。当你创建了一个新的进程，它会返回一个 _进程标示符_ ，或者说 PID，在系统里来唯一确定这个进程。

我们来新建一个模块，然后定义一个要运行的函数：

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

要异步运行这个函数，我们可以使用 `spawn/3`：

```elixir
iex> spawn(Example, :add, [2, 3])
5
#PID<0.80.0>
```

### 消息传递

进程之间通信要依靠消息传递。有两个主要的组件做消息传递：`send/2` 和 `receive`。`send/2` 函数允许我们向 PIDs 发送消息，使用 `receive` 监听和匹配消息，如果没有匹配的消息，运行会一直处于不中断的状态。

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

你可能注意到 `listen/0` 函数是递归的，这样可以让一个进程处理多个消息。如果没有递归调用，上面的进程处理完第一个消息就会退出。

### 进程链接

当进程崩溃的时候，`spawn` 就会有问题（译者注：父进程不知道子进程出错会导致程序异常）。为了解决这个问题，我们可以用 `spawn_link` 把进程链接起来。两个链接起来的进程能收到相互的退出通知。

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)
end

iex> spawn(Example, :explode, [])
#PID<0.66.0>

iex> spawn_link(Example, :explode, [])
** (EXIT from #PID<0.57.0>) evaluator process exited with reason: :kaboom
```

有时候我们不希望链接的进程导致当前进程跟着崩溃，这时候就要通过 `Process.flag/2` 函数捕捉进程的错误退出。这个函数用 Erlang 的 [process_flag/2](http://erlang.org/doc/man/erlang.html#process_flag-2) 的 `trap_exit` 信号。当捕获到被链接的进程发生错误退出时（`trap_exit` 设为 `true`）, 就会收到像 `{:EXIT, from_pid, reason}` 这样的三元组形式的退出信号。

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

### 进程监控

如果我们不想链接两个进程，但仍然希望能有错误信息通知呢？要做到这个，我们可以使用 `spawn_monitor`。当我们监控一个进程的时候，被监控进程崩溃的时候我们会接收到消息，而且不需要去捕获异常，也不会导致当前进程崩溃。

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

## Agent

Agent 是后台运行的可以保存状态进程的抽象，我们可以在应用和节点中的进程中获取它的状态。Agent 的状态被设置成函数的返回值：

```elixir
iex> {:ok, agent} = Agent.start_link(fn -> [1, 2, 3] end)
{:ok, #PID<0.65.0>}

iex> Agent.update(agent, fn (state) -> state ++ [4, 5] end)
:ok

iex> Agent.get(agent, &(&1))
[1, 2, 3, 4, 5]
```

如果我们给 Agent 命名，后面就可以用名字而不是 PID 来指代它：

```elixir
iex> Agent.start_link(fn -> [1, 2, 3] end, name: Numbers)
{:ok, #PID<0.74.0>}

iex> Agent.get(Numbers, &(&1))
[1, 2, 3]
```

## Task

Task 提供了一种方式在后台执行一个函数，并且可以后面再获取它的返回值。在处理耗时操作的时候，tasks 会很有用，因为它们不阻塞当前的程序。

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
