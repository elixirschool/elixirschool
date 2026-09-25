%{
  version: "1.3.0",
  title: "Associations",
  excerpt: """
  Di bagian ini kita akan mempelajari cara menggunakan Ecto untuk mendefinisikan dan bekerja dengan asosiasi antar skema kita.
  """
}
---

## Pengaturan

Kita akan mulai dengan aplikasi `Friends` yang sama dari pelajaran sebelumnya. Anda dapat merujuk ke pengaturan [di sini](/id/lessons/ecto/basics) untuk penyegaran singkat.

## Jenis Asosiasi

Ada tiga jenis asosiasi yang dapat kita definisikan antara skema kita. Kita akan melihat apa itu dan bagaimana cara mengimplementasikan setiap jenis hubungan.

### Belongs To/Has Many

Kita menambahkan beberapa entitas baru ke model domain aplikasi Friends kita sehingga kita dapat mengkatalogkan film favorit kita. Kita akan mulai dengan dua skema: `Movie` dan `Character`. Kita akan mengimplementasikan hubungan "memiliki banyak/milik" antara kedua skema ini: Sebuah film memiliki banyak karakter dan sebuah karakter milik sebuah film.

#### Migrasi Has Many

Mari kita buat migrasi untuk `Movie`:

```console
mix ecto.gen.migration create_movies
```

Buka file migrasi yang baru dibuat dan definisikan fungsi `change` Anda untuk membuat tabel `movies` dengan beberapa atribut:

```elixir
# priv/repo/migrations/*_create_movies.exs
defmodule Friends.Repo.Migrations.CreateMovies do
  use Ecto.Migration

  def change do
    create table(:movies) do
      add :title, :string
      add :tagline, :string
    end
  end
end
```

#### Skema Has Many

Kita akan menambahkan skema yang menentukan hubungan "memiliki banyak" antara sebuah film dan karakter-karakternya.

```elixir
# lib/friends/movie.ex
defmodule Friends.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Friends.Character
  end
end
```

Makro `has_many/3` tidak menambahkan apa pun ke basis data itu sendiri. Yang dilakukannya adalah menggunakan _foreign key_ pada skema terkait, `characters`, untuk membuat karakter yang terkait dengan sebuah film tersedia. Inilah yang memungkinkan kita untuk memanggil `movie.characters`.

#### Migrasi Belongs To

Sekarang kita siap untuk membuat migrasi dan skema `Character`. Sebuah karakter termasuk dalam sebuah film, jadi kita akan mendefinisikan migrasi dan skema yang menentukan hubungan ini.

Pertama, buat migrasinya:

```console
mix ecto.gen.migration create_characters
```

Untuk menyatakan bahwa suatu karakter termasuk dalam suatu film, kita memerlukan tabel `characters` yang memiliki kolom `movie_id`. Kita ingin kolom ini berfungsi sebagai _foreign key_. Kita dapat mencapai hal ini dengan baris berikut dalam fungsi `create table/1` kita:

```elixir
add :movie_id, references(:movies)
```

Jadi, migrasi kita seharusnya terlihat seperti ini:

```elixir
# priv/migrations/*_create_characters.exs
defmodule Friends.Repo.Migrations.CreateCharacters do
  use Ecto.Migration

  def change do
    create table(:characters) do
      add :name, :string
      add :movie_id, references(:movies)
    end
  end
end
```

#### Skema Belongs To

Skema kita juga perlu mendefinisikan hubungan "milik" (belongs to) antara karakter dan filmnya.

```elixir
# lib/friends/character.ex

defmodule Friends.Character do
  use Ecto.Schema

  schema "characters" do
    field :name, :string
    belongs_to :movie, Friends.Movie
  end
end
```

Mari kita perhatikan lebih detail apa yang dilakukan makro `belongs_to/3` untuk kita. Selain menambahkan _foreign key_ `movie_id` ke skema kita, makro ini juga memberi kita kemampuan untuk mengakses skema `movies` terkait *melalui* `characters`. Makro ini menggunakan kunci asing untuk membuat film yang terkait dengan karakter tersedia saat kita melakukan query. Inilah yang memungkinkan kita untuk memanggil `character.movie`.

Sekarang kita siap untuk menjalankan migrasi kita:

```console
mix ecto.migrate
```

### Belongs To/Has One

Misalnya, sebuah film hanya memiliki satu distributor, contohnya Netflix adalah distributor film original mereka "Bright".

Kita akan mendefinisikan migrasi dan skema `Distributor` dengan relasi "milik". Pertama, mari kita buat migrasinya:

```console
mix ecto.gen.migration create_distributors
```

Kita perlu menambahkan _foreign key_ `movie_id` ke migrasi tabel `distributors` yang baru saja kita buat, serta indeks unik untuk memastikan bahwa sebuah film hanya memiliki satu distributor:

```elixir
# priv/repo/migrations/*_create_distributors.exs

defmodule Friends.Repo.Migrations.CreateDistributors do
  use Ecto.Migration

  def change do
    create table(:distributors) do
      add :name, :string
      add :movie_id, references(:movies)
    end
    
    create unique_index(:distributors, [:movie_id])
  end
end
```

Dan skema `Distributor` harus menggunakan makro `belongs_to/3` agar kita dapat memanggil `distributor.movie` dan mencari film yang terkait dengan distributor menggunakan kunci asing ini.

```elixir
# lib/friends/distributor.ex

defmodule Friends.Distributor do
  use Ecto.Schema

  schema "distributors" do
    field :name, :string
    belongs_to :movie, Friends.Movie
  end
end
```

Selanjutnya, kita akan menambahkan relasi "memiliki satu" (has one) ke skema `Film`:

```elixir
# lib/friends/movie.ex

defmodule Friends.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Friends.Character
    has_one :distributor, Friends.Distributor # Aku baru!
  end
end
```

Makro `has_one/3` berfungsi sama seperti makro `has_many/3`. Makro ini menggunakan _foreign key_ skema terkait untuk mencari dan menampilkan distributor film. Ini akan memungkinkan kita untuk memanggil `movie.distributor`.

Kita siap menjalankan migrasi kita:

```console
mix ecto.migrate
```

### Many To Many

Misalkan sebuah film memiliki banyak aktor dan seorang aktor dapat tergabung dalam lebih dari satu film. Kita akan membuat tabel penghubung yang merujuk pada _kedua_ film _dan_ aktor untuk mengimplementasikan hubungan ini.

Pertama, mari kita buat migrasi `Actors`:

```console
mix ecto.gen.migration create_actors
```

Definisikan migrasi:

```elixir
# priv/migrations/*_create_actors.ex

defmodule Friends.Repo.Migrations.CreateActors do
  use Ecto.Migration

  def change do
    create table(:actors) do
      add :name, :string
    end
  end
end
```

Mari kita buat migrasi tabel gabungan kita:

```console
mix ecto.gen.migration create_movies_actors
```

Kita akan mendefinisikan migrasi kita sedemikian rupa sehingga tabel tersebut memiliki dua _foreign key_. Kita juga akan menambahkan indeks unik untuk memastikan pasangan aktor dan film yang unik:

```elixir
# priv/migrations/*_create_movies_actors.ex

defmodule Friends.Repo.Migrations.CreateMoviesActors do
  use Ecto.Migration

  def change do
    create table(:movies_actors, primary_key: false) do
      add :movie_id, references(:movies)
      add :actor_id, references(:actors)
    end

    create unique_index(:movies_actors, [:movie_id, :actor_id])
  end
end
```

Selanjutnya, mari kita tambahkan makro `many_to_many` ke skema `Movie` kita:

```elixir
# lib/friends/movie.ex

defmodule Friends.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Friends.Character
    has_one :distributor, Friends.Distributor
    many_to_many :actors, Friends.Actor, join_through: "movies_actors" # Aku baru!
  end
end
```

Terakhir, kita akan mendefinisikan skema `Actor` kita dengan makro `many_to_many` yang sama.

```elixir
# lib/friends/actor.ex

defmodule Friends.Actor do
  use Ecto.Schema

  schema "actors" do
    field :name, :string
    many_to_many :movies, Friends.Movie, join_through: "movies_actors"
  end
end
```

Kami siap menjalankan migrasi kami:

```console
mix ecto.migrate
```

## Menyimpan Data Terkait

Cara kita menyimpan catatan beserta data terkaitnya bergantung pada sifat hubungan antar catatan. Mari kita mulai dengan hubungan "belongs to/has many".

### Belongs To

#### Menyimpan Dengan Ecto.build_assoc/3

Dengan relasi "belongs to", kita dapat memanfaatkan fungsi `build_assoc/3` Ecto.

[`build_assoc/3`](https://hexdocs.pm/ecto/Ecto.html#build_assoc/3) menerima tiga argumen:

* Struktur record yang ingin kita simpan.
* Nama asosiasi.
* Atribut apa pun yang ingin kita tetapkan ke record terkait yang sedang kita simpan.

Mari kita simpan sebuah film dan karakter terkait. Pertama, kita akan membuat record film:

```elixir
iex> alias Friends.{Movie, Character, Repo}
iex> movie = %Movie{title: "Ready Player One", tagline: "Something about video games"}

%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:built, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: nil,
  tagline: "Something about video games",
  title: "Ready Player One"
}

iex> movie = Repo.insert!(movie)
```

Sekarang kita akan membuat karakter terkait dan memasukkannya ke dalam basis data:

```elixir
iex> character = Ecto.build_assoc(movie, :characters, %{name: "Wade Watts"})
%Friends.Character{
  __meta__: %Ecto.Schema.Metadata<:built, "characters">,
  id: nil,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Wade Watts"
}
iex> Repo.insert!(character)
%Friends.Character{
  __meta__: %Ecto.Schema.Metadata<:loaded, "characters">,
  id: 1,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Wade Watts"
}
```

Perhatikan bahwa karena makro `has_many/3` pada skema `Movie` menentukan bahwa sebuah film memiliki banyak `:characters`, nama asosiasi yang kita berikan sebagai argumen kedua untuk `build_assoc/3` adalah persis seperti itu: `:characters`. Kita dapat melihat bahwa kita telah membuat karakter yang `movie_id`-nya diatur dengan benar ke ID film yang terkait.

Untuk menggunakan `build_assoc/3` untuk menyimpan distributor yang terkait dengan sebuah film, kita menggunakan pendekatan yang sama yaitu memberikan _nama_ hubungan film dengan distributor sebagai argumen kedua untuk `build_assoc/3`:

```elixir
iex> distributor = Ecto.build_assoc(movie, :distributor, %{name: "Netflix"})
%Friends.Distributor{
  __meta__: %Ecto.Schema.Metadata<:built, "distributors">,
  id: nil,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Netflix"
}
iex> Repo.insert!(distributor)
%Friends.Distributor{
  __meta__: %Ecto.Schema.Metadata<:loaded, "distributors">,
  id: 1,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Netflix"
}
```

### Many to Many

#### Menyimpan Dengan Ecto.Changeset.put_assoc/4

Pendekatan `build_assoc/3` tidak akan berfungsi untuk relasi _many-to-many_ kita. Itu karena baik tabel film maupun aktor tidak memiliki kunci asing. Sebagai gantinya, kita perlu memanfaatkan Ecto Changesets dan fungsi `put_assoc/4`.

Dengan asumsi kita sudah memiliki catatan film yang telah kita buat di atas, mari kita buat catatan aktor:

```elixir
iex> alias Friends.Actor
iex> actor = %Actor{name: "Tyler Sheridan"}
%Friends.Actor{
  __meta__: %Ecto.Schema.Metadata<:built, "actors">,
  id: nil,
  movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
  name: "Tyler Sheridan"
}
iex> actor = Repo.insert!(actor)
%Friends.Actor{
  __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
  id: 1,
  movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
  name: "Tyler Sheridan"
}
```

Sekarang kita siap untuk menghubungkan film kita dengan aktor kita melalui tabel penghubung.

Pertama, perhatikan bahwa untuk bekerja dengan changeset, kita perlu memastikan bahwa struktur `movie` kita telah memuat data terkait sebelumnya. Kita akan membahas lebih lanjut tentang memuat data sebelumnya nanti. Untuk saat ini, cukup pahami bahwa kita dapat memuat asosiasi kita seperti ini:

```elixir
iex> movie = Repo.preload(movie, [:distributor, :characters, :actors])
%Friends.Movie{
 __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [],
  characters: [
    %Friends.Character{
      __meta__: #Ecto.Schema.Metadata<:loaded, "characters">,
      id: 1,
      movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
      movie_id: 1,
      name: "Wade Watts"
    }
  ],
  distributor: %Friends.Distributor{
    __meta__: #Ecto.Schema.Metadata<:loaded, "distributors">,
    id: 1,
    movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
    movie_id: 1,
    name: "Netflix"
  },
  id: 1,
  tagline: "Something about video game",
  title: "Ready Player One"
}
```

Selanjutnya, kita akan membuat changeset untuk record film kita:

```elixir
iex> movie_changeset = Ecto.Changeset.change(movie)
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Movie<>,
 valid?: true>
```

Sekarang kita akan meneruskan changeset kita sebagai argumen pertama ke [`Ecto.Changeset.put_assoc/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#put_assoc/4):

```elixir
iex> movie_actors_changeset = movie_changeset |> Ecto.Changeset.put_assoc(:actors, [actor])
%Ecto.Changeset<
  action: nil,
  changes: %{
    actors: [
      %Ecto.Changeset<action: :update, changes: %{}, errors: [],
       data: %Friends.Actor<>, valid?: true>
    ]
  },
  errors: [],
  data: %Friends.Movie<>,
  valid?: true
>
```

Ini memberi kita perubahan baru yang mewakili perubahan berikut: tambahkan aktor dalam daftar aktor ini ke catatan film yang diberikan.

Terakhir, kita akan memperbarui catatan film dan aktor yang diberikan menggunakan perubahan terbaru kita:

```elixir
iex> Repo.update!(movie_actors_changeset)
%Friends.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Friends.Actor{
      __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
      id: 1,
      movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Tyler Sheridan"
    }
  ],
  characters: [
    %Friends.Character{
      __meta__: #Ecto.Schema.Metadata<:loaded, "characters">,
      id: 1,
      movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
      movie_id: 1,
      name: "Wade Watts"
    }
  ],
  distributor: %Friends.Distributor{
    __meta__: #Ecto.Schema.Metadata<:loaded, "distributors">,
    id: 1,
    movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
    movie_id: 1,
    name: "Netflix"
  },
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Kita dapat melihat bahwa ini memberi kita catatan film dengan aktor baru yang terkait dengan benar dan sudah dimuat sebelumnya untuk kita di bawah `movie.actors`.

Kita dapat menggunakan pendekatan yang sama untuk membuat aktor baru yang terkait dengan film yang diberikan. Alih-alih meneruskan struktur aktor yang _tersimpan_ ke `put_assoc/4`, kita cukup meneruskan peta atribut yang menggambarkan aktor baru yang ingin kita buat:

```elixir
iex> changeset = movie_changeset |> Ecto.Changeset.put_assoc(:actors, [%{name: "Gary"}])
%Ecto.Changeset<
  action: nil,
  changes: %{
    actors: [
      %Ecto.Changeset<
        action: :insert,
        changes: %{name: "Gary"},
        errors: [],
        data: %Friends.Actor<>,
        valid?: true
      >
    ]
  },
  errors: [],
  data: %Friends.Movie<>,
  valid?: true
>
iex>  Repo.update!(changeset)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Friends.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
      id: 2,
      movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Gary"
    }
  ],
  characters: [],
  distributor: nil,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Kita dapat melihat bahwa aktor baru telah dibuat dengan ID "2" dan atribut yang telah kita tetapkan.

Pada bagian selanjutnya, kita akan mempelajari cara melakukan query untuk record yang terkait.
