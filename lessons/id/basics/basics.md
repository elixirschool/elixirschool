%{
  version: "1.4.1",
  title: "Dasar-dasar",
  excerpt: """
  Memulai Elixir, tipe data dasar, dan operasi dasar.
  """
}
---

## Memulai Elixir

### Instalasi Elixir

Pentunjuk instalasi untuk setiap sistem operasi dapat ditemukan pada halaman elixir-lang.org di bagian [Installing Elixir](http://elixir-lang.org/install.html).

Setelah Elixir diinstal, kamu dapat menemukan versi yang terinstal dengan mengetikkan:

    % elixir -v
    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Elixir {{ site.elixir.version }}

### Mencoba Mode Interaktif

Elixir dilengkapi dengan IEx, sebuah shell interaktif, yang memungkinkan kamu untuk mengevaluasi ekspresi Elixir secara langsung.

Untuk memulai, mari jalankan `iex` di terminal:

    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
    iex>

Catatan: Pada Windows PowerShell, kamu perlu mengetikkan `iex.bat`.

Mari kita lanjutkan dan mencobanya sekarang dengan mengetikkan beberapa ekspresi dasar:

```elixir
iex> 2+3
5
iex> 2+3 == 5
true
iex> String.length("The quick brown fox jumps over the lazy dog")
43
```

Tidak perlu khawatir jika kamu tidak mengerti setiap ekspresinya, tetapi kami berharap kamu dapat mengerti maksudnya.

## Tipe Data Dasar

### Integers

```elixir
iex> 255
255
```

Elixir mendukung penulisan notasi bilangan biner, oktal, dan heksadesimal:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### Floats

Di Elixir, angka pecahan memerlukan desimal setidaknya satu angka; Elixir memiliki ketelitian hingga 64-bit dan mendukung notasi `e` untuk nilai eksponen:

```elixir
iex> 3.14
3.14
iex> .14
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```

### Booleans

Elixir mendukung `true` dan `false` sebagai boolean, semuanya bernilai benar kecuali `false` dan `nil`.

```elixir
iex> true
true
iex> false
false
```

### Atoms

Atom adalah sebuah konstanta yang namanya adalah nilainya.
Jika kamu terbiasa dengan Ruby, ini identik dengan Simbol:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

Boolean `true` dan `false` juga merupakan atom `:true` dan `:false`.

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

Nama-nama modul di Elixir juga merupakan atom. `MyApp.MyModule` adalah sebuah atom yang valid, meskipun modul ini belum dideklarasikan.

```elixir
iex> is_atom(MyApp.MyModule)
true
```

Atom juga digunakan untuk mereferensikan modul-modul dari pustaka Erlang, termasuk yang sudah ada di dalamnya.

```elixir
iex> :crypto.strong_rand_bytes 3
<<23, 104, 108>>
```

### Strings

Strings dalam Elixir di-encode dengan UTF-8 dan ditulis dengan mengapitkan kutip dua:

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

Strings mendukung _line-breaks_ dan _escape sequences_:

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

Elixir juga menyertakan tipe data yang lebih kompleks.
Kita akan mempelajari lebih lanjut tentang ini ketika kita mempelajari [collections](/en/lessons/basics/collections) dan [functions](/en/lessons/basics/functions).

## Operasi Dasar

### Aritmetika

Elixir mendukung operator dasar `+`, `-`, `*`, dan `/` seperti yang kamu harapkan.
Penting untuk diingat bahwa `/` akan selalu mengembalikan nilai desimal:

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

Jika kamu membutuhkan hasil pembagian bilangan bulat atau sisa pembagian (modulo), Elixir mempunyai dua fungsi yang membantu untuk melakukannya:

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Boolean

Elixir menyediakan operator boolean `||`, `&&`, dan `!`.
Operator ini mendukung semua jenis data:

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

Ada tiga operator tambahan yang mana argumen pertamanya _wajib_ berjenis boolean (`true` dan `false`):

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

Catatan: `and` dan `or` pada Elixir sebenarnya sama dengan `andso` dan `orelse` pada Erlang.

### Perbandingan

Elixir dilengkapi dengan semua operator perbandingan yang biasa kita gunakan: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<`, dan `>`.

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

Untuk perbandingan yang ketat untuk bilangan bulat dan desimal, gunakan `===`:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Fitur penting dari Elixir adalah bahwa dua jenis dapat dibandingkan; ini sangat berguna dalam pengurutan. Kita tidak perlu menghafal urutan pengurutan, tetapi penting untuk mengetahuinya:

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

Hal ini dapat menghasilkan beberapa perbandingan yang menarik namun valid, yang mungkin tidak kamu temukan dalam bahasa pemrograman lainnya:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### Interpolasi String

Jika kamu pernah menggunakan Ruby, interpolasi string Elixir akan tampak mirip seperti ini:

```elixir
iex> name = "Sean"
"Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### Penggabungan String

Penggabungan String menggunakan operator `<>`:

```elixir
iex> name = "Sean"
"Sean"
iex> "Hello " <> name
"Hello Sean"
```
