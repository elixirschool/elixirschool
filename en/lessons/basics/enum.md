---
version: 1.3.0
title: Enum
redirect_from:
  - /lessons/basics/enum/
---

A set of algorithms for enumerating over enumerables.

{% include toc.html %}

## Enum

The `Enum` module includes over 70 functions for working with enumerables.  All the collections that we learned about in the [previous lesson](../collections/), with the exception of tuples, are enumerables.

This lesson will only cover a subset of the available functions, however we can actually examine them ourselves.
Let's do a little experiment in IEx.

```elixir
iex> Enum.__info__(:functions) |> Enum.each(fn({function, arity}) ->
...>   IO.puts "#{function}/#{arity}"
...> end)
all?/1
all?/2
any?/1
any?/2
at/2
at/3
...
```

Using this, it's clear that we have a vast amount of functionality, and that is for a clear reason.
Enumeration is at the core of functional programming and is an incredibly useful thing.
By leveraging it combined with other perks of Elixir, such as documentation being a first class citizen as we just saw, it can be incredibly empowering to the developer as well.

For a full list of functions visit the official [`Enum`](https://hexdocs.pm/elixir/Enum.html) docs; for lazy enumeration use the [`Stream`](https://hexdocs.pm/elixir/Stream.html) module.


### all?

When using `all?/2`, and much of `Enum`, we supply a function to apply to our collection's items.  In the case of `all?/2`, the entire collection must evaluate to `true` otherwise `false` will be returned:

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

Unlike the above, `any?/2` will return `true` if at least one item evaluates to `true`:

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk_every

If you need to break your collection up into smaller groups, `chunk_every/2` is the function you're probably looking for:

```elixir
iex> Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

There are a few options for `chunk_every/4` but we won't go into them, check out [`the official documentation of this function`](https://hexdocs.pm/elixir/Enum.html#chunk_every/4) to learn more.

### chunk_by

If we need to group our collection based on something other than size, we can use the `chunk_by/2` function. It takes a given enumerable and a function, and when the return on that function changes a new group is started and begins the creation of the next:

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
iex> Enum.chunk_by(["one", "two", "three", "four", "five", "six"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"], ["six"]]
```

### map_every

Sometimes chunking out a collection isn't enough for exactly what we may need. If this is the case, `map_every/3` can be very useful to hit every `nth` items, always hitting the first one:

```elixir
# Apply function every three items
iex> Enum.map_every([1, 2, 3, 4, 5, 6, 7, 8], 3, fn x -> x + 1000 end)
[1001, 2, 3, 1004, 5, 6, 1007, 8]
```

### each

It may be necessary to iterate over a collection without producing a new value, for this case we use `each/2`:

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
:ok
```

__Note__: The `each/2` function does return the atom `:ok`.

### map

To apply our function to each item and produce a new collection look to the `map/2` function:

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

`min/1` finds the minimal value in the collection:

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

`min/2` does the same, but in case the enumerable is empty, it allows us to specify a function to produce the minimum value.

```elixir
iex> Enum.min([], fn -> :foo end)
:foo
```

### max

`max/1` returns the maximal value in the collection:

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

`max/2` is to `max/1` what `min/2` is to `min/1`:

```elixir
Enum.max([], fn -> :bar end)
:bar
```

### reduce

With `reduce/3` we can distill our collection down into a single value.  To do this we supply an optional accumulator (`10` in this example) to be passed into our function; if no accumulator is provided the first element in the enumerable is used:

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16

iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6

iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
```

### sort

Sorting our collections is made easy with not one, but two, sorting functions.

`sort/1` uses Erlang's term ordering to determine the sorted order:

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

While `sort/2` allows us to provide a sorting function of our own:

```elixir
# with our function
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# without
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq_by

We can use `uniq_by/2` to remove duplicates from our enumerables:

```elixir
iex> Enum.uniq_by([1, 2, 3, 2, 1, 1, 1, 1, 1], fn x -> x end)
[1, 2, 3]
```
