%{
  version: "0.9.1",
  title: "Basics",
  excerpt: """
  Ecto adalah sebuah project resmi Elixir yang memberikan sebuah wrapper (pembungkus) terhadap database dan bahasa query yang terintegrasi.  Dengan Ecto kita bisa membuat migrasi, mendefinisikan model, melakukan insert dan update data, dan melakukan query.
  """
}
---

## Setup

Untuk mulai kita perlu menginclude Ecto dan sebuah adapter database dalam `mix.exs` project kita.  Anda bisa menemukan daftar adapter database yang didukung di bagian [Usage](https://github.com/elixir-lang/ecto/blob/master/README.md#usage) section dari README Ecto.  Sebagai contoh kita akan gunakan Postgresql:

```elixir
defp deps do
  [{:ecto, "~> 1.0"}, {:postgrex, ">= 0.0.0"}]
end
```

Sekarang kita bisa tambahkan Ecto dan adapter kita ke application:

```elixir
def application do
  [applications: [:ecto, :postgrex]]
end
```

### Repository

Akhirnya kita perlu membuat repositori project kita, wrapper untuk databasenya.  Ini bisa dilakukan lewat task `mix ecto.gen.repo -r FriendsApp.Repo`.  Kita akan membahas task mix Ecto nanti.  Repo bisa ditemukan di `lib/<project name>/repo.ex`:

```elixir
defmodule FriendsApp.Repo do
  use Ecto.Repo, otp_app: :example_app
end
```

### Supervisor

Setelah kita membuat Repo, kita perlu mensetup pohon supervisor (supervisor tree) kita, yang biasanya ditemukan di `lib/<project name>.ex`.

Penting dicatat bahwa kita mensetup Repo sebagai sebuah supervisor dengan `supervisor/3` dan _bukan_ `worker/3`.  Jika anda membuat app dengan flag `--sup` sebagian besarnya sudah dibuat:

```elixir
defmodule FriendsApp.App do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(FriendsApp.Repo, [])
    ]

    opts = [strategy: :one_for_one, name: FriendsApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Untuk info lebih lanjut tentang supervisor lihatlah pelajaran [OTP Supervisors](../../advanced/otp-supervisors).

### Konfigurasi

Untuk mengkonfigurasi Ecto kita perlu menambahkan sebuah bagian ke `config/config.exs` kita.  Di sini kita akan menspesifikasikan repositori, adapter, database, dan informasi terkait account:

```elixir
config :example_app, FriendsApp.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "example_app",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
```

## Mix Task

Ecto menyertakan sejumlah task mix yang membantu untuk bekerja dengan database kita:

```shell
mix ecto.create         # Membuat database untuk repo
mix ecto.drop           # Menghapus database untuk repo
mix ecto.gen.migration  # Membuat migrasi baru untuk repo
mix ecto.gen.repo       # Membuat repo baru
mix ecto.migrate        # Menjalankan migrasi pada repo
mix ecto.rollback       # Menjalankan balik migrasi dari repo
```

## Migrasi

Cara terbaik membuat migrasi adalah dengan task `mix ecto.gen.migration <name>`.  Jika anda sudah kenal ActiveRecord maka ini akan tampak familiar.

Mari mulai dengan melihat sebuah migrasi untuk tabel users:

```elixir
defmodule FriendsApp.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:username, :string, unique: true)
      add(:encrypted_password, :string, null: false)
      add(:email, :string)
      add(:confirmed, :boolean, default: false)

      timestamps
    end

    create(unique_index(:users, [:username], name: :unique_usernames))
  end
end
```

Secara default Ecto membuat sebuah primary key yang auto-increment bernama `id`.  Di sini kita menggunakan callback default `change/0` tetapi Ecto juga mendukung `up/0` dan `down/0` jika anda perlu mengendalikan secara lebih rinci.

Sebagaimana yang anda mungkin sudah terka, menambahkan `timestamps` ke migrasi anda akan membuat dan mengelola `inserted_at` dan `updated_at`.

Untuk menjalankan migrasi kita yang baru jalankanlah `mix ecto.migrate`.

Untuk info lebih lanjut tentang migrasi silakan lihat di bagian [Ecto.Migration](http://hexdocs.pm/ecto/Ecto.Migration.html#content) dari dokumentasi.

## Model

Sekarang setelah kita membuat migrasi kita dapat melanjutkan ke model.  Model mendefinisikan schema kita, metode pembantu, dan changeset.  Kita akan bahas changeset lebih jauh di bagian berikutnya.

Untuk sementara ini mari lihat seperti apa model dari migrasi kita:

```elixir
defmodule FriendsApp.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:username, :string)
    field(:encrypted_password, :string)
    field(:email, :string)
    field(:confirmed, :boolean, default: false)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)

    timestamps
  end

  @required_fields ~w(username encrypted_password email)
  @optional_fields ~w()

  def changeset(user, params \\ :empty) do
    user
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:username)
  end
end
```

Schema yang kita definisikan dalam model kita merepresentasikan apa yang kita spesifikasikan di migrasi kita.  Sebagai tambahan atas field-field database kita kita juga memasukkan dua virtual field.  Virtual field tidak disimpan ke database tapi bisa jadi berguna untuk hal-hal seperti validasi.  Kita akan lihat tentang virtual field di bagian [Changesets](#changesets).

## Query

Sebelum kita bisa melakukan query pada repository kita kita perlu mengimpor API Query.  Untuk saat ini kita hanya perlu mengimpor `from/2`:

```elixir
import Ecto.Query, only: [from: 2]
```

Dokumentasi resmi bisa ditemukan di [Ecto.Query](http://hexdocs.pm/ecto/Ecto.Query.html).

### Dasar

Ecto menyediakan DSL Query yang sangat bagus yang memungkinkan kita mengekspresikan query dengan jelas.  Untuk menemukan username dari semua akun yang sudah dikonfirmasikan kita dapat gunakan seperti ini:

```elixir
alias FriendsApp.{Repo, User}

query =
  from(
    u in User,
    where: u.confirmed == true,
    select: u.username
  )

Repo.all(query)
```

Selain `all/2`, Repo menyediakan sejumlah callback termasuk `one/2`, `get/3`, `insert/2`, dan `delete/2`.  Daftar lengkap callback bisa ditemukan di [Ecto.Repo#callbacks](http://hexdocs.pm/ecto/Ecto.Repo.html#callbacks).

### Count

```elixir
query =
  from(
    u in User,
    where: u.confirmed == true,
    select: count(u.id)
  )
```

### Group By

Untuk mengelompokkan user berdasar status konfirmasinya kita bisa masukkan opsi `group_by`:

```elixir
query =
  from(
    u in User,
    group_by: u.confirmed,
    select: [u.confirmed, count(u.id)]
  )

Repo.all(query)
```

### Order By

Mengurutkan user berdasarkan tanggal pembuatannya:

```elixir
query =
  from(
    u in User,
    order_by: u.inserted_at,
    select: [u.username, u.inserted_at]
  )

Repo.all(query)
```

Untuk mengurutkannya secara menurun (`DESC`):

```elixir
query =
  from(
    u in User,
    order_by: [desc: u.inserted_at],
    select: [u.username, u.inserted_at]
  )
```

### Join

Dengan asumsi kita punya profil yang terkait dengan user kita, mari dapatkan semua profil akun yang sudah terkonfirmasi:

```elixir
query =
  from(
    p in Profile,
    join: u in assoc(p, :user),
    where: u.confirmed == true
  )
```

### Fragment

Terkadang, seperti saat kita butuh fungsi database yang khusus, API Query tidaklah cukup.  Fungsi `fragment/1` ada untuk tujuan ini:

```elixir
query =
  from(
    u in User,
    where: fragment("downcase(?)", u.username) == ^username,
    select: u
  )
```

Contoh tambahan query dapat ditemukan di deskripsi modul [Ecto.Query.API](http://hexdocs.pm/ecto/Ecto.Query.API.html).

## Changeset

Dalam bagian sebelumnya kita pelajari cara mendapatkan data, tetapi bagaimana dengan menambahkan dan mengubahnya?  Untuk itu kita perlu Changeset.

Changeset mengurus pemfilteran, validasi, dan menangani batasan ketika mengubah sebuah model.

Untuk contoh ini kita akan fokus pada changeset untuk membuat user.  Untuk memulai kita perlu mengubah model kita:

```elixir
defmodule FriendsApp.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Comeonin.Bcrypt, only: [hashpwsalt: 1]

  schema "users" do
    field(:username, :string)
    field(:encrypted_password, :string)
    field(:email, :string)
    field(:confirmed, :boolean, default: false)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)

    timestamps
  end

  @required_fields ~w(username email password password_confirmation)
  @optional_fields ~w()

  def changeset(user, params \\ :empty) do
    user
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:password, min: 8)
    |> validate_password_confirmation()
    |> unique_constraint(:username, name: :email)
    |> put_change(:encrypted_password, hashpwsalt(params[:password]))
  end

  defp validate_password_confirmation(changeset) do
    case get_change(changeset, :password_confirmation) do
      nil ->
        password_incorrect_error(changeset)

      confirmation ->
        password = get_field(changeset, :password)
        if confirmation == password, do: changeset, else: password_mismatch_error(changeset)
    end
  end

  defp password_mismatch_error(changeset) do
    add_error(changeset, :password_confirmation, "Password tidak cocok")
  end

  defp password_incorrect_error(changeset) do
    add_error(changeset, :password, "tidak valid")
  end
end
```

Kita sudah mengubah fungsi `changeset/2` kita dan menambahkan tiga fungsi penolong baru: `validate_password_confirmation/1`, `password_mismatch_error/1`, dan `password_incorrect_error/1`.

Sebagaimana diduga, `changeset/2` membuat sebuah changeset baru untuk kita.  Di dalamnya kita menggunakan `cast/4` untuk mengubah parameter kita ke sebuah changeset dari serangkaian field yang dibutuhkan (required) dan yang opsional.  Lelau kita memvalidasi panjang password changeset tersebut, kita gunakan fungsi kita sendiri untuk memvalidasi kecocokan konfirmasi password, dan kita memvalidasi keunikan username.  Akhirnya kita mengubah field database password.  Untuk ini kita gunakan `put_change/3` untuk mengubah sebuah value dalam changeset tersebut.

Menggunakan `User.changeset/2` adalah relatif sederhana:

```elixir
alias FriendsApp.{User, Repo}

pw = "passwords should be hard"

changeset =
  User.changeset(%User{}, %{
    username: "doomspork",
    email: "sean@seancallan.com",
    password: pw,
    password_confirmation: pw
  })

case Repo.insert(changeset) do
  {:ok, model}        -> # Inserted with success
  {:error, changeset} -> # Something went wrong
end
```

Beres! Sekarang anda sudah siap menyimpan data.
