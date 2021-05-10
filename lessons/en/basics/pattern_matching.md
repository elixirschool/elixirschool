%{
  version: "1.0.2",
  title: "Pattern Matching",
  excerpt: """
  Pattern matching is a powerful part of Elixir. It allows us to match simple values, data structures, and even functions.
  In this lesson we will begin to see how pattern matching is used.
  """
}
---

## Match Operator

Are you ready for a curveball? In Elixir, the `=` operator is actually a match operator, comparable to the equals sign in algebra. Writing it turns the whole expression into an equation and makes Elixir match the values on the left hand with the values on the right hand. If the match succeeds, it returns the value of the equation. Otherwise, it throws an error. Let's take a look:

```elixir
iex> x = 1
1
```

Now let's try some simple matching:

```elixir
iex> 1 = x
1
iex> 2 = x
** (MatchError) no match of right hand side value: 1
```

Let's try that with some of the collections we know:

```elixir
# Lists
iex> list = [1, 2, 3]
[1, 2, 3]
iex> [1, 2, 3] = list
[1, 2, 3]
iex> [] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

iex> [1 | tail] = list
[1, 2, 3]
iex> tail
[2, 3]
iex> [2 | _] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

# Tuples
iex> {:ok, value} = {:ok, "Successful!"}
{:ok, "Successful!"}
iex> value
"Successful!"
iex> {:ok, value} = {:error}
** (MatchError) no match of right hand side value: {:error}
```

## Pin Operator

The match operator performs assignment when the left side of the match includes a variable.
In some cases this variable rebinding behavior is undesirable.
For these situations we have the pin operator: `^`.

When we pin a variable we match on the existing value rather than rebinding to a new one.
Let's take a look at how this works:

```elixir
iex> x = 1
1
iex> ^x = 2
** (MatchError) no match of right hand side value: 2
iex> {x, ^x} = {2, 1}
{2, 1}
iex> x
2
```

Elixir 1.2 introduced support for pins in map keys and function clauses:

```elixir
iex> key = "hello"
"hello"
iex> %{^key => value} = %{"hello" => "world"}
%{"hello" => "world"}
iex> value
"world"
iex> %{^key => value} = %{:hello => "world"}
** (MatchError) no match of right hand side value: %{hello: "world"}
```

An example of pinning in a function clause:

```elixir
iex> greeting = "Hello"
"Hello"
iex> greet = fn
...>   (^greeting, name) -> "Hi #{name}"
...>   (greeting, name) -> "#{greeting}, #{name}"
...> end
#Function<12.54118792/2 in :erl_eval.expr/5>
iex> greet.("Hello", "Sean")
"Hi Sean"
iex> greet.("Mornin'", "Sean")
"Mornin', Sean"
iex> greeting
"Hello"
```

Note in the `"Mornin'"` example that the reassignment of `greeting` to `"Mornin'"` only happens inside the function. Outside of the function `greeting` is still `"Hello"`.
