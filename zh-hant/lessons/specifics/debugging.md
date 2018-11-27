---
version: 1.0.1
title: 除錯
---

程式錯誤 (Bugs) 是任何專案與生俱來的一部分，這就是需要除錯的原因。在本課程中，將學習如何除錯 Elixir 程式碼以及使用靜態分析工具，以幫助我們發現潛在的程式錯誤。

{% include toc.html %}

# Dialyxir 與 Dialyzer

[Dialyzer](http://erlang.org/doc/man/dialyzer.html)， 一個 Erlang 程式語言差異分析器 ( **DI**screpancy **A**nal**YZ**er for **ER**lang programs ) 是一個用於靜態程式碼分析的工具。換句話說，它 _閱讀_ 但不會 _執行_  程式和解析 (analyse) 它，例如它會尋找一些 bug；或是無法使用、不必要與無法存取的程式碼。

[Dialyxir](https://github.com/jeremyjh/dialyxir) 是一個 mix 工作用來簡化在 Elixir 中使用 Dialyzer。

規範可幫助 Dialyzer 等工具更好地理解程式碼。與僅適用於人類可閱讀理解的文件 (如果有並且寫得很好的話) 不同，`@spec` 使用更正式的語法並且可以被機器所理解。

現在新增 Dialyxir 到專案中。最簡單的方法是在 `mix.exs` 文件中加入依賴關係：

```elixir
defp deps do
  [{:dialyxir, "~> 0.4", only: [:dev]}]
end
```

接著就可以使用它：

```shell
$ mix deps.get
...
$ mix deps.compile
```

第一個指令將下載並安裝 Dialyxir。可能會要求安裝 Hex。第二個指令則將編譯 Dialyxir 應用程式。如果想在全域範圍內安裝 Dialyxir，請閱讀其[文件](https://github.com/jeremyjh/dialyxir#installation)。

最後一步是執行 Dialyzer 來重建 PLT (Persistent Lookup Table)。每次安裝新版本的 Erlang 或 Elixir 後，都需要這樣做。
幸運的是，每次使用標準函式庫時，Dialyzer 都不會嘗試解析它。下載完成需要幾分鐘的時間。

```shell
$ mix dialyzer --plt
Starting PLT Core Build ... this will take awhile
dialyzer --build_plt --output_plt /.dialyxir_core_18_1.3.2.plt --apps erts kernel stdlib crypto public_key -r /Elixir/lib/elixir/../eex/ebin /Elixir/lib/elixir/../elixir/ebin /Elixir/lib/elixir/../ex_unit/ebin /Elixir/lib/elixir/../iex/ebin /Elixir/lib/elixir/../logger/ebin /Elixir/lib/elixir/../mix/ebin
  Creating PLT /.dialyxir_core_18_1.3.2.plt ...
...
 done in 5m14.67s
done (warnings were emitted)
```

## 程式碼靜態分析

現在準備好來使用 Dialyxir:

```shell
$ mix dialyzer
...
examples.ex:3: Invalid type specification for function 'Elixir.Examples':sum_times/1. The success typing is (_) -> number()
...
```

來自 Dialyzer 的訊息很清楚：函數 `sum_times/1` 的回傳類型與宣告的不同。這是因為 `sum_times/1` 的回傳類型是 `integer` 但 `Enum.sum/1` 則回傳了一個 `number` 而不是 `integer`。

由於 `number` 不同於 `integer` ，所以得到一個錯誤訊息。那該如何修正？需要使用 `round/1` 函數將 `number` 更改為 `integer`：

```elixir
@spec sum_times(integer) :: integer
def sum_times(a) do
  [1, 2, 3]
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

最終將得到:

```shell
$ mix dialyzer
...
  Proceeding with analysis... done in 0m0.95s
done (passed successfully)
```

使用規範檢查工具執行靜態程式碼分析能幫助開發者產生經過自我測試並含有較少錯誤的程式碼。

# 除錯

有時只進行靜態程式碼分析仍不足，可能需要了解執行流程以找到錯誤。最簡單的方法是將輸出的陳述句放在程式碼中，如 `IO.puts/2` 來追踨值和程式流程，但這種技術是原始的並且有局限性。值得慶幸的是，可以使用 Erlang 除錯器來除錯我們的 Elixir 程式碼。

現在來看一個基本的模組:

```elixir
defmodule Example do
  def cpu_burns(a, b, c) do
    x = a * 2
    y = b * 3
    z = c * 5

    x + y + z
  end
end
```

首先執行 `iex`:

```bash
$ iex -S mix
```

而後再執行除錯器:

```elixir
iex > :debugger.start()
{:ok, #PID<0.307.0>}
```

Erlang `:debugger` 模組提供對除錯器的存取使用。 可以使用 `start/1` 函數來設定：

+ 通過輸入文件路徑可以使用外部設定文件
+ 如果參數設定為 `:local` 或 `:global` 那麼除錯器將:
    + `:global` – 除錯器將直譯所有已知節點上的程式碼，這是預設值。
    + `:local` – 除錯器將僅直譯目前節點上的程式碼。

下一步是將模組加入到除錯器：

```elixir
iex > :int.ni(Example)
{:module, Example}
```

`:int` 模組是一個直譯器，它使開發者能夠建立斷點並逐步執行程式碼。

當開啟除錯器時將看到一個像下面一樣的新視窗：

![Debugger Screenshot 1]({% asset debugger_1.png @path %})

而在將模組加入到除錯器後，在左側的選單中即能被使用：

![Debugger Screenshot 2]({% asset debugger_2.png @path %})

## 建立斷點

斷點是程式碼中將停止執行的一個點。有兩種建立斷點的方法：

+ 程式碼中的 `:int.break/2`
+ 除錯器的 UI

現在嘗試在 IEx 中建立一個斷點：

```elixir
iex > :int.break(Example, 8)
:ok
```

這將在 `Example` 模組的第 8 行設置斷點。現在當我們呼用函數時：

```elixir
iex > Example.cpu_burns(1, 1, 1)
```

執行將在 IEx 中暫停，除錯器視窗口應顯示如下：

![Debugger Screenshot 3]({% asset debugger_3.png @path %})

並且將出現帶有原始碼的額外視窗：

![Debugger Screenshot 4]({% asset debugger_4.png @path %})

在這個視窗中，可以尋找變數的值，往前到下一行或計算表達式。 在指令中 `:int.disable_break/2` 則可以被呼用以禁用斷點：

```elixir
iex > :int.disable_break(Example, 8)
:ok
```

要重新啟用斷點，可以呼用 `:int.enable_break/2` 或者可以像這樣移除斷點：

```elixir
iex > :int.delete_break(Example, 8)
:ok
```

除錯器視窗也允許相同的操作。在頂部選單 __Break__ 中，可以選擇 __Line Break__ 並設置斷點。如果選擇不包含程式碼的行時，則將忽略斷點，但會出現在除錯器視窗中。斷點有三種類型：

+ 行斷點 — 當執行到該行時，除錯器將暫停執行，使用 `:int.break/2` 進行設定。
+ 條件式斷點 — 類似於行斷點但除錯器僅在達到指定條件時暫停，使用 `:int.get_binding/2` 來設定。
+ 函數式斷點 — 除錯器將在函數的第一行暫停，使用 `:int.break_in/3` 來設定。

就這樣！ 開心的除錯吧！
