---
version: 0.9.1
title: Pipe Operator
---

Toán tử pipe `|>` truyền kết quả của một biểu thức như là tham số đầu tiên của một biểu thức khác.

{% include toc.html %}

## Giới thiệu

Việc lập trình có thể trở nên rối tung, rối đến nỗi mà việc gọi hàm trở nên lồng ghép và khó đọc hiểu. Ta hãy xem qua cách lồng ghép hàm dưới đây:

```elixir
foo(bar(baz(new_function(other_function()))))
```

Ở đây, ta đang truyền giá trị của `other_function/0` vào `new_function/1`, của `new_function/1` và `baz/1`, của `baz/1` vào `bar/1` và cuối cùng là `bar/1` vào `foo/1`. Trong Elixir có cách giải quyết hay cho cách viết rối tung (mà thực tế) này bằng cách sử dụng toán từ pipe. Toán tử pipe (`|>`) *nhận kết quả của một biểu thức, và truyền nó đi*. Ta hãy xem đoạn code ở trên sau khi được viết lại bằng toán tử pipe.

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

## Cách dùng thực tiễn

Nếu arity của một hàm lớn hơn 1 thì hãy ta nên dùng dấu ngoặc. Điều này không ảnh hướng đến Elixir, nhưng nó ảnh hưởng đến các lập trình viên khác và có thể khiến họ hiểu nhầm code của bạn. Nếu chúng ta xem ví dụ số 3, mà bỏ đi dấu ngoặc của `String.ends_with?/2`, chúng ta sẽ gặp phải câu cảnh báo sau.

```shell
iex> "elixir" |> String.ends_with? "ixir"
warning: parentheses are required when piping into a function call. For example:

  foo 1 |> bar 2 |> baz 3

is ambiguous and should be written as

  foo(1) |> bar(2) |> baz(3)

true
```
