---
version: 1.0.0
title: 函數
redirect_from:
  - /lessons/basics/functions/
---

在 Elixir 和許多函數式語言中，函數是一等公民。本課程將會學習 Elixir 中的函數類型、它們因何與眾不同，以及如何使用它們。

{% include toc.html %}

## 匿名 (Anonymous) 函數

正如函數名稱所暗示的，匿名函數沒有名字。同時與我們在 `Enum` 課程中看到的那樣，匿名函數經常被傳遞給其他函數。 為了在 Elixir 中定義一個名函數，我們需要 `fn` 和 `end` 來做為關鍵字。在這兩個關鍵字之間，我們可以定義任意數量由 `->` 分隔的參數 (parameters) 和函數主體 (bodies)。

現在來看一個基本的例子：

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

###  & 簡寫符號

在 Elixir 中使用匿名函數是非常普遍的做法，因此有一個使用簡寫符號的書寫法：

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

正如你可能猜到的那樣，在簡寫變體中我們的參數可以用 `&1` 、 `&2` 和 `&3` 等等。

## 模式比對

模式比對不僅限於 Elixir 中的變數，同時可以應用於函數簽章 (signatures)，我們將在本節中看到。

Elixir 使用模式比對來識別相配的第一組參數，接著執行相對應的函數：

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
iex> handle_result.({:ok, some_result})
Handling result...

iex> handle_result.({:error})
An error has occurred!
```

## 命名 (Named) 函數

我們可以用名字來定義函數，以便稍後可以很容易地引用它們。在模組中，定義命名函數使用 `def` 做為關鍵字。我們將在接下來的課程中學習更多關於模組的內容，現在我們將單單專注於命名函數。

在模組中定義的函數可供其他模組使用。這是 Elixir 中一個特別有用的構建區塊 (building block)：

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

如果函數主體只有一行，可以用 `do:` 來進一步縮短：

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

借助我們對模式比對的了解，讓我們探索使用命名函數的遞迴 (recursion)：

```elixir
defmodule Length do
  def of([]), do: 0
  def of([_ | tail]), do: 1 + of(tail)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### 函數命名和引數數目 (Arity)

我們前面提到，函數是通過給定名稱和引數數目 (arity) 的組合來命名的。這意味著你可以做這樣的事情：

```elixir
defmodule Greeter2 do
  def hello(), do: "Hello, anonymous person!"   # hello/0
  def hello(name), do: "Hello, " <> name        # hello/1
  def hello(name1, name2), do: "Hello, #{name1} and #{name2}"
                                                # hello/2
end

iex> Greeter2.hello()
"Hello, anonymous person!"
iex> Greeter2.hello("Fred")
"Hello, Fred"
iex> Greeter2.hello("Fred", "Jane")
"Hello, Fred and Jane"
```

我們在上面的註釋中列出了函數名稱。第一個實現 (implementation) 不接受引數 (arguments)，所以它被稱為 `hello/0`；第二個則接受一個引數，所以它被稱為 `hello/1`，依此類推。與某些其他語言中的函數重載 (function overloads) 不同，這些被認為是彼此 _不同_ 的函數。(前面提過的模式比對只有當函數名字與引數數量都 _相同_ 時才適用）。

### 私有 (Private) 函數

當我們不想讓其他模組存取某個特定的函數時，我們可以讓這個函數被保密。私有函數只能從自己的模組中呼用。在 Elixir 中，我們使用 `defp` 來定義：

```elixir
defmodule Greeter do
  def hello(name), do: phrase <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### 監視 (Guards)

我們在 [Control Structures](../control-structures) 課程中簡要地介紹了監視 (guards)，現在我們來看看如何應用到命名函數上。一旦 Elixir 配對了一個函數，任何現有的監視語句 (guards) 都將被檢驗。

在下面的例子中，我們有兩個具有相同簽章的函數，我們依靠監視 (guards) 來決定使用何種引數類型 (argument's type) 的函數：

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase() <> name
  end

  defp phrase, do: "Hello, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"
```

### 預設 (Default) 引數值

如果我們需要定義引數的預設值，使用 `argument \\ value` 語法：

```elixir
defmodule Greeter do
  def hello(name, language_code \\ "en") do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello("Sean", "en")
"Hello, Sean"

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.hello("Sean", "es")
"Hola, Sean"
```

當我們把監視的用法和預設的引數值結合起來時，會遇到一個問題。現在來看看會是什麼樣的情形：

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code \\ "en") when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) iex:31: definitions with multiple clauses and default values require a header. Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b) do ... end

one should write:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end

def hello/2 has multiple clauses and defines defaults in one or more clauses
    iex:31: (module)
```

Elixir 不喜歡多重比對函數中的預設引數值，因可能會造成混淆。我們加上一個帶有預設引數值的函數標頭 (head) 來處理這個問題：

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en")
  def hello(names, language_code) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code) when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "es"
"Hola, Sean, Steve"
```
