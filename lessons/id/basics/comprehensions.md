%{
  version: "1.1.1",
  title: "Comprehensions",
  excerpt: """
  List comprehension adalah sintaksis yang disederhanakan untuk melakukan perulangan melalui enumerable di Elixir.
  Dalam pelajaran ini, kita akan melihat bagaimana kita dapat menggunakan comprehension untuk iterasi dan generasi.
  """
}
---

## Dasar

Comprehension sering kali digunakan untuk menghasilkan pernyataan yang lebih ringkas untuk iterasi `Enum` dan `Stream`.
Mari mulai dengan melihat sebuah comprehension dan kemudian menguraikannya:

```elixir
iex> list = [1, 2, 3, 4, 5]
iex> for x <- list, do: x*x
[1, 4, 9, 16, 25]
```

Hal pertama yang kita perhatikan adalah penggunaan `for` dan generator.
Apa itu generator?
Generator adalah ekspresi `x <- [1, 2, 3, 4]` yang ditemukan dalam list comprehension.
Generator bertanggung jawab untuk menghasilkan nilai berikutnya.

Untungnya, comprehension tidak terbatas pada list; bahkan, comprehension dapat bekerja dengan enumerable apa pun:

```elixir
# Keyword Lists
iex> for {_key, val} <- [one: 1, two: 2, three: 3], do: val
[1, 2, 3]

# Maps
iex> for {k, v} <- %{"a" => "A", "b" => "B"}, do: {k, v}
[{"a", "A"}, {"b", "B"}]

# Binaries
iex> for <<c <- "hello">>, do: <<c>>
["h", "e", "l", "l", "o"]
```

Seperti banyak hal lainnya di Elixir, generator mengandalkan pencocokan pola untuk membandingkan himpunan inputnya dengan variabel di sisi kiri.
Jika tidak ada kecocokan, nilainya akan diabaikan:

```elixir
iex> for {:ok, val} <- [ok: "Hello", error: "Unknown", ok: "World"], do: val
["Hello", "World"]
```

Dimungkinkan untuk menggunakan beberapa generator, mirip dengan perulangan bertingkat:

```elixir
iex> list = [1, 2, 3, 4]
iex> for n <- list, times <- 1..n do
...>   String.duplicate("*", times)
...> end
["*", "*", "**", "*", "**", "***", "*", "**", "***", "****"]
```

Untuk lebih jelas menggambarkan perulangan yang terjadi, mari gunakan `IO.puts` untuk menampilkan dua nilai yang dihasilkan:

```elixir
iex> for n <- list, times <- 1..n, do: IO.puts "#{n} - #{times}"
1 - 1
2 - 1
2 - 2
3 - 1
3 - 2
3 - 3
4 - 1
4 - 2
4 - 3
4 - 4
```

List comprehension adalah bentuk penyederhanaan sintaksis dan sebaiknya hanya digunakan bila sesuai.

## Filter

Anda dapat menganggap filter sebagai semacam Klausa Penjaga untuk Comprehensions.
Ketika nilai yang difilter mengembalikan `false` atau `nil`, nilai tersebut dikecualikan dari daftar akhir.
Mari kita lakukan perulangan pada suatu rentang dan hanya memperhatikan angka genap.
Kita akan pakai fungsi `is_even/1` dari modul Integer untuk memeriksa apakah suatu nilai genap atau tidak.

```elixir
import Integer
iex> for x <- 1..10, is_even(x), do: x
[2, 4, 6, 8, 10]
```

Seperti generator, kita dapat menggunakan beberapa filter.
Mari kita perluas rentang kita dan kemudian saring hanya untuk nilai-nilai yang genap dan habis dibagi 3.

```elixir
import Integer
iex> for x <- 1..100,
...>   is_even(x),
...>   rem(x, 3) == 0, do: x
[6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 78, 84, 90, 96]
```

## Menggunakan :into

Bagaimana jika kita ingin menghasilkan sesuatu selain daftar?
Dengan opsi `:into`, kita bisa melakukannya!
Sebagai aturan umum, `:into` menerima struktur apa pun yang mengimplementasikan protokol `Collectable`.

Dengan menggunakan `:into`, mari buat peta dari daftar kata kunci:

```elixir
iex> for {k, v} <- [one: 1, two: 2, three: 3], into: %{}, do: {k, v}
%{one: 1, three: 3, two: 2}
```

Karena biner adalah Collectable, kita dapat menggunakan list comprehension dan `:into` untuk membuat string:

```elixir
iex> for c <- [72, 101, 108, 108, 111], into: "", do: <<c>>
"Hello"
```

Selesai!
List comprehension adalah cara lain untuk mengulang koleksi secara ringkas.
