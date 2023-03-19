%{
  version: "1.0.3",
  title: "Specifications and types",
  excerpt: """
  In this lesson we will learn about `@spec` and `@type` syntax.
  `@spec` is more of a syntax complement for writing documentation that could be analyzed by tools.
  `@type` helps us write more readable and easier to understand code.
  """
}
---

## Introduction

It's not uncommon you would like to describe the interface of your function.
You could use [@doc annotation](/en/lessons/basics/documentation), but it is only information for other developers that is not checked in compilation time.
For this purpose Elixir has `@spec` annotation to describe the specification of a function that will be checked by compiler.

However in some cases specification is going to be quite big and complicated.
If you would like to reduce complexity, you want to introduce a custom type definition.
Elixir has the `@type` annotation for that.
On the other hand, Elixir is still a dynamic language.
That means all information about a type will be ignored by the compiler, but could be used by other tools.

## Specification

If you have experience with Java you could think about specification as an `interface`.
Specification defines what should be the type of a function's parameters and of its return value.

To define input and output types we use the `@spec` directive placed right before the function definition and taking as a `params` the name of the function, a list of parameter types, and after `::` the type of the return value.

Let's take a look at an example:

```elixir
@spec sum_product(integer) :: integer
def sum_product(a) do
  [1, 2, 3]
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
end
```

Everything looks ok and when we call it, a valid result will be returned, but the function `Enum.sum` returns a `number`, not an `integer` as we expected in `@spec`.
It could be a source of bugs! There are tools like Dialyzer to perform static analysis of code that helps us find this type of bug.
We will talk about them in another lesson.

## Custom types

Writing specifications is nice, but sometimes our functions work with more complex data structures than simple numbers or collections.
In that definition's case in `@spec` it could be hard to understand and/or change for other developers.
Sometimes functions need to take in a large number of parameters or return complex data.
A long parameters list is one of many potential bad smells in one's code.
In object-oriented languages like Ruby or Java we could easily define classes that help us solve this problem.
Elixir does not have classes but because it is easy to extend, we can define our own types.

Out of the box Elixir contains some basic types like `integer` or `pid`.
You  can find the full list of available types in the [documentation](https://hexdocs.pm/elixir/typespecs.html#types-and-their-syntax).

### Defining custom type

Let's modify our `sum_times` function and introduce some extra params:

```elixir
@spec sum_times(integer, %Examples{first: integer, last: integer}) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

We introduced a struct in the `Examples` module that contains two fields - `first` and `last`.
This is a simpler version of the struct from the `Range` module.
For more information on `structs`, please reference the section on [modules](/en/lessons/basics/modules#structs).
Let's imagine that we need a specification with an `Examples` struct in many places.
It would be annoying to write long, complex specifications and could be a source of bugs.
A solution to this problem is `@type`.

Elixir has three directives for types:

- `@type` – simple, public type.
Internal structure of type is public.
- `@typep` – type is private and could be used only in the module where is defined.
- `@opaque` – type is public, but internal structure is private.

Let's define our type:

```elixir
defmodule Examples do
  defstruct first: nil, last: nil

  @type t(first, last) :: %Examples{first: first, last: last}

  @type t :: %Examples{first: integer, last: integer}
end
```

We defined the type `t(first, last)` already, which is a representation of the struct `%Examples{first: first, last: last}`.
At this point we see types could takes parameters, but we defined type `t` as well and this time it is a representation of the struct `%Examples{first: integer, last: integer}`.

What is the difference? The first one represents the struct `Examples` in which the two keys could be any type.
The second one represents the struct in which the keys are `integers`.
This means that code that looks like this:

```elixir
@spec sum_times(integer, Examples.t()) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

Is equal to code like:

```elixir
@spec sum_times(integer, Examples.t(integer, integer)) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

### Documentation of types

The last element that we need to talk about is how to document our types.
As we know from the [documentation](/en/lessons/basics/documentation) lesson we have `@doc` and `@moduledoc` annotations to create documentation for functions and modules.
For documenting our types we can use `@typedoc`:

```elixir
defmodule Examples do
  @typedoc """
      Type that represents Examples struct with :first as integer and :last as integer.
  """
  @type t :: %Examples{first: integer, last: integer}
end
```

The directive `@typedoc` is similar to `@doc` and `@moduledoc`.
