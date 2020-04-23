---
version: 1.0.3
title: 規範和型別
---

在本課程中，將學習 `@spec` 和 `@type` 語法。
`@spec` 提供更多的語法補語來編寫能以工具分析的文件。
`@type` 則幫助我們編寫更易讀易懂的程式碼。

{% include toc.html %}

## 簡介

想描述函數介面 (interface) 的需求並不少見，
能夠使用 [@doc annotation](../../basics/documentation) 做到，但這只是給與其他開發者在編輯期間的未驗證資訊。
而為此，Elixir 有著 `@spec` 註解來描述將由編譯器驗證的函數規範。

但是在某些情況下，規範 (specification) 將會相當大且複雜。
如果想降低複雜性，將會想要引入自定型別定義 (custom type definition)。
Elixir 則為此提供 `@type` 註解。
但另一方面，Elixir 仍然是動態語言。
這意味著關於型別的所有資訊將被編譯器忽略，但可以被其他工具使用。

## 規範

如果有使用 Java 的經驗，可以將規範視為 `interface`。
規範被定義為函數參數的型別和回傳值應該是什麼。

為了定義輸入和輸出的型別，在函數的定義之前使用 `@spec` 指令，並將其作為一個 `params` 名稱的函數、參數型別列表和在 `::` 型別後的回傳值。

現在來看個範例：

```elixir
@spec sum_product(integer) :: integer
def sum_product(a) do
  [1, 2, 3]
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
end
```

一切看起來都不錯，且當呼用時有效 (valid) 結果將會回傳，但函數 `Enum.sum` 則回傳 `number` 而不是像在 `@spec` 中預期的 `integer`。
這可能就是 bugs 來源！所以有像 Dialyzer 這樣的工具可以對程式碼進行靜態分析，以幫助我們找到這種類型的 bug。
我們將會在另一堂課程中談論它。

## 自訂型別

編寫規範很好，但有時函數是工作在比簡單數字或集合更複雜的資料結構中。
在 `@spec` 這個定義的情況下，可能很難讓其他開發者來理解和/或改變。
有時函數需要處理大量的參數或回傳複雜的資料。
一個冗長的參數列表是程式碼中許多潛在的不良氣味 (bad smells) 之一。
在像 Ruby 或 Java 這樣的物件導向語言 (object oriented-languages) 中，可以很容易地藉由定義類別 (class) 來幫助我們解決這個問題。
雖然 Elixir 沒有類別，但因很容易擴展，仍可以定義型別。

現成的 Elixir 包含一些基本型別，如 `integer` 或 `pid`。
可以在 [documentation](https://hexdocs.pm/elixir/typespecs.html#types-and-their-syntax) 中找到可用型別的完整清單。

### 定義自訂型別

現在修改 `sum_times` 函數並引入一些額外參數：

```elixir
@spec sum_times(integer, %Examples{first: integer, last: integer}) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

在 `Examples` 模組中引入了一個結構體，它包含兩個欄位 (fields) `first` 和 `last`。
這是自 `Range` 模組來的較簡易結構體版本。
如需更多 `structs` 資訊，請參考 [modules](../../basics/modules/#structs)。
現在想像一下，我們需要在很多地方用 `Examples` 結構體來做規範。
但寫出冗長而複雜的規範會很煩人，且可能成為 bug 的來源。
一個解決這個問題的方法是 `@type`。

Elixir 對於型別有三種指令：

  - `@type` – 簡易、公開型別，
  型別內部結構是公開的。
  - `@typep` – 型別是私有的，只能在被定義的模組中使用。
  - `@opaque` – 型別是公開的，但內部結構是私有的。

現在定義我們的型別：

```elixir
defmodule Examples do
  defstruct first: nil, last: nil

  @type t(first, last) :: %Examples{first: first, last: last}

  @type t :: %Examples{first: integer, last: integer}
end
```

我們已經定義了 `t(first, last)` 型別，它是結構體 `%Examples{first: first, last: last}` 的再現。
在這一點上，我們看到型別可以接受參數，但也定義型別 `t` ，這次它是結構體 `%Examples{first: integer, last: integer}` 的再現。

有什麼區別？第一個再現 `Examples` 的結構體，其中兩個鍵 (keys) 可以是任何型別。
第二個則再現鍵是 `integers` 的結構體。
這意味著這樣的程式碼：

```elixir
@spec sum_times(integer, Examples.t()) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

等於程式碼如：

```elixir
@spec sum_times(integer, Examples.t(integer, integer)) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

### 型別的文件

我們需要談論的最後一個元素是如何註解型別。
正如從 [documentation](../../basics/documentation) 課程中學到的，有 `@doc` 和 `@moduledoc` 註解來為函數和模組建立文件。
為了註解型別，可以使用 `@typedoc`：

```elixir
defmodule Examples do
  @typedoc """
      Type that represents Examples struct with :first as integer and :last as integer.
  """
  @type t :: %Examples{first: integer, last: integer}
end
```

指令 `@typedoc` 是與 `@doc` 和 `@moduledoc` 相似的。