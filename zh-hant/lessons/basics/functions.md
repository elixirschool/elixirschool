---
version: 1.2.0
title: 函數
---

在 Elixir 和許多函數式語言中，函數是一等公民。
本課程將會學習 Elixir 中的函數類型、它們因何與眾不同，以及如何使用它們。

{% include toc.html %}

## 匿名 (Anonymous) 函數

正如函數名稱所暗示的，匿名函數沒有名字。
同時與我們在 `Enum` 課程中看到的那樣，匿名函數經常被傳遞給其他函數。
為了在 Elixir 中定義一個匿名函數，我們需要 `fn` 和 `end` 來做為關鍵字。
在這兩個關鍵字之間，我們可以定義任意數量由 `->` 分隔的參數 (parameters) 和函數主體 (bodies)。

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

Elixir 使用模式比對來檢查所有可能的比對選項，並選擇第一個吻合的選項來執行：

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:ok, _} -> IO.puts "This would be never run as previous will be matched beforehand."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
1
iex> handle_result.({:ok, some_result})
Handling result...
:ok
iex> handle_result.({:error})
An error has occurred!
```

## 命名 (Named) 函數

我們可以用名字來定義函數，以便稍後可以很容易地引用它們。
在模組中，定義命名函數使用 `def` 做為關鍵字。
我們將在接下來的課程中學習更多關於模組的內容，現在我們將單單專注於命名函數。

在模組中定義的函數可供其他模組使用。
這是 Elixir 中一個特別有用的構建區塊 (building block)：

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

我們前面提到，函數是通過給定名稱和引數數目 (arity) 的組合來命名的。
這意味著你可以做這樣的事情：

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

我們在上面的註釋中列出了函數名稱。
第一個實現 (implementation) 不接受引數 (arguments)，所以它被稱為 `hello/0`；第二個則接受一個引數，所以它被稱為 `hello/1`，依此類推。
與某些其他語言中的函數重載 (function overloads) 不同，這些被認為是彼此 _不同_ 的函數。
(前面提過的模式比對只有當函數名字與引數數量都 _相同_ 時才適用）。

### 函數和模式比對

在背後，函數以模式比對被呼用的參數。

假設需要一個接受映射的函數，但我們只對使用特定鍵感興趣。
那麼可以像這樣用模式比對該參數的鍵：

```elixir
defmodule Greeter1 do
  def hello(%{name: person_name}) do
    IO.puts "Hello, " <> person_name
  end
end
```

現在假設有個描述某人名字為 Fred 的映射：
```elixir
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"
...> }
```

這是以 `fred` 映射呼用 `Greeter1.hello/1` 時得到的結果：

```elixir
# call with entire map
...> Greeter1.hello(fred)
"Hello, Fred"
```

當使用 _不_ 包含 `:name` 鍵的映射來呼用函數時會發生什麼？

```elixir
# call without the key we need returns an error
...> Greeter1.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter3.hello/1

    The following arguments were given to Greeter3.hello/1:

        # 1
        %{age: "95", favorite_color: "Taupe"}

    iex:12: Greeter3.hello/1

```

出現這種行為的原因是 Elixir 會模式比對被呼用函數的參數與定義函數的引數數目。

現在考慮資料到達 `Greeter1.hello/1` 時的樣子：

```Elixir
# incoming map
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"
...> }
```
`Greeter1.hello/1` 期待這樣的參數：
```elixir
%{name: person_name}
```
在 `Greeter1.hello/1` 中，傳入的映射 (`fred`) 是根據參數 (`%{name: person_name}`) 賦值：

```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

它發現在傳入的映射中有一個與 `name` 對應的鍵。
現在配對成立！並且由於這次成功的配對，右邊映射中 `:name` 鍵的值（即 `fred` 映射）將綁定到左邊的變數（`person_name`）上。


現在，如果仍希望將 Fred 的名字分配給 `person_name`，但「也」想保留對整個 person 映射的認知呢？假設在問候他之後想要 `IO.inspect(fred)`。
此時，因為只有對映射中的 `:name` 鍵進行模式比對，因此只會將該鍵的值綁定到變數，所以函數並不會了解 Fred 的其餘資訊。

為了保留完整資訊，需要將整個映射分配給它自己的變數，以便能夠使用它。

現在建立一個新函數：
```elixir
defmodule Greeter2 do
  def hello(%{name: person_name} = person) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

請記住，參數傳入時 Elixir 會進行模式比對。
因此，在這種情況下，兩邊都將模式比對傳入的參數並綁定到無論它配對到的任何內容。
首先來看右邊：

```elixir
person = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

現在，`person` 已被賦值並綁定到整個 fred-map。
接著繼續進行下一個模式比對：
```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

這與原來模式比對映射並且只保留 Fred 名字的 `Greeter1` 函數相同。
這麼做所取得的成果為可以使用兩個變數而不是只有一個：
1. `person` ，指向 `%{name: "Fred", age: "95", favorite_color: "Taupe"}`
2. `person_name` ，指向 `"Fred"`

所以現在當呼用  `Greeter2.hello/1` 時，可以使用 Fred 的所有資訊：
```elixir
# call with entire person
...> Greeter2.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}
# call with only the name key
...> Greeter4.hello(%{name: "Fred"})
"Hello, Fred"
%{name: "Fred"}
# call without the name key
...> Greeter4.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter2.hello/1

    The following arguments were given to Greeter2.hello/1:

        # 1
        %{age: "95", favorite_color: "Taupe"}

    iex:15: Greeter2.hello/1
```

可以看到 Elixir 在多個深度上模式比對，因為每個參數獨立地配對傳入資料，在函數內部留下變數來呼用它們。

如果在列表中切換 `%{name: person_name}` 和 `person` 的順序，將得到相同的結果，因為每個都與 fred 自己配對。

現在交換變數和映射:
```elixir
defmodule Greeter3 do
  def hello(person = %{name: person_name}) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

並以在 `Greeter2.hello/1` 中使用的相同資料呼用它：
```elixir
# call with same old Fred
...> Greeter3.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}
```

請記住，即使 `%{name: person_name} = person}` 看起來像 `%{name: person_name}` 對 `person` 變數進行模式比對，但它們實際上是 _各自_ 模式比對到傳入的參數。

**總結：** 函數各別地模式比對傳入每個參數的資料。
可以使用它將值綁定到函數中的多個獨立變數。

### 私有 (Private) 函數

當我們不想讓其他模組存取某個特定的函數時，我們可以讓這個函數被保密。
私有函數只能從自己的模組中呼用。
在 Elixir 中，我們使用 `defp` 來定義：

```elixir
defmodule Greeter do
  def hello(name), do: phrase() <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### 監視 (Guards)

我們在 [Control Structures](../control-structures) 課程中簡要地介紹了監視 (guards)，現在我們來看看如何應用到命名函數上。
一旦 Elixir 配對了一個函數，任何現有的監視語句 (guards) 都將被檢驗。

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

當我們把監視的用法和預設的引數值結合起來時，會遇到一個問題。
現在來看看會是什麼樣的情形：

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

** (CompileError) iex:31: definitions with multiple clauses and default values require a header.
Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b) do ... end

one should write:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end

def hello/2 has multiple clauses and defines defaults in one or more clauses
    iex:31: (module)
```

Elixir 不喜歡多重比對函數中的預設引數值，因可能會造成混淆。
我們加上一個帶有預設引數值的函數標頭 (head) 來處理這個問題：

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
