%{
  version: "1.0.1",
  title: "Operator Pipa",
  excerpt: """
  Operator pipa `|>` meneruskan hasil suatu ekspresi sebagai parameter pertama dari ekspresi lain.
  """
}
---

## Perkenalan

Pemrograman bisa menjadi rumit.
Bahkan sangat rumit sehingga panggilan fungsi bisa menjadi sangat saling terkait sehingga sulit untuk dipahami.
Perhatikan fungsi berlapis berikut ini:

```elixir
foo(bar(baz(new_function(other_function()))))
```

Di sini, kita meneruskan nilai dari `other_function/0` ke `new_function/1`, dan `new_function/1` ke `baz/1`, `baz/1` ke `bar/1`, dan akhirnya hasil dari `bar/1` ke `foo/1`.
Elixir mengambil pendekatan pragmatis terhadap kekacauan sintaksis ini dengan memberi kita operator pipa.
Operator pipa yang terlihat seperti `|>` _mengambil hasil dari satu ekspresi, dan meneruskannya_.
Mari kita lihat lagi cuplikan kode di atas yang ditulis ulang menggunakan operator pipa.

```elixir
other_function() |> new_function() |> baz() |> bar() |> foo()
```

Pipa tersebut mengambil hasil dari sisi kiri, dan meneruskannya ke sisi kanan.

## Contoh

Untuk rangkaian contoh ini, kita akan menggunakan modul String dari Elixir.

- Tokenisasi String (memecah String secara longgar)

```elixir
iex> "Elixir rocks" |> String.split()
["Elixir", "rocks"]
```

- Mengubah semua token jadi huruf besar

```elixir
iex> "Elixir rocks" |> String.upcase() |> String.split()
["ELIXIR", "ROCKS"]
```

- Mengecek ending

```elixir
iex> "elixir" |> String.ends_with?("ixir")
true
```

## Praktik Terbaik

Jika aritas suatu fungsi lebih dari 1, pastikan untuk menggunakan tanda kurung.
Hal ini tidak terlalu penting bagi Elixir, tetapi penting bagi programmer lain yang mungkin salah menafsirkan kode Anda.
Namun, hal ini penting untuk operator pipa.
Misalnya, jika kita mengambil contoh ketiga kita, dan menghapus tanda kurung dari `String.ends_with?/2`, kita akan mendapatkan peringatan berikut.

```elixir
iex> "elixir" |> String.ends_with? "ixir"
warning: parentheses are required when piping into a function call.
For example:

  foo 1 |> bar 2 |> baz 3

is ambiguous and should be written as

  foo(1) |> bar(2) |> baz(3)

true
```
