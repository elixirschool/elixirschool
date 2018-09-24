---
version: 0.9.1
title: OTP Supervisors
---

supervisors 是一种特殊的进程：专门来监控其他的进程。supervisors 能够自动重启出错的子进程，从而编写容错性高的程序。

{% include toc.html %}

## 配置
Supervisors 的魔力主要在 `Supervisor.start_link/2` 函数中，除了能启动 supervisor 和子进程之外，它还允许我们设置管理子进程的策略：

子进程使用列表和从 `Supervisor.Spec` 库中导进来的 `worker/3` 共同定义，其中 `worker/3` 函数接受模块名，参数列表，和其他选项作为自己的参数。在初始化的时候，`worker/3` 内部会调用 `start_link/3` ，并传进去刚才的参数列表。

使用在 [`OTP 并发`](../../advanced/otp-concurrency) 课程中实现的 SimpleQueue，我们来测试一下：

```elixir
import Supervisor.Spec

children = [
  worker(SimpleQueue, [], [name: SimpleQueue])
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

如果我们的进程崩溃或者被终结，我们的 Supervisor 会自动重启它，对外来说，好像错误从来没有发生一样。

### 策略
目前有四种不同的重启策略可以使用：

- `:one_for_one` - 只重启失败的子进程。
- `:one_for_all` - 当错误事件出现时，重启所有的子进程。
- `:rest_for_one` - 重启失败的子进程，以及所有在它后面启动的进程。
- `:simple_one_for_one` - supervisor 只能包含一个子进程

### 嵌套
除了 worker 进程，我们还可以监控 supervisors，从而生成 supervisor 树。和之前的唯一不同就是，用 `supervisor/3` 来替换 `worker/3` ：

```elixir
import Supervisor.Spec

children = [
  supervisor(ExampleApp.ConnectionSupervisor, [[name: ExampleApp.ConnectionSupervisor]]),
  worker(SimpleQueue, [[], [name: SimpleQueue]])
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

## Task Supervisor
Tasks 有它们自己特殊的 Supervisor，叫做 `Task.Supervisor`。作为专门为动态创建的任务设计的 supervisor，它内部使用 `:simple_one_for_one` 策略。

### setup
`Task.Supervisor` 使用起来和其他的 supervisors 没有任何区别：

```elixir
import Supervisor.Spec

children = [
  supervisor(Task.Supervisor, [[name: ExampleApp.TaskSupervisor]])
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

### Supervised Tasks
supervisor 启动之后，我们可以使用 `start_child/2` 函数来创建一个 supervised task:

```elixir
{:ok, pid} = Task.Supervisor.start_child(ExampleApp.TaskSupervisor, fn -> background_work end)
```

如果我们的任务过早地崩溃掉，它会被自动启动。这个功能在处理大量涌来的请求或者后台工作的时候非常有用。
