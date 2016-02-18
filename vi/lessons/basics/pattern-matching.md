---
layout: page
title: Pattern Matching
category: basics
order: 4
lang: vi
---

Pattern matching is a powerful part of Elixir, it allows us to match simple values, data structures, and even functions.  In this lesson we will begin to see how pattern matching is used.

## Table of Contents

- [Match operator](#match-operator)
- [Pin operator](#pin-operator)

## Match operator

Are you ready for a curveball?  In Elixir, the `=` operator is actually our match operator.  Through the match operator we can assign and then match values, let's take a look:

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
iex> [1, 2, 3] = list
[1, 2, 3]
iex> [] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

iex> [1|tail] = list
[1, 2, 3]
iex> tail
[2, 3]
iex> [2|_] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

# Tuples
iex> {:ok, value} = {:ok, "Successful!"}
{:ok, "Successful!"}
iex> value
"Successful!"
iex> {:ok, value} = {:error}
** (MatchError) no match of right hand side value: {:error}
```

## Pin operator

We just learned the match operator handles assignment when the left side of the match includes a variable.  In some cases this behavior, variable rebinding, is undesirable.  For these situations, we have the pin operator: `^`.

When we pin a variable we match on the existing value rather than rebinding to a new one.  Let's take a look at how this works:

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
```
