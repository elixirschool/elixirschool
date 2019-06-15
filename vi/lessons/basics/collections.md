---
version: 0.9.0
title: Các tập dữ liệu
---

List (Danh sách), tuple, keyword (danh sách từ khoá), map, dict (từ điển) và functional combinators (toán tử kết hợp hướng chức năng)

{% include toc.html %}

## List (Danh sách)

List (danh sách) là một tập hợp các giá trị, có thể bao gồm nhiều kiểu dữ liệu; có thể bao gồm giá trị lặp:

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir triển khai list như những linked list (danh sách liên kết). Có nghĩa là việc truy cập độ dài của list là thao tác có độ phức tạp `O(n)`. Vì lý do này, chèn phần tử vào đầu list thường nhanh hơn so với thêm vào cuối list:

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> ["π" | list]
["π", 3.14, :pie, "Apple"]
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```

### Nối list

Dùng toán tử `++/2` để nối list:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

### Phép trừ list

Phép trừ list có thể thực hiện thông qua toán tử `--/2`; list trừ có thể bao gồm những giá trị không có trong list bị trừ:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

### Phần tử Đầu / Đuôi

Khi sử dụng danh sách, ta thường phải dùng tới đầu và đuôi của danh sách. Đầu là phần tử đầu tiên của danh sách và đuôi là danh sách những phần tử còn lại. Elixir hỗ trợ hai hàm hữu dụng, `hd` và `tl`, để truy cập đầu và đuôi:

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

Bên cạnh những hàm đã nói ở trên, bạn có thể dùng toán tử ống dẫn `|`; chúng ta sẽ còn gặp lại toán tử này trong các bài sau:

```elixir
iex> [head | tail] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> head
3.14
iex> tail
[:pie, "Apple"]
```

## Tuple

Tuple cũng tương tự như list nhưng được lưu trữ một cách liên tục trên bộ nhớ. Điều này dẫn tới việc truy cập kích thước tuple rất nhanh nhưng thay đổi thì chậm. Sau khi thay đổi, tuple mới phải được copy toàn bộ vào bộ nhớ:

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

Thông thường, tuple được sử dụng như một cơ chế để trả về các thông tin bổ sung từ các hàm; sự hữu dụng của nó trở nên rõ ràng hơn khi chúng ta đụng tới pattern matching (so khớp mẫu):

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Keyword Lists (Danh sách từ khoá)

Keywords List (danh sách từ khoá) và map là những kiểu dictionary (từ điển) của Elixir; cả hai cùng sử dụng `Dict` module bên dưới. Một keyword list trong Elixir là một loại danh sách tuple đặc biệt mà ở đó phần tử đầu tiên của tuple là một atom; chúng có cùng hiệu suất với danh sách:

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

Ba tính năng của keyword list cho thấy sự quan trọng của nó:

+ Các khoá đều là atom.
+ Các khoá được sắp xếp trình tự.
+ Các khoá có thể bị lặp

Vì những lý do này, keyword list thường được dùng để truyền vào hàm những giá trị không bắt buộc.

## Map

Map trong Elixir là kiểu từ điển hay được dùng nhất; không như danh sách từ khoá, map cho phép dùng bất kỳ kiểu dữ liệu nào cho khoá và các khoá không theo thứ tự sắp xếp. Bạn có thể tạo map với cú pháp `%{}`:

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

Từ phiên bản Elixir 1.2 có thể sử dụng biến làm khoá:

```elixir
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
```

Nếu một giá trị lặp được thêm vào map, nó sẽ thay thế giá trị cũ:

```elixir
iex> %{:foo => "bar", :foo => "hello world"}
%{foo: "hello world"}
```

Như bạn đã thấy từ output ở trên, có thể dùng cú pháp đặc biệt cho map nếu tất cả các khoá đều là atom:

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}

iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```
