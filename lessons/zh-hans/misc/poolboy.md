%{
version: "1.2.1",
title: "Poolboy",
excerpt: """
如果你不限制你的程序可以产生的最大并发进程数，你会很容易耗尽你的系统资源。
[Poolboy](https://github.com/devinus/poolboy) 就是为了解决这个问题，在 Erlang 下被广泛使用的轻量级，通用进程池程序库。
"""
}

---

## 为什么使用 Poolboy？

让我们先想一个具体的例子。你的任务是构建一个将用户资料信息保存到数据库的应用程序。如果你为每个用户的注册创建了一个进程，你将会创建一个无限制数量的连接。在某些时候，这些连接的数量会超过你的数据库服务器的容量。最终你的应用程序会出现超时和各种异常。

解决办法是使用一组 worker 进程来限制连接数，而不是为每个用户注册创建一个进程。这样你就可以轻松避免系统资源的耗尽。

这就是 Poolboy 的作用。它允许你轻松地建立一个由 `Supervisor` 管理的工作池，而不需要你做很多努力。有很多库都在暗中使用 Poolboy。例如，`redis_poolex` _（Redis 连接池）_ 就是一个使用 Poolboy 的流行库。

## 安装

通过 mix，安装简直易如反掌。我们需要做的就是把 Poolboy 添加到 `mix.exs` 的依赖配置里面。

让我们先来创建一个应用：

```shell
mix new poolboy_app --sup
```

把 Poolboy 添加到 `mix.exs` 的依赖配置里面。

```elixir
defp deps do
  [{:poolboy, "~> 1.5.1"}]
end
```

然后获取依赖项，包括 Poolboy。

```shell
mix deps.get
```

## 配置选项

使用 Poolboy 前，我们还是要了解一些它的各种配置选项。

- `:name` - 池子名称。范围（Scope）可以是 `:local`，`:global` 或者 `:via`。
- `:worker_module` - 代表 worker 的模块。
- `:size` - 最大池子数。
- `:max_overflow` - 当池子为空的时候，可创造的最大临时 worker 数。（可选）
- `:strategy` - `:lifo` 或 `:fifo`，决定了回收到池子的 worker 进程，是放到可用 worker 进程队列的开头还是结尾。默认值为 `:lifo`。（可选）

## 配置 Poolboy

在这个例子中，我们会创建一个负责处理计算平方根请求的 worker 进程池。我们将例子尽量简化以便于我们关注在 Poolboy 上面。

让我们先配置 Poolboy 选项，并把 Poolboy worker 进程池添加到我们的应用中作为一个子进程。编辑 `lib/poolboy_app/application.ex` 如下：

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

最开始定义的是进程池的配置选项。进程池的名字设置为 `:worker`，`:scope` 设为 `:local`。然后我们指派 `PoolboyApp.Worker` 模块作为 `:worker_module`。进程池的大小通过 `:size` 设置为 5。同时，通过配置 `:max_overflow` 选项，我们还可以让进程池在 worker 进程繁忙的情况下，最多创建两个额外的 worker。_（`overflow` workers 完成工作后会被销毁。）_

接下来，我们把 `:poolboy.child_spec/2` 函数添加到 children 数组中，以便它随着应用的启动而启动。这个函数接收两个参数：进程池名字，以及它的配置。

## 创建 Worker

Worker 模块只是一个简单的 `GenServer`。它计算平方根，sleep 一秒，然后打印出 worker 的 pid。创建 `lib/poolboy_app/worker.ex`：

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

## Poolboy 的使用

现在我们已经有了 `PoolboyApp.Worker`，就可以测试 Poolboy 了。我们先创建一个简单的，使用 Poolboy 创建并发进程的模块。`:poolboy.transaction/3` 是可以和 worker 进程池交互的函数。创建 `lib/poolboy_app/test.ex`：

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

运行测试函数，查看结果：

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

如果进程池已经把 worker 进程耗尽了，Poolboy 就会在默认的超时时间（5 秒）后丢出超时错误，并不再接收任何新的请求。在我们的例子中，我们把默认的超时时间增加到一分钟，以便演示我们如何改变默认的超时值。你如果把 `@timeout` 修改到小于 1000，就能观察到错误。

即使我们试图创建多个进程*（在上面的例子中共有 20 个）* `:poolboy.transaction/3`函数将限制创建进程的最大数量为 5 个*（如果需要，加上两个溢出的 worker）*，正如我们在配置中定义的那样。所有的请求都将使用 worker 池来处理，而不是为每个请求创建一个新的进程。
