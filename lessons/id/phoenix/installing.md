%{
  version: "1.1.0",
  title: "Menginstal Phoenix",
  excerpt: """
  Dengan beberapa langkah sederhana, Anda dapat menginstal dan membuat proyek Phoenix pertama Anda.
  """
}
---

## Memulai

### Beberapa Pertimbangan

Sebelum membuat proyek Phoenix, kita perlu menginstal Elixir. Versi terbaru framework Phoenix membutuhkan [Elixir 1.15 atau lebih baru](https://hexdocs.pm/phoenix/installation.html#elixir-1-15-or-later) dan [Erlang 24 atau lebih baru](https://hexdocs.pm/phoenix/installation.html#erlang-24-or-later).

Kita juga membutuhkan basis data untuk menjalankan aplikasi kita, kami sarankan Anda untuk menginstal PostgreSQL. Anda dapat memeriksa [panduan instalasi](https://wiki.postgresql.org/wiki/Detailed_installation_guides) untuk menginstalnya.

**Pengguna Linux**: Kita mungkin perlu menginstal [inotify-tools](https://github.com/inotify-tools/inotify-tools/wiki) untuk menjalankan aplikasi Phoenix.

### Menginstal Phoenix

Untuk memulai, kita perlu menginstal pengelola paket Hex. Pengelola paket diperlukan untuk mendapatkan Aplikasi Phoenix karena beberapa dependensi diinstal bersamanya, dan beberapa dependensi tambahan mungkin diperlukan di sepanjang jalan.

```bash
mix local.hex
```

Setelah menginstal pengelola paket Hex, kita dapat menginstal generator phx.new.

```
mix archive.install hex phx_new
```

Kita akan memiliki semua alat yang diperlukan untuk membuat Proyek Phoenix.

Catatan: Kita perlu menjawab Y untuk mengizinkan keduanya diinstal.

## Membuat Proyek Phoenix Pertama

Untuk membuat proyek baru, cukup jalankan perintah `mix phx.new` dari direktori mana pun untuk memulai aplikasi Phoenix kita. Pada contoh di bawah, kita membuat proyek baru dengan nama `hello`

```bash
$ mix phx.new hello
* creating hello/config/config.exs
* creating hello/config/dev.exs
* creating hello/config/prod.exs
...
Fetch and install dependencies? [Yn]
```

Setelah instalasi selesai, kita dapat mengakses folder proyek dengan `cd hello`

### Konfigurasi Basis Data

Kita perlu mengatur proyek kita agar terhubung ke basis data lokal. Buka folder `config/` dan buka file `dev.exs`, dan kita akan melihat file dengan isi seperti ini.

Jangan lupa untuk mengubah konfigurasi nama pengguna dan kata sandi (jika perlu). Kita mungkin juga perlu mengubah lingkungan pengujian (`config/test.exs`)

```elixir
# Konfigurasi basis data Anda
config :hello, Hello.Repo,
username: "postgres", # Ubah nama pengguna basis data Anda
password: "postgres", # Ubah kata sandi basis data Anda
database: "hello_dev",
hostname: "localhost",
show_sensitive_data_on_connection_error: true,
pool_size: 10
...
...
```

Sekarang kita dapat membuat basis data aplikasi dengan:

```bash
mix ecto.create
```

### Menjalankan aplikasi

Terakhir, kita dapat menjalankan aplikasi dengan:

```bash
mix phx.server
```

Secara default, aplikasi phoenix berjalan di port 4000. Jika kita membuka <http://localhost:4000>, kita akan melihat halaman ini.

![Hello Phoenix page](/images/hello_phoenix.png)
