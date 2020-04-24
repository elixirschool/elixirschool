---
version: 0.9.1
title: Umbrella Projects
---

Terkadang sebuah project bisa menjadi sangat besar. Perangkat build Mix memungkinkan kita untuk memecah code kita jadi beberapa aplikasi dan membuat project Elixir kita lebih tertata dalam pengembangannya.

{% include toc.html %}

## Perkenalan

Untuk membuat sebuah project payung (umbrella project) kita mulai sebuah project seperti project Mix biasa tetapi menggunakan flag `--umbrella`. Untuk contoh ini, kita akan membuat *shell* dari sebuah perangkat (toolkit) untuk pembelajaran mesin (machine learning). Kenapa machine learning toolkit? Kenapa tidak? Toolkit ini terdiri dari berbagai algoritma pembelajaran yang berbeda dan juga fungsi-fungsi pembantu (utility function).

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

Sebagaimana yang bisa anda lihat dari perintah shell tersebut, Mix membuat sebuah project kerangka kecil untuk kita dengan dua direktori:

  - `apps/` - tempat tinggal subproject (project anak) kita
  - `config/` - tempat tinggal konfigurasi project payung kita


## Project Anak

Mari pindah ke direktori project `machine_learning_toolkit/apps` directory dan buat 3 aplikasi normal menggunakan Mix seperti berikut:

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

Seharusnya kita sekarang punya project tree seperti berikut:

```shell
$ tree
.
├── README.md
├── apps
│   ├── datasets
│   │   ├── README.md
│   │   ├── config
│   │   │   └── config.exs
│   │   ├── lib
│   │   │   └── datasets.ex
│   │   ├── mix.exs
│   │   └── test
│   │       ├── datasets_test.exs
│   │       └── test_helper.exs
│   ├── svm
│   │   ├── README.md
│   │   ├── config
│   │   │   └── config.exs
│   │   ├── lib
│   │   │   └── svm.ex
│   │   ├── mix.exs
│   │   └── test
│   │       ├── svm_test.exs
│   │       └── test_helper.exs
│   └── utilities
│       ├── README.md
│       ├── config
│       │   └── config.exs
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

Jika kita pindah kembali ke direktori root project payungnya, kita bisa melihat bahwa kita bisa memanggil semua perintah yang biasa seperti compile. Karena subproject adalah aplikasi normal biasa, anda bisa pindah ke direktorinya dan melakukan semua kegiatan yang biasanya dimungkinkan oleh Mix untuk kita lakukan.

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

Anda mungkin berpikir bahwa berinteraksi dengan applikasi-aplikasinya akan jadi sedikit berbeda di dalam sebuah project payung. Percaya atau tidak, itu salah! Kalau kita pindah direktori ke direktori paling atas, dan memulai IEx dengan `iex -S mix` kita bisa berinteraksi dengan semua projectnya secara normal. Mari ubah isi dari `apps/datasets/lib/datasets.ex` untuk contoh sederhana ini.

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
:world
```
