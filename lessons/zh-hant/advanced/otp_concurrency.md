---
version: 1.0.3
title: OTP 並行性
---

我們已經看過 Elixir 抽象的並行性，但是有時候需要更好的控制，為此我們轉而了解構建 Elixir 的 OTP 行為 (behaviors)。

在本課程中，焦點會放在最龐大的部分：GenServers。

{% include toc.html %}

## GenServer

OTP 伺服器是具有實現一組回呼 GenServer 行為的模組。在最基本的級別上，GenServer 是一個執行迴圈的單一處理程序，每次疊代都處理一個經由更新狀態來的請求。

為了展示 GenServer API，我們將實現一個基本佇列 (queue) 來儲存與檢索值。

要開始使用 GenServer，需要啟動它並處理初始化。而在多數情況下，我們希望連接處理程序，所以使用 `GenServer.start_link/3`。
我們將傳入正在啟動的 GenServer 模組、初始引數和一組 GenServer 選項。引數將傳遞給 `GenServer.init/1` ，通過它的回傳值設置初始狀態。在下面例子當中，引數將是我們的初始狀態：

```elixir
defmodule SimpleQueue do
  use GenServer

  @doc """
  Start our queue and link it.  This is a helper function
  """
  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @doc """
  GenServer.init/1 callback
  """
  def init(state), do: {:ok, state}
end
```

### 同步函數 (Synchronous Functions)

通常需要以同步方式與 GenServers 互動，呼用一個函數並等待回應。
為了處理同步請求，需要實現 `GenServer.handle_call/3` 回呼函數，該回呼函數採用：請求、呼用者的 PID 和現有狀態；它被預期通過回傳一個 tuple 來回覆：`{:reply, response, state}`。

通過模式比對，可以為許多不同的請求和狀態定義回呼。可以在 [`GenServer.handle_call/3`](https://hexdocs.pm/elixir/GenServer.html#c:handle_call/3) 文件中找到被接受回傳值的完整清單。

為了展示同步請求，現在加入顯示當前佇列和刪除值的功能：

```elixir
defmodule SimpleQueue do
  use GenServer

  ### GenServer API

  @doc """
  GenServer.init/1 callback
  """
  def init(state), do: {:ok, state}

  @doc """
  GenServer.handle_call/3 callback
  """
  def handle_call(:dequeue, _from, [value | state]) do
    {:reply, value, state}
  end

  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  ### Client API / Helper functions

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```

現在啟動 SimpleQueue 並測試新的出列 (dequeue) 功能：

```elixir
iex> SimpleQueue.start_link([1, 2, 3])
{:ok, #PID<0.90.0>}
iex> SimpleQueue.dequeue
1
iex> SimpleQueue.dequeue
2
iex> SimpleQueue.queue
[3]
```

### 非同步函數 (Asynchronous Functions)

非同步 (Asynchronous) 請求通過 `handle_cast/2` 回呼來處理。這很像 `handle_call/3` ，但是不接收呼用者 (caller)，也不會回覆。

我們將實現的排隊 (enqueue) 功能是非同步的，更新佇列 (queue) 但不阻礙當前的執行：

```elixir
defmodule SimpleQueue do
  use GenServer

  ### GenServer API

  @doc """
  GenServer.init/1 callback
  """
  def init(state), do: {:ok, state}

  @doc """
  GenServer.handle_call/3 callback
  """
  def handle_call(:dequeue, _from, [value | state]) do
    {:reply, value, state}
  end

  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  @doc """
  GenServer.handle_cast/2 callback
  """
  def handle_cast({:enqueue, value}, state) do
    {:noreply, state ++ [value]}
  end

  ### Client API / Helper functions

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def enqueue(value), do: GenServer.cast(__MODULE__, {:enqueue, value})
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```

現在來使用新功能：

```elixir
iex> SimpleQueue.start_link([1, 2, 3])
{:ok, #PID<0.100.0>}
iex> SimpleQueue.queue
[1, 2, 3]
iex> SimpleQueue.enqueue(20)
:ok
iex> SimpleQueue.queue
[1, 2, 3, 20]
```

有關更多資訊，請參閱官方 [GenServer](https://hexdocs.pm/elixir/GenServer.html#content) 文件。
