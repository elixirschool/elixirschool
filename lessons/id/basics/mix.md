%{
  version: "0.9.2",
  title: "Mix",
  excerpt: """
  Sebelum kita bisa masuk ke pelajaran Elixir lebih mendalam pertama-tama kita harus belajar tentang mix. Jika anda sudah familiar dengan Ruby, mix adalah seperti gabungan dari Bundler, RubyGems, dan Rake.  Mix adalah bagian krusial dari project Elixir apapun dan dalam pelajaran ini kita akan mengeksplorasi sebagian dari fitur-fiturnya. Untuk melihat semua yang bisa dilakukan oleh mix, jalankan `mix help`.

  Sampai sekarang kita hanya bekerja dengan `iex` yang punya keterbatasan.  Untuk membuat sesuatu yang bermakna, kita perlu memecah code kita ke banyak file agar bisa mengaturnya dengan efektir. Mix memungkinkan kita melakukan hal itu dengan project.
  """
}
---

## Project Baru

Ketika kita siap untuk membuat sebuah project Elixir baru, mix membuatnya mudah dengan perintah `mix new`.  Perintah ini akan membuat struktur folder dan prasyarat (boilerplate) yang dibutuhkan untuk project kita.  Hal ini cukup sederhana, jadi mari kita mulai:

```bash
$ mix new example
```

Dari outputnya kita bisa melihat bahwa mix sudah membuat direktori kita dan sejumlah file boilerplate:

```bash
* creating README.md
* creating .gitignore
* creating .formatter.exs
* creating mix.exs
* creating lib
* creating lib/example.ex
* creating test
* creating test/test_helper.exs
* creating test/example_test.exs
```

Dalam pelajaran ini kita akan berfokus pada `mix.exs`.  Di sini kita mengkonfigurasi aplikasi, dependeksi, environment, dan versi kita.  Bukalah file tersebut di editor favorit anda, anda akan melihat seperti berikut (komentar dibuang untuk meringkas tampilan):

```elixir
defmodule Example.Mix do
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

Bagian pertama yang akan kita lihat adalah `project`.  Di sini kita mendefinisikan nama aplikasi kita (`app`), menyatakan versi kita (`version`), versi Elixir (`elixir`), dan terakhir dependensi (`deps`).

Bagian `application` digunakan dalam proses pembuatan file aplikasi kita yang akan kita bahas nanti.

## Interaktif

Mungkin kita perlu menggunakan `iex` dalam konteks aplikasi kita.  Untungnya, mix mempermudah hal ini.  Kita bisa memulasi sebuah sesi `iex` baru:

```bash
$ cd example
$ iex -S mix
```

Memulai `iex` dengan cara ini akan memuat aplikasi anda dan dependensinya ke dalam runtime yang berjalan.

## Kompilasi

Mix cerdas dan akan mengkompilasi perubahan yang anda lakukan jika perlu, tetapi mungkin masih perlu mengkompilasi project anda secara eksplisit.  Dalam bagian ini kita akan membahas cara mengkompilasi project kita dan apa yang dilakukan oleh kompilasi.

Untuk mengkompilasi sebuah project mix kita hanya perlu menjalankan `mix compile` di direktori dasar:

```bash
$ mix compile
```

Tidak banyak yang ada dalam project kita sehingga output nya tidak begitu menarik, tapi kompilasinya harusnya selesai dengan baik:

```bash
Compiled lib/example.ex
Generated example app
```

Ketika kita mengkompilasi sebuah project, mix membuat sebuah direktori `_build` untuk artifak kita.  Jika kita melihat ke dalam `_build` kita akan melihat aplikasi kita yang sudah dikompilasi: `example.app`.

## Menata Dependensi

Project kita tidak punya dependensi (dependency, project lain yang dibutuhkan), sekarang ini, tapi akan punya, sehingga kita akan membahas tentang mendefinisikan ketergantungan dan mengambilnya.

Untuk menambahkan sebuah dependensi baru, kita perlu terlebih dulu menambahkannya ke file `mix.exs` kita di bagian `deps`.  Daftar dependensi kita terdiri dari tuple dengan dua value yang harus ada dan satu opsional: Nama paket (package) sebagai sebuah atom, string berisi versi, dan pilihan opsional.

Untuk contoh ini mari lihat sebuah project dengan dependensi, seperti [phoenix_slim](https://github.com/doomspork/phoenix_slim):

```elixir
def deps do
  [
    {:phoenix, "~> 1.1 or ~> 1.2"},
    {:phoenix_html, "~> 2.3"},
    {:cowboy, "~> 1.0", only: [:dev, :test]},
    {:slime, "~> 0.14"}
  ]
end
```

Seperti yang mungkin sudah anda pahami dari contoh di atas, dependensi `cowboy` hanya dibutuhkan selama development dan tes.

Begitu kita telah mendefinisikan dependensi kita, ada satu langkah terakhir, mengambilnya.  Ini analog dengan `bundle install`:

```bash
$ mix deps.get
```

Selesai!  Kita sudah mendefinisikan dan mangambil dependensi project kita.  Sekarang kita sudah siap untuk manambahkan dependensi jika saatnya tiba.

## Environment

Mix, seperti Bundler, mendukung pembedaan environment.  Secara default mix bekerja dengan tiga environment:

+ `:dev` — Environment default.
+ `:test` — Digunakan oleh `mix test`. Dibahas lebih jauh di pelajaran kita berikutnya.
+ `:prod` — Digunakan ketika kita meluncurkan aplikasi kita di production.

Environment yang sedang berjalan dapat diakses menggunakan `Mix.env`.  Sebagaimana diduga, environment bisa diubah dengan environment variable `MIX_ENV`:

```bash
$ MIX_ENV=prod mix compile
```
