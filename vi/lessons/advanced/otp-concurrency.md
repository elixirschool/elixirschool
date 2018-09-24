---
version: 0.9.1
title: OTP Concurrency
---

Chúng ta đã xem về các trừu tượng hoá của Elixir cho xử lý đồng thời (concurrency), nhưng đôi khi chúng ta cần quyền điều khiển lớn hơn, bởi thế chúng ta sẽ đi sâu vào tìm hiểu hành vi của OTP mà đã có sẵn ở trong Elixir.

Trong bài này, chúng ta sẽ tập trung vào hai phần chính: GenServers và GenEvents.

{% include toc.html %}

## GenServer

Một OTP server là một module với hành vi của GenServer mà được thực thi bởi một chuỗi các callbacks (tạm dịch: gọi ngược). GenServer khi nhìn vào mặt cơ bản nhất chỉ là một vòng lặp mà xử lý từng yêu cầu một mỗi lần, kèm với việc truyền ra trạng thái mới nhất (updated state).

Để minh hoạ về GenServer API, chúng ta sẽ thực hiện một hàng đợi (queue) cơ bản để lưu trữ và lấy ra các giá trị.

Để bắt đầu một GenServer chúng ta sẽ cần khởi động nó, và xử lý phần khởi tạo. Trong hầu hết các trường hợp, chúng ta sẽ muốn kết nối các tiến trình (process), bởi vậy chúng ta sẽ dùng `GenServer.start_link/3`. Chúng ta sẽ truyền vào GenServer module mà chúng ta đang khởi động, các biến khởi tạo và một chuỗi các lựa chọn (option) của GenServer. Các đối số sẽ được truyền vào `GenServer/init/1` mà ở trong đó sẽ cài đặt trạng thái ban đầu dựa vào giá trị trả về của nó. Trong ví dụ của chúng ta, các đối số sẽ là trạng thái khởi tạo:

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

### Các hàm tuần tự

Sẽ có những trường hợp cần thiết để tương tác với GenServers theo một cách tuần tự, gọi một hàm và đợi trả về của nó. Để xử lý yêu cầu một cách tuần tự, chúng ta cần thực thi `GenServer.handle_call/3` callback mà nhận vào: yêu cầu, PID của người gọi, và trạng thái hiện tại; một tuple sẽ được mong đợi để trả về: `{:reply, response, state}`.

Với việc sử dụng so trùng mẫu (pattern matching), chúng ta có thể định nghĩa callbacks cho rất nhiều yêu cầu và trạng thái. Một chuỗi hoàn chỉnh của các giá trị được phép trả về có thể được tìm thấy trong tài liệu [`GenServer.handle_call/3`](https://hexdocs.pm/elixir/GenServer.html#c:handle_call/3)

Để minh hoạ về yêu cầu tuần tự, hãy thêm vào tính năng để hiển thị trạng thái hiện tại của hàng đợi và xoá một giá trị:

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

  ### Client API / Helper methods

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```

Hãy khởi động SimpleQueue và kiểm thử tính năng dequeue nào:

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

### Hàm bất đồng bộ
Các yêu cầu bất đồng bộ sẽ được xử lý bởi callback `handle_cast/2`. Việc này cũng gần như `handle_call/3` nhưng không nhận vào người gọi (caller), và không mong đợi việc trả lời lại.

Chúng ta sẽ thực hiện hàm enqueue sao cho nó là bất đồng bộ, cập nhật hàng đợi nhưng không làm nghẽn xử lý hiện tại:

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

  ### Client API / Helper methods

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def enqueue(value), do: GenServer.cast(__MODULE__, {:enqueue, value})
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```

Hãy thử sử dụng chức năng mới này nào:

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
Để biết thêm thông tin, hãy xem tài liệu chính thức tại [GenServer](https://hexdocs.pm/elixir/GenServer.html#content).

## GenEvent

Chúng ta đã học được rằng GenServers là các tiến trình mà cần lưu giữ trạng thái và có thể xử lý được các yêu cầu đồng bộ cũng như bất đồng bộ. Vậy GenEvent là gì? GenEvents để quản lý các sự kiện (event) mà nó sẽ nhận vào một sự kiện, sau đó sẽ thông báo cho những consumers (tạm dịch: tiền trình tiêu dùng) đã đăng ký. Nhờ đó chúng ta có một cơ chế để thêm và xoá các hàm xử lý (handlers) động cho các sự kiện.

### Xử lý các sự kiện

Hàm callback quan trọng nhất trong GenEvents mà bạn có thể hình dung là `handle_event/2`. Hàm này nhận vào sự kiện cùng với trạng thái hiện tại của hàm xử lý, sau đó sẽ trả lại một tuple: `{:ok, state}`.

Để minh hoạ tính năng của GenEvent, chúng ta hãy bắt đầu bằng việc tạo hai hàm xử lý (handlers), một hàm dành để giữ log của những thông tin đến, và một để lưu trữ chúng lại (trên lý thuyết):

```elixir
defmodule LoggerHandler do
  use GenEvent

  def handle_event({:msg, msg}, messages) do
    IO.puts("Logging new message: #{msg}")
    {:ok, [msg | messages]}
  end
end

defmodule PersistenceHandler do
  use GenEvent

  def handle_event({:msg, msg}, state) do
    IO.puts("Persisting log message: #{msg}")

    # Save message

    {:ok, state}
  end
end
```

### Gọi các hàm xử lý

Ngoài `handle_event/2` ra, GenEvents đồng thời cũng hỗ trợ hàm `handle_call/2`. Với hàm `handle_call/2` chúng ta có thể xử lý các thông điệp đồng bộ được chỉ định bên trong hàm xử lý đó.

Hãy cập nhật `LoggerHandler` để thêm vào hàm dùng để nhận log của thông điệp hiện tại:

```elixir
defmodule LoggerHandler do
  use GenEvent

  def handle_event({:msg, msg}, messages) do
    IO.puts("Logging new message: #{msg}")
    {:ok, [msg | messages]}
  end

  def handle_call(:messages, messages) do
    {:ok, Enum.reverse(messages), messages}
  end
end
```

### Sử dụng GenEvents

Với các hàm xử lý vừa làm, chúng ta cần làm quen thêm với một vài hàm mà GenEvent có sẵn. Ba hàm quan trọng nhất là: `add_handler/3`, `notify/2` và `call/4`. Những hàm đó cho phép chúng ta thêm vào các hàm xử lý, phát tán (broadcast) một thông điệp, và gọi một hàm xử lý nhất định nào đó.

Nếu chúng ta gộp tất cả lại thì sẽ nhìn thấy các hàm xử lý trên thực tế như dưới đây:

```elixir
iex> {:ok, pid} = GenEvent.start_link([])
iex> GenEvent.add_handler(pid, LoggerHandler, [])
iex> GenEvent.add_handler(pid, PersistenceHandler, [])

iex> GenEvent.notify(pid, {:msg, "Hello World"})
Logging new message: Hello World
Persisting log message: Hello World

iex> GenEvent.call(pid, LoggerHandler, :messages)
["Hello World"]
```

Bạn có thể xem tài liệu chính thức tại [GenEvent](https://hexdocs.pm/elixir/GenEvent.html#content) để xem danh mục tất cả các callback và các hàm mà GenEvent hỗ trợ.
