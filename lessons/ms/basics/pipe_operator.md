%{
  version: "0.9.1",
  title: "Operator Paip",
  excerpt: """
  Operator Paip `|>` menghantar hasil dari satu ungkapan(expression) sebagai paramater pertama kepada satu ungkapan lain.
  """
}
---

## Pengenalan

Pengaturcaraan boleh menjadi tidak teratur.  Keadaan menjadi berkecamuk apabila panggilan-panggilan fungsi dibenamkan ke dalam panggilan fungsi lain sehingga membuatkan sukar untuk diikuti.  Lihat keadaan fungsi bersarang berikut:

```elixir
foo(bar(baz(new_function(other_function()))))
```

Di sini, kita menghantar nilai `other_function/0` kepada `new_function/1`, dan `new_function/1` kepada `baz/1`, `baz/1` kepada `bar/1` dan akhir sekali hasil dari `bar/1` kepada `foo/1`.  Elixir mengambil pendekatan pragmatik untuk menguruskan keadaan kelam-kabut ini dengan memberikan operator paip kepada kita.  Operator paip `|>` *mengambil hasil dari satu ungkapan dan menghantarnya ke depan*.  Mari lihat bagaimana suntingan kod di atas ditulis semula menggunakan operator paip.  

```elixir
other_function() |> new_function() |> baz() |> bar() |> foo()
```

Paip itu mengambil hasil dari sebelah kiri, dan hantarkannya kepada sebelah kanan.

## Contoh

Untuk contoh-contoh berikut, kita akan menggunakan modul String Elixir.

- Memecahkan string kepada token (secara longgar)

```shell
iex> "Elixir rocks" |> String.split()
["Elixir", "rocks"]
```

- Menukar semua token ke dalam huruf besar

```shell
iex> "Elixir rocks" |> String.upcase() |> String.split()
["ELIXIR", "ROCKS"]
```

- Menguji penghujung string

```shell
iex> "elixir" |> String.ends_with?("ixir")
true
```

## Amalan Terbaik

Jika 'arity' satu fungsi lebih dari 1, pastikan anda menggunakan tanda kurungan'()'.  Ia tidak begitu penting kepada Elixir, tetapi penting kepada pengaturcara lain yang mungkin akan silap faham kod anda.  Jika kita lihat contoh kedua, dan buangkan tanda kurungan dari `Enum.map/2`, kita akan mendapat amaran berikut.

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
