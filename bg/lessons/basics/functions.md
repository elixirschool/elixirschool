---
layout: page
title: Functions
category: basics
order: 7
lang: bg
---

In Elixir and many functional languages, functions are first class citizens.  We will learn about the types of functions in Elixir, what makes them different, and how to use them.

{% include toc.html %}

## Anonymous functions

Just as the name implies, an anonymous function has no name.  As we saw in the `Enum` lesson, they are frequently passed to other functions.  To define an anonymous function in Elixir we need the `fn` and `end` keywords.  Within these we can define any number of parameters and function bodies separated by `->`.

Let's look at a basic example:

```elixirre
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### The & shorthand

Using anonymous functions is such a common practice in Elixir there is shorthand for doing so:

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

As you probably already guessed, in the shorthand version our parameters are available to us as `&1`, `&2`, `&3`, and so on.

## Pattern matching

Pattern matching isn't limited to just variables in Elixir, it can be applied to function signatures as we will see in this section.

Elixir uses pattern matching to identify the first set of parameters which match and invokes the corresponding body:

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
iex> handle_result.({:ok, some_result})
Handling result...

iex> handle_result.({:error})
An error has occurred!
```

## Named functions

We can define functions with names so we can refer to them later, these named functions are defined with the `def` keyword within a module.  We'll learn more about Modules in the next lessons, for now we'll focus on the named functions alone.

Functions defined within a module are available to other modules for use, this is a particularly useful building block in Elixir:

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

If our function body only spans one line, we can shorten it further with `do:`:

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

Armed with our knowledge of pattern matching, let's explore recursion using named functions:

```elixir
defmodule Length do
  def of([]), do: 0
  def of([_|t]), do: 1 + of(t)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### Private functions

When we don't want other modules accessing a function we can use private functions, which can only be called within their Module.  We can define them in Elixir with `defp`:

```elixir
defmodule Greeter do
  def hello(name), do: phrase <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) undefined function: Greeter.phrase/0
    Greeter.phrase()
```

### Guards

We briefly covered guards in the [Control Structures](../control-structures.md) lesson, now we'll see how we can apply them to named functions.  Once Elixir has matched a function any existing guards will be tested.

In the follow example we have two functions with the same signature, we rely on guards to determine which to use based on the argument's type:

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase <> name
  end

  defp phrase, do: "Hello, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"
```

### Default arguments

If we want a default value for an argument we use the `argument \\ value` syntax:

```elixir
defmodule Greeter do
  def hello(name, country \\ "en") do
    phrase(country) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello("Sean", "en")
"Hello, Sean"

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.hello("Sean", "es")
"Hola, Sean"
```

When we combine our guard example with default arguments, we run into an issue.  Let's see what that might look like:

```elixir
defmodule Greeter do
  def hello(names, country \\ "en") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(country)
  end

  def hello(name, country \\ "en") when is_binary(name) do
    phrase(country) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) def hello/2 has default values and multiple clauses, define a function head with the defaults
```

Elixir doesn't like default arguments in multiple matching functions, it can be  confusing.  To handle this we add a function head with our default arguments:

```elixir
defmodule Greeter do
  def hello(names, country \\ "en")
  def hello(names, country) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(country)
  end

  def hello(name, country) when is_binary(name) do
    phrase(country) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "es"
"Hola, Sean, Steve"
```
