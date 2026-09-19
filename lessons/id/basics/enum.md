%{
  version: "1.9.3",
  title: "Enum",
  excerpt: """
  Sekumpulan algoritma untuk melakukan enumerasi atas enumerables.
  """
}
---

## Enum

Modul `Enum` mencakup lebih dari 70 fungsi untuk bekerja pada enumerables.
Semua koleksi yang sudah kita pelajari dalam [pelajaran sebelumnya](/id/lessons/basics/collections), dengan pengecualian tuple, adalah enumerables.

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

Dengan ini, jelas bahwa kita memiliki sejumlah fungsionalitas yang sangat banyak, dan itu semua bukan tanpa alasan.
Enumerasi adalah inti dari pemrograman fungsional, dan dikombinasikan dengan fasilitas lain Elixir, hal itu dapat sangat membantu para pengembang.

## Fungsi-fungsi umum

Untuk daftar lengkap fungsi (functions) silahkan kunjungi dokumentasi resmi [`Enum`](https://hexdocs.pm/elixir/Enum.html); untuk enumerasi lazy gunakan modul [`Stream`](https://hexdocs.pm/elixir/Stream.html).

### all?

Ketika menggunakan `all?/2`, dan sebagian besar `Enum`, kita menyediakan sebuah fungsi untuk diterapkan ke item koleksi kita. 
Dalam kasus `all?/2`, seluruh koleksi harus dievaluasi menjadi `true`, jika tidak, maka `false` akan dikembalikan:

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

Tidak seperti di atas, `any?` akan mengembalikan `true` jika setidaknya salah satu item bernilai `true`:

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk_every

Jika anda perlu memecah koleksi menjadi kelompok-kelompok yang lebih kecil, `chunk_every/2` adalah fungsi yang dibutuhkan:

```elixir
iex> Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

Ada beberapa opsi untuk `chunk_every/4` tapi kita tidak akan membahas lebih dalam, lihat [`dokumentasi resmi dari fungsi ini`](https://hexdocs.pm/elixir/Enum.html#chunk_every/4) untuk belajar lebih lanjut.

### chunk_by

Jika kita perlu mengelompokkan koleksi kita berdasarkan sesuatu selain ukuran, kita dapat gunakan fungsi `chunk_by/2`.
Fungsi ini menerima enumerable dan sebuah fungsi, dan ketika nilai kembalian fungsi tersebut berubah, sebuah kelompok baru akan dimulai untuk penciptaan kelompok selanjutnya.
Dalam contoh di bawah ini, setiap string dengan panjang yang sama dikelompokkan sampai kita bertemu string dengan panjang yang berbeda:

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
iex> Enum.chunk_by(["one", "two", "three", "four", "five", "six"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"], ["six"]]
```

### map_every

Terkadang memecah koleksi menjadi bagian-bagian kecil tidak cukup untuk apa yang kita butuhkan.
Jika ini kasusnya, `map_every/3` bisa sangat berguna untuk mengambil setiap item `nth` (ke-n), selalu mengambil yang pertama.

```elixir
# Terapkan fungsi setiap tiga item
iex> Enum.map_every([1, 2, 3, 4, 5, 6, 7, 8], 3, fn x -> x + 1000 end)
[1001, 2, 3, 1004, 5, 6, 1007, 8]
```

### each

Jika kita perlu melakukan iterasi atas sebuah collection tanpa menghasilkan sebuah nilai baru, untuk kasus ini kita gunakan `each/2`:

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
:ok
```

__Catatan__: Fungsi `each/2` mengembalikan atom `:ok`.

### map

Untuk menerapkan fungsi kita terhadap setiap item dan menghasilkan sebuah koleksi baru, lihatlah fungsi `map/2`:

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

`min/2` melakukan hal yang sama, tetapi jika enumerable kosong, itu memungkinkan kita menentukan fungsi untuk menghasilkan nilai terkecil.

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

`max/2` adalah padanan dari `max/1`, sebagaimana `min/2` adalah padanan dari `min/1`:

```elixir
iex> Enum.max([], fn -> :bar end)
:bar
```

### filter

Fungsi `filter/2` memungkinkan kita menyaring koleksi agar hanya menyertakan elemen-elemen yang menghasilkan `true` saat dievaluasi menggunakan fungsi yang disediakan.

```elixir
iex> Enum.filter([1, 2, 3, 4], fn(x) -> rem(x, 2) == 0 end)
[2, 4]
```

### reduce

Dengan `reduce/3` kita dapat menyaring koleksi kita menjadi sebuah nilai tunggal.
Untuk melakukan ini kita menyediakan akumulator opsional (`10` dalam contoh ini) untuk dimasukkan ke dalam fungsi kita; jika tidak ada akumulator yang disediakan, elemen pertama dari enumurable yang digunakan sebagai akumulator awal, dan fungsi memproses elemen yang tersisa:

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16

iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6

iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
```

### sort

Mengurutkan koleksi bisa dilakukan dengan tidak hanya satu, melainkan dua, fungsi pengurutan.

`sort/1` menggunakan [istilah pengurutan Erlang](http://erlang.org/doc/reference_manual/expressions.html#term-comparisons) untuk menentukan urutan yang diurutkan:

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

Sedangkan `sort/2` mengizinkan kita untuk menyediakan sebuah fungsi pengurutan kita sendiri:

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

Kita dapat menggunakan `uniq/1` untuk membuang duplikasi dari enumerables kita:

```elixir
iex> Enum.uniq([1, 2, 3, 2, 1, 1, 1, 1, 1])
[1, 2, 3]
```

### uniq_by

`uniq_by/2` juga membuang duplikasi dari enumerables, tapi memungkinkan kita untuk menyediakan fungsi untuk melakukan perbandingan keunikan.

```elixir
iex> Enum.uniq_by([%{x: 1, y: 1}, %{x: 2, y: 1}, %{x: 3, y: 3}], fn coord -> coord.y end)
[%{x: 1, y: 1}, %{x: 3, y: 3}]
```

## Enum menggunakan operator Tangkap (&)

Banyak fungsi-fungsi dalam modul Enum di Elixir menerima fungsi anonim sebagai argumen untuk digunakan pada tiap iterable dari enumerables yang dikirim.

Fungsi anonim tersebut biasanya ditulis secara singkat menggunakan operator Tangkap (&).

Berikut adalah beberapa contoh untuk menunjukkan bagaimana operator Tangkap dapat diimplementasikan dengan modul Enum.
Tiap versi memiliki fungsionalitas yang setara.

### Menggunakan operator capture dengan fungsi anonim

Di bawah ini adalah contoh tipikal dari sintaks standar ketika mengirim sebuah fungsi anonim ke `Enum.map/2`.

```elixir
iex> Enum.map([1,2,3], fn number -> number + 3 end)
[4, 5, 6]
```

Sekarang kita pakai operator Tangkap (&); menangkap setiap iterasi dari sebuah daftar angka ([1,2,3]) dan menetapkan tiap iterasi ke variabel &1 saat dikirim ke fungsi pemetaan.

```elixir
iex> Enum.map([1,2,3], &(&1 + 3))
[4, 5, 6]
```

Cara ini dapat diubah lebih lanjut dengan memasukkan fungsi anonim dengan operator tangkap di atas ke dalam sebuah variabel dan menggunakannya di fungsi `Enum.map/2`.

```elixir
iex> plus_three = &(&1 + 3)
iex> Enum.map([1,2,3], plus_three)
[4, 5, 6]
```

### Menggunakan operator tangkap dengan fungsi bernama

Pertama kita buat fungsi bernama  (named function) dan memanggilnya di dalam fungsi anonim yang didefinisikan di `Enum.map/2`.

```elixir
defmodule Adding do
  def plus_three(number), do: number + 3
end

iex>  Enum.map([1,2,3], fn number -> Adding.plus_three(number) end)
[4, 5, 6]
```

Kemudian kita bisa refactor menggunakan operator Tangkap.

```elixir
iex> Enum.map([1,2,3], &Adding.plus_three(&1))
[4, 5, 6]
```

Untuk sintaks paling ringkas, kita dapat memanggil fungsi bernama (named function) tanpa secara eksplisit menangkap variabel tersebut.

```elixir
iex> Enum.map([1,2,3], &Adding.plus_three/1)
[4, 5, 6]
```
