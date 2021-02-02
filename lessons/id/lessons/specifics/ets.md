%{
  version: "0.9.1",
  title: "Erlang Term Storage (ETS)",
  excerpt: """
  Erlang Term Storage, biasa disebut ETS, adalah sebuah engine penyimpanan yang powerful yang sudah termasuk dalam OTP dan tersedia untuk digunakan di Elixir.  Dalam pelajaran ini kita akan melihat bagaimana mengakses ETS dan bagaimana ETS bisa digunakan dalam aplikasi kita.
  """
}
---

## Sekilas

ETS adalah sebuah fasilitas penyimpanan dalam memori yang kokoh (robust) untuk object Erlang dan Elixir yang sudah disertakan.  ETS sanggup menyimpan sejumlah sangat besar data dan menawarkan akses data dengan waktu yang konstan.

Tabel di ETS dibuat dan dimiliki oleh proses individual.  Ketika proses pemiliknya berhenti, tabel-tabelnya dihapus.  Secara default ETS dibatasi 1400 tabel per node.

## Membuat Tabel

Tabel dibuat dengan `new/2`, yang menerima nama tabel, sejumlah opsi, dan mengembalikan identifier tabel yang bisa kita gunakan dalam operasi-operasi berikutnya.

Untuk contoh kita, kita akan membuat sebuah tabel untuk menyimpan dan mencari user berdasar nickname:

```elixir
iex> table = :ets.new(:user_lookup, [:set, :protected])
8212
```

Sangat mirip GenServer, ada cara untuk mengakses tabel ETS dengan nama dan bukannya identifier.  Untuk melakukan hal ini kita perlu menyertakan opsi `:named_table`.  Kemudian kita bisa mengakses tabel kita langsung dengan nama:

```elixir
iex> :ets.new(:user_lookup, [:set, :protected, :named_table])
:user_lookup
```

### Tipe-tipe Tabel

Ada empat tipe tabel tersedia di ETS:

+ `set` — Ini adalah tipe tabel yang default.  Satu value per key.  Key adalah unik.
+ `ordered_set` — Mirip dengan `set` tetapi terurut berdasarkan term Erlang/Elixir.  Penting dicatat bahwa perbandingan key dalam `ordered_set` berbeda dengan biasanya.  Key tidak harus persis sama selama perbandingannya setara.  1 dan 1.0 dianggap setara (equal).
+ `bag` — Banyak object per key tetapi hanya satu instans dari masing-masing object per key.
+ `duplicate_bag` — Banyak object per key, bisa duplikat.

### Access Control

Access control di ETS adalah mirip dengan di dalam modul:

+ `public` — Pembacaan/Penulisan (Read/Write) tersedia untuk semua process.
+ `protected` — Read tersedia untuk semua process.  Write hanya boleh untuk process yang memiliki ETS tersebut (owner process).  Inilah access control yang default.
+ `private` — Read/Write terbatas pada owner process.

## Menambahkan Data

ETS tidak punya schema.  Satu-satunya batasan adalah data harus disimpan sebagai tuple yang mana elemen pertamanya adalah key.  Untuk menambahkan data baru kita bisa gunakan `insert/2`:

```elixir
iex> :ets.insert(:user_lookup, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
true
```

Ketika kita gunakan `insert/2` dengan sebuah `set` atau `ordered_set` data yang sudah ada akan ditimpa.  Untuk menghindari hal ini ada `insert_new/2` yang mengembalikan `false` jika key sudah ada:

```elixir
iex> :ets.insert_new(:user_lookup, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
false
iex> :ets.insert_new(:user_lookup, {"3100", "", ["Elixir", "Ruby", "JavaScript"]})
true
```

## Mengambil Data

ETS memberikan kita beberapa cara yang mudah dan fleksibel untuk mengambil data.  Kita akan melihat cara mengambil data dengan key dan lewat berbagai ragam pencocokan pola.

Metode pengambilan yang paling efisien, dan ideal, adalah key lookup.  Walaupun berguna, pencocokan (matching) melakukan iterasi di sepanjang tabel dan mesti tidak sering digunakan khususnya untuk data set yang sangat besar.

### Key Lookup

Menggunakan sebuah key, kita bisa gunakan `lookup/2` untuk mengambil semua record dengan key tersebut:

```elixir
iex> :ets.lookup(:user_lookup, "doomspork")
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

### Pencocokan Sederhana

ETS dibuat untuk Erlang, sehingga perhatikan bahwa variabel pencocokan bisa terasa _sedikit_ aneh.

Untuk menspesifikasikan sebuah variabel di pencocokan kita, kita gunakan atom `:"$1"`, `:"$2"`, `:"$3"`, dan seterusnya.  Nomor variabel merefleksikan posisi result dan bukan posisi match.  Untuk value yang kita tidak perhatikan, kita gunakan variabel `:_`.

Value juga bisa digunakan dalam pencocokan, tetapi hanya variable yang akan dikembalikan sebagai bagian dari result kita.  Mari kita coba melihat bagaimana kerjanya:

```elixir
iex> :ets.match(:user_lookup, {:"$1", "Sean", :_})
[["doomspork"]]
```

Mari lihat sebuah contoh lain untuk melihat bagaimana variabel mempengaruhi urutan list hasilnya:

```elixir
iex> :ets.match(:user_lookup, {:"$99", :"$1", :"$3"})
[["Sean", ["Elixir", "Ruby", "Java"], "doomspork"],
 ["", ["Elixir", "Ruby", "JavaScript"], "3100"]]
```

Bagaimana kalau kita inginkan object aslinya, bukan sebuah list?  Kita bisa gunakan `match_object/2`, yang apapun variabelnya mengembalikan object kita secara keseluruhan:

```elixir
iex> :ets.match_object(:user_lookup, {:"$1", :_, :"$3"})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]

iex> :ets.match_object(:user_lookup, {:_, "Sean", :_})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

### Lookup Tingkat Lanjut

Kita sudah pelajari tentang kasus pencocokan sederhana, tetapi bagaimana kalau kita ingin sesuatu yang lebih seperti sebuah query SQL?  Untungnya ada sintaks yang lebih bagus.  Untuk mencari data kita dengan `select/2` kita perlu membuat sebuah list dari tuple dengan arity 3.  Tuple ini merepresentasikan pola kita, nol guard atau lebih, dan format value yang dikembalikan.

Variabel pencocokan kita dan dua variabel baru, `:"$$"` dan `:"$_"`, bisa digunakan untuk mengkonstruksi value yang dikembalikan.  Variabel-variabel baru ini adalah pintasan (shortcut) untuk format hasilnya; `:"$$"` menghasilkan kembalian sebagai list dan `:"$_"` menghasilkan object data aslinya.

Mari kita ambil salah satu contoh `match/2` kita sebelumnya dan mengubahnya menjadi `select/2`:

```elixir
iex> :ets.match_object(:user_lookup, {:"$1", :_, :"$3"})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]

{% raw %}iex> :ets.select(:user_lookup, [{{:"$1", :_, :"$3"}, [], [:"$_"]}]){% endraw %}
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"spork", 30, ["ruby", "elixir"]}]
```

Walaupun `select/2` memungkinkan pengendalian yang lebih detail terhadap apa dan bagaimana kita mengambil record, sintaksnya lumayan kurang ramah.  Untuk menangani hal ini modul ETS menyertakan `fun2ms/1`, yang mengubah fungsi menjadi match_spec.  Dengan `fun2ms/1` kita bisa membuat query menggunakan sintaks fungsi yang sudah familiar.

Mari kita gunakan `fun2ms/1` dan `select/2` untuk menemukan semua username dengan 2 bahasa atau lebih:

```elixir
iex> fun = :ets.fun2ms(fn {username, _, langs} when length(langs) > 2 -> username end)
{% raw %}[{{:"$1", :_, :"$2"}, [{:>, {:length, :"$2"}, 2}], [:"$1"]}]{% endraw %}

iex> :ets.select(:user_lookup, fun)
["doomspork", "3100"]
```

Ingin belajar lebih jauh tentang match specification (spesifikasi pencocokan)?  Lihatlah dokumentasi resmi Erlang untuk [match_spec](http://www.erlang.org/doc/apps/erts/match_spec.html).

## Menghapus Data

### Menghapus Record

Menghapus term adalah semudah `insert/2` dan `lookup/2`.  Dengan `delete/2` kita hanya butuhkan tabel kita dan key nya.  Fungsi ini menghapus key dan value nya:

```elixir
iex> :ets.delete(:user_lookup, "doomspork")
true
```

### Mengapus Tabel

Tabel ETS tidak punya pembersihan sampah (garbage collection) kecuali jika proses parent dihentikan.  Terkadang kita perlu menghapus tabel tanpa menghentikan proses pemiliknya.  Untuk ini kita bisa gunakan `delete/1`:

```elixir
iex> :ets.delete(:user_lookup)
true
```

## Contoh Penggunaan ETS

Dengan apa yang sudah kita pelajari, mari satukan semuanya dan membuat sebuah cache sederhana untuk operasi-operasi yang mahal.  Kita akan mengimplementasikan sebuah fungsi `get/4` untuk mengambil sebuah modul, fungsi, argumen, dan opsi.  Untuk sekarang ini satu-satunya opsi yang akan kita perhatikan adalah `:ttl`.

Untuk contoh ini kita akan menganggap tabel ETS sudah dibuat sebagai bagian dari proses lain, seperti sebuah supervisor:

```elixir
defmodule SimpleCache do
  @moduledoc """
  A simple ETS based cache for expensive function calls.
  """

  @doc """
  Retrieve a cached value or apply the given function caching and returning
  the result.
  """
  def get(mod, fun, args, opts \\ []) do
    case lookup(mod, fun, args) do
      nil ->
        ttl = Keyword.get(opts, :ttl, 3600)
        cache_apply(mod, fun, args, ttl)

      result ->
        result
    end
  end

  @doc """
  Lookup a cached result and check the freshness
  """
  defp lookup(mod, fun, args) do
    case :ets.lookup(:simple_cache, [mod, fun, args]) do
      [result | _] -> check_freshness(result)
      [] -> nil
    end
  end

  @doc """
  Compare the result expiration against the current system time.
  """
  defp check_freshness({mfa, result, expiration}) do
    cond do
      expiration > :os.system_time(:seconds) -> result
      :else -> nil
    end
  end

  @doc """
  Apply the function, calculate expiration, and cache the result.
  """
  defp cache_apply(mod, fun, args, ttl) do
    result = apply(mod, fun, args)
    expiration = :os.system_time(:seconds) + ttl
    :ets.insert(:simple_cache, {[mod, fun, args], result, expiration})
    result
  end
end
```

Untuk mendemonstrasikan cache tersebut kita akan gunakan sebuah fungsi yang mengembalikan waktu sistem (system time) dan TTL 10 detik.  Sebagaimana akan anda lihat di contoh di bawah ini, kita mendapat hasil yang disimpan di cache sampai value tersebut kedaluarsa:

```elixir
defmodule ExampleApp do
  def test do
    :os.system(:seconds)
  end
end

iex> :ets.new(:simple_cache, [:named_table])
:simple_cache
iex> ExampleApp.test
1451089115
iex> SimpleCache.get(SimpleCache, :test, [], ttl: 10)
1451089119
iex> ExampleApp.test
1451089123
iex> ExampleApp.test
1451089127
iex> SimpleCache.get(SimpleCache, :test, [], ttl: 10)
1451089119
```

Setelah 10 detik kalau kita coba lagi kita mestinya menerima hasil yang baru:

```elixir
iex> ExampleApp.test
1451089131
iex> SimpleCache.get(SimpleCache, :test, [], ttl: 10)
1451089134
```

Sebagaimana yang anda lihat kita bisa mengimplementasikan cache yang cepat dan skalabel tanpa dependensi eksternal dan ini hanya salah satu dari banyak kegunaan ETS.

## ETS Berbasis Disk

Kita sekarang tahu bahwa ETS adalah untuk penyimpanan dalam memori, tetapi bagaimana kalau kita butuh penyimpanan berbasis disk? Untuk itu kita punya Disk Based ETS, atau DETS.  API ETS dan DETS bisa saling dipertukarkan kecuali cara pembuatan tabel. DETS bergantung pada `open_file/2` dan tidak butuh opsi `:named_table`:

```elixir
iex> {:ok, table} = :dets.open_file(:disk_storage, [type: :set])
{:ok, :disk_storage}
iex> :dets.insert_new(table, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
true
iex> select_all = :ets.fun2ms(&(&1))
[{:"$1", [], [:"$1"]}]
iex> :dets.select(table, select_all)
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

Jika anda keluar dari `iex` dan melihat di direktori lokal, anda akan melihat sebuah file baru `disk_storage`:

```shell
$ ls | grep -c disk_storage
1
```

Satu hal lagi yang perlu dicatat adalah bahwa DETS tidak mendukung `ordered_set` seperti ETS, hanya `set`, `bag`, dan `duplicate_bag`.
