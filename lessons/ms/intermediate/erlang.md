%{
  version: "0.9.1",
  title: "Kesalingbolehgunaan (Interoperability) Dengan Erlang",
  excerpt: """
  Salah satu faedah tambahan daripada membina di atas Erlang VM (BEAM) ialah lambakan pustaka sedia ada yang tersedia untuk kita.  Kesalingbolehgunaan(Interoperability) mengupayakan kita untuk menuilkan(leverage) pustaka-pustaka tersebut dan pustaka rasmi Erlang daripada kod Elixir kita.  Di dalam pelajaran ini kita akan melihat bagaimana untuk mencapai kefungsian di dalam pustaka rasmi dan juga pustaka-pustaka pihak ketiga Erlang.
  """
}
---

## Pustaka Rasmi

Pustaka rasmi Erlang yang besar boleh dicapai dari mana-mana kod Elixir di dalam aplikasi kita.  Modul-modul Erlang diwakilkan oleh atom-atom berhuruf kecil seperti `:os` dan `:timer`.

Mari kita gunakan `:timer.tc` untuk mengukur masa yang digunakan untuk menjalankan satu fungsi:

```elixir
defmodule Example do
  def timed(fun, args) do
    {time, result} = :timer.tc(fun, args)
    IO.puts("Time: #{time} μs")
    IO.puts("Result: #{result}")
  end
end

iex> Example.timed(fn (n) -> (n * n) * n end, [100])
Time: 8 μs
Result: 1000000
```

Sila lihat [Erlang Reference Manual](http://erlang.org/doc/apps/stdlib/) untuk mendapatkan senarai lengkap modul-modul yang disediakan.

## Pakej Erlang

Di dalam pelajaran lepas kita telah melihat Mix dan cara-cara menguruskan komponen-komponen sokongan(dependencies).  Pustaka Erlang juga boleh diuruskan dengan cara yang sama.  Jika pustaka Erlang yang diperlukan itu masih belum dimasukkan ke dalam [Hex](https://hex.pm), anda boleh membuat rujukan terus ke repositori git:

```elixir
def deps do
  [{:png, github: "yuce/png"}]
end
```

Sekarang kita boleh mencapai pustaka Erlang tersebut:

```elixir
png =
  :png.create(%{:size => {30, 30}, :mode => {:indexed, 8}, :file => file, :palette => palette})
```

## Perbezaan Nyata

Oleh kerana sekarang kita telah tahu bagaimana untuk menggunakan pustaka Elixir kita patut melihat beberapa isu yang didatangkan oleh kesalingbolehgunaan dengan Erlang.

### Atom

Atom-atom Erlang nampak lebih kurang sama dengan atom Elixir, cuma tanpa tanda titik bertindih (`:`).  Mereka diwakili oleh string huruf kecil dan garis bawah.

Elixir:

```elixir
:example
```

Erlang:

```erlang
example.
```

### String

Apabila kita bercakap mengenai string di dalam Elixir, kita merujuk kepada 'UTF-8 encoded binaries'.  Di dalam Erlang, string masih ditandakan menggunakan tanda ungkapan berganda ("") tetapi merujuk kepada list aksara.

Elixir:

```elixir
iex> is_list('Example')
true
iex> is_list("Example")
false
iex> is_binary("Example")
true
iex> <<"Example">> === "Example"
true
```

Erlang:

```erlang
1> is_list('Example').
false
2> is_list("Example").
true
3> is_binary("Example").
false
4> is_binary(<<"Example">>).
true
```

Penting untuk diperhatikan bahawa banyak pustaka Erlang yang lama mungkin tidak menyokong 'binary' jadi kita perlu menukarkan string Elixir kepada list aksara.  Nasib baik ianya mudah untuk dilakukan dengan menggunakan fungsi `to_charlist/1`:

```elixir
iex> :string.words("Hello World")
** (FunctionClauseError) no function clause matching in :string.strip_left/2

    The following arguments were given to :string.strip_left/2:

        # 1
        "Hello World"

        # 2
        32

    (stdlib) string.erl:1661: :string.strip_left/2
    (stdlib) string.erl:1659: :string.strip/3
    (stdlib) string.erl:1597: :string.words/2

iex> "Hello World" |> to_charlist |> :string.words
2
```

### Pembolehubah

Elixir:

```elixir
iex> x = 10
10

iex> x1 = x + 10
20
```

Erlang:

```erlang
1> X = 10.
10

2> X1 = X + 1.
11
```

Itu sahaja!  Menuilkan kelebihan Erlang dari dalam aplikasi Elixir adalah cukup mudah dan secara tidak lansung menggandakan jumlah pustaka yang tersedia untuk kita.
