---
layout: page
title: Pattern matching (so trùng mẫu)
category: basics
order: 4
lang: vi
---

Pattern matching (so trùng mẫu) là chức năng lợi hại của Elixir, nó giúp chung ta so khớp các giá trị đơn giản, các kiểu cấu trúc dữ liệu và cả hàm. Trong bài này chúng ta sẽ cùng khám phá cách cơ chế này.

## Mục lục

- [Match operator (Toán tử khớp)](#match-operator)
- [Pin operator (Toán tử ghim)](#pin-operator)

## Match operator (Toán tử khớp)

Bạn đã chuẩn bị tinh thần chưa? Trong Elixir, khoá `=` là match operator. Thông qua match operator chúng ta có thể gán và sau đó so khớp giá trị, hãy cùng xem ví dụ sau:

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
iex> [1, 2, 3] = list
[1, 2, 3]
iex> [] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

iex> [1|tail] = list
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

Chúng ta vừa học cách match operator đảm nhiệm phần gán giá trị khi vế trái của biểu thức trùng có kèm một biến. Trong một vài trường hợp thì chúng ta không muốn biến bị rebind (gán với giá trị mới). Để tránh được chuyện đó chúng ta dùng pin operator `^`:

Khi chúng ta 'ghim' một biến, chúng ta so khớp giá trị hiện hành hơn là gán vào một biến mới. Hãy xem cách chúng hoặt động:

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

Elixir 1.2 giới thiệu cơ chế ghim cho cả khoá của kiểu map và cú pháp của hàm:

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

Một ví dụ cách ghim cú pháp của hàm:

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
