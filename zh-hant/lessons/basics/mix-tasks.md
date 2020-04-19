---
version: 1.1.0
title: 自訂 Mix 工作
---

為 Elixir 專案建立自訂 Mix 工作 (custom Mix tasks)。

{% include toc.html %}

## 簡介

想要通過加入自訂的 Mix 工作來擴展 Elixir 應用程式功能是很平常的。
在了解如何為專案建立特定的 Mix 工作之前，先來看看已經存在的一個：

```shell
$ mix phx.new my_phoenix_app

* creating my_phoenix_app/config/config.exs
* creating my_phoenix_app/config/dev.exs
* creating my_phoenix_app/config/prod.exs
* creating my_phoenix_app/config/prod.secret.exs
* creating my_phoenix_app/config/test.exs
* creating my_phoenix_app/lib/my_phoenix_app.ex
* creating my_phoenix_app/lib/my_phoenix_app/endpoint.ex
* creating my_phoenix_app/test/views/error_view_test.exs
...
```

從上面的 shell 指令可以看出，Phoenix Framework 已經有個用來生成新專案的自訂 Mix 工作。
如果我們能為自己的專案創造類似的東西呢？好消息是我們的確可以，Elixir 讓我們很容易就能做到。

## 設定

首先來建立一個非常基本的 Mix 應用程式。

```shell
$ mix new hello

* creating README.md
* creating .formatter.exs
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/hello.ex
* creating test
* creating test/test_helper.exs
* creating test/hello_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

cd hello
mix test

Run "mix help" for more commands.
```

現在，在 Mix 生成的 **lib/hello.ex** 檔案中，讓建立一個簡單並能輸出 "Hello, World!" 的函數。

```elixir
defmodule Hello do
  @doc """
  Outputs `Hello, World!` every time.
  """
  def say do
    IO.puts("Hello, World!")
  end
end
```

## 自訂 Mix 工作

現在來建立我們自己的自訂 Mix 工作。
首先建立一個新的目錄和檔案 **hello/lib/mix/tasks/hello.ex**。
而在這個檔案中，插入以下 7 行 Elixir 程式碼。

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Simply runs the Hello.say/0 function"
  def run(_) do
    # calling our Hello.say() function from earlier
    Hello.say()
  end
end
```

注意如何用 `Mix.Tasks` 和想要從命令列呼用的名稱來開始 defmodule 語句。
在第二行中，我們引進 `use Mix.Task`，並將 `Mix.Task` 行為帶入命名空間 (namespace)。
接著宣告一個忽略任何引數的運行函數。
在這個函數中，呼用 `Hello` 模組和 `say` 函數。

## 使用自訂 Mix 工作

現在來看看我們的 mix 工作。
只要我們位於該目錄下，它應該能被執行。
從命令列執行 `mix hello`，應該會看到以下內容：

```shell
$ mix hello
Hello, World!
```

Mix 預設是相當體貼的。
它知道人類經常會出現拼字錯誤，所以它使用了一種叫做模糊字串比對 (fuzzy string matching) 的技術來提出建議：

```shell
$ mix hell
** (Mix) The task "hell" could not be found. Did you mean "hello"?
```

有注意到我們也引入了一個新的模組屬性 `@shortdoc` 嗎？這在發怖應用程式時非常方便，例如當使用者從命令列執行 `mix help`指令時。

```shell
$ mix help

mix app.start         # Starts all registered apps
...
mix hello             # Simply calls the Hello.say/0 function.
...
```

註：在新工作將出現於 `mix help` 輸出前程式碼必須被編譯。
可以經由直接執行 `mix compile` 或像在執行 `mix hello` 那樣來執行工作觸發編譯。
