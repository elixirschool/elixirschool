%{
  version: "0.9.1",
  title: "Komposisi",
  excerpt: """
  Kita tahu dari pengalaman bahawa menyimpan semua fungsi di dalam satu fail dan skop membawa kepada keadaan kelam-kabut.  Di dalam pelajaran ini kita akan melihat bagaimana untuk meletakkan beberapa fungsi ke dalam satu kumpulan dan menetapkan sejenis map khas yang dikenali sebagai struct dalam usaha untuk menguruskan kod kita dengan lebih efisien.
  """
}
---

## Modul

Penggunaan modul-modul adalah cara yang terbaik untuk menguruskan fungsi-fungsi di dalam satu namespace.  Tambahan kepada pengumpulan fungsi-fungsi, mereka juga membenarkan kita menetapkan fungsi bernama dan fungsi terlindung yang telah kita lihat dalam pelajaran lepas.

Mari kita lihat satu contoh asas:

``` elixir
defmodule Example do
  def greeting(name) do
    "Hello #{name}."
  end
end

iex> Example.greeting "Sean"
"Hello Sean."
```

Elixir membolehkan untuk membina modul dalam bentuk bersarang, membenarkan anda untuk mengembangkan penggunaan 'namespace' kefungsian anda:

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

### Ciri-ciri Modul

Ciri-ciri modul adalah yang paling kerap digunakan sebagai pemalar di dalam Elixir.  Mari kita lihat satu contoh ringkas:

```elixir
defmodule Example do
  @greeting "Hello"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

Adalah penting untuk dijelaskan bahawa terdapat beberapa ciri-ciri simpanan dalam Elixir.  Tiga yang paling biasa adalah:

+ `moduledoc` — menjana dokumentasi modul semasa.
+ `doc` — menjana dokumentasi untuk fungsi dan makro.
+ `behaviour` — penggunaan OTP atau kelakuan tetapan pengguna.

## Struct

Struct adalah sejenis map khas yang mengandungi satu set key dan value.  Ia mesti ditetapkan di dalam satu modul, yang mana ia mendapat namanya(nama struct adalah nama modul yang mana ia terkandung).  Menjadi kebiasaan apabila satu modul hanya mengandungi struct di dalamnya.

Gunakan `defstruct` untuk menetapkan satu struct, di samping satu list katakunci yang mengandungi katakunci dan nilai lalai:

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

Mari kita bina beberapa struct:

```elixir
iex> %Example.User{}
%Example.User<name: "Sean", roles: [], ...>

iex> %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [], ...>

iex> %Example.User{name: "Steve", roles: [:manager]}
%Example.User<name: "Steve", roles: [:manager]>
```

Kita boleh mengemaskini struct sebagaimana kita mengemaskini map:

```elixir
iex> steve = %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [...], ...>
iex> sean = %{steve | name: "Sean"}
%Example.User<name: "Sean", roles: [...], ...>
```

Paling penting, anda boleh membuat padanan antara struct dan map:

```elixir
iex> %{name: "Sean"} = sean
%Example.User<name: "Sean", roles: [...], ...>
```

## Komposisi

Setelah kita mengetahui cara untuk membina modul dan struct, kini masa untuk mempelajari cara untuk memasukkan kefungsian sedia ada ke dalam modul tersebut melalui komposisi.  Elixir membekalkan kita beberapa cara berbeza untuk berinteraksi dengan modul-modul lain, mari lihat apa yang telah disediakan untuk kita.

### `alias`

Membenarkan kita membuat alias nama modul, paling kerap digunakan dalam kod Elixir:

```elixir
defmodule Sayings.Greetings do
  def basic(name), do: "Hi, #{name}"
end

defmodule Example do
  alias Sayings.Greetings

  def greeting(name), do: Greetings.basic(name)
end

# tanpa alias

defmodule Example do
  def greeting(name), do: Sayings.Greetings.basic(name)
end
```

Jika terdapat konflik antara dua alias, atau anda cuma mahu membuat alias kepada nama lain, kita boleh gunakan option `:as`:

```elixir
defmodule Example do
  alias Sayings.Greetings, as: Hi

  def print_message(name), do: Hi.basic(name)
end
```

Ianya dibolehkan untuk alias pelbagai modul pada masa yang sama:

```elixir
defmodule Example do
  alias Sayings.{Greetings, Farewells}
end
```

### `import`

Jika kita tidak mahu menggunakan alias, kita boleh mengimport fungsi-fungsi dan makro-makro dengan menggunakan  `import/`:

```elixir
iex> last([1, 2, 3])
** (CompileError) iex:9: undefined function last/1
iex> import List
nil
iex> last([1, 2, 3])
3
```

#### Filtering

Apabila kita mengimport sesatu modul, semua fungsi dan makro di dalam modul tersebut akan diimport secara lalai tetapi kita boleh filter mereka dengan menggunakan option-option `:only` dan `:except`.

Apabila mengimport fungsi-fungsi dan makro-makro khusus kita mesti menyediakan pasangan 'name/arity' kepada `:only` dan `:except`.  Kita akan mula mengimport hanya fungsi `last/1`:

```elixir
iex> import List, only: [last: 1]
iex> first([1, 2, 3])
** (CompileError) iex:13: undefined function first/1
iex> last([1, 2, 3])
3
```

Jika kita mengimport kesemua fungsi-fungsi kecuali fungsi `last/1`:

```elixir
iex> import List, except: [last: 1]
nil
iex> first([1, 2, 3])
1
iex> last([1, 2, 3])
** (CompileError) iex:3: undefined function last/1
```

Sebagai tambahan kepada pasangan 'name/arity' terdapat dua jenis atom istimewa, `:functions` dan `:macros`, yang masing-masing hanya mengimport fungsi dan makro.

```elixir
import List, only: :functions
import List, only: :macros
```

### `require`

Walaupun tidak kerap digunakan `require/2` tidak kurang pentingnya.  Kepemerluan satu modul memastikan ianya dikompilkan dan dipasang.  Ianya amat berguna apabila kita perlu mencapai makro sesatu modul:


```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

Jika kita cuba memanggil satu makro yang masih belum dipasang Elixir akan menimbulkan ralat.

### `use`

Menggunakan modul dalam konteks semasa.  Ianya amat berguna apabila satu modul perlu melakukan beberapa tetapan.  Dengan memanggil `use`, kita juga secara spontan memanggil 'hook'`__using__` di dalam modul tersebut, memberikan peluang kepada modul tersebut untuk membuat perubahan kepada konteks semasa:

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
