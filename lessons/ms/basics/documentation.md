%{
  version: "0.9.1",
  title: "Dokumentasi",
  excerpt: """
  Mendokumentasi kod Elixir.
  """
}
---

## Pencatatan

Berapa banyak komen dibuat dan apa yang dikatakan sebagai dokumentasi berkualiti masih hebat diperdebatkan di dalam dunia pengaturcaraan.  Walaupun begitu, kita masih boleh bersetuju bahawa dokumentasi adalah penting untuk kita dan juga mereka yang bekerja dengan kod asas kita.

Elixir memberikan dokumentasi dengan layanan kelas pertama, dengan menyediaka pelbagai fungsi untuk mencapai dan menjana dokumentasi untuk projek kita.  Komponen teras Elixir menyediakan pelbagai ciri untuk mencatat satu kod asas.  Mari lihat 3 cara:

  - `#` - untuk dokumentasi inline.
  - `@moduledoc` - Untuk dokumentasi peringkat Modul.
  - `@doc` - Untuk dokumentasi peringkat Fungsi.

### Dokumentasi Inline

Mungkin cara yang paling mudah untuk membuat komen kepada kod anda ialah melalui komen inline.  Sama seperti Ruby atau Python, komen inline Elixir ditanda dengan `#`, selalunya dikenali sebagai *pound* bergantung kepada bahagian dunia di mana anda berada.

Lihat skrip Elixir ini (greeting.exs):

```elixir
# Outputs 'Hello, chum.' to the console.
IO.puts("Hello, " <> "chum.")
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
iex> c("greeter.ex", ".")
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
  @spec hello(String.t()) :: String.t()
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
  [{:earmark, "~> 0.1", only: :dev}, {:ex_doc, "~> 0.11", only: :dev}]
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

![ExDoc Screenshot 1](/images/documentation_1.png)

Kita dapat lihat bahawa Earmark telah memproses markdown kita dan ExDoc memaparkannnya di dalam format yang berguna.

![ExDoc Screenshot 2](/images/documentation_2.png)

Sekarang kita boleh melakukan deploy ke Github, laman web kita sendiri, atau [HexDocs](https://hexdocs.pm/).

## Amalan Terbaik

Amalan menambahkan dokumentasi sepatutnya dimasukkan sebagai salah satu panduan amalan terbaik bahasa ini.  Oleh sebab Eixir ialah bahasa yang agak baharu masih banyak standard untuk diterokai sepadan dengan pertumbuhan ekosistemnya.  Bagaimanapun, komuniti ini telah melakukan banyak usaha untuk memantapkan amalan-amalan terbaik.  Untuk membaca lebih lanjut berkenaan amalan-amalan terbaik, sila lihat [The Elixir Style Guide](https://github.com/niftyn8/elixir_style_guide).

  - Selalu mendokumentasi sesatu modul.

```elixir
defmodule Greeter do
  @moduledoc """
  This is good documentation.
  """

end
```

  - Jika anda tidak berniat untuk mendokumentasi sesatu modul, **jangan** tinggalkannya kosong.  Catatkan modul itu sebagai `false` seperti berikut:

```elixir
defmodule Greeter do
  @moduledoc false

end
```

 - Apabila merujuk kepada fungsi-fungsi dari dalam dokumentasi, gunakan simbol backtick seperti berikut:

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

 - Pisahkan semua kod dari dokumentasi dengan satu baris dari bawah `@moduledoc` seperti berikut:

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

 - Gunakan markdown dari dalam fungsi yang akan menjadikannya lebih senang untuk dibaca melaui IEx atau ExDoc.

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

 - Cuba untuk memasukkan contoh-contoh kod ke dalam dokumetasi anda, ini juga memudahkan anda menjana ujian-ujian otomatik daripada kod-kod contoh di dalam sesatu modul, fungsi atau makro menggunakan [ExUnit.DocTest][ExUnit.DocTest].  Untuk melaksanakannya, anda perlu memanggil makro `doctest/1` daripada kes ujian dan tuliskan contoh-contoh berpandukan kepada [dokumentasi rasmi][ExUnit.DocTest].

[ExUnit.DocTest]: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html
