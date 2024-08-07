%{
  version: "1.0.1",
  title: "Протоколы",
  excerpt: """
  В этом уроке мы рассмотрим протоколы, что это такое и как мы их используем в Elixir.
  """
}
---

## Что такое протоколы

Итак, что же это такое?
Протоколы — это средство для достижения полиморфизма в Elixir.
Одной из трудностей Erlang является расширение существующего API для вновь новых типов.
Чтобы избежать этого в Elixir, функция динамически вызывается на основе типа значения.
В Elixir уже есть набор встроенных протоколов, например, протокол `String.Chars` отвечает за функцию `to_string/1`, которую мы уже видели ранее.
Давайте посмотрим поближе на `to_string/1` с небольшим примером:

```elixir
iex> to_string(5)
"5"
iex> to_string(12.4)
"12.4"
iex> to_string("foo")
"foo"
```

Как видите, мы вызвали функцию для нескольких типов и продемонстрировали, что она работает для всех них.
Что произойдет, если мы вызовем `to_string/1` для кортежей (или любого типа, для которого не реализован `String.Chars`)?
Посмотрим:

```elixir
to_string({:foo})
** (Protocol.UndefinedError) protocol String.Chars not implemented for {:foo}
    (elixir) lib/string/chars.ex:3: String.Chars.impl_for!/1
    (elixir) lib/string/chars.ex:17: String.Chars.to_string/1
```

Как видите, мы получаем ошибку протокола, так как для кортежей нет реализации.
В следующем разделе мы реализуем протокол `String.Chars` для кортежей.

## Реализация протокола

Мы увидели, что `to_string/1` еще не реализован для кортежей, так что давайте добавим его.
Для создания реализации мы используем `defimpl` с нашим протоколом, указываем опцию `:for` и наш тип.
Посмотрим, как это может выглядеть:

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

Если мы скопируем это в IEx, мы теперь сможем вызвать `to_string/1` для кортежа без получения ошибки:

```elixir
iex> to_string({3.14, "apple", :pie})
"{3.14, apple, pie}"
```

Мы знаем, как реализовать протокол, но как определить новый?
Для нашего примера мы реализуем `to_atom/1`.
Посмотрим, как это сделать с `defprotocol`:

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

Здесь мы определили наш протокол и ожидаемую функцию `to_atom/1`, а также реализации для нескольких типов.
Теперь, когда у нас есть наш протокол, давайте используем его в IEx:

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

Стоит отметить, что хотя под капотом структуры являются ассоциативными массивами, они не разделяют реализации протоколов с картами.
Они не являются перечисляемыми, к ним нельзя получить доступ.

Как мы видим, протоколы — это мощный способ достижения полиморфизма.
