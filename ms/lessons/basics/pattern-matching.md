---
version: 0.9.0
title: Pemadanan Corak
---

Pemadanan corak ialah satu komponen Elixir yang amat berkuasa, ia mengupayakan kita untuk membuat pemadanan nilai-nilai mudah, struktur data, dan juga fungsi-fungsi.

{% include toc.html %}

## Operator Padanan

Anda bersedia untuk sesuatu yang pelik?  Di dalam Elixir, operator `=` adalah satu operator padanan(match operator).  Melalui operator padanan kita boleh menetapkan nilai dan kemudian membuat pemadanan nilai, mari kita lihat:

```elixir
iex> x = 1
1
```

Sekarang kita akan membuat ujian pemadanan mudah:

```elixir
iex> 1 = x
1
iex> 2 = x
** (MatchError) no match of right hand side value: 1
```

Sekarang kita akan menguji beberapa 'collection' yang kita tahu:

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

## Operator Pin

Kita baru belajar bahawa operator padanan menguruskan penetapan nilai apabila bahagian sebelah kiri pemadanan itu mengandungi satu pembolehubah.  Dalam sesetengah keadaan, penetapan semula nilai kepada pembolehubah tidak dibenarkan.  Untuk keadaan ini, kita mempunyai operator pin: `^`.

Apabila kita meletakkan pin(`^`) kepada satu pembolehubah, kita akan membuat pemadanan untuk nilai semasa dan tidak akan menetapkan nilai baru kepada pembolehubah tersebut.  Mari kita lihat bagaimana ia berfungsi:

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

Elixir 1.2 memperkenalkan sokongan untuk pin di dalam kunci 'map' dan klausa fungsi-fungsi:

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

Satu contoh penggunaan pin di dalam klausa fungsi:

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
