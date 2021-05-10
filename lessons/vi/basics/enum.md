%{
  version: "0.9.0",
  title: "Enum",
  excerpt: """
  Các thuật toán thao tác với các collection (tập dữ liệu)
  """
}
---

## Enum

Module `Enum` bao gồm hơn một trăm hàm để dùng với các collection ta đã biết từ bài trước.

Bài này sẽ chỉ thảo luận một vài trong số các hàm đó, xem đầy đủ các hàm tại trang tài liệu chính thức [`Enum`](https://hexdocs.pm/elixir/Enum.html); xem thêm lazy enumeration (thao tác trì hoãn) tại trang [`Stream`](https://hexdocs.pm/elixir/Stream.html)

### all?

Khi dùng hàm `all?`, và hầu hết các hàm khác của `Enum`, ta cần cung cấp một hàm để xử lý từng phần tử của collection. Trong trường hợp của `all?`, tất cả các phần tử của collection phải có giá trị `true`, nếu không kết quả sẽ trả về `false`:

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

Ngược lại, `any?` trả về `true` nếu có ít nhất 1 phần tử có giá trị `true`:

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk_every/2

Để chia collection thành các nhóm nhỏ, bạn có thể dùng hàm `chunk_every/2`:

```elixir
iex> Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

Có nhiều lựa chọn với hàm `chunk_every/2` nhưng ta sẽ không đi sâu vào chi tiết, xem trang chính thức [`chunk_every/4`](https://hexdocs.pm/elixir/Enum.html#chunk_every/4) để biết thêm chi tiết.

### chunk_by

Nếu cần nhóm các phần tử theo một tính năng khác không phải kích thước, ta có thể dùng `chunk_by`:

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
```

### each

Đôi khi cần phải duyệt phần tử của collection mà không tạo ra giá trị mới, bạn có thể dùng hàm `each`:

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
:ok
```

__Lưu ý__: Hàm `each` thực ra luôn trả về atom `:ok`.

### map

Dùng hàm `map` để tạo collection mới bằng cách gọi một hàm trên mỗi phần tử của collection đang có:

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

Hàm `reduce` có thể rút gọn collection về một giá trị. Ta cần cung cấp một accumulator (giá trị tích luỹ) không bắt buộc (trong trường hợp này là `10`) và một hàm để tính dựa trên accumulator này và các phần tử của collection; nếu không có accumulator, phần tử đầu tiên sẽ được sử dụng thay thế:

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16
iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6
iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
```

### sort

Sắp xếp collection được hỗ trợ bởi hai hàm `sort`. Ta có thể dùng thứ tự sắp xếp có sẵn của Elixir:

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

Hoặc tự cung cấp hàm để sắp xếp:

```elixir
# dùng hàm đã chọn
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# không dùng hàm
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq

Hàm `uniq` dùng để loại bỏ các phần tử lặp trong collection:

```elixir
iex> Enum.uniq([1, 2, 2, 3, 3, 3, 4, 4, 4, 4])
[1, 2, 3, 4]
```
