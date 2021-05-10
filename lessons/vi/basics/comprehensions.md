%{
  version: "0.9.0",
  title: "Comprehensions",
  excerpt: """
  List comprehension là một cú pháp hỗ trợ việc lặp qua các phần tử trong Elixir. Trong bài này, chúng ta sẽ cùng xem cách sử dụng comprehension cho iteration và generation.
  """
}
---

## Cơ bản

Comprehension thường được dùng để cung cấp các lời gọi ngắn gọn cho `Enum` và `Stream`. Hãy cùng bắt đầu với việc xem cách sử dụng comprehension đơn giản, rồi sau đó sẽ chia nhỏ nó:


```elixir
iex> list = [1, 2, 3, 4, 5]
iex> for x <- list, do: x*x
[1, 4, 9, 16, 25]
```

Điều đầu tiên chúng ta chú ý đó là việc sử dụng `for` và một generator. Generator là gì? Generator là biểu thức `x <- [1, 2, 3, 4]` được sử dụng trong list comprehension. Chúng chịu trách nhiệm cho việc sinh ra giá trị tiếp theo.

May mắn cho chúng ta, comprehension không chỉ bị giới hạn trong các list, thực tế chúng có thể làm việc với bất cứ kiểu enumerable nào:

```elixir
# Keyword Lists
iex> for {_key, val} <- [one: 1, two: 2, three: 3], do: val
[1, 2, 3]

# Maps
iex> for {k, v} <- %{"a" => "A", "b" => "B"}, do: {k, v}
[{"a", "A"}, {"b", "B"}]

# Binaries
iex> for <<c <- "hello">>, do: <<c>>
["h", "e", "l", "l", "o"]
```

Giống như rất nhiều thứ khác trong Elixir, generator dựa vào pattern matching để so sánh giá trị input với các biến bên trái. Nếu chúng không thể so trùng với nhau, các giá trị sẽ bị bỏ qua:

```elixir
iex> for {:ok, val} <- [ok: "Hello", error: "Unknown", ok: "World"], do: val
["Hello", "World"]
```

Chúng ta có thể sử dụng nhiều generator, cũng như sử dụng các vòng lặp lồng nhau:

```elixir
iex> list = [1, 2, 3, 4]
iex> for n <- list, times <- 1..n do
...>   String.duplicate("*", times)
...> end
["*", "*", "**", "*", "**", "***", "*", "**", "***", "****"]
```

Để mô tả chi tiết hơn cách vòng lặp thực hiện, hãy cùng sử dung `IO.puts` để hiện thị 2 giá trị được sinh ra:

```elixir
iex> for n <- list, times <- 1..n, do: IO.puts "#{n} - #{times}"
1 - 1
2 - 1
2 - 2
3 - 1
3 - 2
3 - 3
4 - 1
4 - 2
4 - 3
4 - 4
```

List comprehension là một cú pháp hỗ trợ, và nên được sử dụng chỉ khi cần thiết.

## Các bộ lọc

Bạn có thể nghĩ các bộ lọc như là các bảo vệ cho comprehension. Khi một giá trị lọc trả về `false` hoặc `nil` nó sẽ bị loại bỏ khỏi list kết quả. Hãy cùng lặp qua một khoảng, và trả về các số chẵn. Chúng ta sẽ sử dụng hàm `is_even/1` từ module Integer để kiểm tra xem một số là chẵn hay lẻ.


```elixir
import Integer
iex> for x <- 1..10, is_even(x), do: x
[2, 4, 6, 8, 10]
```

Giống như các generator, chúng ta có thể sử dụng các bộ lọc nhiều lần. Hãy cùng mở rộng khoảng của chúng ta, và chỉ lấy các số vừa chẵn và vừa chia hết cho 3.

```elixir
import Integer
iex> for x <- 1..100,
...>   is_even(x),
...>   rem(x, 3) == 0, do: x
[6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 78, 84, 90, 96]
```

## Sử dụng :into

Nếu muốn cung cấp các kết quả khác thay vì chỉ một list, chúng ta sẽ sử dụng lựa chọn `:into` để làm điều đó. `:into` chấp nhận bất cứ cấu trúc nào cài đặt protocol `Collectable`.

Sử dụng `:into`, chúng ta sẽ tạo nên một map từ một keyword list:


```elixir
iex> for {k, v} <- [one: 1, two: 2, three: 3], into: %{}, do: {k, v}
%{one: 1, three: 3, two: 2}
```

Từ việc bitstring cũng là enumerable, chúng ta có thể sử dụng list comprehension và `:into` để tạo nên các xâu:

```elixir
iex> for c <- [72, 101, 108, 108, 111], into: "", do: <<c>>
"Hello"
```

Vậy là hết chương rồi. List comprehension là một cách đơn giản để duyệt qua các bộ theo một cách ngắn gọn.
