---
version: 1.2.0
title: Poolboy
---

如果不控制好程序创建的最大并行进程数，系统资源很容易就会耗尽。[Poolboy](https://github.com/devinus/poolboy) 就是为了解决这个问题，在 Erlang 下被广泛使用的轻量级，通用进程池程序库。

{% include toc.html %}

## 为什么需要 Poolboy？

让我们来考虑一下这个例子。你的任务是打造一个保存用户资料到数据库的应用。如果你为每个用户的注册操作都创建一个进程，最终可能会导致大量的数据库连接被创建出来。到了某一时刻，它可能就超过了数据库的承载能力。最终，你的应用也会抛出连接超时，和其它各种异常。

解决的方案是，使用一组 worker 进程来限制数据库连接，而不是为每一个用户注册操作创建一个进程。这样就能避免耗尽系统的资源。

Poolboy 就是为此产生。它允许你设置一个受 `Supervisor` 管理的 worker 进程池，并且还不需要花费你太多的精力去管理。很多程序库的底层都使用了 Poolboy。比如，`postgrex` 的连接池管理 *（Ecto 连接 PostgreSQL 时使用的程序库）*和 `redis_poolex` *(Redis 连接池)* 都是出名的，使用了 Poolboy 的程序库。

## 安装

通过 mix，安装简直易如反掌。我们需要做的就是把 Poolboy 添加到 `mix.exs` 的依赖配置里面。

让我们先来创建一个应用：

```shell
$ mix new poolboy_app --sup
```

把 Poolboy 添加到 `mix.exs` 的依赖配置里面。

```elixir
defp deps do
  [{:poolboy, "~> 1.5.1"}]
end
```

然后安装获取依赖。

```shell
$ mix deps.get
```

## 配置选项

使用 Poolboy 前，我们还是要了解一些它的配置选项。

* `:name` - 进程池名字。命名空间（Scope）可以是 `:local`，`:global` 或者 `:via`。
* `:worker_module` - 代表 worker 进程的模块。
* `:size` - 最大进程数。
* `:max_overflow` - 当进程池为空的时候，可创造的最大临时进程数。（可选）
* `:strategy` - `:lifo` 或 `:fifo`，决定了回收到进程池的 worker 进程，是放到可用 worker 进程队列的开头还是结尾。默认值为 `:lifo`。（可选）

## 开始配置 Poolboy

以下的例子，我们会创建一个负责处理计算平方根请求的 worker 进程池。样例会尽量简单以便于我们关注在 Poolboy 上为主。

让我们先配置 Poolboy，并把 Poolboy worker 进程池添加到我们的应用中作为一个子进程。编辑 `lib/poolboy_app/application.ex` 如下：

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

最开始定义的是进程池的配置选项。进程池的名字设置为 `:worker`，`:scope` 设为 `:local`。然后我们指派 `PoolboyApp.Worker` 模块作为 `:worker_module`。进程池的大小通过 `:size` 设置为 5。同时，通过配置 `:max_overflow` 选项，我们还可以让进程池在 worker 进程繁忙的情况下，最多创建两个额外的 worker。*（`overflow` workers 完成工作后会被销毁。）*

然后，我们把 `:poolboy.child_spec/2` 函数添加到 children 数组中，它就会随着应用的启动而启动。这个函数接收两个参数：进程池名字，和它的配置。


## 创建 Worker

Worker 模块只是一个简单的 `GenServer`。它计算平方根，sleep 一秒，然后打印出 worker 的 pid。`lib/poolboy_app/worker.ex` 文件如下：

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

既然我们已经有了 `PoolboyApp.Worker`，我们就可以测试 Poolboy 了。我们先创建一个简单的，使用 Poolboy 创建并发进程的模块。`:poolboy.transaction/3` 是可以和 worker 进程池交互的函数。测试文件 `lib/poolboy_app/test.ex` 如下：

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
        fn pid -> GenServer.call(pid, {:square_root, i}) end,
        @timeout
      )
    end)
  end

  defp await_and_inspect(task), do: task |> Task.await(@timeout) |> IO.inspect()
end
```

运行测试，结果如下：

```shell
$ iex -S mix
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

如果进程池已经把 worker 进程耗尽了，Poolboy 就会在默认的超时时间（5秒）后丢出超时错误，并不再接收任何新的请求。我们的这个例子，已经把默认的超时时间改成一分钟，就是为了展示如何更改默认的超时时间。你如果把 `@timeout` 修改到小于 1000，就能观察到错误。

即便我们尝试创建更多的进程 *（上面的例子是 20 ）*，`:poolboy.transaction/3` 函数还是会限制最大的进程数为 5 *（有需要的话会加上两个 overflow worker）*。所有的请求都会通过进程池里面的 worker 来处理，而不会为每个新的请求创建新的进程。
