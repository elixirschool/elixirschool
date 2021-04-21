%{
  version: "1.1.1",
  title: "GenStage",
  excerpt: """
  本课, 我们将学习 GenStage, 它的作用, 以及如何在我们的应用中使用它.
  """
}
---

## 介绍

那么什么是 GenStage? 官方文档中写道, 它是"Elixir 的规格与计算流程", 但对我们来说意味着什么?

这意味着, GenStage 为我们提供了定义一个管道操作的方式, 它是由多个独立的阶段(或 stage)组合起来的; 如果你之前使用过管道, 应该熟悉其中的一些概念.

为了更好地理解它的工作原理, 让我们来看一个简单的生产者-消费者流程:

```
[A] -> [B] -> [C]
```

在这个例子里, 我们有三个 stage: 一个生产者 `A`, 一个生产者-消费者 `B`, 以及一个消费者 `C`.  `A` 生产一个 `B` 供消费的值, `B` 执行了一些工作并返回一个新的值, 提供给消费者 `C`; 我们将在下一节中看到这些角色, 它们十分重要.

虽然我们的例子是1对1的生产者和消费者, 但是在任何一个 stage 都可能拥有多个生产者和多个消费者.

为了更好地说明这些概念, 我们将使用 GenStage 来构建管道, 但首先让我们来探讨一下 GenStage 的角色.

## 消费者与生产者

正如我们所看到的, 我们赋予 stage 的角色很重要. GenStage 的规范中承认三种角色:

+ `:producer` — 一个源.  生产者等待消费者的需求并响应消费者的需求.

+ `:producer_consumer` — 既是源也是汇.  生产者-消费者 可以响应其他消费者的需求, 并向其他生产者提出需求.

+ `:consumer` — 一个汇.  消费者从其他生产者处请求并接收数据.

注意到我们的生产者是在 __等待__ 需求了吗?  使用 GenStage, 我们的消费者向上游发送需求, 并处理来自生产者的数据. 这有助于称为背压的机制.  当消费者忙碌时, 背压使得生产者在消费者繁忙时不会承受过度的压力.

现在, 我们已经介绍了 GenStage 中的角色, 让我们开始编写的应用.

## 入门

在这个例子中, 我们将构建一个 GenStage 应用, 它将产生数字, 过滤掉偶数, 最后打印出剩下的数字.

在这个应用中我们将用到全部三种角色.  我们的生产者将负责计数和排放数字.  我们将使用一个生产者-消费者来筛选偶数, 并响应来自下游的需求.  最后, 我们将构建一个消费者来显示我们剩下的数字.

首先, 我们生成一个带有监控树的项目:

```shell
$ mix new genstage_example --sup
$ cd genstage_example
```

让我们在 `mix.exs` 文件的依赖列表中加入 `gen_stage`:

```elixir
defp deps do
  [
    {:gen_stage, "~> 1.0.0"},
  ]
end
```

接着获取并编译依赖:

```shell
$ mix do deps.get, compile
```

现在我们准备好编写我们的生产者了!

## 生产者

GenStage 应用的第一步是创建我们的生产者.  正如我们之前讨论过的, 我们想要创建一个发出恒定数字流的生产者.  让我们来创建生产者的文件:

```shell
$ touch lib/genstage_example/producer.ex
```

现在添加代码:

```elixir
defmodule GenstageExample.Producer do
  use GenStage

  def start_link(initial \\ 0) do
    GenStage.start_link(__MODULE__, initial, name: __MODULE__)
  end

  def init(counter), do: {:producer, counter}

  def handle_demand(demand, state) do
    events = Enum.to_list(state..(state + demand - 1))
    {:noreply, events, state + demand}
  end
end
```

这里有两个重要的部分需要注意, `init/1` 和 `handle_demand/2`.  在 `init/1` 中我们像 GenServer 一样设置了的初始状态, 更重要的是我们将其标注为了一个生产者.  GenStage 根据 `init/1` 函数的返回值来区分进程的类型.

`handle_demand/2` 函数是生产者的主要部分, 也是所有 GenStage 生产者都必须实现的.  这里, 我们返回了消费者所需要的数字, 并增加了计数.  消费者发来的需求, 也就是上面代码中的`demand`, 是一个代表其所能处理的事件数量的整数; 默认值是 1000.

## 生产者-消费者

现在, 我们有了一个产生数字的生产者, 让我们看看生产者-消费者.  我们想要向生产者请求数字, 过滤掉奇数, 并响应需求.

```shell
$ touch lib/genstage_example/producer_consumer.ex
```

让我们在文件中写入如下代码:

```elixir
defmodule GenstageExample.ProducerConsumer do
  use GenStage

  require Integer

  def start_link(_initial) do
    GenStage.start_link(__MODULE__, :state_doesnt_matter, name: __MODULE__)
  end

  def init(state) do
    {:producer_consumer, state, subscribe_to: [GenstageExample.Producer]}
  end

  def handle_events(events, _from, state) do
    numbers =
      events
      |> Enum.filter(&Integer.is_even/1)

    {:noreply, numbers, state}
  end
end
```

你可能已经注意到, 我们在生产者-消费者中, 为 `init/1` 增加了一个选项, 还增加了一个函数: `handle_events/3`.  通过 `subscribe_to` 选项, 我们让 GenStage 与指定的生产者进行通信.

`handle_events/3` 函数是我们的主力, 它接收事件, 处理它们, 并得到转换后的集合.  我们将在消费者中看到非常类似的实现, 但是最重要的区别在于 `handle_events/3` 函数的返回值.  在生产者-消费者中, 返回值元组的第二个参数 -- 这里是 `numbers` -- 将用于满足下游消费者的需求.  在消费者中, 这个值会被丢弃.

## 消费者

最后来让我们来看看同样重要的消费者:

```shell
$ touch lib/genstage_example/consumer.ex
```

由于消费者和生产者-消费者太相似了, 所以代码看起来没有什么区别:

```elixir
defmodule GenstageExample.Consumer do
  use GenStage

  def start_link(_initial) do
    GenStage.start_link(__MODULE__, :state_doesnt_matter)
  end

  def init(state) do
    {:consumer, state, subscribe_to: [GenstageExample.ProducerConsumer]}
  end

  def handle_events(events, _from, state) do
    for event <- events do
      IO.inspect({self(), event, state})
    end

    # As a consumer we never emit events
    {:noreply, [], state}
  end
end
```

正如之前提到的, 我们的消费者不会生产事件, 所以元组的第二个参数会被抛弃.

## 把它们结合起来

现在我们有了生产者, 生产者-消费者和消费者, 我们已经准备好把所有东西捆绑在一起了.

首先, 打开 `lib/genstage_example/application.ex` 并添加我们的新进程到监控树:

```elixir
def start(_type, _args) do
  import Supervisor.Spec, warn: false

  children = [
    {GenstageExample.Producer, 0},
    {GenstageExample.ProducerConsumer, []},
    {GenstageExample.Consumer, []}
  ]

  opts = [strategy: :one_for_one, name: GenstageExample.Supervisor]
  Supervisor.start_link(children, opts)
end
```

如果一切正确, 那么我们的项目就可以运行, 可以看到它能够工作:

```shell
$ mix run --no-halt
{#PID<0.109.0>, 0, :state_doesnt_matter}
{#PID<0.109.0>, 2, :state_doesnt_matter}
{#PID<0.109.0>, 4, :state_doesnt_matter}
{#PID<0.109.0>, 6, :state_doesnt_matter}
...
{#PID<0.109.0>, 229062, :state_doesnt_matter}
{#PID<0.109.0>, 229064, :state_doesnt_matter}
{#PID<0.109.0>, 229066, :state_doesnt_matter}
```

我们做到了!  正如我们预期的那样, 程序只会产生偶数, 而且非常 __快__.

这样, 我们就有了一条工作流.  一个生产者产生数字, 一个生产者-消费者过滤掉奇数, 然后一个消费者显示所有这些, 并让管道持续流动.

## 多个生产者或消费者

在简介里, 我们有提到可以同时有多个生产者或消费者. 让我们来看看是怎么一回事.

如果我们检查上面例子里 `IO.inspect/1` 的输出, 会发现所有的事件都是由同一个进程来处理的.  让我们修改 `lib/genstage_example/application.ex` 以配置多个 worker:

```elixir
children = [
  {GenstageExample.Producer, 0},
  {GenstageExample.ProducerConsumer, []},
  %{
    id: 1,
    start: {GenstageExample.Consumer, :start_link, [[]]}
  },
  %{
    id: 2,
    start: {GenstageExample.Consumer, :start_link, [[]]}
  }
]
```

现在, 我们有了两个消费者, 让我们来看一下现在运行应用的结果:

```shell
$ mix run --no-halt
{#PID<0.120.0>, 0, :state_doesnt_matter}
{#PID<0.120.0>, 2, :state_doesnt_matter}
{#PID<0.120.0>, 4, :state_doesnt_matter}
{#PID<0.120.0>, 6, :state_doesnt_matter}
...
{#PID<0.120.0>, 86478, :state_doesnt_matter}
{#PID<0.121.0>, 87338, :state_doesnt_matter}
{#PID<0.120.0>, 86480, :state_doesnt_matter}
{#PID<0.120.0>, 86482, :state_doesnt_matter}
```

如你所见, 现在有了多个 PID, 只需要简单地添加一行代码并指定消费者的 ID.

## 用例

现在, 我们已经了解了 GenStage, 并构建了我们的第一个示例应用, 那么 GenStage 有哪些 __真实__ 的用例呢?

+ 数据转换管道 — 生产者不必是简单的数字生成器. 我们可以从数据库甚至其他来源(如 Apache's Kafka)生成事件.  再加上生产者-消费者和消费者, 我们可以在它们可用的时候做处理, 排序, 分类以及指标存储.

+ 工作队列 — 因为事件可以是任何东西, 所以我们可以生产一系列由消费者完成的工作单元.

+ 事件处理 — 类似于数据管道, 我们可以对源产生的实时事件进行接收, 处理, 排序, 以及做出行动.

这些只是 GenStage 的 __一小部分__ 可能性.
