%{
  version: "0.9.1",
  title: "Metaprogramming",
  excerpt: """
  Metaprogramming là quá trình sử dụng code để viết code. Trong Elixir, nó cung cấp cho chúng ta khả năng mở rộng ngôn ngữ để phù hợp với yêu cầu, và để thay đổi code một cách động. Chúng ta sẽ bắt đầu bằng việc xem cách mà Elixir được biểu diễn code, cũng như cách để thay đổi nó, và cuối cùng, chúng ta có thể sử dụng kiến thức này để mở rộng chính Elixir.

Cảnh báo: Metaprogramming khá là khó hiểu, và chỉ nên sử dụng khi cần thiết. Lạm dụng nó sẽ dẫn tới những đoạn code phức tạp, do đó rất khó để hiểu và để debug.
  """
}
---

## Quote

Bước đầu tiên của metaprogramming đó là hiểu cách mà các biểu thức được biểu diễn. Trong Elixir, cây cú pháp (AST), dạng biểu diễn nội tại cho code của chúng ta, được tạo bởi các tuple. Những tuple này chứa ba thành phần: tên hàm, metadata, và các tham số của hàm.

Để xem các cấu trúc nội tại này, Elixir cung cấp hàm `quote/2`. Sử dụng `quote/2`, chúng ta có thể chuyển code Elixir về dạng biểu diễn bên dưới của nó:

```elixir
iex> quote do: 42
42
iex> quote do: "Hello"
"Hello"
iex> quote do: :world
:world
iex> quote do: 1 + 2
{:+, [context: Elixir, import: Kernel], [1, 2]}
iex> quote do: if value, do: "True", else: "False"
{:if, [context: Elixir, import: Kernel],
 [{:value, [], Elixir}, [do: "True", else: "False"]]}
```

Bạn có để ý là 3 ví dụ đầu không trả về tuples? Có 5 literals sẽ trả về chính nó khi được quote:

```elixir
iex> :atom
:atom
iex> "string"
"string"
iex> 1 # All numbers
1
iex> [1, 2] # Lists
[1, 2]
iex> {"hello", :world} # 2 element tuples
{"hello", :world}
```

## Unquote

Giờ chúng ta có thể lấy ra cấu trúc nội tại của code, làm sao chúng ta có thể thay đổi nó? Để chèn thêm code hoặc giá trị mới, chúng ta sử dụng `unquote/1`. Khi chúng ta "unquote" một biểu thức, nó sẽ được thực thi và chèn thêm vào cây AST. Để hiểu `unquote/1`, chúng ta hãy cùng xem một vài ví dụ:

```elixir
iex> denominator = 2
2
iex> quote do: divide(42, denominator)
{:divide, [], [42, {:denominator, [], Elixir}]}
iex> quote do: divide(42, unquote(denominator))
{:divide, [], [42, 2]}
```

Trong ví dụ đầu tiên, biến `denominator` bị quote, do đó kết quả của AST sẽ bao gồm một tuple để truy cập vào biến đó. Bằng cách dùng `unquote/2` trong ví dụ thứ hai, code kết quả đã bao gồm giá trị của `denominator`.

## Macros

Khi chúng ta đã hiểu `quote/2` và `unquote/1`, chúng ta sẵn sàng để học thêm về macro. Cần nhớ rằng macro, cũng như metaprogramming, nên được sử dụng một cách chọn lọc.

Nói một cách đơn giản nhất, macro là các hàm đặc biệt được thiết kế để trả về các biểu thức đã bị quote, và các biểu thức đó sẽ được chèn vào code ứng dụng. Tưởng tượng, macro sẽ được thay thế bằng một biểu thức bị quote thay vì gọi như một hàm. Với macro, chúng ta có tất cả những gì cần thiết để mở rộng Elixir và có thể thêm các đoạn code động vào trong ứng dụng.

Chúng ta bắt đầu định nghĩa một macro bằng cách sử dụng `defmacro/2`, giống như rất phần khác của Elixir cũng là một macro. Và trong ví dụ tới đây, chúng ta sẽ cài đặt `unless` như một macro. Nhớ rằng macro của chúng ta cần trả về một biểu thức đã bị quote:

```elixir
defmodule OurMacro do
  defmacro unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end
```

Sau đây là đoạn code để sử dụng macro ở trên:

```elixir
iex> require OurMacro
nil
iex> OurMacro.unless true, do: "Hi"
nil
iex> OurMacro.unless false, do: "Hi"
"Hi"
```

Bởi vì macro thay thế code trong ứng dụng, chúng ta có thể điều khiển khi nào và cái gì sẽ được biên dịch. Một ví dụ cho chuyện này có thể tìm thấy trong `Logger` module. Khi logging bị tắt đi, sẽ không có đoạn code nào được chèn thêm vào, và kết quả là ứng dụng sẽ không chứa bất cứ tham chiếu hoặc lời gọi nào để log. Đây chính là điểm khác biệt với các ngôn ngữ khác, khi mà vẫn có một vài chi phí cho lời gọi hàm thậm chí khi mà việc cài đặt là không cần đến nó.

Để mô tả, chúng ta sẽ tạo ra một logger đơn giá có thể tắt hoặc bật:

```elixir
defmodule Logger do
  defmacro log(msg) do
    if Application.get_env(:logger, :enabled) do
      quote do
        IO.puts("Logged message: #{unquote(msg)}")
      end
    end
  end
end

defmodule Example do
  require Logger

  def test do
    Logger.log("This is a log message")
  end
end
```

Nếu chúng ta bật logging lên, hàm `test` sẽ có kết quả trong code giống như sau:

```elixir
def test do
  IO.puts("Logged message: #{"This is a log message"}")
end
```

Nếu chúng ta tắt nó đi, thì code sẽ là:

```elixir
def test do
end
```

## Debugging

Bây giờ, chúng ta đã biết cách dùng `quote/2`, `unquote/1` và cách viết macro. Nhưng nếu bạn có một đoạn code dài những quoted code, và muốn hiểu nó thì sao? Trong trường hợp này, bạn có thể dùng `Macro.to_string/2` như sau:

```elixir
iex> Macro.to_string(quote(do: foo.bar(1, 2, 3)))
"foo.bar(1, 2, 3)"
```

Và khi bạn muốn xem đoạn code được sinh ra bởi macro, bạn có thể kết hợp chúng với `Macro.expand/2` và `Macro.expand_once/2`, những hàm này sẽ mở rộng macro vào trong quoted code mà chúng được nhận. Hàm đầu tiên có thể mở rộng nó nhiều lần, trong khi hàm thứ hai chỉ một lần. Ví dụ, hãy cùng thay đổi `unless` chúng ta viết ở phần trước:

```elixir
defmodule OurMacro do
  defmacro unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end

require OurMacro

quoted =
  quote do
    OurMacro.unless(true, do: "Hi")
  end
```

```elixir
iex> quoted |> Macro.expand_once(__ENV__) |> Macro.to_string |> IO.puts
if(!true) do
  "Hi"
end
```

Nếu chúng ta chạy đoạn code trên với `Macro.expand/2`, kết quả sẽ như sau:

```elixir
iex> quoted |> Macro.expand(__ENV__) |> Macro.to_string |> IO.puts
case(!true) do
  x when x in [false, nil] ->
    nil
  _ ->
    "Hi"
end
```

Bạn có thể nhớ rằng, chúng ta đã từng nói `if` cũng là một macro trong Elixir, ở đây, chúng ta thấy, nó đã được mô tả ở bên dưới bằng các lệnh `case`.

### Private Macros

Mặc dù không thường xuyên, Elixir hỗ trợ cả các private macro. Một private macro được định nghĩa với `defmacrop` và chỉ có thể được gọi từ trong chính module mà nó được định nghĩa. Private macro phải được định nghĩa trước đoạn code sẽ gọi nó.

### Macro Hygiene

Cách mà macro tương tác với ngữ cảnh mà gọi macro đó, được gọi là macro hygiene. Mặc định, macro trong Elixir là "vô trùng", nghĩa là nó không bị xung đột với ngữ cảnh macro được gọi:

```elixir
defmodule Example do
  defmacro hygienic do
    quote do: val = -1
  end
end

iex> require Example
nil
iex> val = 42
42
iex> Example.hygienic
-1
iex> val
42
```

Vậy, nếu chúng ta muốn thay đổi giá trị của `val` thì sao? Để đánh dấu một biết là sẽ bị "nhiễm khuẩn", chúng ta dùng `var!/2`. Hãy cùng cập nhật ví dụ của chúng ta để thêm vào một vài macro tận dụng `var!/2`:

```elixir
defmodule Example do
  defmacro hygienic do
    quote do: val = -1
  end

  defmacro unhygienic do
    quote do: var!(val) = -1
  end
end
```

Hãy cùng so sánh cách mà `hygienic` và `unhygienic` tương tác với ngữ cảnh:

```elixir
iex> require Example
nil
iex> val = 42
42
iex> Example.hygienic
-1
iex> val
42
iex> Example.unhygienic
-1
iex> val
-1
```

Bằng cách thêm vào `var!/2` trong macro `unhygienic`, chúng ta đã có thể thay đổi giá trị của biến `val` mà không cần truyền nó vào trong macro. Việc sử dụng các macro "nhiễm khuẩn" như trên nên được hạn chế. Việc sử dụng `var!/2` đã làm tăng thêm rủi ro cho xung đột khi phân giải các biến.

### Binding

Chúng đã đã nói về các sử dụng `unquote/1`, nhưng có một cách khác để chèn thêm giá trị vào trong code: binding.
Với việc binding biến, chúng ta có thể thêm vào nhiều biến trong macro, và đảm bảo là chúng chỉ bị unquoted một lần, để tránh các lỗi khi tính lại. Để sử dụng các biến, chúng ta cần truyền một keyword list vào lựa chọn `bind_quoted` của `quote/2`.

Để thấy lợi ích của `bind_quoted` và mô tả vấn đề khi tính lại, chúng ta hãy cùng xem xét một ví dụ. Chúng ta sẽ bắt đầu tạo ra một macro đơn giản chỉ để in ra một biểu thức hai lần.

```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote do
      IO.puts(unquote(expr))
      IO.puts(unquote(expr))
    end
  end
end
```

Hãy thử macro trên bằng cách truyền cho nó thời gian hiện tại của hệ thống. Chúng ta mong muốn nó sẽ được in ra hai lần:

```elixir
iex> Example.double_puts(:os.system_time)
1450475941851668000
1450475941851733000
```

Kết quả lại không như vậy! Chuyện gì đã xảy ra thế này. Sử dụng `unquote/1` trên cùng một biểu thức nhiều lần, kết quả là biểu thức đo sẽ bị tính đi tính lại, và nó có thể dẫn tới nhiều hệ quả không mong muốn. Để sửa lỗi này, chúng ta cập nhật lại ví dụ trên bằng `bind_quoted` và hãy xem chúng ta có thể đạt được gì:

```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote bind_quoted: [expr: expr] do
      IO.puts(expr)
      IO.puts(expr)
    end
  end
end

iex> require Example
nil
iex> Example.double_puts(:os.system_time)
1450476083466500000
1450476083466500000
```

Với `bind_quoted`, chúng ta có được kết quả như mong muốn: cùng một thời gian được in ra hai lần.
Thông qua việc học về `quote/2`, `unquote/1` và `defmacro/2` chúng ta đã có tất cả các công cụ cần thiết để mở rộng Elixir theo những gì chúng ta muốn.
