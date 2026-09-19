%{
  version: "1.4.2",
  title: "Modul",
  excerpt: """
  Bagaimana cara mengelompokkan fungsi dan mendefinisikan peta khusus 
  untuk mengatur kode kita lebih efisien.
  """
}
---

## Modul

Modul memungkinkan kita untuk mengorganisir fungsi ke dalam sebuah namespace.
Selain mengelompokkan fungsi, modul juga memungkinkan kita untuk mendefinisikan fungsi bernama dan fungsi privat yang telah kita bahas dalam [pelajaran fungsi](/id/lessons/basics/functions).

Mari kita lihat contoh dasar:

```elixir
defmodule Example do
  def greeting(name) do
    "Hello #{name}."
  end
end

iex> Example.greeting "Sean"
"Hello Sean."
```

Dimungkinkan untuk menyusun modul secara bertingkat di Elixir, mengizinkan Anda untuk membuat namespace lebih lanjut untuk fungsionalitas Anda:

```elixir
defmodule Example.Greetings do
  def morning(name) do
    "Good morning #{name}."
  end

  def evening(name) do
    "Good night #{name}."
  end
end

iex> Example.Greetings.morning "Sean"
"Good morning Sean."
```

### Atribut Modul

Atribut modul paling sering digunakan sebagai konstanta di Elixir.
Mari kita lihat contohnya:

```elixir
defmodule Example do
  @greeting "Hello"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

Catatan: konstruksi `~s` dalam contoh di atas adalah sigil string, ini dibahas dalam [pelajaran sigil](/id/lessons/basics/sigils).

Penting untuk dicatat bahwa ada atribut yang dicadangkan di Elixir.
Tiga yang paling umum adalah:

- `moduledoc` — Mendokumentasikan modul saat ini.
- `doc` — Dokumentasi untuk fungsi dan makro.
- `behaviour` — Menggunakan perilaku OTP atau perilaku yang ditentukan pengguna.

## Struct

Struct (sebuah Struktur) adalah map khusus dengan kumpulan kunci dan punya nilai default.
Sebuah struct harus didefinisikan di dalam sebuah modul, yang namanya diambil dari modul tersebut.
Sudah umum sebuah struct adalah satu-satunya hal yang didefinisikan di dalam sebuah modul.

Untuk mendefinisikan sebuah struct, kita menggunakan `defstruct` bersama dengan daftar kata kunci yang berisi field dan nilai default:

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

Mari buat beberapa struct:

```elixir
iex> %Example.User{}
%Example.User<name: "Sean", roles: [], ...>

iex> %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [], ...>

iex> %Example.User{name: "Steve", roles: [:manager]}
%Example.User<name: "Steve", roles: [:manager]>
```

Kita bisa mengubah struct seperti pada map:

```elixir
iex> steve = %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [...], ...>
iex> sean = %{steve | name: "Sean"}
%Example.User<name: "Sean", roles: [...], ...>
```

Lebih penting lagi, kamu bisa mencocokkan struct terhadap map:

```elixir
iex> %{name: "Sean"} = sean
%Example.User<name: "Sean", roles: [...], ...>
```

Mulai Elixir 1.8, struct menyertakan introspeksi kustom.
Untuk memahami apa artinya ini dan bagaimana kita menggunakannya, mari kita periksa tangkapan `sean` kita:

```elixir
iex> inspect(sean)
"%Example.User<name: \"Sean\", roles: [...], ...>"
```

Semua field kita sudah ada, yang mana tidak masalah untuk contoh ini, tetapi bagaimana jika kita memiliki field yang dilindungi yang tidak ingin kita sertakan?
Fitur `@derive` yang baru memungkinkan kita untuk melakukan hal ini!
Mari kita perbarui contoh kita sehingga `roles` tidak lagi disertakan dalam output kita:

```elixir
defmodule Example.User do
  @derive {Inspect, only: [:name]}
  defstruct name: nil, roles: []
end
```

_Catatan_: kita juga bisa menggunakan `@derive {Inspect, except: [:roles]}`, keduanya setara.

Dengan modul yang telah diperbarui, mari kita lihat apa yang terjadi di `iex`:

```elixir
iex> sean = %Example.User{name: "Sean"}
%Example.User<name: "Sean", ...>
iex> inspect(sean)
"%Example.User<name: \"Sean\", ...>"
```

`roles` tersebut dikecualikan dari output!

## Komposisi

Sekarang kita sudah tahu cara membuat modul dan struct, mari kita pelajari cara menambahkan fungsionalitas yang sudah ada ke dalamnya melalui komposisi.
Elixir menyediakan berbagai cara berbeda untuk berinteraksi dengan modul lain.

### alias

Memungkinkan kita untuk membuat alias nama modul; cukup sering digunakan dalam kode Elixir:

```elixir
defmodule Sayings.Greetings do
  def basic(name), do: "Hi, #{name}"
end

defmodule Example do
  alias Sayings.Greetings

  def greeting(name), do: Greetings.basic(name)
end

# Tanpa alias

defmodule Example do
  def greeting(name), do: Sayings.Greetings.basic(name)
end
```

Jika terjadi konflik antara dua alias atau kita ingin membuat alias ke nama yang berbeda sama sekali, kita dapat menggunakan opsi `:as`:

```elixir
defmodule Example do
  alias Sayings.Greetings, as: Hi

  def print_message(name), do: Hi.basic(name)
end
```

Dimungkinkan untuk membuat alias untuk beberapa modul sekaligus:

```elixir
defmodule Example do
  alias Sayings.{Greetings, Farewells}
end
```

### import

Jika kita ingin mengimpor fungsi daripada membuat alias untuk modul, kita dapat menggunakan `import`:

```elixir
iex> last([1, 2, 3])
** (CompileError) iex:9: undefined function last/1
iex> import List
nil
iex> last([1, 2, 3])
3
```

#### Penyaringan

Secara default, semua fungsi dan makro diimpor, tetapi kita dapat menyaringnya menggunakan opsi `:only` dan `:except`.

Untuk mengimpor fungsi dan makro tertentu, kita harus memberikan pasangan nama/aritas ke `:only` dan `:except`.
Mari kita mulai dengan mengimpor hanya fungsi `last/1`:

```elixir
iex> import List, only: [last: 1]
iex> first([1, 2, 3])
** (CompileError) iex:13: undefined function first/1
iex> last([1, 2, 3])
3
```

Jika kita mengimport semua kecuali `last/1` dan mencoba fungsi-fungsi yang sama seperti sebelumnya:

```elixir
iex> import List, except: [last: 1]
nil
iex> first([1, 2, 3])
1
iex> last([1, 2, 3])
** (CompileError) iex:3: undefined function last/1
```

Selain pasangan nama/aritas, terdapat dua atom kasus khusus, `:functions` dan `:macros`, yang masing-masing hanya mengimpor fungsi dan makro:

```elixir
import List, only: :functions
import List, only: :macros
```

### require

Kita bisa menggunakan `require` untuk memberi tahu Elixir bahwa kita akan menggunakan makro dari modul lain.
Perbedaan kecil dengan `import` adalah bahwa `require` memungkinkan penggunaan makro, tetapi bukan fungsi dari modul yang ditentukan:

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

Jika kita mencoba memanggil makro yang belum dimuat, Elixir akan menampilkan kesalahan.

### use

Dengan makro `use`, kita dapat memungkinkan modul lain untuk memodifikasi definisi modul kita saat ini.
Saat kita memanggil `use` dalam kode kita, sebenarnya kita memanggil callback `__using__/1` yang didefinisikan oleh modul yang diberikan.
Hasil dari makro `__using__/1` menjadi bagian dari definisi modul kita.
Untuk memahami cara kerjanya dengan lebih baik, mari kita lihat contohnya:

```elixir
defmodule Hello do
  defmacro __using__(_opts) do
    quote do
      def hello(name), do: "Hi, #{name}"
    end
  end
end
```

Di sini kita telah membuat modul `Hello` yang mendefinisikan callback `__using__/1` di dalamnya kita mendefinisikan fungsi `hello/1`.
Mari kita buat modul baru agar kita dapat mencoba kode baru kita:

```elixir
defmodule Example do
  use Hello
end
```

Jika kita mencoba kode kita di IEx, kita akan melihat bahwa `hello/1` tersedia di modul `Example`:

```elixir
iex> Example.hello("Sean")
"Hi, Sean"
```

Di sini kita dapat melihat bahwa `use` memanggil callback `__using__/1` pada `Hello` yang kemudian menambahkan kode yang dihasilkan ke modul kita.
Sekarang setelah kita mendemonstrasikan contoh dasar, mari kita perbarui kode kita untuk melihat bagaimana `__using__/1` mendukung opsi.
Kita akan melakukan ini dengan menambahkan opsi `greeting`:

```elixir
defmodule Hello do
  defmacro __using__(opts) do
    greeting = Keyword.get(opts, :greeting, "Hi")

    quote do
      def hello(name), do: unquote(greeting) <> ", " <> name
    end
  end
end
```

Mari kita perbarui modul `Example` kita untuk menyertakan opsi `greeting` yang baru dibuat:

```elixir
defmodule Example do
  use Hello, greeting: "Hola"
end
```

Jika kita mencobanya di IEx, kita akan melihat bahwa sapaannya telah diubah:

```elixir
iex> Example.hello("Sean")
"Hola, Sean"
```

Ini adalah contoh untuk menunjukkan cara kerja `use`, tetapi ini adalah alat yang sangat ampuh dalam perangkat Elixir.
Saat Anda terus belajar tentang Elixir, perhatikan `use`, salah satu contoh yang pasti akan Anda lihat adalah `use ExUnit.Case, async: true`.

**Catatan**: `quote`, `alias`, `use`, `require` adalah makro yang terkait dengan [metaprogramming](/id/lessons/advanced/metaprogramming).
