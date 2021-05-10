---
version: 0.9.0
title: Pattern matching (so trùng mẫu)
---

Pattern matching (so trùng mẫu) là chức năng lợi hại của Elixir, nó giúp chúng ta so khớp các giá trị đơn giản, các kiểu cấu trúc dữ liệu và cả hàm. Trong bài này chúng ta sẽ cùng khám phá cách cơ chế này.

{% include toc.html %}

## Match operator (Toán tử khớp)

Bạn đã chuẩn bị tinh thần chưa? Trong Elixir, thực ra dấu = chính là match operator. Thông qua nó chúng ta có thể gán và sau đó so khớp giá trị, hãy cùng xem ví dụ sau:

```elixir
iex> x = 1
1
```

Bây giờ hãy thử với một ví dụ so khớp đơn giản sau:

```elixir
iex> 1 = x
1
iex> 2 = x
** (MatchError) no match of right hand side value: 1
```

Và thử với các kiểu tổ hợp:

```elixir
# Lists
iex> list = [1, 2, 3]
[1, 2, 3]
iex> [1, 2, 3] = list
[1, 2, 3]
iex> [] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

iex> [1 | tail] = list
[1, 2, 3]
iex> tail
[2, 3]
iex> [2|_] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

# Tuples
iex> {:ok, value} = {:ok, "Successful!"}
{:ok, "Successful!"}
iex> value
"Successful!"
iex> {:ok, value} = {:error}
** (MatchError) no match of right hand side value: {:error}
```

## Pin operator (Toán tử ghim)

Chúng ta mới biết được rằng match operator đảm nhiệm phép gán khi vế trái của khớp chứa một biến. Trong một số trường hợp, với cách hoạt động này, variable rebinding (biến bị gán với một giá trị khác) là điều không mong muốn. Những lúc đó, chúng ta có pin operator: `^`.

Khi pin (ghim) một biến thì ta so khớp giá trị hiện tại của nó chứ không phải là gán nó với một giá trị mới. Hãy xem cách chúng hoặt động:

```elixir
iex> x = 1
1
iex> ^x = 2
** (MatchError) no match of right hand side value: 2
iex> {x, ^x} = {2, 1}
{2, 1}
iex> x
2
```

Elixir 1.2 giới thiệu việc hỗ trợ pin (ghim) cho các khoá trong kiểu map và trong mệnh đề của hàm:

```elixir
iex> key = "hello"
"hello"
iex> %{^key => value} = %{"hello" => "world"}
%{"hello" => "world"}
iex> value
"world"
iex> %{^key => value} = %{:hello => "world"}
** (MatchError) no match of right hand side value: %{hello: "world"}
```

Một ví dụ về pin (ghim) trong một mệnh đề hàm:

```elixir
iex> greeting = "Hello"
"Hello"
iex> greet = fn
...>   (^greeting, name) -> "Hi #{name}"
...>   (greeting, name) -> "#{greeting}, #{name}"
...> end
#Function<12.54118792/2 in :erl_eval.expr/5>
iex> greet.("Hello", "Sean")
"Hi Sean"
iex> greet.("Mornin'", "Sean")
"Mornin', Sean"
```
