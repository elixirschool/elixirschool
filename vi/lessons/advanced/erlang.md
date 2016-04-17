---
layout: page
title: Tương tác với Erlang
category: advanced
order: 1
lang: vi
---

Một trong những lợi ích có được khi xây dựng dựa trên ErlangVM là sự phong phú của các thư viện có sẵn. Khả năng tương tác với Erlang cho phép ta sử dụng những thư viện này cũng như thư viện chuẩn của Erlang khi viết code bằng Elixir. Ở bài này, chúng ta sẽ xem xét việc truy cập những tính năng của thư viện chuẩn cũng như thư viện bên thứ ba của Erlang.

## Mục lục

- [Thư viện chuẩn](#standard-library)
- [Erlang Packages](#erlang-packages)
- [Những điểm khác biệt cần lưu ý](#notable-differences)
  - [Atom](#atoms)
  - [String](#strings)
  - [Biến](#variables)


## Thư viện chuẩn

Thư viện chuẩn phong phú của Erlang có thể được truy cập từ bất kỳ đoạn code Elixir nào trong hệ thống. Module của Erlang được ký hiệu bởi atom trong chữ in thường như là `:os` và `:timer`.

Hãy thử dùng `:timer.tc` để tính thời gian chạy của một hàm đã cho:

```elixir
defmodule Example do
  def timed(fun, args) do
    {time, result} = :timer.tc(fun, args)
    IO.puts "Time: #{time}ms"
    IO.puts "Result: #{result}"
  end
end

iex> Example.timed(fn (n) -> (n * n) * n end, [100])
Time: 8ms
Result: 1000000
```

Để có một danh sách đầy đủ các module sẵn có, xem thêm [Erlang Reference Manual (Sổ tay tra cứu Erlang)](http://erlang.org/doc/apps/stdlib/).

## Erlang Packages (Thư viện bên thứ ba của Erlang)

Ở một bài trước, ta đã tìm hiểu về Mix và cách quản lý dependencies (thành phần phụ thuộc), bao gồm các thư viện Erlang cũng có cơ chế hoạt động như vậy. Trong trường hợp thư viện Erlang đó chưa có trên [Hex](https://hex.pm) bạn có thể trỏ tới git repo:

```elixir
def deps do
  [{:png, github: "yuce/png"}]
end
```

Và giờ ta có thể truy cập thư viện Erlang:

```elixir
png = :png.create(#{:size => {30, 30},
                    :mode => {:indexed, 8},
                    :file => file,
                    :palette => palette}),
```

## Những điểm khác biệt cần lưu ý

Sau khi đã biết cách sử dụng Erlang ta nên điểm lại những sai lầm dễ mắc phải khi tương tác với Erlang.

### Atom

Các atom trong Erlang trông giống như trong Elixir nhưng không có dấu hai chấm (`:`). Chúng được ký hiệu bởi string chữ thường và underscore (đường gạch dưới):

Elixir:

```elixir
:example
```

Erlang:

```erlang
example.
```

### String (Chuỗi)

Khi nói đến string trong Elixir ta nói đến binaries (chuỗi nhị phân) được mã hoá theo UTF-8. Với Erlang, string vẫn sử dụng double quotes (dấu phẩy kép ") nhưng lại là các char list (danh sách ký tự):

Elixir:

```elixir
iex> is_list('Example')
true
iex> is_binary("Example")
true
iex> <<"Example">> === "Example"
true
```

Erlang:

```erlang
1> is_list('Example').
false
1> is_list("Example").
true
1> is_binary("Example").
false
1> is_binary(<<"Example">>).
true
```

Điều cần phải chú ý ở đây là nhiều thư viện cũ của Erlang không hỗ trợ binaries (chuỗi nhị phân), vì vậy ta phải biến đổi string Elixir thành char list (danh sách ký tự):

```elixir
iex> :string.words("Hello World")
** (FunctionClauseError) no function clause matching in :string.strip_left/2
    (stdlib) string.erl:380: :string.strip_left("Hello World", 32)
    (stdlib) string.erl:378: :string.strip/3
    (stdlib) string.erl:316: :string.words/2

iex> "Hello World" |> to_char_list |> :string.words
2
```

### Variables

Elixir:

```elixir
iex> x = 10
10

iex> x1 = x + 10
20
```

Erlang:

```erlang
1> X = 10.
10

2> X1 = X + 1.
11
```

Vậy đó! Sử dụng Erlang từ hệ thống Elixir thật dễ dàng và nhân đôi số lượng thư viện ta có thể sử dụng.
