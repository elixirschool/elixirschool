---
version: 1.0.2
title: Benchee
---

我们不能简单地猜测哪个函数运行得快，哪个慢 - 而是需要实际的测量值。这就是需要基准测量介入的时候了。本课程将学习如何度量代码的执行效率。

{% include toc.html %}

## 关于 Benchee

虽然有一个[Erlang 函数](http://erlang.org/doc/man/timer.html#tc-1) 可以测量函数的运行时间，但是它并不如一些工具好用。而且，它不能通过多次测量获得好的统计数字。所以，我们可以使用 [Benchee](https://github.com/PragTob/benchee)。Benchee 提供了不同场景下的统计数字的比较功能。这个功能可以让我们测试函数不同的输入参数。Benchee 还有不同的格式化工具显示比较结果，你甚至可以写自己的格式化工具。

## 使用

把 Benchee 作为依赖添加到你的 `mix.exs` 文件：

```elixir
defp deps do
  [{:benchee, "~> 0.9", only: :dev}]
end
```

然后执行：

```shell
$ mix deps.get
...
$ mix compile
```

第一个命令会下载和安装 Benchee。或许你还会同时被要求安装 Hex。第二个命令编译 Benchee 应用。这样我们就可以写第一个基准测试了！

**开始前的注意事项：** 开始基准测试的时候，最重要的是别使用 `iex` 因为它的行为是不一样给的，也比线上运行的速度要慢很多。所以，我们先创建名为 `benchmark.exs` 的基准测试文件，并在里面添加以下代码：

```elixir
list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(%{
  "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
})
```

现在就可以运行我们的基准测试了：

```shell
$ mix run benchmark.exs
```

类似的输出就会出现在你的命令行控制台：

```shell
Operating System: macOS
CPU Information: Intel(R) Core(TM) i5-4260U CPU @ 1.40GHz
Number of Available Cores: 4
Available memory: 8.589934592 GB
Elixir 1.5.1
Erlang 20.0
Benchmark suite executing with the following configuration:
warmup: 2.00 s
time: 5.00 s
parallel: 1
inputs: none specified
Estimated total run time: 14.00 s


Benchmarking flat_map...
Benchmarking map.flatten...

Name                  ips        average  deviation         median
flat_map           1.03 K        0.97 ms    ±33.00%        0.85 ms
map.flatten        0.56 K        1.80 ms    ±31.26%        1.60 ms

Comparison:
flat_map           1.03 K
map.flatten        0.56 K - 1.85x slower
```

当然，你的系统信息和比较结果应该会和这里不一样，因为运行基准测试的机器配置不同，但是基本的信息应该都在。

一眼看过去，`Comparison` 部分显示 `map.flatten` 比 `flat_map` 慢 1.85 倍 - 这个信息是多么有帮助！让我们再看一下其它统计信息：

* **ips** - 全称是 "iterations per second"。它告诉了我们每秒当前函数可以被调用多少次。对于这个数字，越大越好。
* **average** - 给定函数的平均执行时间。这个数值越小越好。
* **deviation** - 这是标准差，也就是每次调用耗时和前述平均值之间的偏移量。这里是平均标准差的百分比形式。
* **median** - 中位数。当所有的数值都测量出来后，排序，取中间的那个值（如果是偶数结果的话，取中间两个值的平均数）。因为环境的不一致性，这个值比 `average` 更稳定，也更能体现代码在线上运行的效率。这个数值也是越小越好。

还有其它的一些统计数字，但是这四个是最常用，也是最常用的测量基准值，所以它们都在默认的格式化工具中显示。想了解更多可用的测量数值，可参考 [hexdocs](https://hexdocs.pm/benchee/Benchee.Statistics.html#statistics/1) 上的文档。

## 配置

Benchee 的可用配置选项非常强大。我们先过一下基本设置，因为它们不需要代码展示。然后我们再看看 Benchee 其中一个最赞的功能 - 输入。

### 基本配置

Benchee 的配置选项非常丰富。对于最常用的 `Benchee.run/2` 接口，下面是可选的第二个参数的关键字列表所支持的配置：

```elixir
Benchee.run(%{"example function" => fn -> "hi!" end}, [
  warmup: 4,
  time: 10,
  inputs: nil,
  parallel: 1,
  formatters: [&Benchee.Formatters.Console.output/1],
  print: [
    benchmarking: true,
    configuration: true,
    fast_warning: true
  ],
  console: [
    comparison: true,
    unit_scaling: :best
  ]
])
```

以下就是支持的选项（文档也在 [hexdocs](https://hexdocs.pm/benchee/Benchee.Configuration.html#init/1)）.

* **warmup** - 热身时间（以秒为单位）。基准测量在真正计算运行时间前先进行一段时间的热身。这是为了模拟一个已经热身的运行系统。默认值为两秒。
* **time** - 基准测量时间（以秒为单位），也就是每次基准测试的运行和测量时间。默认值为五秒。
* **inputs** - 一个以字符串为键，实际输入为值的映射。默认值为 `nil`。我们在下一章会详细解释这个参数。
* **parallel** - 并行基准测试运行时，使用的进程数。如果你设置了 `parallel: 4`，那么，就会创建 4 个进程来在给定的 `time` 时间内执行相同的函数。完成后，又会创建 4 个新的进程执行下一个函数。使用这个选项虽然能得到更多的数据，但是同时也让系统增加压力，可能会干扰基准测试的结果。在需要测试压力下系统的表现时，这个参数有时还是有用的。但是，必须谨慎使用，因为它可能会以意想不到的方式影响测试结果。默认值为 1（也就是没有并行执行测试）。
* **formatters** - 格式化函数列表，在运行 `Benchee.run/2` 时，应用于基准测试结果。这些函数都应该接收一个参数（基准测试数据集），并产生最后输出结果。默认是内置的命令行控制台格式化工具，`Benchee.Formatters.Console.output/1`。后面的章节会更详细介绍这部分。
* **print** - 一个映射或者关键字列表，以配置项原子作为键，`true` 或者 `false` 为值。这个控制了原子键对应的输出选项是否在标准的基准测试运行中打印出来。所有的选项默认都是打开的（true）。支持的选项有：
  * **benchmarking** - Benchee 开始一个新的基准测试任务时打印。
  * **configuration** - 基准测试的配置选项总结，包括预计总运行时间。在测试前打印。
  * **fast_warning** - 当函数执行速度太快时显示出来的警告，因为有可能导致不准确的测量结果。
* **console** - 一个映射或者关键字列表，以配置项原子作为键，各项有不同类型的值。每个选项支持的值单独列在选项后：
  * **comparison** - 是否显示不同基准测试任务的比较结果（慢 x 倍）。默认值为 `true`，但可以设为 `false`。
  * **unit_scaling** - 选择时间和数量单位刻度的策略。Benchee 会尝试选择最佳的单位来显示一个值（结果中最大的值的单位应该最少是 1）.比如，`1_200_000` 会被显示为 1.2 M，而 `800_000` 则会被显示为 800 K。单位的伸缩策略决定了 Benchee 如何选择适应整个列表值的最佳单位，尤其是列表中不同的值有不同的最佳单位时。一共有四个策略，都以原子表示，默认是 `:best`：
    * **best** - 使用最常用的最佳单位。打平时会选择大的单位。
    * **largest** - 使用最大的最佳单位。
    * **smallest** - 使用最小的最佳单位。
    * **none** - 不适用任何的伸缩调节。时间按照微妙来显示，ips 数量则不显示单位。

### 输入

使用那些实际可能出现的数据，来基准测试一个函数是非常重要的。大多数的情况下，一个函数在大数据集，和小数据集下的行为表现是很不同的！这就是 Benchee 的 `inputs` 配置选项起作用的地方。它允许你使用自选的各种数据来测试同一个函数，然后就能看到各自的结果。

让我们看看原来的例子：

```elixir
list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(%{
  "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
})
```

这个例子中，我们只是使用了从 1 到 10,000 的整数列表。让我们使用几个不同的输入，看看大小不同的列表会有什么表现。我们可以把代码修改为下面的样子：

```elixir
map_fun = fn i -> [i, i * i] end

inputs = %{
  "small list" => Enum.to_list(1..100),
  "medium list" => Enum.to_list(1..10_000),
  "large list" => Enum.to_list(1..1_000_000)
}

Benchee.run(
  %{
    "flat_map" => fn list -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn list -> list |> Enum.map(map_fun) |> List.flatten() end
  },
  inputs: inputs
)
```

你会注意到这里有两个不同。首先，我们现在有了一个 `inputs` 映射，包含了函数的输入。这个 inputs 映射会作为配置参数传给 `Benchee.run/2`。

并且，因为现在我们的函数需要接收一个参数，我们需要更新基准测试函数，与其：

```elixir
fn -> Enum.flat_map(list, map_fun) end
```

我们现在要改为：

```elixir
fn list -> Enum.flat_map(list, map_fun) end
```

让我们再做一次测试：

```shell
$ mix run benchmark.exs
```

现在你应该在控制台看到类似这样的输出：

```shell
Operating System: macOS
CPU Information: Intel(R) Core(TM) i5-4260U CPU @ 1.40GHz
Number of Available Cores: 4
Available memory: 8.589934592 GB
Elixir 1.5.1
Erlang 20.0
Benchmark suite executing with the following configuration:
warmup: 2.00 s
time: 5.00 s
parallel: 1
inputs: large list, medium list, small list
Estimated total run time: 2.10 min

Benchmarking with input large list:
Benchmarking flat_map...
Benchmarking map.flatten...

Benchmarking with input medium list:
Benchmarking flat_map...
Benchmarking map.flatten...

Benchmarking with input small list:
Benchmarking flat_map...
Benchmarking map.flatten...


##### With input large list #####
Name                  ips        average  deviation         median
flat_map             6.29      158.93 ms    ±19.87%      160.19 ms
map.flatten          4.80      208.20 ms    ±23.89%      200.11 ms

Comparison:
flat_map             6.29
map.flatten          4.80 - 1.31x slower

##### With input medium list #####
Name                  ips        average  deviation         median
flat_map           1.34 K        0.75 ms    ±28.14%        0.65 ms
map.flatten        0.87 K        1.15 ms    ±57.91%        1.04 ms

Comparison:
flat_map           1.34 K
map.flatten        0.87 K - 1.55x slower

##### With input small list #####
Name                  ips        average  deviation         median
flat_map         122.71 K        8.15 μs   ±378.78%        7.00 μs
map.flatten       86.39 K       11.58 μs   ±680.56%       10.00 μs

Comparison:
flat_map         122.71 K
map.flatten       86.39 K - 1.42x slower
```

现在，我们的基准测试按照 input 分组了。虽然这个简单的例子并不能得出多深入的见解，但是你应该注意到，性能随着输入数据集的大小变化有多大！

## 格式化工具

控制台的输出对于测量函数的运行时间非常有帮助，也易于使用。但是，这并不代表是唯一的选择！本章我们将粗略地看看其它三个格式化输出工具，并了解如何才能写自己的格式化工具。

### 其它格式化工具

Benchee 默认集成的是控制台的格式化输出工具，但是，还有其它三个官方支持的工具 - `benchee_csv`,
`benchee_json` 和 `benchee_html`。每个都和期望的那样，把结果写到特定格式的文件，然后你可以再进一步处理。

每一个格式化工具都是独立的包，所以，必须把它们添加到 `mix.exs` 中作为依赖才能使用：

```elixir
defp deps do
  [
    {:benchee_csv, "~> 0.6", only: :dev},
    {:benchee_json, "~> 0.3", only: :dev},
    {:benchee_html, "~> 0.3", only: :dev}
  ]
end
```

`benchee_json` 和 `benchee_csv` 非常简单，而 `benchee_html` 则实际上_相当_功能丰富！它很容易就能让你生成漂亮的图表。你还能导出为 PNG 图片。这三个格式化工具的文档都详细记录在它们各自的 Github 主页上，所以我们就不详细说明了。

### 自定义格式化工具

如果提供的四个格式化工具都不足以满足你的需求，你还可以自己写一个。写一个格式化工具相当的容易。你只需要提供一个接收 `%Benchee.Suite{}` 结构体的函数，然后就可以从中获取任何想要的信息。你可以查看 [GitHub](https://github.com/PragTob/benchee/blob/master/lib/benchee/suite.ex) 或者 [HexDocs](https://hexdocs.pm/benchee/Benchee.Suite.html) 来了解结构体里面到底有什么信息。代码都有相当完善的注释易读。如果你想自己实现一个格式化工具，查看有什么信息在里面也不难。

这里，我就简单地展示一个自定义的格式化工具长什么样，并且多容易实现。假设我们仅仅想要最少的数据，只是打印出每个场景的平均运行时间。下面是代码样例：

```elixir
defmodule Custom.Formatter do
  def output(suite) do
    suite
    |> format
    |> IO.write()

    suite
  end

  defp format(suite) do
    Enum.map_join(suite.scenarios, "\n", fn scenario ->
      "Average for #{scenario.job_name}: #{scenario.run_time_statistics.average}"
    end)
  end
end
```

然后我们可以这样运行测试：

```elixir
list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(
  %{
    "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
  },
  formatters: [&Custom.Formatter.output/1]
)
```

然后我们的测试结果，就会按照自定义的格式化工具显示成：

```shell
Operating System: macOS
CPU Information: Intel(R) Core(TM) i5-4260U CPU @ 1.40GHz
Number of Available Cores: 4
Available memory: 8.589934592 GB
Elixir 1.5.1
Erlang 20.0
Benchmark suite executing with the following configuration:
warmup: 2.00 s
time: 5.00 s
parallel: 1
inputs: none specified
Estimated total run time: 14.00 s


Benchmarking flat_map...
Benchmarking map.flatten...
Average for flat_map: 851.8840109326956
Average for map.flatten: 1659.3854339873628
```
