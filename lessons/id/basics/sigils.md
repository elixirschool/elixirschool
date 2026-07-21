%{
  version: "1.1.1",
  title: "Sigil",
  excerpt: """
  Membuat dan bekerja dengan sigil.
  """
}
---

## Sekilas tentang Sigil

Elixir menyediakan sintaks alternatif untuk merepresentasikan dan bekerja dengan literal yang disebut sigil.

Sigil dimulai dengan tanda tilde `~` dan diikuti oleh pengidentifikasi dan sepasang pembatas. Sebelum Elixir 1.15, pengidentifikasi harus berupa satu karakter. Mulai versi 1.15, pengidentifikasi juga dapat berupa rangkaian beberapa karakter huruf besar.

Inti Elixir menyediakan beberapa sigil bawaan, namun, dimungkinkan untuk membuat sigil sendiri jika kita perlu memperluas kemampuan bahasa.

Daftar sigil yang tersedia meliputi:

- `~C` Menghasilkan daftar karakter **tanpa** escaping atau interpolasi
- `~c` Menghasilkan daftar karakter **dengan** escaping dan interpolasi
- `~R` Menghasilkan ekspresi reguler **tanpa** escaping atau interpolasi
- `~r` Menghasilkan ekspresi reguler **dengan** escaping dan interpolasi
- `~S` Menghasilkan string **tanpa** escaping atau interpolasi
- `~s` Menghasilkan string **dengan** escaping dan interpolasi
- `~W` Menghasilkan daftar kata **tanpa** escaping atau interpolasi
- `~w` Menghasilkan daftar kata **dengan** escaping dan interpolasi
- `~N` Menghasilkan struct `NaiveDateTime`
- `~U` Menghasilkan struct `DateTime` (sejak Elixir 1.9.0)

Pembatas yang tersedia meliputi:

- `<...>` Sepasang kurung lancip
- `{...}` Sepasang kurung kurawal
- `[...]` Sepasang kurung siku
- `(...)` Sepasang kurung biasa
- `|...|` Sepasang tanda pipa
- `/.../` Sepasang garis miring
- `"..."` Sepasang tanda kutip ganda
- `'...'` Sepasang tanda kutip tunggal

### Char List

Sigil `~c` dan `~C` masing-masing menghasilkan daftar karakter.
Contohnya:

```elixir
iex> ~c/2 + 7 = #{2 + 7}/
'2 + 7 = 9'

iex> ~C/2 + 7 = #{2 + 7}/
'2 + 7 = \#{2 + 7}'
```

Kita dapat melihat bahwa `~c` huruf kecil menginterpolasi perhitungan, sedangkan simbol `~C` huruf besar tidak.
Kita akan melihat bahwa urutan huruf besar/kecil ini merupakan tema umum di seluruh simbol bawaan.

### Regular Expressions

Simbol `~r` dan `~R` digunakan untuk merepresentasikan Ekspresi Reguler.
Kita membuatnya secara langsung atau untuk digunakan dalam fungsi `Regex`.
Contohnya:

```elixir
iex> re = ~r/elixir/
~r/elixir/

iex> "Elixir" =~ re
false

iex> "elixir" =~ re
true
```

Kita dapat melihat bahwa pada uji kesamaan pertama, `Elixir` tidak cocok dengan ekspresi reguler.
Ini karena hurufnya kapital.
Karena Elixir mendukung Ekspresi Reguler yang Kompatibel dengan Perl (PCRE), kita bisa menambahkan `i` di akhir sigil kita untuk menonaktifkan sensitivitas huruf besar/kecil.

```elixir
iex> re = ~r/elixir/i
~r/elixir/i

iex> "Elixir" =~ re
true

iex> "elixir" =~ re
true
```

Selanjutnya, Elixir menyediakan API [Regex](https://hexdocs.pm/elixir/Regex.html) yang dibangun di atas pustaka ekspresi reguler Erlang.
Mari kita gunakan `Regex.split/2` dengan sigil regex:

```elixir
iex> string = "100_000_000"
"100_000_000"

iex> Regex.split(~r/_/, string)
["100", "000", "000"]
```

Seperti yang kita lihat, string `"100_000_000"` dipisahkan berdasarkan garis bawah berkat sigil `~r/_/` kita.
Fungsi `Regex.split` menghasilkan sebuah daftar.

### String

Sigil `~s` dan `~S` digunakan untuk menghasilkan data string.
Contohnya:

```elixir
iex> ~s/the cat in the hat on the mat/
"the cat in the hat on the mat"

iex> ~S/the cat in the hat on the mat/
"the cat in the hat on the mat"
```

Apa perbedaannya? Perbedaannya mirip dengan sigil Daftar Karakter yang telah kita lihat.
Jawabannya adalah interpolasi dan penggunaan urutan escape.
Jika kita mengambil contoh lain:

```elixir
iex> ~s/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir school"

iex> ~S/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir \#{String.downcase \"SCHOOL\"}"
```

### Daftar Kata

Sigil daftar kata dapat berguna dari waktu ke waktu.
Hal ini bisa menghemat waktu, penekanan tombol, dan dapat dikatakan mengurangi kompleksitas dalam basis kode.
Perhatikan contoh ini:

```elixir
iex> ~w/i love elixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love elixir school/
["i", "love", "elixir", "school"]
```

Kita dapat melihat bahwa apa yang diketik di antara pembatas menghasilkan daftar kata yang dipisahkan oleh spasi.
Namun, tidak ada perbedaan antara kedua contoh ini.
Sekali lagi, perbedaannya terletak pada interpolasi dan urutan escape.
Perhatikan contoh berikut:

```elixir
iex> ~w/i love #{'e'}lixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love #{'e'}lixir school/
["i", "love", "\#{'e'}lixir", "school"]
```

### NaiveDateTime

[NaiveDateTime](https://hexdocs.pm/elixir/NaiveDateTime.html) berguna untuk membuat struct dengan cepat untuk merepresentasikan `DateTime` **tanpa** zona waktu.

Untuk sebagian besar keperluan, kita harus menghindari pembuatan struct `NaiveDateTime` secara langsung.
Namun, ini berguna untuk pencocokan pola.
Misalnya:

```elixir
iex> NaiveDateTime.from_iso8601("2015-01-23 23:50:07") == {:ok, ~N[2015-01-23 23:50:07]}
```

### DateTime

[DateTime](https://hexdocs.pm/elixir/DateTime.html) berguna untuk membuat 
struct dengan cepat guna merepresentasikan `DateTime` **dengan** zona waktu UTC. 
Karena berada di zona waktu UTC, dan string Anda mungkin merepresentasikan zona waktu 
yang berbeda, item ke-3 akan dikembalikan yang merepresentasikan offset dalam detik.

Contohnya:

```elixir
iex> DateTime.from_iso8601("2015-01-23 23:50:07Z") == {:ok, ~U[2015-01-23 23:50:07Z], 0}
iex> DateTime.from_iso8601("2015-01-23 23:50:07-0600") == {:ok, ~U[2015-01-24 05:50:07Z], -21600}
```

## Membuat Sigil

Salah satu tujuan Elixir adalah menjadi bahasa pemrograman yang dapat diperluas.
Oleh karena itu, tidak mengherankan jika Anda dapat membuat sigil kustom Anda sendiri.
Dalam contoh ini, kita akan membuat sigil untuk mengubah string menjadi huruf besar.
Karena sudah ada fungsi untuk ini di Elixir Core (`String.upcase/1`), kita akan membungkus sigil kita di sekitar fungsi tersebut.

```elixir

iex> defmodule MySigils do
...>   def sigil_p(string, []), do: String.upcase(string)
...> end

iex> import MySigils
MySigils

iex> ~p/elixir school/
"ELIXIR SCHOOL"
```

Pertama, kita mendefinisikan modul bernama `MySigils` dan di dalam modul tersebut, kita membuat fungsi bernama `sigil_p`.
Karena tidak ada sigil `~p` yang ada di ruang sigil yang ada, kita akan menggunakannya.
`_p` menunjukkan bahwa kita ingin menggunakan `p` sebagai karakter setelah tilde.
Definisi fungsi ini harus menerima dua argumen, input dan daftar.

### Sigil Multi-karakter

Di Elixir 1.15 dan di atasnya, pengidentifikasi sigil juga dapat berupa rangkaian karakter huruf besar. Ini dapat digunakan untuk memperjelas fungsi sigil dengan memberikan konteks yang lebih banyak daripada yang diberikan oleh satu karakter.

Mengikuti struktur contoh sebelumnya, kita dapat mendefinisikan sigil `~REV` yang membalikkan string.

```elixir

iex> defmodule MySigils do
...>   def sigil_REV(string, []), do: String.reverse(string)
...> end

iex> import MySigils
MySigils

iex> ~REV<foobar>
"raboof"
```

Perhatikan bahwa untuk sigil multi-karakter, semua karakter harus berupa huruf besar. Fungsi sigil seperti `sigil_rev` atau `sigil_Rev` akan menyebabkan `SyntaxError` saat dipanggil.
