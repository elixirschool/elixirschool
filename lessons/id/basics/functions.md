%{
  version: "1.3.1",
  title: "Fungsi",
  excerpt: """
  Di Elixir dan banyak bahasa fungsional lainnya, fungsi adalah warga kelas satu.
  Kita akan pelajari tentang tipe-tipe fungsi di Elixir, apa yang membuatnya berbeda, dan bagaimana menggunakannya.
  """
}
---

## Fungsi Anonim

Sesuai namanya, fungsi anonim tidak memiliki nama.
Seperti yang telah kita lihat di pelajaran `Enum`, fungsi ini sering kali diteruskan ke fungsi lain.
Untuk mendefinisikan sebuah fungsi anonim di Elixir kita perlu kata `fn` dan `end`.
Di antara keduanya kita dapat mendefinisikan sejumlah parameter dan isi fungsi yang dipisahkan oleh `->`.

Mari lihat sebuah contoh dasar:

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### Singkatan &

Penggunaan fungsi anonim adalah praktek yang sangat umum sehingga ada singkatan untuk melakukannya:

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

Sebagai yang bisa diduga, dalam versi singkat, parameter kita bisa diakses sebagai `&1`, `&2`, `&3`, dan seterusnya.

## Pencocokan pola

Pencocokan pola tidak terbatas pada variabel di Elixir, tetapi juga dapat diterapkan pada penanda fungsi (function signature) seperti dapat kita lihat dalam bagian ini.

Elixir menggunakan pencocokan pola untuk memeriksa semua opsi pencocokan yang mungkin dan memilih opsi pencocokan pertama yang akan dijalankan:

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:ok, _} -> IO.puts "This would be never run as previous will be matched beforehand."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
1
iex> handle_result.({:ok, some_result})
Handling result...
:ok
iex> handle_result.({:error})
An error has occurred!
:ok
```

## Fungsi Bernama

Kita dapat mendefinisikan fungsi dengan nama sehingga kita dapat merujuk nanti.
Fungsi bernama didefinisikan di dalam sebuah modul menggunakan kata kunci `def`.
Kita akan mempelajari lebih lanjut tentang Modul di pelajaran berikutnya, untuk saat ini kita akan fokus pada fungsi bernama saja.

Fungsi yang didefinisikan dalam sebuah modul tersedia untuk digunakan oleh modul lain.
Ini adalah blok bangunan khusus yang sangat berguna di Elixir:

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

Jika tubuh fungsi kita hanya terdiri dari satu baris, kita dapat menyingkatnya dengan `do:`:

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

Berbekal pengetahuan kita tentang pencocokan pola, mari kita eksplorasi rekursi menggunakan fungsi bernama:

```elixir
defmodule Length do
  def of([]), do: 0
  def of([_ | tail]), do: 1 + of(tail)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### Penamaan Fungsi dan Aritas

Seperti yang telah disebutkan sebelumnya, fungsi diberi nama berdasarkan kombinasi nama yang diberikan dan aritas (jumlah argumen).
Ini berarti Anda dapat melakukan hal-hal seperti ini:

```elixir
defmodule Greeter2 do
  def hello(), do: "Hello, anonymous person!"   # hello/0
  def hello(name), do: "Hello, " <> name        # hello/1
  def hello(name1, name2), do: "Hello, #{name1} and #{name2}"
                                                # hello/2
end

iex> Greeter2.hello()
"Hello, anonymous person!"
iex> Greeter2.hello("Fred")
"Hello, Fred"
iex> Greeter2.hello("Fred", "Jane")
"Hello, Fred and Jane"
```

Kami telah mencantumkan nama fungsi dalam komentar di atas.
Implementasi pertama tidak mengambil argumen, jadi dikenal sebagai `hello/0`; Yang kedua menerima satu argumen sehingga dikenal sebagai `hello/1`, dan seterusnya.
Tidak seperti _overload_ fungsi di beberapa bahasa lain, ini dianggap sebagai fungsi yang _berbeda_ satu sama lain.
(Pencocokan pola, yang dijelaskan beberapa saat yang lalu, hanya berlaku ketika beberapa definisi diberikan untuk definisi fungsi dengan jumlah argumen yang _sama_.)

### Fungsi dan Pencocokan Pola

Di balik layar, fungsi mencocokkan pola argumen yang dipanggil.

Misalnya, kita membutuhkan fungsi untuk menerima peta (map) tetapi kita hanya tertarik menggunakan kunci tertentu.
Kita dapat mencocokkan argumen berdasarkan keberadaan kunci tersebut seperti ini:

```elixir
defmodule Greeter1 do
  def hello(%{name: person_name}) do
    IO.puts "Hello, " <> person_name
  end
end
```

Sekarang, misalkan kita memiliki peta (map) yang menggambarkan seseorang bernama Fred:

```elixir
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"
...> }
```

Berikut adalah hasil yang akan kita dapatkan ketika kita memanggil `Greeter1.hello/1` dengan map `fred`:

```elixir
# call with entire map
...> Greeter1.hello(fred)
"Hello, Fred"
```

What happens when we call the function with a map that _doesn't_ contain the `:name` key?

```elixir
# call without the key we need returns an error
...> Greeter1.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter1.hello/1

    The following arguments were given to Greeter1.hello/1:

        # 1
        %{age: "95", favorite_color: "Taupe"}

    iex:12: Greeter1.hello/1

```

Alasan perilaku ini adalah karena Elixir mencocokkan pola argumen yang digunakan saat memanggil suatu fungsi dengan aritas (jumlah argumen) yang digunakan saat fungsi tersebut didefinisikan.

Mari kita pikirkan bagaimana tampilan data saat tiba di `Greeter1.hello/1`:

```Elixir
# incoming map
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"
...> }
```

`Greeter1.hello/1` mengharapkan argumen seperti ini:

```elixir
%{name: person_name}
```

Dalam `Greeter1.hello/1`, peta yang kita berikan (`fred`) dievaluasi terhadap argumen kita (`%{name: person_name}`):

```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Fungsi tersebut menemukan bahwa ada kunci yang sesuai dengan `name` dalam peta yang masuk.
Kita menemukan kecocokan! Dan sebagai hasil dari kecocokan yang berhasil ini, nilai kunci `:name` dalam peta di sebelah kanan (yaitu peta `fred`) terikat pada variabel di sebelah kiri (`person_name`).

Sekarang, bagaimana jika kita masih ingin menetapkan nama Fred ke `person_name` tetapi kita JUGA ingin mempertahankan kesadaran akan seluruh peta person? Katakanlah kita ingin `IO.inspect(fred)` setelah kita menyapa mereka.
Pada titik ini, karena kita hanya mencocokkan pola kunci `:name` dari peta kita, sehingga hanya mengikat nilai kunci tersebut ke sebuah variabel, fungsi tersebut tidak mengetahui sisa informasi tentang Fred.

Untuk mempertahankannya, kita perlu menetapkan seluruh peta tersebut ke variabelnya sendiri agar kita dapat menggunakannya.

Mari kita mulai fungsi baru:

```elixir
defmodule Greeter2 do
  def hello(%{name: person_name} = person) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

Ingatlah bahwa Elixir akan mencocokkan pola argumen saat argumen tersebut masuk.
Oleh karena itu, dalam kasus ini, setiap sisi akan mencocokkan pola dengan argumen yang masuk dan mengikat ke apa pun yang cocok dengannya.
Mari kita mulai dari sisi kanan terlebih dahulu:

```elixir
person = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Now, `person` has been evaluated and bound to the entire fred-map.
We move on to the next pattern-match:

```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Ini sama dengan fungsi `Greeter1` asli kita di mana kita mencocokkan pola peta dan hanya mempertahankan nama Fred.
Yang telah kita capai adalah dua variabel yang dapat kita gunakan, bukan hanya satu:

1. `person`, referring to `%{name: "Fred", age: "95", favorite_color: "Taupe"}`
2. `person_name`, referring to `"Fred"`

Jadi sekarang ketika kita memanggil `Greeter2.hello/1`, kita dapat menggunakan semua informasi Fred:

```elixir
# call with entire person
...> Greeter2.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}
# call with only the name key
...> Greeter2.hello(%{name: "Fred"})
"Hello, Fred"
%{name: "Fred"}
# call without the name key
...> Greeter2.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter2.hello/1

    The following arguments were given to Greeter2.hello/1:

        # 1
        %{age: "95", favorite_color: "Taupe"}

    iex:15: Greeter2.hello/1
```

Jadi, kita telah melihat bahwa Elixir melakukan pencocokan pola pada beberapa kedalaman karena setiap argumen dicocokkan dengan data yang masuk secara independen, sehingga kita memiliki variabel untuk memanggilnya di dalam fungsi kita.

Jika kita menukar urutan `%{name: person_name}` dan `person` dalam daftar, kita akan mendapatkan hasil yang sama karena masing-masing cocok dengan `fred` secara terpisah.

Kita tukar variabel dan petanya:

```elixir
defmodule Greeter3 do
  def hello(person = %{name: person_name}) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

Dan panggil dengan data yang sama yang kita gunakan di `Greeter2.hello/1`:

```elixir
# call with same old Fred
...> Greeter3.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}
```

Ingatlah bahwa meskipun terlihat seperti `%{name: person_name} = person` mencocokkan pola `%{name: person_name}` dengan variabel `person`, sebenarnya masing-masing mencocokkan pola dengan argumen yang diberikan.

**Ringkasan:** Fungsi mencocokkan pola data yang diberikan ke setiap argumennya secara independen.
Kita dapat menggunakan ini untuk mengikat nilai ke variabel terpisah di dalam fungsi.

### Fungsi privat

Ketika kita tidak ingin modul lain mengakses fungsi tertentu, kita dapat membuat fungsi tersebut bersifat privat.
Fungsi privat hanya dapat dipanggil dari dalam modulnya sendiri.
Kita mendefinisikannya dengan `defp`:

```elixir
defmodule Greeter do
  def hello(name), do: phrase() <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### Penjaga

Kita telah membahas secara singkat tentang **klausa penjaga** dalam pelajaran [Struktur Kontrol](/id/lessons/basics/control_structures), sekarang kita akan melihat bagaimana menerapkannya pada fungsi bernama.
Setelah Elixir mencocokkan sebuah fungsi, semua klausa Penjaga yang ada akan diuji.

Dalam contoh berikut, kita memiliki dua fungsi dengan penanda yang sama, kita mengandalkan penjaga untuk menentukan fungsi mana yang akan digunakan berdasarkan tipe argumennya:

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names = Enum.join(names, ", ")
    
    hello(names)
  end

  def hello(name) when is_binary(name) do
    phrase() <> name
  end

  defp phrase, do: "Hello, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"
```

### Default arguments

Jika kita menginginkan nilai default untuk suatu argumen, kita menggunakan sintaks `argumen \\ nilai`:

```elixir
defmodule Greeter do
  def hello(name, language_code \\ "en") do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello("Sean", "en")
"Hello, Sean"

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.hello("Sean", "es")
"Hola, Sean"
```

Ketika kita menggabungkan contoh klausa penjaga kita dengan argumen default, kita akan menemui masalah.
Mari kita lihat seperti apa masalah itu:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en") when is_list(names) do
    names = Enum.join(names, ", ")
    
    hello(names, language_code)
  end

  def hello(name, language_code \\ "en") when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) iex:8: def hello/2 defines defaults multiple times. Elixir allows defaults to be declared once per definition.
Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b \\ :default) do ... end

one should write:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end
```

Elixir tidak suka dengan argumen default dalam beberapa fungsi yang tercocok rangkap (multiple matching), hal itu bisa membingungkan.
Untuk mengatasi hal ini, kita menambahkan sebuah kepala fungsi (function head) dengan argumen default kita:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en")

  def hello(names, language_code) when is_list(names) do
    comma_separated_names = Enum.join(names, ", ")

    hello(comma_separated_names, language_code)
  end

  def hello(name, language_code) when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "es"
"Hola, Sean, Steve"
```
