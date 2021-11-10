%{
  version: "0.9.0",
  title: "Asas",
  excerpt: """
  Penyediaan, Jenis Data Asas dan Operasi.
  """
}
---

## Penyediaan

### Pemasangan Elixir

Arahan-arahan pemasangan untuk setiap jenis OS boleh didapati di Elixir-lang.org di dalam panduan [Installing Elixir](http://elixir-lang.org/install.html).

### Mod Interaktif

Elixir disertakan dengan IEx, satu shell interaktif, yang membenarkan kita untuk menilai ekspresi Elixir.

Untuk bermula, kita jalankan `iex`:

	Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

	Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
	iex>

## Type Asas

### Angka Bulat

```elixir
iex> 255
255
```

Sokongan untuk nombor-nombor binari, oktal dan heksadesimal disertakan secara lalai(default):

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### Nombor Apungan

Dalam Elixir, nombor apungan memerlukan satu desimal selepas sekurang-kurangnya satu digit; mereka mempunyai 64 bit double precision dan menyokong penggunaan `e` untuk nombor eksponen:

```elixir
iex> 3.14
3.14
iex> .14
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```


### Boolean

Elixir menyokong penggunaan `true` dan `false` sebagai boolean; kesemuanya bernilai `true` kecuali untuk nilai `false` dan `nil`:

```elixir
iex> true
true
iex> false
false
```

### Atom

Atom ialah sejenis konstan yang nama mereka adalah merupakan nilai mereka.  Jika anda telah biasa dengan Ruby mereka adalah sinonim kepada Symbols:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

NOTA: Boolean `true` dan `false` adalah juga dari jenis atom `:true` dan `:false`.

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

### Strings

String di dalam Elixir adalah dienkod UTF-8 dan disempadankan dengan tanda petik(double quotes):

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

String menyokong pemisah baris(line break) dan urutan escape(escape sequence):

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

## Operasi Asas

### Arithmetik

Elixir menyokong operator asas `+`, `-`, `*` dan `/` sebagaimana yang anda jangkakan.  Ianya penting untuk diambil perhatian bahawa `/` akan sentiasa dipulangkan sebagai nombor float:

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

Jika anda memerlukan pembahagian integer atau baki pembahagian, Elixir membekalkan dengan dua fungsi untuk menjayakannya:

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Boolean

Elixir membekalkan operator boolean `||`, `&&`, and `!`.  Mereka menyokong semua jenis type:

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

Terdapat juga tiga operator tambahan yang mana argumen pertama _mesti_ sejenis boolean (`true` dan `false`):

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

Elixir didatangkan dengan semua operator perbandingan yang kita biasa guna: `==`, `!=`, `===`, `!==`, `<=`, `<` dan `>`.

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

Untuk perbandingan ketat nombor-nombor integer dan float, gunakan `===`:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Satu ciri penting Elixir ialah mana-mana dua bentuk jenis data boleh dibandingkan, ini adalah amat berguna ketika membuat penyusunan.  Kita tidak perlu menghafal susunan tetapi penting untuk diberikan perhatian:

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

Ini boleh membawa kepada beberapa perbandingan yang menarik, dan sah, yang anda mungkin tidak akan jumpai dalam bahasa aturcara lain:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### Interpolasi String

Jika anda pernah menggunakan Ruby, interpolasi string dalam Elixir akan dikenali:

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### Perangkaian String

Perangkaian string menggunakan operator `<>`:

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
