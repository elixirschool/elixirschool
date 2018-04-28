---
version: 0.9.0
title: 模式匹配
---

模式匹配是 Elixir 很强大的特性，它允许我们匹配简单值、数据结构、甚至函数。这篇课程，我们介绍如何使用模式匹配。

{% include toc.html %}

匹配操作符
----------

做好心理准备了吗？Elixir 中，`=` 操作符就是我们的匹配操作符。通过这个匹配操作符，我们可以赋值和匹配值，我们来看一下：

```elixir
iex> x = 1
1
```

现在，试一些简单的匹配：

```elixir
iex> 1 = x
1
iex> 2 = x
** (MatchError) no match of right hand side value: 1
```

然后试一些刚学过的集合类型：

```elixir
# Lists
iex> list = [1, 2, 3]
iex> [1, 2, 3] = list
[1, 2, 3]
iex> [] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

iex> [1 | tail] = list
[1, 2, 3]
iex> tail
[2, 3]
iex> [2|_] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

# Tuples
iex> {:ok, value} = {:ok, "Successful!"}
{:ok, "Successful!"}
iex> value
"Successful!"
iex> {:ok, value} = {:error}
** (MatchError) no match of right hand side value: {:error}
```

Pin 操作符
----------

我们刚学到，当匹配的左边包含变量的时候，匹配操作符同时会做赋值操作。有些时候，这种行为并不是预期的，这种情况下，我们可以使用 `^` 操作符。

_这个例子直接取自 Elixir 的[官方指南](http://elixir-lang.org/getting-started/pattern-matching.html)_。

```elixir
iex> x = 1
1
iex> ^x = 2
** (MatchError) no match of right hand side value: 2
iex> {x, ^x} = {2, 1}
{2, 1}
iex> x
2
```
