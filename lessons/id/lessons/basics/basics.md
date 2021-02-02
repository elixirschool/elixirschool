%{
  version: "1.1.2",
  title: "Dasar",
  excerpt: """
  Awal Mulai, data tipe-tipe dasar, dan operasi-operasi dasar.
  """
}
---

## Setup

### Instalasi Elixir

Instruksi instalasi untuk masing-masing OS dapat dilihat di Elixir-lang.org bagian panduan [Installing Elixir](http://elixir-lang.org/install.html).

Setelah Elixir sudah di instal, anda dapat dengan mudah mengecek versi yang terinstal.

    % elixir -v
    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Elixir {{ site.elixir.version }}

### Moda Interaktif

Elixir dilengkapi dengan IEx, sebuah shell interaktif, yang memungkinkan kita mencoba perintah Elixir.

Untuk memulai, kita jalankan `iex`:

	Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

	Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
	iex>

Mari langsung saja kita coba dengan menulis beberapa sintaks sederhana:

```elixir
iex> 2+3
5
iex> 2+3 == 5
true
iex> String.length("The quick brown fox jumps over the lazy dog")
43
```

Jangan khawatir bila anda belum mengerti setiap sintaks ekspresi yang ada, tetapi kami berharap anda dapat ide-nya.

## Tipe dasar

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

Dalam Elixir, bilangan tidak bulat (float) membutuhkan sebuah titik desimal setelah setidaknya satu digit; bilangan ini memiliki tingkat presisi 64 bit double precision dan mendukung `e` untuk bilangan eksponen:

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

Sebuah atom adalah sebuah konstanta dimana nilainya adalah namanya itu sendiri. Jika anda sudah familiar dengan Ruby, atom adalah sinonim dengan Symbol:

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

Nama modul dalam Elixir adalah juga atom. `MyApp.MyModule` adalah atom yang sah, walaupun modul tersebut belum dideklarasikan.

```elixir
iex> is_atom(MyApp.MyModule)
true
```

Atom juga digunakan untuk mereferensi modul dari librari erlang, termasuk apa yang sudah ada.

```elixir
iex> :crypto.strong_rand_bytes 3
<<23, 104, 108>>
```

### String

String dalam Elixir adalah UTF-8 encoded dan dituliskan di antara petik ganda (double quotes):

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

String mendukung penggantian baris dan escape sequences:

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

Elixir juga memasukkan banyak tipe-tipe data kompleks. Kita akan mempelajari lebih banyak lagi hal tersebut ketika kita belajar tentang [Koleksi](../collections/) dan [Fungsi](../functions/).

## Operasi Dasar

### Aritmetik

Elixir mendukung operator dasar `+`, `-`, `*`, dan `/` sebagaimana yang sudah dapat diduga. Penting diperhatikan bahwa `/` akan selalu menghasilkan bilangan float:

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

Jika anda membutuhkan pembagian bulat (integer) atau sisa pembagian, Elixir memiliki dua fungsi untuk itu:

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Boolean

Elixir menyediakan operator boolean `||`, `&&`, dan `!`. Operator-operator ini mendukung tipe apapun:

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

Ada tiga operator tambahan yang argumen pertamanya _harus_ sebuah boolean (`true` dan `false`):

```elixir
iex> true and 42
42
iex> false or true
true
iex> not false
true
iex> 42 and true
** (ArgumentError) argument error: 42
iex> not 42
** (ArgumentError) argument error
```

### Perbandingan

Elixir dilengkapi semua operator perbandingan (comparison) yang biasa kita pakai: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<` dan `>`.

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

Sebuah fitur penting dari Elixir adalah bahwa segala macam tipe dapat dibandingkan, ini berguna dalam pengurutan (sorting). Kita tidak perlu menghafalkan urutannya tapi penting untuk dipahami:

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

Ini bisa menghasilkan perbandingan yang menarik, dan valid, yang mungkin tidak anda temukan di bahasa lain:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### Interpolasi String

Kalau anda sudah menggunakan Ruby, interpolasi string di Elixir akan tidak asing lagi:

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
