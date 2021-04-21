---
version: 1.0.1
title: Pipe Operator
---

Pipe `|>` lấy kết quả của một biểu thức làm tham số đầu tiên cho một biểu thức khác.

{% include toc.html %}

## Giới thiệu

Việc lập trình có thể trở nên rối tung, rối đến nỗi mà việc gọi function trở nên lồng ghép và khó đọc hiểu. Ta hãy xem qua ví dụ gọi nhiều function dưới đây:

```elixir
foo(bar(baz(new_function(other_function()))))
```

Ở đây, ta đang truyền kết quả của `other_function/0` vào `new_function/1`, rồi lấy kết quả của `new_function/1` cho vào `baz/1`, `baz/1` vào `bar/1` và cuối cùng là `bar/1` vào `foo/1`. Trong Elixir có cách giải quyết sự rắc rối này bằng cách sử dụng pipe. Pipe (`|>`) *nhận kết quả của một biểu thức, và truyền nó đi*. Hãy xem đoạn code ở trên sau khi được viết lại bằng pipe.

```elixir
other_function() |> new_function() |> baz() |> bar() |> foo()
```

Pipe nhận kết quả bên trái, và truyền nó qua bên phải.

## Ví dụ

Với những ví dụ dưới đây ta sẽ dùng String module của Elixir.

- Tách chuỗi

```elixir
iex> "Elixir rocks" |> String.split()
["Elixir", "rocks"]
```

- Viết hoa kết hợp tách chuỗi

```elixir
iex> "Elixir rocks" |> String.upcase() |> String.split()
["ELIXIR", "ROCKS"]
```

- Kiểm tra mẫu kết thúc

```elixir
iex> "elixir" |> String.ends_with?("ixir")
true
```

## Best Practices

Khi function nhận hơn 1 đầu vào, hãy dùng cú pháp gọi function với
dấu đóng mở ngoặc `()`. Việc này giúp các lập trình viên khác
không hiểu nhầm code của bạn.  Xem ví dụ thứ 3, nếu bỏ đi dấu
ngoặc của `String.ends_with?/2`, sẽ thấy cảnh báo sau.

```shell
iex> "elixir" |> String.ends_with? "ixir"
warning: parentheses are required when piping into a function call. For example:

  foo 1 |> bar 2 |> baz 3

is ambiguous and should be written as

  foo(1) |> bar(2) |> baz(3)

true
```
