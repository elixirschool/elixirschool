---
version: 1.1.1
title: OTP Supervisors
---

Supervisors 是一种特殊的进程：专门来监控其他的进程。supervisors 能够自动重启出错的子进程，从而编写容错性高的程序。

{% include toc.html %}

## 配置

Supervisors 的魔力主要在 `Supervisor.start_link/2` 函数。除了能启动 supervisor 和子进程之外，它还允许我们设置管理子进程的策略。

通过 [`OTP 并发`](../../advanced/otp-concurrency) 课程中实现的 `SimpleQueue`，我们开始本节课程：  

使用 `mix new simple_queue --sup` 命令，我们创建了拥有 supervisor 树的新项目。`SimpleQueue` 的代码因为放在 `lib/simple_queue.ex` 而 supervisor 的代码我们将添加到 `lib/simple_queue/application.ex` 中。  

子进程通过列表的方式定义，要么是模块名称的列表：  

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

要么是元组的列表，如果你还想包含配置项的话：  

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

如果我们运行 `iex -S mix` 这个命令，我们就会看到 `SimpleQueue` 已经自动启动了：  

```elixir
iex> SimpleQueue.queue
[1, 2, 3]
```

如果我们的 `SimpleQueue` 进程崩溃了，或者被中止了，Supervisor 会自动重启这个进程，就像什么事情都没有发生过一样。  

### 策略

目前有三种不同的重启策略可以使用：

- `:one_for_one` - 只重启失败的子进程。  
- `:one_for_all` - 当错误事件出现时，重启所有的子进程。  
- `:rest_for_one` - 重启失败的子进程，以及所有在它后面启动的进程。  

## 子进程 Specification

当 supervisor 进程启动后，它必须知道如何 start/stop/restart 它的子进程。每个子模块都应该拥有 `child_spec/1` 函数来定义好这些行为。宏 `use GenServer`，`use Supervisor` 和 `use Agent` 的使用，会自动为我们定义好这些行为（`SimpleQueue` 使用了 `use GenServer`，所以我们不需要修改这个模块）。但是，如果你需要自己定义这些行为，你要在 `child_spec/1` 函数中返回一个选项映射：  

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

+ `id` - 必备 key。Supervisor 用来定位子进程的 specification。  

+ `start` - 必备 key。被 Supervisor 启动时，需要调用的 Module/Function/Arguments  

+ `shutdown` - 可选 key。子进程关闭时的行为。可选项为有以下几种：  

  + `:brutal_kill` - 子进程立即停止  

  + 任何正整数 - 以毫秒为单位的等待时间，超过后 Supervisor 将杀掉此子进程。如果进程是 `:worker` 类型，此选项默认为 5000。  

  + `:infinity` - Supervisor 将会无限期地等待。这是 `:supervisor` 进程类型的默认值。不推荐 `:worker` 类型使用。  

+ `restart` - 可选 key。当子进程崩溃时有如下几种处理方式：  

  + `:permanent` - 总是重启子进程。所有进程的默认值。  

  + `:temporary` - 绝不重启子进程。  

  + `:transient` - 只有在非正常中止的时候，才重启子进程。  

+ `type` - 可选 key。进程可以是 `:worker` 或者 `:supervisor` 类型。默认是 `:worker`。  


## DynamicSupervisor

Supervisors 通常在应用启动的时候，伴随着子进程而启动。但是，有时候，被监管的子进程在应用启动的时候，还是未知的（比如，我们可能在 web 应用中，启动了一个新的进程来处理用户到我们网站的连接）。这种情况下，我们需要的是一个能按需启动子进程的 Supervisor。而 DynamicSupervisor 正是用来处理这种场景的。  

因为我们并不指定子进程，我们只需要为 supervisor 定义好运行时的选项就可以了。DynamicSupervisor 只支持 `:one_for_one` 这种监管策略：  

```elixir
options = [
  name: SimpleQueue.Supervisor,
  strategy: :one_for_one
]

DynamicSupervisor.start_link(options)
```

然后，我们需要使用 `start_child/2` 函数来动态启动新的 SimpleQueue 子进程。这个函数接收一个 supervisor 和 子进程 specification 作为参数（再次强调，`SimpleQueue` 使用了 `use GenServer`，所以子进程的 specification 已经定义好了）：  

```elixir
{:ok, pid} = DynamicSupervisor.start_child(SimpleQueue.Supervisor, SimpleQueue)
```

## Task Supervisor

Tasks 有它们自己特殊的 Supervisor，叫做 `Task.Supervisor`。它是专门为动态创建的任务而设计的 supervisor，内部实际使用的是 `DynamicSupervisor`。  

### Setup

`Task.Supervisor` 使用起来和其他的 supervisors 没有任何区别：  

```elixir
children = [
  {Task.Supervisor, name: ExampleApp.TaskSupervisor, restart: :transient}
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

`Supervisor` 和 `Task.Supervisor` 主要的不同是 `Task.Supervisor` 的默认重启策略是 `:temporary`（绝不重启子任务）。

### 受监管的 Tasks

Supervisor 启动之后，我们可以使用 `start_child/2` 函数来创建受监管的 task:  

```elixir
{:ok, pid} = Task.Supervisor.start_child(ExampleApp.TaskSupervisor, fn -> background_work end)
```

如果我们的任务过早地崩溃掉，它会被自动启动。这个功能在处理大量涌来的请求或者后台工作的时候非常有用。  
