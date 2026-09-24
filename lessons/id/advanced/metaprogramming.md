%{
  version: "1.0.4",
  title: "Metaprogramming",
  excerpt: """
  Metaprogramming adalah proses menggunakan kode untuk menulis kode.
  Dalam Elixir, ini memberi kita kemampuan untuk memperluas bahasa agar sesuai dengan kebutuhan kita dan mengubah kode secara dinamis.
  Kita akan mulai dengan melihat bagaimana Elixir direpresentasikan di balik layar, kemudian bagaimana memodifikasinya, dan akhirnya kita dapat menggunakan pengetahuan ini untuk memperluasnya.
  
  Peringatan: Metaprogramming itu rumit dan hanya boleh digunakan jika diperlukan.
  Penggunaan berlebihan hampir pasti akan menghasilkan kode yang kompleks yang sulit dipahami dan di-debug.
  """
}
---

## Quote

Langkah pertama menuju metaprogramming adalah memahami bagaimana ekspresi direpresentasikan.
Di Elixir, pohon sintaks abstrak (abstract syntax tree atau AST), representasi internal kode kita, terdiri dari tuple.
Tuple ini berisi tiga bagian: nama fungsi, metadata, dan argumen fungsi.

Untuk melihat struktur internal ini, Elixir menyediakan fungsi `quote/2`.
Dengan menggunakan `quote/2`, kita dapat mengkonversi kode Elixir ke representasi dasarnya:

```elixir
iex> quote do: 42
42
iex> quote do: "Hello"
"Hello"
iex> quote do: :world
:world
iex> quote do: 1 + 2
{:+, [context: Elixir, import: Kernel], [1, 2]}
iex> quote do: if value, do: "True", else: "False"
{:if, [context: Elixir, import: Kernel],
 [{:value, [], Elixir}, [do: "True", else: "False"]]}
```

Perhatikan bahwa tiga yang pertama tidak mengembalikan tuple? Ada lima literal yang mengembalikan dirinya sendiri ketika di-quote:

```elixir
iex> :atom
:atom
iex> "string"
"string"
iex> 1 # All numbers
1
iex> [1, 2] # Lists
[1, 2]
iex> {"hello", :world} # 2 element tuples
{"hello", :world}
```

## Unquote

Sekarang kita dapat mengambil struktur internal kode kita, bagaimana cara kita memodifikasinya? Untuk menyuntikkan kode atau nilai baru, kita menggunakan `unquote/1`.
Saat kita menghapus tanda kutip pada sebuah ekspresi, ekspresi tersebut akan dievaluasi dan disuntikkan ke dalam AST.
Untuk mendemonstrasikan `unquote/1`, mari kita lihat beberapa contoh:

```elixir
iex> denominator = 2
2
iex> quote do: divide(42, denominator)
{:divide, [], [42, {:denominator, [], Elixir}]}
iex> quote do: divide(42, unquote(denominator))
{:divide, [], [42, 2]}
```

Pada contoh pertama, variabel `denominator` kita diberi tanda kutip sehingga AST yang dihasilkan menyertakan tuple untuk mengakses variabel tersebut.
Pada contoh `unquote/1`, kode yang dihasilkan menyertakan nilai `denominator` sebagai gantinya.

## Makro

Setelah kita memahami `quote/2` dan `unquote/1`, kita siap untuk mempelajari makro (macro).
Penting untuk diingat bahwa makro, seperti semua metaprogramming, harus digunakan dengan hemat.

Pada intinya, makro adalah fungsi kasus khusus yang dirancang untuk mengembalikan ekspresi yang dikutip yang akan dimasukkan ke dalam kode aplikasi kita.
Bayangkan makro tersebut diganti dengan ekspresi yang dikutip, bukan dipanggil seperti fungsi.
Dengan makro, kita memiliki semua yang diperlukan untuk memperluas Elixir dan menambahkan kode secara dinamis ke aplikasi kita.

Kita mulai dengan mendefinisikan makro menggunakan `defmacro/2` yang, seperti sebagian besar Elixir, itu sendiri adalah makro (renungkan hal itu).
Sebagai contoh, kita akan mengimplementasikan `unless` sebagai makro.
Ingat bahwa makro kita perlu mengembalikan ekspresi yang dikutip:

```elixir
defmodule OurMacro do
  defmacro unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end
```

Mari kita panggil modul kita dan coba jalankan makro kita:

```elixir
iex> require OurMacro
nil
iex> OurMacro.unless true, do: "Hi"
nil
iex> OurMacro.unless false, do: "Hi"
"Hi"
```

Karena makro menggantikan kode dalam aplikasi kita, kita dapat mengontrol kapan dan apa yang dikompilasi.
Contohnya dapat ditemukan di modul `Logger`.
Ketika pencatatan (logging) dinonaktifkan, tidak ada kode yang disuntikkan dan aplikasi yang dihasilkan tidak berisi referensi atau panggilan fungsi ke pencatatan.
Ini berbeda dari bahasa lain di mana masih ada overhead dari panggilan fungsi bahkan ketika implementasinya adalah NOP (No Operating Procedures).

Untuk mendemonstrasikan hal ini, kita akan membuat logger sederhana yang dapat diaktifkan atau dinonaktifkan:

```elixir
defmodule Logger do
  defmacro log(msg) do
    if Application.get_env(:logger, :enabled) do
      quote do
        IO.puts("Logged message: #{unquote(msg)}")
      end
    end
  end
end

defmodule Example do
  require Logger

  def test do
    Logger.log("This is a log message")
  end
end
```

Dengan mengaktifkan pencatatan log, fungsi `test` kita akan menghasilkan kode yang kurang lebih seperti ini:

```elixir
def test do
  IO.puts("Logged message: #{"This is a log message"}")
end
```

Tapi kalau logging dimatikan hasilnya jadi:

```elixir
def test do
end
```

## Debugging

Baiklah, sekarang kita sudah tahu cara menggunakan `quote/2`, `unquote/1` dan menulis makro.
Tetapi bagaimana jika Anda memiliki kode yang sangat panjang yang diapit tanda kutip dan ingin memahaminya? Dalam hal ini, Anda dapat menggunakan `Macro.to_string/2`.
Lihat contoh ini:

```elixir
iex> Macro.to_string(quote(do: foo.bar(1, 2, 3)))
"foo.bar(1, 2, 3)"
```

Dan ketika Anda ingin melihat kode yang dihasilkan oleh makro, Anda dapat menggabungkannya dengan `Macro.expand/2` dan `Macro.expand_once/2`, fungsi-fungsi ini memperluas makro ke dalam kode yang dikutip.
Yang pertama dapat memperluasnya beberapa kali, sedangkan yang kedua hanya sekali.
Sebagai contoh, mari kita modifikasi contoh `unless` dari bagian sebelumnya:

```elixir
defmodule OurMacro do
  defmacro unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end

require OurMacro

quoted =
  quote do
    OurMacro.unless(true, do: "Hi")
  end
```

```elixir
iex> quoted |> Macro.expand_once(__ENV__) |> Macro.to_string |> IO.puts
if(!true) do
  "Hi"
end
```

Jika kita menjalankan kode yang sama dengan `Macro.expand/2`, hasilnya menarik:

```elixir
iex> quoted |> Macro.expand(__ENV__) |> Macro.to_string |> IO.puts
case(!true) do
  x when x in [false, nil] ->
    nil
  _ ->
    "Hi"
end
```

Anda mungkin ingat bahwa kami telah menyebutkan `if` sebagai makro di Elixir, di sini kita melihatnya diperluas menjadi pernyataan `case` yang mendasarinya.

### Makro Privat

Walau tidak begitu umum, Elixir mendukung makro privat.
Makro privat didefinisikan dengan `defmacrop` dan hanya dapat dipanggil dari modul tempat makro tersebut didefinisikan.
Makro privat harus didefinisikan sebelum kode yang memanggilnya.

### Kebersihan Makro

Cara makro berinteraksi dengan konteks pemanggil saat diekspansi dikenal sebagai kebersihan makro (macro hygiene).
Secara default, makro di Elixir bersifat higienis dan tidak akan berkonflik dengan konteks kita:

```elixir
defmodule Example do
  defmacro hygienic do
    quote do: val = -1
  end
end

iex> require Example
nil
iex> val = 42
42
iex> Example.hygienic
-1
iex> val
42
```

Bagaimana jika kita ingin memanipulasi nilai `val`? Untuk menandai variabel sebagai tidak higienis, kita dapat menggunakan `var!/2`.
Mari kita perbarui contoh kita untuk menyertakan makro lain yang menggunakan `var!/2`:

```elixir
defmodule Example do
  defmacro hygienic do
    quote do: val = -1
  end

  defmacro unhygienic do
    quote do: var!(val) = -1
  end
end
```

Mari bandingkan bagaimana mereka berinteraksi dengan konteks kita:

```elixir
iex> require Example
nil
iex> val = 42
42
iex> Example.hygienic
-1
iex> val
42
iex> Example.unhygienic
-1
iex> val
-1
```

Dengan menyertakan `var!/2` dalam makro kita, kita memanipulasi nilai `val` tanpa meneruskannya ke dalam makro kita.
Penggunaan makro yang tidak higienis harus diminimalkan.
Dengan menyertakan `var!/2`, kita meningkatkan risiko konflik resolusi variabel.

### Pengikatan (Binding)

Kita sudah membahas kegunaan `unquote/1`, tetapi ada cara lain untuk memasukkan nilai ke dalam kode kita: pengikatan.
Dengan pengikatan variabel, kita dapat menyertakan beberapa variabel dalam makro kita dan memastikan variabel tersebut hanya dilepas tanda kutipnya sekali, menghindari evaluasi ulang yang tidak disengaja.
Untuk menggunakan variabel terikat, kita perlu memberikan daftar kata kunci ke opsi `bind_quoted` di `quote/2`.

Untuk melihat manfaat `bind_quoted` dan untuk mendemonstrasikan masalah evaluasi ulang, mari kita gunakan contoh.
Kita dapat mulai dengan membuat makro yang hanya mengeluarkan ekspresi dua kali:

```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote do
      IO.puts(unquote(expr))
      IO.puts(unquote(expr))
    end
  end
end
```

Kita akan mencoba makro baru kita dengan memberikan waktu sistem saat ini sebagai input.
Kita akan melihat outputnya dua kali:

```elixir
iex> Example.double_puts(:os.system_time)
1450475941851668000
1450475941851733000
```

Waktunya berbeda! Apa yang terjadi? Menggunakan `unquote/1` pada ekspresi yang sama beberapa kali mengakibatkan evaluasi ulang dan itu dapat menimbulkan konsekuensi yang tidak diinginkan.
Mari kita perbarui contohnya untuk menggunakan `bind_quoted` dan lihat apa yang kita dapatkan:

```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote bind_quoted: [expr: expr] do
      IO.puts(expr)
      IO.puts(expr)
    end
  end
end

iex> require Example
nil
iex> Example.double_puts(:os.system_time)
1450476083466500000
1450476083466500000
```

Dengan `bind_quoted` kita dapatkan hasil yang diharapkan: waktu yang sama dicetak dua kali.

Sekarang setelah kita membahas `quote/2`, `unquote/1`, dan `defmacro/2` kita punya semua alat yang diperlukan untuk mengembangkan Elixir agar sesuai kebutuhan kita.
