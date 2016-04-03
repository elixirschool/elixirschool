---
layout: page
title: Composition
category: basics
order: 8
lang: en
---

We know from experience its unruly to have all of our functions in the same file and scope.  In this lesson we're going to cover how to group functions and define a specialized map known as a struct in order to organize our code more efficiently.

## Table of Contents

- [Modules](#modules)
  - [Module attributes](#module-attributes)
- [Structs](#structs)
- [Composition](#composition)
  - [`alias`](#alias)
  - [`import`](#import)
  - [`require`](#require)
  - [`use`](#use)

## Modules

Modules are the best way to organize functions into a namespace.  In addition to grouping functions, they allow us to define named and private functions which we covered in the previous lesson.

Let's look at a basic example:

``` elixir
defmodule Example do
  def greeting(name) do
    ~s(Hello #{name}.)
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

### Module attributes

Module attributes are most commonly used as constants in Elixir.  Let's take a look at a simple example:

```elixir
defmodule Example do
  @greeting "Hello"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

It is important to note there are reserved attributes in Elixir.  The three most common are:

+ `moduledoc` — Documents the current module.
+ `doc` — Documentation for functions and macros.
+ `behaviour` — Use an OTP or user-defined behaviour.

## Structs

Structs are special maps with a defined set of keys and default values.  It must be defined within a module, which it takes its name from.  It is common for a struct to be the only thing defined within a module.

To define a struct we use `defstruct` along with a keyword list of fields and default values:

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

Let's create some structs:

```elixir
iex> %Example.User{}
%Example.User{name: "Sean", roles: []}

iex> %Example.User{name: "Steve"}
%Example.User{name: "Steve", roles: []}

iex> %Example.User{name: "Steve", roles: [:admin, :owner]}
%Example.User{name: "Steve", roles: [:admin, :owner]}
```

We can update our struct just like we would a map:

```elixir
iex> steve = %Example.User{name: "Steve", roles: [:admin, :owner]}
%Example.User{name: "Steve", roles: [:admin, :owner]}
iex> sean = %{steve | name: "Sean"}
%Example.User{name: "Sean", roles: [:admin, :owner]}
```

Most importantly, you can match structs against maps:

```elixir
iex> %{name: "Sean"} = sean
%Example.User{name: "Sean", roles: [:admin, :owner]}
```

## Composition

Now that we know how to create modules and structs let's learn how to include existing functionality in them through composition.  Elixir provides us with a variety of different ways to interact with other modules, let's look at what we have available to us.

### `alias`

Allows us to alias module names, used quite frequently in Elixir code:

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
  def greeting(name), do: Saying.Greetings.basic(name)
end
```

If there's a conflict with two aliases or you just wish to alias to a different name entirely, we can use the `:as` option:

```elixir
defmodule Example do
  alias Sayings.Greetings, as: Hi

  def print_message(name), do: Hi.basic(name)
end
```

It's possible to alias multiple modules at once:

```elixir
defmodule Example do
  alias Sayings.{Greetings, Farewells}
end
```

### `import`

If we want to import functions and macros rather than aliasing the module we can use `import/`:

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

To import specific functions and macros, we must provide the name/arity pairs to `:only` and `:except`.  Let's start by importing only the `last/1` function:

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

In addition to the name/arty pairs there are two special atoms, `:functions` and `:macros`, which import only functions and macros respectively:

```elixir
import List, only: :functions
import List, only: :macros
```

### `require`

Although used less frequently `require/2` is nonetheless important.  Requiring a module ensures that it is compiled and loaded.  This is most useful when we need to access a module's macros:

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

If we attempt to call a macro that is not yet loaded Elixir will raise an error.

### `use`

Uses the module in the current context.  This is particularly useful when a module needs to perform some setup.  By calling `use` we invoke the `__using__` hook within the module, providing the module an opportunity to modify our existing context:

```elixir
defmodule MyModule do
  defmacro __using__(opts) do
    quote do
      import MyModule.Foo
      import MyModule.Bar
      import MyModule.Baz

      alias MyModule.Repo
    end
  end
end
```
