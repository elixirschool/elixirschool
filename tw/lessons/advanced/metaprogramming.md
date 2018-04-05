---
version: 1.0.2
title: 超編程
---

超編程 (Metaprogramming) 是使用程式碼自身編寫程式碼的過程。在 Elixir 中，這使我們能夠擴展語言本身以適應需求並能動態地改寫程式碼。首先來看 Elixir 是如何在內部再現它，而後如何修改它，最後就可以利用這些知識來擴展它。

警世之言：超編程非常難捉摸 (tricky)，只應該在必要時使用。過度使用幾乎肯定會導致難以理解和除錯的複雜程式碼。

{% include toc.html %}

## Quote

超編程的第一步是理解表達式是如何再現的。在 Elixir 中，抽象語法樹（abstract syntax tree, AST）是程式碼的內部再現，由 tuples 組成。這些 tuples 包含三個部分：函數名稱、後設資料 (metadata) 和函數引數。

為了看到這些內部結構，Elixir 提供 `quote/2` 函數。使用 `quote/2` ，可以將 Elixir 程式碼轉換為其底層表示形式：

```elixir
iex> quote do: 42
42
iex> quote do: "Hello"
"Hello"
iex> quote do: :world
:world
iex> quote do: 1 + 2
{:+, [context: Elixir, import: Kernel], [1, 2]}
iex> quote do: if value, do: "True", else: "False"
{:if, [context: Elixir, import: Kernel],
 [{:value, [], Elixir}, [do: "True", else: "False"]]}
```

有注意到前三個不回傳的 tuples 嗎？有五種文字 (literals) 在 quoted 下會回傳自己：

```elixir
iex> :atom
:atom
iex> "string"
"string"
iex> 1 # All numbers
1
iex> [1, 2] # Lists
[1, 2]
iex> {"hello", :world} # 2 element tuples
{"hello", :world}
```

## Unquote

既然可以檢索程式碼內部結構，那麼該如何修改它？使用 `unquote/1`，達成插入 (inject) 新的程式碼或值。
當 unquote 一個表達式時，它將被求值並插入到 AST 中。現在為了展示 `unquote/1` 來看看一些例子：

```elixir
iex> denominator = 2
2
iex> quote do: divide(42, denominator)
{:divide, [], [42, {:denominator, [], Elixir}]}
iex> quote do: divide(42, unquote(denominator))
{:divide, [], [42, 2]}
```

在第一個例子中，變數 `denominator` 是被 quoted，因此得到的 AST 包含一個用於存取變數的 tuple。
而在 `unquote/1` 例子中，輸出的程式碼反而包含 `denominator` 的值。

## 巨集

一旦理解 `quote/2` 和 `unquote/1` 後，就可以開始深入巨集 (macros)。重要的是要記住，像使用超編程一樣，也應該謹慎使用巨集。

簡單來說，巨集是特殊函數，設計於回傳插入到應用程式程式碼中的 quoted 表達式。想像一下，巨集被替換為 quoted 表達式而不是像函數那樣被呼用。通過巨集，將擁有擴展 Elixir 所需的一切，並能動態地將程式碼加入到應用程式中。

首先使用 `defmacro/2` 定義一個巨集，就像 Elixir 的許多部分一樣，它本身就是一個巨集 (稍微花點時間來領會它)。
為了舉例，我們將實現 `unless` 為巨集。記住巨集需要回傳一個 quoted 表達式：

```elixir
defmodule OurMacro do
  defmacro unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end
```

現在請求模組，並測試一下巨集：

```elixir
iex> require OurMacro
nil
iex> OurMacro.unless true, do: "Hi"
nil
iex> OurMacro.unless false, do: "Hi"
"Hi"
```

因為巨集在應用程式中會替換程式碼，所以可以控制何時編譯以及編譯什麼。上述例子可以在 `Logger` 模組中找到。當禁用 logging 時，不會插入任何程式碼，並且生成的應用程式不包含對 logging 的引用或函數呼用。不過這與其它語言不同，即使實現為無操作 (NOP)，仍然存在函數呼用時的程式碼 (overhead)。

為了證明這一點，製作一個簡單可以啟用或禁用功能的 logger：

```elixir
defmodule Logger do
  defmacro log(msg) do
    if Application.get_env(:logger, :enabled) do
      quote do
        IO.puts("Logged message: #{unquote(msg)}")
      end
    end
  end
end

defmodule Example do
  require Logger

  def test do
    Logger.log("This is a log message")
  end
end
```

啟用 logging 功能後，`test` 函數會導致程式碼如下所示：

```elixir
def test do
  IO.puts("Logged message: #{"This is a log message"}")
end
```

如果禁用 logging，則生成的程式碼將是：

```elixir
def test do
end
```

## 除錯

好，現在我們知道如何使用 `quote/2`, `unquote/1` 和編寫巨集。但是假如你有大量的 quoted 程式碼並想要理解它呢？在這種情況下，可以使用 `Macro.to_string/2`。現在來看這個例子：

```elixir
iex> Macro.to_string(quote(do: foo.bar(1, 2, 3)))
"foo.bar(1, 2, 3)"
```

而當想看看由巨集所生成的程式碼時，可以將它們與 `Macro.expand/2` 和 `Macro.expand_once/2`結合起來，這些函數將巨集擴展到它們給定的 quoted 程式碼中。前者可能會擴展多次，而後者只會擴展一次。 例如，現在來修改前面範例的 `unless` 部分：

```elixir
defmodule OurMacro do
  defmacro unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end

require OurMacro

quoted =
  quote do
    OurMacro.unless(true, do: "Hi")
  end
```

```elixir
iex> quoted |> Macro.expand_once(__ENV__) |> Macro.to_string |> IO.puts
if(!true) do
  "Hi"
end
```

這讓人好奇，如果用 `Macro.expand/2` 執行相同的程式碼：

```elixir
iex> quoted |> Macro.expand(__ENV__) |> Macro.to_string |> IO.puts
case(!true) do
  x when x in [false, nil] ->
    nil
  _ ->
    "Hi"
end
```

你可能還記得我們曾提到 `if` 是 Elixir 中的一個巨集，在這裡看到它擴展到底層 `case` 語句中。

### 私有巨集 (Private Macros)

雖然不常見，但 Elixir 確實支援私有巨集 (private macros)。一個私有巨集使用 `defmacrop` 定義，而且只能從定義它的模組中呼用。在呼用私有巨集的程式碼之前必須定義。

### 巨集衛生 (Macro Hygiene)

巨集在擴展時如何與呼用者的上下文進行互動稱為巨集衛生 (macro hygiene)。預設情況下，Elixir 中的巨集是 hygienic 的，不會與上下文衝突： 

```elixir
defmodule Example do
  defmacro hygienic do
    quote do: val = -1
  end
end

iex> require Example
nil
iex> val = 42
42
iex> Example.hygienic
-1
iex> val
42
```

如果想操縱 `val` 的值呢？為了將變數標記為 unhygienic，可以使用 `var!/2`。現在更新範例，來涵蓋另一個使用 `var!/2` 的巨集：

```elixir
defmodule Example do
  defmacro hygienic do
    quote do: val = -1
  end

  defmacro unhygienic do
    quote do: var!(val) = -1
  end
end
```

現在來比較它們如何與上下文互動：

```elixir
iex> require Example
nil
iex> val = 42
42
iex> Example.hygienic
-1
iex> val
42
iex> Example.unhygienic
-1
iex> val
-1
```

通過在巨集中包含 `var!/2` ，可以操作 `val` 的值，而不會將它傳遞進巨集中。
但應保持最低限度的使用 non-hygienic 巨集。因為包含 `var!/2` ，增加了變數解析 (variable resolution) 衝突的風險。

### 綁定 (Binding)

我們已經介紹了 `unquote/1` 的用處，但還有另一種方法可以將值注入到的程式碼中：綁定 (binding)。
通過變數綁定 (variable binding)，可以在巨集中包含多個變數，並確保它們僅被一次 unquoted，避免意外重新估值 (revaluations)。
要使用變數綁定，需要將關鍵字列表傳遞給 `quote/2` 中的 `bind_quoted` 選項。

現在利用一個範例，以見到 `bind_quote` 的好處並展示重新估值問題。可以從建立一個簡單地輸出表達式兩次的巨集開始：

```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote do
      IO.puts(unquote(expr))
      IO.puts(unquote(expr))
    end
  end
end
```

現在將藉由傳遞當前系統時間來試用新巨集。應該預期看到系統時間輸出兩次：

```elixir
iex> Example.double_puts(:os.system_time)
1450475941851668000
1450475941851733000
```

兩次輸出的系統時間居然是不同的！發生了什麼事？在同一表達式多次使用 `unquote/1` 會導致重新估值，並產生意想不到的後果。
現在更新範例以使用 `bind_quoted` 並查看得到的結果：

```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote bind_quoted: [expr: expr] do
      IO.puts(expr)
      IO.puts(expr)
    end
  end
end

iex> require Example
nil
iex> Example.double_puts(:os.system_time)
1450476083466500000
1450476083466500000
```

使用 `bind_quoted`，可以預期得到的輸出為：相同的系統時間將被輸出兩次。

現在已經有了 `quote/2`、 `unquote/1`和 `defmacro/2`，這樣就擁有擴展 Elixir 以滿足我們需求的所有工具。