%{
  version: "0.9.0",
  title: "Sigil",
  excerpt: """
  Menggunakan dan membuat sigil.
  """
}
---

## Sekilas tentang Sigil

Elixir memberikan sintaks alteratif untuk bekerja dengan literal. Sebuah sigil diawali dengan tanda tilde `~` diikuti sebuah karakter. Elixir core memberi kita beberapa sigil yang built in, tetapi kita bisa buat sendiri ketika kita perlu mengembangkan bahasa tersebut.

Sigil yang tersedia di antaranya:

  - `~C` Membuat sebuah character list **tanpa** escaping maupun interpolasi
  - `~c` Membuat sebuah character list **dengan** escaping dan interpolasi
  - `~R` Membuat sebuah regular expression **tanpa** escaping maupun interpolasi
  - `~r` Membuat sebuah regular expression **dengan** escaping dan interpolasi
  - `~S` Membuat sebuah string **tanpa** escaping maupun interpolasi
  - `~s` Membuat sebuah string **dengan** escaping dan interpolasi
  - `~W` Membuat sebuah list **tanpa** escaping maupun interpolasi
  - `~w` Membuat sebuah list **dengan** escaping dan interpolasi

Pembatas (delimiter) yang tersedia di antaranya:

  - `<...>` Sepasang kurung lancip
  - `{...}` Sepasang kurung kurawal
  - `[...]` Sepasang kurung siku
  - `(...)` Sepasang kurung biasa
  - `|...|` Sepasang tanda pipe
  - `/.../` Sepasang garis miring
  - `"..."` Sepasang kutip ganda
  - `'...'` Sepasang kutip tunggal

### Char List

Sigil `~c` dan `~C` keduanya membuat character list. Sebagai contoh:

```elixir
iex> ~c/2 + 7 = #{2 + 7}/
'2 + 7 = 9'

iex> ~C/2 + 7 = #{2 + 7}/
'2 + 7 = \#{2 + 7}'
```

Kita bisa melihat bahwa `~c` menginterpolasi (menyisipkan) hasil kalkulasi sedangkan `~C` tidak. Kita akan melihat pola huruf kecil / kapital ini adalah pola umum di seluruh sigil yang built in.

### Regular Expressions

Sigil `~r` and `~R` digunakan untuk merepresentasikan Regular Expression. Kita membuatnya bisa secara langsung atau untuk digunakan di dalam fungsi-fungsi `Regex`. Sebagai contoh:

```elixir
iex> re = ~r/elixir/
~r/elixir/

iex> "Elixir" =~ re
false

iex> "elixir" =~ re
true
```

Kita bisa melihat bahwa pada tes persamaan pertama, `Elixir` tidak cocok dengan regular expression tersebut. Ini karena kata tersebut berbentuk kapital. Karena Elixir mendukung Perl Compatible Regular Expressions (PCRE), kita bisa menambahkan `i` ke akhir sigil kita untuk membuatnya tidak case sensitive (tidak peduli huruf kecil dan kapital).

```elixir
iex> re = ~r/elixir/i
~r/elixir/i

iex> "Elixir" =~ re
true

iex> "elixir" =~ re
true
```

Lebih jauh, Elixir menyediakan API [Regex](https://hexdocs.pm/elixir/Regex.html) yang dibangun di atas library regular expression nya Erlang. Mari implementasikan `Regex.split/2` menggunakan sebuah sigil regex:

```elixir
iex> string = "100_000_000"
"100_000_000"

iex> Regex.split(~r/_/, string)
["100", "000", "000"]
```

Sebagaimana bisa kita lihat, string `"100_000_000"` dipecah pada garis bawah (underscore) oleh sigil `~r/_/` yang kita buat. Fungsi `Regex.split` menghasilkan sebuah list.

### String

Sigil `~s` and `~S` digunakan untuk menghasilkan data string. Sebagai contoh:

```elixir
iex> ~s/the cat in the hat on the mat/
"the cat in the hat on the mat"

iex> ~S/the cat in the hat on the mat/
"the cat in the hat on the mat"
```

Tapi apa bedanya? Bedanya adalah seperti pada sigil Character List yang sudah kita lihat. Jawabannya adalah pada interpolasi dan penggunaan escape sequence. Kita lihat contoh lain:

```elixir
iex> ~s/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir school"

iex> ~S/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir \#{String.downcase \"SCHOOL\"}"
```

### Word List

Sigil word list bisa sering berguna. Sigil ini bisa menghemat waktu dan jumlah ketukan di keyboard (keystroke), dan mengurangi kompleksitas dalam source code. Kita lihat contoh sederhana berikut:

```elixir
iex> ~w/i love elixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love elixir school/
["i", "love", "elixir", "school"]
```

Kita bisa melihat bahwa apa yang diketikkan di antara pembatas akan dipecah pada spasi menjadi sebuah list. Tetapi, tidak ada perbedaan di antara kedua contoh tersebut. Sekali lagi, bedanya ada pada interpolasi dan escape sequence. Kita lihat contoh berikut:

```elixir
iex> ~w/i love #{'e'}lixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love #{'e'}lixir school/
["i", "love", "\#{'e'}lixir", "school"]
```

## Membuat Sigil

Salah satu tujuan Elixir adalah menjadi sebuah bahasa pemrograman yang bisa dikembangkan (extensible). Seharusnya tidak mengejutkan bahwa anda bisa dengan mudah membuat sigil sendiri. Dalam contoh ini, kita akan membuat sebuah sigil untuk mengubah sebuah string menjadi huruf kapital. Karena sudah ada fungsi untuknya di Elixir Core (`String.upcase/1`), kita akan menggunakannya dalam sigil kita.

```elixir

iex> defmodule MySigils do
...>   def sigil_u(string, []), do: String.upcase(string)
...> end

iex> import MySigils
nil

iex> ~u/elixir school/
ELIXIR SCHOOL
```

Pertama-tama kita mendefinisikan sebuah modul bernama `MySigils` dan di dalam modul tersebut, kita membuat sebuah fungsi bernama `sigil_u`. Karena belum ada sigil `~u` di dalam lingkup sigil yang ada, kita akan menggunakannya. `_u` mengindikasikan bahwa kita ingin menggunakan `u` sebagai karakter setelah tilde. Definisi fungsinya harus menggunakan dua argumen, sebuah input dan sebuah list.
