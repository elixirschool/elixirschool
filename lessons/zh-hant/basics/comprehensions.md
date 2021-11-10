%{
  version: "1.1.0",
  title: "解析",
  excerpt: """
  列表解析 (List comprehensions) 是在 Elixir 中通過列舉來循環 (looping) 的語法糖 (syntactic sugar)。在本課程中，我們將看看如何使用解析 (comprehensions) 來進行疊代 (iteration) 和生成 (generation)。
  """
}
---

## 基礎

在很多時候，解析可以用來為 `Enum` 和 `Stream` 疊代產生更簡潔的語句。讓我們先看一個簡單的解析，然後再拆解它的結構：

```elixir
iex> list = [1, 2, 3, 4, 5]
iex> for x <- list, do: x*x
[1, 4, 9, 16, 25]
```

我們注意到的第一件事是使用 `for` 和生成器 (generator)。生成器是什麼？生成器是在列表解析中找到的 `x <- [1, 2, 3, 4]` 表達式，它負責產生下一個值。

對我們來說幸運的是，解析不僅限於列表，實際上它能在任何列舉上使用：

```elixir
# Keyword Lists
iex> for {_key, val} <- [one: 1, two: 2, three: 3], do: val
[1, 2, 3]

# Maps
iex> for {k, v} <- %{"a" => "A", "b" => "B"}, do: {k, v}
[{"a", "A"}, {"b", "B"}]

# Binaries
iex> for <<c <- "hello">>, do: <<c>>
["h", "e", "l", "l", "o"]
```

如同 Elixir 中的許多其他東西，生成器依靠模式比對將其輸入集 (input set) 與左側變數進行比較。在無法找到配對的情況下，該值將被忽略：

```elixir
iex> for {:ok, val} <- [ok: "Hello", error: "Unknown", ok: "World"], do: val
["Hello", "World"]
```

可以同時使用多個生成器，就像巢狀迴圈一樣 (nested loops)：

```elixir
iex> list = [1, 2, 3, 4]
iex> for n <- list, times <- 1..n do
...>   String.duplicate("*", times)
...> end
["*", "*", "**", "*", "**", "***", "*", "**", "***", "****"]
```

為了更好地說明正在執行的循環，我們使用 `IO.puts` 來顯示兩個被生成的值：

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

列表解析是語法糖，只有在適當的時候才應該使用。

## 篩選器 (Filters)

可以把篩選器看作是解析式的監視 (guard)。當篩選值回傳 `false` 或 `nil` 時，它將被排除在最終列表之外。讓我們在一個範圍內循環，並只注意偶數。我們將使用 Integer 模組中的 `is_even/1` 函數來檢查一個值是否是偶數。

```elixir
import Integer
iex> for x <- 1..10, is_even(x), do: x
[2, 4, 6, 8, 10]
```

如同生成器 (generators)，可以同時使用多個篩選器。現在擴展範圍，然後僅對偶數且可被 3 整除的值進行篩選。

```elixir
import Integer
iex> for x <- 1..100,
...>   is_even(x),
...>   rem(x, 3) == 0, do: x
[6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 78, 84, 90, 96]
```

## 使用 :into

如果想產生一個列表 (list) 以外的東西呢？加入 `:into` 選項，就可以做到這一點！經驗上來說， `:into` 接受任何能實現 `Collectable` 協定的結構。

要使用 `:into`，讓我們從關鍵字列表中建立一個映射：

```elixir
iex> for {k, v} <- [one: 1, two: 2, three: 3], into: %{}, do: {k, v}
%{one: 1, three: 3, two: 2}
```

由於二進位 (binaries) 也是可群集 (collectables) 的，所以可以使用列表解析和 `:into` 來建立字串：

```elixir
iex> for c <- [72, 101, 108, 108, 111], into: "", do: <<c>>
"Hello"
```

就這樣！列表解析是能以簡潔方式疊代群集的簡單方法。
