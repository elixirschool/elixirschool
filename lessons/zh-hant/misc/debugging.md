%{
  version: "1.1.0",
  title: "除錯",
  excerpt: """
  程式錯誤 (Bugs) 是任何專案與生俱來的一部分，這就是需要除錯的原因。在本課程中，將學習如何除錯 Elixir 程式碼以及使用靜態分析工具，以幫助我們發現潛在的程式錯誤。
  """
}
---


# IEx

我們擁有用於除錯 Elixir 程式碼最直接的工具是 IEx。但是不要囿於它的簡易性 — 可以通過它解決應用程式中大多數的問題。

IEx 是指 `Elixir 的交談式殼層`。可能已經在之前的課程之中見過 IEx，例如 [基礎](../../basics/basics)，它能在殼層中以交談方式執行 Elixir 程式碼。

這裡的概念很簡單。就是在想要除錯位置的上下文中獲得交談式殼層。

現在來嘗試一下。首先，建立一個 `test.exs` 檔案並寫入以下程式碼： 

```
defmodule TestMod do
  def sum([a, b]) do
    b = 0

    a + b
  end
end

IO.puts(TestMod.sum([34, 65]))
```

如果執行它 — 會得到一個明確的 34 輸出： 

```
$ elixir test.exs
warning: variable "b" is unused (if the variable is not meant to be used, prefix it with an underscore)
  test.exs:2

34
```

不過，現在開始進入讓人興奮的部分 — 除錯。在 `b = 0` 此行之後輸入 `require IEx; IEx.pry` 並且再試著執行一次。將會看到像下面的內容：

```
$ elixir test.exs
warning: variable "b" is unused (if the variable is not meant to be used, prefix it with an underscore)
  test.exs:2

Cannot pry #PID<0.92.0> at TestMod.sum/1 (test.exs:5). Is an IEx shell running?
34
```

你應該注意到這個重要訊息。通常，在執行應用程式時，IEx 會輸出以上訊息，而不是阻止程式執行。要正確執行它，需要在指令前加上 `iex -S`。它的作用是在 `iex` 指令中執行 `mix`，以便以特殊模式執行應用程式，對 `IEx.pry` 的呼用從而停止應用程式執行。

例如，以 `iex -S mix phx.server` 對 Phoenix 應用程式進行除錯。在範例中，將會是以 `iex -S test.exs` 來要求檔案：

```
$ iex -r test.exs
Erlang/OTP 21 [erts-10.3.1] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [hipe] [dtrace]

warning: variable "b" is unused (if the variable is not meant to be used, prefix it with an underscore)
  test.exs:2

Request to pry #PID<0.107.0> at TestMod.sum/1 (test.exs:5)

    3:     b = 0
    4:
    5:     require IEx; IEx.pry
    6:
    7:     a + b

Allow? [Yn]
```

通過 `y` 或按 Enter 回應提示後，你就已進入交談模式。

```
 $ iex -r test.exs
Erlang/OTP 21 [erts-10.3.1] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [hipe] [dtrace]

warning: variable "b" is unused (if the variable is not meant to be used, prefix it with an underscore)
  test.exs:2

Request to pry #PID<0.107.0> at TestMod.sum/1 (test.exs:5)

    3:     b = 0
    4:
    5:     require IEx; IEx.pry
    6:
    7:     a + b

Allow? [Yn] y
Interactive Elixir (1.8.1) - press Ctrl+C to exit (type h() ENTER for help)
pry(1)> a
34
pry(2)> b
0
pry(3)> a + b
34
pry(4)> continue
34

Interactive Elixir (1.8.1) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)>
BREAK: (a)bort (c)ontinue (p)roc info (i)nfo (l)oaded
       (v)ersion (k)ill (D)b-tables (d)istribution
```

要跳離 IEx，可以敲擊 `Ctrl+C` 2 次來離開應用程式，或是鍵入 `continue` 來進到下一個斷點。

如你所見，你可以執行任何 Elixir 程式碼。但是，它的局限性在於語言的不可變性，你無法修改現有程式碼的變數。但是，可以獲得所有變數的值並執行任何運算。在這個範例中，該錯誤是將 `b` 重新分配為 0，導致 `sum` 函數的結果中存在錯誤。當然，即便在首次執行時，語言本身也已捕獲了此錯誤，不過這就是個範例！

## IEx 輔助方法

使用 IEx 的煩人的部分之一是，它沒有在先前執行中使用指令的歷史記錄。為了解決該問題，在 [IEx 文件](https://hexdocs.pm/iex/IEx.html#module-shell-history) 上有單獨的小節，可以在其中找到你所選用平台的解決方案。

也可以在 [IEx.Helpers 文件](https://hexdocs.pm/iex/IEx.Helpers.html) 中瀏覽其他可用的輔助方法列表。

# Dialyxir 與 Dialyzer

[Dialyzer](http://erlang.org/doc/man/dialyzer.html)， 一個 Erlang 程式語言差異分析器 ( **DI**screpancy **A**nal**YZ**er for **ER**lang programs ) 是一個用於靜態程式碼分析的工具。
換句話說，它 _閱讀_ 但不會 _執行_  程式和解析 (analyse) 它，
例如它會尋找一些 bug；或是無法使用、不必要與無法存取的程式碼。

[Dialyxir](https://github.com/jeremyjh/dialyxir) 是一個 mix 工作用來簡化在 Elixir 中使用 Dialyzer。

規範可幫助 Dialyzer 等工具更好地理解程式碼。
與僅適用於人類可閱讀理解的文件（如果有並且寫得很好的話）不同，`@spec` 使用更正式的語法並且可以被機器所理解。

現在新增 Dialyxir 到專案中。
最簡單的方法是在 `mix.exs` 文件中加入依賴關係：

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

第一個指令將下載並安裝 Dialyxir。
可能會要求安裝 Hex。
第二個指令則將編譯 Dialyxir 應用程式。
如果想在全域範圍內安裝 Dialyxir，請閱讀其[文件](https://github.com/jeremyjh/dialyxir#installation)。

最後一步是執行 Dialyzer 來重建 PLT（Persistent Lookup Table）。
每次安裝新版本的 Erlang 或 Elixir 後，都需要這樣做。
幸運的是，每次使用標準函式庫時，Dialyzer 都不會嘗試解析它。
下載完成需要幾分鐘的時間。

```shell
$ mix dialyzer --plt
Starting PLT Core Build ...
this will take awhile
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
examples.ex:3: Invalid type specification for function 'Elixir.Examples':sum_times/1.
The success typing is (_) -> number()
...
```

來自 Dialyzer 的訊息很清楚：函數 `sum_times/1` 的回傳類型與宣告的不同。
這是因為 `sum_times/1` 的回傳類型是 `integer` 但 `Enum.sum/1` 則回傳了一個 `number` 而不是 `integer`。

由於 `number` 不同於 `integer` ，所以得到一個錯誤訊息。
那該如何修正？需要使用 `round/1` 函數將 `number` 更改為 `integer`：

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
  Proceeding with analysis...
done in 0m0.95s
done (passed successfully)
```

使用規範檢查工具執行靜態程式碼分析能幫助開發者產生經過自我測試並含有較少錯誤的程式碼。

# 除錯

有時只進行靜態程式碼分析仍不足，
可能需要了解執行流程以找到錯誤。
最簡單的方法是將輸出的陳述句放在程式碼中，如 `IO.puts/2` 來追踨值和程式流程，但這種技術是原始的並且有局限性。
值得慶幸的是，可以使用 Erlang 除錯器來除錯我們的 Elixir 程式碼。

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

Erlang `:debugger` 模組提供對除錯器的存取使用。
可以使用 `start/1` 函數來設定：

+ 通過輸入文件路徑可以使用外部設定文件
+ 如果參數設定為 `:local` 或 `:global` 那麼除錯器將:
    + `:global` – 除錯器將直譯所有已知節點上的程式碼，
這是預設值。
    + `:local` – 除錯器將僅直譯目前節點上的程式碼。

下一步是將模組加入到除錯器：

```elixir
iex > :int.ni(Example)
{:module, Example}
```

`:int` 模組是一個直譯器，它使開發者能夠建立斷點並逐步執行程式碼。

當開啟除錯器時將看到一個像下面一樣的新視窗：

![Debugger Screenshot 1](/images/debugger_1.png)

而在將模組加入到除錯器後，在左側的選單中即能被使用：

![Debugger Screenshot 2](/images/debugger_2.png)

## 建立斷點

斷點是程式碼中將停止執行的一個點。
有兩種建立斷點的方法：

+ 程式碼中的 `:int.break/2`
+ 除錯器的 UI

現在嘗試在 IEx 中建立一個斷點：

```elixir
iex > :int.break(Example, 8)
:ok
```

這將在 `Example` 模組的第 8 行設置斷點。
現在當呼用函數時：

```elixir
iex > Example.cpu_burns(1, 1, 1)
```

執行將在 IEx 中暫停，除錯器視窗口應顯示如下：

![Debugger Screenshot 3](/images/debugger_3.png)

並且將出現帶有原始碼的額外視窗：

![Debugger Screenshot 4](/images/debugger_4.png)

在這個視窗中，可以尋找變數的值，往前到下一行或計算表達式。
在指令中 `:int.disable_break/2` 則可以被呼用以禁用斷點：

```elixir
iex > :int.disable_break(Example, 8)
:ok
```

要重新啟用斷點，可以呼用 `:int.enable_break/2` 或者可以像這樣移除斷點：

```elixir
iex > :int.delete_break(Example, 8)
:ok
```

除錯器視窗也允許相同的操作。
在頂部選單 __Break__ 中，可以選擇 __Line Break__ 並設置斷點。
如果選擇不包含程式碼的行時，則將忽略斷點，但會出現在除錯器視窗中。
斷點有三種類型：

+ 行斷點 — 當執行到該行時，除錯器將暫停執行，使用 `:int.break/2` 進行設定。
+ 條件式斷點 — 類似於行斷點但除錯器僅在達到指定條件時暫停，使用 `:int.get_binding/2` 來設定。
+ 函數式斷點 — 除錯器將在函數的第一行暫停，使用 `:int.break_in/3` 來設定。

就這樣！快樂除錯吧！