---
version: 1.0.0
layout: page
title: 模式匹配
category: basics
order: 4
lang: cn
---

模式匹配是 Elixir 很强大的特性，它允许我们匹配简单值、数据结构、甚至函数。这篇课程，我们介绍如何使用模式匹配。

{% include toc.html %}

## 匹配操作符

做好心理准备了吗？Elixir 中，`=` 操作符就是我们的匹配操作符，它类似于数学中的等号。通过这个匹配操作符，会把整个表达式转变成一个等式，同时 Elixir 会用等式左边的值去匹配等式右边的值。如果匹配成功，会返回等式的值。否则就会抛出一个错误。让我们来看看：

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

iex> [1|tail] = list
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

## 大头针操作符（Pin operator）

正如上面我们所学到的，当模式匹配的左侧是一个变量，该模式匹配也会同时为变量绑定一个值。在某些情况下，这种给变量重新绑定值的行为并不是我们想要的。对于这种需求，我们有大头针操作符：`^`。

当我们在模式匹配中用大头针操作符钉住一个变量，就表明我们希望使用这个变量已经绑定的值，而不是给它重新绑定一个新的值。让我们来看几个例子：

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

在 Elixir 1.2 里，给 map 的键和函数语句引入了大头针操作符的支持：

```elixir
iex> key = "hello"
"hello"
iex> %{^key => value} = %{"hello" => "world"}
%{"hello" => "world"}
iex> value
"world"
iex> %{^key => value} = %{:hello => "world"}
** (MatchError) no match of right hand side value: %{hello: "world"}
```

大头针操作符在函数语句中使用的例子：

```elixir
iex> greeting = "Hello"
"Hello"
iex> greet = fn
...>   (^greeting, name) -> "Hi #{name}"
...>   (greeting, name) -> "#{greeting}, #{name}"
...> end
#Function<12.54118792/2 in :erl_eval.expr/5>
iex> greet.("Hello", "Sean")
"Hi Sean"
iex> greet.("Mornin'", "Sean")
"Mornin', Sean"
```
