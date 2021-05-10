%{
  version: "1.1.0",
  title: "文档模块",
  excerpt: """
  Documenting Elixir code.
  """
}
---

## 注解

如何写注释以及如何编写高质量的文档，这两个问题在编程界依然存在很多争论。然而，在代码中加入适当的文档或者注释很重要，这点是没有什么争议的。

Elixir把文档看作是*一等公民*，它提供了大量的函数来为项目创建和操作（access）文档。Elixir提供了多种方式来编写注释或者是注解。下面是其中三种方式：

  - `#` - 用于单行的注释
  - `@moduledoc` - 用于模块文档的注释
  - `@doc` - 用于函数的注释

### 单行注释

最简单的注释代码的方式可能是使用单行注释了。与Ruby或Python类似，Elixir的单行注释标识符为`#`，也就是井号。

看下这个Elixir Script (greeting.exs)：

```elixir
# Outputs 'Hello, chum.' to the console.
IO.puts("Hello, " <> "chum.")
```

对于每一行，Elixir会忽略`#`到行末的所有内容。这种注释不会影响到程序的执行，但是别人在阅读代码时它可能不会很容易地被看到。因此不要滥用单行注释。乱用注释可能成为别人的噩梦。适度使用就很好。

### 模块注释

`@moduledoc`提供模块级别的注释。这个注解一般放在模块定义的最前面，也就是`defmodule`后。下面的例子简单地展示了`@moduledoc`这个装饰器的用法。

```elixir
defmodule Greeter do
  @moduledoc """
  Provides a function `hello/1` to greet a human
  """

  def hello(name) do
    "Hello, " <> name
  end
end
```

用户可以在IEx里面通过`h`这个辅助函数看到我们在这个模块里定义的文档。

我们可以通过把 `Greeter` 模块移到一个新文件 `greeter.ex` 并编译来亲自试验一下。

```elixir
iex> c("greeter.ex", ".")
[Greeter]

iex> h Greeter

                Greeter

Provides a function hello/1 to greet a human
```

_注意_: 如果代码是在一个 mix 项目底下，我们并不需要像上面那样手动编译文件。只需要通过执行 `iex -S mix` 命令，IEx 控制台就可以加载当前项目。

### 函数注释

正如Elixir提供的模块级别的注释，它也为函数级别的注释提供了注释功能。`@doc`这个装饰器能够提供函数级别的文档注释。`@doc`装饰器使用的时候只需要放在函数定义前。

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

如果在IEx中输入这个函数并且带有`-h`参数时（别忘了输入模块名），你将会看到下列结果：

```elixir
iex> c("greeter.ex")
[Greeter]

iex> h Greeter.hello

                def hello(name)

Prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"

iex>
```

注意到我们是如何使用文档标记以及终端是怎么渲染这些文档的了么？这很不错吧，当你看到使用ExDoc模块能够动态地生成HTML文档时，你会觉得更有趣。

**注意：**`@spec`这个注解一般用于代码的静态分析。想了解更多的话，可以看下[Specifications and types](../../advanced/typespec)这个章节。

## ExDoc

ExDoc是Elixir的官方项目，你可以在 [GitHub](https://github.com/elixir-lang/ex_doc)上看到它。它用于给Elixir项目提供**在线HTML文档**。首先，先让我们用Mix创建一个新项目：

```bash
$ mix new greet_everyone

* creating README.md
* creating .formatter.exs
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/greet_everyone.ex
* creating test
* creating test/test_helper.exs
* creating test/greet_everyone_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd greet_everyone
    mix test

Run "mix help" for more commands.

$ cd greet_everyone

```

现在将`@doc`章节的`lib/greeter.ex`部分的代码复制粘贴过来，并确认这些代码依然能正常运行。既然我们现在要操作一个Mix项目，那么我们需要使用`iex -S mix`来在终端中打开这个项目：

```bash
iex> h Greeter.hello

                def hello(name)

Prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"
```

### 安装过程

假设一切都正常工作，那么你将看到和上面一样的输出，现在我们将配置ExDoc。在文件`mix.exs`中，添加两个依赖`:earmark` 和 `:ex_doc`。

```elixir
  def deps do
    [{:earmark, "~> 1.2", only: :dev},
    {:ex_doc, "~> 0.19", only: :dev}]
  end
```

使用`only: :dev`是因为我们不想在生产环境下下载和编译这些依赖。为什么需要Earmark呢？Earmark是一个使用Elixir编写的markdown分析器，ExDoc使用它来将带有`@moduledoc` 和 `@doc`的注释转换成漂亮的HTML页面。

你可以不使用Earmark。你可以将分析后端改为Pandoc、Hoedown或者Cmark；但是你得根据[这里的文档](https://github.com/elixir-lang/ex_doc#changing-the-markdown-tool)做一点配置工作。在这篇教程里面，我们将使用Earmark。

### 生成文档

继续刚才的工作，接下来需要输入两条命令：

```bash
$ mix deps.get # gets ExDoc + Earmark.
$ mix docs # makes the documentation.

Docs successfully generated.
View them at "doc/index.html".
```

如果一切顺利的话，你将会看到熟悉的成功提示消息。让我们看一下项目里面的**doc/**文件夹。里面有我们生成的文档。如果你使用浏览器打开它的话你将看到如下画面：

![ExDoc Screenshot 1](/images/documentation_1.png)

我们可以看到Earmark已经渲染了我们的Markdown注释文档并且ExDoc现在有漂亮的显示格式。

![ExDoc Screenshot 2](/images/documentation_2.png)

我们可以将这个文档部署到github，也可以部署到Elixir的官方镜像 [HexDocs](https://hexdocs.pm/)。

## 最佳实践

编写文档是编程的最佳实践。因为Elixir还很年轻，许多语言标准依然在随着它的生态发展而发展。Elixir的社区正在尝试进行这种最佳实践。你可以从[Elixir代码风格](https://github.com/niftyn8/elixir_style_guide)中了解到类似的最佳实践。

  - 总是给模块提供注释

```elixir
defmodule Greeter do
  @moduledoc """
  This is good documentation.
  """

end
```

  - 如果你不想给模块注释，**不要留空**。可以考虑给模块注解提供一个值为`false`的参数，就像下面这样：

```elixir
defmodule Greeter do
  @moduledoc false

end
```

 - 当在模块里面引用一个函数时，使用单引号将其括起来：

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 - `@moduledoc`下面的代码一行只写一句：

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  alias Goodbye.bye_bye
  # 就像上面这样...

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 - 使用markdown语法来编写文档。因为它能被ExDoc和IEx更好地解析：

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

 - 尝试在你的文档里面加入一些测试代码。 这将能够让你在模块 [ExUnit.DocTest][]的帮助下对模块、函数、宏等生成自动测试。为了做到这一点，你需要在你的测试用例中使用`doctest/1`这个宏。当然，你首先得看一下[ExUnit的官方文档][ExUnit.DocTest]。

[ExUnit.DocTest]: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html
