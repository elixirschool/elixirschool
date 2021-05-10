%{
  version: "1.0.3",
  title: "Đặc tả và kiểu",
  excerpt: """
  Trong bài học này, chúng ta sẽ học về cú pháp `@spec` và `@type`. `@spec` giống như là một cú pháp hỗ trợ để viết tài liệu, và có thể được phân tích bởi các công cụ khác, `@type` giúp chúng ta viết các code dễ đọc và dễ hiểu hơn.
  """
}
---

## Giới thiệu

Thông thường, bạn sẽ muốn mô tả giao diện cho hàm của bạn. Tất nhiện bạn có thể sử dụng [@doc annotation](../../basics/documentation), tuy nhiên nó chỉ là các thông tin cho các lập trình viên khác, mà không được kiểm tra trong lúc biên dịch. Cho mục đích này, Elixir cung cấp `@spec` annotation để mô tả các đặc tả của hàm sẽ được kiểm tra bởi trình biên dịch

Tuy nhiên, trong một số trường hợp, các đặc tả sẽ trở nên khá lớn và phức tạp. Nếu bạn muốn giảm bớt tính phức tạp, nhưng vẫn muốn đưa ra định nghĩa cho các kiểu mới, Elixir cung cấp anotiation(tạm dịch là ký tự chú thích)`@type` để làm việc này. Nói cách khác, Elixir vẫn là một ngôn ngữ kiểu động (dynamic language). Nghĩa là tất cả các thông tin về kiểu sẽ bị trình biên dịch bỏ qua, nhưng nó có thể được sử dụng bởi các công cụ khác.

## Đặc tả

Nếu đã có kinh nghiệm với Java, bạn có thể coi đặc tả như là một `interface`. Đặc tả định nghĩa kiểu của các tham số của hàm, cũng như kiểu của giá trị trả về.

Để định nghĩa kiểu đầu vào và đầu ra, chúng ta sử dụng `@spec` ngay trước định nghĩa hàm, các tham số cho `@spec` sẽ là tên của hàm, danh sách kiểu của các tham số cho hàm đó, tiếp theo là `::`, cuối cùng là kiểu của giá trị trả về

Hãy cùng xem ví dụ dưới đây:

```elixir
@spec sum_product(integer) :: integer
def sum_product(a) do
  [1, 2, 3]
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
end
```

Mọi thứ trông vẫn tốt, và khi chúng ta gọi hàm này, một giá trị hợp lệ sẽ được trả về, nhưng hàm `Enum.sum` trả về `number` chứ không phải là `integer` như chúng ta mong muốn ở trong `@spec`. Đây có thể nguồn gốc của các lỗi! Có những công cụ như Dialyzer để phân tích tĩnh (static analysis) code có thể giúp chúng ta tìm những lỗi kiểu này. Chúng ta sẽ nói về chúng trong một bài học khác.

## Kiểu tuỳ biến

Các đặc tả là rất tốt, tuy nhiên đôi khi các hàm của chúng ta làm việc với nhiều cấu trúc dữ liệu phức tạp hơn là các số hoặc là các tập hợp (collections). Trong trường hợp này, `@spec` có thể sẽ trở nên rất khó hiểu, hoặc khó thay đổi đối với các lập trình viên khác. Đôi khi các hàm cần nhận vào một lượng lớn các tham số, hoặc là trả về một dữ liệu phức tạp. Một danh sách dài các tham số có thể là một trong những chỗ "bốc mùi" (code smell) trong code. Trong các ngôn ngữ hướng đối tượng giống như Ruby và Java, chúng ta có thể dễ dàng định nghĩa các class để giải quyết vấn đề này. Elixir không có class những bởi vì nó rất dễ để mở rộng, chúng ta có thể định nghĩa kiểu của riêng chúng ta.

Ngoài ra, Elixir chứa một vài kiểu cơ bản như `integer`, hoặc là `pid`. Bạn có thể tìm hiểu về danh sách các kiểu có sẵn của Elixir trong [tài liệu](https://hexdocs.pm/elixir/typespecs.html#types-and-their-syntax).

### Định nghĩa kiểu tuỳ biến

Hãy cùng thay đổi hàm `sum_times` và giới thiệu thêm một vài tham số mới:

```elixir
@spec sum_times(integer, %Examples{first: integer, last: integer}) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

Chúng ta giới thiệu thêm một struct trong `Examples` module, chứa hai trường `first` và `last`. Đây là phiên bản đơn giản hơn của module `Range`. Chúng ta sẽ nói về `struct` khi chúng ta thảo luận về [modules](../../basics/modules/#structs). Tưởng tượng rằng, chúng ta muốn mô tả đặc tả với `Examples` struct trong rất nhiều chỗ. Những đặc tả này có thể sẽ rất dài, phức tạp, và có thể là cội nguồn của các bug. Một giải pháp cho chuyện này là dùng `@type`.

Elixir cung cấp ba cách dùng để định nghĩa kiểu:

  - `@type` – kiểu public. Các cấu trúc nội tại của kiểu là public
  - `@typep` – kiểu private, và chỉ có thể sử dụng trong module mà nó được định nghĩa.
  - `@opaque` – kiểu public, but cấu trúc nội tại là private

Hãy cùng định nghĩa kiểu của chúng ta:

```elixir
defmodule Examples do
  defstruct first: nil, last: nil

  @type t(first, last) :: %Examples{first: first, last: last}

  @type t :: %Examples{first: integer, last: integer}
end
```

Chúng ta định nghĩa kiểu `t(first, last)` để đại diện cho struct `%Examples{first: first, last: last}`. Lúc này, chúng ta thấy các kiểu có thể nhận vào các parameter, nhưng chúng ta cũng định nghĩa kiểu `t`, và lúc này nó đại diện cho struct `%Examples{first: integer, last: integer}`.

Điểm khác nhau là gì? Cái đầu tiên đại diện cho `Examples` struct mà hai khoá có thể là bất cứ kiểu này. Cái thứ hai đại diện cho struct, trong đó các khoá là các `integer`. Điều này có nghĩa là đoạn code sau:

```elixir
@spec sum_times(integer, Examples.t()) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

Tương đương với:

```elixir
@spec sum_times(integer, Examples.t(integer, integer)) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

### Viết tài liệu cho kiểu

Thành phần cuối cùng chúng ta muốn thảo luận là về các để viết tài liệu cho kiểu. Như chúng ta đã biết từ bài [documentation](../../basics/documentation), chúng ta có `@doc` và `@moduledoc` để viết các tài liệu cho hàm và cho module. Để viết tài liệu cho kiểu, chúng ta có thể dùng `@typedoc`:


```elixir
defmodule Examples do
  @typedoc """
      Type that represents Examples struct with :first as integer and :last as integer.
  """
  @type t :: %Examples{first: integer, last: integer}
end
```

`@typedoc` là tương tự `@doc` and `@moduledoc`.
