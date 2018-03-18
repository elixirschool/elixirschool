---
version: 1.0.2
title: Enum 模块
---

一些枚举集合元素的算法。

{% include toc.html %}

## Enum

`Enum` 模块提供了超过一百个函数，和我们上节课提到的集合交互。

这节课程我们只会覆盖一部分函数，不过我们随时都可以自己去了解。
让我们在 IEx 里做个小试验。

```elixir
iex
iex> Enum.__info__(:functions) |> Enum.each(fn({function, arity}) ->
...>   IO.puts "#{function}/#{arity}"
...> end)
all?/1
all?/2
any?/1
any?/2
at/2
at/3
...
```

通过上面的命令，很明显能看到我们有很多函数，而且这些函数都是师出有名。
集合在函数式编程中处于核心地位，同时也是非常有用的部分。
通过利用它与Elixir的其他优势相结合，比如我们刚看到的，文档是一等公民，可以赋予开发人员非常强大的能力。

要想了解全部的函数，请访问官方的 [`Enum`](https://hexdocs.pm/elixir/Enum.html) 文档。而要想了解惰性枚举（lazy enumeration），访问 [`Stream`](https://hexdocs.pm/elixir/Stream.html) 模块。


### all?

使用 `all?` 以及大部分 `Enum` 函数的时候，我们要提供一个函数来作用到要操作的集合上。只有当函数在所有的元素上都返回 `true` 的时候，`all?` 才会返回 `true`，否则结果就是 `false`。

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

和上面不同，只要有一个元素被函数调用返回 `true`，`any?` 就会返回 `true`。

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk_every/2

如果你想把你的集合拆分成小的分组，`chunk_every/2` 就是你要找的函数：

```elixir
iex> Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

`chunk_every/2` 还有其他选项，在这里不深入介绍。如果感兴趣，前往 [`chunk_every/4`](https://hexdocs.pm/elixir/Enum.html#chunk_every/4) 的官方文档去了解。

### chunk_by

如果不按照数量分组（每组的元素数量相同），我们可以使用 `chunk_by` 方法。它接受一个枚举值和一个函数作为参数，如果函数的返回值变了，就是从新从后开始分组：

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
iex> Enum.chunk_by(["one", "two", "three", "four", "five", "six"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"], ["six"]]
```

### map_every

有时候把集合分组并不能满足我们的需求。这时候 `map_every/3` 在修改集合中特定元素的时候会非常有用：

```elixir
iex> Enum.map_every([1, 2, 3, 4], 2, fn x -> x * 2 end)
[2, 2, 6, 4]
```

### each

有时候需要遍历某个集合进行操作，但是不想产生新的值（不把函数的遍历调用结果返回），这种情况下，可以使用 `each`：

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
:ok
```

__注意__：`each` 函数会返回原子 `:ok`

### map

要把某个元素都执行某个函数，并且把结果作为新的集合返回，要使用 `map` 函数：

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

`min/1` 在集合中找到最小的值：

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

`min/2` 也一样，但是它允许我们提供一个匿名函数指定计算最小值的方法：

```elixir
iex> Enum.min([], fn -> :foo end)
:foo
```

### max

`max/1` 返回集合中最大的值：

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

`max/2` 也一样，而且像 `min/2` 一样，它允许我们提供一个匿名函数指定计算最大值的方法：

```elixir
iex> Enum.max([], fn -> :bar end)
:bar
```

### reduce

使用 `reduce`，我们可以把集合不断计算，最终得到一个值。我们需要提供一个可选的累加值（在这个例子中是 `10`），如果没有累加值，集合中的第一个值会被使用。

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16
iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6
iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
```

### sort

对集合进行排序，Elixir 提供了两个 `sort` 函数来帮忙。第一个使用 Elixir 默认的排序规则进行排序：

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

另外 `sort` 允许我们自己提供排序函数：

```elixir
# with our function
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# without
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq_by

我们可以使用 `uniq_by/2` 删除集合中的重复元素：

```elixir
iex> Enum.uniq_by([1, 2, 3, 2, 1, 1, 1, 1, 1], fn x -> x end)
[1, 2, 3]
```

这跟我们以前都熟悉的 `uniq/1` 函数一样，但是这个函数在 Elixir 1.4 中被弃用，不过你还是可以使用它（会收到一个警告信息）。
