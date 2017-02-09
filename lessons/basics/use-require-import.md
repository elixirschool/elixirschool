---
layout: page
title: Use, Require & Import
category: basics
order: 16
lang: en
---

In Elixir, we commonly use several macros that give us some built-in conveniences to pull in functionality from other parts of our code.
The most common of these are `import`, `require`, and `use`.
These keywords all sound very similar, but do quite different things in action when we utilize them.
In this lesson we will investigate how each of these works.

{% include toc.html %}

## Import
Import brings in functions and macros from other modules.
If we are using several functions from a given module, we could import it to not have to call it repeatedly and instead be able to just make a local call.
For example:

```elixir
iex> List.flatten([[1, 2, 3], [4, 5, 6]])
[1, 2, 3, 4, 5, 6]
iex> import List
List
iex> flatten([[1, 2, 3], [4, 5, 6]])
[1, 2, 3, 4, 5, 6]
```

This is most common when we simply just dont want be forced into continuously calling the same module and we are using its functions quite a bit.
We can also filter to import only macros or functions with the `only` option:

```elixir
iex> import List, only: :macros
iex> flatten([[1, 2], [3, 4]])
** (CompileError) iex:2: undefined function flatten/1
```

This fails because we only imported the macros, not the functions.
If instead we grabbed the functions:

```elixir
iex> import List, only: :functions
iex> flatten([[1, 2], [3, 4]])
[1, 2, 3, 4]
```

The `import` macro is also lexical.
You can import specific macros inside of a given function because of this.
The documentation has a great simple example:

```elixir
defmodule Math do
  def some_function do
    # 1) Disable "if/2" from Kernel
    import Kernel, except: [if: 2]

    # 2) Require the new "if/2" macro from MyMacros
    import MyMacros

    # 3) Use the new macro
    if do_something, it_works
  end
end
```

And with this simple import we can use our own specially created `if` macro if we had defined it in `MyMacros`.

## Use
`use` uses a module that is given to it in the current context.
This is a very useful macro for building up composable, reuseable modules.
The most common use case a beginning use would see is in ExUnit.
If we generate a new mix project, we get a boilerplate test that looks something like this:

```elixir
defmodule FooTest do
  use ExUnit.Case
  doctest Foo

  test "the truth" do
    assert 1 + 1 == 2
  end
end
```

As you can see in line 2, we have `use ExUnit.Case`.
This imports all the common pieces needed for a test module to behave the way mix needs it to in order to interact with it.
We could define our own module to include that wraps this so we could call it in a different way to be included.

```elixir
# test/foo_test.exs
defmodule TestWrapper do
  defmacro __using__ do
    quote do
      use ExUnit.Case, async: true
      @some_attributes "foobar"
    end
  end
end

defmodule FooTest do
  use TestWrapper

  test "the truth" do
    1 + 1 == 2
  end
end
```

And we could verify it words by simply running our tests:

```shell
$ mix test
Compiling 1 file (.ex)
Generated foo app
.

Finished in 0.03 seconds
1 test, 0 failures

Randomized with seed 623983
```
We should not use `use` when we are simply importing functions.
In this case `alias` or `require` is more appropriate.
An example from the documentation of what _not_ to do:

```elixir
defmodule MyModule do
  defmacro __using__(opts) do
    quote do
      import MyModule
    end
  end
end
```

## Require
`require` requires a given module for compilation and loading.
Usually a module shouldnt be required before usage, unless youre calling macros from it.
A common example of this is `IEx` and `IEx.pry`.
`require/2` accepts an `as:` option to automatically set up an alias, as well.
