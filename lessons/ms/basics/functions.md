%{
  version: "0.9.1",
  title: "Fungsi",
  excerpt: """
  Di dalam Elixir dan kebanyakan bahasa aturcara kefungsian, fungsi adalah rakyat kelas pertama.  Kita akan belajar mengenai jenis-jenis fungsi di dalam Elixir, apa yang menyebabkan mereka berbeza, dan bagaimana menggunakan mereka.
  """
}
---

## Fungsi Tanpa Nama

Seperti yang dibayangkan oleh namanya, fungsi tanpa nama(anonymous function) adalah fungsi yang tidak mempunyai nama.  Sebagaimana kita lihat di dalam pelajaran `Enum`, mereka selalunya dihantar kepada fungsi-fungsi lain.  Untuk mentakrifkan satu fungsi tanpa nama di dalam Elixir kita perlukan katakunci `fn` dan `end`.  Di antara kedua katakunci ini kita boleh mentakrifkan beberapa parameter dan badan fungsi yang dipisahkan oleh `->`.

Mari lihat satu contoh mudah:

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### Shorthand &

Oleh kerana fungsi tanpa nama amat lazim digunakan di dalam Elixir terdapat shorthand untuknya:

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

Sebagaimana tekaan anda, di dalam versi shorthand tersebut parameter kita disediakan kepada kita sebagai `&1`, `&2`, `&3`, dan seterusnya.

## Pemadanan Corak

Pemadanan corak(pattern matching) bukan hanya terhad kepada pembolehubah di dalam Elixir, ia juga boleh diaplikasikan kepada pengenalan fungsi(function signature) sebagaimana yang akan kita lihat di dalam bahagian ini.

Elixir menggunakan pemadanan corak untuk memastikan mana satu kumpulan parameter yang padan dan memanggil badan fungsi yang berkaitan:

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

## Fungsi Bernama

Kita boleh takrifkan fungsi-fungsi dengan nama supaya boleh dirujuk kemudian, fungsi-fungsi bernama ini ditakrifkan dengan katakunci `def` di dalam satu modul.  Kita akan belajar lebih lanjut mengenai Modul di dalam pelajaran-pelajaran selepas ini, untuk masa sekarang kita akan fokus hanya kepada fungsi bernama.


Fungsi-fungsi yang ditakrifkan di dalam satu modul adalah tersedia untuk digunakan oleh modul-modul lain, ini adalah blok binaan penting di dalam Elixir:

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

Jika fungsi kita hanya mengandungi satu baris, kita boleh pendekkan lagi dengan `do:`:

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

Bersedia dengan pengetahuan mengenai pemadanan corak, kita akan meneroka rekursi menggunakan fungsi-fungsi bernama:

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

### Fungsi Terlindung

Jika kita tidak mahu modul-modul lain untuk mengakses sesatu fungsi, kita boleh gunakan fungsi-fungsi terlindung(private functions), yang hanya boleh dipanggil dari dalam modul mereka sahaja.  Kita takrifkan fungsi terlindung di dalam Elixir dengan `defp`:

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

### Klausa Kawalan

Kita telah melihat sepintas lalu mengenai klausa kawalan(guard) di dalam bahagian [Control Structures](../control-structures), sekarang kita akan melihat bagaimana kita boleh aplikasikan mereka kepada fungsi-fungsi bernama.  Sebaik sahaja Elixir berjaya memadankan corak satu fungsi, apa-apa klausa kawalan pada fungsi tersebut akan diuji.

Di dalam contoh di bawah kita ada dua fungsi yang mempunyai pengenalan yang sama, kita bergantung kepada klausa kawalan untuk menentukan yang mana satu akan digunakan berdasarkan kepada jenis argumen:

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

### Argumen Lalai

Jika kita mahukan satu nilai lalai(default value) untuk satu argumen kita gunakan sintaks `argumen \\ nilai`:

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

Jika kita gabungkan contoh klausa kawalan dengan argumen lalai(default argument), kita akan menemui satu isu.  Mari lihat bagaimana rupa isu tersebut:

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

Elixir tidak sukakan argumen lalai di dalam beberapa fungsi-fungsi yang berjaya dipadankan, ia boleh jadi mengelirukan.  Untuk mengatasi keadaan ini kita tambahkan satu kepala fungsi bersama argumen lalai kita:  

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
