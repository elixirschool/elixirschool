%{
  version: "0.9.1",
  title: "Interoperabilitas dengan Erlang",
  excerpt: """
  Salah satu keuntungan tambahan dari membangun di atas VM Erlang adalah banyaknya librari yang sudah ada yang bisa kita pakai. Interoperabilitas memungkinkan kita memanfaatkan librari-librari tersebut dan juga librari standar Erlang dari code Elixir kita.  Dalam pelajaran ini kita akan melihat bagaimana mengakses fungsi dalam librari standar dan juga paket Erlang buatan pihak lain (third party).
  """
}
---

## Librari Standar

Librari standar Erlang yang luas itu dapat diakses dari code Elixir di dalam aplikasi kita.  Modul-modul Erlang direpresentasikan dengan atom huruf kecil seperti `:os` dan `:timer`.

Mari gunakan `:timer.tc` untuk mengukur waktu eksekusi dari sebuah fungsi yang ada:

```elixir
defmodule Example do
  def timed(fun, args) do
    {time, result} = :timer.tc(fun, args)
    IO.puts("Time: #{time} μs")
    IO.puts("Result: #{result}")
  end
end

iex> Example.timed(fn (n) -> (n * n) * n end, [100])
Time: 8 μs
Result: 1000000
```

Untuk daftar lengkap modul yang tersedia, lihat [Erlang Reference Manual](http://erlang.org/doc/apps/stdlib/).

## Paket Erlang

Dalam pelajaran sebelumnya kita membahas Mix dan menata dependensi kita.  Librari Erlang juga dengan cara yang sama.  Jika librari Erlang tersebut belum dimasukkan ke [Hex](https://hex.pm) anda bisa merujuk ke repositori git:

```elixir
def deps do
  [{:png, github: "yuce/png"}]
end
```

Sekarang kita bisa mengakses librari Erlang kita:

```elixir
png =
  :png.create(%{:size => {30, 30}, :mode => {:indexed, 8}, :file => file, :palette => palette})
```

## Perbedaan yang Nampak

Sekarang setelah kita tahu cara menggunakan Erlang kita harus membahas sebagian kejutan (gotcha) yang ada.

### Atom

Atom Erlang sangat mirip atom Elixir tanpa tanda titik dua (`:`).  Atom-atom Erlang direpresentasikan dengan string huruf kecil dan garis bawah:

Elixir:

```elixir
:example
```

Erlang:

```erlang
example.
```

### String

Dalam Elixir ketika kita berbicara tentang string yang kita maksud adalah binari yang dienkode dengan UTF-8.  Dalam Erlang, string tetap pakai kutip ganda tetapi merujuk ke char list:

Elixir:

```elixir
iex> is_list('Example')
true
iex> is_list("Example")
false
iex> is_binary("Example")
true
iex> <<"Example">> === "Example"
true
```

Erlang:

```erlang
1> is_list('Example').
false
2> is_list("Example").
true
3> is_binary("Example").
false
4> is_binary(<<"Example">>).
true
```

Adalah penting dicatat bahwa banyak librari Erlang yang lawas mungkin tidak mendukung binary sehingga kita perlu mengkonversi string Elixir ke char list.  Untungnya hal ini mudah dikerjakan dengan fungsi `to_charlist/1`:

```elixir
iex> :string.words("Hello World")
** (FunctionClauseError) no function clause matching in :string.strip_left/2

    The following arguments were given to :string.strip_left/2:

        # 1
        "Hello World"

        # 2
        32

    (stdlib) string.erl:1661: :string.strip_left/2
    (stdlib) string.erl:1659: :string.strip/3
    (stdlib) string.erl:1597: :string.words/2

iex> "Hello World" |> to_charlist |> :string.words
2
```

### Variabel

Elixir:

```elixir
iex> x = 10
10

iex> x1 = x + 10
20
```

Erlang:

```erlang
1> X = 10.
10

2> X1 = X + 1.
11
```

Selesai!  Menggunakan Erlang dari dalam aplikasi Elixir kita adalah mudah dan secara efektif melipatgandakan jumlah librari yang tersedia untuk kita.
