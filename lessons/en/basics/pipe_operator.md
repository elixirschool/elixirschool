%{
  version: "1.0.1",
  title: "Pipe Operator",
  excerpt: """
  The pipe operator `|>` passes the result of an expression as the first parameter of another expression.
  """
}
---

## Introduction

Programming can get messy.
So messy in fact that function calls can get so embedded that they become difficult to follow.
Take the following nested functions into consideration:

```elixir
foo(bar(baz(new_function(other_function()))))
```

Here, we are passing the value `other_function/0` to `new_function/1`, and `new_function/1` to `baz/1`, `baz/1` to `bar/1`, and finally the result of `bar/1` to `foo/1`.
Elixir takes a pragmatic approach to this syntactical chaos by giving us the pipe operator.
The pipe operator which looks like `|>` _takes the result of one expression, and passes it on_.
Let's take another look at the code snippet above rewritten using the pipe operator.

```elixir
other_function() |> new_function() |> baz() |> bar() |> foo()
```

The pipe takes the result on the left, and passes it to the right hand side.

## Examples

For this set of examples, we will use Elixir's String module.

- Tokenize String (loosely)

```elixir
iex> "Elixir rocks" |> String.split()
["Elixir", "rocks"]
```

- Uppercase all the tokens

```elixir
iex> "Elixir rocks" |> String.upcase() |> String.split()
["ELIXIR", "ROCKS"]
```

- Check ending

```elixir
iex> "elixir" |> String.ends_with?("ixir")
true
```

## Best Practices

If the arity of a function is more than 1, then make sure to use parentheses.
This doesn't matter much to Elixir, but it matters to other programmers who may misinterpret your code.
It does matter with the pipe operator though.
For example, if we take our third example, and remove the parentheses from `String.ends_with?/2`, we are met with the following warning.

```elixir
iex> "elixir" |> String.ends_with? "ixir"
warning: parentheses are required when piping into a function call.
For example:

  foo 1 |> bar 2 |> baz 3

is ambiguous and should be written as

  foo(1) |> bar(2) |> baz(3)

true
```
