---
version: 0.9.0
title: Collections
---

List, tuples, keywords, maps, dicts dan functional combinators.

{% include toc.html %}

## List

List adalah senarai nilai ringkas, mereka boleh mengandungi pelbagai jenis data; list dibolehkan untuk mengandungi nilai-nilai yang bukan unik:

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir melaksanakan list sebagai 'linked list'.  Ini bermakna mencapai saiz list ialah satu operasi `0(n)`.  Oleh sebab ini selalunya lebih cepat untuk melakukan operasi penambahan awalan(prepend) dari melakukan operasi lampiran(append):

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> ["π" | list]
["π", 3.14, :pie, "Apple"]
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```


### Perangkaian List

Perangkaian list menggunakan operator `++/2`:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

### Penolakan List

Sokongan untuk proses penolakan dibekalkan melalui operator `--/2`; ianya selamat untuk membuat penolakan nilai yang hilang:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

### Head / Tail

Apabila menggunakan list ianya biasa untuk melakukan kerja menggunakan `head` dan `tail` sesatu list.  `Head` ialah elemen pertama sesatu list dan `tail` ialah elemen-elemen seterusnya.  Elixir membekalkan dua kaedah yang berguna, `hd` dan `tl`, untuk bekerja dengan kedua-dua komponen tersebut:

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

Sebagai tambahan kepada fungsi-fungsi yang telah disebutkan, anda juga dibenarkan menggunakan aksara paip `|`; kita akan melihat penggunaan corak ini di dalam pelajaran seterusnya:

```elixir
iex> [head | tail] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> head
3.14
iex> tail
[:pie, "Apple"]
```

## Tuple

Tuple adalah sama dengan list tetapi disimpan secara berturutan di dalam ingatan.  Ini membuatkan capaian ke atas nilai panjang mereka laju tetapi membuat kemaskini adalah mahal; satu tuple baru mestilah disalin keseluruhannya ke dalam ingatan.  Tuple diisytiharkan menggunakan curly braces:

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

Menjadi kebiasaan untuk menggunakan tuple sebagai mekanisma untuk memulangkan maklumat tambahan dari fungsi-fungsi;  Kebaikan penggunaan ini akan lebih jelas apabila kita masuk kepada pemadanan corak:

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Kata-kunci list

Keyword dan map adalah koleksi asosiatif( associative collections of) Elixir; kedua-duanya melaksanakan modul `Dict`.  Dalam Elixir, kata-kunci list ialah sejenis senarai tuple khas yang mengandungi elemen pertama dari jenis atom; prestasi mereka adalah sama dengan list:

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

Terdapat tiga ciri kata-kunci list yang menonjolkan kepentingan mereka:

+ Keys adalah dari jenis atom.
+ Keys adalah dalam bentuk turutan.
+ Keys adalah tidak unik.

Atas sebab-sebab tersebut kata-kunci list selalu digunakan to menghantar pilihan kepada fungsi.

## Map

Dalam Elixir map adalah 'key-value store' yang paling kerap digunapakai, berlainanan dengan kata-kunci list mereka membenarkan penggunan key dari pelbagai jenis data dan mereka tidak mengikut turutan.  Anda boleh mengisytiharkan sesatu map dengan menggunakan sintaks `%{}`:

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

Mulai dari Elixir 1.2 pembolehubah dibenarkan untuk digunakan sebagai map key:

```elixir
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
```

Sekiranya satu salinan baru ditambah kepada satu map, ia akan menukarkan nilai asal:

```elixir
iex> %{:foo => "bar", :foo => "hello world"}
%{foo: "hello world"}
```

Daripada paparan di atas, terdapat satu sintaks khas untuk map yang hanya mengandungi key dari jenis atom:

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}

iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```
