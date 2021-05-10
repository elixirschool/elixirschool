%{
  version: "0.9.0",
  title: "Struktur Kawalan",
  excerpt: """
  Dalam pelajaran ini kita akan melihat struktur kawalan yang dibekalkan oleh ELixir.
  """
}
---

## `if` dan `unless`

Kemungkinan besar anda telah menemui `if/2` sebelum ini, dan jika anda pernah menggunakan Ruby anda sudah biasa dengan `unless/2`.  Dalam Elixir mereka berfungsi lebih kurang sama tetapi mereka adalah ditetapkan sebagai makro, bukan komponen asas bahasa itu sendiri;  Anda akan menjumpai pelaksanaan mereka dalam [Kernel module](https://hexdocs.pm/elixir/Kernel.html).

Perlu diingat di dalam Elixir, hanya `nil` dan boolean `false` mempunyai nilai false.

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

Penggunaan `unless/2` adalah seperti `if/2` cuma ia berfungsi secara negatif:

```elixir
iex> unless is_integer("hello") do
...>   "Not an Int"
...> end
"Not an Int"
```

## `case`

Jika memerlukan pemadanan dengan pelbagai corak kita boleh gunakan `case`:

```elixir
iex> case {:ok, "Hello World"} do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```

Pembolehubah `_` itu adalah penambahan penting di dalam kenyataan `case`.  Jika tidak digunakan, sebarang padanan yang gagal akan menimbulkan ralat:

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

Anggapkan `_` sebagai `else` yang akan dipadankan dengan "yang lain-lain".
Oleh kerana `case` bergantung kepada pemadanan corak, semua undang-undang dan restriction adalah digunapakai.  Jika anda berhasrat untuk membuat padanan kepada pembolehubah sedia ada anda perlu menggunakan operator pin `^`:

```elixir
iex> pie = 3.14
3.14
iex> case "cherry pie" do
...>   ^pie -> "Not so tasty"
...>   pie -> "I bet #{pie} is tasty"
...> end
"I bet cherry pie is tasty"
```

Satu lagi ciri `case` ialah sokongan kepada klausa 'guard':

_Contoh ini diambil terus dari panduan rasmi Elixir [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#case)._

```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "Will match"
...>   _ ->
...>     "Won't match"
...> end
"Will match"
```

Lihat dokumen rasmi untuk [Kenyataan yang dibenarkan di dalam klausa 'guard'](https://hexdocs.pm/elixir/guards.html#list-of-allowed-expressions).

## `cond`

Jika kita perlu untuk memadankan keadaan, dan bukan nilai, kita boleh berpaling kepada `cond`; ini adalah sama dengan `else if` atau `elsif` dalam bahasa-bahasa lain:

_Contoh ini diambil terus dari panduan rasmi Elixir [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#cond)._

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

Seperti juga `case`, `cond` akan menimbulkan satu ralat jika tiada padanan.  Untuk mengatasi keadaan ini, kita boleh menetapkan satu padanan kepada `true`:
```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```
