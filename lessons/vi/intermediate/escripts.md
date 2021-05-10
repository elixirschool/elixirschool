%{
  version: "0.9.1",
  title: "File thực thi",
  excerpt: """
  Để tạo các file thực thi trong Elixir chúng ta sẽ sử dụng escript. Escript tạo một thực thi mà có thể chạy trên bất kỳ hệ thống nào với Erlang được cài đặt.
  """
}
---

## Bắt đầu

Để tạo một file thực thi với escript có một vài điều chúng ta cần làm: cài đặt hàm `main/1` và cập nhật Mixfile của chúng ta.

Chúng ta sẽ bắt đầu bằng cách tạo một module để phục vụ như là một điểm khởi đầu để thực thi. Đây là nơi chúng ta sẽ thực hiện `main/1`:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    # Do stuff
  end
end
```

Tiếp theo chúng ta cần cập nhật Mixfile để chèn vào tùy chọn `:escript` cho dự án của của chúng ta cùng với quy định cụ thể `:main_module`:

```elixir
defmodule ExampleApp.Mixfile do
  def project do
    [app: :example_app, version: "0.0.1", escript: escript()]
  end

  defp escript do
    [main_module: ExampleApp.CLI]
  end
end
```

## Phân tích đối số (Parsing args)

Với việc ứng dụng đã được cấu hình (with our application set up), chúng ta có thể chuyển sang phân tích các đối số trên command line. Để làm điều này chúng ta sẽ sử dụng `OptionParser.parse/2` của Elixir với tùy chọn `:switches` để chỉ ra cờ của chúng ta là luận lý: 

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    args
    |> parse_args
    |> response
    |> IO.puts()
  end

  defp parse_args(args) do
    {opts, word, _} =
      args
      |> OptionParser.parse(switches: [upcase: :boolean])

    {opts, List.to_string(word)}
  end

  defp response({opts, word}) do
    if opts[:upcase], do: String.upcase(word), else: word
  end
end
```

## Xây dựng

Một khi chúng ta đã hoàn tất việc cấu hình ứng dụng để sử dụng escript, xây dựng file thực thi khá là đơn giản với Mix:

```elixir
$ mix escript.build
```

Giờ hãy cùng thử xem kết quả ra sao:

```elixir
$ ./example_app --upcase Hello
HELLO

$ ./example_app Hi
Hi
```

Chính là như vậy. Chúng ta đã xây dựng file thực thi đầu tiên trong Elixir sử dụng escript.
