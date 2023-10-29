%{
  version: "1.9.1",
  title: "Enum",
  excerpt: """
  Sekumpulan algoritma untuk melakukan enumerasi atas enumerables.
  """
}
---

## Enum

Modul `Enum` mencakup lebih dari 70 fungsi untuk bekerja pada enumrables. Semua koleksi yang sudah kita pelajari dalam [pelajaran sebelumnya](/id/lessons/basics/collections), dengan pengecualian tuple, adalah enumerables.

Pelajaran ini hanya akan mencakup sebagian dari fungsi yang ada, akan tetapi kita sebenarnya dapat memeriksa semuanya sendiri.
Mari lakukan sedikit eksperimen pada IEx.

```elixir
iex> Enum.__info__(:functions) |> Enum.each(fn({function, arity}) ->
...>   IO.puts "#{function}/#{arity}"
...> end)
all?/1
all?/2
any?/1
any?/2
at/2
at/3
...
```

Dengan ini, jelas bahwa kita memiliki sejumlah fungsionalias yang sangat banyak, dan itu semua bukan tanpa alasan. Enumerasi adalah inti dari pemrograman fungsional, dan dikombinasikan dengan fasilitas lain Elixir, hal itu dapat sangat membantu para pengembang (developer).

## Fungsi-fungsi umum

Untuk daftar lengkap fungsi (functions) silahkan kunjungi dokumentasi resmi [`Enum`](https://hexdocs.pm/elixir/Enum.html); untuk enumerasi lazy gunakan modul [`Stream`](https://hexdocs.pm/elixir/Stream.html).

### all?

Ketika menggunakan `all?/2`, dan banyak `Enum`, kita menyediakan sebuah fungsi untuk diterapkan ke item koleksi kita. Dalam kasus `all?/2`, keseluruhan koleksi harus mengevaluasi `true` jika tidak `false` akan dikembalikan:

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

### chunk_every

Jika anda perlu memecah collection jadi kelompok-kelompok yang lebih kecil, `chunk_every/2` adalah fungsi yang dibutuhkan:

```elixir
iex> Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

Ada beberapa opsi untuk `chunk_every/4` tapi kita tidak akan membahas lebih dalam, lihat [`dokumentasi resmi dari fungsi ini`](https://hexdocs.pm/elixir/Enum.html#chunk_every/4) untuk belajar lebih jauh.

### chunk_by

Jika kita butuh mengelompokkan koleksi kita berdasarkan selain ukuran, kita dapat gunakan fungsi `chunk_by/2`. Fungsi ini membutuhkan enumerable dan sebuah fungsi, dan ketika hasil kembali fungsi tersebut berubah, sebuah kelompok baru dimulai untuk penciptaan selanjutnya. Pada contoh di bawah ini, tiap string dengan panjang yang sama dikelompokkan sampai kita bertemu string dengan panjang yang berbeda:

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
iex> Enum.chunk_by(["one", "two", "three", "four", "five", "six"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"], ["six"]]
```

### map_every

Terkadang membingkah (chungking) keluar sebuah koleksi tidak cukup untuk apa yang kita butuhkan. Jika hal tersebut pada kasus ini, `map_every/3` dapat sangatlah berguna untuk mengenai setiap item `nth`, selalu mengenai yang pertama.

```elixir
# Menerapkan fungsi setiap tiga item
iex> Enum.map_every([1, 2, 3, 4, 5, 6, 7, 8], 3, fn x -> x + 1000 end)
[1001, 2, 3, 1004, 5, 6, 1007, 8]
```

### each

Jika kita perlu melakukan iterasi atas sebuah collection tanpa menghasilkan sebuah value baru, kita gunakan `each/2`:

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
:ok
```

__Catatan__: Fungsi `each/2` mengembalikan atom `:ok`.

### map

Untuk menerapkan fungsi kita terhadap setiap item dan menghasilkan sebuah collection baru, lihatlah fungsi `map/2`:

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

`min/1` menemukan nilai terkecil dalam koleksi:

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

`min/2` juga melakukan hal yang sama, namun jika enumerable kosong, itu memperbolehkan kita menentukan fungsi untuk menghasilkan nilai terkecil.

```elixir
iex> Enum.min([], fn -> :foo end)
:foo
```

### max

`max/1` mengembalikan nilai maksimal dalam koleksi:

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

`max/2` adalah `max/1` apa `min/2` ke `min/1`:

```elixir
Enum.max([], fn -> :bar end)
:bar
```

### filter

Fungsi `filter/2` memungkinkan kita menyaring collection untuk hanya berisi elemen-elemen yang menghasilkan `true` saat dievaluasi menggunakan fungsi yang disediakan.

```elixir
iex> Enum.filter([1, 2, 3, 4], fn(x) -> rem(x, 2) == 0 end)
[2, 4]
```

### reduce

Dengan `reduce/3` kita dapat memeras collection kita menjadi sebuah nilai tunggal. Untuk melakukan ini kita memasukkan sebuah akumulator yang opsional (`10` dalam contoh ini) untuk dimasukkan ke dalam fungsi kita; jika tidak ada akumulator diberikan maka value pertama yang digunakan:

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16

iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6

iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
```

### sort

Mengurutkan collection kita menjadi mudah dengan adanya tidak hanya satu, melainkan dua, fungsi pengurutan.

`sort/1` menggunakan istilah Erlang [term ordering](http://erlang.org/doc/reference_manual/expressions.html#term-comparisons) untuk menentukan urutan yang diurutkan:

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

Sedangkan `sort/2` mengijinkan kita untuk menyediakan sebuah fungsi pengurutan kita sendiri:

```elixir
# dengan fungsi kita
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# tanpa fungsi kita
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

Untuk kemudahan, `sort/2` membolehkan kita untuk memakai `:asc` atau `:desc` sebagai fungsi pengurutan:

```elixir
Enum.sort([2, 3, 1], :desc)
[3, 2, 1]
```

### uniq

Kita dapat menggunakan `uniq_by/2` untuk membuang duplikasi dari enumerables kita:

```elixir
iex> Enum.uniq([1, 2, 3, 2, 1, 1, 1, 1, 1])
[1, 2, 3]
```
### uniq_by

`uniq_by/2` juga membuang duplikasi dari enumerables, tapi memungkinkan kita untuk menyediakan fungsi yang mengecek keunikan.

```elixir
iex> Enum.uniq_by([%{x: 1, y: 1}, %{x: 2, y: 1}, %{x: 3, y: 3}], fn coord -> coord.y end)
[%{x: 1, y: 1}, %{x: 3, y: 3}]
```

## Enum menggunakan operator Capture (&)

Banyak fungsi-fungsi di dalam modul Enum di Elixir menerima fungsi anonim sebagai argumen untuk digunakan pada tiap iterable dari enumerables yang dikirim.

Fungsi anonim tersebut biasanya ditulis secara singkat menggunakan operator Capture (&).

Berikut adalah beberapa contoh untuk menunjukkan bagaimana operator Capture dapat diimplementasikan dengan modul Enum.
Tiap versi memiliki fungsionalitas yang setara.

### Menggunakan operator capture dengan fungsi anonim

Di bawah ini adalah contoh tipikal dari sintaks standar ketika mengirim sebuah fungsi anonim ke `Enum.map/2`.

```elixir
iex> Enum.map([1,2,3], fn number -> number + 3 end)
[4, 5, 6]
```

Sekarang kita pakai operator capture (&); menangkap tiap iterasi dari sebuah daftar angka ([1,2,3]) dan memasukkan tiap iterasi ke variabel &1 saat dikirim ke fungsi pemetaan.

```elixir
iex> Enum.map([1,2,3], &(&1 + 3))
[4, 5, 6]
```

Cara ini dapat di-refactor lebih lanjut dengan memasukkan fungsi anonim dengan operator capture di atas ke dalam sebuah variabel dan menggunakannya di fungsi `Enum.map/2`.

```elixir
iex> plus_three = &(&1 + 3)
iex> Enum.map([1,2,3], plus_three)
[4, 5, 6]
```

### Menggunakan operator capture dengan named function

Pertama kita buat named function dan memanggilnya di dalam fungsi anonim yang didefinisikan di `Enum.map/2`.

```elixir
defmodule Adding do
def plus_three(number), do: number + 3
end

iex>  Enum.map([1,2,3], fn number -> Adding.plus_three(number) end)
[4, 5, 6]
```

Kemudian kita bisa refactor menggunakan operator capture.

```elixir
iex> Enum.map([1,2,3], &Adding.plus_three(&1))
[4, 5, 6]
```

Untuk sintaks paling ringkas, kita dapat memanggil named function tanpa menuliskan variabel capture (&1) secara eksplisit.

```elixir
iex> Enum.map([1,2,3], &Adding.plus_three/1)
[4, 5, 6]
```
