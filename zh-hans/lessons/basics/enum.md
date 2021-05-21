---
version: 1.6.1
title: Enum 模块
---

一些枚举集合元素的算法。

{% include toc.html %}

## Enum

`Enum` 模块提供了超过70个操作枚举类型的函数。我们在[上一节](../collections)学到的集合类型中除了元组（tuple）之外都是枚举类型。

这节课程我们只会覆盖 Enum 模块的一部分函数，不过我们随时都可以自己去了解。
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
集合在函数式编程占有核心地位，结合 Elixir 的其他特性，它可以赋予开发人员非常强大的能力。

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

如果不按照数量分组（每组的元素数量相同），我们可以使用 `chunk_by` 方法。它接受一个枚举值和一个函数作为参数，如果函数的返回值变了，新的分组就从这里开始创建：

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
iex> Enum.chunk_by(["one", "two", "three", "four", "five", "six"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"], ["six"]]
```

### map_every

有时候把集合分组并不能满足我们的需求。这时候 `map_every/3` 在修改集合中特定元素的时候会非常有用：

```elixir
# Apply function every three items
iex> Enum.map_every([1, 2, 3, 4, 5, 6, 7, 8], 3, fn x -> x + 1000 end)
[1001, 2, 3, 1004, 5, 6, 1007, 8]
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

如果需要把执行结果做为一个新集合返回的话，可以使用`map` 函数：

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

### filter

`filter/2` 函数可以帮我们过滤集合，只留下能是我们提供的函数返回`true`的那些元素。

```elixir
iex> Enum.filter([1, 2, 3, 4], fn(x) -> rem(x, 2) == 0 end)
[2, 4]
```

### reduce

使用 `reduce/3`，我们可以把集合不断计算，最终得到一个值。我们需要提供一个可选的累加值（在这个例子中是 `10`），如果没有累加值，集合中的第一个值会被使用。

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

`sort/1` 使用了 Erlang 的 [数据比较规则](http://erlang.org/doc/reference_manual/expressions.html#term-comparisons) 来决定排序的顺序：

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

另外 `sort/2` 允许我们自己提供排序函数：

```elixir
# with our function
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# without
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq

我们可以使用 `uniq/1` 来删除集合中的重复元素：

```elixir
iex> Enum.uniq([1, 2, 3, 2, 1, 1, 1, 1, 1])
[1, 2, 3]
```

### uniq_by

`uniq_by/2` 也可以用来删除集合中的重复元素，只是它允许我们提供自定义的函数来作唯一性比较。

```elixir
iex> Enum.uniq_by([%{x: 1, y: 1}, %{x: 2, y: 1}, %{x: 3, y: 3}], fn coord -> coord.y end)
[%{x: 1, y: 1}, %{x: 3, y: 3}]
```




### 使用 & 操作符
Enum 模块中的很多函数接收一个 匿名函数 作为参数。

这些匿名函数往往可以使用 & 操作符来简写。

下面是一些例子，展现了如何在 Enum 模块中使用 & 操作符。 
每个例子在功能上都是等价的。

#### 用 & 操作符取代一个匿名函数

下面是一个经典的关于 `Enum.map/2` 的例子。使用了标准的匿名函数语法。

```elixir
iex> Enum.map([1,2,3], fn number -> number + 3 end)
[4, 5, 6]
```

现在我们用 & 操作符重写; 语法显而易见，我们用 `&(函数体)` 申明了一个匿名函数， 用`&1` 取代了第一个参数（在这里也是唯一一个参数）。

```elixir
iex> Enum.map([1,2,3], &(&1 + 3))
[4, 5, 6]
```

我们也可以进一步重写这个例子，将这个匿名函数分配给一个变量，然后再去调用 `Enum.map2`。

```elixir
iex> plus_three = &(&1 + 3)
iex> Enum.map([1,2,3], plus_three)
[4, 5, 6]
```

#### 在具名函数上使用 & 操作符

首先我们创建一个具名函数，然后通过一个在 `Enum.map/2` 中定义的匿名函数调用它。

```elixir
defmodule Adding do
  def plus_three(number), do: number + 3
end

iex>  Enum.map([1,2,3], fn number -> Adding.plus_three(number) end)
[4, 5, 6]
```

然后我们可以通过 & 操作符重写它

```elixir
iex> Enum.map([1,2,3], &Adding.plus_three(&1)) 
[4, 5, 6]
```

更简单的语法是，直接使用函数名，而不显式捕获变量
> 去掉`/1`会被认为是调用 `Adding.plus_three/0`
```elixir
iex> Enum.map([1,2,3], &Adding.plus_three/1) 
[4, 5, 6]
```
