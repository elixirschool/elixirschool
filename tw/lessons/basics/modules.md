---
version: 1.2.0
title: 模組
redirect_from:
  - /lessons/basics/modules/
---

我們從經驗中知道，把所有的功能放在同一個文件和範圍 (scope) 內是不合理的。
在本課程中，我們將介紹如何對函數進行分組，並定義一個稱為函數體 (struct) 的特殊映射，以便更有效地組織我們的程式碼。

{% include toc.html %}

## 模組

模組允許我們將函數整合到一個名稱空間 (namespace) 中。除了對函數進行分組之外，它同時允許我們定義在 [functions lesson](../functions/) 中介紹的命名函數和私有函數。

現在來看看一個基本的例子：

``` elixir
defmodule Example do
  def greeting(name) do
    "Hello #{name}."
  end
end

iex> Example.greeting "Sean"
"Hello Sean."
```

在 Elixir 中能夠使用巢狀模組，使您可以進一步定義多層命名空間：

```elixir
defmodule Example.Greetings do
  def morning(name) do
    "Good morning #{name}."
  end

  def evening(name) do
    "Good night #{name}."
  end
end

iex> Example.Greetings.morning "Sean"
"Good morning Sean."
```

### 模組屬性

模組屬性在 Elixir 中最常用作常數。現在來看一個簡單的例子：

```elixir
defmodule Example do
  @greeting "Hello"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

注意 Elixir 有保留某些屬性 (reserved attributes)。最常見的三個是：

+ `moduledoc` — 記錄當前模組。
+ `doc` — 文件的功能和巨集 (macros)。
+ `behaviour` — 使用 OTP 或使用者定義的行為。

## 結構體 (Structs)

結構體是具有一組被定義的鍵 (keys) 和預設值的特殊映射。
結構體必須定義在一個模組中，因此必須通過模組來存取。在模組中，單只定義結構體是常見用法。

為了定義一個結構體，我們使用 `defstruct` 和關鍵字列表以及預設值：

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

現在來創建一些結構：

```elixir
iex> %Example.User{}
%Example.User{name: "Sean", roles: []}

iex> %Example.User{name: "Steve"}
%Example.User{name: "Steve", roles: []}

iex> %Example.User{name: "Steve", roles: [:admin, :owner]}
%Example.User{name: "Steve", roles: [:admin, :owner]}
```

我們可以像更新映射一樣更新結構體：

```elixir
iex> steve = %Example.User{name: "Steve", roles: [:admin, :owner]}
%Example.User{name: "Steve", roles: [:admin, :owner]}
iex> sean = %{steve | name: "Sean"}
%Example.User{name: "Sean", roles: [:admin, :owner]}
```

最重要的是，你可以將結構體與映射配對：

```elixir
iex> %{name: "Sean"} = sean
%Example.User{name: "Sean", roles: [:admin, :owner]}
```

## 合成 (Composition)

我們已經知道如何創建模組和結構體，現在讓我們學習如何通過合成來加入已存在的功能。
Elixir 提供了多種不同的方式來與其他模組進行互動。

### `別名 (alias)`

允許在模組名稱中使用別名；這在 Elixir 程式碼中使用相當頻繁：

```elixir
defmodule Sayings.Greetings do
  def basic(name), do: "Hi, #{name}"
end

defmodule Example do
  alias Sayings.Greetings

  def greeting(name), do: Greetings.basic(name)
end

# Without alias

defmodule Example do
  def greeting(name), do: Sayings.Greetings.basic(name)
end
```

如果兩個別名之間有衝突，或者我們只是想完全使用別名，我們可以使用 `:as` 選項：

```elixir
defmodule Example do
  alias Sayings.Greetings, as: Hi

  def print_message(name), do: Hi.basic(name)
end
```

同時為多個模組套用別名是可行的：

```elixir
defmodule Example do
  alias Sayings.{Greetings, Farewells}
end
```

### `導入 (import)`

如果我們想導入函數和巨集 (macros) 而不是別名 (aliasing) 這個模組，我們可以使用 `import/`：

```elixir
iex> last([1, 2, 3])
** (CompileError) iex:9: undefined function last/1
iex> import List
nil
iex> last([1, 2, 3])
3
```

#### 篩選 (Filtering)

預設情況下，所有的函數和巨集都會被導入，但是我們可以使用 `:only` 和 `:except` 選項進行篩選。

要導入特定的函數和巨集，我們必須提供一對 (pairs) 名稱/引數數目給 `:only` 和 `:except`。讓我們從只導入 `last/1` 函數開始:

```elixir
iex> import List, only: [last: 1]
iex> first([1, 2, 3])
** (CompileError) iex:13: undefined function first/1
iex> last([1, 2, 3])
3
```

導入除了 `last/1` 之外的所有內容，並嘗試與之前相同的函數：

```elixir
iex> import List, except: [last: 1]
nil
iex> first([1, 2, 3])
1
iex> last([1, 2, 3])
** (CompileError) iex:3: undefined function last/1
```

除了一對的名稱/引數數之外，還有兩個特殊的 atoms， `:functions` 和 `:macros` 分別只導入函數和巨集：

```elixir
import List, only: :functions
import List, only: :macros
```

### `請求 (require)`

雖然不常使用，但 `require/2` 其實非常重要。請求 (Requiring) 一個模組來確保它被編譯和載入。當我們需要存取模組的巨集時，這是非常有用的語法：

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

如果我們試圖呼用一個尚未載入的巨集，Elixir 將會出現錯誤訊息。

### `呼用 (use)`

使用 `use` 巨集，我們可以讓另一個模組修改我們目前模組的定義。
當我們在程式碼中呼用 `use` 時，實際上是呼用由所提供模組定義的 `__using__/1` 回呼函數。
巨集 `__using__/1` 的結果將成為我們模組定義的一部分。
為了更好地理解實際上是如何運作的，現在來看一個簡單的例子：

```elixir
defmodule Hello do
  defmacro __using__(_opts) do
    quote do
      def hello(name), do: "Hi, #{name}"
    end
  end
end
```

這裡我們創設了一個 `Hello` 模組，它定義了 `__using__/1` 回呼函數，而我們在其內部同時定義了一個 `hello/1` 函式。
讓我們創設一個新的模組，以便我們可以試用我們的新程式碼：

```elixir
defmodule Example do
  use Hello
end
```

如果在 IEx 中試用我們的程式碼，會看到  `Example` 模組上的 `hello/1` ：

```elixir
iex> Example.hello("Sean")
"Hi, Sean"
```

這裡可以看到 `use` 在 `Hello` 上呼用 `__using__/1` 回呼函數，然後將執行後的程式碼加入到模組中。
我們已經展示了一個基本的例子，現在更新我們的程式碼來看看 `__using__/1` 如何支援其它選項。
我們將通過加入一個選項 `greeting` 來實做：

```elixir
defmodule Hello do
  defmacro __using__(opts) do
    greeting = Keyword.get(opts, :greeting, "Hi")

    quote do
      def hello(name), do: unquote(greeting) <> ", " <> name
    end
  end
end
```

現在更新我們的 `Example` 模組以包含新創設的選項 `greeting` ：

```elixir
defmodule Example do
  use Hello, greeting: "Hola"
end
```

如果現在我們在 IEx 試用，應該會看到 greeting 已經改變了：

```
iex> Example.hello("Sean")
"Hola, Sean"
```

這些簡單的例子說明了 `use` 是如何運作的，它是 Elixir 工具箱中一個非常強大的工具。
當你繼續學習 Elixir 的時候，留意一下 `use` ，你肯定會看到一個例子，就是 `use ExUnit.Case, async: true`。

**註**： `quote`, `alias`, `use`, `require` 是我們使用 [metaprogramming](../../advanced/metaprogramming) 時引用的巨集。