---
layout: page
title: Dokumentasi
category: basics
order: 11
lang: my
---

Mendokumentasi kod Elixir.

## Kandungan

- [Annotation](#annotation)
  - [Dokumentasi Inline](#inline-documentation)
  - [Menjana Dokumentasi Modul](#documenting-modules)
  - [Menjana Dokumentasi Fungsi](#documenting-functions)
- [ExDoc](#exdoc)
  - [Pemasangan](#pemasangan)
  - [Penjanaan Dokumentasi](#penjanaan-dokumentasi)
- [Best Practice](#best-practice)


## Annotation

Berapa banyak komen dibuat dan apa yang dikatakan sebagai dokumentasi berkualiti masih hebat diperdebatkan di dalam dunia pengaturcaraan.  Walaupun begitu, kita masih boleh bersetuju bahawa dokumentasi adalah penting untuk kita dan juga mereka yang bekerja dengan codebase kita.

Elixir memberikan dokumentasi dengan layanan kelas pertama, dengan menyediaka pelbagai fungsi untuk mencapai dan menjana dokumentasi untuk projek kita.  Komponen teras Elixir menyediakan pelbagai ciri untuk annotate satu codebase.  Mari lihat 3 cara:

  - `#` - untuk dokumentasi inline.
  - `@moduledoc` - Untuk dokumentasi peringkat Modul.
  - `@doc` - Untuk dokumentasi peringkat Fungsi.

### Dokumentasi Inline

Mungkin cara yang paling mudah untuk membuat komen kepada kod anda ialah melalui komen inline.  Sama seperti Ruby atau Python, komen inline Elixir ditanda dengan `#`, selalunya dikenali sebagai *pound* bergantung kepada bahagian dunia di mana anda berada.

Lihat skrip Elixir ini (greeting.exs):

```elixir
# Outputs 'Hello, chum.' to the console.
IO.puts "Hello, " <> "chum."
```

Apabila menjalankan skrip ini, Elixir tidak akan mempedulikan semua dari `#` hingga ke pengakhir line tersebut, melayannya sebagai data pakai buang.  Ia mungkin tidak menambah nilai kepada operasi atau prestasi skrip tersebut, tetapi walaupun ianya tidak ketara apa yang sedang berlaku seorang pengaturcara sepatutnya tahu dari membaca komen anda.  Berhati-hati supaya tidak abuse komen satu baris tersebut!  Mencomotkan satu codebase mungkin tidak dialu-alukan oleh sesetengah pihak.  Sebaiknya gunakanlah dengan berimbang. 

### Menjana Dokumentasi Modul

Annotator `@moduledoc` membenarkan dokumentasi inline pada peringkat modul.  Biasanya ia berada di bawah tetapan `defmodule` di bahagian atas fail.  COntoh di bawah menunjukkan satu komen satu baris di dalam dekorator `@moduledoc`.

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

Kita (atau orang lain) boleh mencapai dokumentasi modul ini menggunakan fungsi helper `h` di dalam `iex`.

```elixir
iex> c("greeter.ex")
[Greeter]

iex> h Greeter

                Greeter

Provides a function hello/1 to greet a human
```

### Menjana Dokumentasi Fungsi

Sebagaimana Elixir memberikan kita keupayaan untuk menjana dokumentasi peringkat modul, ia juga mengupayakan anotasi yang sama utuk menjana dokumentasi untuk fungsi.  Annotator `@doc` membenarkan untuk membuat dokumentasi inline pada peringkat fungsi.  Annotator `@doc` terletak di atas kod fungsi yang ia membuat anotitasi.

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
  @spec hello(String.t) :: String.t
  def hello(name) do
    "Hello, " <> name
  end
end
```

Jika kita memulakan iex semula dan menggunakan arahan helper `h` di atas fungsi yang diprepend dengan nama modul, kita sepatutnya boleh melihat paparan berikut:

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

Perhatikan bagaimana anda boleh gunakan 'markup' di dalam dokumentasi kita dan terminal akan memaparkannya?  Selain dari ianya hebat dan tambahan amat bagus kepada ekosistem ELixir, ianya lebih lagi menarik apabila kita melihat ExDoc menjana dokumentasi HTML secara spontan.

## ExDoc

ExDoc ialah satu projek rasmi Elixir yang **menjana HTML dan dokumentasi atas talian untuk projek-projek Elixir** yang boleh didapati di [GitHub](https://github.com/elixir-lang/ex_doc).  Pertama sekali kita akan membuat satu projek Mix untuk aplikasi kita:

```bash
$ mix new greet_everyone

* creating README.md
* creating .gitignore
* creating mix.exs
* creating config
* creating config/config.exs
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

Sekarang salin dan tampal kod dari pelajaran annotator `@doc` ke dalam satu fail `lib/greeter.ex` dan pastikan semuanya masih berfungsi daripada command line.  Oeh kerana sekarang kita bekerja di dalam satu projek Mix kita perlu jalankan IEx menggunakan arahan `iex -S mix`:

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

### Pemasangan

Dengan anggapan semuaya berfungsi dengan baik, dan kita dapat melihat paparan sebagaimana di atas kita telah bersedia untuk memasang ExDoc.  Di dalam fail `mix.exs` kita, tambahkan dua dependency yang diperlukan untuk bermula; `:earmark` and `:ex_doc`.

```elixir
  def deps do
    [{:earmark, "~> 0.1", only: :dev},
    {:ex_doc, "~> 0.11", only: :dev}]
  end
```

Kita menetapkan pasangan key-value `only: :dev` sebab kita tidak mahu untuk memuatturun dan mengkompil dependency tersebut di dalam persekitaran pengeluaran(production environment).

Perlu diingatkan, anda tidak diwajibkan untuk menggunakan Earkmark,  Anda boeh menggunakan alat markup yang lain seperti Pandoc, Hoedown atau Cmark; tetapi anda akan diperlukan untuk membuat sedikit konfigurasi yang boleh anda baca [di sini](https://github.com/elixir-lang/ex_doc#changing-the-markdown-tool).  Untuk tutorial ini kita akan gunakan Earmark. 

### Menjana Dokumentasi

Jalankan arahan berikut dari command line:

```bash
$ mix deps.get # gets ExDoc + Earmark.
$ mix docs # makes the documentation.

Docs successfully generated.
View them at "doc/index.html".
```
Harap-harap, jika semuanya mengikut rancangan, anda sepatutnya dapa melihat mesej yang sama dengan paparan mesej di dalam contoh di atas.  Sekarang kita akan lihat ke dalam projek Mix kita dan kita akan dapat melihat lagi satu direktori bernama **doc/**.  Di dalamnya ialah dokumentasi yang dijanakan.  Jika kita capai page indeks di dalam browser kita sepatutnya dapat melihat paparan seperti berikut:

![ExDoc Screenshot 1]({{ site.url }}/assets/documentation_1.png)

We can see that Earmark has rendered our markdown and ExDoc is now displaying it in a useful format.

![ExDoc Screenshot 2]({{ site.url }}/assets/documentation_2.png)

We can now deploy this to GitHub, our own website, more commonly [HexDocs](https://hexdocs.pm/).

## Best Practice

Adding documentation should be added within the Best practices guidelines of the language. Since Elixir is a fairly young language many standards are still to be discovered as the ecosystem grows. The community, however, has made efforts to establish best practices. To read more about best practices see [The Elixir Style Guide](https://github.com/niftyn8/elixir_style_guide).

  - Always document a module.

```elixir
defmodule Greeter do
  @moduledoc """
  This is good documentation.
  """

end
```

  - If you do not intend to document a module, **do not** leave it blank. Consider annotating the module `false` as so:

```elixir
defmodule Greeter do
  @moduledoc false

end
```

 - When referring to functions within module documentation, use backticks like so:

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  def hello(name) do
    IO.puts "Hello, " <> name
  end
end
```

 - Separate any and all code one line under the `@moduledoc` as so:

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  alias Goodbye.bye_bye
  # and so on...

  def hello(name) do
    IO.puts "Hello, " <> name
  end
end
```

 - Use markdown within functions that will make it easier to read either via IEx or ExDoc.

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
  @spec hello(String.t) :: String.t
  def hello(name) do
    "Hello, " <> name
  end
end
```

 - Try to include some code examples in your documentation, this also allows you to generate automatic tests from the code examples found in a module, function or macro with [ExUnit.DocTest][]. In order to do that, one needs to invoke the `doctest/1` macro from their test case and write their examples according to some guidelines, which are detailed in the [official documentation][ExUnit.DocTest]

[ExUnit.DocTest]: http://elixir-lang.org/docs/master/ex_unit/ExUnit.DocTest.html
