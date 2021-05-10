%{
  version: "1.2.0",
  title: "Poolboy",
  excerpt: """
  如果不限制程式可以生成的最大並行處理程序數量，則會輕易地耗盡系統資源。[Poolboy](https://github.com/devinus/poolboy) 是一個廣泛使用於解決這個問題的 Erlang 輕量級通用池函式庫。
  """
}
---

## 為什麼使用 Poolboy？

現在暫時考慮一個具體的例子。
任務是建立一個用於將使用者個人資訊儲存到資料庫的應用程式。
如果為每個使用者的註冊都建立一個處理程序，那麼將建立無限數量的連接。
在某些時候，這些連接的數量可能超過資料庫伺服器的容量。
最終，應用程式可能會出現逾時和各種異常。

解決方案是使用一組 worker(處理程序) 來限制連接數，而不是為每個使用者的註冊都建立處理程序。
這樣，可以輕鬆避免耗盡系統資源。

這就是 Poolboy 的用武之地。
它允許輕鬆設定由一個 `Supervisor` 管理的 worker 池，而無需付出太多努力。
有許多函式庫使用 Poolboy。
例如， `postgrex` 的連接池 *(當使用 PostgreSQL 時由藉力 Ecto)* 和 `redis_poolex` *（Redis 連接池）*是一些使用 Poolboy 的熱門函式庫。

## 安裝

使用 mix 來安裝是輕而易舉的。
需要做的就是將 Poolboy 加入到 `mix.exs` 的相依性中。

首先來建立一個應用程式：

```shell
$ mix new poolboy_app --sup
```

將 Poolboy 加入到 `mix.exs` 的相依性中。

```elixir
defp deps do
  [{:poolboy, "~> 1.5.1"}]
end
```

然後提取依賴性，包括 Poolboy。
```shell
$ mix deps.get
```

## 配置選項

為了開始使用 Poolboy，需要了解各種配置選項。

* `:name` - pool 的名稱。
Scope 可以是 `:local`、`:global` 或 `:via`。
* `:worker_module` - 代表 worker 的模組。
* `:size` - 最大處理程序數。
* `:max_overflow` - 池為空時建立的臨時 worker 最大數量。
(可選)
* `:strategy` - `:lifo` 或 `:fifo`， 決定回傳池中 worker 應放在可用 worker 隊列的第一位還是最後一位。
預設是 `:lifo`。
(可選)

## 配置 Poolboy

在此範例中，將建立一個 worker 池，負責處理計算數字的平方根請求。
範例將保持簡單，以便可以專注在 Poolboy。

現在定義 Poolboy 的配置選項，並將 Poolboy worker 池入加為應用程式的子 worker。
編輯 `lib/poolboy_app/application.ex`：

```elixir
defmodule PoolboyApp.Application do
  @moduledoc false

  use Application

  defp poolboy_config do
    [
      name: {:local, :worker},
      worker_module: PoolboyApp.Worker,
      size: 5,
      max_overflow: 2
    ]
  end

  def start(_type, _args) do
    children = [
      :poolboy.child_spec(:worker, poolboy_config())
    ]

    opts = [strategy: :one_for_one, name: PoolboyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

首先定義池的配置選項。
將池命名為 `:worker` 並且設置 `:scope` 為 `:local`。
接著，將 `PoolboyApp.Worker` 模組指定為該池應使用的 `:worker_module`。
同時也將池的 `:size` 設定為總共有 `5` 個 worker。
同樣，如果所有 worker 都處於負載狀態，那將告訴它使用 `:max_overflow` 選項來建立更多的 2 個 worker 來協助負載。
*(`overflow` worker 完成工作後就會消失。)*

接下來，將向子陣例加入 `:poolboy.child_spec/2` 函數，以便在應用程式啟動時啟動 worker 池。
它帶有兩個參數：池的名稱和池配置。

## 建立 Worker
worker 模組將是一個簡單的 `GenServer`，可以計算數字的平方根，休眠一秒鐘，然後印出 worker 的 pid。
建立 `lib/poolboy_app/worker.ex`：

```elixir
defmodule PoolboyApp.Worker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_call({:square_root, x}, _from, state) do
    IO.puts("process #{inspect(self())} calculating square root of #{x}")
    Process.sleep(1000)
    {:reply, :math.sqrt(x), state}
  end
end
```

## 使用 Poolboy

現在有了 `PoolboyApp.Worker`，就可以測試 Poolboy。
現在建立一個簡單的模組，該模組使用 Poolboy 建立並行處理程序。
`:poolboy.transaction/3` 是可用於與 worker 池連接的函數。
建立 `lib/poolboy_app/test.ex`:

```elixir
defmodule PoolboyApp.Test do
  @timeout 60000

  def start do
    1..20
    |> Enum.map(fn i -> async_call_square_root(i) end)
    |> Enum.each(fn task -> await_and_inspect(task) end)
  end

  defp async_call_square_root(i) do
    Task.async(fn ->
      :poolboy.transaction(
        :worker,
        fn pid -> GenServer.call(pid, {:square_root, i}) end,
        @timeout
      )
    end)
  end

  defp await_and_inspect(task), do: task |> Task.await(@timeout) |> IO.inspect()
end
```

執行測試函數來查看結果。

```shell
$ iex -S mix
```

```elixir
iex> PoolboyApp.Test.start()
process #PID<0.182.0> calculating square root of 7
process #PID<0.181.0> calculating square root of 6
process #PID<0.157.0> calculating square root of 2
process #PID<0.155.0> calculating square root of 4
process #PID<0.154.0> calculating square root of 5
process #PID<0.158.0> calculating square root of 1
process #PID<0.156.0> calculating square root of 3
...
```

如果池中沒有可用的 worker，則 Poolboy 將在預設逾時(五秒)後逾時，並且將不接受任何新請求。
在範例中，將增加預設逾時到一分鐘，以展示如何更改預設逾時值。
在此應用程式中，如果將 `@timeout` 的值更改為小於 1000，則可以觀察到錯誤。

即使嘗試建立多個處理程序 *(在上面的範例中總共 20 個)* `:poolboy.transaction/3` 函數仍將會限制建立的最大處理程序數為 5 *(如有需要，可加入兩個 overflow worker)*，正如在配置中定義的那樣。
所有請求都將使用池中 worker 進行處理，而不是為每個請求建立新處理程序。
