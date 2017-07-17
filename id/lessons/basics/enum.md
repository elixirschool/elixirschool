---
version: 0.9.0
title: Enum
---

Sekumpulan algoritma untuk melakukan enumerasi atas collection.

{% include toc.html %}

## Enum

Modul `Enum` berisi lebih dari seratus fungsi untuk bekerja dengan koleksi yang sudah kita pelajari di pelajaran sebelumnya.

Pelajaran ini akan hanya mencakup sebagian dari fungsi yang ada, untuk melihat daftar fungsi yang lengkap kunjungi dokumentasi resmi [`Enum`](https://hexdocs.pm/elixir/Enum.html); untuk enumerasi yang lazy gunakan modul [`Stream`](https://hexdocs.pm/elixir/Stream.html).


### all?

Ketika menggunakan `all?`, dan mayoritas dari `Enum`, kita memberikan sebuah fungsi untuk diterapkan ke isi dari collection kita. Dalam kasus `all?`, keseluruhan isi collection harus menghasilkan `true`, jika tidak maka hasilnya adalah `false`:

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

Tidak seperti di atas, `any?` akan menghasilkan `true` jika setidaknya salah satu item menghasilkan `true`:

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk

Jika anda perlu memecah collection jadi kelompok-kelompok yang lebih kecil, `chunk` adalah fungsi yang dibutuhkan:

```elixir
iex> Enum.chunk([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

Ada beberapa opsi untuk `chunk` tapi kita tidak akan membahas lebih dalam, lihatlah [`chunk/2`](https://hexdocs.pm/elixir/Enum.html#chunk/2) di dokumentasi resmi untuk belajar lebih jauh.

### chunk_by

Jika kita butuh mengelompokkan collection kita berdasar selain ukuran, kita dapat gunakan fungsi `chunk_by/2`. `chunk_by/2` menerima sebuah enumerable dan sebuah fungsi, yang jika hasil pemanggilan fungsi tersebut berubah maka sebuah kelompok baru akan dibuat:

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five", "six"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"], ["six"]]
```

### each

Jika kita perlu melakukan iterasi atas sebuah collection tanpa menghasilkan sebuah value baru, kita gunakan `each`:

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
:ok
```

__Catatan__: Fungsi `each` mengembalikan atom `:ok`.

### map

Untuk menerapkan fungsi kita terhadap setiap item dan menghasilkan sebuah collection baru, lihatlah fungsi `map`:

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

Menemukan nilai terkecil dalam collection kita:

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

### max

Menemukan nilai terbesar dalam collection kita:

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

### reduce

Dengan `reduce` kita dapat memeras collection kita menjadi sebuah value tunggal. Untuk melakukan ini kita memasukkan sebuah akumulator yang opsional (`10` dalam contoh ini) untuk dimasukkan ke dalam fungsi kita; jika tidak ada akumulator diberikan maka value pertama yang digunakan:

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16
iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6
iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
```

### sort

Mengurutkan collection kita menjadi mudah dengan adanya tidak hanya satu, melainkan dua, fungsi `sort`. Yang pertama menggunakan pengurutan (ordering) dari Elixir untuk menentukan urutan:

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

Pilihan yang kedua mengijinkan kita memberikan fungsi untuk mengurutkan:

```elixir
# with our function
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# without
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq

Kita dapat menggunakan `uniq` untuk membuang duplikasi dari collection kita:

```elixir
iex> Enum.uniq([1, 2, 2, 3, 3, 3, 4, 4, 4, 4])
[1, 2, 3, 4]
```
