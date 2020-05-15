---
version: 1.1.0
title: 调试
---

臭虫（Bugs）可谓是任何项目都无法避免的存在，所以调试也不可或缺。本课程我们将学习如何调试 Elixir 代码，并使用静态分析工具来帮助寻找可能存在的 bugs。 

{% include toc.html %}

## Iex
我们最直接的调试 Elixir 代码的工具是IEx。但不要被它的简单性所迷惑--你可以通过它解决你的应用程序中的大部分问题。

IEx指的是 `Elixir 的交互式 shell`。你可能已经在之前的课程中看到过 IEx 了，比如 [基础](../../basics/basics) 部分，我们在 Shell 中交互式地运行Elixir 代码。

这里的想法很简单。你在你想调试的地方获取交互式 shell 的上下文。

让我们尝试一下。要做到这一点，创建一个名为 `test.exe` 的文件，然后下面的内容写入文件：

```elixir
defmodule TestMod do
  def sum([a, b]) do
    b = 0

    a + b
  end
end

IO.puts(TestMod.sum([34, 65]))
```

如果你运行它 - 你会得到一个明显的输出 `34`:

```shell
$ elixir test.exs
warning: variable "b" is unused (if the variable is not meant to be used, prefix it with an underscore)
  test.exs:2

34
```

但是现在让我们进入激动人心的部分 -- 调试。将 `require IEx; IEx.pry` 放在 `b = 0` 之后的行中，让我们再试着运行一次。你会得到这样的结果。

```shell
$ elixir test.exs
warning: variable "b" is unused (if the variable is not meant to be used, prefix it with an underscore)
  test.exs:2

Cannot pry #PID<0.92.0> at TestMod.sum/1 (test.exs:5). Is an IEx shell running?
34
```

你应该注意到这个重要的消息。当运行一个应用程序时，像往常一样，IEx 会输出这个消息，而不是阻止程序的执行。为了正常运行，你需要在命令前加上 `iex -S`。它的作用是在 `iex` 命令中运行 `mix`，这样它就会在一个特殊模式下运行程序，例如，调用 `IEx.pry` 就会停止程序的执行。

例如，`iex -S mix phx.server` 来调试 Phoenix 应用程序。在我们的例子中，要用 `iex -S test.exs` 来要求文件。

```shell
$ iex -r test.exs
Erlang/OTP 21 [erts-10.3.1] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [hipe] [dtrace]

warning: variable "b" is unused (if the variable is not meant to be used, prefix it with an underscore)
  test.exs:2

Request to pry #PID<0.107.0> at TestMod.sum/1 (test.exs:5)

    3:     b = 0
    4:
    5:     require IEx; IEx.pry
    6:
    7:     a + b

Allow? [Yn]
```

通过 `y` 或按回车键回复提示后，您就进入了交互模式。

```shell
$ iex -r test.exs
Erlang/OTP 21 [erts-10.3.1] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [hipe] [dtrace]

warning: variable "b" is unused (if the variable is not meant to be used, prefix it with an underscore)
  test.exs:2

Request to pry #PID<0.107.0> at TestMod.sum/1 (test.exs:5)

    3:     b = 0
    4:
    5:     require IEx; IEx.pry
    6:
    7:     a + b

Allow? [Yn] y
Interactive Elixir (1.8.1) - press Ctrl+C to exit (type h() ENTER for help)
pry(1)> a
34
pry(2)> b
0
pry(3)> a + b
34
pry(4)> continue
34

Interactive Elixir (1.8.1) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)>
BREAK: (a)bort (c)ontinue (p)roc info (i)nfo (l)oaded
       (v)ersion (k)ill (D)b-tables (d)istribution
```

要退出IEx，你可以按两次 `Ctrl+C` 键退出应用，或者键入 `continue` 转到下一个断点。

如你所见，你可以运行任何 Elixir 代码。但是，由于语言的不可更改性，你不能修改现有代码中的变量。但是，你可以得到所有变量的值，并运行任何计算。在这种情况下，`b` 被重新赋值为 0，结果是 `sum` 函数出现了错误。当然，即使是在第一次运行时，语言已经发现了这个 bug，但这只是个例子!

### Iex helpers
在使用 IEx 工作时，有一个比较烦人的地方，就是它没有你以前运行时使用的命令历史记录。为了解决这个问题，在 [IEx 文档](https://hexdocs.pm/iex/IEx.html#module-shell-history) 中有一个单独的小节，你可以在其中找到适合你所选择的平台的解决方案。

你也可以在 [IEx.Helpers 文档](https://hexdocs.pm/iex/IEx.Helpers.html) 中查看其他可用的帮助列表。

## Dialyxir 和 Dialyzer

[Dialyzer](http://erlang.org/doc/man/dialyzer.html)，全称就是 **DI**screpancy **A**na**LYZ**er for **ER**lang，它是一个静态代码分析工具。也就是说，它_阅读_和分析你的代码，但是不_执行_它们，比如说，寻找 bugs，无法触及的死代码等。

[Dialyxir](https://github.com/jeremyjh/dialyxir) 则是在 Elixir 里简化了 Dialyzer 使用的 mix 任务。  

Specification 可以帮助像 Dialyzer 这样的工具更好地理解代码。不像那些只能被人类阅读和理解的文档（假如存在或者写的足够好的话），`@spec` 使用了一些可以被机器理解的，更规范的语法。  

让我们把 Dialyxir 加到我们的项目里头吧。最简单的方式就是添加依赖到 `mix.exs` 文件中：  

```elixir
defp deps do
  [{:dialyxir, "~> 0.4", only: [:dev]}]
end
```

然后调用一下面的命令：  

```shell
$ mix deps.get
...
$ mix deps.compile
```

第一个命令下载并安装 Dialyxir。或许你会同时被要求安装 Hex。第二个命令编译 Dialyxir 应用。如果你想全局安装 Dialyxir，请参考它的[文档](https://github.com/jeremyjh/dialyxir#installation)。  

最后一个步骤就是要运行 Dialyzer 来重建 PLT（Persistent Lookup Table）。每次安装新版本的 Erlang 或者 Elixir 后，你都要做这一步。幸运地是，Dialyzer 不会每次使用的时候都去分析标准程序库。这个重建过程需要好几分钟才能下载完成。  

```shell
$ mix dialyzer --plt
Starting PLT Core Build ... this will take awhile
dialyzer --build_plt --output_plt /.dialyxir_core_18_1.3.2.plt --apps erts kernel stdlib crypto public_key -r /Elixir/lib/elixir/../eex/ebin /Elixir/lib/elixir/../elixir/ebin /Elixir/lib/elixir/../ex_unit/ebin /Elixir/lib/elixir/../iex/ebin /Elixir/lib/elixir/../logger/ebin /Elixir/lib/elixir/../mix/ebin
  Creating PLT /.dialyxir_core_18_1.3.2.plt ...
...
 done in 5m14.67s
done (warnings were emitted)
```

## 代码静态分析

Dialyxir 已经准备好了：  

```shell
$ mix dialyzer
...
examples.ex:3: Invalid type specification for function 'Elixir.Examples':sum_times/1. The success typing is (_) -> number()
...
```

Dialyzer 提示的信息已经很明确了：函数 `sum_times/1` 的返回值，和声明的不一样。因为 `Enum.sum/1` 返回的是 `number` 而不是一个 `integer`。但是 `sum_times/1` 的返回值声明为 `integer`。  

因为 `number` 并不是 `integer`，所以我们就得到了一个错误。那该怎么修改？我们可以使用 `round/1` 函数把 `number` 类型转换为 `integer`：  

```elixir
@spec sum_times(integer) :: integer
def sum_times(a) do
  [1, 2, 3]
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

最后：  

```shell
$ mix dialyzer
...
  Proceeding with analysis... done in 0m0.95s
done (passed successfully)
```
借助 specifications 就可以使用工具进行静态代码分析，并让代码变得更健壮和包含更少的 bugs。  

## 调试

有时，静态代码分析是不够的。要找到 bugs，理解代码的执行过程是必须的。最简单的方案发就是在代码里加上诸如 `IO.puts/2` 这样的代码来打印输出一些语句以便跟踪值的变化和代码执行过程。但是，这样的手段非常的原始，并有很多局限性。庆幸的是，我们可以使用 Erlang 的调试器来调试 Elixir 代码。  

现在我们来看一个基本的模块：  

```elixir
defmodule Example do
  def cpu_burns(a, b, c) do
    x = a * 2
    y = b * 3
    z = c * 5

    x + y + z
  end
end
```

然后运行 `iex`：  

```bash
$ iex -S mix
```

再运行调试器：  

```elixir
iex > :debugger.start()
{:ok, #PID<0.307.0>}
```

Erlang 的 `:debugger` 模块可以让我们访问调试器。我们可以使用 `start/1` 函数来对它进行配置：  

+ 通过传入文件路径来指定外部配置文件。  
+ 如果参数是 `:local` 或者 `:global`，调试器就会：  
    + `:global` - 调试器会解析所有已知节点的代码。这个是选项的默认值。  
    + `:local` - 调试器只会解析当前节点的代码。  

下一步就是把调试器挂载到我们的模块上：  

```elixir
iex > :int.ni(Example)
{:module, Example}
```

`:int` 模块是一个解析器。它能让我们创建断点，和一步步执行代码。  

当你打开调试器的时候，会出现类似的新窗口：  

![Debugger Screenshot 1]({% asset debugger_1.png @path %})

当我们把调试器挂载到要调试的模块时，它就会出现在左边的菜单：  

![Debugger Screenshot 2]({% asset debugger_2.png @path %})

### 创建断点

一个断点就是代码执行到指定位置后，会挂起的地方。有两种创建断点的方法：  

+ 在代码里调用 `:int.break/2`  
+ 通过调试器界面

让我们先在 IEx 尝试添加一个断点：  

```elixir
iex > :int.break(Example, 8)
:ok
```

这在 `Example` 模块代码的第 8 行处设定了一个断点。然后开始调用我们的函数：  

```elixir
iex > Example.cpu_burns(1, 1, 1)
```

在 IEx 中，代码的运行被挂起了，调试器窗口显示如下：  

![Debugger Screenshot 3]({% asset debugger_3.png @path %})

另一个窗口会显示出当前执行的源代码：  

![Debugger Screenshot 4]({% asset debugger_4.png @path %})

在这个窗口中，我们可以查看变量的值，跳到下一行代码，或者执行表达式。调用 `:int.disable_break/2` 就能够禁用断点：  

```elixir
iex > :int.disable_break(Example, 8)
:ok
```

我们可以调用 `:int.enable_break/2` 来重新开启一个断点，或者通过如下命令删除断点：  

```elixir
iex > :int.delete_break(Example, 8)
:ok
```

在调试器窗口也有同样的操作选项。在顶层菜单，__Break__，我们可以选择 __Line Break__ 并设置断点。如果我们选择了一行没有代码的涤烦设置了断点，它会被忽略，但是依然会在调试器窗口出现。断点的类型有三种：  

+ 行断点 - 调试器到达目标行时，挂起执行。这种断点通过 `:int.break/2` 设置。  
+ 条件断点 - 和行断点类似，但是调试器只有在满足特定条件的时候才会挂起代码。`:int.get_binding/2` 可以获取绑定的条件变量。  
+ 函数断点 - 调试器会在函数的第一行挂起。这种断点通过 `:int.break_in/3` 配置。  

准备就绪！调试快乐！  
