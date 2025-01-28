%{
  version: "1.3.2",
  title: "Koleksi",
  excerpt: """
  Lists, tuples, keyword lists, dan maps.
  """
}
---

## Lists

Lists adalah kumpulan nilai yang dapat mencakup beberapa tipe data; lists juga dapat mencakup nilai yang tidak unik:

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir mengimplementasikan list sebagai linked list.
Ini berarti mengakses panjang sebuah list adalah operasi yang akan berjalan dalam waktu linear (`O(n)`).
Untuk alasan ini, biasanya lebih cepat untuk melakukan operasi penambahan di awal list (prepend) daripada melakukan operasi penambahan di akhir (append):

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
# Prepending (operasi yang cepat)
iex> ["π" | list]
["π", 3.14, :pie, "Apple"]
# Appending (operasi yang lambat)
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```

### Penggabungan List

Penggabungan list menggunakan operator `++/2`:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

Catatan tambahan tentang penulisan format yang digunakan di atas (`++/2`):
Di Elixir (dan Erlang, di mana Elixir dibangun di atasnya), nama sebuah fungsi atau operator memiliki dua komponen yaitu: nama yang kamu berikan (di sini adalah `++`) dan _ariti-nya_.
Arity adalah bagian inti dari pembicaraan tentang kode Elixir (dan Erlang).
Ini adalah jumlah argumen yang dibutuhkan oleh fungsi yang diberikan (dua, dalam kasus ini).
Ariti dan nama yang diberikan digabungkan dengan garis miring. Kita akan membahas lebih lanjut tentang hal ini nanti; pengetahuan ini akan membantu kamu memahami notasi untuk saat ini.

### Pengurangan List

Dukungan untuk pengurangan list disediakan melalui operator `--/2`; ini operasi saman untuk mengurangi nilai yang tidak ada atau hilang:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

Berhati-hatilah dengan nilai duplikat!.
Untuk setiap elemen di sebelah kanan, kemunculan pertama elemen tersebut akan dihapus dari list sebelah kiri:

```elixir
iex> [1,2,2,3,2,3] -- [1,2,3,2]
[2, 3]
```

**Catatan:** Pengurangan list menggunakan [perbandingan ketat](/en/lessons/basics/basics#comparison) untuk menemukan nilai yang cocok.

```elixir
iex> [2] -- [2.0]
[2]
iex> [2.0] -- [2.0]
[]
```

### Head / Tail

Ketika menggunakan lists, adalah hal umum untuk bekerja dengan head dan tail.
Head adalah elemen pertama dalam list, sementara tail adalah list yang mengandung elemen-elemen yang sisanya.
Elixir menyediakan dua fungsi yang membantu kita bekerja dengan head dan tail yaitu `hd` dan `tl`:

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

Selain fungsi-fungsi yang telah disebutkan di atas, kamu dapat menggunakan [pattern matching](/en/lessons/basics/pattern_matching) dan operator cons `|` untuk membagi sebuah list menjadi head dan tail. Kita akan mempelajari lebih lanjut tentang pola ini di pelajaran selanjutnya:


```elixir
iex> [head | tail] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> head
3.14
iex> tail
[:pie, "Apple"]
```

## Tuples

Tuples mirip dengan lists, tetapi disimpan secara berdekatan di memori.
Hal ini membuat pengaksesan panjangnya adalah operasi yang cepat tetapi modifikasinya adalah operasi yang mahal; karena tuple baru harus disalin seluruhnya ke memori.
Tuples didefinisikan dengan kurung kurawal:

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

Tuple adalah hal yang umum yang digunakan sebagai mekanisme untuk mengembalikan informasi tambahan dari fungsi; kegunaannya akan lebih jelas ketika kita masuk ke [pattern matching] (/en/lessons/basics/pattern_matching):


```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Keyword lists

Keyword lists dan maps adalah koleksi asosiatif dari Elixir.
Di Elixir, Keyword lists adalah list khusus yang berisi tupel dua elemen yang elemen pertamanya adalah atom; cara kerjanya sama seperti list:

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

Tiga karakteristik utama dari keyword list menunjukkan betapa pentingnya struktur ini:

- Keys (kuncinya) harus berupa atom.
- Keys memiliki urutan sesuai dengan yang ditentukan oleh pengembang.
- Keys tidak harus unik.

Untuk alasan ini, keyword lists umumnya digunakan untuk meneruskan opsi ke fungsi-fungsi di Elixir.

## Maps

Di Elixir, maps adalah pilihan utama untuk penyimpanan pasangan key-value.
Berbeda dengan keyword list, map memungkinkan key dari berbagai tipe data dan tidak memiliki urutan.
Kamu dapat mendefinisikan map menggunakan sintaks `%{}`:

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

Pada Elixir 1.2, variabel diperbolehkan sebagai key pada map:

```elixir
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
```

Jika ada duplikat yang ditambahkan ke map, ia akan mengganti nilai sebelumnya:

```elixir
iex> %{:foo => "bar", :foo => "hello world"}
%{foo: "hello world"}
```

Seperti yang kita lihat pada output di atas, ada ciri khusus untuk map yang hanya berisi atom keys:

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```

Selain itu, ada sintaks untuk mengambil nilai untuk key yang berjenis atom:

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> map.hello
"world"
```

Satu lagi sifat menarik dari map adalah kemampuannya untuk menyediakan sintaks khusus dalam melakukan pembaruan (perlu dicatat: ini akan menghasilkan map baru):

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{map | foo: "baz"}
%{foo: "baz", hello: "world"}
```

**Catatan**: sintaks ini hanya berfungsi untuk memperbarui key yang sudah ada di dalam map! Jika kunci tersebut tidak ada, akan muncul `KeyError`.

Untuk membuat key yang baru, gunakan [`Map.put/3`](https://hexdocs.pm/elixir/Map.html#put/3)

```elixir
iex> map = %{hello: "world"}
%{hello: "world"}
iex> %{map | foo: "baz"}
** (KeyError) key :foo not found in: %{hello: "world"}
    (stdlib) :maps.update(:foo, "baz", %{hello: "world"})
    (stdlib) erl_eval.erl:259: anonymous fn/2 in :erl_eval.expr/5
    (stdlib) lists.erl:1263: :lists.foldl/3
iex> Map.put(map, :foo, "baz")
%{foo: "baz", hello: "world"}
```
