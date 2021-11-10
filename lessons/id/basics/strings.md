%{
  version: "0.9.1",
  title: "Strings",
  excerpt: """
  Tentang String di Elixir, Char list, Grapheme, dan Codepoint.
  """
}
---

## String di Elixir

String Elixir tidak lebih dari serangkaian byte. Mari lihat sebuah contoh:

```elixir
iex> string = <<104,101,108,108,111>>
"hello"
```

>PERHATIKAN: Menggunakan sintaks << >> kita memberitahukan ke compiler bahwa elemen-elemen di dalam simbol ini adalah byte.

## Char list

Secara internal, string Elixir direpresentasikan dengan serangkaian byte dan bukannya array dari karakter, dan Elixir juga punya tipe char list (list dari karaketer).  String Elixir dibuat dengan kutip ganda, sedangkan char list dibuat dengan kutip tunggal.

Apa beda antara keduanya? Setiap value dari char list adalah nilai ASCII dari karakter tersebut. Mari kita dalami:

```elixir
iex> char_list = 'hello'
'hello'

iex> [hd|tl] = char_list
'hello'

iex> {hd, tl}
{104, 'ello'}

iex> Enum.reduce(char_list, "", fn char, acc -> acc <> to_string(char) <> "," end)
"104,101,108,108,111,"
```

Ketika membuat program di Elixir, kita biasanya tidak memakai char list melainkan String. Dukungan terhadap char list diberikan karena char list dibutuhkan oleh beberapa modul Erlang.

## Grapheme and codepoint

Codepoint adalah karakter Unicode sederhana, yang bisa direpresentasikan dengan satu atau dua byte. Sebagai contoh, karakter dengan tilde atau aksen: `á, ñ, è`. Grapheme terdiri dari beberapa codepoint yang tampak sebagai satu karakter sederhana.

Modul String sudah menyediakan dua fungsi untuk menggunakannya, `graphemes/1` and `codepoints/1`. Mari kita lihat contohnya:

```elixir
iex> string = "\u0061\u0301"
"á"

iex> String.codepoints string
["a", "́"]

iex> String.graphemes string
["á"]
```

## Fungsi String

Mari kita review beberapa fungsi yang paling penting dan berguna yang disediakan modul String untuk kita.

### length/1

Mengembalikan jumlah Grapheme dalam string tersebut.

```elixir
iex> String.length "Hello"
5
```

### replace/3

Mengembalikan sebuah string baru, mengganti sebuah pola yang ada dalam string tersebut dngan string baru.

```elixir
iex> String.replace("Hello", "e", "a")
"Hallo"
```

### duplicate/2

Mengembalikan sebuah string baru yang diulang n kali.

```elixir
iex> String.duplicate("Oh my ", 3)
"Oh my Oh my Oh my "
```

### split/2

Mengembalikan sebuah array dari string setelah dipisah oleh sebuah pola.

```elixir
iex> String.split("Hello World", " ")
["Hello", "World"]
```

## Latihan

Mari langsung mencoba dengan dua latihan sederhana untuk mendemonstrasikan bahwa kita sudah paham String!

### Anagram

A dan B dianggap anagram jika dengan mengubah urutan karakternya kita bisa membuatnya jadi sama. Sebagai contoh: 
A = super
B = perus 

Jika kita mengubah urutan karakter-karakter di string A, kita bisa dapatkan string B, dan sebaliknya.

Jadi, bagaimana cara mengecek apakah dua string adalah Anagram di Elixir?

Cara yang termudah adalah dengan mengurutkan kedua string secara alfabet dan mencek apakah sama. Mari cek contoh berikut:

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

Mari pertama-tama mengamati `anagrams?/2`. Kita mengecek apakah parameter yang kita terima adalah binary atau bukan. Itulah cara untuk mengecek apakah sebuah parameter adalah String di Elixir.

Setelah itu, kita memanggil sebuah fungsi yang mengurutkan kedua string dalam urutan alfabetis, pertama-tama mengubahnya jadi huruf kecil dan lalu menggunakan `String.graphemes` yang mengembalikan array berisi Grapheme dari string tersebut.

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

Sebagaimana bisa anda lihat, pemanggilan terakhir ke `anagrams?` mengakibatkan FunctionClauseError.  Error ini memberitahu kita bahwa tidak ada fungsi di modul kita yang cocok dengan pola menerima dua argumen non-biner, dan itu persis yang kita inginkan, menerima dua string dan tidak yang lain.
