%{
  version: "1.2.1",
  title: "Dokumentasi",
  excerpt: """
  Mendokumentasikan kode Elixir.
  """
}
---

## Anotasi

Seberapa banyak kita membuat komentar dan apa yang membuat dokumentasi berkualitas adalah isu yang diperdebatkan dalam dunia pemrograman.
Kita sepakat bahwa dokumentasi penting bagi diri kita sendiri dan mereka yang bekerja dengan basis kode kita.
Elixir memperlakukan dokumentasi sebagai *warga negara kelas satu*, menawarkan berbagai fungsi untuk mengakses dan menghasilkan dokumentasi untuk proyek Anda.
Inti Elixir menyediakan banyak atribut berbeda untuk memberi anotasi pada basis kode.

Mari kita lihat tiga caranya:

- `#` - Untuk dokumentasi inline.
- `@moduledoc` - Untuk dokumentasi tingkat modul.
- `@doc` - Untuk dokumentasi tingkat fungsi.

### Dokumentasi Inline

Mungkin cara paling sederhana untuk memberi komentar pada kode Anda adalah dengan komentar sebaris.
Mirip dengan Ruby atau Python, komentar sebaris Elixir ditandai dengan `#`, yang sering dikenal sebagai *pound* atau *hash* tergantung dari mana Anda berasal di dunia.

Coba lihat skrip Elixir berikut (greeting.exs):

```elixir
# Outputs 'Hello, chum.' to the console.
IO.puts("Hello, " <> "chum.")
```

Elixir, saat menjalankan skrip ini, akan mengabaikan semua yang ada dari `#` hingga akhir baris, memperlakukannya sebagai data yang tidak penting.
Mungkin tidak menambah nilai pada operasi atau kinerja skrip, namun ketika kurang jelas apa yang terjadi, seorang programmer harus mengetahuinya dari membaca komentar Anda.
Berhati-hatilah agar tidak terlalu sering menggunakan komentar satu baris! Mengotori kode bisa jadi menyusahkan untuk sebagian orang.
Sebaiknya digunakan secukupnya.

### Mendokumentasikan Modul

Anotasi `@moduledoc` memungkinkan dokumentasi inline pada tingkat modul.
Biasanya terletak di bawah deklarasi `defmodule` di bagian atas file.
Contoh di bawah ini menunjukkan komentar satu baris di dalam dekorator `@moduledoc`.

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

Kita (atau orang lain) dapat mengakses dokumentasi modul ini menggunakan fungsi pembantu `h` di dalam IEx.
Namun, menggunakan fungsi pembantu `h` segera setelah membuat modul di `iex` dapat menyebabkan masalah berikut:

```elixir
iex> h Greeter
Greeter was not compiled with docs
```
Alasan: Saat kode dimasukkan ke dalam `iex`, shell interaktif Elixir mengkompilasinya di memori tanpa secara otomatis menulis kode yang telah dikompilasi ke disk. Menyimpan bytecode yang telah dikompilasi memerlukan instruksi eksplisit, baik dengan menyimpan bytecode secara eksplisit atau dengan menggunakan fungsi I/O file Elixir untuk menuliskannya ke file.

Pertimbangkan skenario di mana terdapat file bernama `greeter.ex` di direktori kerja saat ini, dan sesi `iex` diluncurkan dari sana:

```elixir
iex> c("greeter.ex")
[Greeter]

iex> h Greeter
Greeter was not compiled with docs
```

Menemukan masalah yang sama di sini adalah hal yang wajar karena sifat dari `c("greeter.ex")`. Perintah ini mengkompilasi berkas di memori tetapi tidak secara otomatis menulis bytecode (berkas `.beam`) ke disk. Namun, agar helper `h/1` berfungsi dengan benar, file `.beam` perlu ada di disk.

Untuk mengatasi hal ini, penting untuk menginstruksikan `c` untuk menyimpan bytecode yang dihasilkan di direktori saat ini. Tindakan ini memungkinkan helper `h/1` untuk mengakses dan menampilkan dokumentasi sebagaimana mestinya.

```elixir
iex> c("greeter.ex", ".")
[Greeter]

iex> h Greeter

                Greeter

Provides a function hello/1 to greet a human
```

*Catatan*: Kita tidak perlu mengkompilasi file secara manual seperti yang kita lakukan di atas jika kita bekerja dalam konteks proyek mix. Anda dapat menggunakan `iex -S mix` untuk memuat konsol IEx untuk proyek saat ini jika Anda bekerja dalam proyek mix.

### Mendokumentasikan Fungsi

Elixir memberi kita kemampuan untuk anotasi tingkat modul dan juga memungkinkan anotasi serupa untuk mendokumentasikan fungsi.
Anotator `@doc` memungkinkan dokumentasi sebaris pada tingkat fungsi.
Anotator `@doc` berada tepat di atas fungsi yang dianotasi.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message.

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

Jika kita masuk ke IEx lagi dan menggunakan perintah pembantu (`h`) pada fungsi yang diawali dengan nama modul, kita akan melihat hasil berikut:

```elixir
iex> c("greeter.ex", ".")
[Greeter]

iex> h Greeter.hello

                def hello(name)

  @spec hello(String.t()) :: String.t()

Prints a hello message.

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"

iex>
```

Perhatikan bagaimana Anda dapat menggunakan markup di dalam dokumentasi kami dan terminal akan menampilkannya? Selain sangat keren dan merupakan tambahan baru bagi ekosistem Elixir yang luas, hal ini menjadi jauh lebih menarik ketika kita melihat ExDoc untuk menghasilkan dokumentasi HTML secara instan.

**Catatan:** Anotasi `@spec` digunakan untuk menganalisis kode secara statis.
Untuk mempelajari lebih lanjut tentang hal ini, lihat pelajaran [Spesifikasi dan tipe](/id/lessons/advanced/typespec).

## ExDoc

ExDoc adalah proyek Elixir resmi yang dapat ditemukan di [GitHub](https://github.com/elixir-lang/ex_doc).
Proyek ini menghasilkan **HTML (HyperText Markup Language) dan dokumentasi online** untuk proyek Elixir.
Pertama, mari kita buat proyek Mix untuk aplikasi kita:

```bash
$ mix new greet_everyone

* creating README.md
* creating .formatter.exs
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

Salin dan tempel kode dari pelajaran anotator `@doc` ke dalam file bernama `lib/greeter.ex` dan pastikan semuanya masih berfungsi dari baris perintah.
Sekarang kita bekerja dalam proyek Mix, kita perlu memulai IEx sedikit berbeda menggunakan urutan perintah `iex -S mix`:

```elixir
iex> h Greeter.hello

                def hello(name)

  @spec hello(String.t()) :: String.t()

Prints a hello message.

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"
```

### Menginstal

Dengan asumsi semuanya berjalan lancar dan kita melihat output di atas, kita sekarang siap untuk mengatur ExDoc.
Di dalam file `mix.exs`, tambahkan dependensi `:ex_doc` untuk memulai.

```elixir
  def deps do
    [{:ex_doc, "~> 0.21", only: :dev, runtime: false}]
  end
```

Kita menentukan pasangan key-value `only: :dev` karena kita tidak ingin mengunduh dan mengkompilasi dependensi `ex_doc` di lingkungan produksi.

`ex_doc` juga akan menambahkan pustaka lain untuk kita, Earmark.

Earmark adalah parser Markdown untuk bahasa pemrograman Elixir yang digunakan ExDoc untuk mengubah dokumentasi kita di dalam `@moduledoc` dan `@doc` menjadi HTML yang indah.

Perlu dicatat pada titik ini bahwa Anda dapat mengubah alat markup menjadi Cmark jika Anda mau, tetapi Anda perlu melakukan sedikit konfigurasi tambahan yang dapat Anda baca [di sini](https://hexdocs.pm/ex_doc/ExDoc.Markdown.html#module-using-cmark).
Untuk tutorial ini, kita akan tetap menggunakan Earmark.

### Membuat Dokumentasi

Selanjutnya, jalankan dua perintah berikut dari baris perintah:

```bash
$ mix deps.get # mengunduh ExDoc + Earmark.
$ mix docs # membuat dokumentasi.

Docs successfully generated.
View them at "doc/index.html".
```

Jika semuanya berjalan sesuai rencana, Anda akan melihat pesan yang mirip dengan pesan output pada contoh di atas.
Sekarang mari kita lihat ke dalam proyek Mix kita dan kita akan melihat ada direktori lain yang disebut **doc/**.
Di dalamnya terdapat dokumentasi yang telah kita buat.
Jika kita mengunjungi halaman indeks di browser kita, kita akan melihat hal berikut:

![ExDoc Screenshot 1](/images/documentation_1.png)

Kita dapat melihat bahwa Earmark telah merender Markdown kita dan ExDoc sekarang menampilkannya dalam format yang berguna.

![ExDoc Screenshot 2](/images/documentation_2.png)

Kita sekarang dapat menyebarkan ini ke GitHub, situs web kita sendiri, atau yang lebih umum [HexDocs](https://hexdocs.pm/).

## Praktik Terbaik

Dokumentasi harus ditambahkan dalam Pedoman Praktik Terbaik bahasa tersebut.
Karena Elixir adalah bahasa yang relatif baru, banyak standar masih perlu ditemukan seiring pertumbuhan ekosistemnya.
Namun, komunitas telah mencoba untuk menetapkan praktik terbaik.
Untuk membaca lebih lanjut tentang praktik terbaik, lihat [Panduan Gaya Elixir](https://github.com/niftyn8/elixir_style_guide).

- Selalu dokumentasikan sebuah modul.

```elixir
defmodule Greeter do
  @moduledoc """
  Ini adalah dokumentasi yang baik.
  """

end
```

- Jika Anda tidak bermaksud mendokumentasikan modul, **jangan** biarkan kosong.
Pertimbangkan untuk memberi anotasi `false` pada modul, seperti ini:

```elixir
defmodule Greeter do
  @moduledoc false

end
```

- Saat merujuk pada fungsi dalam dokumentasi modul, gunakan tanda backtick seperti ini:

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

- Pisahkan semua kode satu baris di bawah `@moduledoc` seperti ini:

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

- Gunakan Markdown di dalam dokumen.
Ini akan mempermudah pembacaan baik melalui IEx maupun ExDoc.

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

- Cobalah untuk menyertakan beberapa contoh kode dalam dokumentasi Anda.
Ini juga memungkinkan Anda untuk menghasilkan pengujian otomatis dari contoh kode yang ditemukan dalam modul, fungsi, atau makro dengan [ExUnit.DocTest][].
Untuk melakukan itu, Anda perlu memanggil makro `doctest/1` dari *test case* Anda dan menulis contoh Anda sesuai dengan beberapa panduan seperti yang dijelaskan dalam [dokumentasi resmi][ExUnit.DocTest].

[ExUnit.DocTest]: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html
