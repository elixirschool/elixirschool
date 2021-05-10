%{
  version: "0.9.2",
  title: "Documentation",
  excerpt: """
  Mendokumentasikan Elixir code.
  """
}
---

## Anotasi

Seberapa banyak kita membuat komentar dalam source code dan apa yang membuat dokumentasi berkualitas tetap jadi perdebatan dalam dunia pemrograman. Tetapi, kita semua bisa sepakat bahwa dokumentasi penting bagi diri kita sendiri dan bagi orang-orang yang bekerja dengan code kita.

Elixir memperlakukan dokumentasi sebagai kelompok yang penting (first-class citizen), menawarkan berbagai fungsi untuk mengakses dan membuat dokumentasi untuk project. Elixir core memberi kita banyak atribut untuk menganotasi sebuah code. Mari lihat 3 cara:

  - `#` - Untuk dokumentasi inline.
  - `@moduledoc` - Untuk dokumentasi tingkat modul.
  - `@doc` - Untuk dokumentasi tingkat fungsi.

### Dokumentasi Inline

Mungkin cara termudah untuk memberi dokumentasi adalah dengan komentar yang inline (disisipkan dalam code). Serupa dengan Ruby atau Python, komentar inline Elixir ditandai dengan `#`, sering disebut tanda *pound*, atau tanda *hash*.

Coba lihat script Elixir berikut (greeting.exs):

```elixir
# Outputs 'Hello, chum.' to the console.
IO.puts "Hello, " <> "chum."
```

Elixir, ketika menjalankan script ini, akan mengabaikan semua mulai dari tanda `#` sampai akhir baris, memperlakukannya seperti data yang dibuang. Bagian itu mungkin tidak memberi nilai tambah pada operasi atau kinerja program, tetapi jika apa yang sedang terjadi tidak mudah dipahami, seorang programmer bisa tahu dari komentarnya. Perhatikan untuk tidak terlalu banyak menggunakan komentar seperti ini. Mengotori code bisa jadi menyusahkan untuk sebagian orang. Yang terbaik adalah menggunakannya secukupnya.

### Mendokumentasikan Modul

Anotator `@moduledoc` mengijinkan adanya dokumentasi inline di tingkat modul. Anotator ini biasanya berada persis di bawah deklarasi `defmodule` pada bagian atas file. Contoh di bawah ini menunjukkan sebuah komentar satu baris di dalam `@moduledoc`.

```elixir
defmodule Greeter do
  @moduledoc """
  Provides a function `hello/1` to greet a human
  """

  def hello(name) do
    "Hello, " <> name
  end
end
```

Kita (atau orang lain) bisa mengakses dokumentasi modul ini menggunakan fungsi pembantu `h` di dalam IEx.

```elixir
iex> c("greeter.ex", ".")
[Greeter]

iex> h Greeter

                Greeter

Provides a function hello/1 to greet a human
```

### Mendokumentasikan Fungsi

Sebagaimana Elixir memberi kita anotasi tingkat modul, Elixir juga memberikan anotasi serupa untuk mendokumentasikan fungsi. Anotator `@doc` memungkinkan dokumentasi inline di tingkat fungsi. Anotator `@doc` berada tepat di atas fungsi yang didokumentasikan.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

Jika kita masuk IEx lagi dan menggunakan fungsi pembantu `h` terhadap fungsi tersebut, diawali nama modul, kita mestinya melihat seperti berikut.

```elixir
iex> c("greeter.ex")
[Greeter]

iex> h Greeter.hello

                def hello(name)

`hello/1` prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"

iex>
```

Apakah anda perhatikan bahwa kita bisa menggunakan markup di dalam dokumentasi kita dan terminal akan menampilkannya ? Memang itu fasilitas yang bagus dan berguna, tapi lebih menarik lagi kalau kita melihat ExDoc untuk menghasilkan dokumentasi HTML.

## ExDoc

ExDoc adalah project Elixir resmi yang menghasilkan **dokumentasi untuk project Elixir** yang online dan berformat HTML yang bisa dilihat di [GitHub](https://github.com/elixir-lang/ex_doc). Pertama-tama mari buat sebuah project Mix untuk aplikasi kita:

```bash
$ mix new greet_everyone

* creating README.md
* creating .gitignore
* creating .formatter.exs
* creating mix.exs
* creating lib
* creating lib/greet_everyone.ex
* creating test
* creating test/test_helper.exs
* creating test/greet_everyone_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd greet_everyone
    mix test

Run "mix help" for more commands.

$ cd greet_everyone

```

Sekarang copas code dari pelajaran anotator `@doc` ke dalam sebuah file bernama `lib/greeter.ex` dan pastikan semua masih bekerja dari command line. Sekarang karena kita bekerja di dalam sebuah project Mix kita perlu menjalankan IEx secara sedikit berbeda menggunakan perintah `iex -S mix`:

```bash
iex> h Greeter.hello

                def hello(name)

Prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"
```

### Menginstal

Mengasumsikan bahwa semuanya berjalan baik, dan kita melihat output di atas mengindikasikan bahwa kita siap mensetup ExDoc. Di dalam file `mix.exs` kita tambahkan kedua dependensi yang dibutuhkan untuk memulai; `:earmark` dan `:ex_doc`.

```elixir
def deps do
  [{:earmark, "~> 0.1", only: :dev}, {:ex_doc, "~> 0.11", only: :dev}]
end
```

Kita menspesifikasikan pasangan key-value `only: :dev` karena kita tidak ingin mengunduh dan mengkompilkasi dependensi ini di production. Tapi kenapa Earmark? Earmark adalah sebuah parser Markdown untuk Elixir yang digunakan ExDoc untuk mengubah dokumentasi kita di dalam `@moduledoc` dan `@doc` menjadi HTML yang cantik.

Adalah patut diperhatikan bahwa anda tidak dipaksa menggunakan Earmark. Anda bisa mengubah tool markup nya ke tool lain seperti Pandoc, Hoedown, atau Cmark; hanya saja akan perlu melakukan sedikit konfigurasi lagi yang bisa dibaca [di sini](https://github.com/elixir-lang/ex_doc#changing-the-markdown-tool). Untuk tutorial ini, kita tetap pakai Earmark.

### Membuat Dokumentasi

Kemudian, dari command line jalankan kedua perintah berikut ini:

```bash
$ mix deps.get # mengunduh ExDoc + Earmark.
$ mix docs # membuat dokumentasi.

Docs successfully generated.
View them at "doc/index.html".
```

Jika semuanya berjalan sesuai rencana, anda mestinya melihat pesan serupa dengan output contoh di atas. Mari sekarang lihat ke dalam project Mix kita dan kita mestinya melihat bahwa ada direktori lain bernama **doc/**. Di dalamnya adalah dokumentasi yang kita hasilkan. Jika kita mengunjungi halaman indox di browser kita kita harusnya melihat seperti berikut:

![ExDoc Screenshot 1](/images/documentation_1.png)

Kita bisa melihat bahwa Earmark telah merender markdown kita dan ExDoc sekarang menampilkannya dalam format yang bagus.

![ExDoc Screenshot 2](/images/documentation_2.png)

Kita sekarang bisa mendeploy ke GitHub, website kita sendiri, atau, lebih umum, [HexDocs](https://hexdocs.pm/).

## Best Practice

Menambahkan dokumentasi semestinya ditambahkan di dalam panduan Best Practice. Karena Elixir adalah sebuah bahasa yang masih muda, banyak standar yang masih perlu ditumbuhkan bersama ekosistemnya. Tetapi, komunitas Elixir sudah berusaha membuat panduan ini. Untuk membaca lebih jauh tentang best practice, lihatlah [The Elixir Style Guide](https://github.com/niftyn8/elixir_style_guide).

  - Selalu dokumentasikan sebuah modul.

```elixir
defmodule Greeter do
  @moduledoc """
  This is good documentation.
  """

end
```

  - Jika anda tidak berniat mendokumentasikan sebuah modul, **jangan** membiarkannya kosong. Pertimbangkan untuk menganotasi modul itu dengan `false` seperti berikut:

```elixir
defmodule Greeter do
  @moduledoc false

end
```

 - Ketika merefer ke fungsi di dalam dokumentasi modul, gunakanlah tanda backtick seperti berikut:

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 - Pisahkanlah setiap code satu baris di bawah `@moduledoc` seperti berikut:

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  alias Goodbye.bye_bye
  # and so on...

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 - Gunakan markdown di dalam fungsi yang akan membuatnya lebih mudah dibaca baik lewat IEx maupun ExDoc.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

 - Upayakan untuk memasukkan beberapa contoh code dalam dokumentasi anda, ini juga memungkinkan anda menghasilkan test secara otomatis dari contoh yang ditemukan di dalam sebuah modul, fungsi, maupun macro menggunakan [ExUnit.DocTest][]. Untuk melakukan hal itu, kita perlu memanggil macro `doctest/1` dari test case kita dan menulis contoh mengikuti beberapa panduan yang didetailkan di [dokumentasi resmi][ExUnit.DocTest]

[ExUnit.DocTest]: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html
