---
layout: page
title: 函数
category: basics
order: 7
lang: cn
---

Elixir 和其他函数式语言一样，函数都是一等公民。我们将学习 Elixir 中不同类型的函数，它们与众不同的地方，以及如何使用它们。

{% include toc.html %}

## 匿名函数

就像名字中说明的那样，匿名函数没有名字。我们在 `Enum` 课程中看到过，它们经常被用来传递给其他函数。
要定义匿名函数，我们需要 `fn` 和 `end` 关键字，在这两者之间，我们可以定义任意数量的参数和函数体，它们用 `->` 分隔开。

我们来看一个简单的例子：

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

###  & 操作符

因为在 Elixir 中使用匿名函数非常常见，所以有一个快捷方式来做这件事：

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

你可能也猜到了，在这种简写的模式下，函数的参数可以通过 `&1`，`&2`，`&3` 等来获取。

## 模式匹配

在 Elixir 中模式匹配不仅限于变量，也可以用在函数签名上，我们在后面章节会看到这个功能。
Elixir 使用模式匹配来找到第一个匹配参数的模式，然后执行它后面的函数体。

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
iex> handle_result.({:ok, some_result})
Handling result...

iex> handle_result.({:error})
An error has occurred!
```

## 命名函数
我们也可以定义有名字的函数，这样在后面可以直接用名字来使用它。命名函数通过 `def` 关键字定义在某个模块中，关于模块，我们会在后面的课程中详细学习，
现在我们只关心命名函数。

定义在模块内部的函数可以被其他模块使用，这在 Elixir 中构建代码块非常有用：

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

如果我们的函数体只有一行，我们可以缩写成 `do:`：

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

学到了那么多模式匹配的知识，现在我们用命名函数实现递归：

```elixir
defmodule Length do
  def of([]), do: 0
  def of([_|t]), do: 1 + of(t)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### 私有函数

如果我们不想其他模块使用某个函数，我们可以使用私有函数，也就是只能被它所在模块调用的函数。在 Elixir 中，我们可以用 `defp` 来定义私有函数：

```elixir
defmodule Greeter do
  def hello(name), do: phrase <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) undefined function: Greeter.phrase/0
    Greeter.phrase()
```

### 卫兵

我们在[控制语句](../control-structures.md)那一个提过卫兵，现在我们就来看看怎么在命名函数中使用它们。当 Elixir 匹配某个函数之后，后面的卫兵都会被检测。

在下面的例子中，我们定义了两个有相同签名的函数，而依赖判断参数类型的卫兵来确定调用哪个函数：

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase <> name
  end

  defp phrase, do: "Hello, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"
```

### 参数默认值

如果想给参数设置默认值，我们可以用 `argument \\ value` 语法：

```elixir
defmodule Greeter do
  def hello(name, country \\ "en") do
    phrase(country) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello("Sean", "en")
"Hello, Sean"

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.hello("Sean", "es")
"Hola, Sean"
```

当我们同时使用卫兵和默认参数值的时候，会遇到问题，先看一下程序会报什么错：

```elixir
defmodule Greeter do
  def hello(names, country \\ "en") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(country)
  end

  def hello(name, country \\ "en") when is_binary(name) do
    phrase(country) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) def hello/2 has default values and multiple clauses, define a function head with the defaults
```

Elixir 在处理多个匹配函数的时候，不喜欢默认参数这种模式，因为它很容易让人混淆。要处理这种情况，我们可以添加一个设置了默认参数值的函数头部：

```elixir
defmodule Greeter do
  def hello(names, country \\ "en")
  def hello(names, country) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(country)
  end

  def hello(name, country) when is_binary(name) do
    phrase(country) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "es"
"Hola, Sean, Steve"
```
