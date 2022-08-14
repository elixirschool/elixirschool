%{
  version: "1.1.1",
  title: "StreamData",
  excerpt: """
  An example-based unit testing library like [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html) is a wonderful tool to help you verify that your code works the way you think it does.
  However, example-based unit tests have some drawbacks:

* It can be easy to miss edge cases, since you're only testing a few inputs.
* You can write these tests without thinking through your requirements thoroughly.
* These tests can be very verbose when you use several examples for one function.

In this lesson we're going to explore how [StreamData](https://github.com/whatyouhide/stream_data) can help us overcome some of these drawbacks
  """
}
---

## What is StreamData?

[StreamData](https://github.com/whatyouhide/stream_data) is a library that performs stateless property-based testing.

The StreamData library will run each test [100 times by default](https://hexdocs.pm/stream_data/ExUnitProperties.html#check/1-options), using random data each time.
When a test fails, StreamData will try to [shrink](https://hexdocs.pm/stream_data/StreamData.html#module-shrinking) the input to the smallest value that causes the test failure.
This can be helpful when you have to debug your code!
If a 50-element list causes your function to break, and only one of the list elements is problematic, StreamData can help you identify the offending element.

This testing library has two main modules.
[`StreamData`](https://hexdocs.pm/stream_data/StreamData.html) generates streams of random data.
[`ExUnitProperties`](https://hexdocs.pm/stream_data/ExUnitProperties.html) lets you run tests against your functions, using the generated data as your input.

You might be asking how you can say anything meaningful about a function if you don't know what your exact inputs are. Read on!

## Installing StreamData

First, create a new Mix project.
Refer to [New Projects](https://elixirschool.com/en/lessons/basics/mix/#new-projects) if you need some help.

Second, add StreamData as a dependency to your `mix.exs` file:

```elixir
defp deps do
  [{:stream_data, "~> x.y", only: :test}]
end
```

Just replace `x` and `y` with the version of StreamData shown in the library's [installation instructions](https://github.com/whatyouhide/stream_data#installation).

Third, run this from the command line of your terminal:

```shell
mix deps.get
```

## Using StreamData

To illustrate the features of StreamData, we'll write a few simple utility functions that repeat values.
Let's say we want a function like [`String.duplicate/2`](https://hexdocs.pm/elixir/String.html#duplicate/2), but one that will duplicate strings, lists, or tuples.

### Strings

First, let's write a function that duplicates strings.
What are some requirements for our function?

1. The first argument should be a string.
This is the string that we'll duplicate.
2. The second argument should be a non-negative integer.
It shows how many times we'll duplicate the first argument.
3. The function should return a string.
This new string is just the original string, repeated zero or more times.
4. If the original string is empty, the returned string should also be empty.
5. If the second argument is `0`, the returned string should be empty.

When we run our function, we want it to look like this:

```elixir
Repeater.duplicate("a", 4)
# "aaaa"
```

Elixir has a function, `String.duplicate/2` that will handle this for us.
Our new `duplicate/2` will just delegate to that function:

```elixir
defmodule Repeater do
  def duplicate(string, times) when is_binary(string) do
    String.duplicate(string, times)
  end
end
```

The happy path should be easy to test with [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html).

```elixir
defmodule RepeaterTest do
  use ExUnit.Case

  describe "duplicate/2" do
    test "creates a new string, with the first argument duplicated a specified number of times" do
      assert "aaaa" == Repeater.duplicate("a", 4)
    end
  end
end
```

That's hardly a comprehensive test, though.
What should happen when the second argument is `0`?
What should the output be when the first argument is an empty string?
What does it even mean to repeat an empty string?
How should the function work with UTF-8 characters?
Will the function still work with large input strings?

We could write more examples to test edge cases and large strings.
However, let's see if we can use StreamData to test this function more rigorously without much more code.

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "creates a new string, with the first argument duplicated a specified number of times" do
      check all str <- string(:printable),
                times <- integer(),
                times >= 0 do

        assert ??? == Repeater.duplicate(str, times)
      end
    end
  end
end
```

What does that do?

* We replaced `test` with [`property`](https://github.com/whatyouhide/stream_data/blob/v0.4.2/lib/ex_unit_properties.ex#L109).
This lets us document the property we're testing.
* [`check/1`](https://hexdocs.pm/stream_data/ExUnitProperties.html#check/1) is a macro that allows us to set up the data we'll use in the test.
* [`StreamData.string/2`](https://hexdocs.pm/stream_data/StreamData.html#string/2) generates random strings.
We can omit the module name when calling `string/2` because `use ExUnitProperties` [imports StreamData functions](https://github.com/whatyouhide/stream_data/blob/v0.4.2/lib/ex_unit_properties.ex#L109).
* `StreamData.integer/0` generates random integers.
* `times >= 0` is kind of like a guard clause.
It ensures that the random integers we use in our test are greater than or equal to zero.
[`SreamData.positive_integer/0`](https://hexdocs.pm/stream_data/StreamData.html#positive_integer/0) exists, but it's not quite what we want, since `0` is an acceptable value in our function.

The `???` is just some pseudocode I added.
What exactly should we assert?
We _could_ write:

```elixir
assert String.duplicate(str, times) == Repeater.duplicate(str, times)
```

...but that just uses the actual function's implementation, which isn't helpful.
We could loosen up our assertion by only verifying the length of the string:

```elixir
expected_length = String.length(str) * times
actual_length =
  str
  |> Repeater.duplicate(times)
  |> String.length()

assert actual_length == expected_length
```

That's better than nothing, but it's not ideal.
This test would still pass if our function generated random strings of the correct length.

We really want to verify two things:

1. Our function generates a string of the right length.
2. The contents of the final string are the original string repeated over and over again.

This is just another way of [rephrasing the property](https://www.propertesting.com/book_what_is_a_property.html#_alternate_wording_of_properties).
We already have some code to verify #1.
To verify #2, let's split the final string by the original string, and verify that we are left with a list of zero or more empty strings.

```elixir
list =
  str
  |> Repeater.duplicate(times)
  |> String.split(str)

assert Enum.all?(list, &(&1 == ""))
```

Let's combine our assertions:

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "creates a new string, with the first argument duplicated a specified number of times" do
      check all str <- string(:printable),
                times <- integer(),
                times >= 0 do
        new_string = Repeater.duplicate(str, times)

        assert String.length(new_string) == String.length(str) * times
        assert Enum.all?(String.split(new_string, str), &(&1 == ""))
      end
    end
  end
end
```

When we compare that with our original test, we see that the StreamData version is twice as long.
However, by the time you add more test cases to the original test...

```elixir
defmodule RepeaterTest do
  use ExUnit.Case

  describe "duplicating a string" do
    test "duplicates the first argument a number of times equal to the second argument" do
      assert "aaaa" == Repeater.duplicate("a", 4)
    end

    test "returns an empty string if the first argument is an empty string" do
      assert "" == Repeater.duplicate("", 4)
    end

    test "returns an empty string if the second argument is zero" do
      assert "" == Repeater.duplicate("a", 0)
    end

    test "works with longer strings" do
      alphabet = "abcdefghijklmnopqrstuvwxyz"

      assert "#{alphabet}#{alphabet}" == Repeater.duplicate(alphabet, 2)
    end
  end
end
```

...the StreamData version is actually shorter.
StreamData also covers edge cases a developer might forget to test.

### Lists

Now, let's write a function that repeats lists.
We want the function to work like this:

```elixir
Repeater.duplicate([1, 2, 3], 3)
# [1, 2, 3, 1, 2, 3, 1, 2, 3]
```

Here is a correct, but somewhat inefficient, implementation:

```elixir
defmodule Repeater do
  def duplicate(list, 0) when is_list(list) do
    []
  end

  def duplicate(list, times) when is_list(list) do
    list ++ duplicate(list, times - 1)
  end
end
```

A StreamData test might look like this:

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "creates a new list, with the elements of the original list repeated a specified number or times" do
      check all list <- list_of(term()),
                times <- integer(),
                times >= 0 do
        new_list = Repeater.duplicate(list, times)

        assert length(new_list) == length(list) * times

        if length(list) > 0 do
          assert Enum.all?(Enum.chunk_every(new_list, length(list)), &(&1 == list))
        end
      end
    end
  end
end
```

We used `StreamData.list_of/1` and `StreamData.term/0` to create lists of random length, whose elements are any type.

Like the property-based test for repeating strings, we compare the length of the new list with the product of the source list and `times`.
The second assertion takes some explaining:

1. We break the new list apart into several lists, each of which has the same number of elements as `list`.
2. We then verify that each chunked list is equal to `list`.

To put it differently, we make sure that our original list appears in the final list the right number of times, and that no _other_ elements show up in our final list.

Why did we use the conditional?
The first assertion and the conditional combine to tell us that the original list and the final list are both empty, so there is no need to do any more list comparison.
Moreover, `Enum.chunk_every/2` requires the second argument to be positive.

### Tuples

Finally, let's implement a function that repeats the elements of a tuple.
The function should work like this:

```elixir
Repeater.duplicate({:a, :b, :c}, 3)
# {:a, :b, :c, :a, :b, :c, :a, :b, :c}
```

One way we could approach this is to convert the tuple to a list, duplicate the list, and convert the data structure back to a tuple.

```elixir
defmodule Repeater do
  def duplicate(tuple, times) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> Repeater.duplicate(times)
    |> List.to_tuple()
  end
end
```

How might we test this?
Let's approach it a bit differently than we've done so far.
For strings and lists, we asserted something about the length of the final data, and we asserted something about the contents of the data.
Trying the same approach with tuples is possible, but the test code may not be as straightforward.

Consider two sequences of operations you could perform on a tuple:

1. Call `Repeater.duplicate/2` on the tuple, and convert the result to a list
2. Convert the tuple to a list, and then pass the list to `Repeater.duplicate/2`

This is an application of a pattern that Scott Wlaschin calls ["Different Paths, Same Destination"](https://fsharpforfunandprofit.com/posts/property-based-testing-2/#different-paths-same-destination).
I would expect both of these sequences of operations to yield the same result.
Let's use that approach in our test.

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "creates a new tuple, with the elements of the original tuple repeated a specified number of times" do
      check all t <- tuple({term()}),
                times <- integer(),
                times >= 0 do
        result_1 =
          t
          |> Repeater.duplicate(times)
          |> Tuple.to_list()

        result_2 =
          t
          |> Tuple.to_list()
          |> Repeater.duplicate(times)

        assert result_1 == result_2
      end
    end
  end
end
```

## Summary

We now have three function clauses that repeat strings, list elements, and tuple elements.
We have some property-based tests that give us a high degree of confidence that our implementation is correct.

Here is our final application code:

```elixir
defmodule Repeater do
  def duplicate(string, times) when is_binary(string) do
    String.duplicate(string, times)
  end

  def duplicate(list, 0) when is_list(list) do
    []
  end

  def duplicate(list, times) when is_list(list) do
    list ++ duplicate(list, times - 1)
  end

  def duplicate(tuple, times) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> Repeater.duplicate(times)
    |> List.to_tuple()
  end
end
```

Here are the property-based tests:

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "creates a new string, with the first argument duplicated a specified number of times" do
      check all str <- string(:printable),
                times <- integer(),
                times >= 0 do
        new_string = Repeater.duplicate(str, times)

        assert String.length(new_string) == String.length(str) * times
        assert Enum.all?(String.split(new_string, str), &(&1 == ""))
      end
    end

    property "creates a new list, with the elements of the original list repeated a specified number or times" do
      check all list <- list_of(term()),
                times <- integer(),
                times >= 0 do
        new_list = Repeater.duplicate(list, times)

        assert length(new_list) == length(list) * times

        if length(list) > 0 do
          assert Enum.all?(Enum.chunk_every(new_list, length(list)), &(&1 == list))
        end
      end
    end

    property "creates a new tuple, with the elements of the original tuple repeated a specified number of times" do
      check all t <- tuple({term()}),
                times <- integer(),
                times >= 0 do
        result_1 =
          t
          |> Repeater.duplicate(times)
          |> Tuple.to_list()

        result_2 =
          t
          |> Tuple.to_list()
          |> Repeater.duplicate(times)

        assert result_1 == result_2
      end
    end
  end
end
```

You can run your tests by entering this on your terminal's command line:

```shell
mix test
```

Remember that each StreamData test you write will run 100 times by default.
Additionally, some of StreamData's random data takes longer to generate than others.
The cumulative effect is that these types of tests will run more slowly than example-based unit tests.

Even so, property-based testing is a nice complement to example-based unit testing.
It allows us to write succinct tests that cover a wide variety of inputs.
If you don't need to maintain state between test runs, StreamData offers a nice syntax to write property-based tests.
