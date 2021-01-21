---
version: 1.0.1
title: Pencocokan Pola
---

Pencocokan pola (Pattern matching) adalah sebuah bagian Elixir yang powerful, memungkinkan kita mencocokkan value sederhana, struktur data, dan bahkan fungsi. Dalam pelajaran ini kita akan mulai melihat bagaimana pencocokan pola ini digunakan.

{% include toc.html %}

## Match operator

Siap untuk dibuat bingung? Dalam Elixir, operator `=` sebetulnya adalah operator pencocokan (match operator). Melalui operator pencocokan kita dapat menetapkan (assign) dan kemudian mencocokkan value, mari kita lihat:

```elixir
iex> x = 1
1
```

Sekarang mari coba pencocokan sederhana:

```elixir
iex> 1 = x
1
iex> 2 = x
** (MatchError) no match of right hand side value: 1
```

Mari coba dengan sebagian collection yang kita tahu:

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
iex> [2 | _] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

# Tuples
iex> {:ok, value} = {:ok, "Successful!"}
{:ok, "Successful!"}
iex> value
"Successful!"
iex> {:ok, value} = {:error}
** (MatchError) no match of right hand side value: {:error}
```

## Pin operator

Kita baru saja pelajari bahwa operator pencocokan melakukan assignment ketika sisi kiri pencocokan berisi variabel. Dalam beberapa kasus perilaku ini, variable rebinding, tidak diinginkan. Untuk situasi semacam ini, kita punya pin operator: `^`.

Ketika kita melakukan pin sebuah variabel kita mencocokkan terhadap value yang ada dan bukannya melakukan rebinding terhadap value yang baru. Mari lihat bagaimana ini terjadi:

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

Elixir 1.2 menambahkan dukungan pada pin dalam key dari map dan klausa fungsi:

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

Sebuah contoh pinning dalam klausa fungsi:

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
