%{
  version: "1.2.0",
  title: "Struktur Kendali",
  excerpt: """
  Dalam pelajaran ini kita akan melihat struktur kendali yang tersedia di Elixir.
  """
}
---

## if

Besar kemungkinan kamu sudah bertemu `if/2` sebelumnya. Di Elixir, cara kerjanya hampir sama, tetapi `if` didefinisikan sebagai makro, bukan sebagai konstruksi bahasa. Kamu dapat menemukan implementasinya di [modul Kernel](https://hexdocs.pm/elixir/Kernel.html).

Perlu dicatat bahwa di Elixir, satu-satunya nilai yang bernilai false adalah `nil` dan boolean `false`.

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

## case

Jika perlu mencocokkan dengan beberapa pola, kita dapat menggunakan `case/2`:

```elixir
iex> status = {:ok, "Hello World"}
{:ok, "Hello World"}
iex> case status do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```

Variabel `_` merupakan hal penting yang harus disertakan dalam pernyataan `case/2`. Tanpa variabel ini, jika tidak ditemukan kecocokan, akan muncul kesalahan:

```elixir
iex> result = :even
:even
iex> case result do
...>   :odd -> "Odd"
...> end
** (CaseClauseError) no case clause matching: :even

iex> case :even do
...>   :odd -> "Odd"
...>   _ -> "Not Odd"
...> end
"Not Odd"
```

Anggaplah `_` sebagai `else` yang akan cocok dengan "semua yang lain".

Karena `case/2` bergantung pada pencocokan pola, semua aturan dan batasan yang sama berlaku.
Jika kamu ingin mencocokkan nilai terhadap variabel yang sudah ada, kamu harus menggunakan operator pin `^/1`:

```elixir
iex> pie = 3.14
 3.14
iex> case "cherry pie" do
...>   ^pie -> "Not so tasty"
...>   pie -> "I bet #{pie} is tasty"
...> end
"I bet cherry pie is tasty"
```

Fitur menarik lainnya dari `case/2` adalah dukungannya terhadap klausa penjaga (guard clause):

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

Cek dokumentasi resmi untuk [Ekspresi yang diizinkan dalam klausa penjaga](https://hexdocs.pm/elixir/guards.html#list-of-allowed-expressions).

## cond

Ketika kita perlu mengevaluasi kondisi alih-alih mencocokkan nilai, kita dapat menggunakan `cond`; ini seperti `else if` atau `elsif` di bahasa-bahasa lain:

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

Seperti `case/2`, `cond/1` akan menimbulkan kesalahan jika tidak ada kecocokan.
Untuk mengatasi hal ini, kita dapat menambahkan kondisi yang selalu bernilai `true`:

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```

## with

Konstruksi `with/1` berguna ketika kamu mungkin menggunakan sebuah pernyataan `case/2` bertingkat atau situasi yang tidak dapat di-pipe (`|>`) dengan mudah. Ekspresi `with/1` terdiri dari kata kunci, generator, dan akhirnya sebuah ekspresi.

Kita akan membahas generator lebih lanjut dalam pelajaran [Pemahaman Daftar](/id/lessons/basics/comprehensions), tapi untuk saat ini kita hanya perlu tahu bahwa generator menggunakan [pencocokan pola](/id/lessons/basics/pattern_matching) untuk membandingkan sisi kanan dari `<-` terhadap sisi kiri.

Kita akan mulai dengan contoh sederhana dari `with/1` dan kemudian melihat lebih jauh:

```elixir
iex> user = %{first: "Sean", last: "Callan"}
%{first: "Sean", last: "Callan"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
"Callan, Sean"
```

Jika salah satu ekspresi gagal menemukan kecocokan, nilai yang tidak cocok akan dikembalikan:

```elixir
iex> user = %{first: "doomspork"}
%{first: "doomspork"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
:error
```

Sekarang mari lihat contoh yang lebih besar tanpa `with/1` dan kemudian lihat bagaimana kita dapat merefaktornya kembali:

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

Dengan `with/1` kode menjadi lebih mudah dipahami dan lebih ringkas:

```elixir
with {:ok, user} <- Repo.insert(changeset),
     {:ok, token, full_claims} <- Guardian.encode_and_sign(user, :token, claims) do
  important_stuff(token, full_claims)
end
```

Sejak Elixir 1.3, pernyataan `with/1` mendukung `else`:

```elixir
iex> import Integer
Integer
iex> m = %{a: 1, c: 3}
%{a: 1, c: 3}
iex> a =
...>   with {:ok, number} <- Map.fetch(m, :a),
...>     true <- is_even(number) do
...>       IO.puts "#{number} divided by 2 is #{div(number, 2)}"
...>       :even
...>   else
...>     :error ->
...>       IO.puts("We don't have this item in map")
...>       :error
...> 
...>     _ ->
...>       IO.puts("It is odd")
...>       :odd
...>   end
It is odd
:odd
```

`else` membantu menangani kesalahan dengan menyediakan pencocokan pola seperti `case`. Ekspresi pertama yang gagal dicocokkan akan diteruskan ke blok `else`.
