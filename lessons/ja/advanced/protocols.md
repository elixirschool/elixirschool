%{
  version: "1.0.1",
  title: "プロトコル",
  excerpt: """
  このレッスンではプロトコルがどんなものなのか、そしてElixirでどのように使うのかを見ていきます。
  """
}
---

## プロトコルとは何か

プロトコルとは何でしょうか？
プロトコルはElixirにおいてポリモルフィズムを獲得する手段です。
Erlangの苦痛の一つは、新しく定義する型のために、既存のAPIを拡張していることです。
Elixirではこれを避けるため、関数はその値の型に基いて、動的にディスパッチされます。
Elixirには数多くのビルトインのプロトコルがあり、例えば `String.Chars` プロトコルは以前使った `to_string/1` 関数を担当します。
簡単な例で `to_string/1` を更に詳しく見てみましょう。

```elixir
iex> to_string(5)
"5"
iex> to_string(12.4)
"12.4"
iex> to_string("foo")
"foo"
```

ご覧の通り、この関数を複数の型で呼び出し、どの型でも動くことが示されています。
`to_string/1` をタプル（もしくは `String.Chars` を実装していない何らかの型）で呼び出すとどうなるでしょうか？
見てみましょう:

```elixir
to_string({:foo})
** (Protocol.UndefinedError) protocol String.Chars not implemented for {:foo}
    (elixir) lib/string/chars.ex:3: String.Chars.impl_for!/1
    (elixir) lib/string/chars.ex:17: String.Chars.to_string/1
```

ご覧の通り、タプルには実装が無いのでプロトコル・エラーが発生しました。
次のセクションでは、タプルに `String.Chars` プロトコルを実装します。

## プロトコルを実装する

タプルには `to_string/1` はまだ実装されていないことが分かっていますので、追加しましょう。
実装を行うには `defimpl` でプロトコルを指定し、 `:for` オプションで型を指定します。
実際どんな風になるのか見てみましょう。

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

IExにこれをコピーして流し込めば、今度はエラーを出さずタプルに対して `to_string/1` を呼び出すことが出来るはずです。

```elixir
iex> to_string({3.14, "apple", :pie})
"{3.14, apple, pie}"
```

どうやってプロトコルの実装を行えばいいのかはわかりましたが、では、新しいプロトコルを定義するにはどうしたら良いのでしょうか？
この例では `to_atom/1` を実装してみます。
`defprotocol` を用いる方法を見ていきましょう。

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

さてプロトコルを定義しましたが、このプロトコルではいくつかの型に対する実装で `to_atom/1` 関数が要求されます。
それではプロトコルができたので、IExで使ってみましょう。

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

特筆すべきは、構造体の内部にはMapがあるものの、構造体はプロトコルの実装をMapと共有していないという点です。それらは列挙可能ではなく、それらにアクセスもできません。

以上でおわかりのように、プロトコルはポリモルフィズムを獲得するための強力な手段です。
