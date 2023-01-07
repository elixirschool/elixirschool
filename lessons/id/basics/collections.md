%{
  version: "1.3.1",
  title: "Koleksi",
  excerpt: """
  List, tuple, keyword lists, dan map.
  """
}
---

## List

List adalah kumpulan sederhana dari nilai-nilai, bisa berisi beberapa tipe sekaligus; list bisa berisi nilai yang tidak unik (bisa berisi duplikat):

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir mengimplementasikan list sebagai `linked list`.
Artinya, operasi untuk mendapatkan panjang sebuah list merupakan operasi yang berjalan dalam waktu yang linear (`O(n)`).
Karenanya, biasanya lebih cepat menambahkan anggota baru di awal list daripada di akhir list:

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

### Penggandengan List

Penggandengan list menggunakan operator `++/2`:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

Sebuah catatan tentang format nama (`++/2`) yang digunakan di atas:
Dalam Elixir (dan Erlang, bahasa yang digunakan untuk membangun Elixir), sebuah nama fungsi atau operator memiliki dua komponen: nama yang kamu berikan (di sini `++`) dan _arity_ nya.
Arity (jumlah parameter) adalah bagian inti (penting) dari pembicaraan tentang kode Elixir (dan Erlang).
Arity merupakan jumlah argumen yang bisa diterima oleh sebuah fungsi (dua, dalam kasus ini).
Arity dan nama fungsinya digabungkan dengan garis miring. Kita akan membicarakannya nanti; saat ini, pengetahuan ini akan membantu kamu untuk memahami notasi ini.

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

**Catatan:** List menggunakan [perbandingan ketat](/id/lessons/basics/basics#perbandingan) untuk mencocokkan nilai. Contoh:

```elixir
iex> [2] -- [2.0]
[2]
iex> [2.0] -- [2.0]
[]
```

### Kepala / Ekor

Ketika menggunakan list, kita sering menggunakan kepala (head) dan ekor (tail) dari list tersebut.
Kepala (Head) adalah elemen pertama dari list dan ekor (tail) adalah sisanya.
Elixir memiliki dua fungsi yang sangat membantu, `hd` dan `tl`, untuk mengakses keduanya:

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

Di samping kedua fungsi tersebut, kamu juga bisa menggunakan [pencocokan pola](/id/lessons/basics/pattern_matching) dan operator `|` untuk memisahkan kepala (head) list dan ekornya (tail). Kita akan melihat pola ini di pelajaran-pelajaran selanjutnya:

```elixir
iex> [head | tail] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> head
3.14
iex> tail
[:pie, "Apple"]
```

## Tuple

Tuple mirip dengan list, hanya saja ia disimpan secara berturutan di memori.
Ini membuat panjang tuple mudah dan cepat untuk diakses namun membutuhkan sumber daya lebih untuk mengubah/memodifikasinya; tuple yang baru harus disalin keseluruhannya ke memori baru.
Tuple didefinisikan menggunakan kurung kurawal:

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

Umumnya tuple digunakan sebagai mekanisme untuk mengembalikan informasi tambahan dari fungsi; manfaat dari ini akan lebih jelas ketika kita mempelajari [pencocokan pola (pattern matching)](/en/lessons/basics/pattern_matching):

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Keyword list

Daftar kata kunci (keyword list) dan map adalah koleksi asosiatif dalam Elixir.
Dalam Elixir, sebuah keyword list adalah sejenis list khusus berisi tuple yang elemen pertamanya adalah sebuah atom; kinerjanya serupa dengan list:

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

Ketiga karakteristik keyword list mengindikasikan keutamaannya:

+ Kunci (key)nya adalah atom.
+ Kuncinya berurutan.
+ Kuncinya tidak harus unik.

Untuk alasan inilah keyword list paling sering digunakan untuk memasukkan parameter ke fungsi.

## Map

Dalam Elixir map adalah sarana yang paling sering digunakan untuk penyimpanan key-value (kunci-nilai).
Tidak seperti keyword list, kita bisa menggunakan menggunakan dari tipe apapun untuk dijadikan kunci dan tidak perlu urut.
Kamu bisa mendefinisikan sebuah map dengan sintaks `%{}`:

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

Sejak Elixir 1.2, variabel bisa digunakan sebagai key dari map:

```elixir
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
```

Jika sebuah duplikasi ditambahkan ke sebuah map, data yang baru akan mengubah yang lama:

```elixir
iex> %{:foo => "bar", :foo => "hello world"}
%{foo: "hello world"}
```

Sebagaimana bisa dilihat di tampilan output di atas, ada sintaks khusus untuk map yang seluruh kuncinya adalah atom:

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```

Sebagai tambahan, ada sebuah sintaks spesial untuk mengakses kunci atom:

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> map.hello
"world"
```

Hal menarik lain mengenai map adalah tersedianya sintaks tersendiri untuk memperbarui nilai-nilainya (catatan: ini akan membuat map baru):

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{map | foo: "baz"}
%{foo: "baz", hello: "world"}
```

**Catatan**: sintaks ini hanya bisa digunakan untuk memperbarui nilai sebuah kunci yang sudah ada di dalam map! Jika kunci tersebut belum ada, error `KeyError` akan ditimbulkan.

Untuk menambahkan kunci baru, gunakan [`Map.put/3`](https://hexdocs.pm/elixir/Map.html#put/3).

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
