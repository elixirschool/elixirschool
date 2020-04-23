---
version: 1.0.1
title: 调试
---

臭虫（Bugs）可谓是任何项目都无法避免的存在，所以调试也不可或缺。本课程我们将学习如何调试 Elixir 代码，并使用静态分析工具来帮助寻找可能存在的 bugs。  

{% include toc.html %}

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
