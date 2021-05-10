%{
  version: "0.9.1",
  title: "Erlang Interoperability",
  excerpt: """
  Một trong những lợi ích của việc xây dựng dựa trên Erlang VM (BEAM) chính là việc có rất nhiều những thư viện mà chúng ta có thể sử dụng. Tính tương tác này giúp chúng ta có thể tận dụng những thư viện đó cũng như thư viện chuẩn của Erlang từ Elixir code. Trong bài này chúng ta sẽ xem làm thế nào để sử dụng được những tính năng bên trong thư viện chuẩn cũng như thư viện của bên thứ ba từ Erlang.
  """
}
---

## Thư viện chuẩn
Chúng ta có thể sử dụng một cách rộng rãi các thư viện chuẩn của Erlang ở bên trong ứng dụng Elixir. Module Erlang được biểu diễn bằng các atom không viết hoa (lowercase) như là `:os` hay là `:timer`.

Hãy thử sử dụng `:timer.tc` để đo thời gian chạy của một hàm:

```elixir
defmodule Example do
  def timed(fun, args) do
    {time, result} = :timer.tc(fun, args)
    IO.puts("Time: #{time} μs")
    IO.puts("Result: #{result}")
  end
end

iex> Example.timed(fn (n) -> (n * n) * n end, [100])
Time: 8 μs
Result: 1000000
```

Để xem những module nào có thể sử dụng được, hãy xem [Hướng dẫn tham khảo Erlang](http://erlang.org/doc/apps/stdlib/).

## Gói thư viện Erlang

Ở bài trước chúng ta đã học về Mix và quản lý thư viện phụ thuộc. Thêm thư viện Erlang vào cũng tương tự như vậy. Trong trường hợp mà thư viện Erlang không nằm trên [Hex](https://hex.pm) bạn có thể tham khảo về cách sử dụng git repository như dưới đây:

```elixir
def deps do
  [{:png, github: "yuce/png"}]
end
```

Sau đó chúng ta có thể truy cập vào thư viện Erlang:

```elixir
png =
  :png.create(%{:size => {30, 30}, :mode => {:indexed, 8}, :file => file, :palette => palette})
```

## Những khác biệt đáng chú ý

Khi chúng ta đã biết cách sử dụng Erlang, chúng ta cũng nên xem cả những điểm chốt đi cùng với việc tương tác với Erlang.

### Atoms

Atoms của Erlang vẻ ngoài nhìn giống như bản sao bên Elixir khi không có dấu hai chấm (`:`). Chúng được biểu diễn bởi chuỗi kí tự không viết hoa và dấu gạch dưới:

Elixir:

```elixir
:example
```

Erlang:

```erlang
example.
```

### Chuỗi kí tự

Ở Elixir khi chúng ta nói về chuỗi kí tự chúng ta nói về chuỗi binary được mã hoá dưới dạng UTF-8. Với Erlang, chuỗi kí tự vẫn được biểu diễn bởi dấu ngoặc kép, nhưng thực tế lại được chỉ đến một chuỗi các kí tự đơn (char list):

Elixir:

```elixir
iex> is_list('Example')
true
iex> is_list("Example")
false
iex> is_binary("Example")
true
iex> <<"Example">> === "Example"
true
```

Erlang:

```erlang
1> is_list('Example').
false
2> is_list("Example").
true
3> is_binary("Example").
false
4> is_binary(<<"Example">>).
true
```

Nên chú ý rằng rất nhiều thư viện Erlang cũ không hỗ trợ chuỗi binary, với trường hợp đó chúng ta cần chuyển đổi chuỗi kí tự Elixir sang các chuỗi kí tự đơn. May mắn là việc đó có thể làm khá dễ dàng với hàm `to_charlist/1`:

```elixir
iex> :string.words("Hello World")
** (FunctionClauseError) no function clause matching in :string.strip_left/2

    The following arguments were given to :string.strip_left/2:

        # 1
        "Hello World"

        # 2
        32

    (stdlib) string.erl:1661: :string.strip_left/2
    (stdlib) string.erl:1659: :string.strip/3
    (stdlib) string.erl:1597: :string.words/2

iex> "Hello World" |> to_charlist |> :string.words
2
```

### Biến

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

Đơn giản vậy đó! Tận dụng Erlang từ bên trong ứng dụng Elixir vô cùng dễ dàng và qua đó nhân đôi số lượng thư viện mà chúng ta có thể sử dụng được.
