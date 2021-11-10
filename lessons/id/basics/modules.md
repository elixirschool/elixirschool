%{
  version: "0.9.1",
  title: "Composition",
  excerpt: """
  Kita tahu dari pengalaman bahwa adalah menyusahkan jika kita mengumpulkan semua fungsi yang kita buat dalam file dan scope (cakupan) yang sama.  Dalam pelajaran ini kita akan mengulas bahgaimana mengelompokkan fungsi dan mendefinisikan suatu map khusus yang dikenal sebagai sebuah struct untuk mengorganisasikan code kita secara lebih efisien.
  """
}
---

## Modul

Modul adalah cara terbaik untuk mengorganisasikan fungsi ke dalam sebuah namespace.  Selain mengelompokkan fungsi, modul juga memungkinkan kita mendefinisikan fungsi bernama dan fungsi privat yang kita bahas di pelajaran sebelumnya.

Let's look at a basic example:

``` elixir
defmodule Example do
  def greeting(name) do
    ~s(Hello #{name}.)
  end
end

iex> Example.greeting "Sean"
"Hello Sean."
```

Kita bisa membuat modul bertingkat (nested) di Elixir, memungkinkan kita untuk mengelompokkan fungsi-fungsi lebih lanjut:

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

Atribut modul paling sering digunakan sebagai konstanta di Elixir.  Mari lihat contoh sederhana berikut:

```elixir
defmodule Example do
  @greeting "Hello"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

Penting dicatat bahwa ada atribut yang dicadangkan (reserved) di Elixir.  Tiga atribut tercadang (reserved attribute) yang paling umum adalah:

+ `moduledoc` — Dokumentasi modul.
+ `doc` — Dokumentasi fungsi dan makro.
+ `behaviour` — Menggunakan behaviour dari OTP atau yang didefinisikan oleh user.

## Struct

Struct adalah map yang spesial dengan sekumpulan key yang sudah didefinisikan dan punya nilai default.  Struct harus didefinisikan di dalam sebuah modul yang namanya juga menjadi nama struct tersebut.  Lazim terjadi bahwa struct tersebut merupakan satu-satunya yang didefinisikan di dalam sebuah modul.

Untuk mendefinisikan sebuah struct kita menggunakan `defstruct` bersama daftar keyword dari fieldnya dan juga nilai defaultnya:

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

Lebih penting lagi, anda bisa mencocokkan struct terhadap map:

```elixir
iex> %{name: "Sean"} = sean
%Example.User<name: "Sean", roles: [...], ...>
```

## Composition

Setelah kita tahu cara membuat modul dan struct, mari pelajari cara memasukkan fungsionalitas yang sudah ada ke dalamnya melalui komposisi (composition).  Elixir memberi kita beragam cara untuk berinteraksi dengan modul lain.

### alias

Elixir mengijinkan kita melakukan alias terhadap nama modul, sering dipakai di code Elixir:

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

If there's a conflict with two aliases or you just wish to alias to a different name entirely, we can use the `:as` option:

```elixir
defmodule Example do
  alias Sayings.Greetings, as: Hi

  def print_message(name), do: Hi.basic(name)
end
```

It's possible to alias multiple modules at once:

```elixir
defmodule Example do
  alias Sayings.{Greetings, Farewells}
end
```

### import

Jika kita ingin mengimpor fungsi dan macro dari modul lain dan bukannya melakukan alias terhadap modul tersebut kita bisa menggunakan `import`:

```elixir
iex> last([1, 2, 3])
** (CompileError) iex:9: undefined function last/1
iex> import List
nil
iex> last([1, 2, 3])
3
```

#### Filtering

Secara default semua fungsi dan macro diimpor, tetapi kita bisa memfilter menggunakan pilihan `:only` dan `:except`.

Untuk mengimpor fungsi dan macro secara spesifik, kita harus memberikan pasangan nama/arity ke `:only` dan `:except`.  Mari kita awali dengan hanya mengimpor fungsi `last/1`:

```elixir
iex> import List, only: [last: 1]
iex> first([1, 2, 3])
** (CompileError) iex:13: undefined function first/1
iex> last([1, 2, 3])
3
```

Jika kita mengimport semua kecuali `last/1` dan mencoba fungsi-fungsi yang sama dengan sebelumnya:

```elixir
iex> import List, except: [last: 1]
nil
iex> first([1, 2, 3])
1
iex> last([1, 2, 3])
** (CompileError) iex:3: undefined function last/1
```

Sebagai tambahan pada pasangan nama/arity, ada dua atom spesial `:functions` dan `macros`, yang masing-masing hanya mengimpor fungsi dan macro:

```elixir
import List, only: :functions
import List, only: :macros
```

### require

Walau lebih jarang dipakai `require/2` tetaplah penting.  Melakukan require pada sebuah modul memastikan bahwa modul itu dikompilasi dan dimuat (load).  Ini paling berguna kala kita perlu mengakses makro di sebuah modul:

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

Jika kita mencoba memanggil sebuah macro yang belum dimuat, Elixir akan menghasilkan error.

### use

Menggunakan sebuah modul di konteks saat ini.  Ini khususnya berguna ketika sebuah modul perlu melakukan setup.  Dengan memanggil `use` kita mengaktifkan hook `__using__` di dalam modul tersebut, memungkinkan modul tersebut mengubah konteks yang ada:

```elixir
defmodule MyModule do
  defmacro __using__(opts) do
    quote do
      import MyModule.Foo
      import MyModule.Bar
      import MyModule.Baz

      alias MyModule.Repo
    end
  end
end
```
