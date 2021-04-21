%{
  version: "0.9.0",
  title: "Enum",
  excerpt: """
  Satu kumpulan algorithm untuk memproses satu persatu(enumerate) isi kandungan 'collection'.
  """
}
---

## Enum

Modul `Enum` mengandungi lebih dari satu ratus fungsi-fungsi untuk bekerja dengan 'collection' yang telah kita pelajari dalam pelajaran lepas.

Pelajaran ini cuma akan meliputi sedikit sahaja daripada fungsi-fungsi yang tersedia, untuk melihat fungsi-fungsi lengkap lawati [dokumentasi rasmi `Enum`](https://hexdocs.pm/elixir/Enum.html); untuk kaedah 'lazy enumeration' gunakan modul [`Stream`](https://hexdocs.pm/elixir/Stream.html).

### all?

Apabila menggunakan `all?`, dan sebahagian besar dari `Enum`, kita bekalkan satu fungsi untuk dilaksanakan ke atas item-item di dalam 'collection' kita.  Di dalam kes `all?`, keseluruhan 'collection' mesti dinilaikan kepada `true` jika tidak `false` akan dipulangkan.

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

Tidak seperti di atas, `any?` akan memulangkan `true` jika sekurang-kurangnya satu item di dalam 'collection' dinilaikan kepada `true`.

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk_every/2

Jika anda perlu untuk menceraikan 'collection' kepada kumpulan-kumpulan kecil, gunakan fungsi `chunk_every/2`:

```elixir
iex> Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

Terdapat beberapa pilihan untuk `chunk_every/2` tetapi kita tidak akan sebutkan di sini, lihat [dokumentasi rasmi `chunk_every/4`](https://hexdocs.pm/elixir/Enum.html#chunk_every/4) untuk maklumat lebih lanjut.

### chunk_by

Jika kita perlu untuk membuat pengasingan kepada 'collection' berdasarkan kepada kriteria selain dari saiz, kita boleh gunakan fungsi `chunk_by`:

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
```

### each

Jika perlu untuk memproses satu persatu elemen di dalam 'collection' tanpa menghasilkan nilai baru, kita akan gunakan `each`:

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
:ok
```

__Nota__: Fungsi `each` akan memulangkan atom `:ok`.

### map

Untuk melaksanakan fungsi kepada setiap item di dalam 'collection' dan menghasilkan satu 'collection' baru, gunakan fungsi `map`:

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

Untuk mencari nilai `min` di dalam 'collection':

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

### max

Untuk mencari nilai `max` di dalam 'collection':

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

### reduce

Dengan `reduce` kita boleh memampatkan 'collection' kepada satu nilai.  Untuk ini kita hantarkan satu 'accumulator' pilihan (`10` di dalam contoh di bawah) kepada fungsi; jika tiada 'accumulator' dibekalkan, nilai pertama akan digunakan:

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16
iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6
iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
```

### sort

Pengisihan(sorting) 'collection' dipermudahkan bukan dengan satu, tetapi dua fungsi `sort`.  Pilihan pertama yang disediakan kepada kita menggunakan tertiban istilah Elixir untuk menentukan susunan isihan:

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

Pilihan kedua membenarkan kita menyediakan satu fungsi isihan:

```elixir
# with our function
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# without
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq

Kita boleh gunakan `uniq` untuk menyingkirkan pertindanan daripada 'collection' kita:

```elixir
iex> Enum.uniq([1, 2, 2, 3, 3, 3, 4, 4, 4, 4])
[1, 2, 3, 4]
```
