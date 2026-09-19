%{
  version: "1.1.1",
  title: "Penanganan Error",
  excerpt: """
  Meskipun lebih umum untuk mengembalikan tuple `{:error, reason}`, Elixir mendukung exception dan dalam pelajaran ini kita akan melihat bagaimana menangani error dan berbagai mekanisme yang tersedia bagi kita.
    
  Secara umum, konvensi dalam Elixir adalah untuk membuat sebuah fungsi (`example/1`) yang mengembalikan `{:ok, result}` dan `{:error, reason}` dan fungsi lain yang terpisah (`example!/1`) yang mengembalikan `result` saja atau memunculkan (raise) sebuah error.
  
  Pelajaran ini akan fokus pada berinteraksi dengan yang terakhir
  """
}
---

## Konvensi Umum

Saat ini, komunitas Elixir telah menyepakati beberapa konvensi mengenai penanganan kesalahan:

* Untuk kesalahan yang merupakan bagian dari operasi reguler suatu fungsi (misalnya, pengguna memasukkan tipe tanggal yang salah), fungsi tersebut mengembalikan `{:ok, result}` dan `{:error, reason}` sesuai dengan itu.
* Untuk kesalahan yang bukan bagian dari operasi normal (misalnya, tidak dapat mengurai data konfigurasi), ada pengecualian (exception).

Kita umumnya menangani kesalahan alur standar dengan [Pencocokan Pola](/id/lessons/basics/pattern_matching), tetapi dalam pelajaran ini, kita berfokus pada kasus kedua - pada exception.

Seringkali, dalam API publik, Anda juga dapat menemukan versi kedua dari fungsi dengan ! (contoh!/1) yang mengembalikan hasil yang tidak dibungkus atau menimbulkan kesalahan.

## Penanganan Error

Sebelum kita dapat menangani error kita perlu membuatnya dan cara termudah adalah dengan `raise/1`:

```elixir
iex> raise "Oh no!"
** (RuntimeError) Oh no!
```

Jika kita ingin menentukan tipe dan pesannya, kita perlu menggunakan `raise/2`:

```elixir
iex> raise ArgumentError, message: "the argument value is invalid"
** (ArgumentError) the argument value is invalid
```

Ketika kita tahu bahwa kesalahan mungkin terjadi, kita bisa menanganinya menggunakan `try/rescue` dan pencocokan pola:

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> end
An error occurred: Oh no!
:ok
```

Adalah mungkin mencocokkan beberapa error dalam satu rescue tunggal:

```elixir
try do
  opts
  |> Keyword.fetch!(:source_file)
  |> File.read!()
rescue
  e in KeyError -> IO.puts("missing :source_file option")
  e in File.Error -> IO.puts("unable to read source file")
end
```

## After

Terkadang mungkin perlu melakukan beberapa tindakan setelah `try/rescue` kita terlepas dari kesalahan yang terjadi.
Untuk ini kita punya `try/after`.
Jika Anda familiar dengan Ruby, ini mirip dengan `begin/rescue/ensure` atau di Java `try/catch/finally`:

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> after
...>   IO.puts "The end!"
...> end
An error occurred: Oh no!
The end!
:ok
```

Ini paling sering dipakai dengan file atau koneksi yang harus ditutup:

```elixir
{:ok, file} = File.open("example.json")

try do
  # Do hazardous work
after
  File.close(file)
end
```

## Error Baru

Meskipun Elixir menyertakan sejumlah tipe kesalahan bawaan seperti `RuntimeError`, kami tetap mempertahankan kemampuan untuk membuat sendiri jika kami membutuhkan sesuatu yang spesifik.
Membuat kesalahan baru dengan makro `defexception/1` dengan mudah menerima opsi `:message` untuk mengatur pesan kesalahan default:

```elixir
defmodule ExampleError do
  defexception message: "an example error has occurred"
end
```

Mari coba pakai error baru kita:

```elixir
iex> try do
...>   raise ExampleError
...> rescue
...>   e in ExampleError -> e
...> end
%ExampleError{message: "an example error has occurred"}
```

## Throw

Mekanisme lain untuk menangani kesalahan di Elixir adalah `throw` dan `catch`.
Dalam praktiknya, ini sangat jarang terjadi dalam kode Elixir yang lebih baru, tetapi tetap penting untuk mengetahui dan memahaminya.

Fungsi `throw/1` memberi kita kemampuan untuk keluar dari eksekusi dengan value spesifik yang bisa kita `catch` (tangkap) dan gunakan:

```elixir
iex> try do
...>   for x <- 0..10 do
...>     if x == 5, do: throw(x)
...>     IO.puts(x)
...>   end
...> catch
...>   x -> "Caught: #{x}"
...> end
0
1
2
3
4
"Caught: 5"
```

Seperti yang telah disebutkan, `throw/catch` cukup jarang digunakan dan biasanya ada sebagai solusi sementara ketika pustaka gagal menyediakan API yang memadai.

## Exit

Mekanisme kesalahan terakhir yang disediakan Elixir adalah `exit`.
Sinyal exit terjadi setiap kali suatu proses mati dan merupakan bagian penting dari toleransi kesalahan Elixir.

Untuk keluar secara eksplisit, kita dapat menggunakan `exit/1`:

```elixir
iex> spawn_link fn -> exit("oh no") end
** (EXIT from #PID<0.101.0>) evaluator process exited with reason: "oh no"
```

Meskipun dimungkinkan untuk menangkap exit dengan `try/catch`, melakukannya adalah sangat jarang.
Dalam hampir semua kasus, lebih menguntungkan untuk membiarkan supervisor menangani keluaran proses:

```elixir
iex> try do
...>   exit "oh no!"
...> catch
...>   :exit, _ -> "exit blocked"
...> end
"exit blocked"
```
