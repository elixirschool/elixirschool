%{
  version: "1.0.1",
  title: "Behaviours",
  excerpt: """
  Chúng ta đã học về Typespecs trong bài học trước, trong bài này, chúng ta sẽ học về cách để yêu cầu một module cài đặt những tiêu chuẩn đó. Trong Elixir, tính năng này thường được gọi bằng Behaviours.
  """
}
---

## Sử dụng

Đôi khi, bạn muốn các module cùng chia sẻ một public API, giải pháp cho vấn đề này trong Elixir là behaviours. Behaviours thực thi hai vai trò chính:

+ Định nghĩa một tập các hàm bắt buộc phải cài đặt
+ Kiểm tra xem tập đó có được cài đặt hay không

Elixir đã bao gồm một tập các behaviours ví dụ như GenServer, nhưng trong bài học này, chúng ta sẽ tập trung vào việc tạo ra các Behaviour cho riêng chúng ta.

## Định nghĩa một behaviour

Để hiểu rõ về behaviour hơn, hãy cùng cài đặt một worker module. Những worker này được kỳ vọng sẽ cài đặt 2 hàm `init/1` và `perform/2`.

Để đạt được điều đó, chúng ta sẽ sử dụng `@callback` với cú pháp tương tự như `@spec`, để định nghĩa các hàm bắt buộc (__required__ method), đối với macro, chúng ta có thể sử dụng `@macrocallback`. Hãy cùng xác định `init/1` và `perform/2` cho các worker của chúng ta:

```elixir
defmodule Example.Worker do
  @callback init(state :: term) :: {:ok, new_state :: term} | {:error, reason :: term}
  @callback perform(args :: term, state :: term) ::
              {:ok, result :: term, new_state :: term}
              | {:error, reason :: term, new_state :: term}
end
```

Ở đây chúng ta định nghĩa `init/1` chấp nhận bất cứ giá trị nào, và trả về một tuple hoặc là `{:ok, state}` hoặc là `{:error, reason}`, đây là tiêu chuẩn cho việc khởi tạo. Hàm `perform/2` sẽ nhận vào một vài tham số cho worker cùng với trạng thái mà chúng ta đã khởi tạo, chúng ta kỳ vọng rằng `perform/2` sẽ trả về `{:ok, result, state}` hoặc là `{:error, reason, state}` giống như GenServer.

## Sử dụng behaviours

Giờ đây chúng ta đã định nghĩa behaviour, chúng ta có thể sử dụng nó để tạo ra một số module mà tất cả chia sẻ cùng một public API. Thêm một behaviour vào module khá là dễ với thuộc tính `@behaviour`.

Sử dụng behaviour mới, chúng ta sẽ tạo ra một module để tải một file, sau đó lưu nó lại:

```elixir
defmodule Example.Downloader do
  @behaviour Example.Worker

  def init(opts), do: {:ok, opts}

  def perform(url, opts) do
    url
    |> HTTPoison.get!()
    |> Map.fetch(:body)
    |> write_file(opts[:path])
    |> respond(opts)
  end

  defp write_file(:error, _), do: {:error, :missing_body}

  defp write_file({:ok, contents}, path) do
    path
    |> Path.expand()
    |> File.write(contents)
  end

  defp respond(:ok, opts), do: {:ok, opts[:path], opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

Vậy còn một worker để nén một mảng các file thì sao? Chúng ta cũng có thể làm như sau:

```elixir
defmodule Example.Compressor do
  @behaviour Example.Worker

  def init(opts), do: {:ok, opts}

  def perform(payload, opts) do
    payload
    |> compress
    |> respond(opts)
  end

  defp compress({name, files}), do: :zip.create(name, files)

  defp respond({:ok, path}, opts), do: {:ok, path, opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

Trong khi các công việc được thực hiện là khác nhau, nhưng public API thì không, và bất cứ đoạn code nào sử dụng các module này, để có thể tương tác với những module đó và biết rằng chúng sẽ nhận được kết quả trả về như mong muốn. Điều này cho phép chúng ta khả năng tạo ra rất nhiều loại worker, thực hiện những nhiệm vụ khác nhau, nhưng cùng sử dụng chúng một public API.

Nếu chúng ta muốn thêm vào một behaviour, nhưng lại không cài đặt đủ tất cả các hàm cần thết, một cảnh báo sẽ được văng ra lúc biên dịch. Hãy cùng thay đổi `Example.Compressor` bằng cách bỏ đi hàm `init/1`:

```elixir
defmodule Example.Compressor do
  @behaviour Example.Worker

  def perform(payload, opts) do
    payload
    |> compress
    |> respond(opts)
  end

  defp compress({name, files}), do: :zip.create(name, files)

  defp respond({:ok, path}, opts), do: {:ok, path, opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

Giờ đây khi biên dịch đoạn code trên, chúng ta có thể thấy cảnh báo:

```shell
lib/example/compressor.ex:1: warning: undefined behaviour function init/1 (for behaviour Example.Worker)
Compiled lib/example/compressor.ex
```

Vậy là hết rồi. Giờ chúng ta đã sẵn sàng để tạo mới và chia sẻ behaviour với các module khác.
