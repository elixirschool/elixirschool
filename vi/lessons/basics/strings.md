---
version: 0.9.1
title: Strings
---

String, Chuỗi kí tự (Char List), Chữ cái (Graphemes) và Codepoints.

{% include toc.html %}

## Strings

String trong Elixir đơn giản là một chuỗi các byte. Ví dụ như:

```elixir
iex> string = <<104,101,108,108,111>>
"hello"
```

>NOTE: Khi dùng cú pháp << >>, chúng ta đang khai báo cho trình biên dịch biết rằng những thành phần bên trong << >> là các byte.

## Chuỗi kí tự (Char Lists)

String bên trong Elixir được biểu diễn với một chuỗi các byte hơn là một dãy (array) các kí tự. Elixir cũng có một kiểu dữ liệu **khác** dành cho chuỗi kí tự. String của Elixir được bọc trong dấu ngoặc kép, trong khi chuỗi kí tự được bọc trong dấu ngoặc đơn.

Chúng khác nhau như thế nào? Mỗi giá trị trong chuỗi kí tự là giá trị ASCII của kí tự đó. Ta hãy đi sâu vào một chút:

```elixir
iex> char_list = 'hello'
'hello'

iex> [hd|tl] = char_list
'hello'

iex> {hd, tl}
{104, 'ello'}

iex> Enum.reduce(char_list, "", fn char, acc -> acc <> to_string(char) <> "," end)
"104,101,108,108,111,"
```

Khi lập trình với Elixir, ta thường dùng String mà không phải chuỗi kí tự. Chuỗi kí tự được hỗ trợ chủ yếu vì một số Erlang module cần có nó.

## Graphemes và Codepoints

Codepoints đơn giản chỉ là những kí tự Unicode mà được biểu diễn bằng một hoặc nhiều byte, tùy vào định dạng UTF-8. Các kí tự không thuộc tập US ASCII luôn luôn được định dạng nhiều hơn một byte. Ví dụ như kí tự Latin có dấu như (`á`, `è`, `ô`) thường được định dạng hai byte. Kí tự của các ngôn ngữ Châu Á cũng thường được định dạng ba hoặc bốn byte. Grapheme bao gồm nhiều codepoints được hiển thị ra như là một kí tự.

String module cung cấp hai phương thức để lấy chúng là `graphemes/1` and `codepoints/1`. Chúng ta cũng xem ví dụ:

```elixir
iex> string = "\u0061\u0301"
"á"

iex> String.codepoints string
["a", "́"]

iex> String.graphemes string
["á"]
```

## Các hàm của String

Chúng ta hãy cùng xem qua một số hàm quan trọng và hữu ích nhất của String module. Bài này chỉ đề cập một số các hàm có sẵn. Các bạn có thể xem đầy đủ tại tài liệu chính thức [`String`](https://hexdocs.pm/elixir/String.html).

### `length/1`

Trả về số Grapheme trong string.

```elixir
iex> String.length "Hello"
5
```

### `replace/3`

Trả về một string mới với các mẫu trùng đã được thay thế.

```elixir
iex> String.replace("Hello", "e", "a")
"Hallo"
```

### `duplicate/2`

Trả về một string mới được lặp lại n lần.

```elixir
iex> String.duplicate("Oh my ", 3)
"Oh my Oh my Oh my "
```

### `split/2`

Tách chuỗi được ngăn cách bởi một mẫu nào đó.

```elixir
iex> String.split("Hello World", " ")
["Hello", "World"]
```

## Bài tập

Ta hãy cùng lướt qua một số bài tập để xem liệu mình đã sẵn sàng với String!

### Anagrams

A và B được xem là anagram nếu có một sách sắp xếp A hoặc B sao cho chúng giống nhau. Ví dụ:

+ A = super
+ B = perus

Nếu chúng ta hoán đổi vị trí các kí tự của String A, chúng ta có string B, và ngược lại.

Vậy làm sao để chúng ta kiểm tra hai chuỗi có là anagram trong Elixir? Cách đơn giản nhất là sắp xếp các chữ cái của từng string theo thứ tự ABC và sau đó kiểm tra liệu chúng có giống nhau. Thử xem nào:

```elixir
defmodule Anagram do
  def anagrams?(a, b) when is_binary(a) and is_binary(b) do
    sort_string(a) == sort_string(b)
  end

  def sort_string(string) do
    string
    |> String.downcase()
    |> String.graphemes()
    |> Enum.sort()
  end
end
```

Với `anagrams?/2`, ta sẽ kiểm tra tham số ta nhận được có phải binaries hay không. Đây là cách mà chúng ta kiểm tra một tham số có là String trong Elixir.

Sau đó chúng ta sẽ gọi hàm sắp sếp chuỗi theo thứ tự ABC, trước hết ta sẽ biến string thành kiểu viết thường và sau đó dùng `String.graphemes` để trả về danh sách chữ cái của string. Cũng đơn giản mà chứ nhỉ?

Chúng ta cũng kiểm tra kết quả trên iex:

```elixir
iex> Anagram.anagrams?("Hello", "ohell")
true

iex> Anagram.anagrams?("María", "íMara")
true

iex> Anagram.anagrams?(3, 5)
** (FunctionClauseError) no function clause matching in Anagram.anagrams?/2

    The following arguments were given to Anagram.anagrams?/2:

        # 1
        3

        # 2
        5

    iex:11: Anagram.anagrams?/2
```

Như bạn thấy, lần gọi cuối cùng của `anagrams?` văng lỗi FunctionClauseError. Lỗi này có nghĩa là không có hàm trong module của chúng ta thỏa điều kiện hai tham số không phải binary, đó chính là thứ mà ta cần: chỉ nhận hai string mà không phải thứ gì khác.
