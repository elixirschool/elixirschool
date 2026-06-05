%{
  version: "1.4.0",
  title: "Koleksi",
  excerpt: """
  List, tuple, keyword lists, dan map.
  """
}
---

## List

List adalah kumpulan dari nilai-nilai yang mungkin berisi beberapa tipe sekaligus; list juga bisa berisi nilai-nilai yang tidak unik (bisa berisi duplikat):

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir mengimplementasikan koleksi list sebagai `linked list` (daftar tertaut).
Ini berarti mengakses panjang sebuah list adalah operasi yang akan dijalankan secara linear (`O(n)`).
Karena alasan ini, biasanya lebih cepat menambahkan elemen di depan list daripada menambahkan elemen di belakang list:

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
# Penambahan di awal (cepat)
iex> ["π" | list]
["π", 3.14, :pie, "Apple"]
# Penambahan di akhir (lambat)
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```

### Penggabungan List

Penggabungan list menggunakan operator `++/2`:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

Catatan tambahan tentang format nama (`++/2`) yang digunakan di atas:
Dalam Elixir (dan Erlang, bahasa yang digunakan untuk membangun Elixir), sebuah nama fungsi atau operator memiliki dua komponen: nama yang kamu berikan (di sini `++`) dan _arity_ nya.
Arity (jumlah parameter) adalah bagian inti (penting) dari pembicaraan tentang kode Elixir (dan Erlang).
Arity merupakan jumlah argumen yang bisa diterima oleh sebuah fungsi (dua, dalam kasus ini).
Arity dan nama fungsinya digabungkan dengan garis miring. Kita akan membicarakan hal ini lebih banyak; saat ini, pengetahuan ini akan membantu kamu untuk memahami notasi ini.

### Pengurangan List

Dukungan terhadap pengurangan diberikan melalui operator `--/2`; pengurangan nilai yang tidak ada dalam list tidak menghasilkan error:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

Perhatikan nilai yang terulang.
Setiap elemen yang ada di sebelah kanan akan menghapus elemen pertama dengan nilai yang sama dari sebelah kiri kiri:

```elixir
iex> [1,2,2,3,2,3] -- [1,2,3,2]
[2, 3]
```

**Catatan:** List menggunakan [perbandingan ketat](/id/lessons/basics/basics#perbandingan-12) untuk mencocokkan nilai. Contoh:

```elixir
iex> [2] -- [2.0]
[2]
iex> [2.0] -- [2.0]
[]
```

### Kepala / Ekor

Ketika menggunakan list, kita biasa menggunakan kepala (head) dan ekor (tail) dari list tersebut.
Kepala (Head) adalah elemen pertama dari list, sedang ekor (tail) adalah list yang berisi elemen-elemen lainnya.
Elixir menyediakan dua fungsi yang sangat berguna, `hd` dan `tl`, untuk memakai keduanya:

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

Di samping kedua fungsi tersebut, kamu juga bisa menggunakan [pencocokan pola](/id/lessons/basics/pattern_matching) dan operator  `|` untuk memisahkan list menjadi bagian kepala (head) list dan ekor (tail). Kita akan mempelajari pola ini di pelajaran-pelajaran selanjutnya:

```elixir
iex> [head | tail] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> head
3.14
iex> tail
[:pie, "Apple"]
```

## Tuple

Tuple mirip dengan list, tetapi disimpan secara berturutan di memori.
Ini membuat akses ke panjang tuple cepat tetapi modifikasinya mahal; karena tuple baru harus disalin seluruhannya ke memori.
Tuple didefinisikan menggunakan kurung kurawal:

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

Umumnya tuple digunakan sebagai mekanisme untuk mengembalikan informasi tambahan dari fungsi; manfaat dari ini akan lebih jelas ketika kita mempelajari [pencocokan pola (pattern matching)](/id/lessons/basics/pattern_matching):

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Keyword list

Daftar kata kunci (keyword list) dan map adalah koleksi asosiatif di Elixir.
Dalam Elixir, sebuah keyword list adalah sejenis list khusus berisi tuple yang elemen pertamanya adalah sebuah atom; kinerjanya serupa dengan list:

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

Tiga karakteristik keyword list menyoroti pentingnya mereka:

+ Kunci (key)-nya harus berupa atom.
+ Kuncinya diurutkan sesuai yang ditentukan.
+ Kuncinya tidak harus unik.

Untuk alasan-alasan inilah keyword list paling sering digunakan untuk meneruskan parameter ke fungsi.

## Map

Di Elixir, map adalah sarana yang paling sering digunakan untuk penyimpanan key-value (kunci-nilai).
Tidak seperti keyword list, mereka (map) membolehkan kunci dari tipe apa pun dan tidak perlu urut.
Kamu bisa mendefinisikan sebuah map dengan sintaks `%{}`, memakai kunci atau variabel yang ditentukan:

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
```

Ada juga beberapa cara untuk mengakses nilai map:

```elixir
iex> map[:foo]
"bar"
iex> map["hello"]
:world
iex> Map.get(map, :foo)
"bar"
```

Seperti yang dapat kita lihat dari output di atas, ada sintaks khusus untuk map yang hanya berisi kunci atom:

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```

Selain itu, terdapat sintaks untuk mengambil nilai untuk kunci atom:

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> map.hello
"world"
```

Sifat menarik lainnya dari map adalah bahwa map menyediakan sintaksnya sendiri untuk pembaruan (catatan: ini akan membuat map baru):

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{map | foo: "baz"}
%{foo: "baz", hello: "world"}
```

**Catatan**: sintaks ini hanya berfungsi untuk memperbarui kunci yang sudah ada di dalam map! Jika kunci tidak ada, akan muncul `KeyError`.

Untuk menambahkan kunci baru, kita dapat menggunakan [`Map.put/3`](https://hexdocs.pm/elixir/Map.html#put/3), yang menambahkan kunci baru jika belum ada dan memperbarui record jika nilai sudah ada pada kunci tersebut. Kita dapat melihat perilaku ini ditunjukkan dalam contoh kita:

Untuk menambahkan kunci baru, gunakan [`Map.put/3`](https://hexdocs.pm/elixir/Map.html#put/3).

```elixir
iex> map = %{hello: "world"}
%{hello: "world"}
# Coba perbarui peta kita dengan kunci `:foo` baru menggunakan metode `|`
iex> %{map | foo: "baz"}
** (KeyError) key :foo not found in: %{hello: "world"}
    (stdlib) :maps.update(:foo, "baz", %{hello: "world"})
    (stdlib) erl_eval.erl:259: anonymous fn/2 in :erl_eval.expr/5
    (stdlib) lists.erl:1263: :lists.foldl/3
# Pakai `Map.put/3` untuk menambah kunci dan nilai baru
iex> map = Map.put(map, :foo, "baz")
%{foo: "baz", hello: "world"}
# Pakai `Map.put/3` untuk pemaruan kunci
iex> Map.put(map, :foo, "bar")
%{foo: "bar", hello: "world"}
```
