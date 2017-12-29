---
version: 0.9.1
title: Executables
---

Untuk membuat eksekutabel di Elixir kita akan menggunakan escript.  Escript menghasilkan sebuah eksekutabel yang bisa dijalankan pada sistem apapun yang sudah diinstali Erlang.

{% include toc.html %}

## Memulai

Untuk membuat sebuah eksekutabel dengan escript hanya ada beberapa hal yang kita perlu lakukan: implementasi sebuah fungsi `main/1` dan mengubah Mixfile kita.

Kita akan mulai dengan membuat sebuah modul untuk menjadi titik masuk (entry point) ke eksekutabel kita.  Inilah tempat kita mengimplementasi `main/1`:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    # Do stuff
  end
end
```

Kemudian kita perlu mengubah Mixfile kita untuk memasukkan opsi `:escript` ke project kita bersama dengan menspesifikasikan `:main_module` kita:

```elixir
defmodule ExampleApp.Mixfile do
  def project do
    [app: :example_app, version: "0.0.1", escript: escript()]
  end

  defp escript do
    [main_module: ExampleApp.CLI]
  end
end
```

## Memparse Argumen

Dengan aplikasi kita siap, kita dapat lanjut ke memparse argumen dari command line.  Untuk melakukan ini kita akan gunakan `OptionParser.parse/2` dari Elixir dengan opsi `:switches` untuk mengindikasikan bahwa flag kita adalah boolean:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    args
    |> parse_args
    |> response
    |> IO.puts()
  end

  defp parse_args(args) do
    {opts, word, _} =
      args
      |> OptionParser.parse(switches: [upcase: :boolean])

    {opts, List.to_string(word)}
  end

  defp response({opts, "Hello"}), do: response({opts, "World"})

  defp response({opts, word}) do
    if opts[:upcase], do: String.upcase(word), else: word
  end
end
```

## Membuild

Sesudah kita selesai mengkonfigurasi aplikasi kita untuk menggunakan escript, membuild eksekutabel kita adalah mudah dengan Mix:

```elixir
$ mix escript.build
```

Let's take it for a spin:

```elixir
$ ./example_app --upcase Hello
WORLD

$ ./example_app Hi
Hi
```

Selesai.  Kita sudah membuat eksekutabel pertama kita menggunakan escript.
