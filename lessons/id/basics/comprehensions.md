%{
  version: "0.9.0",
  title: "Comprehensions",
  excerpt: """
  List comprehension adalah pemanis sintaks (syntactic sugar) untuk menjalani enumerable di Elixir.  Dalam pelajaran ini kita akan melihat bagaimana kita bisa menggunakannya untuk iterasi dan pembuatan enumerable.
  """
}
---

## Dasar

Sering kali comprehension bisa digunakan untuk membuat statement yang lebih ringkas untuk iterasi `Enum` dan `Stream`.  Mari mulai dengan melihat sebuah comprehension sederhana dan kemudian memecahnya:

```elixir
iex> list = [1, 2, 3, 4, 5]
iex> for x <- list, do: x*x
[1, 4, 9, 16, 25]
```

Yang pertama kita sadari adalah penggunaan `for` dan sebuah generator.  Apa itu generator?  Generator adalah ekspresi serupa `x <- [1, 2, 3, 4]` yang ditemukan dalam list comprehension, dan berperan membuat nilai berikutnya.

Untungnya comprehension tidak hanya terbatas pada list, melainkan juga pada segala enumerable:

```elixir
# Keyword List
iex> for {_key, val} <- [one: 1, two: 2, three: 3], do: val
[1, 2, 3]

# Map
iex> for {k, v} <- %{"a" => "A", "b" => "B"}, do: {k, v}
[{"a", "A"}, {"b", "B"}]

# Binary
iex> for <<c <- "hello">>, do: <<c>>
["h", "e", "l", "l", "o"]
```

Sebagaimana yang anda mungkin sudah sadari, generator bergantung pada pencocokan pola (pattern matching) untuk membandingkan inputnya dengan variabel di sisi kiri.  Dalam kondisi sebuah match tidak ditemukan, value tersebut diabaikan:

```elixir
iex> for {:ok, val} <- [ok: "Hello", error: "Unknown", ok: "World"], do: val
["Hello", "World"]
```

Adalah mungkin untuk menggunakan generator rangkap (multiple), seperti loop bertingkat:

```elixir
iex> list = [1, 2, 3, 4]
iex> for n <- list, times <- 1..n do
...>   String.duplicate("*", times)
...> end
["*", "*", "**", "*", "**", "***", "*", "**", "***", "****"]
```

Untuk mengilustraksikan dengan lebih baik loop yang terjadi, mari gunakan `IO.puts` untuk menampilkan kedua value yang dihasilkan:

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

List comprehension adalah pemanis sintaks dan mestinya dipakai hanya jika dalam kondisi yang cocok.

## Filter

Anda bisa membayangkan filter sebagai semacam guard untuk comprehension.  Ketika sebuah value bernilai `false` atau `nil`, value tersebut dikecualikan dari list yang dihasilkan.  Mari lakukan loop atas sebuah range dan hanya perhatikan bilangan genap:

```elixir
iex> for x <- 1..10, is_even(x), do: x
[2, 4, 6, 8, 10]
```

Seperti generator, kita bisa gunakan filter rangkap.  Mari coba pada sebuah range dan membuang semua yang tidak genap dan tidak habis dibagi 3:

```elixir
iex> for x <- 1..100,
...>   is_even(x),
...>   rem(x, 3) == 0, do: x
[6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 78, 84, 90, 96]
```

## Menggunakan `:into`

Bagaimana jika kita ingin membuat sesuatu yang bukan list?  Dengan pilihan `:into` kita bisa.  Sebagai panduan umum, `:into` menerima segala struktur yang mengimplementasikan protokol `Collectable`.

Menggunakan `:into`, mari buat sebuah map dari sebuah keyword list:

```elixir
iex> for {k, v} <- [one: 1, two: 2, three: 3], into: %{}, do: {k, v}
%{one: 1, three: 3, two: 2}
```

Karena bitstring adalah enumerable kita bisa gunakan list comprehension dan `:into` untuk membuat string:

```elixir
iex> for c <- [72, 101, 108, 108, 111], into: "", do: <<c>>
"Hello"
```

List comprehension adalah sebuah cara yang mudah untuk mengiterasi atas berbagai collection dengan cara yang ringkas.
