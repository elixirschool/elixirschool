---
layout: page
title: Executables
category: advanced
order: 3
lang: vi
---

Để xây dựng thực thi trong Elixir chúng ta sẽ sử dụng escript. Escript tạo một thực thi mà có thể chạy trên bất kỳ hệ thống nào với Erlang được cài đặt. 

{% include toc.html %}

## Bắt đầu

Để tạo một thực thi với escript có một vài điều chúng ta cần làm: thực thiện một hàm `main/1` và cập nhật Mixfile của chúng ta.

Chúng ta sẽ bắt đầu bằng cách tạo một module để phục vụ như là một điểm mấu chốt để thực thi. Đây là nơi chúng ta sẽ thực hiện `main/1`:

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
    [app: :example_app,
     version: "0.0.1",
     escript: escript]
  end

  def escript do
    [main_module: ExampleApp.CLI]
  end
end
```

## Phân tích đối số (Parsing args)

Cùng với cài đặt chương trình, chúng ta có thể chuyển sang phân tích các đối số trên command line. Để làm điều này chúng ta sẽ sử dụng `OptionParser.parse/2` của Elixir với tùy chọn `:switches` để chỉ ra cờ của chúng ta là luận lý: 

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    args
    |> parse_args
    |> response
    |> IO.puts
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

Một khi chúng ta đã hoàn tất việc cấu hình chương trình để sử dụng escript, xây dựng thực thi là một sự lướt qua với Mix:

```elixir
$ mix escript.build
```

Hãy giữ nó cho một sự xoay tròn:

```elixir
$ ./example_app --upcase Hello
HELLO

$ ./example_app Hi
Hi
```

Chính là như vậy. Chúng ta đã xây dựng thực thi đầu tiên trong Elixir sử dụng escript.
