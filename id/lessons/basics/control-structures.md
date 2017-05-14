---
version: 0.9.0
layout: page
title: Struktur Kendali
category: basics
order: 5
lang: id
---

Dalam pelajaran ini kita akan melihat struktur kendali yang tersedia untuk kita di Elixir.

{% include toc.html %}

## `if` dan `unless`

Besar kemungkinan anda sudah bertemu `if/2` sebelumnya, dan jika sudah terbiasa dengan Ruby anda juga sudah familiar dengan `unless/2`.  Dalam Elixir keduanya berfungsi cukup mirip tetapi keduanya didefinisikan sebagai macro, bukannya fasilitas bahasa; Anda dapat melihat implementasinya di [modul Kernel](https://hexdocs.pm/elixir/Kernel.html).

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

Jika diperlukan untuk mencocokkan pada banyak pola kita dapat menggunakan `case`:

```elixir
iex> case {:ok, "Hello World"} do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```

Variabel `_` adalah bagian yang penting dalam pernyataan `case`. Tanpa itu kegagalan menemukan kecocokan akan menghasilkan error:

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
Karena `case` bergantung pada pencocokan pola, semua aturan dan batasan yang sama berlaku.  Jika anda berniat untuk mencocokkan terhadap variabel yang sudah ada isinya anda harus menggunakan operator pin `^`:

```elixir
iex> pie = 3.14 
 3.14
iex> case "cherry pie" do
...>   ^pie -> "Not so tasty"
...>   pie -> "I bet #{pie} is tasty"
...> end
"I bet cherry pie is tasty"
```

Satu lagi fitur `case` yang menarik adalah dukungannya terhadap klausa penjaga (guard clause):

_Contoh ini diambil langsung dari panduan resmi [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#case) Elixir._

```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "Will match"
...>   _ ->
...>     "Won't match"
...> end
"Will match"
```

Ceklah dokumentasi resmi untuk [Expression yang diijinkan dalam guard clause](http://elixir-lang.org/getting-started/case-cond-and-if.html#expressions-in-guard-clauses).

## `cond`

Ketika kita perlu mencocokkan kondisi, dan bukannya value, kita dapat menggunakan `cond`; ini seperti `else if` atau `elsif` di bahasa-bahasa lain:

_Contoh ini diambil langsung dari panduan resmi [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#cond) Elixir._

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

Seperti `case`, `cond` akan menghasilkan error kalau tidak ada kecocokan.  Untuk menangani ini, kita dapat mendefinisikan sebuah kondisi untuk `true`:

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```

## `with`

Bentuk spesial `with` berguna ketika anda ingin menggunakan sebuah pernyataan `case` bertingkat atau situasi yang tidak dapat di-pipe dengan mudah. Ekspresi `with` terdiri dari keyword, generator, dan akhirnya sebuah expression.

Kita akan diskusikan generator lebih jauh di pelajaran List Comprehension tapi sementara ini kita hanya perlu mengetahui bahwa mereka menggunakan pencocokan pola untuk membandingkant sisi kanan dari `<-` terhadap sisi kiri.

Kita akan mulai dengan contoh sederhana dari `with` dan kemudian melihat lebih jauh:

```elixir
iex> user = %{first: "Sean", last: "Callan"}
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

Sekarang mari lihat contoh yang lebih besar tanpa `with` dan kemudian melihat bagaimana kita bisa merefaktornya:

```elixir
case Repo.insert(changeset) do 
  {:ok, user} -> 
    case Guardian.encode_and_sign(resource, :token, claims) do
      {:ok, jwt, full_claims} ->
        important_stuff(jwt, full_claims)
      error -> error
    end
  error -> error
end
```

Ketika kita menggunakan `with` kita dapati code yang mudah dipahami dan menggunakan jumlah line yang lebih sedikit:

```elixir
with {:ok, user} <- Repo.insert(changeset),
     {:ok, jwt, full_claims} <- Guardian.encode_and_sign(user, :token),
     do: important_stuff(jwt, full_claims)
```
