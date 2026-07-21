%{
  version: "1.2.2",
  title: "Strings",
  excerpt: """
  String, Charlist, Graphemes dan Codepoints.
  """
}
---

## String di Elixir

String Elixir hanyalah urutan byte.
Lihat contohnya:

```elixir
iex> string = <<104,101,108,108,111>>
"hello"
iex> string <> <<0>>
<<104, 101, 108, 108, 111, 0>>
```

Dengan menggabungkan string dengan byte `0`, IEx menampilkan string tersebut sebagai biner karena string tersebut bukan lagi string yang valid.
Trik ini dapat membantu kita melihat byte yang mendasari string apa pun.

>CATATAN: Dengan menggunakan sintaks << >> kita memberi tahu kompiler bahwa elemen di dalam simbol tersebut adalah byte.

## Charlists

Secara internal, string Elixir direpresentasikan dengan urutan byte, bukan array karakter.
Elixir juga memiliki tipe daftar karakter (character list).
String Elixir diapit dengan tanda kutip ganda, sedangkan daftar karakter diapit dengan tanda kutip tunggal.

Apa perbedaannya? Setiap nilai dalam daftar karakter adalah titik kode Unicode dari sebuah karakter, sedangkan dalam biner, titik kode dikodekan sebagai UTF-8.
Mari kita pelajari:

```elixir
iex> 'hełło'
[104, 101, 322, 322, 111]
iex> "hełło" <> <<0>>
<<104, 101, 197, 130, 197, 130, 111, 0>>
```

`322` is the Unicode codepoint for ł but it is encoded in UTF-8 as the two bytes `197`, `130`.

You can get a character’s code point by using `?`

```elixir
iex> ?Z
90
```

Ini memungkinkan Anda menggunakan notasi `?Z` daripada 'Z' untuk sebuah simbol.

Saat memprogram di Elixir, kita biasanya menggunakan string, bukan charlist.
Dukungan charlist terutama disertakan karena diperlukan untuk beberapa modul Erlang.

Untuk informasi lebih lanjut, lihat [`Panduan Memulai` resmi](http://elixir-lang.org/getting-started/binaries-strings-and-char-lists.html).

## Grafem dan Codepoints

Codepoint adalah karakter Unicode dasar yang direpresentasikan oleh satu atau lebih byte, tergantung pada pengkodean UTF-8.
Karakter di luar set karakter ASCII AS akan selalu dikodekan sebagai lebih dari satu byte.
Misalnya, karakter Latin dengan tilde atau aksen (`á, ñ, è`) biasanya dikodekan sebagai dua byte.
Karakter dari bahasa Asia sering dikodekan sebagai tiga atau empat byte.
Grafem terdiri dari beberapa codepoint yang dirender sebagai satu karakter.

Modul String sudah menyediakan dua fungsi untuk mendapatkannya, `graphemes/1` dan `codepoints/1`.
Mari kita lihat contohnya:

```elixir
iex> string = "\u0061\u0301"
"á"

iex> String.codepoints string
["a", "́"]

iex> String.graphemes string
["á"]
```

## Fungsi String

Mari kita tinjau beberapa fungsi terpenting dan paling berguna dari modul String.
Pelajaran ini hanya akan membahas sebagian kecil dari fungsi yang tersedia.
Untuk melihat kumpulan fungsi lengkap, kunjungi dokumentasi resmi [`String`](https://hexdocs.pm/elixir/String.html).

### length/1

Mengembalikan jumlah grafem dalam string.

```elixir
iex> String.length "Hello"
5
```

### replace/3

Mengembalikan string baru yang menggantikan pola saat ini dalam string dengan string pengganti baru.

```elixir
iex> String.replace("Hello", "e", "a")
"Hallo"
```

### duplicate/2

Mengembalikan sebuah string baru yang diulang sebanyak n kali.

```elixir
iex> String.duplicate("Oh my ", 3)
"Oh my Oh my Oh my "
```

### split/2

Mengembalikan daftar string yang dipisahkan berdasarkan pola.

```elixir
iex> String.split("Hello World", " ")
["Hello", "World"]
```

## Latihan

Mari langsung mencoba dengan dua latihan sederhana untuk mendemonstrasikan bahwa kita sudah paham String!

### Anagram

A dan B dianggap sebagai anagram jika ada cara untuk menyusun ulang A atau B sehingga keduanya sama.
Sebagai contoh:

+ A = super
+ B = perus

Jika kita menyusun ulang karakter pada String A, kita bisa mendapatkan string B, dan sebaliknya.

Jadi, bagaimana kita bisa memeriksa apakah dua string adalah anagram di Elixir? Pendekatan yang paling mudah adalah dengan mengurutkan graphem dari setiap string secara alfabetis dan kemudian memeriksa apakah kedua daftar tersebut sama.
Mari kita coba:

```elixir
defmodule Anagram do
  def anagrams?(a, b) when is_binary(a) and is_binary(b) do
    sort_string(a) == sort_string(b)
  end

  def sort_string(string) do
    string
    |> String.downcase()
    |> String.graphemes()
    |> Enum.sort()
  end
end
```

Mari lihat `anagrams?/2` terlebih dahulu.
Kita memeriksa apakah parameter yang kita terima berupa biner atau bukan.
Itulah cara kita memeriksa apakah suatu parameter adalah String di Elixir.

Setelah itu, kita memanggil fungsi yang mengurutkan string secara alfabetis.
Pertama, fungsi tersebut mengubah string menjadi huruf kecil, kemudian menggunakan `String.graphemes/1` untuk mendapatkan daftar grafem dalam string.
Terakhir, mengalirkan pipa daftar tersebut ke `Enum.sort/1`.

Mari kita cek outputnya di iex:

```elixir
iex> Anagram.anagrams?("Hello", "ohell")
true

iex> Anagram.anagrams?("María", "íMara")
true

iex> Anagram.anagrams?(3, 5)
** (FunctionClauseError) no function clause matching in Anagram.anagrams?/2

    The following arguments were given to Anagram.anagrams?/2:

        # 1
        3

        # 2
        5

    iex:11: Anagram.anagrams?/2
```

Seperti yang Anda lihat, panggilan terakhir ke `anagrams?` menyebabkan FunctionClauseError.
Kesalahan ini memberi tahu kita bahwa tidak ada fungsi dalam modul kita yang memenuhi pola menerima dua argumen non-biner, dan itulah yang kita inginkan, yaitu menerima dua string, dan tidak yang lain.
