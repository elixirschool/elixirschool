%{
  version: "1.0.2",
  title: "嵌入式 Elixir (EEx)",
  excerpt: """
  就像 Ruby 有 ERB 而 Java 有 JSP 一樣，Elixir 有 EEx，或稱為嵌入式 (Embedded) Elixir。通過 EEx，可以嵌入 Elixir 內部字串並求值。
  """
}
---

## API

EEx API 支援直接處理字串和檔案。API 分為三個主要部分：簡單求值、函數定義和編譯為 AST。

### 求值 (Evaluation)

使用 `eval_string/3` 和 `eval_file/2` ，可以對字串或檔案內文進行簡單求值。這是最簡單的 API，但是由於程式碼是經過求值和未編譯的，因此速度最慢。

```elixir
iex> EEx.eval_string "Hi, <%= name %>", [name: "Sean"]
"Hi, Sean"
```

### 定義 (Definitions)

使用 EEx 最快且首選的方法是將模板 (template) 嵌入到模組中，以能編譯它。為此，需要在編譯時使用模板，以及 `function_from_string/5` 和 `function_from_file/5` 巨集。

現在將 greeting 移動到另一個檔案並為模板生成一個函數：

```elixir
# greeting.eex
Hi, <%= name %>

defmodule Example do
  require EEx
  EEx.function_from_file(:def, :greeting, "greeting.eex", [:name])
end

iex> Example.greeting("Sean")
"Hi, Sean"
```

### 編譯 (Compilation)

最後，EEx 提供了一種經由使用 `compile_string/2` 或 `compile_file/2` 從字串或檔案直接生成 Elixir AST 的方法。該 API 主要用於上述所說的 API，但如果希望實現自己對嵌入式 Elixir 的處理，該 API 也可使用。

## 標籤 (Tags)

預設情況下，EEx 中有四個支援的 Tag：

```elixir
<% Elixir expression - inline with output %>
<%= Elixir expression - replace with result %>
<%% EEx quotation - returns the contents inside %>
<%# Comments - they are discarded from source %>
```

所有希望被輸出的表達式 __必須__ 使用等號 (`=`)。要注意的重點是，雖然其他模板語言 (templating language) 以特殊方式處理像 `if` 這樣的子句，但 EEx 沒有。沒有 `=` 什麼都不會輸出：

```elixir
<%= if true do %>
  A truthful statement
<% else %>
  A false statement
<% end %>
```

## 程式引擎 (Engine)

預設情況下，Elixir 使用 `EEx.SmartEngine`，其中包括對指派 (assignments) 的支援（ 如`@name` ）：

```elixir
iex> EEx.eval_string "Hi, <%= @name %>", assigns: [name: "Sean"]
"Hi, Sean"
```

`EEx.SmartEngine` 指派很有用，因為可以在不請求模板編譯的情況下更改指派 (assignments)。

有興趣編寫自己的程式引擎？ 請查看 [`EEx.Engine`](https://hexdocs.pm/eex/EEx.Engine.html) 行為以了解需要什麼。