%{
  version: "1.2.3",
  title: "Changesets",
  excerpt: """
  Untuk menyisipkan, memperbarui, atau menghapus data dari basis data, `Ecto.Repo.insert/2`, `update/2`, dan `delete/2` memerlukan changeset sebagai parameter pertama. Tetapi apa itu changeset?
  
  Tugas yang familiar bagi hampir setiap pengembang adalah memeriksa data input untuk potensi kesalahan karena kita ingin memastikan bahwa data berada dalam keadaan yang benar sebelum kita mencoba menggunakannya untuk tujuan kita.
  
  Ecto menyediakan solusi lengkap untuk bekerja dengan perubahan data dalam bentuk modul dan struktur data `Changeset`.
  Dalam pelajaran ini, kita akan menjelajahi fungsionalitas ini dan mempelajari cara memverifikasi integritas data sebelum kita menyimpannya ke basis data.
  """
}
---

## Membuat changeset pertama Anda

Mari kita lihat struct `%Changeset{}` yang kosong:

```elixir
iex> %Ecto.Changeset{}
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: nil, valid?: false>
```

Seperti yang Anda lihat, struct ini memiliki beberapa field yang berpotensi berguna, tetapi semuanya kosong.

Agar changeset benar-benar berguna, saat kita membuatnya, kita perlu menyediakan cetak biru tentang seperti apa data tersebut.
Cetak biru apa yang lebih baik untuk data kita selain skema yang telah kita buat yang mendefinisikan field dan tipe kita?

Mari kita gunakan skema `Friends.Person` kita dari pelajaran sebelumnya:

```elixir
defmodule Friends.Person do
  use Ecto.Schema

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

Untuk membuat changeset menggunakan skema `Person`, kita akan menggunakan `Ecto.Changeset.cast/3`:

```elixir
iex> Ecto.Changeset.cast(%Friends.Person{name: "Bob"}, %{}, [:name, :age])
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Person<>,
 valid?: true>
```

Parameter pertama adalah data asli — dalam hal ini, sebuah struct `%Friends.Person{}` awal.
Ecto cukup pintar untuk menemukan skema berdasarkan struct itu sendiri.
Parameter kedua adalah perubahan yang ingin kita buat — hanya sebuah map kosong.
Parameter ketiga adalah yang membuat `cast/3` istimewa: ini adalah daftar field yang diizinkan untuk diproses, yang memberi kita kemampuan untuk mengontrol field mana yang dapat diubah dan melindungi sisanya.

```elixir
iex> Ecto.Changeset.cast(%Friends.Person{name: "Bob"}, %{"name" => "Jack"}, [:name, :age])
%Ecto.Changeset<
  action: nil,
  changes: %{name: "Jack"},
  errors: [],
  data: %Friends.Person<>,
  valid?: true
>

iex> Ecto.Changeset.cast(%Friends.Person{name: "Bob"}, %{"name" => "Jack"}, [])
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Person<>,
 valid?: true>
```

Anda dapat melihat bagaimana nama baru diabaikan untuk kedua kalinya, di mana hal itu tidak secara eksplisit diizinkan.

Alternatif untuk `cast/3` adalah fungsi `change/2`, yang tidak memiliki kemampuan untuk memfilter perubahan seperti `cast/3`.
Ini berguna ketika Anda mempercayai sumber yang melakukan perubahan atau ketika Anda bekerja dengan data secara manual.

Sekarang kita dapat membuat changeset, tetapi karena kita tidak memiliki validasi, setiap perubahan pada nama orang akan diterima, sehingga kita dapat berakhir dengan nama kosong:

```elixir
iex> Ecto.Changeset.change(%Friends.Person{name: "Bob"}, %{name: ""})
#Ecto.Changeset<
  action: nil,
  changes: %{name: ""},
  errors: [],
  data: #Friends.Person<>,
  valid?: true
>
```

Ecto mengatakan changeset tersebut valid, tetapi sebenarnya, kita tidak ingin mengizinkan nama kosong. Mari kita perbaiki ini!

## Validasi

Ecto dilengkapi dengan sejumlah fungsi validasi bawaan untuk membantu kita.

Kita akan sering menggunakan `Ecto.Changeset`, jadi mari kita impor `Ecto.Changeset` ke dalam modul `person.ex` kita, yang juga berisi skema kita:

```elixir
defmodule Friends.Person do
  use Ecto.Schema
  import Ecto.Changeset

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

Sekarang kita dapat menggunakan fungsi `cast/3` secara langsung.

Biasanya terdapat satu atau lebih fungsi pembuat changeset untuk sebuah skema. Mari kita buat satu fungsi yang menerima sebuah struct, sebuah map perubahan, dan mengembalikan sebuah changeset:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
end
```

Sekarang kita dapat memastikan bahwa `name` selalu ada:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> validate_required([:name])
end
```

Saat kita memanggil fungsi `Friends.Person.changeset/2` dan memberikan nama kosong, changeset tersebut tidak akan lagi valid, dan bahkan akan berisi pesan kesalahan yang membantu.
Catatan: jangan lupa untuk menjalankan `recompile()` saat bekerja di `iex`, jika tidak, perubahan yang Anda buat dalam kode tidak akan diterapkan.

```elixir
iex> recompile
Compiling 1 file (.ex)
:ok
iex> Friends.Person.changeset(%Friends.Person{}, %{"name" => ""})
%Ecto.Changeset<
  action: nil,
  changes: %{},
  errors: [name: {"can't be blank", [validation: :required]}],
  data: %Friends.Person<>,
  valid?: false
>
```

Jika Anda mencoba melakukan `Repo.insert(changeset)` dengan changeset di atas, Anda akan menerima `{:error, changeset}` kembali dengan kesalahan yang sama, jadi Anda tidak perlu memeriksa `changeset.valid?` sendiri setiap kali.
Lebih mudah untuk mencoba melakukan insert, update, atau delete, dan memproses kesalahan setelahnya jika ada.

Selain `validate_required/2`, ada juga `validate_length/3`, yang memerlukan beberapa opsi tambahan:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> validate_required([:name])
  |> validate_length(:name, min: 2)
end
```

Anda bisa mencoba menebak apa hasilnya jika kita memberikan nama yang hanya terdiri dari satu karakter!

```elixir
iex> Friends.Person.changeset(%Friends.Person{}, %{"name" => "A"})
%Ecto.Changeset<
  action: nil,
  changes: %{name: "A"},
  errors: [
    name: {"should be at least %{count} character(s)",
     [count: 2, validation: :length, kind: :min, type: :string]}
  ],
  data: %Friends.Person<>,
  valid?: false
>
```

Anda mungkin terkejut bahwa pesan kesalahan berisi `%{count}` yang samar — ini untuk membantu penerjemahan ke bahasa lain; jika Anda ingin menampilkan kesalahan langsung kepada pengguna, Anda dapat membuatnya mudah dibaca manusia menggunakan [`traverse_errors/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#traverse_errors/2) — lihat contoh yang diberikan dalam dokumentasi.

Beberapa validator bawaan lainnya di `Ecto.Changeset` adalah:

+ validate_acceptance/3
+ validate_change/3 & /4
+ validate_confirmation/3
+ validate_exclusion/4 & validate_inclusion/4
+ validate_format/4
+ validate_number/3
+ validate_subset/4

Anda dapat menemukan daftar lengkap beserta detail cara menggunakannya [di sini](https://hexdocs.pm/ecto/Ecto.Changeset.html#summary).

### Validasi Kustom

Meskipun validator bawaan mencakup berbagai macam kasus penggunaan, Anda mungkin masih memerlukan sesuatu yang berbeda.

Setiap fungsi `validate_` yang telah kita gunakan sejauh ini menerima dan mengembalikan `%Ecto.Changeset{}`, sehingga kita dapat dengan mudah memasukkan validator kita sendiri.

Misalnya, kita dapat memastikan bahwa hanya nama karakter fiktif yang diizinkan:

```elixir
@fictional_names ["Black Panther", "Wonder Woman", "Spiderman"]
def validate_fictional_name(changeset) do
  name = get_field(changeset, :name)

  if name in @fictional_names do
    changeset
  else
    add_error(changeset, :name, "is not a superhero")
  end
end
```

Di atas, kita memperkenalkan dua fungsi pembantu baru: [`get_field/3`](https://hexdocs.pm/ecto/Ecto.Changeset.html#get_field/3) dan [`add_error/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#add_error/4). Fungsinya hampir mudah dipahami, tetapi saya sarankan Anda untuk memeriksa tautan ke dokumentasi.

Sebaiknya selalu kembalikan `%Ecto.Changeset{}`, sehingga Anda dapat menggunakan operator `|>` dan memudahkan penambahan validasi di kemudian hari:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> validate_required([:name])
  |> validate_length(:name, min: 2)
  |> validate_fictional_name()
end
```

```elixir
iex> Friends.Person.changeset(%Friends.Person{}, %{"name" => "Bob"})
%Ecto.Changeset<
  action: nil,
  changes: %{name: "Bob"},
  errors: [name: {"is not a superhero", []}],
  data: %Friends.Person<>,
  valid?: false
>
```

Bagus, berhasil! Namun, sebenarnya tidak perlu mengimplementasikan fungsi ini sendiri — fungsi `validate_inclusion/4` dapat digunakan sebagai gantinya; meskipun demikian, Anda dapat melihat bagaimana Anda dapat menambahkan kesalahan Anda sendiri yang mungkin berguna.

## Menambahkan perubahan secara terprogram

Terkadang Anda ingin memperkenalkan perubahan pada changeset secara manual. Fungsi pembantu `put_change/3` ada untuk tujuan ini.

Daripada mewajibkan kolom `name`, mari kita izinkan pengguna untuk mendaftar tanpa nama, dan sebut mereka "Anonim".
Fungsi yang kita butuhkan akan terlihat familiar — fungsi ini menerima dan mengembalikan changeset, sama seperti `validate_fictional_name/1` yang telah kita perkenalkan sebelumnya:

```elixir
def set_name_if_anonymous(changeset) do
  name = get_field(changeset, :name)

  if is_nil(name) do
    put_change(changeset, :name, "Anonymous")
  else
    changeset
  end
end
```

Kita dapat mengatur nama pengguna sebagai "Anonim" hanya ketika mereka mendaftar di aplikasi kita; untuk melakukan ini, kita akan membuat fungsi pembuat perubahan (changeset creator) yang baru:

```elixir
def registration_changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> set_name_if_anonymous()
end
```

Sekarang kita tidak perlu lagi memasukkan `name` dan `Anonymous` akan diatur secara otomatis, seperti yang diharapkan:

```elixir
iex> Friends.Person.registration_changeset(%Friends.Person{}, %{})
%Ecto.Changeset<
  action: nil,
  changes: %{name: "Anonymous"},
  errors: [],
  data: %Friends.Person<>,
  valid?: true
>
```

Memiliki fungsi pembuat changeset yang memiliki tanggung jawab spesifik (seperti `registration_changeset/2`) adalah hal yang umum — terkadang Anda membutuhkan fleksibilitas untuk hanya melakukan validasi tertentu atau memfilter parameter spesifik.
Fungsi di atas kemudian dapat digunakan dalam helper `sign_up/1` khusus di tempat lain:

```elixir
def sign_up(params) do
  %Friends.Person{}
  |> Friends.Person.registration_changeset(params)
  |> Repo.insert()
end
```

## Conclusion

Ada banyak kasus penggunaan dan fungsionalitas yang tidak kami bahas dalam pelajaran ini, seperti [changeset tanpa skema](https://hexdocs.pm/ecto/Ecto.Changeset.html#module-schemaless-changesets) yang dapat Anda gunakan untuk memvalidasi data apa pun; atau menangani efek samping bersamaan dengan changeset ([`prepare_changes/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#prepare_changes/2)) atau bekerja dengan asosiasi dan embed.
Kami mungkin akan membahasnya dalam pelajaran lanjutan di masa mendatang, tetapi untuk sementara waktu kami mendorong Anda untuk menjelajahi [dokumentasi Ecto Changeset](https://hexdocs.pm/ecto/Ecto.Changeset.html) untuk informasi lebih lanjut.
