%{
  version: "1.0.1",
  title: "管線運算子",
  excerpt: """
  管線運算子 `|>` ，傳遞一個表達式的結果作為另一個表達式的第一個參數 (parameter)。
  """
}
---

## 簡介

編寫程式的過程可能變得雜亂。實際上，函數呼用是能夠混亂的難以判讀。參見以下巢狀函數：

```elixir
foo(bar(baz(new_function(other_function()))))
```

在這裡，我們將 `other_function/0` 的值傳遞給 `new_function/1`，而 `new_function/1` 傳給 `baz/1` ，接著 `baz/1` 傳給 `bar/1`，最後 `bar/1` 傳到 `foo/1`。 Elixir 通過管線運算子來解決這個語法混亂的問題。管線運算子看起來像 `|>` *採用一個表達式的結果，並將其傳遞*。 來看看上述範例改用管線運算子重寫後的程式碼片段。

```elixir
other_function() |> new_function() |> baz() |> bar() |> foo()
```

管線運算子採用它左側的結果，並將其傳遞到右側。

## 範例

我們將使用 Elixir String 模組做為這組範例。

- Tokenize 字串 (loosely)

```elixir
iex> "Elixir rocks" |> String.split()
["Elixir", "rocks"]
```

- 大寫 (Uppercase) 所有的 tokens

```elixir
iex> "Elixir rocks" |> String.upcase() |> String.split()
["ELIXIR", "ROCKS"]
```

- 驗證字串末端

```elixir
iex> "elixir" |> String.ends_with?("ixir")
true
```

## 最佳實踐

如果函數的引數數目 (arity) 超過 1，則確保使用括號。這對於 Elixir 來說無關緊要，但是對於其他可能會誤解你程式碼的程式設計師來說，這很重要。
這對管線運算子來說也確實很重要。例如，如果我們拿第三個例子，並從 `String.ends_with?/2` 中刪除括號，我們會遇到下面的警告。

```shell
iex> "elixir" |> String.ends_with? "ixir"
warning: parentheses are required when piping into a function call. For example:

  foo 1 |> bar 2 |> baz 3

is ambiguous and should be written as

  foo(1) |> bar(2) |> baz(3)

true
```
