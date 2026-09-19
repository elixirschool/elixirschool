%{
  version: "1.0.2",
  title: "Executables",
  excerpt: """
  Untuk membuat Executable di Elixir, kita akan menggunakan escript.
  Escript menghasilkan berkas yang dapat dieksekusi di sistem apa pun yang sudah terpasang Erlang.
  """
}
---

## Memulai

Untuk membuat eksekutabel dengan escript, hanya ada beberapa hal yang perlu kita lakukan: implementasi fungsi `main/1` dan memperbarui Mixfile kita.

Kita akan mulai dengan membuat modul yang berfungsi sebagai titik masuk ke program yang dapat dieksekusi.
Di sinilah kita akan mengimplementasikan `main/1`:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    # Do stuff
  end
end
```

Selanjutnya, kita perlu memperbarui Mixfile kita untuk menyertakan opsi `:escript` untuk proyek kita beserta penentuan `:main_module`:

```elixir
defmodule ExampleApp.Mixproject do
  def project do
    [app: :example_app, version: "0.0.1", escript: escript()]
  end

  defp escript do
    [main_module: ExampleApp.CLI]
  end
end
```

## Mengurai Argumen

Setelah aplikasi kita siap, kita dapat melanjutkan ke penguraian argumen dari baris perintah (command line).
Untuk melakukan ini, kita akan gunakan `OptionParser.parse/2` Elixir dengan opsi `:switches` untuk menunjukkan bahwa flag kita adalah boolean:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    args
    |> parse_args()
    |> response()
    |> IO.puts()
  end

  defp parse_args(args) do
    {opts, word, _} =
      args
      |> OptionParser.parse(switches: [upcase: :boolean])

    {opts, List.to_string(word)}
  end

  defp response({opts, word}) do
    if opts[:upcase], do: String.upcase(word), else: word
  end
end
```

## Membangun

Setelah kita selesai mengkonfigurasi aplikasi kita untuk menggunakan escript, membangun file executable kita menjadi mudah dengan Mix:

```bash
mix escript.build
```

Let's take it for a spin:

```bash
$ ./example_app --upcase Hello
HELLO

$ ./example_app Hi
Hi
```

Selesai.
Kita telah membuat eksekutabel pertama kita di Elixir menggunakan escript.
