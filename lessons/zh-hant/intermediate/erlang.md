%{
  version: "1.0.1",
  title: "Erlang 互用性",
  excerpt: """
  在 Erlang VM（BEAM）之上構建的附加好處之一，就是有大量的現有函式庫可供使用。互用性 (Interoperability) 使我們能夠藉由 Elixir 程式碼即能利用這些函式庫和 Erlang 標準函式庫。在本課程中，將介紹如何存取隨第三方 Erlang packages 一起的標準函式庫功能。
  """
}
---

## 標準函式庫

Erlang 的大量標準函式庫可以從應用程式中的任何 Elixir 程式碼來存取。Erlang 模組由小寫字母 atoms 表示，例如 `:os` 和 `:timer`。

現在使用 `:timer.tc` 來計時執行一個給定的函數所需時間：

```elixir
defmodule Example do
  def timed(fun, args) do
    {time, result} = :timer.tc(fun, args)
    IO.puts("Time: #{time} μs")
    IO.puts("Result: #{result}")
  end
end

iex> Example.timed(fn (n) -> (n * n) * n end, [100])
Time: 8 μs
Result: 1000000
```

有關可用模組的完整清單，請參閱 [Erlang Reference Manual](http://erlang.org/doc/apps/stdlib/)。

## Erlang Packages

在之前的課程中，介紹了 Mix 與管理耦合性。而使用 Erlang 函式庫的工作原理也是一樣的。
如果事件所需的 Erlang 函式庫還沒有被推送到 [Hex](https://hex.pm)，你也可以參考 git 程式碼庫來代替：

```elixir
def deps do
  [{:png, github: "yuce/png"}]
end
```

現在，我們能夠存取 Erlang 函式庫：

```elixir
png =
  :png.create(%{:size => {30, 30}, :mode => {:indexed, 8}, :file => file, :palette => palette})
```

## 顯著差異

我們已經知道如何使用 Erlang，現在應該介紹一下 Erlang 的互用性問題。

### Atoms

Erlang atoms 看起來很像沒有冒號 (`:`) 的 Elixir atoms。它們由小寫字母字串和下底線所表示：

Elixir:

```elixir
:example
```

Erlang:

```erlang
example.
```

### 字串

在 Elixir 中，當談論字串時，是指 UTF-8 編碼的二進位格式。而在 Erlang 中，字串仍然使用雙引號，但引用字元列表 (char lists)：

Elixir:

```elixir
iex> is_list('Example')
true
iex> is_list("Example")
false
iex> is_binary("Example")
true
iex> <<"Example">> === "Example"
true
```

Erlang:

```erlang
1> is_list('Example').
false
2> is_list("Example").
true
3> is_binary("Example").
false
4> is_binary(<<"Example">>).
true
```

需要注意的是許多較舊版本的 Erlang 函式庫可能不支援二進位格式，因此需要將 Elixir 字串轉換為字元列表。不過謝天謝地，用 `to_charlist/1` 函數很容易實現：

```elixir
iex> :string.words("Hello World")
** (FunctionClauseError) no function clause matching in :string.strip_left/2
    (stdlib) string.erl:380: :string.strip_left("Hello World", 32)
    (stdlib) string.erl:378: :string.strip/3
    (stdlib) string.erl:316: :string.words/2

iex> "Hello World" |> to_charlist |> :string.words
2
```

### 變數

Elixir:

```elixir
iex> x = 10
10

iex> x1 = x + 10
20
```

Erlang:

```erlang
1> X = 10.
10

2> X1 = X + 1.
11
```

就這樣！在 Elixir 應用程式中利用 Erlang 可以輕鬆有效地將可用函式庫的數量增加一倍。
