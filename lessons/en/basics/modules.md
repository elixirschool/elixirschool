%{
  version: "1.4.1",
  title: "Modules",
  excerpt: """
  We know from experience it's unruly to have all of our functions in the same file and scope.
  In this lesson we're going to cover how to group functions and define a specialized map known as a struct in order to organize our code more efficiently.
  """
}
---

## Modules

Modules allow us to organize functions into a namespace.
In addition to grouping functions, they allow us to define named and private functions which we covered in the [functions lesson](/en/lessons/basics/functions).

Let's look at a basic example:

```elixir
defmodule Example do
  def greeting(name) do
    "Hello #{name}."
  end
end

iex> Example.greeting "Sean"
"Hello Sean."
```

It is possible to nest modules in Elixir, allowing you to further namespace your functionality:

```elixir
defmodule Example.Greetings do
  def morning(name) do
    "Good morning #{name}."
  end

  def evening(name) do
    "Good night #{name}."
  end
end

iex> Example.Greetings.morning "Sean"
"Good morning Sean."
```

### Module Attributes

Module attributes are most commonly used as constants in Elixir.
Let's look at a simple example:

```elixir
defmodule Example do
  @greeting "Hello"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

It is important to note there are reserved attributes in Elixir.
The three most common are:

- `moduledoc` — Documents the current module.
- `doc` — Documentation for functions and macros.
- `behaviour` — Use an OTP or user-defined behaviour.

## Structs

Structs are special maps with a defined set of keys and default values.
A struct must be defined within a module, which it takes its name from.
It is common for a struct to be the only thing defined within a module.

To define a struct we use `defstruct` along with a keyword list of fields and default values:

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

Let's create some structs:

```elixir
iex> %Example.User{}
%Example.User<name: "Sean", roles: [], ...>

iex> %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [], ...>

iex> %Example.User{name: "Steve", roles: [:manager]}
%Example.User<name: "Steve", roles: [:manager]>
```

We can update our struct just like we would a map:

```elixir
iex> steve = %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [...], ...>
iex> sean = %{steve | name: "Sean"}
%Example.User<name: "Sean", roles: [...], ...>
```

Most importantly, you can match structs against maps:

```elixir
iex> %{name: "Sean"} = sean
%Example.User<name: "Sean", roles: [...], ...>
```

As of Elixir 1.8 structs include custom introspection.
To understand what this means and how we are to use it let us inspect our `sean` capture:

```elixir
iex> inspect(sean)
"%Example.User<name: \"Sean\", roles: [...], ...>"
```

All of our fields are present which is okay for this example but what if we had a protected field we didn't want to include?
The new `@derive` feature let's us accomplish just this!
Let's update our example so `roles` are no longer included in our output:

```elixir
defmodule Example.User do
  @derive {Inspect, only: [:name]}
  defstruct name: nil, roles: []
end
```

_Note_: we could also use `@derive {Inspect, except: [:roles]}`, they are equivalent.

With our updated module in place let's take a look at what happens in `iex`:

```elixir
iex> sean = %Example.User{name: "Sean"}
%Example.User<name: "Sean", ...>
iex> inspect(sean)
"%Example.User<name: \"Sean\", ...>"
```

The `roles` are excluded from output!

## Composition

Now that we know how to create modules and structs let's learn how to add existing functionality to them via composition.
Elixir provides us with a variety of different ways to interact with other modules.

### alias

Allows us to alias module names; used quite frequently in Elixir code:

```elixir
defmodule Sayings.Greetings do
  def basic(name), do: "Hi, #{name}"
end

defmodule Example do
  alias Sayings.Greetings

  def greeting(name), do: Greetings.basic(name)
end

# Without alias

defmodule Example do
  def greeting(name), do: Sayings.Greetings.basic(name)
end
```

If there's a conflict between two aliases or we just wish to alias to a different name entirely, we can use the `:as` option:

```elixir
defmodule Example do
  alias Sayings.Greetings, as: Hi

  def print_message(name), do: Hi.basic(name)
end
```

It's even possible to alias multiple modules at once:

```elixir
defmodule Example do
  alias Sayings.{Greetings, Farewells}
end
```

### import

If we want to import functions rather than aliasing the module we can use `import`:

```elixir
iex> last([1, 2, 3])
** (CompileError) iex:9: undefined function last/1
iex> import List
nil
iex> last([1, 2, 3])
3
```

#### Filtering

By default all functions and macros are imported but we can filter them using the `:only` and `:except` options.

To import specific functions and macros, we must provide the name/arity pairs to `:only` and `:except`.
Let's start by importing only the `last/1` function:

```elixir
iex> import List, only: [last: 1]
iex> first([1, 2, 3])
** (CompileError) iex:13: undefined function first/1
iex> last([1, 2, 3])
3
```

If we import everything except `last/1` and try the same functions as before:

```elixir
iex> import List, except: [last: 1]
nil
iex> first([1, 2, 3])
1
iex> last([1, 2, 3])
** (CompileError) iex:3: undefined function last/1
```

In addition to the name/arity pairs there are two special atoms, `:functions` and `:macros`, which import only functions and macros respectively:

```elixir
import List, only: :functions
import List, only: :macros
```

### require

We could use `require` to tell Elixir you're going to use macros from another module.
The slight difference with `import` is that it allows using macros, but not functions from the specified module:

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

If we attempt to call a macro that is not yet loaded Elixir will raise an error.

### use

With the `use` macro we can enable another module to modify our current module's definition.
When we call `use` in our code we're actually invoking the `__using__/1` callback defined by the provided module.
The result of the `__using__/1` macro becomes part of our module's definition.
To get a better understanding how this works let's look at a simple example:

```elixir
defmodule Hello do
  defmacro __using__(_opts) do
    quote do
      def hello(name), do: "Hi, #{name}"
    end
  end
end
```

Here we've created a `Hello` module that defines the `__using__/1` callback inside of which we define a `hello/1` function.
Let's create a new module so we can try out our new code:

```elixir
defmodule Example do
  use Hello
end
```

If we try our code out in IEx we'll see that `hello/1` is available on the `Example` module:

```elixir
iex> Example.hello("Sean")
"Hi, Sean"
```

Here we can see that `use` invoked the `__using__/1` callback on `Hello` which in turn added the resulting code to our module.
Now that we've demonstrated a basic example let's update our code to look at how `__using__/1` supports options.
We'll do this by adding a `greeting` option:

```elixir
defmodule Hello do
  defmacro __using__(opts) do
    greeting = Keyword.get(opts, :greeting, "Hi")

    quote do
      def hello(name), do: unquote(greeting) <> ", " <> name
    end
  end
end
```

Let's update our `Example` module to include the newly created `greeting` option:

```elixir
defmodule Example do
  use Hello, greeting: "Hola"
end
```

If we give it a try in IEx we should see that the greeting has been changed:

```elixir
iex> Example.hello("Sean")
"Hola, Sean"
```

These are simple examples to demonstrate how `use` works but it is an incredibly powerful tool in the Elixir toolbox.
As you continue to learn about Elixir keep an eye out for `use`, one example you're sure to see is `use ExUnit.Case, async: true`.

**Note**: `quote`, `alias`, `use`, `require` are macros related to [metaprogramming](/en/lessons/advanced/metaprogramming).
