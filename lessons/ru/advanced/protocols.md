%{
  version: "1.0.1",
  title: "Протоколы",
  excerpt: """
  В этом уроке мы рассмотрим протоколы в языке Elixir: что это такое и как их использовать.
  """
}
---

## Что такое протоколы?
Так что же это такое? Протоколы &mdash; способ реализации полиморфизма в Elixir. Исторически сложилось, что в Erlang есть проблема с расширением уже существующих API для новых типов. Решением этой проблемы в Elixir являются протоколы — функции, определяемые динамически на основе типа передаваемого значения.

В Elixir уже есть набор встроенных протоколов с имплементациями. Отличным примером является протокол `String.Chars`, который используется в функции `to_string/1`. Давайте рассмотрим этот пример подробнее:

```elixir
iex> to_string(5)
"5"
iex> to_string(12.4)
"12.4"
iex> to_string("foo")
"foo"
```

Как мы видим, вызов функции работает на нескольких типах. А что если мы хотим вызывать `to_string/1` на кортежах (или любом другом типе, для которого не реализован `String.Chars`)? Попробуем:

```elixir
to_string({:foo})
** (Protocol.UndefinedError) protocol String.Chars not implemented for {:foo}
    (elixir) lib/string/chars.ex:3: String.Chars.impl_for!/1
    (elixir) lib/string/chars.ex:17: String.Chars.to_string/1
```

Как мы видим, возникает ошибка из-за отсутствия реализации для этого типа.

## Имплементация протокола

Мы уже видели, что `to_string/1` не имплементирован для кортежей, так что давайте добавим эту реализацию. Для ее создания мы воспользуемся `defimpl`, передав опцию `:for` с типом, для которого реализуется этот протокол:

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

После выполнения этого кода в IEx можно будет вызывать `to_string/1` на кортеже без получения ошибки:

```elixir
iex> to_string({3.14, "apple", :pie})
"{3.14, apple, pie}"
```

Теперь мы можем реализовать протокол, но как создать новый? Для примера давайте попробуем создать функцию `to_atom/1`. Для создания нового протокола используется макрос `defprotocol`:

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

Таким образом мы создали новый протокол с методом `to_atom/1` вместе с имплементацией для нескольких типов. Теперь, когда протокол есть, давайте попробуем использовать его в IEx:

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

Структуры реализованы как ассоциативные массивы, однако они не могут использовать те же имплементации протоколов, потому что не являются перечисляемыми.

Как мы убедились в этом уроке, протоколы являются мощным инструментом для достижения полиморфизма.
