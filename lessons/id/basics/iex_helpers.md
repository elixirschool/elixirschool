%{
  version: "1.0.3",
  title: "Fitur Penunjang IEx",
  excerpt: """
  
  """
}
---

## Gambaran

Ketika mulai bekerja dengan Elixir, IEx adalah sahabat terbaik.
IEx adalah sebuah REPL (Read–Eval–Print Loop), tetapi memiliki lebih banyak fitur yang bisa mempermudah ketika mengeksplorasi kode baru atau dipakai untuk membantu pengembangan.
Terdapat banyak *helper* bawaan yang akan kita bahas dalam pelajaran ini.

### Autocomplete

Saat bekerja di shell, Anda mungkin sering menemukan diri Anda menggunakan modul baru yang tidak dikenal.
Untuk memahami beberapa hal yang tersedia bagi Anda, fungsi autocomplete sangat membantu.
Ketik nama modul diikuti dengan `.` lalu tekan `Tab`:

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

Dan sekarang kita tahu fungsi-fungsi yang kita miliki dan aritasnya!

### .iex.exs

Setiap kali IEx dijalankan, ia akan mencari file konfigurasi `.iex.exs`.
Jika file tersebut tidak ada di direktori saat ini, maka direktori home pengguna (`~/.iex.exs`) akan digunakan sebagai cadangan.

Opsi konfigurasi dan kode yang didefinisikan dalam file ini akan tersedia bagi kita saat shell IEx dijalankan.
Misalnya, jika kita menginginkan beberapa fungsi pembantu yang tersedia di IEx, kita dapat membuka `.iex.exs` dan melakukan beberapa perubahan.

Mari kita mulai dengan menambahkan modul dengan beberapa fungsi pembantu:

```elixir
defmodule IExHelpers do
  def whats_this?(term) when is_nil(term), do: "Type: Nil"
  def whats_this?(term) when is_binary(term), do: "Type: Binary"
  def whats_this?(term) when is_boolean(term), do: "Type: Boolean"
  def whats_this?(term) when is_atom(term), do: "Type: Atom"
  def whats_this?(_term), do: "Type: Unknown"
end
```

Sekarang, saat kita menjalankan IEx, modul IExHelpers akan tersedia bagi kita sejak awal.
Buka IEx dan mari kita coba helper baru kita:

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

Seperti yang kita lihat, kita tidak perlu melakukan hal tambahan apa pun untuk membutuhkan atau mengimpor helper kita, IEx menanganinya untuk kita.

### h

`h` adalah salah satu alat paling berguna yang diberikan oleh shell Elixir kita.
Karena dukungan kelas satu yang fantastis dari bahasa ini untuk dokumentasi, dokumentasi untuk kode apa pun dapat diakses menggunakan helper ini.
Untuk melihat cara kerjanya:

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

And now we can even combine this with the autocomplete features of our shell.
Imagine we were exploring Map for the first time:

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

Seperti yang dapat kita lihat, kita tidak hanya dapat menemukan fungsi apa saja yang tersedia sebagai bagian dari modul tersebut, tetapi kita juga dapat mengakses dokumentasi fungsi individual, yang banyak di antaranya menyertakan contoh penggunaan.

### i

Mari kita terapkan sebagian pengetahuan baru kita dengan menggunakan `h` untuk mempelajari lebih lanjut tentang helper `i`:

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

Sekarang kita punya cukup informasi tentang `Map`, termasuk di mana kode sumbernya disimpan dan modul-modul yang dirujuknya.
Ini sangat berguna saat menjelajahi tipe data kustom, tipe data asing, dan fungsi-fungsi baru.

Judul-judul individualnya mungkin padat, tetapi secara garis besar kita dapat mengumpulkan beberapa informasi yang relevan:

- Ini adalah tipe data atom
- Di mana kode sumbernya berada
- Versi dan opsi kompilasi
- Deskripsi umum
- Cara mengaksesnya
- Modul lain apa yang dirujuknya

Ini memberi kita banyak hal untuk dikerjakan dan lebih baik daripada melakukannya tanpa informasi yang cukup.

### r

Jika kita ingin mengkompilasi ulang modul tertentu, kita dapat menggunakan helper `r`.
Misalnya, kita telah mengubah beberapa kode dan ingin menjalankan fungsi baru yang telah kita tambahkan.
Untuk melakukan itu, kita perlu menyimpan perubahan kita dan mengkompilasi ulang dengan `r`:

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

Sekarang kita tahu bahwa di dalam modul `Map` telah dideklarasikan tipe `key` dan `value`.
Dan berikut kalau kita lihat kode sumbernya:

```elixir
defmodule Map do
# ...
  @type key :: any
  @type value :: any
# ...
```

Ini adalah contoh yang menyatakan bahwa `key` dan `value` sesuai implementasi dapat berupa tipe apa pun, ini hal penting untuk mengetahuinya.

Dengan memanfaatkan semua fitur bawaan ini, kita dapat menjelajahi kode dan mempelajari lebih lanjut tentang cara kerja berbagai hal.
IEx adalah alat yang sangat ampuh dan tangguh yang memberdayakan para pengembang.
Dengan alat-alat ini di kotak peralatan kita, menjelajahi dan membangun dapat menjadi lebih menyenangkan!
