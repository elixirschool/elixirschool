---
version: 0.9.1
title: Custom Mix Tasks 
---

Membuat task Mix custom untuk project Elixir anda.

{% include toc.html %}

## Perkenalan 

Tidak jarang kita ingin mengembangkan (extend) fungsionalitas aplikasi Elixir kita dengan menambahkan task Mix sendiri. Sebelum kita belajar tentang cara membuat task Mix spesifik untuk project kita, mari lihat salah satu yang sudah ada:

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

Sebagaimana bisa kita lihat dari perintah shell di atas, Phoenix Framework punya sebuah task Mix custom untuk membuat sebuah project baru. Bagaimana jika kita bisa membuat hal serupa untuk project kita? Kita bisa, dan Elixir membuat ini mudah untuk kita lakukan.

## Setup

Mari setup sebuah aplikasi Mix yang sangat mendasar.

```shell
$ mix new hello

* creating README.md
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

Sekarang, dalam file **lib/hello.ex** yang dibuat Mix untuk kita, mari buat sebuah fungsi sederhana yang akan beri output "Hello, World!"

```elixir
defmodule Hello do
  @doc """
  Output's `Hello, World!` everytime.
  """
  def say do
    IO.puts("Hello, World!")
  end
end
```

## Task Mix Custom

Mari kita buat task Mix custom kita. Buat sebuah direktori baru dan file **hello/lib/mix/tasks/hello.ex**. Di dalam file ini, mari masukkan 7 baris Elixir berikut.

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Simply runs the Hello.say/0 command."
  def run(_) do
    # calling our Hello.say() function from earlier
    Hello.say()
  end
end
```

Perhatikan bagaimana kita mengawali pernyataan defmodule kita dengan `Mix.Tasks` dan nama yang kita ingin panggil dari command line. Pada baris kedua kita memperkenalkan `use Mix.Task` yang mengambil perilaku (behaviour) `Mix.Task` ke dalam namespace tersebut. Kita kemudian mendeklarasikan sebuah fungsi run yang mengabaikan segala argumen, semetara ini. Di dalam fungsi ini, kita memanggil modul `Hello` kita dan fungsi `say`.

## Task Mix Bekerja

Mari kita coba task Mix kita. Selama kita ada di direktori tersebut seharusnya bisa bekerja. Dari command line, jalankan `mix hello`, dan kita semestinya melihat tampilan seperti berikut:

```shell
$ mix hello
Hello, World!
```

Mix secara default cukup ramah. Mix tahu bahwa semua orang bisa melakukan kesalahan eja, jadi Mix menggunakan teknik yang disebut fuzzy string matching (pencocokan string yang tidak tegas) untuk membuat rekomendasi:

```shell
$ mix hell
** (Mix) The task "hell" could not be found. Did you mean "hello"?
```

Apakah anda juga memperhatikan bahwa kita memperkenalkan sebuah atribut modul baru, `@shortdoc`? Atribut ini berguna ketika meluncurkan aplikasi kita, seperti ketika seorang user menjalankan perintah `mix help` dari terminal.

```shell
$ mix help

mix app.start         # Starts all registered apps
...
mix hello             # Simply calls the Hello.say/0 function.
...
```
