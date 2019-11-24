---
version: 0.9.0
title: Cơ bản
---

Cài đặt, cái kiểu phổ thông và cơ chế hoạt động.

{% include toc.html %}

## Cài đặt

### Cài Elixir

Hướng dẫn cài đặt cho mỗi OS có thể tìm trên trang Elixir-lang.org trong mục [Installing Elixir](http://elixir-lang.org/install.html).

### Chế độ trực quan (Interactive Mode)

Elixir đi kèm với `iex`, một shell trực quan, cho phép chúng ta chạy biểu thức Elixir nhập vào.

Để bắt đầu, hãy chạy `iex`:

	Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

	Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)

## Các kiểu phổ thông

### Integer (Số nguyên)

```elixir
iex> 255
255
```

Có hỗ trợ số nhị phân, bát phân, thập lục phân:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### Float (Số thực dấu phẩy động)

Trong Elixir, số Float được thể hiện bằng một số thập phân đi sau dấu phân số; chúng sẽ có độ chính xác kép 64bit và hỗ trợ `e` cho số luỹ thừa:

CHÚ THÍCH: Dấu phân số theo hệ toán học Anh là `.` chứ không phải dấu `,`

```elixir
iex> 3.14 
3.14
iex> .14
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```

### Boolean (Luận lý Boole)

Elixir dùng `true` và `false` như luận lý; tất cả mọi thứ đều được xem là thật ngoại trừ `false` và `nil`:

```elixir
iex> true
true
iex> false
false
```

### Atom

Một atom là một biến không thay đổi với tên là giá trị của chúng. Nếu bạn quen Ruby thì chúng giống Symbols:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

CHÚ THÍCH: Luận lý `true` và `false` tuần tự là atoms `:true` và `:false`.

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

### String (Chuỗi)

String (chuỗi) trong Elixir được định dạng theo chuẩn UTF-8 và được gói trong dấu ngoặc kép:

```elixir
iex> "Hello"
"Hello"
iex> "cải cách"
"cải cách"
```

String cũng hỗ trợ tách ra nhiều dòng và tự động thoát các chuỗi theo trình tự:

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

## Cơ chế vận hành phổ thông

### Toán học

Elixir hỗ trợ các toán tử phổ thông `+`, `-`, `*`, và `/` như bạn kì vọng. Xin lưu ý rằng `/` luôn trả về một số Float động:

```elixir
iex> 2 + 2
4
iex> 2 - 1
1
iex> 2 * 5
10
iex> 10 / 5
2.0
```

Nếu bạn cần chia số Integer hoặc tìm số thừa, Elixir có 2 hàm hữu dụng để thực hiện:

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Boolean (Luận lý Boole)

Elixir cung cấp luận tử `||`, `&&`, and `!`, chúng hỗ trợ các kiểu dữ liệu sau:

```elixir
iex> -20 || true
-20
iex> false || 42
42

iex> 42 && true
true
iex> 42 && nil
nil

iex> !42
false
iex> !false
true
```

Có 3 luận tử bổ sung mà đối số _phải là_ một luận lý Boolean (`true` và `false`):

```elixir
iex> true and 42
42
iex> false or true
true
iex> not false
true
iex> 42 and true
** (ArgumentError) argument error: 42
iex> not 42
** (ArgumentError) argument error
```

### So sánh

Elixir có hỗ trợ các toán tử so sánh quen thuộc: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<` và `>`.

```elixir
iex> 1 > 2
false
iex> 1 != 2
true
iex> 2 == 2
true
iex> 2 <= 3
true
```

Nếu muốn so sánh kĩ số Float hay số Integer, sử dụng `===`:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Một chức năng quan trọng của Elixir là hai kiểu có thể được so sánh với nhau, thực sự rất là hữu dụng cho việc sắp xếp. Chúng ta không cần phải nhớ thứ tự sắp xếp nhưng nên lưu ý:

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

Điều này có thể dẫn đến một vài trường hợp so sánh hợp lệ nhưng khá xa lạ so với các ngôn ngữ khác:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### String Interpolation (Chèn chuỗi)

Nếu bạn đã từng sử dụng qua Ruby, chèn vào một String với Elixir rất giống:

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### Sâu nối String

Dùng `<>` để xâu các String lại với nhau:

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
