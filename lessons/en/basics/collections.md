%{
  version: "1.3.1",
  title: "Collections",
  excerpt: """
  Lists, tuples, keyword lists, and maps.
  """
}
---

## Lists

Lists are simple collections of values which may include multiple types; lists may also include non-unique values:

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir implements list collections as linked lists.
This means that accessing the list length is an operation that will run in linear time (`O(n)`).
For this reason, it is typically faster to prepend than to append:

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
# Prepending (fast)
iex> ["π" | list]
["π", 3.14, :pie, "Apple"]
# Appending (slow)
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```

### List Concatenation

List concatenation uses the `++/2` operator:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

A side note about the name (`++/2`) format used above:
In Elixir (and Erlang, upon which Elixir is built), a function or operator name has two components: the name you give it (here `++`) and its _arity_.
Arity is a core part of speaking about Elixir (and Erlang) code.
It is the number of arguments a given function takes (two, in this case).
Arity and the given name are combined with a slash. We'll talk more about this later; this knowledge will help you understand the notation for now.

### List Subtraction

Support for subtraction is provided via the `--/2` operator; it's safe to subtract a missing value:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

Be mindful of duplicate values.
For every element on the right, the first occurrence of it gets removed from the left:

```elixir
iex> [1,2,2,3,2,3] -- [1,2,3,2]
[2, 3]
```

**Note:** List subtraction uses [strict comparison](/en/lessons/basics/basics#comparison) to match the values. For example:

```elixir
iex> [2] -- [2.0]
[2]
iex> [2.0] -- [2.0]
[]
```

### Head / Tail

When using lists, it is common to work with a list's head and tail.
The head is the list's first element, while the tail is a list containing the remaining elements.
Elixir provides two helpful functions, `hd` and `tl`, for working with these parts:

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

In addition to the aforementioned functions, you can use [pattern matching](/en/lessons/basics/pattern_matching) and the cons operator `|` to split a list into head and tail. We'll learn more about this pattern in later lessons:

```elixir
iex> [head | tail] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> head
3.14
iex> tail
[:pie, "Apple"]
```

## Tuples

Tuples are similar to lists, but are stored contiguously in memory.
This makes accessing their length fast but modification expensive; the new tuple must be copied entirely to memory.
Tuples are defined with curly braces:

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

It is common for tuples to be used as a mechanism to return additional information from functions; the usefulness of this will be more apparent when we get into [pattern matching](/en/lessons/basics/pattern_matching):

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Keyword lists

Keyword lists and maps are the associative collections of Elixir.
In Elixir, a keyword list is a special list of two-element tuples whose first element is an atom; they share performance with lists:

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

The three characteristics of keyword lists highlight their importance:

+ Keys are atoms.
+ Keys are ordered.
+ Keys do not have to be unique.

For these reasons, keyword lists are most commonly used to pass options to functions.

## Maps

In Elixir, maps are the "go-to" key-value store.
Unlike keyword lists, they allow keys of any type and are un-ordered.
You can define a map with the `%{}` syntax:

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

As of Elixir 1.2, variables are allowed as map keys:

```elixir
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
```

If a duplicate is added to a map, it will replace the former value:

```elixir
iex> %{:foo => "bar", :foo => "hello world"}
%{foo: "hello world"}
```

As we can see from the output above, there is a special syntax for maps containing only atom keys:

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```

In addition, there is a special syntax you can use with atom keys:

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> map.hello
"world"
```

Another interesting property of maps is that they provide their own syntax for updates (note: this creates a new map):

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{map | foo: "baz"}
%{foo: "baz", hello: "world"}
```

**Note**: this syntax only works for updating a key that already exists in the map! If the key does not exist, a `KeyError` will be raised.

To create a new key, instead use [`Map.put/3`](https://hexdocs.pm/elixir/Map.html#put/3)

```elixir
iex> map = %{hello: "world"}
%{hello: "world"}
iex> %{map | foo: "baz"}
** (KeyError) key :foo not found in: %{hello: "world"}
    (stdlib) :maps.update(:foo, "baz", %{hello: "world"})
    (stdlib) erl_eval.erl:259: anonymous fn/2 in :erl_eval.expr/5
    (stdlib) lists.erl:1263: :lists.foldl/3
iex> Map.put(map, :foo, "baz")
%{foo: "baz", hello: "world"}
```
