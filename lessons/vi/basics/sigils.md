---
version: 0.9.0
title: Sigils
---

Làm việc cùng và tạo mới sigils.

{% include toc.html %}

## Tổng quan về Sigils

Elixir cung cấp cho chúng ta một cú pháp thay thế để mô tả và làm việc với chuỗi kí tự. Một sigil sẽ bắt đầu với dấu ngã `~` theo sau bởi một kí tự. Elixir cung cấp cho chúng ta một số sigils ban đầu, tuy nhiên chúng ta có thể tự tạo thêm các sigils khi cần thiết để mở rộng ngôn ngữ.

Chuỗi sigils được cung cấp ban đầu bao gồm:

  - `~C` Sinh ra một chuỗi các kí tự **không gồm** kí tự escape và kí tự nội suy (interpolation)
  - `~c` Sinh ra một chuỗi các kí tự **gồm** kí tự escape và kí tự nội suy (interpolation)
  - `~R` Sinh ra một chuỗi biểu thức chính qui **không gồm** kí tự escape và kí tự nội suy (interpolation)
  - `~r` Sinh ra một chuỗi biểu thức chính qui **gồm** kí tự escape và kí tự nội suy (interpolation)
  - `~S` Sinh ra một string **không gồm** kí tự escape và kí tự nội suy (interpolation)
  - `~s` Sinh ra một string **gồm** kí tự escape và kí tự nội suy (interpolation)
  - `~W` Sinh ra một list **không gồm** kí tự escape và kí tự nội suy (interpolation)
  - `~w` Sinh ra một list **gồm** kí tự escape và kí tự nội suy (interpolation)

Chuỗi phân tách bao gồm:

  - `<...>` Một cặp dấu ngoặc nhọn
  - `{...}` Một cặp dấu ngoặc xoắn
  - `[...]` Một cặp dấu ngoặc vuông
  - `(...)` Một cặp dấu ngoặc tròn
  - `|...|` Một cặp dấu đường ống
  - `/.../` Một cặp dấu gạch chéo
  - `"..."` Một cặp dấu trích dẫn kép
  - `'...'` Một cặp dấu trích dẫn đơn

### Chuỗi kí tự

Kí tự `~c` và `~C` sigils sinh ra chuỗi kí tự tương ứng. Ví dụ:

```elixir
iex> ~c/2 + 7 = #{2 + 7}/
'2 + 7 = 9'

iex> ~C/2 + 7 = #{2 + 7}/
'2 + 7 = \#{2 + 7}'
```

Chúng ta có thể thấy kí tự thường `~c` sẽ nội suy phần tính toán, trong khi kĩ tự hoa `~C` không. Chúng ta sẽ thấy chuỗi kí tự hoa / thường sẽ là chủ đề thường thấy của các sigils có sẵn. 

### Biểu thức chính qui 
`~r` và `~R` sigils thường được sử dụng để biểu diễn biểu thức chính qui. Biểu thức chính qui đó được tạo ra ngay lúc chạy hoặc là để sử dụng bên trong hàm `Regex`. Ví dụ:

```elixir
iex> re = ~r/elixir/
~r/elixir/

iex> "Elixir" =~ re
false

iex> "elixir" =~ re
true
```

Chúng ta có thể thấy trong ví dụ đầu tiên kiểm tra về mặt đẳng thức, `Elixir` không khớp với biểu thức chính qui, bởi vì nó được viết hoa. Do Elixir hỗ trợ biểu thức chính qui theo chuẩn Perl ( Perl Compatible Regular Expressions (PCRE)), chúng ta có thể thêm `i` vào cuối của sigils để bật chế độ kiểm tra không phụ thuộc vào viết hoa.

```elixir
iex> re = ~r/elixir/i
~r/elixir/i

iex> "Elixir" =~ re
true

iex> "elixir" =~ re
true
```

Hơn nữa, Elixir cung cấp [Regex](https://hexdocs.pm/elixir/Regex.html) API được xây dựng trên nền của thư viện biểu thức chính qui của Erlang. Hãy thử thực hành hàm `Regex.split/2` sử dụng regex sigil nào:

```elixir
iex> string = "100_000_000"
"100_000_000"

iex> Regex.split(~r/_/, string)
["100", "000", "000"]
```

Như chúng ta có thể thấy, chuỗi `"100_000_000"` được chia tại dấu gạch dưới nhờ có sự giúp đỡ của `~r/_/` sigil. Hàm `Regex.split` trả lại một chuỗi.

### Chuỗi

`~s` và `~S` sigils được sử dụng để sinh dữ liệu chuỗi. Ví dụ:

```elixir
iex> ~s/the cat in the hat on the mat/
"the cat in the hat on the mat"

iex> ~S/the cat in the hat on the mat/
"the cat in the hat on the mat"
```

Vậy hai biểu diễn khác gì nhau? Điểm khác nhau tương tự như sigil cho chuỗi các kí tự mà chúng ta đã xem ở trên. Câu trả lời nằm ở việc nội suy và sử dụng chuỗi escape. Hãy xem một ví dụ khác:

```elixir
iex> ~s/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir school"

iex> ~S/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir \#{String.downcase \"SCHOOL\"}"
```

### Chuỗi các từ

Chuỗi từ sigil rất tiện dụng trong nhiều hoàn cảnh. Nhờ nó chúng ta có thể tiết kiệm thời gian, số lượng phím bấm và thậm chí có thể giảm được sự phức tạp bên trong dự án. Hãy xem ví dụ đơn giản dưới đây:

```elixir
iex> ~w/i love elixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love elixir school/
["i", "love", "elixir", "school"]
```

Chúng ta có thể thấy những thứ được phân tách bởi dấu cách sẽ thành một phần tử trong chuỗi. Tuy nhiên, không có nhiều khác biệt giữa hai ví dụ. Một lần nữa, sự khác biệt lại chính là việc nội suy và chuỗi kí tự escape. Hãy xem ví dụ dưới đây:

```elixir
iex> ~w/i love #{'e'}lixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love #{'e'}lixir school/
["i", "love", "\#{'e'}lixir", "school"]
```

## Tạo mới Sigils
Một trong những mục tiêu của Elixir là trở thành một ngôn ngữ có thể mở rộng được. Do đó mà không hề ngạc nhiên khi chúng ta có thể tự tạo mới sigils. Trong ví dụ dưới đây, chúng ta sẽ tạo mới sigil để chuyển một chuỗi sang dạng viết hoa. Do chúng ta đã có sẵn hàm để làm việc đó trong Elixir (`String.upcase/1`), chúng ta sẽ bọc hàm đó lại bởi sigil.

```elixir

iex> defmodule MySigils do
...>   def sigil_u(string, []), do: String.upcase(string)
...> end

iex> import MySigils
nil

iex> ~u/elixir school/
ELIXIR SCHOOL
```

Đầu tiên chúng ta định nghĩa một module tên là `MySigils` và bên trong module đó, chúng ta tạo một hàm tên là `sigil_u`. Do chưa có `~u` nào có sẵn trong không gian sigil, chúng ta sẽ có thể sử dụng được kí tự đó. Phần `_u` nói lên rằng chúng ta muốn sử dụng kí tự `u` sau dấu ngã của sigil. Định nghĩa của hàm sẽ phải nhận vào 2 biến, một input và một chuỗi.
