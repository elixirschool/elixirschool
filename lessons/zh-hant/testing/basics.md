---
version: 1.2.0
title: 測試
---

測試 (Testing) 是開發軟體的一個重要部分。
在本課程中，將介紹如何使用 ExUnit 測試 Elixir 程式碼，以及一些很棒的測試方法。

{% include toc.html %}

## ExUnit

Elixir 的內建測試 frameworks 是 ExUnit，它包含徹底測試程式碼所需的一切。
在繼續之前，需要注意的是，測試是以 Elixir scripts 的形式實現，所以需要使用 `.exs` 做為檔案副檔名。
在執行測試之前，需要用 `ExUnit.start()` 來啟動 ExUnit，這通常在 `test/test_helper.exs` 中完成設定。

當我們在上個課程中生成範例專案時，mix 已經建立了一個簡單的測試，可以在 `test/example_test.exs` 找到它：

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :world
  end
end
```

可以使用 `mix test` 執行專案測試。
如果現在執行，應該會看到類似於以下的輸出：

```shell
..

Finished in 0.03 seconds
2 tests, 0 failures
```

為什麼在輸出訊息中出現兩個點(dot)？除了在 `test/example_test.exs` 的測試外，Mix 同時在 `lib/example.ex` 建立了一個文件測試 (doctest)。

```elixir
defmodule Example do
  @moduledoc """
  Documentation for Example.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Example.hello
      :world

  """
  def hello do
    :world
  end
end
```

### 斷言 (assert)

如果你有過編寫測試的經驗，那麼你是熟悉 `assert` 的；在某些 frameworks 中是使用 `should` 或 `expect` 來替代 `assert`。

使用 `assert` 巨集來測試表達式是否為真。
如果測試事件結果不為真，就會出現錯誤訊息，測試結果將為失敗 (fail)。
為了測試失敗情境，讓我們改變範例內容，然後再次執行 `mix test`：

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :word
  end
end
```

現在應該看到不同的輸出訊息：

```shell
  1) test greets the world (ExampleTest)
     test/example_test.exs:5
     Assertion with == failed
     code:  assert Example.hello() == :word
     left:  :world
     right: :word
     stacktrace:
       test/example_test.exs:6 (test)

.

Finished in 0.03 seconds
2 tests, 1 failures
```

ExUnit 會告訴我們失敗斷言 (failed assertions) 出現的行數、期望的值 (expected value)，以及實際的值 (actual value) 是多少。

### refute

`refute` 之於 `assert` 如同 `unless` 之於 `if`。
當想確保一個陳述式永遠為假 (false) 的時候請使用 `refute` 。

### assert_raise

有時候需要斷言測試一個被觸發的錯誤 (error)。
我們可以用 `assert_raise` 來做到這一點。
這將在之後的 Plug 課程中看到一個 `assert_raise` 的例子。

### assert_receive

在 Elixir 中，應用程式是由互相發送訊息的 actors/processes 組成，因此會有測試發送訊息的需要。
由於 ExUnit 在其自身的執行序 (process) 中執行，所以可以像其它任何執行序一樣接收訊息，並可以使用 `assert_received` 巨集執行斷言： 

```elixir
defmodule SendingProcess do
  def run(pid) do
    send(pid, :ping)
  end
end

defmodule TestReceive do
  use ExUnit.Case

  test "receives ping" do
    SendingProcess.run(self())
    assert_received :ping
  end
end
```

`assert_received` 不等待訊息 (messages)，但可使用 `assert_receive` 指定超時 (timeout)。

### capture_io 和 capture_log

通過 `ExUnit.CaptureIO` 捕獲 (Capturing) 應用程式的輸出而不需要改變原來的應用程式是可能的。
只需將生成輸出的函數傳遞進去：

```elixir
defmodule OutputTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "outputs Hello World" do
    assert capture_io(fn -> IO.puts("Hello World") end) == "Hello World\n"
  end
end
```

`ExUnit.CaptureLog` 就是 `Logger` 的捕獲輸出 (capturing output)。

## 測試設定 (Test Setup)

在某些情況下，會需要在測試之前執行設定。
為了完成設定，可以使用 `setup` 和 `setup_all` 巨集。
`setup` 會在每個測試之前執行，`setup_all` 則只在整套測試流程之前執行一次。
預計測試結果將回傳一個 `{:ok, state}` tuple，這個 state 可用於後續的測試中。

為了方便舉例，我們將改寫程式碼並使用 `setup_all`：

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  setup_all do
    {:ok, recipient: :world}
  end

  test "greets", state do
    assert Example.hello() == state[:recipient]
  end
end
```

## Mocking

Elixir 對於 mocking 的簡單回答是：不。
你可能本能地想使用 mocks，但在 Elixir 社群中，有充分理由不鼓勵這樣做。

對於更長篇幅的討論，請參閱此 [出色文章](http://blog.plataformatec.com.br/2015/10/mocks-and-explicit-contracts/)。
要點在於，相對於用模擬 (mocking) 測試耦合性 (mock 為*動詞* )，明確定義應用程式之外的程式碼介面（行為）且在客戶端程式碼使用 Mock (mock 為*名詞* ) 執行 (implementations) 來進行測試是有很多優點的。

要切換應用程式中程式碼的實作，首選方法是將模組作為引數 (arguments) 傳遞並使用預設值。
如果這樣沒有作用，請使用內建的設定機制。
建立這些模擬實作，並不需要特殊的模擬函式庫，只需要行為 (behaviours) 和回呼。
