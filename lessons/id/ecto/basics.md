%{
  version: "2.4.0",
  title: "Dasar Ecto",
  excerpt: """
  Ecto adalah proyek Elixir resmi yang menyediakan pembungkus basis data dan bahasa kueri terintegrasi. Dengan Ecto, kita dapat membuat migrasi, mendefinisikan skema, menyisipkan dan memperbarui data, serta melakukan kueri terhadap data tersebut.
  """
}
---

### Adapter

Ecto mendukung berbagai basis data melalui penggunaan adapter. Beberapa contoh adapter adalah:

* PostgreSQL
* MySQL
* SQLite

Untuk pelajaran ini, kita akan mengkonfigurasi Ecto untuk menggunakan adapter PostgreSQL.

### Memulai

Sepanjang pelajaran ini, kita akan membahas tiga bagian Ecto:

* Repositori — menyediakan antarmuka ke basis data kita, termasuk koneksi
* Migrasi — mekanisme untuk membuat, memodifikasi, dan menghapus tabel dan indeks basis data
* Skema — struktur khusus yang mewakili entri tabel basis data

Untuk memulai, kita akan membuat aplikasi dengan pohon supervisi.

```shell
mix new friends --sup
cd friends
```

Tambahkan dependensi paket ecto dan postgrex ke file `mix.exs` Anda.

```elixir
  defp deps do
    [
      {:ecto_sql, "~> 3.2"},
      {:postgrex, "~> 0.15"}
    ]
  end
```

Ambil dependensi menggunakan:

```shell
mix deps.get
```

#### Membuat Repositori

Repositori di Ecto dipetakan ke penyimpanan data seperti basis data Postgres kita.
Semua komunikasi ke basis data akan dilakukan menggunakan repositori ini.

Siapkan repositori dengan menjalankan:

```shell
mix ecto.gen.repo -r Friends.Repo
```

Ini akan menghasilkan konfigurasi yang diperlukan di `config/config.exs` untuk terhubung ke basis data termasuk adaptor yang akan digunakan.
Ini adalah file konfigurasi untuk aplikasi `Friends` kita.

```elixir
config :friends, Friends.Repo,
  database: "friends_repo",
  username: "postgres",
  password: "",
  hostname: "localhost"
```

Ini mengkonfigurasi cara Ecto terhubung ke basis data. Anda mungkin perlu mengkonfigurasi basis data Anda agar memiliki kredensial yang sesuai.

Ini juga membuat modul `Friends.Repo` di dalam `lib/friends/repo.ex`.

```elixir
defmodule Friends.Repo do
  use Ecto.Repo, 
    otp_app: :friends,
    adapter: Ecto.Adapters.Postgres
end
```

Kita akan menggunakan modul `Friends.Repo` untuk melakukan query ke database. Kita juga memberi tahu modul ini untuk menemukan informasi konfigurasi database-nya di aplikasi Elixir `:friends` dan kita memilih adapter `Ecto.Adapters.Postgres`.

Selanjutnya, kita akan mengatur `Friends.Repo` sebagai supervisor di dalam pohon supervisi aplikasi kita di `lib/friends/application.ex`.
Ini akan memulai proses Ecto saat aplikasi kita dijalankan.

```elixir
  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      Friends.Repo,
    ]

  ...
```

Setelah itu, kita perlu menambahkan baris berikut ke file `config/config.exs` kita:

```elixir
config :friends, ecto_repos: [Friends.Repo]
```

Ini akan memungkinkan aplikasi kita untuk menjalankan perintah ecto mix dari baris perintah.

Kita sudah selesai mengkonfigurasi repositori!
Sekarang kita dapat membuat basis data di dalam postgres dengan perintah ini:

```shell
mix ecto.create
```

Ecto akan menggunakan informasi dalam file `config/config.exs` untuk menentukan cara terhubung ke Postgres dan nama apa yang akan diberikan pada basis data.

Jika Anda menerima kesalahan apa pun, pastikan informasi konfigurasi sudah benar dan instance postgres Anda sedang berjalan.

### Migrasi

Untuk membuat dan memodifikasi tabel di dalam basis data postgres, Ecto menyediakan migrasi.
Setiap migrasi menjelaskan serangkaian tindakan yang akan dilakukan pada basis data kita, seperti tabel mana yang akan dibuat atau diperbarui.

Karena basis data kita belum memiliki tabel, kita perlu membuat migrasi untuk menambahkannya.
Konvensi di Ecto adalah menggunakan bentuk jamak untuk tabel kita. Untuk aplikasi kita, kita membutuhkan tabel `people`, jadi mari kita mulai dari sana dengan migrasi kita.

Cara terbaik untuk membuat migrasi adalah dengan menggunakan tugas `mix ecto.gen.migration <name>`, jadi dalam kasus kita, mari kita gunakan:

```shell
mix ecto.gen.migration create_people
```

Ini akan menghasilkan file baru di folder `priv/repo/migrations` yang berisi stempel waktu dalam nama file.
Jika kita menavigasi ke direktori kita dan membuka migrasi, kita akan melihat sesuatu seperti ini:

```elixir
defmodule Friends.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do

  end
end
```

Mari kita mulai dengan memodifikasi fungsi `change/0` untuk membuat tabel baru `people` dengan `name` dan `age`:

```elixir
defmodule Friends.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do
    create table(:people) do
      add :name, :string, null: false
      add :age, :integer, default: 0
    end
  end
end
```

Seperti yang Anda lihat di atas, kami juga telah mendefinisikan tipe data kolom.
Selain itu, kami juga menyertakan `null: false` dan `default: 0` sebagai opsi.

Mari kita langsung ke shell dan jalankan migrasi kita:

```shell
mix ecto.migrate
```

### Skema

Setelah kita membuat tabel awal, kita perlu memberi tahu Ecto lebih banyak tentang tabel tersebut, dan salah satu caranya adalah melalui skema.
Skema adalah modul yang mendefinisikan pemetaan ke bidang tabel basis data yang mendasarinya.

Meskipun Ecto lebih menyukai bentuk jamak untuk nama tabel basis data, skema biasanya tunggal, jadi kita akan membuat skema `Person` untuk menyertai tabel kita.

Mari kita buat skema baru kita di `lib/friends/person.ex`:

```elixir
defmodule Friends.Person do
  use Ecto.Schema

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

Di sini kita dapat melihat bahwa modul `Friends.Person` memberi tahu Ecto bahwa skema ini berkaitan dengan tabel `people` dan bahwa kita memiliki dua kolom: `name` yang merupakan string dan `age`, sebuah bilangan bulat dengan nilai default `0`.

Mari kita lihat skema kita dengan membuka `iex -S mix` dan membuat orang baru:

```elixir
iex> %Friends.Person{}
%Friends.Person{age: 0, name: nil}
```

Seperti yang diharapkan, kita mendapatkan `Person` baru dengan nilai default yang diterapkan pada `age`.
Sekarang mari kita buat orang "nyata":

```elixir
iex> person = %Friends.Person{name: "Tom", age: 11}
%Friends.Person{age: 11, name: "Tom"}
```

Karena skema hanyalah sebuah struktur (struct), kita dapat berinteraksi dengan data kita seperti yang biasa kita lakukan:

```elixir
iex> person.name
"Tom"
iex> Map.get(person, :name)
"Tom"
iex> %{name: name} = person
%Friends.Person{age: 11, name: "Tom"}
iex> name
"Tom"
```

Demikian pula, kita dapat memperbarui skema kita seperti halnya kita memperbarui map atau struktur lainnya di Elixir:

```elixir
iex> person = %{person | age: 18}
%Friends.Person{age: 18, name: "Tom"}
iex> Map.put(person, :name, "Jerry")
%Friends.Person{age: 18, name: "Jerry"}
```

Pada pelajaran kita selanjutnya tentang Changeset, kita akan melihat bagaimana cara memvalidasi perubahan data kita dan akhirnya bagaimana cara menyimpannya ke dalam basis data kita.
