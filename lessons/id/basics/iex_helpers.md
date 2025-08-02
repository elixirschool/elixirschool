%{
  version: "1.0.2",
  title: "Fitur Penunjang IEx",
  excerpt: """
  
  """
}
---

## Gambaran

Ketika mulai bekerja dengan Elixir, maka IEx ada teman terbaik.
IEx adalah sebuah REPL (Read–Eval–Print Loop), tetapi memiliki lebih banyak fitur yang bisa mempermudah ketika mengeksplorasi kode baru atau dipakai untuk membantu pengembangan.
Terdapat banyak fitur bawaan yang akan kita ulas satu-persatu di pelajaran ini.

### Autocomplete

Ketika bekerja di shell IEx, kadang kita perlu menggunakan modul baru yang belum pernah kita pakai.
Untuk mengetahui apa saja yang tersedia dari modul tersebut, autocomplete bisa membantu.
Hanya dengan mengetik nama modul diikuti tanda `.` (titik) dan tekan tombol `Tab`:

```elixir
iex> Map. # press Tab
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
replace!/3           replace/3            split/2
take/2               to_list/1            update!/3
update/4             values/1
```

Dan sekarang kita bisa tahu semua fungsi yang ada termasuk *arity* atau jumlah parameternya!

### .iex.exs

Setiap kali IEx dijalankan maka dia akan coba membaca file konfigurasi  `.iex.exs`.
Apabila file tersebut tidak ditemukan di direktori saat ini (lokasi dijalankannya IEx), maka file tersebut akan coba dibaca dari direktori home pengguna (`~/.iex.exs`).

Konfigurasi dan kode yang ada di dalam file tersebut akan otomatis tersedia ketika kita menjalankan IEx.
Misalnya kita ingin sebuah fungsi pembantu supaya bisa diakses dari dalam IEx, tinggal buka file `.iex.exs` dan tambah kode yang diperlukan.

Mari kita mulai dengan membuat sebuah modul dan fungsi pembantu di dalamnya:

```elixir
defmodule IExHelpers do
  def whats_this?(term) when is_nil(term), do: "Type: Nil"
  def whats_this?(term) when is_binary(term), do: "Type: Binary"
  def whats_this?(term) when is_boolean(term), do: "Type: Boolean"
  def whats_this?(term) when is_atom(term), do: "Type: Atom"
  def whats_this?(_term), do: "Type: Unknown"
end
```

Sekarang ketika kita menjalankan IEx maka module `IExHelpers` akan tersedia dan bisa diakses.
Jalankan IEx dan coba menggunakan module dan fungsi-fungsi yang sudah kita buat tadi:

```elixir
$ iex
{{ site.erlang.OTP }} [{{ site.erlang.erts }}] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex> IExHelpers.whats_this?("a string")
"Type: Binary"
iex> IExHelpers.whats_this?(%{})
"Type: Unknown"
iex> IExHelpers.whats_this?(:test)
"Type: Atom"
```

Seperti yang terlihat, kita tidak perlu melakukkan tindakan khusus untuk meng-import modul yang kita buat barusan, IEx melakukkannya buat kita.

### h

`h` adalah salah satu alat (fungsi) paling berguna yang shell Elixir berikan kepada kita.
Digunakan untuk membaca dokumentasi kode.
Untuk menggunakannya sangatlah mudah:

```elixir
iex> h Enum
                                      Enum

Provides a set of algorithms that enumerate over enumerables according to the
Enumerable protocol.

┃ iex> Enum.map([1, 2, 3], fn(x) -> x * 2 end)
┃ [2, 4, 6]

Some particular types, like maps, yield a specific format on enumeration.
For example, the argument is always a {key, value} tuple for maps:

┃ iex> map = %{a: 1, b: 2}
┃ iex> Enum.map(map, fn {k, v} -> {k, v * 2} end)
┃ [a: 2, b: 4]

Note that the functions in the Enum module are eager: they always start the
enumeration of the given enumerable.
The Stream module allows lazy enumeration
of enumerables and provides infinite streams.

Since the majority of the functions in Enum enumerate the whole enumerable and
return a list as a result, infinite streams need to be carefully used with such
functions, as they can potentially run forever.
For example:

┃ Enum.each Stream.cycle([1, 2, 3]), &IO.puts(&1)
```

Sekarang kita gabung dengan fitur autocomplete yang dibahas sebelumnya.
Bayangkan kita sedang mempelajari modul `Map` untuk pertama kalinya:

```elixir
iex> h Map
                                      Map

A set of functions for working with maps.

Maps are key-value stores where keys can be any value and are compared using
the match operator (===).
Maps can be created with the %{} special form defined
in the Kernel.SpecialForms module.

iex> Map.
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
split/2              take/2               to_list/1
update!/3            update/4             values/1

iex> h Map.merge/2
                             def merge(map1, map2)

Merges two maps into one.

All keys in map2 will be added to map1, overriding any existing one.

If you have a struct and you would like to merge a set of keys into the struct,
do not use this function, as it would merge all keys on the right side into the
struct, even if the key is not part of the struct.
Instead, use
Kernel.struct/2.

Examples

┃ iex> Map.merge(%{a: 1, b: 2}, %{a: 3, d: 4})
┃ %{a: 3, b: 2, d: 4}
```

Bisa dilihat bahwa kita tidak hanya bisa melihat fungsi-fungsi apa saja yang tersedia dari modul tersebut tetapi juga bisa mengakses dokumentasi dari setiap fungsi tersebut, diantaranya bahkan menyertakan contoh penggunaan.

### i

Mari kita gunakan pengetahuan yang baru saja kita pelajari tentang `h` untuk mengetahui lebih banyak tentang apa itu fungsi `i`:

```elixir
iex> h i

                                  def i(term)

Prints information about the given data type.

iex> i Map
Term
  Map
Data type
  Atom
Module bytecode
  /usr/local/Cellar/elixir/1.3.3/bin/../lib/elixir/ebin/Elixir.Map.beam
Source
  /private/tmp/elixir-20160918-33925-1ki46ng/elixir-1.3.3/lib/elixir/lib/map.ex
Version
  [9651177287794427227743899018880159024]
Compile time
  no value found
Compile options
  [:debug_info]
Description
  Use h(Map) to access its documentation.
  Call Map.module_info() to access metadata.
Raw representation
  :"Elixir.Map"
Reference modules
  Module, Atom
```

Sekarang kita punya cukup informasi tentang `Map` termasuk dimana kode sumbernya disimpan dan modul-module yang menjadi rujukannya.
Ini cukup berguna ketika kita mempelajari tipe data atau fungsi-fungsi asing dan baru yang tidak pernah kita pakai sebelumnya.

Isinya memang cukup banyak, tetapi secara umum kita bisa mengambil beberapa informasi berikut:

- Apa tipe datanya, dalam hal ini atom
- Dimana letak kode sumbernya
- Versi dan opsi kompilasinya
- Keterangan umum
- Bagaimana cara mengaksesnya
- Module lain apa yang menjadi rujukannya

Hal tersebut memberikan kita cukup informasi, lebih baik daripada tidak ada sama sekali.

### r

Apabila kita ingin mengkompilasi ulang modul tertentu, kita bisa menggunakan `r` yang merupakan alias dari `recompile`.
Misalkan kita melakukkan perubahan terhadap sebuah kode atau ingin menjalankan fungsi baru yang kita buat (tanpa keluar dari shell IEx).
Cukup simpan perubahan tersebut dan kompilasi ulang dengan `r`:

```elixir
iex> r MyProject
warning: redefining module MyProject (current version loaded from _build/dev/lib/my_project/ebin/Elixir.MyProject.beam)
  lib/my_project.ex:1

{:reloaded, MyProject, [MyProject]}
```

### t

Fungsi pembantu `t` memberi tahu kita tipe dari sebuah module:

```elixir
iex> t Map
@type key() :: any()
@type value() :: any()
```

Sekarang kita tahu bahwa di dalam module `Map` telah dideklarasikan tipe `key` dan `value`.
Dan berikut kalau kita lihat kode sumbernya:

```elixir
defmodule Map do
# ...
  @type key :: any
  @type value :: any
# ...
```

Memperlihatkan bahwa key dan value dari sebuah Map bisa bertipe apapun.

Nah dengan memanfaatkan fitur-fitur diatas maka kita bisa dengan mudah mengeksplorasi kode dan mempelajari bagaimana sesuatu itu bekerja.
IEx sangatlah bermanfaat buat para pengembang, dengan semua fitur tersebut maka bereksplorasi dan membangun dengan Elixir menjadi lebih menyenangkan!
