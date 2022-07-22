%{
  version: "1.3.0",
  title: "Functions",
  excerpt: """
  In Elixir and many functional languages, functions are first class citizens.
  We will learn about the types of functions in Elixir, what makes them different, and how to use them.
  """
}
---

## Anonymous Functions

Just as the name implies, an anonymous function has no name.
As we saw in the `Enum` lesson, these are frequently passed to other functions.
To define an anonymous function in Elixir we need the `fn` and `end` keywords.
Within these we can define any number of parameters and function bodies separated by `->`.

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

Elixir uses pattern matching to check through all possible match options and select the first matching option to run:

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:ok, _} -> IO.puts "This would be never run as previous will be matched beforehand."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
1
iex> handle_result.({:ok, some_result})
Handling result...
:ok
iex> handle_result.({:error})
An error has occurred!
:ok
```

## Named Functions

We can define functions with names so we can easily refer to them later.
Named functions are defined within a module using the `def` keyword .
We'll learn more about Modules in the next lessons, for now we'll focus on the named functions alone.

Functions defined within a module are available to other modules for use.
This is a particularly useful building block in Elixir:

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

We mentioned earlier that functions are named by the combination of given name and arity (number of arguments).
This means you can do things like this:

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

We've listed the function names in comments above.
The first implementation takes no arguments, so it is known as `hello/0`; the second takes one argument so it is known as `hello/1`, and so on.
Unlike function overloads in some other languages, these are thought of as _different_ functions from each other.
(Pattern matching, described just a moment ago, applies only when multiple definitions are provided for function definitions with the _same_ number of arguments.)

### Functions and Pattern Matching

Behind the scenes, functions are pattern-matching the arguments that they're called with.

Say we needed a function to accept a map but we're only interested in using a particular key.
We can pattern-match the argument on the presence of that key like this:

```elixir
defmodule Greeter1 do
  def hello(%{name: person_name}) do
    IO.puts "Hello, " <> person_name
  end
end
```

Now let's say we have a map describing a person named Fred:

```elixir
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"
...> }
```

These are the results we'll get when we call `Greeter1.hello/1` with the `fred` map:

```elixir
# call with entire map
...> Greeter1.hello(fred)
"Hello, Fred"
```

What happens when we call the function with a map that _doesn't_ contain the `:name` key?

```elixir
# call without the key we need returns an error
...> Greeter1.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter1.hello/1

    The following arguments were given to Greeter1.hello/1:

        # 1
        %{age: "95", favorite_color: "Taupe"}

    iex:12: Greeter1.hello/1

```

The reason for this behavior is that Elixir pattern-matches the arguments that a function is called with against the arity the function is defined with.

Let's think about how the data looks when it arrives to `Greeter1.hello/1`:

```Elixir
# incoming map
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"
...> }
```

`Greeter1.hello/1` expects an argument like this:

```elixir
%{name: person_name}
```

In `Greeter1.hello/1`, the map we pass (`fred`) is evaluated against our argument (`%{name: person_name}`):

```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

It finds that there is a key that corresponds to `name` in the incoming map.
We have a match! And as a result of this successful match, the value of the `:name` key in the map on the right (i.e. the `fred` map) is bound to the variable on the left (`person_name`).

Now, what if we still wanted to assign Fred's name to `person_name` but we ALSO want to retain awareness of the entire person map? Let's say we want to `IO.inspect(fred)` after we greet him.
At this point, because we only pattern-matched the `:name` key of our map, thus only binding the value of that key to a variable, the function doesn't have knowledge of the rest of Fred.

In order to retain it, we need to assign that entire map to its own variable for us to be able to use it.

Let's start a new function:

```elixir
defmodule Greeter2 do
  def hello(%{name: person_name} = person) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

Remember that Elixir will pattern match the argument as it comes in.
Therefore in this case, each side will pattern match against the incoming argument and bind to whatever it matches with.
Let's take the right side first:

```elixir
person = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Now, `person` has been evaluated and bound to the entire fred-map.
We move on to the next pattern-match:

```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Now this is the same as our original `Greeter1` function where we pattern matched the map and only retained Fred's name.
What we've achieved is two variables we can use instead of one:

1. `person`, referring to `%{name: "Fred", age: "95", favorite_color: "Taupe"}`
2. `person_name`, referring to `"Fred"`

So now when we call `Greeter2.hello/1`, we can use all of Fred's information:

```elixir
# call with entire person
...> Greeter2.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}
# call with only the name key
...> Greeter2.hello(%{name: "Fred"})
"Hello, Fred"
%{name: "Fred"}
# call without the name key
...> Greeter2.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter2.hello/1

    The following arguments were given to Greeter2.hello/1:

        # 1
        %{age: "95", favorite_color: "Taupe"}

    iex:15: Greeter2.hello/1
```

So we've seen that Elixir pattern-matches at multiple depths because each argument matches against the incoming data independently, leaving us with the variables to call them by inside our function.

If we switch the order of `%{name: person_name}` and `person` in the list, we will get the same result because each are matching to fred on their own.

We swap the variable and the map:

```elixir
defmodule Greeter3 do
  def hello(person = %{name: person_name}) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

And call it with the same data we used in `Greeter2.hello/1`:

```elixir
# call with same old Fred
...> Greeter3.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}
```

Remember that even though it looks like `%{name: person_name} = person` is pattern-matching the `%{name: person_name}` against the `person` variable, they're actually _each_ pattern-matching to the passed-in argument.

**Summary:** Functions pattern-match the data passed in to each of its arguments independently.
We can use this to bind values to separate variables within the function.

### Private Functions

When we don't want other modules accessing a specific function we can make the function private.
Private functions can only be called from within their own Module.
We define them in Elixir with `defp`:

```elixir
defmodule Greeter do
  def hello(name), do: phrase() <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### Guards

We briefly covered guards in the [Control Structures](/en/lessons/basics/control_structures) lesson, now we'll see how we can apply them to named functions.
Once Elixir has matched a function any existing guards will be tested.

In the following example we have two functions with the same signature, we rely on guards to determine which to use based on the argument's type:

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names = Enum.join(names, ", ")
    
    hello(names)
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

When we combine our guard example with default arguments, we run into an issue.
Let's see what that might look like:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en") when is_list(names) do
    names = Enum.join(names, ", ")
    
    hello(names, language_code)
  end

  def hello(name, language_code \\ "en") when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) iex:8: def hello/2 defines defaults multiple times. Elixir allows defaults to be declared once per definition.
Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b \\ :default) do ... end

one should write:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end
```

Elixir doesn't like default arguments in multiple matching functions, it can be confusing.
To handle this we add a function head with our default arguments:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en")

  def hello(names, language_code) when is_list(names) do
    names = Enum.join(names, ", ")

    hello(names, language_code)
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
