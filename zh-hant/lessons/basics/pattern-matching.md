---
version: 1.0.2
title: 模式比對
---

模式比對是 Elixir 中一個強大的部分。它使我們能夠比對簡單的值、資料結構甚至函數。在本課中，我們將開始了解如何使用模式比對。

{% include toc.html %}

## 比對 (Match) 運算子

你準備好了嗎? 在 Elixir 中，`=` 運算子實際上是一個比對運算子，與代數中的等號相當。使用它整個表達式將變成一個等式，並且讓 Elixir 將左邊的值與右邊的值進行比對。如果比對成功，則回傳等式的值。否則，它會回傳一個錯誤。讓我們來看看：

```elixir
iex> x = 1
1
```

現在來看一下簡單的比對例子：

```elixir
iex> 1 = x
1
iex> 2 = x
** (MatchError) no match of right hand side value: 1
```

接著試用在我們知道的集合例子：

```elixir
# Lists
iex> list = [1, 2, 3]
[1, 2, 3]
iex> [1, 2, 3] = list
[1, 2, 3]
iex> [] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

iex> [1 | tail] = list
[1, 2, 3]
iex> tail
[2, 3]
iex> [2 | _] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

# Tuples
iex> {:ok, value} = {:ok, "Successful!"}
{:ok, "Successful!"}
iex> value
"Successful!"
iex> {:ok, value} = {:error}
** (MatchError) no match of right hand side value: {:error}
```

## Pin 運算子

當比對的左側包含變數時，比對運算子將執行賦值。在某些情況下，這種變數重新宣告 (rebinding) 行為是我們不希望的。而對於這些情況，我們使用 pin 運算子： `^`。

當我們固定 (pin) 一個變數時，我們會比對現有的值，而不是重新宣告一個新值。現在來看看這是如何實現的：

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

Elixir 1.2 在映射鍵值和函數子句中介紹了將支援固定 (pin) 操作：

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

一個在函數子句中的固定 (pinning) 例子：

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
iex> greeting
"Hello"
```

注意在 `"Mornin'"` 中的例子中，`greeting` 重新分配給 `"Mornin'"` 只發生在函數內部。函數 `greeting` 之外仍然是 `"Hello"`。
