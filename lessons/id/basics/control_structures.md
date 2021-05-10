%{
  version: "1.1.1",
  title: "Struktur Kendali",
  excerpt: """
  Dalam pelajaran ini kita akan melihat struktur kendali yang tersedia untuk kita di Elixir.
  """
}
---

## `if` dan `unless`

Besar kemungkinan anda sudah bertemu `if/2` sebelumnya, dan jika sudah terbiasa dengan Ruby anda juga sudah familiar dengan `unless/2`. Dalam Elixir keduanya berfungsi cukup mirip tetapi keduanya didefinisikan sebagai macro, bukannya fasilitas bahasa; Anda dapat melihat implementasinya di [modul Kernel](https://hexdocs.pm/elixir/Kernel.html).

Harus dicatat bahwa di Elixir, nilai yang dianggap false (falsey value) hanyalah `nil` dan boolean `false`.

```elixir
iex> if String.valid?("Hello") do
...>   "Valid string!"
...> else
...>   "Invalid string."
...> end
"Valid string!"

iex> if "a string value" do
...>   "Truthy"
...> end
"Truthy"
```

Menggunakan `unless/2` adalah seperti `if/2` hanya saja bekerja pada yang false:

```elixir
iex> unless is_integer("hello") do
...>   "Not an Int"
...> end
"Not an Int"
```

## `case`

Jika diperlukan untuk mencocokkan pada banyak pola kita dapat menggunakan `case/2`:

```elixir
iex> case {:ok, "Hello World"} do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```

Variabel `_` adalah bagian yang penting dalam pernyataan `case/2`. Tanpa itu kegagalan menemukan kecocokan akan menghasilkan error:

```elixir
iex> case :even do
...>   :odd -> "Odd"
...> end
** (CaseClauseError) no case clause matching: :even

iex> case :even do
...>   :odd -> "Odd"
...>   _ -> "Not Odd"
...> end
"Not Odd"
```

Anggaplah `_` sebagai `else` yang akan cocok dengan "semua yang lain.
Karena `case/2` bergantung pada pencocokan pola, semua aturan dan batasan yang sama berlaku.  Jika anda berniat untuk mencocokkan terhadap variabel yang sudah ada isinya anda harus menggunakan operator pin `^/1`:

```elixir
iex> pie = 3.14
 3.14
iex> case "cherry pie" do
...>   ^pie -> "Not so tasty"
...>   pie -> "I bet #{pie} is tasty"
...> end
"I bet cherry pie is tasty"
```

Satu lagi fitur `case/2` yang menarik adalah dukungannya terhadap klausa penjaga (guard clause):

_Contoh ini diambil langsung dari panduan resmi [Awal Mulai](http://elixir-lang.org/getting-started/case-cond-and-if.html#case) Elixir._

```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "Will match"
...>   _ ->
...>     "Won't match"
...> end
"Will match"
```

Ceklah dokumentasi resmi untuk [Expression yang diijinkan dalam klausa penjaga](https://hexdocs.pm/elixir/guards.html#list-of-allowed-expressions).

## `cond`

Ketika kita perlu mencocokkan kondisi, dan bukannya value, kita dapat menggunakan `cond`; ini seperti `else if` atau `elsif` di bahasa-bahasa lain:

_Contoh ini diambil langsung dari panduan resmi [Awal Mulai](http://elixir-lang.org/getting-started/case-cond-and-if.html#cond) Elixir._

```elixir
iex> cond do
...>   2 + 2 == 5 ->
...>     "This will not be true"
...>   2 * 2 == 3 ->
...>     "Nor this"
...>   1 + 1 == 2 ->
...>     "But this will"
...> end
"But this will"
```

Seperti `case/2`, `cond/1` akan menghasilkan error kalau tidak ada kecocokan.  Untuk menangani ini, kita dapat mendefinisikan sebuah kondisi untuk `true`:

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```

## `with`

Bentuk spesial `with/1` berguna ketika anda ingin menggunakan sebuah pernyataan `case/2` bertingkat atau situasi yang tidak dapat di-pipe dengan mudah. Ekspresi `with/1` terdiri dari keyword, generator, dan akhirnya sebuah expression.

Kita akan diskusikan generator lebih jauh di [Daftar Pelajaran Pemahaman](../comprehensions/), tapi sementara ini kita hanya perlu mengetahui bahwa mereka menggunakan [pencocokan pola](../pattern-matching/) untuk membandingkan sisi kanan dari `<-` terhadap sisi kiri.

Kita akan mulai dengan contoh sederhana dari `with/1` dan kemudian melihat lebih jauh:

```elixir
iex> user = %{first: "Sean", last: "Callan"}
%{first: "Sean", last: "Callan"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
"Callan, Sean"
```

Dalam kondisi dimana sebuah expression gagal mendapati kecocokan, value yang tidak cocok akan dikembalikan:

```elixir
iex> user = %{first: "doomspork"}
%{first: "doomspork"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
:error
```

Sekarang mari lihat contoh yang lebih besar tanpa `with/1` dan kemudian melihat bagaimana kita bisa merefaktornya:

```elixir
case Repo.insert(changeset) do
  {:ok, user} ->
    case Guardian.encode_and_sign(user, :token, claims) do
      {:ok, token, full_claims} ->
        important_stuff(token, full_claims)

      error ->
        error
    end

  error ->
    error
end
```

Ketika kita menggunakan `with/1` kita dapati code yang mudah dipahami dan menggunakan jumlah line yang lebih sedikit:

```elixir
with {:ok, user} <- Repo.insert(changeset),
     {:ok, token, full_claims} <- Guardian.encode_and_sign(user, :token, claims) do
  important_stuff(token, full_claims)
end
```


Seperti pada Elixir 1.3, `with/1` mendukung pernyataan `else`:

```elixir
import Integer

m = %{a: 1, c: 3}

a =
  with {:ok, number} <- Map.fetch(m, :a),
       true <- is_even(number) do
    IO.puts("#{number} divided by 2 is #{div(number, 2)}")
    :even
  else
    :error ->
      IO.puts("We don't have this item in map")
      :error

    _ ->
      IO.puts("It is odd")
      :odd
  end
```

Ini membantu menangani kesalahan dengan menyediakan pencocokan pola `case` seperti di dalamnya. Nilai yang dilewatkan adalah ekspresi non-matching pertama.
