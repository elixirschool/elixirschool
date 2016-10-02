---
layout: page
title: Enum
category: basics
order: 3
lang: en
---

A set of algorithms for enumerating over collections.

{% include toc.html %}

## Enum

The `Enum` module includes nearly 100 functions for working with the collections we learned about in the last lesson.

This lesson will only cover a subset of the available functions, however we can actually examine them ourselves.
Let's do a little experiment in IEx.

```elixir
iex
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

Using this, its clear that we have a vas amount of functionality, and that is for a clear reason.
Enumeration is at the core of functional programming and is an incredibly useful thing.
By leveraging it combined with other perks of Elixir, such as documentation being a first class citizen as we just saw, it can be incredibly empowering to the developer as well.

For a full list of functions visit the official [`Enum`](http://elixir-lang.org/docs/stable/elixir/Enum.html) docs; for lazy enumeration use the [`Stream`](http://elixir-lang.org/docs/stable/elixir/Stream.html) module.


### all?

When using `all?`, and much of `Enum`, we supply a function to apply to our collection's items.  In the case of `all?`, the entire collection must evaluate to `true` otherwise `false` will be returned:

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

Unlike the above, `any?` will return `true` if at least one item evaluates to `true`:

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk

If you need to break your collection up into smaller groups, `chunk` is the function you're probably looking for:

```elixir
iex> Enum.chunk([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

There are a few options for `chunk` but we won't go into them, check out [`chunk/2`](http://elixir-lang.org/docs/stable/elixir/Enum.html#chunk/2) in the official docs to learn more.

### chunk_by

If we need to group our collection based on something other than size, we can use the `chunk_by` method. It takes a given enumerable and a function, and when the return on that function changes a new group is started and begins the creation of the next:

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
iex> Enum.chunk_by(["one", "two", "three", "four", "five", "six"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"], ["six"]]
```

### each

It may be necessary to iterate over a collection without producing a new value, for this case we use `each`:

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
```

__Note__: The `each` method does return the atom `:ok`.

### map

To apply our function to each item and produce a new collection look to the `map` function:

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

Find the `min` value in our collection:

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

### max

Returns the `max` value in the collection:

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

### reduce

With `reduce` we can distill our collection down into a single value.  To do this we supply an optional accumulator (`10` in this example) to be passed into our function; if no accumulator is provided the first value is used:

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16
iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6
```

### sort

Sorting our collections is made easy with not one, but two, `sort` functions.  The first option available to us uses Elixir's term ordering to determine the sorted order:

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

The other option allows us to provide a sort function:

```elixir
# with our function
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# without
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq

We can use `uniq` to remove duplicates from our collections:

```elixir
iex> Enum.uniq([1, 2, 2, 3, 3, 3, 4, 4, 4, 4])
[1, 2, 3, 4]
```
