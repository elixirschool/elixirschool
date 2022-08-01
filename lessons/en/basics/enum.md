%{
  version: "1.9.1",
  title: "Enum",
  excerpt: """
  A set of algorithms for enumerating over enumerables.
  """
}
---

# Overview

The `Enum` module includes over 70 functions for working with enumerables.
All the collections that we learned about in the [previous lesson](/en/lessons/basics/collections), with the exception of tuples, are enumerables.

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
Enumeration is at the core of functional programming, and combined with other perks of Elixir it can be incredibly empowering for developers.

# Common Functions

For a full list of functions visit the official [`Enum`](https://hexdocs.pm/elixir/Enum.html) docs; for lazy enumeration use the [`Stream`](https://hexdocs.pm/elixir/Stream.html) module.

## all?

When using `all?/2`, and much of `Enum`, we supply a function to apply to our collection's items.
In the case of `all?/2`, the entire collection must evaluate to `true` otherwise `false` will be returned:

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

## any?

Unlike the above, `any?/2` will return `true` if at least one item evaluates to `true`:

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

## chunk_every

If you need to break your collection up into smaller groups, `chunk_every/2` is the function you're probably looking for:

```elixir
iex> Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

There are a few options for `chunk_every/4` but we won't go into them, check out [the official documentation of this function](https://hexdocs.pm/elixir/Enum.html#chunk_every/4) to learn more.

## chunk_by

If we need to group our collection based on something other than size, we can use the `chunk_by/2` function.
It takes a given enumerable and a function, and when the return on that function changes a new group is started and begins the creation of the next.
In the examples below, each string of the same length is grouped together until we encounter a new string of a new length:

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
iex> Enum.chunk_by(["one", "two", "three", "four", "five", "six"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"], ["six"]]
```

## map_every

Sometimes chunking out a collection isn't enough for exactly what we may need.
If this is the case, `map_every/3` can be very useful to hit every `nth` items, always hitting the first one:

```elixir
# Apply function every three items
iex> Enum.map_every([1, 2, 3, 4, 5, 6, 7, 8], 3, fn x -> x + 1000 end)
[1001, 2, 3, 1004, 5, 6, 1007, 8]
```

## each

It may be necessary to iterate over a collection without producing a new value, for this case we use `each/2`:

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
:ok
```

__Note__: The `each/2` function does return the atom `:ok`.

## map

To apply our function to each item and produce a new collection look to the `map/2` function:

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

## min

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

## max

`max/1` returns the maximal value in the collection:

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

`max/2` is to `max/1` what `min/2` is to `min/1`:

```elixir
iex> Enum.max([], fn -> :bar end)
:bar
```

## filter

The `filter/2` function enables us to filter the collection to include only those elements that evaluate to `true` using the provided function.

```elixir
iex> Enum.filter([1, 2, 3, 4], fn(x) -> rem(x, 2) == 0 end)
[2, 4]
```

## reduce

With `reduce/3` we can distill our collection down into a single value.
To do this we supply an optional accumulator (`10` in this example) to be passed into our function; if no accumulator is provided the first element in the enumerable is used:

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16

iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6

iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
```

## sort

Sorting our collections is made easy with not one, but two, sorting functions.

`sort/1` uses Erlang's [term ordering](http://erlang.org/doc/reference_manual/expressions.html#term-comparisons) to determine the sorted order:

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

For convenience, `sort/2` allows us to pass `:asc` or `:desc` as the sorting function:

```elixir
Enum.sort([2, 3, 1], :desc)
[3, 2, 1]
```

## uniq

We can use `uniq/1` to remove duplicates from our enumerables:

```elixir
iex> Enum.uniq([1, 2, 3, 2, 1, 1, 1, 1, 1])
[1, 2, 3]
```

## uniq_by

`uniq_by/2` also removes duplicates from enumerables, but it allows us to provide a function to do the uniqueness comparison.

```elixir
iex> Enum.uniq_by([%{x: 1, y: 1}, %{x: 2, y: 1}, %{x: 3, y: 3}], fn coord -> coord.y end)
[%{x: 1, y: 1}, %{x: 3, y: 3}]
```

# Enum using the Capture operator (&)

Many functions within the Enum module in Elixir take anonymous functions as an argument to work with each iterable of the enumerable that is passed.

These anonymous functions are often written shorthand using the Capture operator (&).

Here are some examples that show how the capture operator can be implemented with the Enum module.
Each version is functionally equivalent.

## Using the capture operator with an anonymous function

Below is a typical example of the standard syntax when passing an anonymous function to `Enum.map/2`.

```elixir
iex> Enum.map([1,2,3], fn number -> number + 3 end)
[4, 5, 6]
```

Now we implement the capture operator (&); capturing each iterable of the list of numbers ([1,2,3]) and assign each iterable to the variable &1 as it is passed through the mapping function.

```elixir
iex> Enum.map([1,2,3], &(&1 + 3))
[4, 5, 6]
```

This can be further refactored to assign the prior anonymous function featuring the Capture operator to a variable and called from the `Enum.map/2` function.

```elixir
iex> plus_three = &(&1 + 3)
iex> Enum.map([1,2,3], plus_three)
[4, 5, 6]
```

## Using the capture operator with a named function

First we create a named function and call it within the anonymous function defined in `Enum.map/2`.

```elixir
defmodule Adding do
  def plus_three(number), do: number + 3
end

iex>  Enum.map([1,2,3], fn number -> Adding.plus_three(number) end)
[4, 5, 6]
```

Next we can refactor to use the Capture operator.

```elixir
iex> Enum.map([1,2,3], &Adding.plus_three(&1))
[4, 5, 6]
```

For the most succinct syntax, we can directly call the named function without explicitly capturing the variable.

```elixir
iex> Enum.map([1,2,3], &Adding.plus_three/1)
[4, 5, 6]
```
