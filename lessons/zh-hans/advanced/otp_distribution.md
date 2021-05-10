%{
  version: "1.0.1",
  title: "OTP 分布式",
  excerpt: """
  ## 分布式简介

我们可以把我们的 Elixir 应用运行分布在单主机，或者多主机的不同的节点上。Elixir 允许这些不同的节点通过以下课程中列出来的不同的机制来相互通信。
  """
}
---

## 节点间通信

Elixir 运行在 Erlang 虚拟机之上，也就意味着它拥有了 Erlang 强大的[分布式特性。](http://erlang.org/doc/reference_manual/distributed.html)

> 一个分布式 Erlang 系统由相互沟通的 Erlang 运行环境组成。每个这样的环境称之为一个节点。

一个节点就是赋予了名字的 Erlang 运行环境。我们可以通过打开 `iex` 会话，并设置名称的方式来启动一个节点：

```bash
iex --sname alex@localhost
iex(alex@localhost)>
```

然后我们可以在另一个命令行窗口启动另一个节点：

```bash
iex --sname kate@localhost
iex(kate@localhost)>
```

这两个节点可以通过 `Node.spawn_link/2` 来相互发送消息。

### 通过 Node.spawn_link/2 来通信

这个函数需要接收两个参数：

* 需要连接的节点名称  
* 需要远程节点运行的函数  

它会和远程节点建立连接，然后在对方那运行指定的函数，然后返回关联进程的 PID。

让我们先定义一个模块，`Kate`，在 `kate` 节点上，并懂得如何介绍 Kate 这个人：

```elixir
iex(kate@localhost)> defmodule Kate do
...(kate@localhost)>   def say_name do
...(kate@localhost)>     IO.puts "Hi, my name is Kate"
...(kate@localhost)>   end
...(kate@localhost)> end
```

#### 发送消息

现在，我们就可以使用 [`Node.spawn_link/2`](https://hexdocs.pm/elixir/Node.html#spawn_link/2) 来让 `alex` 节点要求 `kate` 节点运行 `say_name/0` 这个函数：

```elixir
iex(alex@localhost)> Node.spawn_link(:kate@localhost, fn -> Kate.say_name end)
Hi, my name is Kate
#PID<10507.132.0>
```

#### 关于 I/O 和节点要注意的地方

注意到，尽管 `Kate.say_name/0` 是在远程节点调用的，但确实本地，或者说调用节点这里接收到 `IO.puts` 的输出。

这是因为本地节点是 **群组领导节点（group leader）**。Erlang 虚拟机通过进程来管理 I/O。这就使得我们可以在分布式的节点间执行 I/O 操作，比如 `IO.puts`。这些分布式的进程是通过群组领导节点的 I/O 进程来管理的。群组领导节点总是发起进程的那个节点。

因为 `alex` 节点是我们调用 `spawn_link/2` 函数的节点，所以它就是群组领导节点，`IO.puts` 的返回也会指向这个节点的标准输出流上。

#### 回应消息

如果我们希望接收到消息的节点发送某些 **回应** 到发送方？我们可以简单的使用 `receive/1` 和 [`send/3`](https://hexdocs.pm/elixir/Process.html#send/3) 来实现这一点。

我们可以让 `alex` 节点建立一个通道到 `kate` 节点，并指定 `kate` 节点运行某个匿名函数。这个匿名函数会监听是否收到某个描述了特定消息和 `alex` 节点 PID 的元组。如果收到了这个元组消息，它就会通过相应的 PID 回应一条消息到 `alex` 节点上：

```elixir
iex(alex@localhost)> pid = Node.spawn_link :kate@localhost, fn ->
...(alex@localhost)>   receive do
...(alex@localhost)>     {:hi, alex_node_pid} -> send alex_node_pid, :sup?
...(alex@localhost)>   end
...(alex@localhost)> end
#PID<10467.112.0>
iex(alex@localhost)> pid
#PID<10467.112.0>
iex(alex@localhost)> send(pid, {:hi, self()})
{:hi, #PID<0.106.0>}
iex(alex@localhost)> flush()
:sup?
:ok
```

#### 关于跨网络间的节点通信

如果你希望在不同网络间的节点之间发送消息，我们需要在启动命名节点的时候提供相同的一个 cookie：

```bash
iex --sname alex@localhost --cookie secret_token
```

```bash
iex --sname kate@localhost --cookie secret_token
```

只有拿着相同 `cookie` 启动的节点才能够成功相互通信。

#### Node.spawn_link/2 的限制

虽然 `Node.spawn_link/2` 很好阐明节点之间的关系，以及我们在它们之间发送消息的方式，但是，它 **不是** 在分布式节点中运行的应用之间传递消息的好的做法。`Node.spawn_link/2` 会创建出独立的进程，也就是不受监管的进程。如果能有 **跨节点** 之间创建出受监管的异步进程的话...

## 分布式任务

[分布式任务](https://hexdocs.pm/elixir/master/Task.html#module-distributed-tasks) 允许我们在节点之间创建出受监管的任务。我们通过一个简单的 supervisor 应用来实现分布式任务，允许用户通过 `iex` 会话来在分布式的节点之间相互通信。

### 定义一个 Supervisor 应用

生成应用：

```
mix new chat --sup
```

### 把 Task Suppervisor 加入到 Supervision Tree

Task Supervisor 动态监管任务。它启动的时候并没有任何子进程，通常只是在自己的 supervisor **监管之下**。后面我们可以让它监管任何数量的子任务。

我们会把 Task Supervisor 添加到我们应用的 supervision tree 里面，并且命名为 `Chat.TaskSupervisor`。

```elixir
# lib/chat/application.ex
defmodule Chat.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Chat.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: Chat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

这样，无论我们的应用在哪一个节点启动，`Chat.Supervisor` 就会运行并随时准备监管任务。

### 使用受监管的任务发送消息

我们会使用 [`Task.Supervisor.async/5`](https://hexdocs.pm/elixir/master/Task.Supervisor.html#async/5) 函数来启动监管任务。

这个函数需要四个参数：

* 我们想用来监管任务的 supervisor。为了让远程节点来监管任务，我们可以传入一个 `{SupervisorName, remote_node_name}` 的元组。  
* 要执行的函数所在的模块名  
* 要执行的函数名  
* 任何需要传入函数的参数  

我们还可以传入第五个，可选的参数来设置 shutdown 选项。不过这里我们暂时不考虑这个问题。

我们的 Chat 应用非常简单。它发送消息到远程节点，然后远程节点通过 `IO.puts` 的方式来给予相应，通过远程节点的标准输出。

首先，我们来定义一个函数，`Chat.receive_message/1`。这是我们要在远程节点运行的任务。

```elixir
# lib/chat.ex
defmodule Chat do
  def receive_message(message) do
    IO.puts message
  end
end
```

然后，我们需要让 `Chat` 模块懂得如何使用受监管的任务发送消息到一个远程的节点。我们再定义一个方法 `Chat.send_message/2` 来实现这个功能：

```elixir
# lib/chat.ex
defmodule Chat do
  ...

  def send_message(recipient, message) do
    spawn_task(__MODULE__, :receive_message, recipient, [message])
  end

  def spawn_task(module, fun, recipient, args) do
    recipient
    |> remote_supervisor()
    |> Task.Supervisor.async(module, fun, args)
    |> Task.await()
  end

  defp remote_supervisor(recipient) do
    {Chat.TaskSupervisor, recipient}
  end
end
```

让我们来运行一下看看。

在一个命令行窗口，通过一个命名的 `iex` 会话来启动我们的 chat 应用。

```bash
iex --sname alex@localhost -S mix
```

打开另一个命令行窗口，启动另一个命名的节点和应用：

```bash
iex --sname kate@localhost -S mix
```

现在，通过 `alex` 节点，我们可以这样发送消息到 `kate` 节点：

```elixir
iex(alex@localhost)> Chat.send_message(:kate@localhost, "hi")
:ok
```

切换到 `kate` 窗口，你会看到这条消息：

```elixir
iex(kate@localhost)> hi
```

`kate` 节点也可以回应 `alex` 节点：

```elixir
iex(kate@localhost)> hi
Chat.send_message(:alex@localhost, "how are you?")
:ok
iex(kate@localhost)>
```

同样，在 `alex` 节点的 `iex` 会话会出现：

```elixir
iex(alex@localhost)> how are you?
```

让我们来回顾我们的实现代码，并深入分析每一步到底发生了什么。

首先，函数 `Chat.send_message/2` 接收了两个参数：要运行监管任务的远程节点名，和要发送的消息。

这个函数调用了 `spawn_task/4` 函数，也就在相应的节点启动运行了一个异步任务，同时受到远程节点的 `Chat.TaskSupervisor` 监管。我们知道，名为 `Chat.TaskSupervisor` 的 Task Supervisor 运行在那个远程节点。这是因为在我们的 Chat 应用实例 **也** 在那个节点里面运行，并且 `Chat.TaskSupervisor` 也作为 supervision tree 的一部分在运行着。

我们让 `Chat.TaskSupervisor` 监管的任务是负责执行 `Chat.receive_message` 函数。其中的参数是 `send_message/2` 接收的任何消息，再经 `spawn_task/4` 传递过来。

所以，`Chat.receive_message("hi")` 是在远程节点 `kate` 调用的。那么，消息 `"hi"` 也就显示在那个节点的标准输出上。在这个例子，因为任务是被远程节点监管，所以那个节点也就成为这次 IO 进程的群组领导节点。


### 回应远程节点发送过来的消息

让我们把这个 Chat 应用变得更智能一些吧。

目前，任何人都可以在一个命名的 `iex` 会话运行这个应用，开始聊天。但是，比如说一直中型白色，名为 Moebi 的狗也希望能参与进来。Moebi 希望能加入 Chat 应用，但是可惜的是它不懂得如何打字，因为它是一只狗嘛。所以，我们希望 `Chat` 模块能帮 Moebi 回复任何发送到 `moebi@localhost` 节点的消息。无论你对 Moebi 说什么，它总是回复 `"chicken?"`。因为它的唯一希望就是能吃鸡。

我们来定义另一个版本的 `send_message/2` 函数，让它能模式匹配 `recipient` 参数。如果接收方是 `:moebi@locahost`，我们就会：

* 通过 `Node.self()` 来获取当前节点的名字  
* 把当前节点，也就是消息发送方，的名字，传到新的函数 `receive_message_for_moebi/2`，使得我们可以给它 **返回** 消息。

```elixir
# lib/chat.ex
...
def send_message(:moebi@localhost, message) do
  spawn_task(__MODULE__, :receive_message_for_moebi, :moebi@localhost, [message, Node.self()])
end
```

接下来，我们定义函数 `receive_message_for_moebi/2`，在使用 `IO.puts` 在 `moebi` 节点的标准输出打印消息的同时，_也_ 把消息返回给发送方：

```elixir
# lib/chat.ex
...
def receive_message_for_moebi(message, from) do
  IO.puts message
  send_message(from, "chicken?")
end
```

通过调用 `send_message/2` 函数并传入原始消息发送方的节点名称，我们就让 **远程的** 节点在那边创建出一个受监管的任务。

让我们来看看实际效果。在三个不同的命令行窗口，启动三个不同的命名节点：

```bash
iex --sname alex@localhost -S mix
```

```bash
iex --sname kate@localhost -S mix
```

```bash
iex --sname moebi@localhost -S mix
```

让我们请 `alex` 发送消息给 `moebi`：

```elixir
iex(alex@localhost)> Chat.send_message(:moebi@localhost, "hi")
chicken?
:ok
```

我们可以看到，`alex` 节点收到了回应，`"chicken?"`。如果我们查看 `kate` 节点，它没有收到任何消息，因为 `alex` 和 `moebi` 都没有给她发送消息（对不起，`kate`）。如果我们查看 `moebi` 节点的命令行窗口，我们会看到 `alex` 节点发送过来的消息：

```elixir
iex(moebi@localhost)> hi
```

## 测试分布式代码

让我们来给我们的 `send_message` 函数编写一个简单的测试用例吧。

```elixir
# test/chat_test.ex
defmodule ChatTest do
  use ExUnit.Case, async: true
  doctest Chat

  test "send_message" do
    assert Chat.send_message(:moebi@localhost, "hi") == :ok
  end
end
```

如果我们通过 `mix test` 运行这个测试，我们会看到以下错误信息：

```elixir
** (exit) exited in: GenServer.call({Chat.TaskSupervisor, :moebi@localhost}, {:start_task, [#PID<0.158.0>, :monitor, {:sophie@localhost, #PID<0.158.0>}, {Chat, :receive_message_for_moebi, ["hi", :sophie@localhost]}], :temporary, nil}, :infinity)
         ** (EXIT) no connection to moebi@localhost
```

这个错误信息太正常不过了 —— 我们怎么可能连接到一个名为 `moebi@localhost` 的节点呢？因为根本没有这样一个节点在运行啊。

我们可以通过下面几个步骤来让这个测试得以通过：

* 打开另一个命令行窗口，运行命令 `iex --sname moebi@localhost -S mix` 来启动一个命名的节点  
* 回到第一个命令行窗口，通过一个 `iex` 会话来启动一个命名的几点并运行这个测试：`iex --sname sophie@localhost -S mix test`  

显然，这么麻烦，而且这绝对不能算是自动化测试的过程。

我们有两种不同的选择：

1. 选择性的排除掉一些需要分布式节点的测试，如果相应的节点没有在运行的话。

2. 通过配置你的应用，避免在测试环境创建任务到远程节点。

让我们来看看第一种方式怎么处理。

### 通过标签来选择性的排除测试用例

我们需要添加一个 `ExUnit` tag 到测试用例之上：

```elixir
#test/chat_test.ex
defmodule ChatTest do
  use ExUnit.Case, async: true
  doctest Chat

  @tag :distributed
  test "send_message" do
    assert Chat.send_message(:moebi@localhost, "hi") == :ok
  end
end
```

然后，我们就可以在测试的 helper 模块添加一些条件逻辑，使得那些拥有特定标签的测试用例，当不是运行在一个命名的节点的时侯，被排除在外。

```elixir
exclude =
  if Node.alive?, do: [], else: [distributed: true]

ExUnit.start(exclude: exclude)
```

我们可以通过 [`Node.alive?`](https://hexdocs.pm/elixir/Node.html#alive?/0) 来检查一个节点是不是运行中，也就是是否在一个分布式的系统中。如果不是，我们可以让 `ExUnit` 来跳过打上了 `distributed: true` 标签的测试。反之，则不需要排除那些测试。

现在，如果我们直接运行 `mix test`，我们就会看到：

```bash
mix test
Excluding tags: [distributed: true]

Finished in 0.02 seconds
1 test, 0 failures, 1 excluded
```

如果我们想运行那些分布式测试，我们仅仅需要按照上面列出来的步骤：运行 `moebi@localhost` 节点，**并且** 通过 `iex` 来在一个命名的节点中运行测试。

让我们来看看另一种测试方式 —— 配置应用程序使得它在不同的环境有不同的表现行为。

### 应用的特定环境配置

我们那些让 `Task.Supervisor` 在远程节点启动一个受监管的任务的代码是这样的：

```elixir
# app/chat.ex
def spawn_task(module, fun, recipient, args) do
  recipient
  |> remote_supervisor()
  |> Task.Supervisor.async(module, fun, args)
  |> Task.await()
end

defp remote_supervisor(recipient) do
  {Chat.TaskSupervisor, recipient}
end
```

`Task.Supervisor.async/5` 接收的第一个参数是我们希望使用的 supervisor。如果我们传入的参数是 `{SupervisorName, location}` 这种格式的元组，它就会在给定的节点运行这个 supervisor。但是，如果我们传入 `Task.Supervisor` 的第一个参数仅仅只是 supervisor 的名字，它就会在本地的 supervisor 来监管这个任务。

让我们把 `remote_supervisor/1` 函数改造成基于环境的可配置化。在开发环境，它就返回 `{Chat.TaskSupervisor, recipient}`，在测试环境，它就返回 `Chat.TaskSupervisor`。

我们通过应用的环境变量来实现。

创建文件，`config/dev.exs`，然后加入：

```elixir
# config/dev.exs
use Mix.Config
config :chat, remote_supervisor: fn(recipient) -> {Chat.TaskSupervisor, recipient} end
```

创建另一个文件，`config/test.exs`，然后加入：

```elixir
# config/test.exs
use Mix.Config
config :chat, remote_supervisor: fn(_recipient) -> Chat.TaskSupervisor end
```

把 `config/config.exs` 内的以下这行前面的注释去掉：

```elixir
import_config "#{Mix.env()}.exs"
```

最后，我们把 `Chat.remote_supervisor/1` 函数修改为查找和使用定义好的新应用变量：

```elixir
# lib/chat.ex
defp remote_supervisor(recipient) do
  Application.get_env(:chat, :remote_supervisor).(recipient)
end
```

## 总结

Elixir 的原生分布式能力，当然还是应当感谢 Erlang VM 的强大能力，是其中一个让 Elixir 如此强大的特性。我们可以想象，通过 Elixir 的能力，运用分布式计算的方式来运行后台并行任务，对高性能应用的支持，和执行一些昂贵的操作，等等。

本教程让我们了解到 Elixir 的基本的分布式的概念，并且介绍了开始打造分布式应用的工具。通过使用监管任务，我们就能在分布式应用的不同节点之间发送消息。
