%{
  version: "1.5.0",
  title: "Dasar",
  excerpt: """
  Persiapan, tipe data dasar, dan operasi dasar.
  """
}
---

## Persiapan

### Instalasi Elixir

Instruksi instalasi untuk masing-masing OS dapat dilihat di Elixir-lang.org bagian panduan [Installing Elixir](http://elixir-lang.org/install.html).

Setelah Elixir terinstal, kamu dapat dengan mudah melihat versi yang terinstal.

    % elixir -v
    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Elixir {{ site.elixir.version }}

### Moda Interaktif

Elixir dilengkapi dengan IEx, sebuah shell interaktif, yang memungkinkan kita mencoba perintah Elixir.

Untuk memulai, mari kita jalankan `iex`:

 Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

 Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
 iex>

Catatan: Pada Windows PowerShell, IEx dijalankan dengan mengetik `iex.bat`.

Sekarang, mari kita coba menulis beberapa ekpresi sederhana:

```elixir
iex> 2+3
5
iex> 2+3 == 5
true
iex> String.length("The quick brown fox jumps over the lazy dog")
43
```

Jangan khawatir bila kamu belum memahami setiap ekspresi yang ada, tetapi kami berharap kamu memahami garis besarnya.

## Tipe Data Dasar

### Integer

```elixir
iex> 255
255
```

Dukungan terhadap bilangan biner, oktal, dan heksadesimal sudah tersedia secara default:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### Float

Dalam Elixir, bilangan tidak bulat (float) membutuhkan sebuah titik desimal setelah setidaknya satu digit; bilangan ini memiliki tingkat presisi 64-bit double precision dan mendukung `e` untuk bilangan eksponen:

```elixir
iex> 3.14 
 3.14
iex> .14 
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```

### Boolean

Elixir mendukung `true` and `false` sebagai nilai boolean (logika); semua nilai dianggap sama dengan `true` kecuali `false` dan `nil`:

```elixir
iex> true
true
iex> false
false
```

### Atom

Sebuah atom adalah sebuah konstanta dimana nilainya adalah namanya itu sendiri. Jika kamu familiar dengan Ruby, atom merupakan sinonim dari Symbol:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

Nilai boolean `true` dan `false` masing-masing adalah juga atom `:true` dan `:false`.

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

Nama modul dalam Elixir juga berupa atom. `MyApp.MyModule` adalah atom yang sah, walaupun modul tersebut belum dideklarasikan.

```elixir
iex> is_atom(MyApp.MyModule)
true
```

Atom juga digunakan untuk mereferensikan modul dari librari erlang, termasuk modul-modul bawaan.

```elixir
iex> :crypto.strong_rand_bytes 3
<<23, 104, 108>>
```

### String

String dalam Elixir terkodekan dalam UTF-8 dan dituliskan di antara petik ganda (double quotes):

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

String mendukung jeda baris (line break) dan escape sequences:

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

Elixir juga mendukung banyak tipe data kompleks. Kita akan mempelajari hal-hal tersebut lebih banyak ketika kita belajar tentang [Koleksi](/id/lessons/basics/collections) dan [Fungsi](/id/lessons/basics/functions).

## Operasi Dasar

### Aritmetik

Elixir mendukung operator dasar `+`, `-`, `*`, dan `/` sebagaimana yang sudah dapat diduga. Perlu diperhatikan bahwa `/` akan selalu menghasilkan bilangan dengan tipe data float:

```elixir
iex> 2 + 2
4
iex> 2 - 1
1
iex> 2 * 5
10
iex> 10 / 5
2.0
```

Jika kamu membutuhkan pembagian dengan hasil bilangan bulat (integer) atau sisa pembagian, Elixir memiliki dua fungsi untuk itu:

```elixir
iex> div(10, 3)
3
iex> rem(10, 3)
1
```

### Boolean

Elixir menyediakan operator boolean `||`, `&&`, dan `!`. Operator-operator ini bisa digunakan untuk tipe data apapun:

```elixir
iex> -20 || true
-20
iex> false || 42
42

iex> 42 && true
true
iex> 42 && nil
nil

iex> !42
false
iex> !false
true
```

Di Elixir, konsep "kebenaran" sangat sederhana: hanya `false` dan `nil` yang dianggap salah. Setiap nilai lainnya, termasuk `0`, `""` (string kosong), dan `[]` (list kosong), dianggap benar. Aturan ketat ini memungkinkan operator boolean seperti `||`, `&&`, dan `!` bekerja secara dapat diprediksi dengan tipe data apa pun untuk logika kondisional.

Ada tiga operator tambahan yang argumen pertamanya _harus_ sebuah boolean (`true` dan `false`):

```elixir
iex> true and 42
42
iex> false or true
true
iex> not false
true
iex> 42 and true
** (BadBooleanError) expected a boolean on left-side of "and", got: 42
iex> not 42
** (ArgumentError) argument error
```

Catatan: `and` dan `or` di Elixir sebenarnya dipetakan ke `andalso` dan `orelse` di Erlang.

### Perbandingan

Elixir dilengkapi dengan semua operator perbandingan (comparison) yang biasa kita pakai: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<` dan `>`.

```elixir
iex> 1 > 2
false
iex> 1 != 2
true
iex> 2 == 2
true
iex> 2 <= 3
true
```

Untuk perbandingan yang ketat (strict) antara integer dan float gunakan operator `===`:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Sebuah fitur penting dari Elixir adalah bahwa segala macam tipe dapat dibandingkan; ini berguna dalam pengurutan (sorting). Kita tidak perlu menghafalkan urutannya. Tapi penting untuk dipahami:

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

Ini bisa menghasilkan perbandingan yang menarik namun valid, yang mungkin tidak akan kamu temukan di bahasa lain:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### Interpolasi String

Kalau kamu pernah menggunakan Ruby, interpolasi string di Elixir tidak akan terasa asing:

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### Perangkaian String

Perangkaian string menggunakan operator `<>` :

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```

## Kesimpulan

Dalam pelajaran ini, kita telah membahas blok bangunan dasar Elixir.

Kita mulai dengan menginstal Elixir dan menjalankan shell interaktif IEx, di mana kita mengevaluasi ekspresi sederhana dan melihat hasil secara langsung. Dari sana, kita menjelajahi tipe data inti: integer (termasuk bentuk biner, oktal, dan heksadesimal), float, boolean, atom, dan string.

Kita juga bekerja dengan operasi dasar seperti aritmatika, logika boolean, dan operator perbandingan. Sepanjang jalan, kita melihat bagaimana Elixir menangani kebenaran — hanya `false` dan `nil` yang salah — dan bagaimana operator `||`, `&&`, `and`, dan `or` berperilaku berbeda tergantung pada ekspektasinya.

Terakhir, kita melihat interpolasi dan penggabungan string, dua alat penting untuk bekerja dengan teks.

Konsep-konsep ini membentuk fondasi pengembangan Elixir sehari-hari. Luangkan waktu untuk bereksperimen dengannya di IEx, coba modifikasi contoh-contohnya, dan amati bagaimana bahasa ini berperilaku. Pemahaman yang kuat tentang dasar-dasar ini akan membuat topik selanjutnya jauh lebih mudah dipahami.
