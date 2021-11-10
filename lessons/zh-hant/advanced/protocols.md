%{
  version: "1.0.1",
  title: "協定",
  excerpt: """
  在本課程中，將研究協定 (Protocols) 是什麼，以及如何在 Elixir 中使用。
  """
}
---

## 什麼是協定 (Protocols)

那麼協定是什麼？協定是實現 Elixir 多型 (polymorphism) 的一種手段。Erlang 的一個惱人之處是會為新定義的型別擴展現有 API。為了在 Elixir 中避免這件事，函數會根據值的型別動態調度 (dispatched dynamically)。

Elixir 帶有一些內建的協定，例如 `String.Chars` 協定負責之前看到並使用過的 `to_string/1` 函數。現在來看看 `to_string/1` 的一個簡短例子：

```elixir
iex> to_string(5)
"5"
iex> to_string(12.4)
"12.4"
iex> to_string("foo")
"foo"
```

正如所看到的，我們已經在多種型別上呼用了函數，並證明它對所有型別都有效。如果在 tuple（或任何沒有實現 `String.Chars` 的型別）上呼用 `to_string/1` 會怎麼樣？這就來看看：

```elixir
to_string({:foo})
** (Protocol.UndefinedError) protocol String.Chars not implemented for {:foo}
    (elixir) lib/string/chars.ex:3: String.Chars.impl_for!/1
    (elixir) lib/string/chars.ex:17: String.Chars.to_string/1
```

正如你所看到的，我們會得到一個協定錯誤 (protocol error)，因為沒有實現 tuple。在下一節中，將為 tuple 實現 `String.Chars` 協定。

## 實現一個協定

我們看到 `to_string/1` 尚未因 tuple 實現 ，所以手動加進它。要建立一個實現，將在協定中使用 `defimpl` ，並提供 `:for` 選項和我們的型別。它可能看起來像：

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

如果將其複製到 IEx 中，現在應該可以在 tuple 上呼用 `to_string/1` 而不會出現錯誤訊息：

```elixir
iex> to_string({3.14, "apple", :pie})
"{3.14, apple, pie}"
```

我們已經知道如何實現一個協定，但如何定義一個新協定呢？將實現 `to_atom / 1` 來做為範例。讓我們看看如何用 `defprotocol` 來做到這一點：

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

這裡定義了協定、它的預期函數 `to_atom/1`，以及幾種型別的實現。現在有了協定，接著在 IEx 中使用它：

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

值得注意的是，雖然下層結構是 Map，但它們不會與 Map 共享協定實現。它們不是可枚舉 (enumerable)，也不能被存取。

而如以上所看到的，協定是實現多型的有效方式。