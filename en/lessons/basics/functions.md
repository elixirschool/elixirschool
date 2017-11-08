---
version: 1.0.1
title: Functions
redirect_from:
  - /lessons/basics/functions/
---

In Elixir and many functional languages, functions are first class citizens.  We will learn about the types of functions in Elixir, what makes them different, and how to use them.

{% include toc.html %}

## Anonymous Functions

Just as the name implies, an anonymous function has no name.  As we saw in the `Enum` lesson, these are frequently passed to other functions.  To define an anonymous function in Elixir we need the `fn` and `end` keywords.  Within these we can define any number of parameters and function bodies separated by `->`.

Let's look at a basic example:

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### The & Shorthand

Using anonymous functions is such a common practice in Elixir there is shorthand for doing so:

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

As you probably already guessed, in the shorthand version our parameters are available to us as `&1`, `&2`, `&3`, and so on.

## Pattern Matching

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

## Named Functions

We can define functions with names so we can easily refer to them later.  Named functions are defined within a module using the `def` keyword .  We'll learn more about Modules in the next lessons, for now we'll focus on the named functions alone.

Functions defined within a module are available to other modules for use.  This is a particularly useful building block in Elixir:

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
  def of([_ | tail]), do: 1 + of(tail)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### Function Naming and Arity

We mentioned earlier that functions are named by the combination of given name and arity (number of arguments). This means you can do things like this:

```elixir
defmodule Greeter2 do
  def hello(), do: "Hello, anonymous person!"   # hello/0
  def hello(name), do: "Hello, " <> name        # hello/1
  def hello(name1, name2), do: "Hello, #{name1} and #{name2}"
                                                # hello/2
end

iex> Greeter2.hello()
"Hello, anonymous person!"
iex> Greeter2.hello("Fred")
"Hello, Fred"
iex> Greeter2.hello("Fred", "Jane")
"Hello, Fred and Jane"
```

We've listed the function names in comments above. The first implementation takes no arguments, so it is known as `hello/0`; the second takes one argument so it is known as `hello/1`, and so on. Unlike function overloads in some other languages, these are thought of as _different_ functions from each other. (Pattern matching, described just a moment ago, applies only when multiple definitions are provided for function definitions with the _same_ number of arguments.)

### Private Functions

When we don't want other modules accessing a specific function we can make the function private.  Private functions can only be called from within their own Module.  We define them in Elixir with `defp`:

```elixir
defmodule Greeter do
  def hello(name), do: phrase <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### Guards

We briefly covered guards in the [Control Structures](../control-structures) lesson, now we'll see how we can apply them to named functions.  Once Elixir has matched a function any existing guards will be tested.

In the following example we have two functions with the same signature, we rely on guards to determine which to use based on the argument's type:

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase() <> name
  end

  defp phrase, do: "Hello, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"
```

### Default Arguments

If we want a default value for an argument we use the `argument \\ value` syntax:

```elixir
defmodule Greeter do
  def hello(name, language_code \\ "en") do
    phrase(language_code) <> name
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
  def hello(names, language_code \\ "en") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code \\ "en") when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) iex:31: definitions with multiple clauses and default values require a header. Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b) do ... end

one should write:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end

def hello/2 has multiple clauses and defines defaults in one or more clauses
    iex:31: (module)
```

Elixir doesn't like default arguments in multiple matching functions, it can be  confusing.  To handle this we add a function head with our default arguments:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en")

  def hello(names, language_code) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code) when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "es"
"Hola, Sean, Steve"
```
