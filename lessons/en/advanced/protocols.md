%{
  version: "1.0.1",
  title: "Protocols",
  excerpt: """
  In this lesson we are going to look at Protocols, what they are, and how we use them in Elixir.
  """
}
---

## What Are Protocols

So what are they?
Protocols are a means of achieving polymorphism in Elixir.
One pain of Erlang is extending an existing API for newly defined types.
To avoid this in Elixir the function is dispatched dynamically based on the value's type.
Elixir comes with a number of protocols built in, for example the `String.Chars` protocol is responsible for the `to_string/1` function we've seen used previously.
Let's take a closer look at `to_string/1` with a quick example:

```elixir
iex> to_string(5)
"5"
iex> to_string(12.4)
"12.4"
iex> to_string("foo")
"foo"
```

As you can see we've called the function on multiple types and demonstrated that it works on them all.
What if we call `to_string/1` on tuples (or any type that hasn't implemented `String.Chars`)?
Let's see:

```elixir
to_string({:foo})
** (Protocol.UndefinedError) protocol String.Chars not implemented for {:foo}
    (elixir) lib/string/chars.ex:3: String.Chars.impl_for!/1
    (elixir) lib/string/chars.ex:17: String.Chars.to_string/1
```

As you can see we get a protocol error as there is no implementation for tuples.
In the next section we'll implement the `String.Chars` protocol for tuples.

## Implementing a protocol

We saw that `to_string/1` has not yet been implemented for tuples, so let's add it.
To create an implementation we'll use `defimpl` with our protocol, and provide the `:for` option, and our type.
Let's take a look at how it might look:

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

If we copy this into IEx we should be now be able to call `to_string/1` on a tuple without getting an error:

```elixir
iex> to_string({3.14, "apple", :pie})
"{3.14, apple, pie}"
```

We know how to implement a protocol but how do we define a new one?
For our example we'll implement `to_atom/1`.
Let's see how to do that with `defprotocol`:

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

Here we've defined our protocol and it's expected function, `to_atom/1`, along with implementations for a few types.
Now that we have our protocol, let's put it to use in IEx:

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

It is worth it to note, that although underneath structs are Maps, they do not share protocol implementations with Maps.
They are not enumerable, they cannot be accessed.

As we can see, protocols are a powerful way to achieve polymorphism.
