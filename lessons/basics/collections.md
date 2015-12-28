---
layout: page
title: Collections
category: basics
order: 2
lang: en
---

List, tuples, keywords, maps, dicts and functional combinators.

## Table of Contents

- [Lists](#lists)
	- [List concatenation](#list-concatenation)
	- [List subtraction](#list-subtraction)
	- [Head / Tail](#head--tail)
- [Tuples](#tuples)
- [Keyword lists](#keyword-lists)
- [Maps](#maps)
- [Dicts](#dicts)

## Lists

Lists are simple collections of values, they may include multiple types; lists may include non-unique values:

```elixir
iex> [3.41, :pie, "Apple"]
[3.41, :pie, "Apple"]
```

Elixir implements list as linked lists.  This means accessing the list length is an `O(n)` operation.  For this reason, it is typically faster to prepend than append:

```elixir
iex> list = [3.41, :pie, "Apple"]
[3.41, :pie, "Apple"]
iex> ["π"] ++ list
["π", 3.41, :pie, "Apple"]
iex> list ++ ["Cherry"]
[3.41, :pie, "Apple", "Cherry"]
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

### Head / Tail

When using lists it is common to work with the list's head and tail.  The head is the first element of the list and the tail the remaining elements.  Elixir provides two helpful methods, `hd` and `tl`, for working with these parts:

```elixir
iex> hd [3.41, :pie, "Apple"]
3.41
iex> tl [3.41, :pie, "Apple"]
[:pie, "Apple"]
```

In addition to the aforementioned functions, you may use the pipe operator `|`; we'll see this pattern in later lessons:

```elixir
iex> [h|t] = [3.41, :pie, "Apple"]
[3.41, :pie, "Apple"]
iex> h
3.41
iex> t
[:pie, "Apple"]
```

## Tuples

Tuples are similar to lists but are stored contiguously in memory.  This makes accessing their length fast but modification expensive; the new tuple must be copied entirely to memory.  Tuples are defined with curly braces:

```elixir
iex> {3.41, :pie, "Apple"}
{3.41, :pie, "Apple"}
```

It is common for tuples to be used as a mechanism to return additional information from functions; the usefulness of this will be more apparent when we get into pattern matching:

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Keyword lists

Keywords and maps are the associative collections of Elixir; both implement the `Dict` module.  In Elixir, a keyword list is a special list of tuples whose first element is an atom; they share performance with lists:

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

In Elixir maps are the "go-to" key-value store, unlike keyword lists they allow keys of any type and they do not follow ordering.  You can define a map with the `%{}` syntax:

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
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

## Dicts

In Elixir, both keyword lists and maps implement the `Dict` module; as such they are known collectively as dictionaries.  If you need to build your own key-value store, implementing the `Dict` module is a good place to start.

The [`Dict` module](http://elixir-lang.org/docs/stable/elixir/#!Dict.html) provides a number of useful functions for interacting with, and manipulating, these dictionaries:

```elixir
# keyword lists
iex> Dict.put([foo: "bar"], :hello, "world")
[hello: "world", foo: "bar"]

# maps
iex> Dict.put(%{:foo => "bar"}, "hello", "world")
%{:foo => "bar", "hello" => "world"}

iex> Dict.has_key?(%{:foo => "bar"}, :foo)
true
```
