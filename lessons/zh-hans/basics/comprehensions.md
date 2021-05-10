%{
  version: "1.1.1",
  title: "推导",
  excerpt: """
  在 Elixir 中，列表推导是循环遍历枚举值的语法糖。这节课，我们就来看看如何使用推导式进行遍历。
  """
}
---

## 基础

很多时候，使用推导能使用更简洁的表达式来遍历 Enum 和 Stream。我们先看一个简单的例子，然后分析它的结构：

```elixir
iex> list = [1, 2, 3, 4, 5]
iex> for x <- list, do: x*x
[1, 4, 9, 16, 25]
```

首先注意 `for` 和生成器的使用。什么是“生成器”呢？生成器就是上面 `x <- [1, 2, 3, 4]` 表达式部分，它们用来生成下一个值。

幸运的是，推导式不仅可以用在列表上，它们实际上可用在任何可遍历类型。

```elixir
# 关键字列表
iex> for {_key, val} <- [one: 1, two: 2, three: 3], do: val
[1, 2, 3]

# 映射
iex> for {k, v} <- %{"a" => "A", "b" => "B"}, do: {k, v}
[{"a", "A"}, {"b", "B"}]

# 二进制
iex> for <<c <- "hello">>, do: <<c>>
["h", "e", "l", "l", "o"]
```

和 Elixir 很多东西一样，生成器也依靠模式匹配来比较它们的输入和左边的变量。如果匹配没有找到，对应的值就直接被忽略：

```elixir
iex> for {:ok, val} <- [ok: "Hello", error: "Unknown", ok: "World"], do: val
["Hello", "World"]
```

也可以同时使用多个生成器，达到类似嵌套循环的效果：

```elixir
iex> list = [1, 2, 3, 4]
iex> for n <- list, times <- 1..n do
...>   String.duplicate("*", times)
...> end
["*", "*", "**", "*", "**", "***", "*", "**", "***", "****"]
```

为了更清晰地展示循环的内容，我们用 `IO.puts` 来打印出生成的两个值：

```elixir
iex> for n <- list, times <- 1..n, do: IO.puts "#{n} - #{times}"
1 - 1
2 - 1
2 - 2
3 - 1
3 - 2
3 - 3
4 - 1
4 - 2
4 - 3
4 - 4
```

列表推导式只是语法糖，应该用在适当的地方。

## 过滤器（filters）

你可以把过滤器想象成推导式的哨兵（guard），如果被过滤的值返回是 `false` 或者 `nil`，那它就不会出现在最终的列表里。比如可以循环某个范围的值，但是只给出偶数。我们使用 `Integer` 模块提供的 `is_even/1` 函数来检查某个值是否为偶数：

```elixir
import Integer
iex> for x <- 1..10, is_even(x), do: x
[2, 4, 6, 8, 10]
```

和生成器一样，我们也可以使用多个过滤器。我们修改上面的例子，只返回所有是偶数并且能被 3 整数的值：

```elixir
import Integer
iex> for x <- 1..100,
...>   is_even(x),
...>   rem(x, 3) == 0, do: x
[6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 78, 84, 90, 96]
```

## 使用 :into

如果我们想生成的不是列表呢？`:into` 选项可以解决这个问题！`:into` 接受实现了 `Collectable` 协议的任何结构体。

让我们用 `:into` 从关键字列表中推导出一个映射：

```elixir
iex> for {k, v} <- [one: 1, two: 2, three: 3], into: %{}, do: {k, v}
%{one: 1, three: 3, two: 2}
```

因为二进制也是可以枚举的，所以我们可以使用推导式和 `:into` 来创建字符串：

```elixir
iex> for c <- [72, 101, 108, 108, 111], into: "", do: <<c>>
"Hello"
```

就这么多内容！列表推导式提供了一种简单的方式来精确地遍历集合。
