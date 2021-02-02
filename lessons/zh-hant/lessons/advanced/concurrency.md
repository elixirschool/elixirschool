%{
  version: "1.1.0",
  title: "並行性",
  excerpt: """
  Elixir 的賣點之一是支援並行性 (concurrency)。感謝 Erlang VM (BEAM)，Elixir 的並行性比預期的要容易。並行性模組依賴於 Actors，一個包含通過信文傳遞 (message passing) 而與其它處理程序 (processes) 對話的行程。

在本課程中，將介紹 Elixir 附帶的並行性模組。而在下面章節中，會介紹實現它們的 OTP 行為。
  """
}
---

## 處理程序 (Processes)

Erlang VM 中的處理程序是輕量級的，可以在所有的 CPU 上執行。儘管看起來像原生執行緒 (native threads)，但它們更簡單，在一個 Elixir 應用程式中有數千個並性處理程序並不罕見。

建立一個新處理程序的最簡單方法是 `spawn`，它可以使用匿名函數或命名函數。當建立一個新處理程序時，它會回傳一個 _Process Identifier_ 或 PID，以在應用程式中獨特地標識它。

現在以建立一個模組並定義一個想執行的函數來開始：

```elixir
defmodule Example do
  def add(a, b) do
    IO.puts(a + b)
  end
end

iex> Example.add(2, 3)
5
:ok
```

為了非同步 (asynchronously) 地賦值 (evaluate) 函數，使用 `spawn/3`：

```elixir
iex> spawn(Example, :add, [2, 3])
5
#PID<0.80.0>
```

### 信文遞送 (Message Passing)

為了相互溝通，處理程序依靠信文遞送。其中有兩個主要元件： `send/2` 與 `receive`。`send/2` 函數允許發送信文給 PID。
而監聽 (listen) 使用 `receive` 來配對信文。如果找不到配對，則執行式將處於不中斷狀態。

```elixir
defmodule Example do
  def listen do
    receive do
      {:ok, "hello"} -> IO.puts("World")
    end

    listen
  end
end

iex> pid = spawn(Example, :listen, [])
#PID<0.108.0>

iex> send pid, {:ok, "hello"}
World
{:ok, "hello"}

iex> send pid, :ok
:ok
```

你可能會注意到 `listen/0` 函數是遞迴的，這使得處理程序可以處理多個信文。沒有遞迴，處理程序將在處理完第一則信文後退出。

### 處理程序連結 (Process Linking)

當一個處理程序崩潰時，有個與 `spawn` 有關問題是已知的。為此，需要使用 `spawn_link` 連接處理程序。兩個被連接一起的處理程序將能收到從對方來的退出通知：

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)
end

iex> spawn(Example, :explode, [])
#PID<0.66.0>

iex> spawn_link(Example, :explode, [])
** (EXIT from #PID<0.57.0>) evaluator process exited with reason: :kaboom
```

有時我們不希望被連結的處理程序造成當前的崩潰。為此，需要使用 `Process.flag/2` 來捕獲 (trap) 退出。它使用 erlang 的 [process_flag/2](http://erlang.org/doc/man/erlang.html#process_flag-2) 函數來做為 `trap_exit` 旗標 (flag)。當捕獲退出時 (`trap_exit` 是被設定為 `true`)，退出信號將作為一個 tuple 信文而被接收：`{:EXIT, from_pid, reason}`。

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)

  def run do
    Process.flag(:trap_exit, true)
    spawn_link(Example, :explode, [])

    receive do
      {:EXIT, from_pid, reason} -> IO.puts("Exit reason: #{reason}")
    end
  end
end

iex> Example.run
Exit reason: kaboom
:ok
```

### 處理程序監視 (Process Monitoring)

如果不想將兩個處理程序連接起來，但是仍然需要通知功能呢？為此，可以使用 `spawn_monitor` 進行處理程序監視。當監視的處理程序崩潰時，會收到信文，而不會造成當前的處理程序崩潰或者需要捕獲退出。

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)

  def run do
    {pid, ref} = spawn_monitor(Example, :explode, [])

    receive do
      {:DOWN, ref, :process, from_pid, reason} -> IO.puts("Exit reason: #{reason}")
    end
  end
end

iex> Example.run
Exit reason: kaboom
:ok
```

## Agents

Agents 是背景處理程序持續狀態 (maintaining state) 的抽象化。可以從應用程式和節點 (node) 中存取。Agent 狀態被設置為函數的回傳值：

```elixir
iex> {:ok, agent} = Agent.start_link(fn -> [1, 2, 3] end)
{:ok, #PID<0.65.0>}

iex> Agent.update(agent, fn (state) -> state ++ [4, 5] end)
:ok

iex> Agent.get(agent, &(&1))
[1, 2, 3, 4, 5]
```

當命名一個 Agent 後，可以用這個命名來代替它的 PID：

```elixir
iex> Agent.start_link(fn -> [1, 2, 3] end, name: Numbers)
{:ok, #PID<0.74.0>}

iex> Agent.get(Numbers, &(&1))
[1, 2, 3]
```

## Tasks

Tasks 提供了一種在背景執行函數的方法，可以稍後再擷取它的回傳值。當處理耗時 (expensive) 操作時，因不阻礙當前應用程序的執行而特別有用。

```elixir
defmodule Example do
  def double(x) do
    :timer.sleep(2000)
    x * 2
  end
end

iex> task = Task.async(Example, :double, [2000])
%Task{pid: #PID<0.111.0>, ref: #Reference<0.0.8.200>}

# Do some work

iex> Task.await(task)
4000
```
