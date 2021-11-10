%{
  version: "1.0.0",
  title: "프로토콜",
  excerpt: """
  여기에서는 프로토콜을 들여다보고, 이것이 무엇인지, Elixir에서 어떻게 사용하는지에 대해서 알아봅니다.
  """
}
---

## 프로토콜이란

그래서 뭘까요?
프로토콜은 Elixir에서 다형성을 성취하기 위한 도구입니다.
Erlang의 불편한 부분 중 하나는 새로 정의된 타입을 사용해 기존의 API를 확장하는 것입니다.
Elixir는 많은 프로토콜을 가지고 있으며, 예를 들어 `String.Chars` 프로토콜은 이전에 보았던 `to_string/1` 함수를 책임집니다.
`to_string/1`을 간단한 예제와 함께 살펴보죠.

```elixir
iex> to_string(5)
"5"
iex> to_string(12.4)
"12.4"
iex> to_string("foo")
"foo"
```

여기에서 볼 수 있듯, 여러 타입에 대해서 함수를 호출하고 그 모두와 잘 동작합니다.
`to_string/1`을 튜플(또는 `String.Chars`에 구현되지 않은 아무 타입)을 사용하여 호출하면 어떻게 될까요?
확인해봅시다.

```elixir
to_string({:foo})
** (Protocol.UndefinedError) protocol String.Chars not implemented for {:foo}
    (elixir) lib/string/chars.ex:3: String.Chars.impl_for!/1
    (elixir) lib/string/chars.ex:17: String.Chars.to_string/1
```

튜플을 위한 구현이 존재하지 않는다는 프로토콜 에러를 볼 수 있습니다.
다음 장에서는 튜플을 위한 `String.Chars` 프로토콜을 구현해봅시다.

## 프로토콜 구현하기

튜플을 위한 `to_string/1`의 구현이 없다는 것을 확인했으니 추가해봅시다.
프로토콜을 구현하기 위해서 `defimpl`을 사용하고, 구현할 타입을 `:for` 옵션에 넘겨줍니다.
어떤 모습인지 살펴봅시다.

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

이 코드를 IEx에 붙여넣고 `to_string/1`을 호출하면 에러가 발생하는 일 없이 결과를 확인할 수 있습니다.

```elixir
iex> to_string({3.14, "apple", :pie})
"{3.14, apple, pie}"
```

이제 어떻게 프로토콜을 구현하는지 배웠습니다만, 아예 새로운 프로토콜은 어떻게 만들어야 할까요?
예제로 `to_atom/1`을 구현해보겠습니다.
`defprotocol`을 어떻게 사용하는지 보세요.

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

여기에서는 프로토콜을 정의하고 이 프로토콜이 구현할 것이라고 기대하는 함수인 `to_atom/1`를 몇몇 타입에 대해서 구현하고 있습니다.
이제 프로토콜을 만들었으니, IEx에서 사용해봅시다.

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

주의해야할 점은 구조체의 내부는 Map임에도 불구하고 Map의 프로토콜을 공유하지 않는다는 점입니다. 이들은 열거할 수 없으므로, 접근도 할 수 없습니다.

여기까지 보았듯, 프로토콜은 다형성을 성취하기 위한 강력한 방식입니다.
