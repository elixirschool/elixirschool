%{
  version: "1.0.1",
  title: "协议",
  excerpt: """
  我们将在本课程看看 Elixir 里面的协议到底是什么，以及如何使用。
  """
}
---

## 什么是协议

协议到底是什么呢？协议是 Elixir 实现多态的一种方式。Erlang 的其中一个痛点，就是为现有的 API 扩展到新定义的类型上面。为了在 Elixir 里解决这个问题，函数是基于数值的类型来动态派遣的。Elixir 里预定义了好一些协议，比如说，`String.Chars`。这个协议定义了我们之前看过和用过的 `to_string/1` 函数。让我们用一些简单的例子来近距离看看 `to_string/1`。  


```elixir
iex> to_string(5)
"5"
iex> to_string(12.4)
"12.4"
iex> to_string("foo")
"foo"
```

正如你看到的，我们在函数调用的时候传入好几个不同类型的数据，而且也都能正常执行。那如果我们在调用 `to_string/1` 的时候传入元组（或者其它没有实现 `String.Chars` 协议的类型）呢？来看看结果：  

```elixir
to_string({:foo})
** (Protocol.UndefinedError) protocol String.Chars not implemented for {:foo}
    (elixir) lib/string/chars.ex:3: String.Chars.impl_for!/1
    (elixir) lib/string/chars.ex:17: String.Chars.to_string/1
```

由于没有为元组提供这个协议的实现，一个协议错误产生了。下一节，我们将为元组提供 `String.Chars` 协议的实现。  

## 实现协议

我们已经知道，`to_string/1` 并没有为元组提供实现，所以让我们来添加一个。要提供某个协议的实现，我们需要使用 `defimpl` 来指定这个协议，并用 `:for` 选项指明类型。让我们看看代码大概是什么样子的：  

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

如果把上面的代码复制到 IEx，我们现在就可以在调用 `to_string/1` 的时候传入一个元组，而且还不会出错了：  

```elixir
iex> to_string({3.14, "apple", :pie})
"{3.14, apple, pie}"
```

我们已经知道如何实现一个接口，但是如何定义一个新的协议呢？通过下面的例子，我们将会实现 `to_atom/1` 这个函数。来看看如何使用 `defprotocol` 定义一个协议：  

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

这里，我们定义了自己的协议，以及它提供的函数 `to_atom/1`，还有某一些类型的实现方式。既然现在我们拥有了自己的协议，那就放到 IEx 里面来使用一下：  

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

要注意的是，虽然结构体的本质是映射（Map），但是它们并不和映射共享协议的实现方式。它们不可遍历，所以也不能以这种方式访问。  

如你所见，协议是一种强大的实现多态的手段。  
