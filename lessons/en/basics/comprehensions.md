%{
  version: "1.1.0",
  title: "Comprehensions",
  excerpt: """
  List comprehensions are syntactic sugar for looping through enumerables in Elixir.
  In this lesson, we'll look at how we can use comprehensions for iteration and generation.
  """
}
---

## Basics

Comprehensions can often be used to produce more concise statements for `Enum` and `Stream` iteration.
Let's start by looking at a simple comprehension and then break it down:

```elixir
iex> list = [1, 2, 3, 4, 5]
iex> for x <- list, do: x*x
[1, 4, 9, 16, 25]
```

The first thing we notice is the use of `for` and a generator.
What is a generator?
Generators are the `x <- [1, 2, 3, 4]` expressions found in list comprehensions.
They're responsible for generating the next value.

Lucky for us, comprehensions aren't limited to lists; in fact they'll work with any enumerable:

```elixir
# Keyword Lists
iex> for {_key, val} <- [one: 1, two: 2, three: 3], do: val
[1, 2, 3]

# Maps
iex> for {k, v} <- %{"a" => "A", "b" => "B"}, do: {k, v}
[{"a", "A"}, {"b", "B"}]

# Binaries
iex> for <<c <- "hello">>, do: <<c>>
["h", "e", "l", "l", "o"]
```

Like many other things in Elixir, generators rely on pattern matching to compare their input set to the left side variable.
In the event a match is not found, the value is ignored:

```elixir
iex> for {:ok, val} <- [ok: "Hello", error: "Unknown", ok: "World"], do: val
["Hello", "World"]
```

It's possible to use multiple generators, much like nested loops:

```elixir
iex> list = [1, 2, 3, 4]
iex> for n <- list, times <- 1..n do
...>   String.duplicate("*", times)
...> end
["*", "*", "**", "*", "**", "***", "*", "**", "***", "****"]
```

To better illustrate the looping that is occurring, let's use `IO.puts` to display the two generated values:

```elixir
iex> for n <- list, times <- 1..n, do: IO.puts "#{n} - #{times}"
1 - 1
2 - 1
2 - 2
3 - 1
3 - 2
3 - 3
4 - 1
4 - 2
4 - 3
4 - 4
```

List comprehensions are syntactic sugar and should be used only when appropriate.

## Filters

You can think of filters as a sort of guard for comprehensions.
When a filtered value returns `false` or `nil` it is excluded from the final list.
Let's loop over a range and only worry about even numbers.
We'll use the `is_even/1` function from the Integer module to check if a value is even or not.

```elixir
import Integer
iex> for x <- 1..10, is_even(x), do: x
[2, 4, 6, 8, 10]
```

Like generators, we can use multiple filters.
Let's expand our range and then filter only for values that are both even and evenly divisible by 3.

```elixir
import Integer
iex> for x <- 1..100,
...>   is_even(x),
...>   rem(x, 3) == 0, do: x
[6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 78, 84, 90, 96]
```

## Using :into

What if we want to produce something other than a list?
Given the `:into` option we can do just that!
As a general rule of thumb, `:into` accepts any structure that implements the `Collectable` protocol.

Using `:into`, let's create a map from a keyword list:

```elixir
iex> for {k, v} <- [one: 1, two: 2, three: 3], into: %{}, do: {k, v}
%{one: 1, three: 3, two: 2}
```

Since binaries are collectables we can use list comprehensions and `:into` to create strings:

```elixir
iex> for c <- [72, 101, 108, 108, 111], into: "", do: <<c>>
"Hello"
```

That's it!
List comprehensions are an easy way to iterate through collections concisely.
