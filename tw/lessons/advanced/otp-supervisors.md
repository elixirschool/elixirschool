---
version: 1.0.1
title: OTP Supervisors
---

Supervisors 是一個有特殊目的處理程序：它監控其它處理程序。這些 supervisors 使我們能夠藉由在子 (child) 處理程序失效時自動重新啟動，進而建立有故障容錯能力 (fault-tolerant) 的應用程式 。

{% include toc.html %}

## 配置 (Configuration)

Supervisors 的魔法是藏在 `Supervisor.start_link/2` 函數中。除了能啟動 Supervisors 和子處理程序 (Children) 之外，它還允許定義 supervisor 用於管理子處理程序的策略 (strategy)。

子處理程序使用一個列表和從 `Supervisor.Spec` 導入的 `worker/3` 函數來定義。`worker / 3` 函數需要一個模組、引數和一組選項。在 `worker/3` 內部，初始化期間會和引數一起呼用 `start_link/3` 。

現在從使用 [OTP Concurrency](../../advanced/otp-concurrency) 課程中的 SimpleQueue 開始吧：

```elixir
import Supervisor.Spec

children = [
  worker(SimpleQueue, [], name: SimpleQueue)
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

如果處理程序崩潰或被終止，Supervisor 會自動重新啟動它，就像什麼都沒發生過一樣。

### 策略 (Strategies)

Supervisors 目前有四種不同的重新啟動策略：

+ `:one_for_one` - 只重新啟動失敗的子處理程序。

+ `:one_for_all` - 重新啟動錯誤事件中所有的子處理程序。

+ `:rest_for_one` - 重新啟動失敗的處理程序與在其之後啟動的任何處理程序。

+ `:simple_one_for_one` - 最適合動態 (dynamically) 附加的子處理程序。
Supervisor 規範被要求包含一個子處理程序，但是這個子處理程序可以被衍生 (spawned) 多次。當需要動態地啟動和停止受監控的子處理程序時，將預期使用這個策略。

### 重新開始值 (Restart values)

對待子處理程序崩潰有幾種方法：

+ `:permanent` - 子處理程序總是重新啟動。

+ `:temporary` - 子處理程序不會重新啟動。

+ `:transient` - 子處理程序只有在異常終止時才會重新啟動。

這不是必需的選項，不過預設為 `:permanent`。

### 巢套 (Nesting)

除了 worker 處理程序外，還可以藉由監控 supervisors 來建立一個 supervisors 樹。唯一的區別是以 `supervisor/3` 替換 `worker/3` ：

```elixir
import Supervisor.Spec

children = [
  supervisor(ExampleApp.ConnectionSupervisor, [[name: ExampleApp.ConnectionSupervisor]]),
  worker(SimpleQueue, [[], [name: SimpleQueue]])
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

## Task Supervisor

Tasks 有自己專屬的 Supervisor，`Task.Supervisor`。
被設計用於動態建立 tasks，這個 supervisor 在內部使用 `:simple_one_for_one` 。

### 設定

`Task.Supervisor` 設定上與其他 supervisors 沒有區別：

```elixir
import Supervisor.Spec

children = [
  supervisor(Task.Supervisor, [[name: ExampleApp.TaskSupervisor, restart: :transient]])
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

 而 `Task.Supervisor` 與 `Supervisor` 的主要區別在於其預設的重新啟動策略為`:temporary`（ tasks 永遠不會被重新啟動）。

### 監控 Tasks

在 supervisor 啟動後，可以使用 `start_child/2` 函數來建立監控 task：

```elixir
{:ok, pid} = Task.Supervisor.start_child(ExampleApp.TaskSupervisor, fn -> background_work end)
```

如果 task 過早崩潰，它將被重新啟動。在處理接踵而來的連接 (connections) 或執行背景工作時，將會特別有用。