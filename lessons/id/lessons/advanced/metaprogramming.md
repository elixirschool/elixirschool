%{
  version: "0.9.1",
  title: "Metaprogramming",
  excerpt: """
  Metaprogramming adalah proses menggunakan code untuk menulis code.  Dalam Elixir hal ini memberi kita kemampuan mengembangkan bahasa ini agar sesuai dengan kebutuhan kita dan mengubah code secara dinamis.  Kita akan mulai dengan melihat bagaimana Elixir direpresentasikan di dalamnya, bagaimana mengubahnya, dan akhirnya kita bisa menggunakan pengetahuan itu untuk mengembangkannya.

Perhatian:  Metaprogramming itu tidak mudah dan hanya patut digunakan ketika teramat perlu.  Terlalu banyak menggunakannya hampir pasti hasilkan code yang kompleks dan sulit dipahami dan didebug.
  """
}
---

## Quote

Langkah pertama metaprogramming adalah memahami bagaimana expression itu direpresentasikan.  Dalam Elixir abstract syntax tree (AST), representasi internal code kita, disusun dalam tuple.  Tuple-tuple ini terdiri dari tiga bagian: nama fungsi, metadata, dan argumen-argumen fungsi.

Untuk melihat struktur internal ini, Elixir memberi kita fungsi `quote/2`.  Menggunakan `quote/2` kita dapat mengubah code Elixir menjadi representasi mendasarnya:

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

Lihat bahwa tiga yang pertama di atas tidak menghasilkan tuple?  Ada lima literal yang mengembalikan dirinya sendiri ketika di-quote:

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

Sekarang, setelah kita bisa mengakses struktur internal code kita, bagaimana kita mengubahnya?  Untuk memasukkan code atau value yang baru kita gunakan `unquote/1`.  Ketika kita melakukan unquote sebuah ekspresi, ekspresi tersebut akan dievaluasi dan dimasukkan ke AST.  Untuk mendemonstrasikan `unquote/1` mari lihat beberapa contoh:

```elixir
iex> denominator = 2
2
iex> quote do: divide(42, denominator)
{:divide, [], [42, {:denominator, [], Elixir}]}
iex> quote do: divide(42, unquote(denominator))
{:divide, [], [42, 2]}
```

Dalam contoh pertama variabel `denominator` kita di-quote sehingga AST yang dihasilkan berisi tuple untuk mengakses variabel tersebut.  Dalam contoh yang `unquote/1` code yang dihasilkan mengandung nilai dari `denominator`.

## Macro

Begitu kita paham `quote/2` dan `unquote/1` kita siap untuk masuk ke macro.  Adalah penting diingat bahwa macro, seperti halnya semua metaprogramming, sepatutnya digunakan secara tidak boros.

Dalam bentuk yang paling sederhana macro adalah fungsi khusus yang dirancang untuk mengembalikan sebuah ekspresi yang di-quote yang akan disisipkan ke dalam code aplikasi kita.  Bayangkan macro tersebut diganti dengan ekspresi yang ter-quote dan bukannya dipanggil seperti sebuah fungsi.  Dengan macro kita punya semua yang dibutuhkan untuk mengembangkan Elixir dan secara dinamis menambahkan code ke aplikasi kita.

Kita mulai dengan mendefinisikan sebuah macro dengan `defmacro/2` yang, seperti banyak bagian Elixir, sendirinya adalah sebuah macro.  Sebagai sebuah contoh kita akan mengimplementasikan `unless` sebagai sebuah macro.  Ingatlah bahwa macro kita harus mengembalikan ekspresi yang ter-quote:

```elixir
defmodule OurMacro do
  defmacro unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end
```

Mari require modul kita dan tes macro kita:

```elixir
iex> require OurMacro
nil
iex> OurMacro.unless true, do: "Hi"
nil
iex> OurMacro.unless false, do: "Hi"
"Hi"
```

Karena macro mengganti code kita dalam aplikasi kita, kita bisa mengendalikan kapan dan apa yang dikompilasi.  Sebuah contoh untuk ini dapat ditemukan di modul `Logger`.  Ketika logging dimatikan tidak ada code yang dimasukkan dan aplikasi yang dihasilkan tidak mengandung referensi atau pemanggilan fungsi ke logging.  Ini berbeda dengan bahasa lain dimana masih ada overhead dari sebuah pemanggilan fungsi bahkan ketika implementasinya adalah NOP (tidak ada eksekusi).

Untuk mendemonstrasikan ini kita akan membuat sebuah logger sederhana yang bisa diaktifkan dan dimatikan:

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

Dengan logging diaktifkan fungsi `test` kita akan tampak seperti ini:

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

### Private Macro

Walau tidak begitu umum, Elixir mendukung macro yang privat.  Sebuah macro privat didefinisikan dengan `defmacrop` dan hanya bisa dipanggil dari dalam modul tempatnya didefinisikan.  Macro privat harus didenifisikan sebelum code yang memanggilnya.

### Macro Hygiene

Bagaimana macro berinteraksi dengan konteks pemanggilnya ketika disisipkan/diekspansi dikenal dengan macro hygiene. Secara default macro di Elixir adalah higienis dan tidak berkonflik dengan konteks code kita:

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

Tetapi bagaimana jika kita ingin memanipulasi nilai `val`?  Untuk menandai sebuah variabel sebagai tidak higienis kita bisa menggunakan `var!/2`.  Mari coba ubah contoh kita untuk menggunakan macro lain yang menggunakan `var!/2`:

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

Dengan menggunakan `var!/2` dalam macro kita, kita memanipulasi nilai dari `val` tanpa mengirimkannya ke dalam macro kita (sebagai argumen misalnya).  Penggunaan macro non-higienis mesti dijaga tetap minimal.  Dengan menggunakan `var!/2` kita menaikkan resiko konflik variabel.

### Binding

Kita sudah membahas kegunaan `unquote/1`, tapi ada cara lain untuk menyisipkan value ke code kita: pengikatan (binding).  Dengan pengikatan variabel (variable binding) kita bisa menyertakan banyak variabel dalam macro kita dan memastikan variabel-variabel tersebut hanya di-unqote sekali, menghindari reevaluasi tanpa sengaja. Untuk menggunakan variabel yang diikat kita perlu memasukkan daftar keyword (keyword list) ke opsi `bind_quoted` di `quote/2`.

Untuk melihat manfaat dari `bind_quote` dan untuk mendemonstrasikan masalah reevaluasi, mari kita gunakan sebuah contoh.  Kita bisa mulai dengan membuat sebuah macro yang menuliskan ekspresinya dua kali:

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

Kita akan mencoba macro kita yang baru ini dengan memberinya waktu sistem saat ini.  Kita harusnya mengharapkan tampilnya tulisan yang sama dua kali:

```elixir
iex> Example.double_puts(:os.system_time)
1450475941851668000
1450475941851733000
```

Waktunya berbeda!  Ada apa?  Menggunakan `unquote/1` pada ekspresi yang sama beberapa kali menghasilkan reevaluasi dan hal itu bisa memiliki konsekuensi yang tidak diharapkan.  Mari ubah contoh tersebut dengan menggunakan `bind_quoted` dan lihat apa yang kita dapat:

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

Sekarang setelah kita membahas `quote/2`, `unquote/1`, dan `defmacro/2` kita punya semua yang diperlukan untuk mengembangkan Elixir untuk sesuai kebutuhan kita.
