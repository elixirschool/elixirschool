---
version: 0.9.0
title: 组合
---

根据以往的经验，我们知道把所有的函数都放到同一个文件是不可控的。这节课我们就讲一下如何给函数分组，以及如何定义一种叫结构体的特殊字典来有效地组织代码。

{% include toc.html %}

## 模块

模块是把函数组织到不同命名空间的最好方法，除了能为函数分组，它还允许我们定义命名函数和私有函数，这个已经在前面讲过。

我们来看一个简单的例子：

``` elixir
defmodule Example do
  def greeting(name) do
    "Hello #{name}."
  end
end

iex> Example.greeting "Sean"
"Hello Sean."
```

Elixir 也允许嵌套的模块，这让你可以轻松定义多层命名空间：

```elixir
defmodule Example.Greetings do
  def morning(name) do
    "Good morning #{name}."
  end

  def evening(name) do
    "Good night #{name}."
  end
end

iex> Example.Greetings.morning "Sean"
"Good morning Sean."
```

### 模块属性

模块的属性通常被用作常量，来看一下简单的例子：

```elixir
defmodule Example do
  @greeting "Hello"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

需要注意有些属性是保留的，最常用到的三个为：

+ `moduledoc` — 当前模块的文档
+ `doc` — 函数和宏的文档
+ `behaviour` — 使用 OTP 或者用户定义的行为

## 结构体

结构体是字典的特殊形式，它们的键是预定义的，一般都有默认值。结构体必须定义在某个模块内部，因此也必须通过模块的命名空间来访问。
在一个模块里只定义一个结构体是一种常用的手法。

要定义一个结构体，我们使用 `defstruct` 关键字，后面跟着关键字列表和默认值：

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

我们来创建一些结构体：

```elixir
iex> %Example.User{}
%Example.User{name: "Sean", roles: []}

iex> %Example.User{name: "Steve"}
%Example.User{name: "Steve", roles: []}

iex> %Example.User{name: "Steve", roles: [:admin, :owner]}
%Example.User{name: "Steve", roles: [:admin, :owner]}
```

我们也可以像更新图（map）那样更新结构体：

```elixir
iex> steve = %Example.User{name: "Steve", roles: [:admin, :owner]}
%Example.User{name: "Steve", roles: [:admin, :owner]}
iex> sean = %{steve | name: "Sean"}
%Example.User{name: "Sean", roles: [:admin, :owner]}
```

更重要的是：结构体可以匹配图（maps）：

```elixir
iex> %{name: "Sean"} = sean
%Example.User{name: "Sean", roles: [:admin, :owner]}
```
