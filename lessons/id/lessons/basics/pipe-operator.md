%{
  version: "0.9.1",
  title: "Operator pipe",
  excerpt: """
  Operator pipe`|>` melewatkan hasil expression di sebelah kirinya sebagai parameter pertama untuk expression di sebelah kanannya.
  """
}
---

## Perkenalan

Pembuatan program bisa sangat rumit. Begitu rumitnya sehingga pemanggilan fungsi bisa begitu berlapis sehingga sulit ditelusuri. Sebagai contoh fungsi berlapis berikut ini:

```elixir
foo(bar(baz(new_function(other_function()))))
```

Di sini, kita meneruskan nilai dari `other_function/0` ke `new_function/1`, dan `new_function/1` ke `baz/1`, `baz/1` ke `bar/1`, dan akhirnya hasil dari `bar/1` ke `foo/1`. Elixir mengambil pendekatan pragmatis terhadap kekacauan sintaksis ini dengan memberi kita operator pipe. Operator pipe yang tampak seperti `|>` *mengambil hasil dari satu expression dan meneruskannya*. Mari lihat lagi snippet di atas kalau ditulis dengan operator pipe.

```elixir
other_function() |> new_function() |> baz() |> bar() |> foo()
```

Pipe mengambil hasil dari kiri, dan meneruskannya ke sebelah kanan.

## Contoh

Pada sekumpulan contoh berikut, kita akan menggunakan modul String dari Elixir.

- Memecah string

```shell
iex> "Elixir rocks" |> String.split()
["Elixir", "rocks"]
```

- Mengubah semua token jadi huruf kapital

```shell
iex> "Elixir rocks" |> String.upcase() |> String.split()
["ELIXIR", "ROCKS"]
```

- Mengecek ending

```shell
iex> "elixir" |> String.ends_with?("ixir")
true
```

## Best Practice

Jika arity (jumlah parameter) dari sebuah fungsi adalah lebih dari 1, pastikan untuk menggunakan tanda kurung. Hal ini tidak berarti banyak untuk Elixir, tapi penting untuk programmer lain yang bisa salah memahami code anda. Jika kita lihat contoh ke-2, dan membuang tanda kurungnya dari `Enum.map/2`, kita mendapat peringatan sebagai berikut.

```shell
iex> "Elixir rocks" |> String.split |> Enum.map &String.upcase/1
warning: parentheses are required when piping into a function call. For example:

    foo 1 |> bar 2 |> baz 3

is ambiguous and should be written as

    foo(1) |> bar(2) |> baz(3)

Ambiguous pipe found at:
  iex:1

["ELIXIR", "ROCKS"]
```

