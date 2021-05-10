---
version: 0.9.1
title: Penanganan Error 
---

Walaupun lebih umum menggunakan pengembalian tuple `{:error, reason}`, Elixir mendukung exception dan dalam pelajaran ini kita akan melihat bagaimana menangani error dan berbagai mekanisme yang tersedia untuk kita.

Secara umum, konvensi dalam Elixir adalah untuk membuat sebuah fungsi (`example/1`) yang mengembalikan `{:ok, result}` dan `{:error, reason}` dan fungsi lain yang terpisah (`example!/1`) yang mengembalikan `result` saja atau memunculkan (raise) sebuah error.

Pelajaran ini akan fokus pada berinteraksi dengan yang terakhir.

{% include toc.html %}

## Penanganan Error

Sebelum kita dapat menangani error kita perlu membuatnya dan cara termudah adalah dengan `raise/1`:

```elixir
iex> raise "Oh no!"
** (RuntimeError) Oh no!
```

Jika kita ingin menspesifikasikan tipe dan pesan kesalahan (message), kita perlu menggunakan `raise/2`:

```elixir
iex> raise ArgumentError, message: "the argument value is invalid"
** (ArgumentError) the argument value is invalid
```

Ketika kita tahu sebuah error bisa muncul, kita bisa menanganinya menggunakan `try/rescue` dan pencocokan pola:

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> end
An error occurred: Oh no!
:ok
```

Adalah mungkin mencocokkan banyak error dalam satu rescue tunggal:

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

Pada berbagai kesempatan mungkin perlu melakukan beberapa tindakan setelah `try/rescue` kita apapun errornya.  Untuk ini kita punya `try/after`.  Jika anda familiar dengan Ruby ini seperti `begin/rescue/ensure` atau di Java `try/catch/finally`:

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
{:ok, file} = File.open "example.json"
try do
   # Do hazardous work
after
   File.close(file)
end
```

## Error Baru

Sementara Elixir mencakup sejumlah tipe error yang built in seperti `RuntimeError` kita punya kemampuan membuat tipe error sendiri jika kita perlu sesuatu yang spesifik.  Membuat error baru adalah mudah dengan macro `defexception/1` yang menerima opsi `:message` untuk menset pesan kesalahan default:

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

Mekanisme lain untuk bekerja dengan error dalam Elixir adalah `throw` and `catch`.  Dalam prakteknya ini sangat jarang muncul dalam code Elixir yang lebih baru tetapi tetap penting untuk diketahui dan dipahami.

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

Sebagaimana disinggung, `throw/catch` cukup jarang ada dan biasanya hadir sebagai penghadang (stopgap) ketika librari gagal menyediakan API yang memadai.

## Exit

Mekanisme kesalahan Elixir yang terakhir adalah `exit`.  Signal exit muncul manakala sebuah proses mati dan merupakan bagian penting dalam toleransi kegagalan Elixir.

Untuk keluar secara eksplisit kita bisa gunakan `exit/1`:

```elixir
iex> spawn_link fn -> exit("oh no") end
** (EXIT from #PID<0.101.0>) evaluator process exited with reason: "oh no"
```

Walau adalah mungkin menangkap sebuah exit dengan `try/catch`, melakukannya adalah _sangat_ jarang.  Dalam hampir semua kasus lebih baik membiarkan supervisor menangani exit proses tersebut:

```elixir
iex> try do
...>   exit "oh no!"
...> catch
...>   :exit, _ -> "exit blocked"
...> end
"exit blocked"
```
