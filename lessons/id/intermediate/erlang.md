%{
  version: "1.0.4",
  title: "Interoperabilitas dengan Erlang",
  excerpt: """
  Salah satu keuntungan tambahan dari membangun di atas VM Erlang (BEAM) adalah banyaknya pustaka yang tersedia untuk kita pakai.
  Interoperabilitas memungkinkan kita memanfaatkan pustaka-pustaka tersebut dan juga pustaka standar Erlang dari kode Elixir kita.
  Dalam pelajaran ini kita akan melihat bagaimana mengakses fungsi dalam librari standar dan juga paket Erlang pihak ketiga.
  """
}
---

## Pustaka Standar

Pustaka standar Erlang yang luas dapat diakses dari kode Elixir mana pun dalam aplikasi kita.
Modul Erlang direpresentasikan oleh atom huruf kecil seperti `:os` dan `:timer`.

Mari gunakan `:timer.tc` untuk mengukur waktu eksekusi fungsi tertentu:

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

Pada pelajaran sebelumnya kita telah membahas Mix dan mengelola dependensi kita.
Menambahkan pustaka Erlang bekerja dengan cara yang sama.
Jika pustaka Erlang belum diunggah ke [Hex](https://hex.pm), Anda dapat merujuk ke repositori git sebagai gantinya:

```elixir
def deps do
  [{:png, github: "yuce/png"}]
end
```

Sekarang kita bisa mengakses pustaka Erlang tersebut:

```elixir
png =
  :png.create(%{:size => {30, 30}, :mode => {:indexed, 8}, :file => file, :palette => palette})
```

## Perbedaan yang Nampak

Sekarang setelah kita tahu cara menggunakan Erlang, kita perlu membahas beberapa kendala yang muncul terkait interoperabilitas Erlang.

### Atom

Atom Erlang terlihat sangat mirip dengan atom Elixir tanpa tanda titik dua (`:`).
Atom direpresentasikan oleh string huruf kecil dan garis bawah:

Elixir:

```elixir
:example
```

Erlang:

```erlang
example.
```

### String

Dalam Elixir, ketika kita berbicara tentang string, yang kita maksud adalah biner yang dikodekan UTF-8.
Dalam Erlang, string masih menggunakan tanda kutip ganda tetapi merujuk pada daftar karakter (char list):

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

Penting untuk dicatat bahwa banyak pustaka Erlang lama mungkin tidak mendukung biner, jadi kita perlu mengkonversi string Elixir ke daftar karakter.
Untungnya, ini mudah dilakukan dengan fungsi `to_charlist/1`:

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

iex> "Hello World" |> to_charlist() |> :string.words
2
```

### Variabel

Dalam Erlang, variabel diawali dengan huruf kapital dan pengikatan ulang tidak diperbolehkan.

Elixir:

```elixir
iex> x = 10
10

iex> x = 20
20

iex> x1 = x + 10
30
```

Erlang:

```erlang
1> X = 10.
10

2> X = 20.
** exception error: no match of right hand side value 20

3> X1 = X + 10.
20
```

Selesai! Memanfaatkan Erlang dari dalam aplikasi Elixir kita secara efektif melipatgandakan jumlah pustaka yang tersedia bagi kita.
