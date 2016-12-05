---
layout: page
title: Pipe Operator 
category: basics
order: 7
lang: vi 
---

The pipe operator `|>` passes the result of an expression as the first parameter of another expression.

{% include toc.html %}

## Introduction

Programming can get messy. So messy in fact that function calls can get so embedded the function calls becomes very difficult to follow. Take the following nested functions into consideration:

```elixir
foo(bar(baz(new_function(other_function()))))
```

Here, we are passing the value `other_function/1` to `new_function/1`, and `new_function/1` to `baz/1`, `baz/1` to `bar/1`, and finally the result of `bar/1` to `foo/1`. Elixir takes a pragmatic approach to this syntactical chaos by giving us the pipe operator. The pipe operator which looks like `|>` *takes the result of one expression, and passes it on*. Let's take another look at the code snippet above rewritten with the pipe operator.

```elixir
other_function() |> new_function() |> baz() |> bar() |> foo()
```

The pipe takes the result on the left, and passes it to the right hand side.

## Examples

For this set of examples, we will use Elixir's String module.

- Tokenize String (loosely)

```shell
iex> "Elixir rocks" |> String.split
["Elixir", "rocks"]
```

- Uppercase all the tokens

```shell
iex> "Elixir rocks" |> String.upcase |> String.split
["ELIXIR", "ROCKS"]
```

- Check ending

```shell
iex> "elixir" |> String.ends_with?("ixir")
true
```

## Best Practices

If the arity of a function is more than 1, then make sure to use parenthesis. This doesn't matter much to the Elixir compiler, but it matters to other programmers who may misinterpret your code. If we take our 2nd example, and remove the brackets from `Enum.map/2`, we are met with the following warning.

```shell
iex> "Elixir rocks" |> String.split |> Enum.map &String.upcase/1
iex: warning: you are piping into a function call without parentheses, which may be ambiguous. Please wrap the function you are piping into in parenthesis. For example:

foo 1 |> bar 2 |> baz 3

Should be written as:

foo(1) |> bar(2) |> baz(3)

["ELIXIR", "ROCKS"]
```

