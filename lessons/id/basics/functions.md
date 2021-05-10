---
version: 0.9.1
title: Fungsi
---

Di Elixir dan banyak bahasa fungsional lainnya, fungsi adalah first class citizen. Kita akan pelajari tentang tipe-tipe fungsi di Elixir, apa yang membuatnya berbeda, dan bagaimana menggunakannya.

{% include toc.html %}

## Anonymous function

Seperti dimengerti dari namanya, fungsi anonim tidak bernama. Seperti kita lihat di pelajaran `Enum`, fungsi semacam ini seringkali digunakan sebagai parameter ke fungsi lain. Untuk membuat sebuah fungsi anonim di Elixir kita menggunakan kata kunci `fn` dan `end`.  Di antara keduanya kita dapat mendefinisikan sejumlah parameter dan tubuh fungsi dengan dipisahkan dengan `->`.

Mari lihat sebuah contoh mendasar:

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### The & shorthand

Penggunaan fungsi anonim adalah praktek yang sangat umum sehingga ada singkatan untuk melakukannya:

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

Sebagai yang bisa diduga, dalam versi singkat, parameter kita bisa diakses sebagai `&1`, `&2`, `&3`, dan seterusnya.

## Pencocokan pola

Pencocokan pola (pattern matching) tidak terbatas pada hanya variabel di Elixir. Ia bisa juga diterapkan pada penanda fungsi (function signature) seperti dapat kita lihat dalam bagian ini.

Elixir menggunakan pencocokan pola untuk mengidentifikasikan kumpulan pertama parameter yang cocok dan menjalankan tubuh fungsi yang bersesuaian:

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
1
iex> handle_result.({:ok, some_result})
Handling result...
:ok
iex> handle_result.({:error})
An error has occurred!
```

## Fungsi bernama

Kita dapat mendefinisikan fungsi yang memiliki nama sehingga kita dapat merujuk padanya, fungsi seperti ini didefinisikan dengan kata kunci `def` di dalam sebuah modul.  Kita akan pelajari lebih jauh tentan Modul di pelajaran-pelajaran berikutnya, untuk saat ini kita akan fokus pada fungsi bernama saja.

Fungsi yang didefinisikan dalam sebuah modul dapat digunakan oleh modul lain, ini adalah fitur penting Elixir dalam pembuatan aplikasi:

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

Jika tubuh fungsi yang kita buat hanya terdiri dari satu baris, kita dapat menyingkatnya dengan `do:`:

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

Dilengkapi dengan pengetahuan kita tentang pencocokan pola, mari kita eksplorasi rekursi menggunakan fungsi bernama:

```elixir
defmodule Length do
  def of([]), do: 0
  def of([_ | tail]), do: 1 + of(tail)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### Fungsi privat

Jika kita tidak ingin modul lain mengakses sebuah fungsi, kita dapat menggunakan fungsi privat yang hanya bisa dipanggil di dalam Module mereka.  Kita dapat mendefinisikannya dengan `defp`:

```elixir
defmodule Greeter do
  def hello(name), do: phrase <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### Guard

Kita sudah sekilas menyinggung guard di pelajaran [Struktur Kendali](../control-structures), sekarang kita akan melihat bagaimana menerapkannya dalam fungsi bernama.  Saat Elixir sudah menemukan fungsi yang cocok, guard yang ada akan diuji.

Dalam contoh berikut kita memiliki dua fungsi yang memiliki penanda (signature) yang sama, kita bergantung pada guard untuk menentukan mana yang akan digunakan berdasarkan tipe argumen/parameternya:

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase() <> name
  end

  defp phrase, do: "Hello, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"
```

### Default arguments

Jika kita inginkan adanya nilai default untuk salah satu argumen, kita gunakan sintaks `argument \\ value`:

```elixir
defmodule Greeter do
  def hello(name, language_code \\ "en") do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello("Sean", "en")
"Hello, Sean"

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.hello("Sean", "es")
"Hola, Sean"
```

Ketika kita menggabungkan contoh guard kita dengan argumen default, kita bertemu sebuah masalah. Mari kita lihat seperti apa:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code \\ "en") when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) iex:31: definitions with multiple clauses and default values require a header. Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b) do ... end

one should write:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end

def hello/2 has multiple clauses and defines defaults in one or more clauses
    iex:31: (module)
```

Elixir tidak suka dengan argumen default dalam fungsi yang tercocok rangkap (multiple matching), terlalu membingungkan.  Untuk mengatasi hal ini kita menambahkan sebuah kepala fungsi (function head) dengan argumen default kita:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en")

  def hello(names, language_code) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code) when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "es"
"Hola, Sean, Steve"
```
