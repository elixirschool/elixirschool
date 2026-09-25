%{
  version: "1.3.0",
  title: "Kueri Data",
  excerpt: """
  Di pelajaran ini kita akan mempelajari cara mengambil data memakai Ecto.
  """
}
---

Dalam pelajaran ini, kita akan melanjutkan pengembangan aplikasi `Friends` dan domain katalog film yang telah kita buat di [pelajaran sebelumnya](/id/lessons/ecto/associations).

## Mengambil Data dengan Ecto.Repo

Ingat bahwa "repositori" di Ecto dipetakan ke penyimpanan data seperti basis data Postgres kita.
Semua komunikasi ke basis data akan dilakukan menggunakan repositori ini.

Kita dapat melakukan kueri sederhana langsung terhadap `Friends.Repo` kita dengan bantuan beberapa fungsi.

### Mengambil Data berdasarkan ID

Kita dapat menggunakan fungsi `Repo.get/3` untuk mengambil data dari basis data berdasarkan ID-nya. Fungsi ini membutuhkan dua argumen: struktur data yang "dapat dikueri" dan ID data yang akan diambil dari basis data. Fungsi ini mengembalikan struktur yang menjelaskan data yang ditemukan, jika ada. Fungsi ini mengembalikan `nil` jika tidak ada data seperti itu yang ditemukan.

Mari kita lihat contohnya. Di bawah ini, kita akan mendapatkan film dengan ID 1:

```elixir
iex> alias Friends.{Repo, Movie}
iex> Repo.get(Movie, 1)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Perhatikan bahwa argumen pertama yang kita berikan ke `Repo.get/3` adalah modul `Movie` kita. `Movie` dapat diakses melalui kueri karena modul tersebut menggunakan modul `Ecto.Schema` dan mendefinisikan skema untuk struktur datanya. Ini memberi `Movie` akses ke protokol `Ecto.Queryable`. Protokol ini mengubah struktur data menjadi `Ecto.Query`. Kueri Ecto digunakan untuk mengambil data dari repositori. Lebih lanjut tentang kueri akan dibahas nanti.

### Mengambil Data Berdasarkan Atribut

Kita juga dapat mengambil data yang memenuhi kriteria tertentu dengan fungsi `Repo.get_by/3`. Fungsi ini membutuhkan dua argumen: struktur data yang "dapat dikueri" dan klausa yang ingin kita gunakan untuk mengkueri. `Repo.get_by/3` mengembalikan satu hasil dari repositori. Mari kita lihat contohnya:

```elixir
iex> Repo.get_by(Movie, title: "Ready Player One")
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Jika kita ingin menulis kueri yang lebih kompleks, atau jika kita ingin mengembalikan _semua_ catatan yang memenuhi kondisi tertentu, kita perlu menggunakan modul `Ecto.Query`.

## Menulis Kueri dengan Ecto.Query

Modul `Ecto.Query` menyediakan Bahasa Khusus Domain (Domain-Specific Language atau DSL) Kueri yang dapat kita gunakan untuk menulis kueri guna mengambil data dari repositori aplikasi.

### Kueri berbasis kata kunci dengan Ecto.Query.from/2

Kita dapat membuat kueri dengan makro `Ecto.Query.from/2`. Fungsi ini menerima dua argumen: sebuah ekspresi dan daftar kata kunci opsional. Mari kita buat kueri paling sederhana untuk memilih semua film dari repositori kita:

```elixir
iex> import Ecto.Query
iex> query = from(Movie)
#Ecto.Query<from m0 in Friends.Movie>
```

Untuk menjalankan kueri kita, kita menggunakan fungsi `Repo.all/2`. Fungsi ini menerima argumen wajib berupa kueri Ecto dan mengembalikan semua catatan yang memenuhi kondisi kueri tersebut.

```elixir
iex> Repo.all(query)

14:58:03.187 [debug] QUERY OK source="movies" db=1.7ms decode=4.2ms
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

#### Kueri tanpa pengikatan dengan from

Contoh di atas tidak mencakup bagian-bagian paling menarik dari pernyataan SQL. Kita seringkali hanya ingin melakukan kueri untuk bidang tertentu atau memfilter catatan berdasarkan beberapa kondisi. Mari kita ambil `title` dan `tagline` dari semua film yang memiliki judul `"Ready Player One"`:

```elixir
iex> query = from(Movie, where: [title: "Ready Player One"], select: [:title, :tagline])
#Ecto.Query<from m0 in Friends.Movie, where: m0.title == "Ready Player One",
 select: [:title, :tagline]>

iex> Repo.all(query)
SELECT m0."title", m0."tagline" FROM "movies" AS m0 WHERE (m0."title" = 'Ready Player One') []
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    id: nil,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

Harap dicatat bahwa struct yang dikembalikan hanya memiliki field `tagline` dan `title` yang diatur – ini adalah hasil dari bagian `select:` kita.

Kueri seperti ini disebut _bindingless_, karena cukup sederhana sehingga tidak memerlukan binding.

#### Binding dalam kueri

Sejauh ini kita menggunakan modul yang mengimplementasikan protokol `Ecto.Queryable` (contoh: `Movie`) sebagai argumen pertama untuk makro `from`. Namun, kita juga dapat menggunakan ekspresi `in`, seperti ini:

```elixir
iex> query = from(m in Movie)
#Ecto.Query<from m0 in Friends.Movie>
```

Dalam kasus seperti itu, kita menyebut `m` sebagai _binding_ (pengikatan). Binding sangat berguna karena memungkinkan kita untuk merujuk modul di bagian lain dari query. Mari kita pilih judul semua film yang memiliki `id` kurang dari `2`:

```elixir
iex> query = from(m in Movie, where: m.id < 2, select: m.title)
#Ecto.Query<from m0 in Friends.Movie, where: m0.id < 2, select: m0.title>

iex> Repo.all(query)
SELECT m0."title" FROM "movies" AS m0 WHERE (m0."id" < 2) []
["Ready Player One"]
```

Hal yang sangat penting di sini adalah bagaimana output dari query berubah. Menggunakan _ekspresi_ dengan binding di bagian `select:` memungkinkan Anda untuk menentukan dengan tepat bagaimana field yang dipilih akan dikembalikan. Kita dapat meminta tuple, misalnya:

```elixir
iex> query = from(m in Movie, where: m.id < 2, select: {m.title})

iex> Repo.all(query)
[{"Ready Player One"}]
```

Sebaiknya selalu mulai dengan kueri sederhana tanpa pengikatan (binding) dan tambahkan pengikatan setiap kali Anda perlu merujuk struktur data Anda. Informasi lebih lanjut tentang pengikatan dalam kueri dapat ditemukan di [dokumentasi Ecto](https://hexdocs.pm/ecto/Ecto.Query.html#module-query-expressions)

### Kueri Berbasis Makro

Pada contoh di atas, kita menggunakan kata kunci `select:` dan `where:` di dalam makro `from` untuk membangun kueri – ini disebut _kueri berbasis kata kunci_. Namun, ada cara lain untuk menyusun kueri – kueri berbasis makro. Ecto menyediakan makro untuk setiap kata kunci, seperti `select/3` atau `where/3`. Setiap makro menerima nilai yang _dapat dikueri_, _daftar pengikatan eksplisit_, dan ekspresi yang sama yang akan Anda berikan pada analog kata kuncinya:

```elixir
iex> query = select(Movie, [m], m.title)
#Ecto.Query<from m0 in Friends.Movie, select: m0.title>

iex> Repo.all(query)
SELECT m0."title" FROM "movies" AS m0 []
["Ready Player One"]
```

Keunggulan makro adalah kemampuannya bekerja sangat baik dengan pipa:

```elixir
iex> Movie \
...>  |> where([m], m.id < 2) \
...>  |> select([m], {m.title}) \
...>  |> Repo.all
[{"Ready Player One"}]
```

Perhatikan bahwa untuk melanjutkan penulisan setelah pemisah baris, gunakan karakter `\`.

### Menggunakan klausa where dengan Nilai Interpolasi

Untuk menggunakan nilai interpolasi atau ekspresi Elixir dalam klausa `where` kita, kita perlu menggunakan operator `^`, atau pin. Ini memungkinkan kita untuk _menyematkan_ nilai ke variabel dan merujuk pada nilai yang disematkan tersebut, alih-alih mengikat ulang variabel tersebut.

```elixir
iex> title = "Ready Player One"
"Ready Player One"
iex> query = from(m in Movie, where: m.title == ^title, select: m.tagline)
%Ecto.Query<from m in Friends.Movie, where: m.title == ^"Ready Player One",
 select: m.tagline>
iex> Repo.all(query)

15:21:46.809 [debug] QUERY OK source="movies" db=3.8ms
["Something about video games"]
```

### Mengambil Data Pertama dan Terakhir

Kita dapat mengambil data pertama atau terakhir dari sebuah repositori menggunakan fungsi `Ecto.Query.first/2` dan `Ecto.Query.last/2`.

Pertama, kita akan menulis ekspresi kueri menggunakan fungsi `first/2`:

```elixir
iex> first(Movie)
#Ecto.Query<from m0 in Friends.Movie, order_by: [asc: m0.id], limit: 1>
```

Kemudian kita meneruskan kueri kita ke fungsi `Repo.one/2` untuk mendapatkan hasilnya:

```elixir
iex> Movie |> first() |> Repo.one()

SELECT m0."id", m0."title", m0."tagline" FROM "movies" AS m0 ORDER BY m0."id" LIMIT 1 []
%Friends.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Fungsi `Ecto.Query.last/2` digunakan dengan cara yang sama:

```elixir
iex> Movie |> last() |> Repo.one()
```

## Meng-kueri Data Terkait

### Pra-muat

Agar dapat mengakses record terkait yang diekspos oleh makro `belongs_to`, `has_many`, dan `has_one`, kita perlu _memuat_ skema terkait terlebih dahulu.

Mari kita lihat apa yang terjadi ketika kita mencoba meminta aktor terkait dari sebuah film:

```elixir
iex> movie = Repo.get(Movie, 1)
iex> movie.actors
%Ecto.Association.NotLoaded<association :actors is not loaded>
```

Kita tidak dapat mengakses karakter terkait tersebut kecuali kita memuatnya terlebih dahulu. Ada beberapa cara berbeda untuk memuat data terlebih dahulu dengan Ecto.

#### Memuat Data Terlebih Dahulu Dengan Dua Kueri

Kueri berikut akan memuat data terkait terlebih dahulu dalam kueri terpisah.

```elixir
iex> Repo.all(from m in Movie, preload: [:actors])

13:17:28.354 [debug] QUERY OK source="movies" db=2.3ms queue=0.1ms
13:17:28.357 [debug] QUERY OK source="actors" db=2.4ms
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Tyler Sheridan"
      },
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 2,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Gary"
      }
    ],
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

Kita dapat melihat bahwa baris kode di atas menjalankan _dua_ kueri basis data. Satu untuk semua film, dan satu lagi untuk semua aktor dengan ID film yang diberikan.

#### Pra-pemuatan dengan Satu Kueri

Kita dapat mengurangi kueri basis data kita dengan cara berikut:

```elixir
iex> query = from(m in Movie, join: a in assoc(m, :actors), preload: [actors: a])
iex> Repo.all(query)

13:18:52.053 [debug] QUERY OK source="movies" db=3.7ms
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Tyler Sheridan"
      },
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 2,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Gary"
      }
    ],
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

Ini memungkinkan kita untuk menjalankan hanya satu panggilan basis data. Selain itu, ini juga memiliki manfaat tambahan yaitu memungkinkan kita untuk memilih dan memfilter film dan aktor terkait dalam kueri yang sama. Misalnya, pendekatan ini memungkinkan kita untuk melakukan kueri untuk semua film di mana aktor terkait memenuhi kondisi tertentu menggunakan pernyataan `join`. Kurang lebih seperti ini:

```elixir
Repo.all from m in Movie,
  join: a in assoc(m, :actors),
  where: a.name == "John Wayne",
  preload: [actors: a]
```

Penjelasan lebih lanjut tentang pernyataan join akan dibahas sebentar lagi.

#### Pra-pemuatan Data yang Diambil

Kita juga dapat memuat terlebih dahulu skema terkait dari data yang telah diambil dari basis data.

```elixir
iex> movie = Repo.get(Movie, 1)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>, # actors are NOT LOADED!!
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
iex> movie = Repo.preload(movie, :actors)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Friends.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
      id: 1,
      movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Tyler Sheridan"
    },
    %Friends.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
      id: 2,
      movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Gary"
    }
  ], # actors are LOADED!!
  characters: [],
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Sekarang kita bisa meminta nama aktor dalam sebuah film:

```elixir
iex> movie.actors
[
  %Friends.Actor{
    __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
    id: 1,
    movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Tyler Sheridan"
  },
  %Friends.Actor{
    __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
    id: 2,
    movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Gary"
  }
]
```

### Menggunakan Statemen Join

Kita dapat mengeksekusi kueri yang menyertakan pernyataan `join` dengan bantuan fungsi `Ecto.Query.join/5`.

```elixir
iex> alias Friends.Character
iex> query = from m in Movie,
              join: c in Character,
              on: m.id == c.movie_id,
              where: c.name == "Wade Watts",
              select: {m.title, c.name}
iex> Repo.all(query)
15:28:23.756 [debug] QUERY OK source="movies" db=5.5ms
[{"Ready Player One", "Wade Watts"}]
```

Ekspresi `on` juga dapat menggunakan daftar kata kunci:

```elixir
from m in Movie,
  join: c in Character,
  on: [id: c.movie_id], # keyword list
  where: c.name == "Wade Watts",
  select: {m.title, c.name}
```

Pada contoh di atas, kita melakukan join berdasarkan skema Ecto, `m in Movie`. Kita juga dapat melakukan join berdasarkan query Ecto. Misalnya, tabel film kita memiliki kolom `stars`, tempat kita menyimpan "peringkat bintang" film, yaitu angka 1-5.

```elixir
movies = from m in Movie, where: [stars: 5]
from c in Character,
  join: m in subquery(movies),
  on: [id: c.movie_id], # keyword list
  where: c.name == "Wade Watts",
  select: {m.title, c.name}
```

Ecto Query DSL adalah alat yang ampuh yang menyediakan semua yang kita butuhkan untuk membuat kueri basis data yang kompleks sekalipun. Dengan pengantar ini, Anda diberikan dasar-dasar untuk mulai membuat kueri.
