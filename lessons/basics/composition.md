---
layout: page
title: Composition
category: basics
order: 7
---

We know from experience its unruly to have all of our functions in the same file and scope.  In this lesson we're going to cover how to group functions and define a specialized map known as a struct in order to organize our code more efficiently.

## Table of Contents

- [Modules](#modules)
  - [Module attributes](#module-attributes)
- [Structs](#structs)

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
+ `behaviour` — Use an OTP or use-defined behaviour.

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
%Example.User{name: "Steve", roles: [:admin]}

iex> %Example.User{name: "Steve", roles: [:admin, :owner]}
%Example.User{name: "Steve", roles: [:admin, :owner]}
```

We can update our struct just like we would a map:

```elixir
iex> steve = %Example.User{name: "Steve", roles: [:admin, :owner]}
%Example.User{name: "Steve", roles: [:admin, :owner]}
iex> sean = %{steve | name: "Sean"}
%Example.User{name: "Sean", password: nil, roles: [:admin, :owner]}
```

Most importantly, you can match structs against maps:

```elixir
iex(12)> %{name: "Sean"} = sean
%Example.User{name: "Sean", password: nil, roles: [:admin, :owner]}
```

