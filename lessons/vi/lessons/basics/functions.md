%{
  version: "0.9.1",
  title: "Hàm",
  excerpt: """
  Trong Elixir và nhiều ngôn ngữ lập trình hàm, hàm là "first class citizen". Chúng ta sẽ học về các kiểu hàm trong Elixir, chúng khác nhau như thế nào, và dùng chúng ra sao.
  """
}
---

## Hàm nặc danh (Anonymous function)

Cái tên nói lên tất cả, hàm nặc danh là một hàm không có tên. Như chúng ta đã thấy ở bài `Enum`, chúng thường xuyên được truyền vào các hàm khác. Để định nghĩa một hàm nặc danh trong Elixir chúng ta dùng từ khóa `fn` và `end`, với bất kì tham số nào và nội dung hàm được viết sau `->`.

Ta xem thử một ví dụ cơ bản:

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### Cách viết tắt dùng &

Hàm nặc danh được sử dụng thường xuyên đến nỗi Elixir có hẳn cách viết tắt cho nó:

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

Chắc bạn cũng đoán được, trong cách viết tắt ta có thể gọi các tham số bằng cách dùng `&1`, `&2`, `&3`, vv.

## Pattern Matching

Pattern matching không chỉ giới hạn cho biến trong Elixir, nó còn có thể dùng cho hàm như ví dụ trong phần này.

Elixir dùng pattern matching để xác định tập tham số trùng hợp đầu tiên và gọi nội dung hàm tương ứng:

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Đang xử lý lỗi..."
...>   {:error} -> IO.puts "Lỗi đã xảy ra!"
...> end

iex> some_result = 1
iex> handle_result.({:ok, some_result})
"Đang xử lý lỗi..."

iex> handle_result.({:error})
"Lỗi đã xảy ra!"
```

# Hàm được đặt tên (Named function)

Chúng ta có thể định nghĩa hàm với tên mà ta có thể gọi chúng sau, những hàm được đặt tên này được định nghĩa với từ khóa `def` trong module. Chúng ta sẽ học về Modules trong bài tiếp theo, ở đây ta chỉ tập trung vào hàm được đặt tên.

Hàm được định nghĩa trong một module có thể được dùng cho các module khác, đây là một phần cơ bản và được dùng rất nhiều trong Elixir.

```elixir
defmodule Greeter do
  def hello(name) do
    "Chào " <> name
  end
end

iex> Greeter.hello("Minh")
"Chào Minh"
```

Nếu hàm chỉ có một dòng, ta có thể viết ngắn bằng cách dùng `do:`:

```elixir
defmodule Greeter do
  def hello(name), do: "Chào " <> name
end
```

Với những kiến thức về pattern matching đã biết, chúng ta hãy khám phá cách viết đệ quy dùng hàm được đặt tên:

```elixir
defmodule Length do
  def of([]), do: 0
  def of([_ | tail]), do: 1 + of(tail)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### Việc đặt tên hàm và Arity

Chúng ta đã đề cập trước đó là hàm có thể được đặt tên bằng cách kết hợp tên của nó và arity (số lượng tham số). Điều đó có nghĩa bạn có thể làm như sau:

```elixir
defmodule Greeter2 do
  def hello(), do: "Hello, anonymous person!"   # hello/0
  def hello(name), do: "Hello, " <> name        # hello/1
  def hello(name1, name2), do: "Hello, #{name1} and #{name2}"
                                                # hello/2
end

iex> Greeter2.hello()
"Hello, anonymous person!"
iex> Greeter2.hello("Fred")
"Hello, Fred"
iex> Greeter2.hello("Fred", "Jane")
"Hello, Fred and Jane"
```

Chúng ta đã liệt kê tên của các hàm trong phần comment ở trên. Hàm đầu tiên không nhận tham số, nên nó được xem là `hello/0`, hàm thứ hai nhận một tham số nên nó là `hello/1`, vv. Không giống như việc overload hàm trong các ngôn ngữ khác, nó được xem là những hàm _khác nhau_. (Pattern matching, đã được đề cập ở bài trước, chỉ áp dụng khi các định nghĩa hàm có cùng tên lẫn số lượng tham số)

### Hàm Private (Private function)

Khi chúng ta không muốn những module khác truy cập vào một hàm chúng ta dùng hàm private, và nó chỉ có thể được gọi nội trong module đó. Ta có thể định nghĩa chúng trong Elixir với `defp`:

```elixir
defmodule Greeter do
  def hello(name), do: phrase <> name
  defp phrase, do: "Chào "
end

iex> Greeter.hello("Minh")
"Chào Minh"

iex> Greeter.phrase
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### Guards

Ta đã xem sơ qua guards trong bài [Cấu trúc điều khiển](../control-structures), giờ ta sẽ xem cách chúng ta áp dụng chúng cho hàm được đặt tên.  Một khi Elixir so trùng được một hàm các guard sẽ được kiểm tra.

Trong ví dụ tiếp theo ta có hai function với signature giống nhau, ta phải dựa vào guard để xác định cái nào sẽ được dùng dựa vào kiểu của tham số:

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase() <> name
  end

  defp phrase, do: "Chào "
end

iex> Greeter.hello ["Minh", "Phú"]
"Chào Minh, Phú"
```

### Tham số mặc định

Nếu chúng ta muốn có một giá trị mặc định cho tham số ta dùng cú pháp `tham số \\ giá trị`:

```elixir
defmodule Greeter do
  def hello(name, language_code \\ "vn") do
    phrase(language_code) <> name
  end

  defp phrase("vn"), do: "Chào, "
  defp phrase("en"), do: "Hello, "
end

iex> Greeter.hello("Minh", "en")
"Hello, Minh"

iex> Greeter.hello("Sean")
"Chào Minh"

iex> Greeter.hello("Sean", "vn")
"Chào Minh"
```

Khi chúng ta kết hợp ví dụ guard với tham số mặc định, ta sẽ gặp phải một vấn đề. Ta xem thử nó thế nào:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "vn") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code \\ "vn") when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("vn"), do: "Chào "
  defp phrase("en"), do: "Hello, "
end

** (CompileError) iex:31: definitions with multiple clauses and default values require a header. Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b) do ... end

one should write:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end

def hello/2 has multiple clauses and defines defaults in one or more clauses
    iex:31: (module)
```

Elixir không xử lý được trong trường hợp có nhiều hàm trùng khớp với tham số mặc định. Để xử lý điều này ta thêm một hàm trước tham số mặc định:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "vn")

  def hello(names, language_code) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code) when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("vn"), do: "Chào "
  defp phrase("en"), do: "Hello, "
end

iex> Greeter.hello ["Minh", "Phú"]
"Chào Minh, Phú"

iex> Greeter.hello ["Sean", "Steve"], "en"
"Hello, Sean, Steve"
```
