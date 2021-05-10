---
version: 1.0.1
title: OTP 分散式
---

## 分散式簡介
可以於一組分散在單個主機或多個主機上的不同 node 中執行 Elixir 應用程式。
Elixir 允許通過幾個不同的機制在這些 node 之間進行通訊，在本課程中將概述這些機制。

{% include toc.html %}

## node 間的通訊

Elixir 在 Erlang VM 上執行，這意味著它可以取用 Erlang 強大的[分散式機能](http://erlang.org/doc/reference_manual/distributed.html)

> 分散式 Erlang 系統由許多相互通訊的 Erlang 執行期 (runtime) 系統組成。
每個這樣的執行期系統稱為 node。

node 是任何已被賦予名稱的 Erlang 執行期系統。
可以通過打開 `iex` 對話並命名它來啟動一個 node：

```bash
iex --sname alex@localhost
iex(alex@localhost)>
```

在另一個命令列介面視窗中開啟另一個 node：

```bash
iex --sname kate@localhost
iex(kate@localhost)>
```

這兩個 node 可以使用 `Node.spawn_link/2` 互相發送訊息。

###  藉由 `Node.spawn_link/2` 進行通訊

這個函數有兩個參數：
* 要連接 node 的名稱
* 由遠端處理程序要在該 node 上執行的函數

它建立與遠端 node 的連接並在該 node 上執行指定的函數，並回傳連接處理程序的 PID。

現在定義一個模組，`Kate`。在 `Kate` node 中會知道如何介紹 Kate 這個人：

```elixir
iex(kate@localhost)> defmodule Kate do
...(kate@localhost)>   def say_name do
...(kate@localhost)>     IO.puts "Hi, my name is Kate"
...(kate@localhost)>   end
...(kate@localhost)> end
```

#### 發送訊息

現在，可以使用 [`Node.spawn_link/2`](https://hexdocs.pm/elixir/Node.html#spawn_link/2) 讓 `alex` node 要求 `kate`  node 呼用 `say_name/0` 函數：

```elixir
iex(alex@localhost)> Node.spawn_link(:kate@localhost, fn -> Kate.say_name end)
Hi, my name is Kate
#PID<10507.132.0>
```

#### 一個關於 I/O 和 Nodes 的注意事項

請注意，雖然 `Kate.say_name/0` 正在遠端 node 上執行，但它是在本機接收 `IO.puts` 輸出或呼用的 node。
那是因為本機 node 是 **組長(group leader)**。
Erlang VM 藉由處理程序管理 I/O。
這允許在分散式 node 間執行 I/O 工作，如 `IO.puts`。
這些分散式處理程序是由 I/O 處理程序組長管理。
而組長始終是產生處理程序的 node。
因此，既然 `alex` node 是稱之為 `spawn_link/2` 的 node，則該 node 是組長，並且 `IO.puts` 的輸出將被定向到該 node 的標準輸出流中。

#### 回應訊息

如果希望接收訊息的 node 將一些 *回應* 發送回發送方，該怎麼辦？可以使用一組簡單的 `receive/1` 和 [`send/3`](https://hexdocs.pm/elixir/Process.html#send/3) 設定來完整實現。

`alex` node 會產生一個指向 `kate` node 的 link，並為 `kate` node 提供一個匿名函數來執行。
該匿名函數將監聽描述收到特定訊息的 tuple 和 `alex` node 的 PID。
它會通過 `send` 回傳給 `alex` node 的 PID 來回應該訊息：

```elixir
iex(alex@localhost)> pid = Node.spawn_link :kate@localhost, fn ->
...(alex@localhost)>   receive do
...(alex@localhost)>     {:hi, alex_node_pid} -> send alex_node_pid, :sup?
...(alex@localhost)>   end
...(alex@localhost)> end
#PID<10467.112.0>
iex(alex@localhost)> pid
#PID<10467.112.0>
iex(alex@localhost)> send(pid, {:hi, self()})
{:hi, #PID<0.106.0>}
iex(alex@localhost)> flush()
:sup?
:ok
```

#### 關於跨網路 node 間通訊

如果要在不同網路的 node 間發送訊息，啟動該命名節點同時需要一個共用 cookie ：

```bash
iex --sname alex@localhost --cookie secret_token
```

```bash
iex --sname kate@localhost --cookie secret_token
```

只有以相同 `cookie` 開頭的 node 才能成功對接到彼此。

#### `Node.spawn_link/2` 限制

雖然 `Node.spawn_link/2` 說明了 node 間的關係及可以在它們之間發送訊息的規則，但它真的 _不是_ 將執行在分散式 node 上應用程式的正確選擇。
`Node.spawn_link/2` 產生孤立的處理程序，
即不受監控的處理程序。
要是能有一種方法產生 _跨 node 間_ 被監控的非同步處理程序…

## 分散式工作

[分散式工作](https://hexdocs.pm/elixir/master/Task.html#module-distributed-tasks) 允許跨 node 產生受監控的工作。
現在將構建一個簡單的 supervisor 應用程式，利用分散式工作來允許在分散式 node 中的另一個使用者通過 `iex` 對話來聊天。

### 定義 Supervisor 應用程式

創建應用程式：

```
mix new chat --sup
```

### 將 Task Supervisor 加入 Supervision Tree

Task Supervisor 動態地監控工作。
它啟動時沒有子處理程序，通常是在自己的 supervisor _監控下_，並且可以在以後用於監控任何數量的工作。

將為應用程式的 supervision tree 加入一個 Task Supervisor，並將其命名為 `Chat.TaskSupervisor`

```elixir
# lib/chat/application.ex
defmodule Chat.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Chat.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: Chat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

現在知道，無論在任一個 node 上啟動應用程式，`Chat.Supervisor` 都會執行並準備好監控工作。

### 使用受監控的工作發送訊息

現在將使用 [`Task.Supervisor.async/5`](https://hexdocs.pm/elixir/master/Task.Supervisor.html#async/5) 函數開始監控工作

此函數必須包含四個參數：

* 想用來監控工作的 supervisor。
這可以作為 `{SupervisorName, remote_node_name}` 的 tuple 傳遞，以便監控遠端 node 上的工作。
* 要執行函數的模組名稱
* 要執行的函數名稱
* 任何需要提供給該函數的參數

還可以傳入描述 shutdown 選項的第 5 個可選參數。
不過在此暫不考慮。

這個 Chat 應用程式非常簡單。
它將訊息發送到遠端 node，而遠端 node 通過 `IO.puts` 將這些訊息回應到遠端 node 的 標準輸出流(STDOUT)。

首先，定義一個函數，`Chat.receive_message/1`，我們希望工作在遠端 node 上執行。

```elixir
# lib/chat.ex
defmodule Chat do
  def receive_message(message) do
    IO.puts message
  end
end
```

接下來，教一下 `Chat` 模組如何使用監控工作將訊息發送到遠端 node。
現在將定義一個方法 `Chat.send_message/2` 來實現這個處理程序：

```elixir
# lib/chat.ex
defmodule Chat do
  ...

  def send_message(recipient, message) do
    spawn_task(__MODULE__, :receive_message, recipient, [message])
  end

  def spawn_task(module, fun, recipient, args) do
    recipient
    |> remote_supervisor()
    |> Task.Supervisor.async(module, fun, args)
    |> Task.await()
  end

  defp remote_supervisor(recipient) do
    {Chat.TaskSupervisor, recipient}
  end
end
```

現在來看看它的實際執行情況。

在一個終端機視窗中，並在命名的 `iex` 的對話中啟動聊天應用程式

```bash
iex --sname alex@localhost -S mix
```

打開另一個終端機視窗以在另一個命名的 node 上啟動應用程式：

```bash
iex --sname kate@localhost -S mix
```

現在，可以從 `alex` node，向 `kate` node 發送訊息：

```elixir
iex(alex@localhost)> Chat.send_message(:kate@localhost, "hi")
:ok
```

接著切換到 `kate` 的視窗，應該會看到以下訊息：

```elixir
iex(kate@localhost)> hi
```

`kate` node 可以回應 `alex` node：

```elixir
iex(kate@localhost)> hi
Chat.send_message(:alex@localhost, "how are you?")
:ok
iex(kate@localhost)>
```

訊息將出現在 `alex` node 的 `iex` 對話中：

```elixir
iex(alex@localhost)> how are you?
```

現在重新回顧程式碼並分析每一件發生的事。

現在有一個函數 `Chat.send_message/2`，它接收想要執行監控工作的遠端 node 名稱以及發送給該 node 的訊息。

該函數呼用 `spawn_task/4` 函數，啟動在遠端 node 上執行且由`Chat.TaskSupervisor` 監控具有給定名稱的非同步工作。
我們知道名為 `Chat.TaskSupervisor` 的 Task Supervisor 正在該 node 上執行，因為該 node _也_ 是執行聊天應用程式的實例，並且 `Chat.TaskSupervisor` 是作為聊天應用程式的 supervision tree 的一部分啟動的。

我們告訴 `Chat.TaskSupervisor` 來監控一個執行 `Chat.receive_message` 函數的工作，該工作的參數是從 `send_message/2` 傳遞給 `spawn_task/4` 的任何訊息。

因此，在遠端 `kate` node 上呼用 `Chat.receive_message("hi")` ，導致訊息 `"hi"`，被放到該 node 的標準輸出流中。
在這種情況下，由於該工作正在遠端 node 上進行監控，因此該 node 是此 I/O 處理程序的群組管理者。

### 回應來自遠端 node 的訊息

現在來讓聊天程式更聰明一點。
到目前為止，任何數量的使用者都可以在名為 `iex` 的對話中執行該應用程式並開始聊天。
但是，假設有一隻名叫 Moebi 的中型白狗不想被排除在外。
Moebi 想要加入聊天應用程式，但遺憾的是他不知道如何輸入，因為他是一隻狗。
因此，我們將教導 `Chat` 模組，讓它代表 Moebi 回應任何被發送到名為 `moebi@localhost` 的 node 的訊息。
無論你對 Moebi 說什麼，他都會回答 `"雞?"`，因為他真正的願望是吃雞肉。

我們將定義另一個版本的 `send_message/2` 函數，它在 `recipient` 參數上進行模式比對。
如果收件人是 `:moebi@locahost`，那麼將會

* 使用 `Node.self()` 獲取當前 node 的名稱
* 給出當前 node ，即
發送者名稱，到一個新函數 `receive_message_for_moebi/2`，這樣就可以發送訊息 _回_ 該 node。

```elixir
# lib/chat.ex
...
def send_message(:moebi@localhost, message) do
  spawn_task(__MODULE__, :receive_message_for_moebi, :moebi@localhost, [message, Node.self()])
end
```

接下來，將定義一個函數 `receive_message_for_moebi/2`，`IO.puts` 在 `moebi` node 的 STDOUT 流中輸出  訊息 _且_ 將訊息發送回發送者：

```elixir
# lib/chat.ex
...
def receive_message_for_moebi(message, from) do
  IO.puts message
  send_message(from, "chicken?")
end
```

通過使用發送原始訊息 node ("發送者 node") 的名稱呼用 `send_message/2` ，是告訴 _遠端_ node 在該發送者 node 上產生一個受監控的工作。

現在來看看它的實際執行效果。
在三個不同的終端機視窗中，打開三個不同命名的 node：

```bash
iex --sname alex@localhost -S mix
```

```bash
iex --sname kate@localhost -S mix
```

```bash
iex --sname moebi@localhost -S mix
```

讓 `alex` 向 `moebi` 發送訊息：

```elixir
iex(alex@localhost)> Chat.send_message(:moebi@localhost, "hi")
chicken?
:ok
```

我們可以看到 `alex` node 收到回應，`"雞?"`。
如果打開 `kate` node，會看到沒有收到任何訊息，因為 `alex` 和 `moebi` 都沒有發送給她(抱歉囉 `kate`)。
如果打開 `moebi` node 的終端機視窗，將看到 `alex` node 發送的訊息：

```elixir
iex(moebi@localhost)> hi
```

## 測試分散式程式碼

現在從為 `send_message` 函數編寫一個簡單的測試開始。

```elixir
# test/chat_test.ex
defmodule ChatTest do
  use ExUnit.Case, async: true
  doctest Chat

  test "send_message" do
    assert Chat.send_message(:moebi@localhost, "hi") == :ok
  end
end
```

如果通過 `mix test` 執行測試，會看到它失敗並出現以下錯誤：

```elixir
** (exit) exited in: GenServer.call({Chat.TaskSupervisor, :moebi@localhost}, {:start_task, [#PID<0.158.0>, :monitor, {:sophie@localhost, #PID<0.158.0>}, {Chat, :receive_message_for_moebi, ["hi", :sophie@localhost]}], :temporary, nil}, :infinity)
         ** (EXIT) no connection to moebi@localhost
```

這個錯誤非常合理 - 無法連接到名為 `moebi@localhost` 的 node，因為沒有這樣的 node 在執行。

可以通過執行以下幾個步驟來完成此測試：

* 打開另一個終端機視窗並執行該命名 node：`iex --sname moebi@localhost -S mix`
* 在第一個終端機，通過 `iex` 對話中命名的 node 執行 mix tests 進行測試：`iex --sname sophie@localhost -S mix test`

這是一項很繁瑣的工作，且絕對不會被視為一個自動化測試過程。

不過這裡可以採取兩個不同的選擇：

1.
如果必要的 node 未執行，則有條件地排除需要分散式 node 的測試。

2.
配置應用程式以避免在測試環境中的遠端 node 上建立工作。

現在來看看第一種方法。

### 有條件地排除帶標籤(Tags)的測試

現在將在此測試中加入一個 `ExUnit` 標籤：

```elixir
#test/chat_test.ex
defmodule ChatTest do
  use ExUnit.Case, async: true
  doctest Chat

  @tag :distributed
  test "send_message" do
    assert Chat.send_message(:moebi@localhost, "hi") == :ok
  end
end
```

如果測試 _不是_ 在命名 node 上執行，將在測試 helper 加入一些條件邏輯，以排除帶有此類標籤的測試。

```elixir
exclude =
  if Node.alive?, do: [], else: [distributed: true]

ExUnit.start(exclude: exclude)
```

現在檢查 node 是否存活，即
[`Node.alive?`](https://hexdocs.pm/elixir/Node.html#alive?/0) node 是否是分散式系統的一部分
如果沒有，可以告訴 `ExUnit` 跳過任何帶有 `distributed: true` 標籤的測試。
否則，會告訴它不要排除任何測試。

現在，如果執行平凡的 `mix test`，會看到：

```bash
mix test
Excluding tags: [distributed: true]

Finished in 0.02 seconds
1 test, 0 failures, 1 excluded
```

如果想執行分散式測試，只需要完成上一節中概述的步驟：執行 `moebi@localhost` node _且_ 藉由 `iex` 在命名節點中執行測試。

現在來看看其他測試方法 - 將應用程式配置為在不同環境中有不同的表現。

### 特定環境的應用程式配置

程式碼中告訴 `Task.Supervisor` 在遠端 node 上啟動監控工作的部分在這裡：

```elixir
# app/chat.ex
def spawn_task(module, fun, recipient, args) do
  recipient
  |> remote_supervisor()
  |> Task.Supervisor.async(module, fun, args)
  |> Task.await()
end

defp remote_supervisor(recipient) do
  {Chat.TaskSupervisor, recipient}
end
```

`Task.Supervisor.async/5` 接受想使用的 supervisor 為第一參數。
如果傳入 `{SupervisorName, location}` 的 tuple，它將啟動給定遠端 node 上指定的 supervisor。
但是，如果將 `Task.Supervisor` 傳遞的第一個參數只有 supervisor 名稱，它將使用該 supervisor 在本機監控工作。

讓 `remote_supervisor/1` 函數能夠根據不同環境配置。
在開發環境中，它將回傳 `{Chat.TaskSupervisor, recipient}`，而在測試環境中它將回傳 `Chat.TaskSupervisor`。

現在將通過應用程式變數執行此操作。

建立一個檔案 `config/dev.exs`，然後加入：

```elixir
# config/dev.exs
use Mix.Config
config :chat, remote_supervisor: fn(recipient) -> {Chat.TaskSupervisor, recipient} end
```

建立另一個檔案 `config/test.exs` 並加入：

```elixir
# config/test.exs
use Mix.Config
config :chat, remote_supervisor: fn(_recipient) -> Chat.TaskSupervisor end
```

記得在 `config/config.exs` 中取消註解這一行：

```elixir
import_config "#{Mix.env()}.exs"
```

最後，更新 `Chat.remote_supervisor/1` 函數以查找並使用儲存在新應用程式變數中的函數：

```elixir
# lib/chat.ex
defp remote_supervisor(recipient) do
  Application.get_env(:chat, :remote_supervisor).(recipient)
end
```

## 結論

Elixir 原生的分散式功能，歸功於 Erlang VM 的強大能力，且是使其成為如此強大工具的特色之一。
可以想像利用 Elixir 處理分散式計算來執行平行式背景作業，支援高性能應用程式，執行高代價的操作--您所命名。

本課程介紹 Elixir 中的分散式概念，並提供開始構建分散式應用程式的所需工具。
通過使用受監控的工作，可以在跨多個 node 的分散式應用程式中發送訊息。