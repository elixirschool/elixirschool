---
version: 1.0.3
title: Specifications and types
---

这节课我们学习 `@spec` 和 `@type` 语法. `@spec` 不仅仅是一个写文档的语法补充, 它还可以被工具用来进行分析. `@type` 则帮助我们写更易读易懂的代码.

{% include toc.html %}

## 简介

通常你可能会希望描述所写函数的接口. 那么你可以使用 [@文档注解](../../basics/documentation), 但这部分信息并不能在编译时用来做检查. 出于这个原因 Elixir 有 `@spec` 注解用来描述函数的定义, 并且会被编译器检查.

然而在某些情况下定义会非常的多并且复杂. 如果希望减少复杂度, 你会想要采用自定义的类型. Elixir 有 `@type` 注解可以做到. 另一方面 Elixr 始终是一个动态语言. 这意味着所有类型的信息会被编译器忽略, 但会被其他工具使用.

## Specification

如果你有 Java 的经验, 可能会认将 specification 理解为一个`接口(interface)`. Specification 定义了函数的参数和返回值应该是什么类型的.

为了定义输入和输出的类型, 在函数定义的前面我们使用 `@spec` 指令, 作为 `参数` 的有函数的名称, 函数参数类型的列表, `::` 后是返回值的类型.

让我们看一个例子:

```elixir
@spec sum_product(integer) :: integer
def sum_product(a) do
  [1, 2, 3]
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
end
```

当我们调用这个函数的时候, 一个有效的结果将会被返回, 一切看起来都很好. 但函数 `Enum.sum` 返回一个 `number` 而不是 我们在`@spec`中预期的 `integer` 类型. 这将会成为 bug 源头! 有类似 Dialyzer 这样的工具可以通过静态分析帮助我们发现这类的 bug. 我们将在另一节课讨论它们.

## 自定义类型（Custom types）

写 specification 是非常好的, 但有时候函数会使用更复杂的数据结构而不是简单的数字和集合. 这种函数的 `@spec` 会非常难被其他开发者理解和修改. 有时候函数需要大量的参数或者返回类型复杂的数据. 代码中会有很多潜在的坏习惯(bad smells), 长的参数列表就是其中之一. 在面向对象的语言中像Ruby 或 Java 我们可以轻松的定义类来帮助我们解决这个问题。 Elixir 并没有类但却可以轻易的扩展, 我们可以定义我们自己的类型。

Elixir 包含了一些如: `integer`, `pid` 这样的基础类型. 你可以在[官方文档](https://hexdocs.pm/elixir/typespecs.html#types-and-their-syntax)中找到可用的完整列表。

### 定义自定义类型

让我们编辑 `sum_times` 函数来引入一些额外的参数:

```elixir
@spec sum_times(integer, %Examples{first: integer, last: integer}) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

我们引入了一个 `Examples` 模块的结构体, 包含了两个字段: `first`, `last`. 这是一个构建 `Range` 模块的简易版结构体. 更多的关于结构体的信息可以查看[模块](../../basics/modules/#structs)部分. 想象一下我们在很多地方都需要 `Examples` 结构体. 写这么又长又复杂的 specification 会非常烦, 并且也可能会成为 bug 的来源. 一个解决这个问题的方法就是 `@type`.

Elixir 有3种关于类型的指令：

  - `@type` – 简单，公开的类型。类型内部的结构是公开的。
  - `@typep` – 类型是私有的并且只能在模块定义的地方使用。
  - `@opaque` – 类型是公开的，但内部结构是私有的。

来定义一下我们的类型：

```elixir
defmodule Examples do
  defstruct first: nil, last: nil

  @type t(first, last) :: %Examples{first: first, last: last}

  @type t :: %Examples{first: integer, last: integer}
end
```

我们已经定义了类型 `t(first, last)`，它是结构体 `%Examples{first: first, last: last}` 的表现形式。这回我们看到了类型也可以携带参数，尽管如此我们还是定义了一个类型 `t` 来表示结构体 `%Examples{first: integer, last: integer}`。

它们有什么区别？ 第一个表示结构体中的两个 key 可以是任意类型. 第二个表示结构体中的 key 是整数(`integer`)类型。这意味着代码可以像这样：

```elixir
@spec sum_times(integer, Examples.t()) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

和下面的代码等价:

```elixir
@spec sum_times(integer, Examples.t(integer, integer)) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

### 类型的文档（Documentation of types）

最后一个我们需要谈论的是如何为我们添加文档。如我们从 [文档](../../basics/documentation) 这节课学到的, `@doc` 和 `@moduledoc` 注解可以为函数和模块创建文档。为我们的类型创建文档可以使用 `@typedoc`：

```elixir
defmodule Examples do
  @typedoc """
      Type that represents Examples struct with :first as integer and :last as integer.
  """
  @type t :: %Examples{first: integer, last: integer}
end
```

指令 `@typedoc` 与 `@doc`, `@moduledoc` 相似。
