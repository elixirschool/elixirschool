# Lesson 2 — Collections

List, tuples, keywords, maps, dicts and functional combinators.

## Table of Contents

- [Lists](#lists)
	- [List concatenation](#list-concatenation) 
	- [List subtraction](#list-subtraction) 
	- [Head / Tail](#head-/-tail) 
- [Tuples](#tuples)
- [Keywords](#keywords)
- [Maps](#maps)
- [Dicts](#dicts)

## Lists

Lists are simple collections of values, they may include multiple types; lists may include non-unqiue values:

```elixir
iex> [3.41, :pie, "Apple"]
[3.41, :pie, "Apple"]
```

Elixir implements list as linked lists.  This means accessing the list length is an `O(n)` operation.  For of this reason, it is typically faster to prepend than append:

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

Support for substraction is provided via the `--/2` operator; it's safe to subtract a missing value:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

### Head / Tail

When using lists it is common to work with the list's head and tail.  The head is the first element of the list and the tail the remainding elements.  Elixir provides two helpful methods, `hd` and `tl`, for working with these parts:

```elixir
iex> hd [3.41, :pie, "Apple"]
3.41
iex> tl [3.41, :pie, "Apple"]
[:pie, "Apple"]
```

In addition to the aforementioned functions, you may use the pipe operator; we'll see this pattern in later lessons:

```elixir
iex> [h|t] = [3.41, :pie, "Apple"]
[3.41, :pie, "Apple"]
iex> h
3.41
iex> t
[:pie, "Apple"]
```

## Tuples

Tuples are similar to lists but are stored contigiously in memory.  This makes accessing their length fast but modification expensive; the new tuple must copied entirely to memory.  Tuples are defined with curly brances:

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

## Keywords

## Maps

## Dicts

