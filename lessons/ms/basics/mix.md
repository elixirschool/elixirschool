%{
  version: "0.9.2",
  title: "Mix",
  excerpt: """
  Sebelum kita belajar lebih mendalam mengenai Elixir kita perlu memahami tentang mix.  Jika anda biasa dengan Ruby, mix adalah gabungan Bundler, RubyGems dan Rake.  Ia adalah elemen penting di dalam mana-mana projek Elixir dan di dalam pelajaran ini kita akan meneroka beberapa cirinya yang hebat.  Untuk melihat apa yang dibekalkan oleh mix, jalankan `mix help`.

Sehingga tahap ini kita telah bekerja dengan `iex` yang mempunyai banyak kekangan.  Untuk membina sesuatu yang berguna kita perlu memisahkan kod kita kepada banyak fail supaya mudah untuk diuruskan, dan mix memudahkan kita menguruskan projek-projek kita.
  """
}
---

## Projek Baru

Apabila kita bersedia untuk membina satu projek baru Elixir, mix memudahkannya dengan arahan `mix new`.  Ini akan menjana struktur direktori projek dan plat dandang(boilerplate) yang berkaitan.  Ianya agak mudah, jadi mari kita mulakan:

```bash
$ mix new example
```

Daripada paparan output kita boleh melihat yang mix telah membuat direktori kita dan beberapa fail plat dandang:

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

Di dalam pelajaran ini kita akan memberi fokus kepada `mix.exs`.  Di sini kita membuat tetapan aplikasi kita, komponen sokongan, persekitaran, dan versi.  Buka fail tersebut di dalam perisian suntingan teks kegemaran anda, anda sepatutnya dapat melihat sesuatu seperti ini(komen-komen dibuang untuk memudahkan pembacaan):

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

Bahagian pertama yang akan kita lihat ialah `project`.  Di sini kita tetapkan nama aplikasi kita (`app`), versi kita (`version`), versi Elixir (`elixir`), dan akhir sekali komponen sokongan (`deps`).

Bahagian `application` digunakan semasa penjanaan fail aplikasi kita yang akan kita lihat seterusnya.

## Interaktif

Ada kemungkinan di mana `iex` perlu digunakan di dalam konteks aplikasi kita.  Kita bernasib baik, mix telah memudahkan kita.  Kita boleh menjalankan satu sesi `iex` baru:

```bash
$ cd example
$ iex -S mix
```

Menjalankan `iex` dengan cara ini akan memuatkan aplikasi kita dan komponen sokongan ke dalam runtime semasa.

## Pengkompilan

Mix adalah pintar dan akan mengkompil perubahan anda apabila diperlukan, tetapi ada kemungkinan di mana kita perlu menyatakan keperluan pengkompilan secara nyata di dalam projek kita.  Di dalam bahagian ini kita akan lihat bagaimana untuk mengkompil projek dan apa yang dilakukan oleh pengkompil.

Untuk mengkompil projek, kita hanya perlu jalankan `mix compile` di dalam direktori induk:

```bash
$ mix compile
```

Projek kita tidak mempunyai banyak kandungan jadi paparan output tidak begitu menarik tetap ia sepatutnya berjaya dijalankan:

```bash
Compiled lib/example.ex
Generated example app
```

Apabila kita kompilkan satu projek, mix akan membuat direktori `_build`.  Jika kita melihat ke dalam `_build` kita akan nampak fail kompilan aplikasi kita: `example.app`.

## Mengurus Komponen Sokongan

Projek kita masih belum mengandungi apa-apa komponen sokongan, jadi kita akan teruskan dan lihat bagaimana untuk membuat tetapan dan memuatkan komponen sokongan.

Untuk memuatkan satu komponen sokongan baru, kita perlu masukkan ia ke dalam fail `mix.exs` di bahagian `deps`.  Senarai komponen sokongan adalah sekumpulan tuple yang mengandungi dua nilai wajib dan  satu nilai pilihan:  Nama pakej dalam bentuk atom, versi dalam bentuk string, dan nilai-nilai pilihan.

Sebagai contoh mari kita lihat satu projek yang mengandungi komponen sokongan, seperti [phoenix_slim](https://github.com/doomspork/phoenix_slim):

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

Sebagaimana yang dapat anda lihat dari senarai komponen sokongan di atas, komponen sokongan `cowboy` cuma diperlukan dalam persekitaran pembangunan(dev) dan pengujian(test).

Setelah membuat tetapan komponen sokongan langkah terakhir ialah memuatkan mereka.  Ini adalah sama dengan `bundle install`:

```bash
$ mix deps.get
```

Itu sahaja!  Kita telah membuat tetapan dan memuatkan komponen sokongan untuk projek kita.  Sekarang kita telah bersedia untuk memuatkan komponen sokongan lain apabila diperlukan.

## Persekitaran

Mix, seperti Bundler, menyokong pelbagai persekitaran(environment).  Secara lalai, mix boleh digunakan dalam tiga persekitaran:

+ `:dev` — persekitaran lalai.
+ `:test` — Digunakan oleh `mix test`.  Akan dilihat lebih lanjut dalam pelajaran seterusnya.
+ `:prod` — Digunakan apabila memasang aplikasi kita dalam persekitaran pengeluaran(production)

Nilai persekitaran semasa boleh dicapai menggunakan `Mix.env`.  ilai persekitaran juga boleh diubah menggunakan pembolehubah `MIX_ENV`:

```bash
$ MIX_ENV=prod mix compile
```
