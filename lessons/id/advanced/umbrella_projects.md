%{
  version: "1.0.3",
  title: "Umbrella Projects",
  excerpt: """
  Terkadang sebuah proyek bisa menjadi besar, bahkan sangat besar.
  Alat build Mix memungkinkan kita untuk membagi kode kita menjadi beberapa aplikasi dan membuat proyek Elixir kita lebih mudah dikelola seiring pertumbuhannya.
  """
}
---

## Perkenalan

Untuk membuat proyek payung, kita memulai proyek seolah-olah kita akan memulai proyek Mix biasa, tetapi dengan menambahkan flag `--umbrella`.
Untuk contoh ini, kita akan membuat *kerangka* dari sebuah toolkit pembelajaran mesin (machine learning).
Mengapa toolkit pembelajaran mesin? Mengapa tidak? Toolkit ini terdiri dari berbagai algoritma pembelajaran dan fungsi utilitas.

```shell
$ mix new machine_learning_toolkit --umbrella

* creating .gitignore
* creating README.md
* creating mix.exs
* creating apps
* creating config
* creating config/config.exs

Your umbrella project was created successfully.
Inside your project, you will find an apps/ directory
where you can create and host many apps:

    cd machine_learning_toolkit
    cd apps
    mix new my_app

Commands like "mix compile" and "mix test" when executed
in the umbrella project root will automatically run
for each application in the apps/ directory.
```

Seperti yang Anda lihat dari perintah shell tersebut, Mix telah membuat proyek kerangka kecil untuk kita dengan dua direktori:

- `apps/` - tempat proyek sub (anak) kita akan berada
- `config/` - tempat konfigurasi proyek induk kita akan berada

## Project Anak

Mari kita masuk ke direktori `machine_learning_toolkit/apps` proyek dan buat 3 aplikasi biasa menggunakan Mix seperti berikut:

```shell
$ mix new utilities

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/utilities.ex
* creating test
* creating test/test_helper.exs
* creating test/utilities_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd utilities
    mix test

Run "mix help" for more commands.


$ mix new datasets

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/datasets.ex
* creating test
* creating test/test_helper.exs
* creating test/datasets_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd datasets
    mix test

Run "mix help" for more commands.

$ mix new svm

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/svm.ex
* creating test
* creating test/test_helper.exs
* creating test/svm_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd svm
    mix test

Run "mix help" for more commands.
```

Sekarang kita seharusnya memiliki struktur proyek seperti ini:

```shell
$ tree
.
├── README.md
├── apps
│   ├── datasets
│   │   ├── README.md
│   │   ├── lib
│   │   │   └── datasets.ex
│   │   ├── mix.exs
│   │   └── test
│   │       ├── datasets_test.exs
│   │       └── test_helper.exs
│   ├── svm
│   │   ├── README.md
│   │   ├── lib
│   │   │   └── svm.ex
│   │   ├── mix.exs
│   │   └── test
│   │       ├── svm_test.exs
│   │       └── test_helper.exs
│   └── utilities
│       ├── README.md
│       ├── lib
│       │   └── utilities.ex
│       ├── mix.exs
│       └── test
│           ├── test_helper.exs
│           └── utilities_test.exs
├── config
│   └── config.exs
└── mix.exs
```

Jika kita kembali ke direktori root proyek utama, kita dapat melihat bahwa kita dapat memanggil semua perintah umum seperti kompilasi.
Karena subproyek hanyalah aplikasi biasa, Anda dapat masuk ke direktori mereka dan melakukan semua hal yang sama seperti biasanya yang memungkinkan Mix untuk Anda lakukan.

```bash
$ mix compile

==> svm
Compiled lib/svm.ex
Generated svm app

==> datasets
Compiled lib/datasets.ex
Generated datasets app

==> utilities
Compiled lib/utilities.ex
Generated utilities app

Consolidated List.Chars
Consolidated Collectable
Consolidated String.Chars
Consolidated Enumerable
Consolidated IEx.Info
Consolidated Inspect
```

## IEx

Anda mungkin berpikir bahwa berinteraksi dengan aplikasi akan sedikit berbeda dalam proyek payung.
Percaya atau tidak, Anda salah! Jika kita mengubah direktori ke direktori tingkat atas, dan memulai IEx dengan `iex -S mix`, kita dapat berinteraksi dengan semua proyek secara normal.
Mari kita ubah isi `apps/datasets/lib/datasets.ex` untuk contoh sederhana ini.

```elixir
defmodule Datasets do
  def hello do
    IO.puts("Hello, I'm the datasets")
  end
end
```

```shell
$ iex -S mix
Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

==> datasets
Compiled lib/datasets.ex
Consolidated List.Chars
Consolidated Collectable
Consolidated String.Chars
Consolidated Enumerable
Consolidated IEx.Info
Consolidated Inspect
Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)

iex> Datasets.hello
Hello, I'm the datasets
:ok
```
