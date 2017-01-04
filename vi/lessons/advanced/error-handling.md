---
layout: page
title: Xử Lý Lỗi
category: advanced
order: 2
lang: vi
---

Mặc dù có nhiều ảnh hưởng để trả về tuple `{:error, reason}`, Elixir hỗ trợ nhiều ngoại lệ và trong bài học này chúng ta sẽ xem làm thế nào để xử lý lỗi và các cơ chế khác nhau có sẵn cho chúng ta.

Nói chung quy ước trong Elixir là tạo ra một hàm (`example/1`) mà trả về `{:ok, result}` và `{:error, reason}` và một hàm riêng biệt (`example!/1`) trả về `result` hoặc đưa ra một lỗi.

Trong bài học này sẽ tập trung tương tác với sau cùng.

{% include toc.html %}

## Xử Lý Lỗi

Trước khi chúng ta có thể xử lý lỗi chúng ta cần phải tạo ra chúng và cách đơn giản nhất để làm như vậy là với `raise/1`: 

```elixir
iex> raise "Oh no!"
** (RuntimeError) Oh no!
```

Nếu chúng ta muốn xác định loại và thông điệp, chúng ta cần sử dụng `raise/2`:

```elixir
iex> raise ArgumentError, message: "the argument value is invalid"
** (ArgumentError) the argument value is invalid
```

Khi chúng ta biết một lỗi có thể xảy ra, chúng ta có thể xử lý chúng bằng cách sử dụng `try/rescue` và so trùng mẫu (pattern matching):

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> end
An error occurred: Oh no!
:ok
```

Nó có thể kết hợp nhiều lỗi trong một giải pháp duy nhất:

```elixir
try do
  opts
  |> Keyword.fetch!(:source_file)
  |> File.read!
rescue
  e in KeyError -> IO.puts "missing :source_file option"
  e in File.Error -> IO.puts "unable to read source file"
end
```

## After

Đôi khi nó có thể cần thiết để thực hiện một số hành động sau khi chúng ta `try/rescue` bất kể lỗi. Đối với điều này chúng ta có `try/after`. Nếu bạn đã quen thuộc với Ruby giống như là `begin/rescue/ensure` hoặc `try/catch/finally` trong Java:

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> after
...>   IO.puts "The end!"
...> end
An error occurred: Oh no!
The end!
:ok
```

Điều này thường được sử dụng nhiều với các tập tin (files) hoặc các kết nối cần phải được đóng:

```elixir
{:ok, file} = File.open "example.json"
try do
   # Do hazardous work
after
   File.close(file)
end
```

## Lỗi Mới

Trong khi Elixir bao gồm một số lỗi được xây dựng sẵn như `RuntimeError`, chúng ta có khả năng bảo trì cái mà được chúng ta tạo ra nếu chúng ta cần một cái gì đó cụ thể. Tạo một lỗi mới rất là dễ dàng với macro `defexception/1` mà thuận tiện nhận tùy chọn `:message` để thiết lập một thông báo lỗi mặc định:

```elixir
defmodule ExampleError do
  defexception message: "an example error has occurred"
end
```

Giờ hãy cùng thử xem lỗi mới của chúng ta ra sao:

```elixir
iex> try do
...>   raise ExampleError
...> rescue
...>   e in ExampleError -> e
...> end
%ExampleError{message: "an example error has occurred"}
```

## Throws

Một cơ chế khác để làm việc với các lỗi trong Elixir là `throw` và `catch`. Trong thực tế các lỗi xảy ra rất thường xuyên trong code Elixir mới hơn nhưng tuy nhiên điều quan trọng là phải biết và hiểu chúng.

Hàm `throw/1` cung cấp cho chúng ta khả năng để thoát khỏi thực thi với một giá trị cụ thể, chúng ta có thể sử dụng `catch`:

```elixir
iex> try do
...>   for x <- 0..10 do
...>     if x == 5, do: throw(x)
...>     IO.puts(x)
...>   end
...> catch
...>   x -> "Caught: #{x}"
...> end
0
1
2
3
4
"Caught: 5"
```

Như đã đề cập, `throw/catch` không phổ biến và điển hình tồn tại như stopgaps khi thư viện không cung cấp đủ APIs.

## Exiting

Cơ chế lỗi cuối cùng mà Elixir cung cấp cho chúng ta là `exit`. Dấu hiệu thoát khỏi xảy ra bất cứ khi nào một process chết và là một phần quan trọng lỗi của Elixir.

Để thoát khỏi một cách rõ ràng chúng ta có thể sử dụng `exit/1`:

```elixir
iex> spawn_link fn -> exit("oh no") end
** (EXIT from #PID<0.101.0>) "oh no"
```

Trong khi nó có thể bắt và thoát khỏi với `try/catch` làm như vậy là _cựckỳ_ hiếm. Trong hầu hết các trường hợp, nó có ích để cho supervisor xử lý thoát khỏi process:

```elixir
iex> try do
...>   exit "oh no!"
...> catch
...>   :exit, _ -> "exit blocked"
...> end
"exit blocked"
```
