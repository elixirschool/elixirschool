%{
  version: "1.1.1",
  title: "Pencocokan Pola",
  excerpt: """
  Pencocokan pola adalah bagian penting dari Elixir. Ini memungkinkan kita untuk mencocokkan nilai, struktur data, dan bahkan fungsi.
  Dalam pelajaran ini kita akan mulai melihat bagaimana pencocokan pola digunakan.
  """
}
---

## Operator Pencocokan

Apa kamu siap menghadapi kejutan? Di Elixir, operator `=` sebetulnya adalah operator pencocokan (match operator), dapat disamakan dengan tanda sama dengan dalam aljabar. Saat digunakan, operator ini memperlakukan ekspresi sebagai sebuah persamaan dan membuat Elixir mencoba mencocokkan nilai di sisi kiri dengan nilai di sisi kanan. Jika pencocokan berhasil, ekspresi tersebut mengembalikan nilai persamaan. Jika tidak, ia akan melempar kesalahan. Mari kita lihat:

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

Mari mencobanya dengan beberapa koleksi yang sudah kita kenal:

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

## Operator Pin

Operator pencocokan melakukan penugasan ketika sisi kiri pencocokan mencakup sebuah variabel.
Dalam beberapa kasus, perilaku pengikatan ulang variabel ini tidak diinginkan.
Untuk situasi semacam ini, kita punya pin operator: `^`.

Ketika sebuah variabel diberi operator pin, Elixir akan mencocokkan nilai yang sudah, bukan mengikat ulang variabel tersebut ke nilai baru.
Mari kita lihat bagaimana cara kerjanya:

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

Sejak Elixir 1.2, operator pin juga dapat digunakan pada key map dan klausa fungsi:

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

Contoh penggunaan operator pin dalam klausa fungsi:

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
iex> greeting
"Hello"
```
Klausa pertama fungsi menggunakan operator pin untuk mencocokkan nilai yang sudah ada dari `greeting`. Ini berarti jika `greeting` adalah "Hello", maka akan menggunakan klausa pertama, jika tidak maka akan menggunakan klausa kedua.

Perhatikan pada contoh `"Mornin'"` bahwa penugasan ulang `greeting` menjadi `"Mornin'"` hanya terjadi di dalam fungsi. Di luar fungsi, `greeting` tetap `"Hello"`.
