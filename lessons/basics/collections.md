---
layout: page
title: Collections
category: basics
order: 2
lang: en
---

List, tuples, keywords, maps and functional combinators.

{% include toc.html %}

## Lists

Lists are simple collections of values, they may include multiple types; lists may include non-unique values:

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir implements list as linked lists.  This means accessing the list length is an `O(n)` operation.  For this reason, it is typically faster to prepend than append:

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> ["π"] ++ list
["π", 3.14, :pie, "Apple"]
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```


### List Concatenation

List concatenation uses the `++/2` operator:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

### List Subtraction

Support for subtraction is provided via the `--/2` operator; it's safe to subtract a missing value:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

**Note:** It uses [strict comparison](../basics/#comparison) to match the values.

### Head / Tail

When using lists it is common to work with a list's head and tail.  The head is the list's first element while the tail is the remaining elements.  Elixir provides two helpful methods, `hd` and `tl`, for working with these parts:

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14ex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

In addition to the aforementioned functions, you can use [pattern matching](../pattern-matching/) and the cons operator `|` to split a list into head and tail; we'll learn more about this pattern in later lessons:

```elixir
iex> [h|t] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> h
3.14ex> t
[:pie, "Apple"]
```

## Tuples

Tuples are similar to lists but are stored contiguously in memory.  This makes accessing their length fast but modification expensive; the new tuple must be copied entirely to memory.  Tuples are defined with curly braces:

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

It is common for tuples to be used as a mechanism to return additional information from functions; the usefulness of this will be more apparent when we get into pattern matching:

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Keyword lists

Keywords and maps are the associative collections of Elixir.  In Elixir, a keyword list is a special list of tuples whose first element is an atom; they share performance with lists:

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

The three characteristics of keyword lists highlight their importance:

+ Keys are atoms.
+ Keys are ordered.
+ Keys are not unique.

For these reasons keyword lists are most commonly used to pass options to functions.

## Maps

In Elixir maps are the "go-to" key-value store. Unlike keyword lists they allow keys of any type and are un-ordered.  You can define a map with the `%{}` syntax:

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

As of Elixir 1.2 variables are allowed as map keys:

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

Another interesting property of maps is that they provide their own syntax for updating and accessing atom keys:

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{map | foo: "baz"}
%{foo: "baz", hello: "world"}
iex> map.hello
"world"
```
