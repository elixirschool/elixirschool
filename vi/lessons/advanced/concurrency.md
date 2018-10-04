---
version: 0.9.1
title: Xử lý đồng thời
---

Một trong những điểm nổi bật của Elixir đó là việc hỗ trợ xử lý đồng thời. Nhờ có máy ảo Erlang (BEAM), việc xử lý đồng thời trong Elixir dễ hơn rất nhiều so với mong đợi. Mô hình xử lý đồng thời dựa và Actor, một process có thể tương tác với các process khác thông qua việc truyền thông điệp.

Trong bài học này, chúng ta xem cách các module xử lý đồng thời làm việc trong Elixir. Trong chương kế tiếp chúng ta sẽ học về OTP, và cách cài đặt chúng.


{% include toc.html %}

## Processes

Process trong máy ảo Erlang là nhẹ (nhẹ ở đây hiểu theo nghĩa nó là process được cài đặt ở không gian của người dùng, thay vì không gian của nhân hệ điều hành) và chạy trên tất cả các CPU. Trong khi chúng có vẻ như là các native thread, chúng đơn giản hơn nhiều, và khá là bình thường nếu một ứng dụng Elixir có hàng ngàn process chạy cùng nhau.

Cách dễ nhất để tạo mới một process đó là `spawn`, hàm này sẽ nhận vào một hàm anonymous hoặc là một hàm có tên. Khi chúng ta tạo mới một process, nó sẽ trả về một _Process Identifier_, hoặc là PID, giá trị này là duy nhất trong ứng dụng của chúng ta.

Để bắt đầu, chúng ta sẽ tạo ra một module, và định nghĩa một hàm chúng ta muốn chạy:

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

Để chạy hàm này một cách bất đồng bộ, chúng ta sử dung `spawn/3`:

```elixir
iex> spawn(Example, :add, [2, 3])
5
#PID<0.80.0>
```

### Truyền thông điệp

Để tương tác với nhau, các process dựa vào cơ chế truyền thông điệp. Có hai thành phần chính để làm chuyện này: `send/2` và `receive`. Hàm `send/2` cho phép chúng ta truyền một thông điệp tới PID. Để lắng nghe, chúng ta sử dụng `receive` và so trùng thông điệp. Nếu không có thông điệp vào được so trùng, việc hoạt động của process vẫn được tiến hành mà không bị ngưng lại.

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

Bạn có thể chú ý rằng hàm `listen/0` là đệ quy, điều này cho phép process của chúng ta có thể xử lý nhiều thông điệp. Nếu không có đệ quy, process sẽ bị thoát ra sau khi xử lý thông điệp đầu tiên.

### Liên kết các process

Một vấn đề của `spawn` đó là cần phải biết khi một process bị crash. Để làm điều này, chúng ta sẽ cần liên kết các process lại với nhau bằng hàm `spawn_link`. Hai process được liên kết với nhau sẽ nhận được thông báo khi process kia bị thoát:

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)
end

iex> spawn(Example, :explode, [])
#PID<0.66.0>

iex> spawn_link(Example, :explode, [])
** (EXIT from #PID<0.57.0>) evaluator process exited with reason: :kaboom
```

Đôi khi, chúng ta không muốn process được liên kết làm cho process hiện tại bị crash. Vì thế chúng ta cần đánh bẫy sự thoát ra của process kia. Khi đánh bẫy sự thoát ra, chúng ta sẽ nhận được một thông điệp dạng tuple như sau: `{:EXIT, from_pid, reason}`.

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

### Giám sát process

Vậy nếu chúng ta không muốn liên kết hai process, nhưng vẫn muốn được thông báo? Trong trường hợp này, chúng ta có thể giám sát process bằng hàm `spawn_monitor`. Khi chúng ta giám sát một process, chúng ta sẽ nhận được một thông điệp nếu process bị crash mà không làm process hiện tại bị crash hoặc là cần phải đánh bẫy thoát một cách minh bạch.

Khi giám sát một process, nếu process đó bị crash, process hiện tại sẽ nhận được một thông điệp dạng `{:DOWN, ref, :process, from_pid, reason}`.

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

Agents là một mức trừu tượng hoá lên các process nền để lưu giữ trạng thái. Chúng ta có thể truy cập chúng từ các process khác trong ứng dụng và các node. Trạng thái của một Agent được gán bằng giá trị trả về của hàm:

```elixir
iex> {:ok, agent} = Agent.start_link(fn -> [1, 2, 3] end)
{:ok, #PID<0.65.0>}

iex> Agent.update(agent, fn (state) -> state ++ [4, 5] end)
:ok

iex> Agent.get(agent, &(&1))
[1, 2, 3, 4, 5]
```

Khi chúng ta đặt tên một Agent, chúng ta có thể trỏ tới nó bằng tên thay vì PID:

```elixir
iex> Agent.start_link(fn -> [1, 2, 3] end, name: Numbers)
{:ok, #PID<0.74.0>}

iex> Agent.get(Numbers, &(&1))
[1, 2, 3]
```

## Tasks

Tasks cung cấp một cách để chạy một hàm dưới nền, và lấy ra giá trị trả về lúc sau. Chúng có thể cực kỳ hữu dụng khi muốn xử lý các hoạt động tốn chi phí mà không làm chậm lại ứng dụng.


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
