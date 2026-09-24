%{
  version: "1.0.1",
  title: "Protokol",
  excerpt: """
  Di pelajaran ini kita akan mempelajari Protokol, apa itu, dan bagaimana kita menggunakannya di Elixir.
  """
}
---

## Apa Itu Protokol

Jadi, apa itu protokol?
Protokol adalah cara untuk mencapai polimorfisme di Elixir.
Salah satu hal sulit di Erlang adalah memperluas API yang ada untuk tipe yang baru didefinisikan.
Untuk menghindari hal ini di Elixir, fungsi dikirim secara dinamis berdasarkan tipe nilai.
Elixir hadir dengan sejumlah protokol bawaan, misalnya protokol `String.Chars` bertanggung jawab atas fungsi `to_string/1` yang telah kita lihat sebelumnya.
Mari kita lihat lebih dekat `to_string/1` dengan contoh singkat:

```elixir
iex> to_string(5)
"5"
iex> to_string(12.4)
"12.4"
iex> to_string("foo")
"foo"
```

Seperti yang Anda lihat, kita telah memanggil fungsi tersebut pada beberapa tipe dan menunjukkan bahwa fungsi tersebut bekerja pada semuanya.
Bagaimana jika kita memanggil `to_string/1` pada tuple (atau tipe apa pun yang belum mengimplementasikan `String.Chars`)?
Mari kita lihat:

```elixir
to_string({:foo})
** (Protocol.UndefinedError) protocol String.Chars not implemented for {:foo}
    (elixir) lib/string/chars.ex:3: String.Chars.impl_for!/1
    (elixir) lib/string/chars.ex:17: String.Chars.to_string/1
```

Seperti yang Anda lihat, kita mendapatkan kesalahan protokol karena tidak ada implementasi untuk tuple.
Di bagian selanjutnya, kita akan mengimplementasikan protokol `String.Chars` untuk tuple.

## Mengimplementasikan Protokol

Kita telah melihat bahwa `to_string/1` belum diimplementasikan untuk tuple, jadi mari kita tambahkan.
Untuk membuat implementasi, kita akan menggunakan `defimpl` dengan protokol kita, dan menyediakan opsi `:for`, serta tipe kita.
Mari kita lihat bagaimana tampilannya:

```elixir
defimpl String.Chars, for: Tuple do
  def to_string(tuple) do
    interior =
      tuple
      |> Tuple.to_list()
      |> Enum.map(&Kernel.to_string/1)
      |> Enum.join(", ")

    "{#{interior}}"
  end
end
```

Jika kita menyalin ini ke IEx, seharusnya sekarang kita dapat memanggil `to_string/1` pada sebuah tuple tanpa mendapatkan kesalahan:

```elixir
iex> to_string({3.14, "apple", :pie})
"{3.14, apple, pie}"
```

Kita tahu cara mengimplementasikan sebuah protokol, tetapi bagaimana cara kita mendefinisikan protokol baru?
Untuk contoh kita, kita akan mengimplementasikan `to_atom/1`.
Mari kita lihat bagaimana cara melakukannya dengan `defprotocol`:

```elixir
defprotocol AsAtom do
  def to_atom(data)
end

defimpl AsAtom, for: Atom do
  def to_atom(atom), do: atom
end

defimpl AsAtom, for: BitString do
  defdelegate to_atom(string), to: String
end

defimpl AsAtom, for: List do
  defdelegate to_atom(list), to: List
end

defimpl AsAtom, for: Map do
  def to_atom(map), do: List.first(Map.keys(map))
end
```

Di sini kita telah mendefinisikan protokol kita dan fungsi yang diharapkan, `to_atom/1`, beserta implementasi untuk beberapa tipe.
Sekarang setelah kita memiliki protokol kita, mari kita gunakan di IEx:

```elixir
iex> import AsAtom
AsAtom
iex> to_atom("string")
:string
iex> to_atom(:an_atom)
:an_atom
iex> to_atom([1, 2])
:"\x01\x02"
iex> to_atom(%{foo: "bar"})
:foo
```

Perlu dicatat bahwa meskipun di bawah struct terdapat Map, struct tersebut tidak memiliki implementasi protokol yang sama dengan Map.
Struktur tersebut tidak dapat dihitung (enumerable), sehingga tidak dapat diakses.

Seperti yang kita lihat, protokol merupakan cara ampuh untuk mencapai polimorfisme.
