---
layout: page
title: Enum
category: basics
order: 3
lang: vi
---

Các thuật toán để thao tác với tập hợp

## Mục lục

- [Enum](#enum)
  - [all?](#all)
  - [any?](#any)
  - [chunk](#chunk)
  - [chunk_by](#chunk_by)
  - [each](#each)
  - [map](#map)
  - [min](#min)
  - [max](#max)
  - [reduce](#reduce)
  - [sort](#sort)
  - [uniq](#uniq)

## Enum

Module Enum bao gồm hơn một trăm hàm để dùng với các tập hợp ta đã biết từ bài trước.

Bài này sẽ chỉ thảo luận một vài trong số các hàm đó, xem đầy đủ các hàm tại trang tài liệu chính thức [`Enum`](http://elixir-lang.org/docs/v1.0/elixir/Enum.html); xem thao tác trì hoãn (lazy enumeration) tại trang [`Stream`](http://elixir-lang.org/docs/v1.0/elixir/Stream.html)

### all?

Khi dùng hàm 'all?', và hầu hết các hàm khác của 'Enum', ta cần cung cấp một hàm để xử lý từng phần tử của tập hợp. Trong trường hợp của 'all?', tất cả các phần tử của tập hợp phải có giá trị `true`, nếu không kết quả sẽ trả về `false`

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

Ngược lại, `any?` trả về `true` nếu có ít nhất 1 phần tử có giá trị `true`

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk

Để chia tập hợp thành các nhóm nhỏ, bạn có thể dùng `chunk`:

```elixir
iex> Enum.chunk([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

Có nhiều lựa chọn với hàm `chunk` nhưng ta sẽ không đi sâu vào chi tiết, xem trang chính thức [`chunk/2`](http://elixir-lang.org/docs/v1.0/elixir/Enum.html#chunk/2) để biết thêm chi tiết.

### chunk_by

Nếu cần nhóm các phần tử theo một tính năng khác không phải kích thước, ta có thể dùng `chunk_by`:

```elixir
iex> Enum.chunk_by(["one", "twoóm", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
```

### each

Để xử lý tất cả các phần tử mà không trả về giá trị mới, hãy sử dụng `each`:

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
```

__Lưu ý__: Hàm `each` thực ra luôn trả về atom `:ok`.

### map

Dùng hàm `map` để tạo tập hợp mới bằng cách gọi một hàm trên mỗi phần tử của tập hợp đang có:

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

Dùng hàm `min` để tìm giá trị của phần tử nhỏ nhất:

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

### max

Dùng hàm `max` để tìm giá trị của phần tử lớn nhất:

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

### reduce

Hàm `reduce` có thể rút gọn tập hợp về một giá trị. Ta cần cung cấp một giá trị tích luỹ (accumulator) không bắt buộc (trong trường hợp này là `10`) và một hàm để tính dựa trên giá trị tích luỹ này và các phần tử của tập hợp; nếu không có giá trị tích luỹ, phần tử đầu tiên sẽ được sử dụng thay thế:

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16
iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6
```

### sort

Sắp xếp tập hợp được hỗ trợ bởi hai hàm `sort`. Ta có thể dùng thứ tự sắp xếp có sẵn của Elixir:

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

Hoặc tự cung cấp một hàm để sắp xếp:

```elixir
# dùng hàm đã chọn
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# không dùng hàm
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq

Hàm `uniq` dùng để loại bỏ các phần tử bị lặp trong tập hợp:

```elixir
iex> Enum.uniq([1, 2, 2, 3, 3, 3, 4, 4, 4, 4])
[1, 2, 3, 4]
```
