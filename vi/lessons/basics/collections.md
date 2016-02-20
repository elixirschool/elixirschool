---
layout: page
title: Các tập dữ liệu
category: basics
order: 2
lang: vi
---

Danh sách (list), tuple, danh sách từ khoá (keyword), map, từ điển (dict) và sự kết hợp hàm số

## Mục Lục

- [Danh sách](#lists)
	- [Nối danh sách](#list-concatenation)
	- [Phép trừ danh sách](#list-subtraction)
	- [Đầu / Đuôi](#head--tail)
- [Tuple](#tuples)
- [Danh sách từ khoá](#keyword-lists)
- [Map](#maps)

## Danh sách

Danh sách là một tập hợp các giá trị, có thể bao gồm nhiều kiểu dữ liệu; có thể bao gồm giá trị bị lặp:

```elixir
iex> [3.41, :pie, "Apple"]
[3.41, :pie, "Apple"]
```

Với Elixir, danh sách được xây dựng từ danh sách liên kết (linked list). Điều này dẫn đến việc truy cập kích thước của danh sách là một thao tác với độ phức tạp `O(n)`. Vì lý do này, chèn phần tử vào đầu danh sách thường nhanh hơn so với thêm vào cuối danh sách:

```elixir
iex> list = [3.41, :pie, "Apple"]
[3.41, :pie, "Apple"]
iex> ["π"] ++ list
["π", 3.41, :pie, "Apple"]
iex> list ++ ["Cherry"]
[3.41, :pie, "Apple", "Cherry"]
```

### Nối danh sách

Dùng toán tử `++/2` để nối danh sách:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

### Phép trừ danh sách

Phép trừ danh sách có thể thực hiện thông qua toán tử `--/2`; danh sách trừ có thể bao gồm những giá trị không có trong danh sách bị trừ:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

### Đầu / Đuôi

Khi sử dụng danh sách, ta thường phải dùng tới đầu và đuôi của danh sách. Đầu là phần tử đầu tiên của danh sách và đuôi là danh sách những phần tử còn lại. Elixir hỗ trợ hai hàm hữu dụng, `hd` và `tl`, để truy cập đầu và đuôi:

```elixir
iex> hd [3.41, :pie, "Apple"]
3.41
iex> tl [3.41, :pie, "Apple"]
[:pie, "Apple"]
```

Bên cạnh những hàm đã nói ở trên, bạn có thể dùng toán tử ống dẫn `|`; chúng ta sẽ còn gặp lại toán tử này trong các bài sau:

```elixir
iex> [h|t] = [3.41, :pie, "Apple"]
[3.41, :pie, "Apple"]
iex> h
3.41
iex> t
[:pie, "Apple"]
```

## Tuple

Tuple cũng tương tự như danh sách nhưng luôn được lưu cạnh nhau trong bộ nhớ. Điều này dẫn tới việc truy cập kích thước tuple rất nhanh nhưng thay đổi thì chậm. Sau khi thay đổi, tuple mới phải được copy lại hết vào bộ nhớ:

```elixir
iex> {3.41, :pie, "Apple"}
{3.41, :pie, "Apple"}
```

Thông thường, tuple được sử dụng để trả về những thông tin thêm vào của các hàm; bạn sẽ thấy rõ hơn sự hữu dụng của tuple khi dùng so khớp mẫu (pattern matching):

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Danh sách từ khoá

Danh sách từ khoá và map là những kiểu từ điển của Elixir; cả hai cùng sử dụng `Dict` module bên dưới. Một danh sách từ khoá trong Elixir là một loại danh sách tuple đặc biệt mà ở đó phần tử đầu tiên của tuple là một atom; chúng có cùng hiệu suất với danh sách:

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

Ba tính năng của danh sách từ khoá cho thấy sự quan trọng của nó:

+ Các khoá đều là atom.
+ Các khoá được sắp xếp trình tự.
+ Các khoá có thể bị lặp

Vì những lý do này, danh sách từ khoá thường được dùng để truyền vào hàm những giá trị không bắt buộc.

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
