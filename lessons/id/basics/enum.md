%{
  version: "1.9.2",
  title: "Enum",
  excerpt: """
  Sekumpulan Algoritma untuk Enumerasi atas Enumerable.
  """
}
---

## Gambaran Umum

Modul `Enum` memiliki lebih dari 70 fungsi untuk bekerja dengan koleksi enumerable.
Semua koleksi yang telah kita pelajari pada [pelajaran sebelumnya](/en/lessons/basics/collections) dengan pengecualian tuples adalah enumerable.

Pelajaran kali ini hanya akan membahas sebagian kecil dari fungsi-fungsi enumerable yang tersedia, namun kita dapat mencobanya sendiri.
Mari kita lakukan sebuah percobaan kecil di IEx.

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

Dengan menggunakan ini, kita bisa lihat bahwa banyak sekali fungsionalitas yang tersedia, dan itu ada alasan jelas di baliknya. Enumerasi adalah dasar dari pemrograman fungsional, dan jika digabungkan dengan kelebihan lain dari Elixir, ini bisa sangat membantu para developer.

## Fungsi-Fungsi Umum

For a full list of functions visit the official [`Enum`](https://hexdocs.pm/elixir/Enum.html) docs; for lazy enumeration use the [`Stream`](https://hexdocs.pm/elixir/Stream.html) module.

### all?

Ketika menggunakan `all?/2`, dan banyak fungsi dari Enum, kita memberikan sebuah fungsi yang akan diterapkan pada setiap item dalam koleksi. Pada kasus all?/2, seluruh koleksi harus menghasilkan nilai `true`, jika tidak, yang akan dikembalikan adalah `false`.

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

Tidak seperti fungsi di atas, `any?/2` akan mengembalikan `true` jika sekurang-kurangnya satu item yang dievaluasi di dalam koleksi bernilai `true`.

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk_every

Jika kamu ingin memecah koleksi menjadi beberapa grup yang lebih kecil, `chunk_every/2` adalah fungsi yang mungkin kamu cari:

```elixir
iex> Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

Ada beberapa opsi untuk `chunk_every/4` tetapi kita tidak akan membahasnya, silahkan cek [dokumentasi resmi fungsi ini](https://hexdocs.pm/elixir/Enum.html#chunk_every/4) untuk mempelajari lebih lanjut.

### chunk_by

Jika kita perlu mengelompokkan koleksi berdasarkan sesuatu selain ukurannya, kita bisa menggunakan fungsi `chunk_by/2`.
Fungsi ini menerima sebuah enumerable dan sebuah fungsi, lalu akan membuat grup baru setiap kali hasil dari fungsi tersebut berubah.
Pada contoh di bawah ini, setiap string dengan panjang yang sama dikelompokkan bersama hingga kita menemukan string dengan panjang yang berbeda, yang akan memulai grup baru.

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
iex> Enum.chunk_by(["one", "two", "three", "four", "five", "six"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"], ["six"]]
```

### map_every

Terkadang, membagi koleksi menjadi beberapa bagian saja tidak cukup untuk apa yang kita butuhkan. Jika itu terjadi, map_every/3 bisa sangat berguna untuk memproses setiap elemen ke-n, operasi ini selalu dimulai dari elemen pertama.

```elixir
# Apply function every three items
iex> Enum.map_every([1, 2, 3, 4, 5, 6, 7, 8], 3, fn x -> x + 1000 end)
[1001, 2, 3, 1004, 5, 6, 1007, 8]
```

### each

Terkadang, kita perlu melakukan iterasi pada sebuah koleksi tanpa menghasilkan nilai baru. Untuk kasus seperti ini, kita bisa menggunakan `each/2`.

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
:ok
```

__Catatan__: Fungsi `each/2` akan mengembalikan atom `:ok`.

### map

Untuk menerapkan fungsi kita ke setiap item dan menghasilkan koleksi baru, gunakan fungsi `map/2`.

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

Fungsi `min/1` berfungsi untuk mencari nilai minimal dalam koleksi:

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

Fungsi `min/2` juga melakukan hal yang sama, tetapi dalam kasus di mana koleksi kosong, kita bisa menentukan fungsi untuk membuat nilai minimum.

```elixir
iex> Enum.min([], fn -> :foo end)
:foo
```

### max

Fungsi `max/1` mengembalikan nilai maksimal dalam koleksi:

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

Fungsi `max/2` memiliki hubungan dengan `max/1` seperti halnya `min/2` dengan `min/1`:

```elixir
iex> Enum.max([], fn -> :bar end)
:bar
```

### filter

Fungsi `filter/2` memungkinkan kita menyaring koleksi sehingga hanya elemen-elemen yang menghasilkan `true` berdasarkan fungsi yang diberikan yang akan dikembalikan nilainya:

```elixir
iex> Enum.filter([1, 2, 3, 4], fn(x) -> rem(x, 2) == 0 end)
[2, 4]
```

### reduce

Dengan fungsi `reduce/3`, kita dapat menyederhanakan koleksi menjadi satu nilai.
Untuk melakukannya, kita memberikan akumulator opsional (`10` dalam contoh ini) yang akan diteruskan ke dalam fungsi. Jika tidak ada akumulator yang diberikan, elemen pertama dalam enumerable akan digunakan sebagai nilai awal.

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16

iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6

iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
```

### sort

Untuk mengurutkan koleksi, kita tidak hanya memiliki satu, tetapi dua fungsi pengurutan.

Fungsi `sort/1` menggunakan *term ordering* dari Erlang ([term ordering](http://erlang.org/doc/reference_manual/expressions.html#term-comparisons)) untuk menentukan urutan yang benar.

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

Sementara itu, fungsi `sort/2` memungkinkan kita menyediakan fungsi pengurutan sendiri.

```elixir
# with our function
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# without
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

Untuk kenyamanan, fungsi `sort/2` memungkinkan kita memberikan `:asc` atau `:desc` sebagai fungsi pengurutan.

```elixir
Enum.sort([2, 3, 1], :desc)
[3, 2, 1]
```

### uniq

Kita bisa menggunakan fungsi `uniq/1` untuk menghilangkan duplikasi dari koleksi:

```elixir
iex> Enum.uniq([1, 2, 3, 2, 1, 1, 1, 1, 1])
[1, 2, 3]
```

### uniq_by

Fungsi `uniq_by/2` juga menghapus duplikasi dari koleksi, tetapi kita bisa memberikan fungsi untuk melakukan perbandingan unik.

```elixir
iex> Enum.uniq_by([%{x: 1, y: 1}, %{x: 2, y: 1}, %{x: 3, y: 3}], fn coord -> coord.y end)
[%{x: 1, y: 1}, %{x: 3, y: 3}]
```

## Enum menggunakan operator Capture (&)

Banyak fungsi dalam modul Enum di Elixir menerima fungsi anonim (*anonymous function*) sebagai argumen untuk bekerja dengan setiap elemen dalam enumerable yang diberikan.

Anonymous function ini sering kali ditulis secara singkat menggunakan operator Capture (&).

Berikut adalah beberapa contoh yang menunjukkan bagaimana operator capture dapat diterapkan dengan modul Enum. Setiap versi secara fungsional setara.

### Menggunakan operator Capture (&) dengan anonymous function

Di bawah ini adalah contoh sintaks standar ketika meneruskan anonymous function ke `Enum.map/2`.

```elixir
iex> Enum.map([1,2,3], fn number -> number + 3 end)
[4, 5, 6]
```

Sekarang kita mengimplementasikan operator capture (&); dengan menangkap setiap elemen dari list angka ([1,2,3]) dan menetapkan setiap elemen tersebut ke variabel &1 saat diproses melalui fungsi `map`.

```elixir
iex> Enum.map([1,2,3], &(&1 + 3))
[4, 5, 6]
```

Ini bisa lebih disederhanakan lagi dengan menetapkan anonymous function sebelumnya yang menggunakan operator Capture ke sebuah variabel, lalu memanggilnya dari fungsi `Enum.map/2`.

```elixir
iex> plus_three = &(&1 + 3)
iex> Enum.map([1,2,3], plus_three)
[4, 5, 6]
```

### Menggunakan operator Capture (&) dengan fungsi bernama

Pertama, kita buat sebuah fungsi bernama dan memanggilnya di dalam fungsi anonim yang didefinisikan dalam `Enum.map/2`.

```elixir
defmodule Adding do
  def plus_three(number), do: number + 3
end

iex>  Enum.map([1,2,3], fn number -> Adding.plus_three(number) end)
[4, 5, 6]
```

Selanjutnya kita bisa refactor kodenya untuk menggunakan operator Capture.

```elixir
iex> Enum.map([1,2,3], &Adding.plus_three(&1))
[4, 5, 6]
```

Untuk sintaks yang paling ringkas, kita bisa langsung memanggil fungsi bernama tanpa perlu secara eksplisit menangkap variabelnya.

```elixir
iex> Enum.map([1,2,3], &Adding.plus_three/1)
[4, 5, 6]
```
