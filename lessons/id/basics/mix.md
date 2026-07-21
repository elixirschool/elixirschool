%{
  version: "1.1.3",
  title: "Mix",
  excerpt: """
  Sebelum kita dapat menyelami lebih dalam Elixir, pertama-tama kita perlu mempelajari tentang Mix.
  Jika Anda familiar dengan Ruby, Mix adalah gabungan dari Bundler, RubyGems, dan Rake.
  Ini adalah bagian penting dari setiap proyek Elixir dan dalam pelajaran ini kita akan menjelajahi beberapa fitur hebatnya.
  Untuk melihat semua yang ditawarkan Mix di lingkungan saat ini, jalankan `mix help`.

  Sampai sekarang kita telah bekerja secara eksklusif di dalam `iex` yang memiliki keterbatasan.
  Untuk membangun sesuatu yang substansial, kita perlu membagi kode kita menjadi banyak file agar dapat dikelola secara efektif; Mix memungkinkan kita melakukan itu dengan proyek.
  """
}
---

## Project Baru

Saat kita siap membuat proyek Elixir baru, Mix mempermudahnya dengan perintah `mix new`.
Ini akan menghasilkan struktur folder proyek kita dan file-file dasar yang diperlukan.
Mari kita mulai:

```bash
mix new example
```

Dari outputnya kita dapat melihat bahwa Mix telah membuat direktori kita dan sejumlah file dasar:

```bash
* creating README.md
* creating .formatter.exs
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/example.ex
* creating test
* creating test/test_helper.exs
* creating test/example_test.exs
```

Dalam pelajaran ini kita akan memfokuskan perhatian kita pada `mix.exs`.
Di sini kita mengkonfigurasi aplikasi, dependensi, lingkungan, dan versi kita.
Buka file tersebut di editor favorit Anda, Anda akan melihat sesuatu seperti ini (komentar dihapus untuk mempersingkat):

```elixir
defmodule Example.MixProject do
  use Mix.Project

  def project do
    [
      app: :example,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end
end
```

Bagian pertama yang akan kita lihat adalah `project`.
Di sini kita mendefinisikan nama aplikasi (`app`), menentukan versi (`version`), versi Elixir (`elixir`), dan akhirnya dependensi (`deps`).

Bagian `application` digunakan selama pembuatan file aplikasi yang akan kita bahas nanti.

## Interaktif

Mungkin perlu menggunakan `iex` dalam konteks aplikasi kita.
Kita dapat memulai sesi `iex` baru:

```bash
cd example
iex -S mix
```

Menjalankan `iex` dengan cara ini akan memuat aplikasi dan dependensi Anda ke dalam runtime saat ini.

## Kompilasi

Mix itu cerdas dan akan mengkompilasi perubahan Anda jika diperlukan, tetapi mungkin masih perlu untuk mengkompilasi proyek Anda secara eksplisit.
Di bagian ini kita akan membahas cara mengkompilasi proyek kita dan apa yang dilakukan kompilasi.

Untuk mengkompilasi proyek Mix, kita hanya perlu menjalankan `mix compile` di direktori dasar kita:
**Catatan: Tugas Mix untuk sebuah proyek hanya tersedia dari direktori root proyek, hanya tugas Mix global yang tersedia selain itu.**

```bash
mix compile
```

Tidak banyak yang ada dalam project kita sehingga output nya tidak begitu menarik, tapi kompilasinya harusnya selesai dengan baik:

```bash
Compiled lib/example.ex
Generated example app
```

Saat kita mengkompilasi sebuah proyek, Mix membuat direktori `_build` untuk artefak kita.
Jika kita melihat ke dalam `_build`, kita akan melihat aplikasi yang telah dikompilasi: `example.app`.

## Mengelola Dependensi

Proyek kita belum memiliki dependensi, tetapi akan segera memilikinya, jadi kita akan membahas cara mendefinisikan dependensi dan mengambilnya.

Untuk menambahkan dependensi baru, kita perlu menambahkannya terlebih dahulu ke `mix.exs` di bagian `deps`.
Daftar dependensi kita terdiri dari tuple dengan dua nilai wajib dan satu nilai opsional: nama paket sebagai atom, string versi, dan opsi opsional.

Untuk contoh ini, mari kita lihat sebuah proyek dengan dependensi, seperti [phoenix_slim](https://github.com/doomspork/phoenix_slim):

```elixir
def deps do
  [
    {:phoenix, "~> 1.8"},
    {:phoenix_html, "~> 4.3"},
    {:cowboy, "~> 2.12", only: [:dev, :test]},
    {:slime, "~> 1.3"}
  ]
end
```

Seperti yang mungkin Anda pahami dari dependensi di atas, dependensi `cowboy` hanya diperlukan selama pengembangan dan pengujian.

Setelah kita mendefinisikan dependensi kita, ada satu langkah terakhir: mengambilnya.
Ini mirip dengan `bundle install`:

```bash
mix deps.get
```

Selesai! Kita sudah mendefinisikan dan mengambil dependensi proyek kita.
Sekarang kita siap untuk menambahkan dependensi ketika saatnya tiba.

## Lingkungan

Mix, seperti halnya Bundler, mendukung berbagai lingkungan.
Secara default, Mix dikonfigurasi untuk memiliki tiga lingkungan:

- `:dev` — Lingkungan default.
- `:test` — Digunakan oleh `mix test`. Dibahas lebih lanjut di pelajaran berikutnya.
- `:prod` — Digunakan saat kita meluncurkan aplikasi ke lingkungan produksi.

Lingkungan saat ini dapat diakses menggunakan `Mix.env`.
Seperti yang diharapkan, lingkungan dapat diubah melalui variabel lingkungan `MIX_ENV`:

```bash
MIX_ENV=prod mix compile
```
