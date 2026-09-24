%{
  version: "1.0.3",
  title: "Spesifikasi dan Tipe",
  excerpt: """
  Dalam pelajaran ini kita akan mempelajari tentang sintaks `@spec` dan `@type`.
  `@spec` lebih merupakan pelengkap sintaks untuk menulis dokumentasi yang dapat dianalisis oleh alat.
  `@type` membantu kita menulis kode yang lebih mudah dibaca dan dipahami.
  """
}
---

## Pendahuluan

Tidak jarang Anda ingin mendeskripsikan antarmuka fungsi Anda.
Anda dapat menggunakan anotasi `@doc`, tetapi itu hanya informasi untuk pengembang lain yang tidak diperiksa pada waktu kompilasi.
Untuk tujuan ini, Elixir memiliki anotasi `@spec` untuk mendeskripsikan spesifikasi fungsi yang akan diperiksa oleh kompiler.

Namun, dalam beberapa kasus, spesifikasi akan cukup besar dan rumit.
Jika Anda ingin mengurangi kompleksitas, Anda ingin memperkenalkan definisi tipe kustom.
Elixir memiliki anotasi `@type` untuk itu.
Di sisi lain, Elixir masih merupakan bahasa dinamis.
Itu berarti semua informasi tentang suatu tipe akan diabaikan oleh kompiler, tetapi dapat digunakan oleh alat lain.

## Spesifikasi

Jika Anda memiliki pengalaman dengan Java, Anda dapat menganggap spesifikasi sebagai `interface`.
Spesifikasi mendefinisikan apa yang seharusnya menjadi tipe parameter fungsi dan nilai kembaliannya.

Untuk mendefinisikan tipe input dan output, kita menggunakan direktif `@spec` yang ditempatkan tepat sebelum definisi fungsi dan mengambil `params` sebagai nama fungsi, daftar tipe parameter, dan setelah `::` tipe nilai kembalian.

Mari kita lihat contohnya:

```elixir
@spec sum_product(integer) :: integer
def sum_product(a) do
  [1, 2, 3]
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
end
```

Semuanya tampak baik-baik saja dan ketika kita memanggilnya, hasil yang valid akan dikembalikan, tetapi fungsi `Enum.sum` mengembalikan `angka`, bukan `bilangan bulat` seperti yang kita harapkan di `@spec`.
Ini bisa menjadi sumber bug! Ada alat seperti Dialyzer untuk melakukan analisis statis kode yang membantu kita menemukan jenis bug ini.
Kita akan membahasnya di pelajaran lain.

## Tipe Kustom

Menulis spesifikasi itu bagus, tetapi terkadang fungsi kita bekerja dengan struktur data yang lebih kompleks daripada sekadar angka atau koleksi sederhana.
Dalam kasus definisi tersebut di `@spec`, mungkin sulit dipahami dan/atau diubah oleh pengembang lain.
Terkadang fungsi perlu menerima sejumlah besar parameter atau mengembalikan data yang kompleks.
Daftar parameter yang panjang adalah salah satu dari banyak potensi masalah dalam kode seseorang.
Dalam bahasa berorientasi objek seperti Ruby atau Java, kita dapat dengan mudah mendefinisikan kelas yang membantu kita menyelesaikan masalah ini.
Elixir tidak memiliki kelas, tetapi karena mudah diperluas, kita dapat mendefinisikan tipe kita sendiri.

Secara bawaan, Elixir berisi beberapa tipe dasar seperti `integer` atau `pid`.
Anda dapat menemukan daftar lengkap tipe yang tersedia di [dokumentasi](https://hexdocs.pm/elixir/typespecs.html#types-and-their-syntax).

### Mendefinisikan tipe kustom

Mari kita modifikasi fungsi `sum_times` kita dan tambahkan beberapa parameter tambahan:

```elixir
@spec sum_times(integer, %Examples{first: integer, last: integer}) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

Kita memperkenalkan sebuah struct di modul `Examples` yang berisi dua field - `first` dan `last`.
Ini adalah versi yang lebih sederhana dari struct di modul `Range`.
Untuk informasi lebih lanjut tentang `struct`, silakan lihat bagian tentang [modul](/id/lessons/basics/modules#structs).
Mari kita bayangkan bahwa kita membutuhkan spesifikasi dengan struct `Examples` di banyak tempat.
Akan merepotkan untuk menulis spesifikasi yang panjang dan kompleks dan dapat menjadi sumber bug.
Solusi untuk masalah ini adalah `@type`.

Elixir memiliki tiga arahan untuk tipe:

- `@type` – tipe publik yang sederhana.
Struktur internal tipe bersifat publik.
- `@typep` – tipe bersifat privat dan hanya dapat digunakan di modul tempat tipe tersebut didefinisikan.
- `@opaque` – tipe bersifat publik, tetapi struktur internal bersifat privat.

Mari kita definisikan tipe kita:

```elixir
defmodule Examples do
  defstruct first: nil, last: nil

  @type t(first, last) :: %Examples{first: first, last: last}

  @type t :: %Examples{first: integer, last: integer}
end
```

Kita sudah mendefinisikan tipe `t(first, last)`, yang merupakan representasi dari struct `%Examples{first: first, last: last}`.
Pada titik ini kita melihat bahwa tipe dapat mengambil parameter, tetapi kita juga mendefinisikan tipe `t` dan kali ini merupakan representasi dari struct `%Examples{first: integer, last: integer}`.

Apa perbedaannya? Yang pertama mewakili struct `Examples` di mana kedua kuncinya dapat berupa tipe apa pun.
Yang kedua mewakili struct di mana kuncinya adalah `integer`.
Ini berarti kode yang terlihat seperti ini:

```elixir
@spec sum_times(integer, Examples.t()) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

Sama dengan kode seperti:

```elixir
@spec sum_times(integer, Examples.t(integer, integer)) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

### Dokumentasi Tipe

Elemen terakhir yang perlu kita bahas adalah cara mendokumentasikan tipe kita.
Seperti yang kita ketahui dari pelajaran [dokumentasi](/id/lessons/basics/documentation), kita memiliki anotasi `@doc` dan `@moduledoc` untuk membuat dokumentasi fungsi dan modul.
Untuk mendokumentasikan tipe kita, kita dapat menggunakan `@typedoc`:

```elixir
defmodule Examples do
  @typedoc """
      Type that represents Examples struct with :first as integer and :last as integer.
  """
  @type t :: %Examples{first: integer, last: integer}
end
```

Direktif `@typedoc` mirip dengan `@doc` dan `@moduledoc`.
