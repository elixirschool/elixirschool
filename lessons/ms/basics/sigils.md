%{
  version: "0.9.0",
  title: "Sigil",
  excerpt: """
  Membuat dan menggunakan sigil.
  """
}
---

## Gambaran Keseluruhan Sigil

Elixir membekalkan satu sintaks alternatif untuk mewakili dan memanipulasi string.  Satu sigil dimulakan dengan satu simbol tilde `~` dan dikuti oleh satu aksara.  Kod teras Elixir ada membekalkan beberapa sigil yang telah disiap-pasang.  Walaupun begitu kita masih dibenarkan untuk membuat sigil kita sendiri apabila ada keperluan untuk mengembangkan bahasa ini.

Senarai sigil yang tersedia termasuk:

  - `~C` Menjana satu list aksara **tanpa** 'escaping' atau 'interpolation'
  - `~c` Menjana satu list aksara **mengandungi** 'escaping' atau 'interpolation'
  - `~R` Menjana satu ungkapan nalar(regular expression) **tanpa** 'escaping' atau 'interpolation'
  - `~r` Menjana satu ungkapan nalar(regular expression) **mengandungi** 'escaping' atau 'interpolation'
  - `~S` Menjana string **tanpa** 'escaping' atau 'interpolation'
  - `~s` Menjana string **mengandungi** 'escaping' atau 'interpolation'
  - `~W` Menjana satu list **tanpa** 'escaping' atau 'interpolation'
  - `~w` Menjana satu list **mengandungi** 'escaping' atau 'interpolation'

Senarai kata-kata sempadan(delimiters) termasuk:

  - `<...>` Sepasang tanda kurungan muncung
  - `{...}` Sepasang tanda kurungan kerinting
  - `[...]` Sepasang tanda kurungan kotak
  - `(...)` Sepasang tanda kurungan
  - `|...|` Sepasang tanda paip
  - `/.../` Sepasang tanda miring hadapan
  - `"..."` Sepasang tanda ungkapan berganda
  - `'...'` Sepasang tanda ungkapan tunggal

### List Aksara

Sigil-sigil `~c` dan `~C` digunakan untuk menjana list aksara.  Sebagai contoh:

```elixir
iex> ~c/2 + 7 = #{2 + 7}/
'2 + 7 = 9'

iex> ~C/2 + 7 = #{2 + 7}/
'2 + 7 = \#{2 + 7}'
```

Kita dapat lihat apabila menggunakan huruf kecil, iaitu `~c`, ia akan membuat interpolasi(menjalankan proses dan memulangkan hasil proses) pengiraan di dalam string tersebut, sementara sigil huruf besar `~C` tidak melakukan interpolasi.  Kita akan dapat melihat bagaimana penggunaan huruf kecil/huruf besar ini menjadi tema lazim di dalam keseluruhan sigil-sigil yang disiap-pasang.

### Ungkapan Nalar

Sigil-sigil `~r` dan `~R` digunakan untuk mewakili Ungkapan Nalar(Regular Expression).  Kita membuat mereka secara layang(on the fly) atau untuk kegunaan dari dalam fungsi-fungsi `Regex`.  Sebagai contoh:

```elixir
iex> re = ~r/elixir/
~r/elixir/

iex> "Elixir" =~ re
false

iex> "elixir" =~ re
true
```

Kita dapat lihat di dalam ujian persamaan yang pertama, perkataan `Elixir` tidak sepadan dengan ungkapan nalar tersebut.  Ini kerana huruf pertamanya adalah huruf besar.  Oleh sebab Elixir menyokong format Perl Compatible Regular Expressions (PCRE), kita boleh menambah `i` pada penghujung sigil untuk menyingkirkan kesensitifan huruf.

```elixir
iex> re = ~r/elixir/i
~r/elixir/i

iex> "Elixir" =~ re
true

iex> "elixir" =~ re
true
```

Seterusnya, Elixir menyediakan API [Regex](https://hexdocs.pm/elixir/Regex.html) yang dibina di atas pustaka ungkapan nalar Erlang.  Mari kita laksanakan `Regex.split/2` menggunakan sigil ungkapan nalar:

```elixir
iex> string = "100_000_000"
"100_000_000"

iex> Regex.split(~r/_/, string)
["100", "000", "000"]
```

Sebagaimana yang dapat kita lihat, string `"100_000_000"` telah diceraikan berdasarkan simbol garis bawah melalui sigil `~r/_/` kita.  Fungsi `Regex.split` itu memulangkan satu list.

### String

Sigil-sigil `~s` and `~S` digunakan untuk menjana data string.  Sebagai contoh:

```elixir
iex> ~s/the cat in the hat on the mat/
"the cat in the hat on the mat"

iex> ~S/the cat in the hat on the mat/
"the cat in the hat on the mat"
```
Tetapi apakah perbezaannya?  Perbezaannya adalah sama dengan sigil List Aksara yang telah kita lihat.  Jawapannya adalah 'interpolation' dan 'escape sequence'.  Jika kita lihat satu lagi contoh:

```elixir
iex> ~s/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir school"

iex> ~S/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir \#{String.downcase \"SCHOOL\"}"
```

### List Perkataan

Sigil list perkataan adalah amat berguna.  Ia dapat menjimatkan masa, 'keystroke' dan megurangkan kerumitan di dalam 'codebase'.  Lihat contoh mudah ini:

```elixir
iex> ~w/i love elixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love elixir school/
["i", "love", "elixir", "school"]
```

Kita dapat lihat apa yang ditaip di antara kedua-dua sempadan itu dipisahkan oleh 'whitespace' ke dalam satu list.  Walaupun begitu, tidak ada yang membezakan antara kedua-dua contoh tersebut.  Perbezaannya adalah 'interpolation' dan 'escape sequence'.  Lihat contoh di bawah:

```elixir
iex> ~w/i love #{'e'}lixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love #{'e'}lixir school/
["i", "love", "\#{'e'}lixir", "school"]
```

## Membuat Sigil

Salah satu matlamat Elixir ialah menjadi satu bahasa aturcara yang boleh dikembangkan.  Oleh itu tidak mengejutkan jika anda boleh membuat sigil-sigil anda sendiri.  Di dalam contoh ini, kita akan membuat satu sigil untuk menukarkan satu string ke dalam bentuk huruf besar.  Oleh kerana sudah terdapat fungsi yang sama di dalam teras ELixir(`String.upcase/1`), kita akan bungkuskan sigil kita diatas fungsi tersebut.

```elixir

iex> defmodule MySigils do
...>   def sigil_u(string, []), do: String.upcase(string)
...> end

iex> import MySigils
nil

iex> ~u/elixir school/
ELIXIR SCHOOL
```

Mula-mula kita takrifkan satu modul berama `MySigil` dan  di dalam modul tersebut, kita membuat satu fungsi dipanggil `sigil_u`.  Oleh kerana sigil `~u` masih belum wujud, kita akan gunakannya.  Simbol `_u` memberitahu kita mahu menggunakan `u` sebagai aksara selepas simbol tilde.  Pengenalan fungsi itu wajib mempunyai dua argumen, satu input dan satu list.  
