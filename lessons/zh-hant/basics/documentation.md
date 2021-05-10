%{
  version: "1.1.0",
  title: "文件",
  excerpt: """
  註解 (Documenting) Elixir 程式碼。
  """
}
---

## 註解 (Annotation)

該如何撰寫註解，而一份高品質的說明文件又該包含什麼，這在程式設計的世界中依然是個有爭議的問題。
不過，我們都同意說明文件對於程式設計師自己以及程式庫的使用者來說都非常重要。

Elixir 將文件視為*一等公民*，提供多樣的函數來存取和生成專案所需文件。
Elixir 核心為提供許多不同的屬性來標註程式庫。
現在來看看 3 種不同的方式：

  - `#` - 行內註解
  - `@moduledoc` - 模組層 (module-level) 註解文件。
  - `@doc` - 函數內 (function-level) 註解文件。

### 行內註解 (Inline Documentation)

也許行內註解是註解程式碼最簡易的方法。
與 Ruby 或者 Python 雷同，Elixir 行內註解也使用 `#`，通常稱為 *pound* 或者 *hash*，至於使用那一個稱呼就看世界各地的使用習慣。

現在來看這個 Elixir Script (greeting.exs)：

```elixir
# Outputs 'Hello, chum.' to the console.
IO.puts("Hello, " <> "chum.")
```

Elixir 在執行這個 script 時會忽略從 `#` 到該行末端的所有內容，並將其視為一次性資料 (throwaway data)。
雖然這種註解在 script 執行時不會增加新值也不影響其效能，但當一個程式設計師經由閱讀這些註解想知道產生什麼事件時是不太明顯的。
因此留心不要濫用單行註解！註解的亂七八糟的程式庫可能成為不受人歡迎的噩夢。
最好適量使用。

### 模組內註解 (Documenting Modules)

`@moduledoc` 註解器 (annotator) 允許在模組層內存在行內註解文件 (inline documentation)。
它通常位於檔案頂部的 `defmodule` 宣告下。
下面的例子顯示了 `@moduledoc` 裝飾器 (decorator) 中的單行註解。

```elixir
defmodule Greeter do
  @moduledoc """
  Provides a function `hello/1` to greet a human
  """

  def hello(name) do
    "Hello, " <> name
  end
end
```

我們（或其他人）可以在 IEx 中 使用 `h` 輔助函數來存取這個模組內文件。
如果將 `Greeter` 模組放進一個新檔案 `greeter.ex` 內並進行編譯，我們自己就會看到：

```elixir
iex> c("greeter.ex", ".")
[Greeter]

iex> h Greeter

                Greeter

Provides a function hello/1 to greet a human
```

_註_：在 mix 專案內，是不需要像上面那樣手動編譯檔案。如果是正在 mix 專案中工作，則使用 `iex -S mix` 就可以為當前專案載入 IEx 控制台。

### 函數內註解 (Documenting Functions)

如同 Elixir 為我們提供模組層註解能力一樣，同時也可以應用相似的註解手法在函數上。
`@doc` 註解器 (annotator) 允許函數層內存在行內註解文件。
`@doc` 註解器會位於被註解函數的上方。

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

現在我們再次跳回 IEx，並在加上模組名稱的函數前面使用 helper 指令 (`h`)，應該會看到以下內容：

```elixir
iex> c("greeter.ex")
[Greeter]

iex> h Greeter.hello

                def hello(name)

Prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"

iex>
```

有注意我們如何在文件中使用 markup 語言，而 terminal 又是如何渲染它的嗎？除了讓 Elixir 龐大的生態系統中增加一個很酷的功能外，同時當我們查看 ExDoc 來動態生成 HTML 文件時，它又變得更加有趣。

**註：** `@spec` 註解用於程式碼的靜態分析。
要了解更多資訊，請查看 [規範和型別](../../advanced/typespec) 課程。

## ExDoc

ExDoc 是一個官方 Elixir 專案，可以在 [GitHub](https://github.com/elixir-lang/ex_doc) 找到。
它能為 Elixir 專案生成 **HTML (HyperText Markup Language)）和線上文件**。
首先讓我們為應用程式建立一個 Mix 專案：

```bash
$ mix new greet_everyone

* creating README.md
* creating .formatter.exs
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/greet_everyone.ex
* creating test
* creating test/test_helper.exs
* creating test/greet_everyone_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd greet_everyone
    mix test

Run "mix help" for more commands.

$ cd greet_everyone

```

現在將 `@doc` 註解器 (annotator) 課程中的程式碼複製並貼上到一個名為 `lib/greeter.ex` 的檔案中，並由命令列中確認所有功能仍能執行。
我們正在 Mix 專案中工作，現在需要使用稍微不同的 `iex -S mix` 命令序列來啟動 IEx：

```elixir
iex> h Greeter.hello

                def hello(name)

Prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"
```

### 安裝設定 (Installing)

假設一切正常，我們將看到上面的輸出，表示現在已經準備好來設定 ExDoc。
在 `mix.exs` 文件中，加入兩個必要的耦合性來開始： `:earmark` 和 `:ex_doc`。

```elixir
  def deps do
    [{:earmark, "~> 1.2", only: :dev},
    {:ex_doc, "~> 0.19", only: :dev}]
  end
```

指定一對鍵值 `only: :dev`，因為我們不想在 production 環境中下載和編譯這些耦合性。
但為什麼需要 Earmark？ Earmark 是 Elixir 程式語言的 Markdown 解析器 (parser)，ExDoc 利用它將 `@moduledoc` 和 `@doc` 的文件內容轉換為美麗的 HTML。

值得注意的一點是，此時並不強迫使用 Earmark。
你可以更改為其它的 markup 工具，如 Pandoc、Hoedown 或 Cmark；不過如果要這樣你將會需要做更多的設定工作，相關資訊可以參考 [這裡](https://github.com/elixir-lang/ex_doc#changing-the-markdown-tool)。
而對於本課程，我們將保持使用 Earmark。

### 產生文件 (Generating Documentation)

從命令列繼續執行以下兩個指令：

```bash
$ mix deps.get # gets ExDoc + Earmark.
$ mix docs # makes the documentation.

Docs successfully generated.
View them at "doc/index.html".
```

如果一切都按計劃進行，則應在上例中看到類似於輸出訊息的資訊。
現在來看看我們的 Mix 專案，應該會看到一個名為 **doc/** 的目錄。
裡面是那些被生成的文件。
如果在瀏覽器中存取索引頁面 (index page)，應該會看到以下內容：

![ExDoc Screenshot 1]({% asset documentation_1.png @path %})

可以看到，Earmark 已經完成渲染 Markdown 因而 ExDoc 現在顯示為一個可用易讀的格式。

![ExDoc Screenshot 2]({% asset documentation_2.png @path %})

現在可以將其部署到 GitHub、我們自己的網站，或更常見的 [HexDocs](https://hexdocs.pm/)。

## 最佳實踐 (Best Practice)

程式語言都應該在它的最佳實踐指南中增加撰寫文件這個項目。
由於 Elixir 是一個相當年輕的語言，隨著語言生態系統的發展，許多標準還有待探索。
但即便如此，Elixir 社群依然試圖建立最佳實踐。
要詳細了解最佳實踐，請參考 [The Elixir Style Guide](https://github.com/niftyn8/elixir_style_guide).

  - 永遠記得註解模組。

```elixir
defmodule Greeter do
  @moduledoc """
  This is good documentation.
  """

end
```

  - 如果你不打算註解一個模組，**不要** 留白。
  考慮以 `false` 來註解模組，如下所示：

```elixir
defmodule Greeter do
  @moduledoc false

end
```

 - 引述位於模組文件內的函數時，請使用反引號 (backticks)：

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 - 在 `@moduledoc` 下面的程式碼，以空一行的方式分隔，如下所示：

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  alias Goodbye.bye_bye
  # and so on...

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 - 在文件 (docs) 中使用 Markdown 語法。
 這將讓不論是 IEx 或 ExDoc 都能更容易解析文件。

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

 - 試著在文件中包含一些程式碼範例。
 這會允許你在 [ExUnit.DocTest][] 幫助下從模組、函數或巨集中的程式碼範例中生成自動測試。
 為了做到這一點，需要在測試例子中呼用 `doctest/1` 巨集，並根據 [official documentation][ExUnit.DocTest] 中介紹的準則編寫範例。

[ExUnit.DocTest]: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html
