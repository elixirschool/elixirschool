%{
  version: "0.9.1",
  title: "Poolboy",
  excerpt: """
  Bạn có thể dễ dàng hao tổn hết tài nguyên của hệ thống nếu bạn cho phép các tiến trình đồng thời (concurrent process) chạy một cách tùy ý. Poolboy giúp chúng ta tránh việc hao tổn quá mức đó bằng cách tạo ra một tập worker (worker pool) để giới hạn các tiến trình đồng thời.
  """
}
---

## Vì sao dùng Poolboy?

Chúng ta hãy bàn về một ví dụ cụ thể. Bạn được giao nhiệm vụ phải thiết kế một ứng dụng để lưu thông tin tài khoản người dùng vào database. Nếu với mỗi lần user đăng ký bạn đều tạo một tiến trình, bạn sẽ không thể điều khiển được số lượng kết nối. Ở một thời điểm nào đó, những kết nối trên bắt đầu giành nhau những tài nguyên có hạn sẵn dùng trên database server. Chẳng mấy chốc thì ứng dụng của bạn bị timeout vì những overhead gây ra bởi việc tranh giành đó.

Giải pháp cho vấn đề trên là dùng một tập worker (tiến trình) để giới hạn số lượng kết nối thay vì tạo ra một tiến trình cho mỗi lần user đăng ký. Như vậy bạn sẽ dễ dàng tránh được việc hao tổn tài nguyên hệ thống.

Đó là lý do Poolboy tồn tại. Nó tạo một một tập các worker được quản lý bởi một `Supervisor` (và cái hay là bạn không cần phải tự tay làm nó). Có rất nhiều thư viên sử dụng Poolboy ở bên dưới nó như tập kết nối `postgrex` *(cái mà Ecto dùng để làm việc PostgreSQL)* và `redis_poolex` *(tập kết nối cho Redis)* là một trong những thư viện điển hình dùng Poolboy.

## Cài đặt

Cài đặt là việc quá dễ với mix. Đơn giản là thêm Poolboy làm thư viện trong file `mix.exs`.

Trước hết ta hãy tạo một ứng dụng:

```bash
$ mix new poolboy_app --sup
$ mix deps.get
```

Thêm Poolboy vào thư viện trong file `mix.exs`.

```elixir
defp deps do
  [{:poolboy, "~> 1.5.1"}]
end
```

Thêm Poolboy vào ứng dụng OTP:

```elixir
def application do
  [applications: [:logger, :poolboy]]
end
```

## Các tùy chọn cài đặt

Chúng ta chỉ cần biết chút ít về các tùy chọn cài đặt để bắt đầu làm việc với Poolboy.

* `:name` - tên của tập. Phạm vi (scope) có thể là `:local`, `:global` hoặc `:via`.
* `:worker_module` - tên module của worker.
* `:size` - kích thước tối đa của tập.
* `:max_overflow` - số worker tối đa sẽ được tạo khi tập không còn worker sẵn dùng. (không bắt buộc)
* `:strategy` - `:lifo` hoặc `:fifo`, định nghĩa việc các worker mới đăng ký sẽ được đặt trước hay đặt sau các worker có sẵn. Mặc định là `:lifo`. (không bắt buộc)

## Cấu hình Poolboy

Trong ví dụ này ta sẽ tạo ra một tập worker để xử lý các yêu cầu tính căn của một số. Ta sẽ dùng ví dụ đơn giản để tập trung vào Poolboy.

Ta hãy định nghĩa các tùy chọn cấu hình Poolboy và thêm nó là một worker con khi ứng dụng chạy.

```elixir
defmodule PoolboyApp do
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
    import Supervisor.Spec, warn: false

    children = [
      :poolboy.child_spec(:worker, poolboy_config, [])
    ]

    opts = [strategy: :one_for_one, name: PoolboyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Thứ đầu tiên ta định nghĩa là tùy chọn cấu hình cho tập. Ta gán vào `:name` tên duy nhất của tập, cấu hình phạm vi `:scope` thành local và kích thước `:size` của tập là năm worker. Và trong trường hợp mọi worker đều đang bận, ta bảo nó tạo thêm hai worker khác để giúp đỡ bằng cách sử dụng tùy chọn `:max_overflow`. *(các worker `overflow` sẽ được xóa sau khi nó xong việc.)*

Sau đó ta thêm hàm `pollboy.child_spec/3` vào mảng các con để tập worker có thể chạy khi ứng dụng chạy.

Hàm `child_spec/3` nhận ba tham số: Tên của tập, cấu hình của tập và tham số thứ ba là cái sẽ được truyền vào hàm `worker.start_link`. Trong trường hợp của chúng ta là một mảng rỗng.

## Tạo worker
Worker module sẽ là một GenServer đơn giản tính căn của một số, sleep một giây và sau đó in ra số pid của worker.

```elixir
defmodule Worker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_call({:square_root, x}, _from, state) do
    IO.puts("process #{inspect(self)} calculating square root of #{x}")
    Process.sleep(1000)
    {:reply, :math.sqrt(x), state}
  end
end
```

## Dùng Poolboy

Sau khi có `Worker`, ta có thể chạy thử Poolboy. Ta hãy tạo ra một module đơn giản để tạo ra các tiến trình đồng thời dùng hàm `:poolboy.transaction`:

```elixir
defmodule Test do
  @timeout 60000

  def start do
    tasks =
      Enum.map(1..20, fn i ->
        Task.async(fn ->
          :poolboy.transaction(:worker, &GenServer.call(&1, {:square_root, i}), @timeout)
        end)
      end)

    Enum.each(tasks, fn task -> IO.puts(Task.await(task, @timeout)) end)
  end
end
```

Nếu bạn không có các worker sẵn dùng trong tập, Poolboy sẽ timeout một thời gian mặc định (năm giây) và không nhận thêm yêu cầu mới nào cả. Ở ví dụ của chúng ta, việc ta tăng thời gian timeout lên một phút chỉ là để mô phỏng cách ta thay đổi giá trị mặc định của nó như thế nào.

Ngay cả khi ta cố ý tạo ra nhiều tiến trình *(như ở trên có tổng cộng hai mươi cái)*, hàm `:poolboy.transaction` sẽ giới hạn số tiến trình được tạo ra là năm *(cộng thêm hai overflow worker nếu cần thiết)* như ta đã định nghĩa trong cấu hình. Tất cả yêu cầu sẽ được xử lý bởi tập worker thay vì tạo ra một tiến trình mới cho mỗi một yêu cầu.
