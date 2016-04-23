---
layout: page
title: Koleksi
category: basics
order: 2
lang: id
---

List, tuple, kata kunci, map dan kombinator fungsional.

## Daftar Isi

- [List](#list)
	- [Penggandengan list](#penggandengan-list)
	- [Pengurangan list](#pengurangan-list)
	- [Head / Tail](#head--tail)
- [Tuple](#tuple)
- [Daftar kata kunci](#keyword-list)
- [Map](#map)

## List

List adalah kumpulan sederhana dari nilai-nilai, bisa berisi beberapa tipe sekaligus; list bisa berisi nilai yang tidak unik (bisa berisi duplikat):

```elixir
iex> [3.41, :pie, "Apple"]
[3.41, :pie, "Apple"]
```

Elixir mengimplementasikan list sebagai `linked list`. Hal ini berarti operasi untuk mendapatkan panjang sebuah list merupakan operasi yang `O(n)`.  Karenanya, biasanya lebih cepat menambahkan anggota baru di awal list daripada di akhir list:

```elixir
iex> list = [3.41, :pie, "Apple"]
[3.41, :pie, "Apple"]
iex> ["π"] ++ list
["π", 3.41, :pie, "Apple"]
iex> list ++ ["Cherry"]
[3.41, :pie, "Apple", "Cherry"]
```


### Penggandengan List

Penggandengan list menggunakan operator `++/2`:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

### Pengurangan List

Dukungan terhadap pengurangan diberikan melalui operator `--/2`; pengurangan nilai yang tidak ada dalam list tidak menghasilkan error:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

**Catatan:** List menggunakan [perbandingan ketat](../basics/#perbandingan) untuk mencocokkan nilai.

### Head / Tail

Ketika menggunakan list, kita sering menggunakan head dan tail dari list tersebut. Head adalah elemen pertama dari list dan tail adalah sisanya. Elixir memberikan dua fungsi, `hd` dan `tl`, untuk mengakses keduanya:

```elixir
iex> hd [3.41, :pie, "Apple"]
3.41
iex> tl [3.41, :pie, "Apple"]
[:pie, "Apple"]
```

Di samping kedua fungsi tersebut, anda juga bisa menggunakan operator `|`; kita akan melihat pola ini di pelajaran-pelajaran selanjutnya:

```elixir
iex> [h|t] = [3.41, :pie, "Apple"]
[3.41, :pie, "Apple"]
iex> h
3.41
iex> t
[:pie, "Apple"]
```

## Tuple

Tuple mirip dengan list tetapi disimpan secara berturutan di memori. Ini membuat pengaksesan panjangnya jadi cepat tetapi modifikasinya jadi lambat; tuple yang baru harus disalin keseluruhannya ke memori baru. Tuple didefinisikan menggunakan kurung kurawal:

```elixir
iex> {3.41, :pie, "Apple"}
{3.41, :pie, "Apple"}
```

Umumnya tuple digunakan sebagai mekanisme untuk mengembalikan informasi tambahan dari fungsi; manfaat dari ini akan lebih jelas ketika kita masuk ke pencocokan pola (pattern matching):

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Keyword list

Daftar kata kunci (keyword list) dan map adalah koleksi asosiatif dalam Elixir. Dalam Elixir, sebuah keyword list adalah sejenis list khusus berisi tuple yang elemen pertamanya adalah sebuah atom; kinerjanya serupa dengan list:

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

Ketiga karakteristik keyword list mengindikasikan keutamaannya:

+ Kunci (key)nya adalah atom.
+ Kuncinya berurutan.
+ Kuncinya tidak unik.

Untuk alasan inilah keyword list paling sering digunakan untuk memasukkan parameter ke fungsi.

## Map

Dalam Elixir map adalah sarana yang paling sering digunakan untuk penyimpanan key-value (kunci-isi). Tidak seperti keyword list, map mengijinkan kunci dari tipe apapun dan tidak ada pengurutan (ordering). Anda bisa mendefinisikan sebuah map dengan sintaks `%{}`:

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

Sejak Elixir 1.2 variabel boleh digunakan sebagai key dari map:

```elixir
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
```

Jika sebuah duplikasi ditambahkan ke sebuah mapl data yang baru menimpa yang lama:

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
