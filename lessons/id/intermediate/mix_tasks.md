%{
  version: "1.4.2",
  title: "Custom Mix Tasks",
  excerpt: """
  Membuat Mix Task kustom untuk proyek Elixir Anda.
  """
}
---

## Pendahuluan

Tidak jarang kita ingin memperluas fungsionalitas aplikasi Elixir dengan menambahkan Mix Task kustom.
Sebelum kita mempelajari cara membuat Mix Task kustom untuk proyek kita, mari kita lihat salah satu yang sudah ada:

```shell
$ mix phx.new my_phoenix_app

* creating my_phoenix_app/config/config.exs
* creating my_phoenix_app/config/dev.exs
* creating my_phoenix_app/config/prod.exs
* creating my_phoenix_app/config/prod.secret.exs
* creating my_phoenix_app/config/test.exs
* creating my_phoenix_app/lib/my_phoenix_app.ex
* creating my_phoenix_app/lib/my_phoenix_app/endpoint.ex
* creating my_phoenix_app/test/views/error_view_test.exs
...
```

Seperti yang dapat kita lihat dari perintah shell di atas, Framework Phoenix memiliki Mix Task kustom untuk menghasilkan proyek baru.
Bagaimana jika kita dapat membuat sesuatu yang serupa untuk proyek kita? Kabar baiknya adalah kita bisa, dan Elixir menyediakan alat yang sangat baik untuk ini.

## Setup

Mari kita siapkan aplikasi Mix dasar.

```shell
$ mix new hello

* creating README.md
* creating .formatter.exs
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/hello.ex
* creating test
* creating test/test_helper.exs
* creating test/hello_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

cd hello
mix test

Run "mix help" for more commands.
```

Sekarang, di berkas **lib/hello.ex** yang telah dibuat Mix untuk kita, mari kita buat fungsi yang akan menampilkan "Hello, World!"

```elixir
defmodule Hello do
  @doc """
  Outputs `Hello, World!` every time.
  """
  def say do
    IO.puts("Hello, World!")
  end
end
```

## Mix Task Kustom

Mari kita buat Mix Task kustom kita.
Buat direktori dan berkas baru **hello/lib/mix/tasks/hello.ex**.
Di dalam berkas ini, mari kita masukkan 7 baris kode Elixir berikut.

```elixir
defmodule Mix.Tasks.Hello do
  @moduledoc "The hello mix task: `mix help hello`"
  use Mix.Task

  @shortdoc "Calls the Hello.say/0 function."
  def run(_) do
    # calling our Hello.say() function from earlier
    Hello.say()
  end
end
```

Perhatikan bagaimana kita memulai pernyataan defmodule dengan `Mix.Tasks` dan nama yang ingin kita panggil dari baris perintah.
Pada baris kedua, kita memperkenalkan `use Mix.Task` yang membawa **perilaku** `Mix.Task` ke dalam namespace.
Kemudian kita mendeklarasikan fungsi run yang mengabaikan argumen apa pun untuk saat ini.
Di dalam fungsi ini, kita memanggil modul `Hello` dan fungsi `say`.

## Memuat aplikasi Anda

Mix tidak secara otomatis memulai aplikasi kita atau dependensinya, yang mana hal ini baik untuk banyak kasus penggunaan Mix Task, tetapi bagaimana jika kita perlu menggunakan Ecto dan berinteraksi dengan basis data?
Dalam hal ini, kita perlu memastikan aplikasi di balik Ecto.Repo telah dimulai.
Ada 2 cara untuk menangani hal ini: memulai aplikasi secara eksplisit atau kita dapat memulai aplikasi kita yang pada gilirannya akan memulai aplikasi lainnya.

Mari kita lihat bagaimana memperbarui Mix Task kita untuk memulai aplikasi dan dependensi kita:

```elixir
defmodule Mix.Tasks.Hello do
  @moduledoc "The hello mix task: `mix help hello`"
  use Mix.Task

  @shortdoc "Calls the Hello.say/0 function."
  def run(_) do
    # This will start our application
    Mix.Task.run("app.start")

    Hello.say()
  end
end
```

## Mix Task dalam Aksi

Mari kita cek mix task kita.
Selama kita berada di direktori tersebut, seharusnya akan berfungsi.
Dari baris perintah, jalankan `mix hello`, dan kita akan melihat hasil berikut:

```shell
$ mix hello
Hello, World!
```

Mix pada dasarnya cukup ramah.
Ia menyadari bahwa setiap orang bisa saja membuat kesalahan ejaan sesekali, jadi ia menggunakan teknik yang disebut pencocokan string tidak ketat (fuzzy) untuk memberikan rekomendasi:

```shell
$ mix hell
** (Mix) The task "hell" could not be found. Did you mean "hello"?
```

Apakah Anda juga memperhatikan bahwa kita memperkenalkan atribut modul baru, `@shortdoc`? Atribut ini berguna saat merilis aplikasi kita, misalnya ketika pengguna menjalankan perintah `mix help` dari terminal.

```shell
$ mix help

mix app.start         # Starts all registered apps
...
mix hello             # Simply calls the Hello.say/0 function.
...
```

Catatan: Kode kita harus dikompilasi sebelum tugas baru muncul di output `mix help`.
Kita dapat melakukan ini dengan menjalankan `mix compile` secara langsung atau dengan menjalankan tugas kita seperti yang kita lakukan dengan `mix hello`, yang akan memicu kompilasi untuk kita.

Penting untuk dicatat bahwa nama tugas berasal dari nama modul, jadi `Mix.Tasks.MyHelper.Utility` akan menjadi `my_helper.utility`.
