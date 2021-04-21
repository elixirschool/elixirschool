%{
  version: "0.9.0",
  title: "Comprehension",
  excerpt: """
  'List comprehension' ialah 'syntactic sugar'(sintaks untuk memudahkan pembacaan dan penjelasan sesuatu topik) untuk menggelung 'enumerable' di dalam Elixir.  Di dalam pelajaran ini kita akan melihat bagaimana kita boleh menggunakan 'comprehension' untuk lelaran(iteration) dan penjanaan.
  """
}
---

## Asas

Pada kebanyakan masa 'comprehension' boleh digunakan untuk menghasilkan kenyataan-kenyataan yang lebih ringkas untuk lelaran `Enum` dan `Stream`.  Mari mulakan dengan melihat satu 'comprehension' mudah dan leraikan ia satu persatu:

```elixir
iex> list = [1, 2, 3, 4, 5]
iex> for x <- list, do: x*x
[1, 4, 9, 16, 25]
```

Perkara pertama yang dapat kita lihat ialah penggunaan `for` dan satu penjana.  Apa itu penjana? Penjana adalah ungkapan-ungkapan `x <- [1, 2, 3, 4]` yang dijumpai di dalam 'list comprehension', mereka bertanggungjawab untuk menjana nilai-nilai seterusnya.

'Comprehension' tidak hanya terhad kepada list, ia boleh digunakan dengan mana-mana enumerable:

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

Sebagaimana yang anda mungkin perasan, penjana bergantung kepada pemadanan corak untuk memadankan kumpulan input dengan pembolehubah sebelah kiri.  Jika tiada padanan dapat dilakukan, nilai itu diabaikan:

```elixir
iex> for {:ok, val} <- [ok: "Hello", error: "Unknown", ok: "World"], do: val
["Hello", "World"]
```

Pelbagai penjana juga boleh digunakan, lebih kurang sama dengan gelungan bersarang:

```elixir
iex> list = [1, 2, 3, 4]
iex> for n <- list, times <- 1..n do
...>   String.duplicate("*", times)
...> end
["*", "*", "**", "*", "**", "***", "*", "**", "***", "****"]
```

Untuk memberikan gambaran yang lebih baik tentang gelungan yang sedang berjalan, mari kita gunakan `IO.puts` untuk memaparkan dua nilai janaan:

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

List comprehensions adalah 'syntactic sugar' dan sepatutnya hanya digunakan apabila sesuai.

## Tapisan

Anda boleh anggapkan tapisan(filter) sebagai sejenis klausa kawalan untuk 'comprehension'.  Apabila satu nilai yang telah ditapis memulangkan nilai `false` atau `nil` ianya diabaikan dari list muktamad.  Mari gelungkan satu julat dan hanya pedulikan tentang nombor genap:

```elixir
iex> for x <- 1..10, is_even(x), do: x
[2, 4, 6, 8, 10]
```

Seperti dengan penjana, kita boleh gunakan pelbagai tapisan.  Mari proses julat kita dan tapiskan nilai-nilai ganjil dan tidak boleh dibahagikan dengan 3 tanpa meninggalkan baki:

```elixir
iex> for x <- 1..100,
...>   is_even(x),
...>   rem(x, 3) == 0, do: x
[6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 78, 84, 90, 96]
```

## Menggunakan `:into`

Bagaimana pula jika kita mahu menghasilkan sesuatu selain dari list?  Gunakan pilihan `:into` untuk lakukannya!  Sebagai satu peraturan am, `:into` menerima apa-apa struktur yang mengimplementasi protokol 'Collectable'.

Dengan menggunakan `:into`, mari buat satu map dari satu list katakunci:

```elixir
iex> for {k, v} <- [one: 1, two: 2, three: 3], into: %{}, do: {k, v}
%{one: 1, three: 3, two: 2}
```

Oleh sebab 'bitstring' adalah 'enumerable' kita boleh gunakan 'list comprehension' dan `:into` untuk membuat string:

```elixir
iex> for c <- [72, 101, 108, 108, 111], into: "", do: <<c>>
"Hello"
```

Itu sahaja!  'List comprehension' adalah cara mudah untuk meringkaskan lelarkan sesatu 'collection'.
