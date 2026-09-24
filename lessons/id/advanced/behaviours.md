%{
  version: "1.0.2",
  title: "Behaviours",
  excerpt: """
  We learned about Typespecs in the previous lesson, here we'll learn how to require a module to implement those specifications.
  In Elixir, this functionality is referred to as behaviours.
  """
}
---

## Kegunaan

Terkadang Anda ingin modul berbagi API publik, solusinya di Elixir adalah behavior.
Behavior memiliki dua peran utama:

+ Mendefinisikan serangkaian fungsi yang harus diimplementasikan
+ Memeriksa apakah serangkaian fungsi tersebut benar-benar telah diimplementasikan

Elixir menyertakan sejumlah behavior seperti `GenServer`, tetapi dalam pelajaran ini kita akan fokus pada pembuatan behavior kita sendiri.

## Mendefinisikan behavior

Untuk lebih memahami behavior, mari kita implementasikan satu behavior untuk modul worker.
Worker ini diharapkan untuk mengimplementasikan dua fungsi: `init/1` dan `perform/2`.

Untuk mencapai hal ini, kita akan menggunakan direktif `@callback` dengan sintaks yang mirip dengan `@spec`.
Ini mendefinisikan fungsi __required__; untuk makro kita dapat menggunakan `@macrocallback`.
Mari kita tentukan fungsi `init/1` dan `perform/2` untuk worker kita:

```elixir
defmodule Example.Worker do
  @callback init(state :: term) :: {:ok, new_state :: term} | {:error, reason :: term}
  @callback perform(args :: term, state :: term) ::
              {:ok, result :: term, new_state :: term}
              | {:error, reason :: term, new_state :: term}
end
```

Di sini kita telah mendefinisikan `init/1` sebagai fungsi yang menerima nilai apa pun dan mengembalikan tuple berupa `{:ok, state}` atau `{:error, reason}`, ini adalah inisialisasi yang cukup standar.
Fungsi `perform/2` kita akan menerima beberapa argumen untuk worker bersama dengan state yang telah kita inisialisasi, kita akan mengharapkan `perform/2` untuk mengembalikan `{:ok, result, state}` atau `{:error, reason, state}` seperti halnya GenServer.

### Tipe `term` di Elixir

Tipe `term` di Elixir mewakili **nilai apa pun** dan merupakan tipe terluas dalam bahasa ini, mencakup semua tipe lain seperti atom, bilangan bulat, peta, daftar, dll. Tipe ini sering digunakan dalam perilaku untuk memungkinkan fleksibilitas maksimum dalam kontrak. Selalu baik untuk menggunakan tipe yang lebih spesifik (misalnya, map, list, integer) ketika konteks memungkinkan, karena ini meningkatkan keterbacaan dan pemeriksaan tipe.

Untuk detail lebih lanjut, lihat [Dokumentasi Spesifikasi Tipe Elixir](https://hexdocs.pm/elixir/typespecs.html#built-in-types).

## Menggunakan behavior

Sekarang setelah kita mendefinisikan behavior kita, kita dapat menggunakannya untuk membuat berbagai modul yang semuanya berbagi API publik yang sama.
Menambahkan behavior ke modul kita mudah dengan atribut `@behaviour`.

Dengan menggunakan perilaku baru kita, mari kita buat modul yang tugasnya adalah mengunduh file jarak jauh dan menyimpannya secara lokal:

```elixir
defmodule Example.Downloader do
  @behaviour Example.Worker

  def init(opts), do: {:ok, opts}

  def perform(url, opts) do
    url
    |> HTTPoison.get!()
    |> Map.fetch(:body)
    |> write_file(opts[:path])
    |> respond(opts)
  end

  defp write_file(:error, _), do: {:error, :missing_body}

  defp write_file({:ok, contents}, path) do
    path
    |> Path.expand()
    |> File.write(contents)
  end

  defp respond(:ok, opts), do: {:ok, opts[:path], opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

Atau bagaimana dengan pekerja yang mengompres serangkaian file? Itu juga mungkin:

```elixir
defmodule Example.Compressor do
  @behaviour Example.Worker

  def init(opts), do: {:ok, opts}

  def perform(payload, opts) do
    payload
    |> compress
    |> respond(opts)
  end

  defp compress({name, files}), do: :zip.create(name, files)

  defp respond({:ok, path}, opts), do: {:ok, path, opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

Meskipun pekerjaan yang dilakukan berbeda, API yang menghadap publik tidak berubah, dan kode apa pun yang memanfaatkan modul ini dapat berinteraksi dengannya dengan mengetahui bahwa modul tersebut akan merespons seperti yang diharapkan.
Hal ini memungkinkan kita untuk membuat sejumlah pekerja, yang semuanya melakukan tugas yang berbeda, tetapi sesuai dengan API publik yang sama.

Jika kita menambahkan behavior tetapi gagal mengimplementasikan semua fungsi yang diperlukan, peringatan kompilasi akan muncul.
Untuk melihat hal ini secara langsung, mari kita modifikasi kode `Example.Compressor` kita dengan menghapus fungsi `init/1`:

```elixir
defmodule Example.Compressor do
  @behaviour Example.Worker

  def perform(payload, opts) do
    payload
    |> compress
    |> respond(opts)
  end

  defp compress({name, files}), do: :zip.create(name, files)

  defp respond({:ok, path}, opts), do: {:ok, path, opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

Sekarang, saat kita mengkompilasi kode kita, kita akan melihat peringatan:

```shell
lib/example/compressor.ex:1: warning: undefined behaviour function init/1 (for behaviour Example.Worker)
Compiled lib/example/compressor.ex
```

Selesai! Sekarang kita siap untuk membangun dan berbagi perilaku dengan orang lain.
