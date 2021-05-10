%{
  version: "1.5.0",
  title: "列舉 (Enum)",
  excerpt: """
  一組在可列舉函數中的列舉演算法。
  """
}
---

## 列舉 (Enum)

`Enum` 模組包含超過 70 個可列舉 (enumerables) 的工作函數。
我們在 [previous lesson](../collections/)，中了解到的所有群集，除了元組之外，都為可列舉。

這個課程只涵蓋可用函數中的一個子集，但我們其實可以自己去測試它們。
讓我們在 IEx 中做一個小實驗。

```elixir
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

經由上述指令，很明顯的我們有很多函數，而且它們都有明確的存在原因。
列舉法 (Enumeration) 是函數式程式設計的核心，將其與 Elixir 的其他特性結合起來，能夠賦與開發者不可思議的強大能力。

有關函數的完整列表，請參考官方 [`Enum`](https://hexdocs.pm/elixir/Enum.html) 文件；惰性列舉 (lazy enumeration) 請使用 [`Stream`](https://hexdocs.pm/elixir/Stream.html) 模組。

### all?

當使用 `all?/2`，和眾多 `Enum` 時，我們提供一個適用於我們群集項目的函數。
在 `all?/2` 這個例子中，全部的群集必須回傳 `true` 否則只有 `false` 將被回傳：

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

不像前述的例子，假設至少有一個項目為 `true`， `any?/2` 即回傳 `true` ：

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk_every

如果你需要把群集分成更小的群組，`chunk_every/2` 就可能是你正在尋找的函數：

```elixir
iex> Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

`chunk_every/4` 有幾個選項，但我們還不會深入了解它，查看 [`the official documentation of this function`](https://hexdocs.pm/elixir/Enum.html#chunk_every/4) 來獲得更多資訊。

### chunk_by

如果我們需要根據大小以外的東西對我們的群集進行分組，我們可以使用 `chunk_by/2` 函數。
它需要一個給定的列舉和一個函數，而當該函數回傳值改變時，一個新群組將被觸發並開始創建下一個：

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
iex> Enum.chunk_by(["one", "two", "three", "four", "five", "six"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"], ["six"]]
```

### map_every

有時候，分類群集仍無法滿足我們的需求。
在這個例子中 `map_every/3`，能夠非常有效的對中 (hit) 每一個 `nth` 項目，且總是準確對中第一個需要被改變的值：

```elixir
# Apply function every three items
iex> Enum.map_every([1, 2, 3, 4, 5, 6, 7, 8], 3, fn x -> x + 1000 end)
[1001, 2, 3, 1004, 5, 6, 1007, 8]
```

### each

可能有必要迭代 (iterate) 一個群集而不產生新的值，對於這個例子我們使用 `each/2` ：

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
:ok
```

__註__: `each/2` 函數回傳 atom `:ok`。

### map

將函數應用到每個項目，並產生一個新的群集時，使用 `map/2` 函數：

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

`min/1` 在群集中找到最小值：

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

`min/2` 做同樣的事，但萬一列舉是空的，它允許我們指定一個函數來產生最小值。

```elixir
iex> Enum.min([], fn -> :foo end)
:foo
```

### max

`max/1` 回傳群集中的最大值：

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

`max/2` 相對 `max/1` 就如同 `min/2` 相對 `min/1` 一樣：

```elixir
iex> Enum.max([], fn -> :bar end)
:bar
```

### filter

`filter/2` 函數使我們有能力篩選集合，留下只包含使用所提供函數且計算後為 `true` 的那些元素。


```elixir
iex> Enum.filter([1, 2, 3, 4], fn(x) -> rem(x, 2) == 0 end)
[2, 4]
```

### reduce

通過 `reduce/3` 我們可以將我們的群集精煉成單一的值。為此，我們提供一個可選擇的累加器 (`10` 在這個例子中) 傳遞到我們的函數中；如果沒有提供累加器，則使用列舉中的第一個元素：

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16

iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6

iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
```

### sort

排序群集時有二個排序函數會較為簡易。

`sort/1` 使用 Erlang [Term 排序規則](http://erlang.org/doc/reference_manual/expressions.html#term-comparisons) 來確定排序順序：

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

`sort/2` 則允許我們提供自己的排序函數：

```elixir
# with our function
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# without
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq

可以使用 `uniq/1` 刪除列舉中的重複項目：

```elixir
iex> Enum.uniq([1, 2, 3, 2, 1, 1, 1, 1, 1])
[1, 2, 3]
```

### uniq_by

`uniq_by/2` 也從列舉中刪除重複項目，但是它允許提供一個函數來進行唯一性比較。

```elixir
iex> Enum.uniq_by([%{x: 1, y: 1}, %{x: 2, y: 1}, %{x: 3, y: 3}], fn coord -> coord.y end)
[%{x: 1, y: 1}, %{x: 3, y: 3}]
```
