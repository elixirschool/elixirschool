---
version: 1.1.1
title: OTP Supervisors
---

Supervisors 是一個有特殊目的處理程序：它監控其它處理程序。這些 supervisors 使我們能夠藉由在子 (child) 處理程序失效時自動重新啟動，進而建立有故障容錯能力 (fault-tolerant) 的應用程式 。

{% include toc.html %}

## 配置 (Configuration)

Supervisors 的魔法是藏在 `Supervisor.start_link/2` 函數中。除了能啟動 Supervisors 和子處理程序 (Children) 之外，它還允許定義 supervisor 用於管理子處理程序的策略 (strategy)。

現在從使用 [OTP Concurrency](../../advanced/otp-concurrency) 課程中的 SimpleQueue 開始吧：

使用 `mix new simple_queue --sup` 建立一個帶有 supervisor tree 的新專案。`SimpleQueue` 模組的程式碼應該置於 `lib/simple_queue.ex` ，而新增的 supervisor 程式碼則於 `lib/simple_queue/application.ex` 中。

子處理程序使用一個列表或列表模組的名稱來定義。

```elixir
defmodule SimpleQueue.Application do
  use Application

  def start(_type, _args) do
    children = [
      SimpleQueue
    ]

    opts = [strategy: :one_for_one, name: SimpleQueue.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

或者 tuples 的列表，如果要包含配置選項：

```elixir
defmodule SimpleQueue.Application do
  use Application

  def start(_type, _args) do
    children = [
      {SimpleQueue, [1, 2, 3]}
    ]

    opts = [strategy: :one_for_one, name: SimpleQueue.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

如果執行 `iex -S mix` 將會看到 `SimpleQueue` 被自動地啟動。

```elixir
iex> SimpleQueue.queue
[1, 2, 3]
```

如果 `SimpleQueue` 處理程序崩潰或被終止，Supervisor 會自動重新啟動它，就像什麼都沒發生過一樣。

### 策略 (Strategies)

Supervisors 目前有三種不同的重新啟動策略：

+ `:one_for_one` - 只重新啟動失敗的子處理程序。

+ `:one_for_all` - 重新啟動錯誤事件中所有的子處理程序。

+ `:rest_for_one` - 重新啟動失敗的處理程序與在其之後啟動的任何處理程序。

### 子處理程序規範 (Child Specification)

在 supervisor 啟動後，它必須知道如何啟動/停止/重啟它的子處理程序。每個子處理程序模組都應該有一個 `child_spec/1` 函數來定義這些行為。`use GenServer`、`use Supervisor` 和 `use Agent` 巨集自動定義了這個方法 (`SimpleQueue` 有 `use Genserver`，所以不需要修改模組)，但是如果需要自己定義， `child_spec/1` 應該回傳一個選項的映射 (map of options)：

```elixir
def child_spec(opts) do
  %{
    id: SimpleQueue,
    start: {__MODULE__, :start_link, [opts]},
    shutdown: 5_000,
    restart: :permanent,
    type: :worker
  }
end
```

+ `id` - 必要的鍵。用於 supervisor 識別子處理程序規範。

+ `start` - 必要的鍵。由 supervisor 啟動時所呼用的模組/函數/參數。

+ `shutdown` - 可選的鍵。定義子處理程序在關閉期間的行為，選項包括：

  + `:brutal_kill` - 子處理程序立即停止

  + 任何正整數 -  supervisor 將在殺死子處理程序之前以時間毫秒為單位等待。如果處理程序是 `:worker` 類型，此選項預設為 5000。

  + `:infinity` - Supervisor 在殺死子處理程序前將無限期地等待。預設給 `:supervisor` 處程程序類型，不建議用在 `:worker` 類型。

+ `restart` - 可選的鍵。對待子處理程序崩潰有幾種方法：

  + `:permanent` - 子處理程序永遠重新啟動，所有處理程序的預設值。

  + `:temporary` - 子處理程序不會重新啟動。

  + `:transient` - 子處理程序只有在異常終止時才會重新啟動。

+ `type` - 可選的鍵。處理程序可以是 `:worker` 或 `:supervisor`，預設是 `:worker`。

## DynamicSupervisor

Supervisors 通常在應用程式啟始時伴隨子處理程序啟動。但是，有時應用程式啟始時受監視的子處理程序仍是未知 (例如，可能有一個 Web 應用程式啟動一個新的處理程序來處理使用者到網站的連接)。
對於這些情況，需要一個可以因著需求啟動子處理程序的 supervisor。 而 DynamicSupervisor 就是用於處理這種情況。

由於不會指定子處理程序，因此只需要為 supervisor 定義執行時的選項。DynamicSupervisor 只有支援 `:one_for_one` 監視策略:

```elixir
options = [
  name: SimpleQueue.Supervisor,
  strategy: :one_for_one
]

DynamicSupervisor.start_link(options)
```

那麼，為了動態啟動一個新的 SimpleQueue 將使用 `start_child/2` 來獲取一個 supervisor 和子處理程序規範 (再次說明， `SimpleQueue` 使用 `use GenServer` ，因此已經定義了子處理程序規範)：

```elixir
{:ok, pid} = DynamicSupervisor.start_child(SimpleQueue.Supervisor, SimpleQueue)
```

## Task Supervisor

Tasks 有自己專屬的 Supervisor，`Task.Supervisor`。
被設計用於動態建立 tasks，這個 supervisor 在內部使用 `DynamicSupervisor`。

### 設定

`Task.Supervisor` 設定上與其他 supervisors 沒有區別：

```elixir
children = [
  {Task.Supervisor, name: ExampleApp.TaskSupervisor, restart: :transient}
]

{:ok, pid} = Supervisor.start_link(
```

而 `Task.Supervisor` 與 `Supervisor` 的主要區別在於其預設的重新啟動策略為 `:temporary`（tasks 永遠不會被重新啟動）。

### 監控 Tasks

在 supervisor 啟動後，可以使用 `start_child/2` 函數來建立監控 task：

```elixir
{:ok, pid} = Task.Supervisor.start_child(ExampleApp.TaskSupervisor, fn -> background_work end)
```

如果 task 過早崩潰，它將被重新啟動。在處理接踵而來的連接 (connections) 或執行背景工作時，將會特別有用。
