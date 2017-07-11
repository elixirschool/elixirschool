---
version: 1.0.1
title: Specifications and types
redirect_from:
  - /lessons/advanced/typespec
---

In this lesson we will learn about `@spec` and `@type` syntax. First is more syntax complement for writing documentation that could be analyzed by tools. Second helps us to write more readable and easier to understand code.

{% include toc.html %}

## Introduction

It's not uncommon you would like to describe interface of your function. You could use [@doc annotation](../../basics/documentation), but it only serves as documentation for other developers. It is not checked at compilation time. For this purpose Elixir has `@spec` annotation to describe specification of function that will be checked by compiler.

<<<<<<< HEAD:en/lessons/advanced/typespec.md
However in some cases specification is going to be quite big and complicated. If you would like to reduce complexity, you want to introduce custom type definition. Elixir has `@type` annotation for that. In the other hand, Elixir is still dynamic language. That means all information about type will be ignored by compiler, but could be used by other tools.
=======
However in some cases specification is going to be quite big and complicated. If you would like to reduce complexity, you want to introduce custom type definition. Elixir has `@type` annotation for that. In the other hand, Elixir is still a dynamic language. That means all information about types will be ignored by compiler, but could be used by other tools.   
>>>>>>> 02901c69058414572e16bfe5d32615dac2323cd5:lessons/advanced/typespec.md

## Specification

If you have experience with Java, Typescript or C# you can think of specifications as an `interface`. Specification define the expected types of function parameters and return values.

<<<<<<< HEAD:en/lessons/advanced/typespec.md
To define input and output types we use `@spec` directive placed right before function definition and taking as a `params` name of function, list of parameter types, and after `::` type of return value.
=======
To define input and output types we can place an `@spec` directive above a function definition. It accepts a list of `param` names (a list of parameter types) and is followed by `::`, indicating the return type.  
>>>>>>> 02901c69058414572e16bfe5d32615dac2323cd5:lessons/advanced/typespec.md

Let's take a look at an example:

```elixir
@spec sum_product(integer) :: integer
def sum_product(a) do
    [1, 2, 3]
    |> Enum.map(fn el -> el * a end)
    |> Enum.sum
end
```

Everything looks ok and when we call valid result will be return, but function `Enum.sum` returns `number` not `integer` as we expected in `@spec`. It could be source of bugs! There are tools like Dialyzer to static analysis of code that helps us to find this type of bugs. We will talk about them in another lesson.

## Custom types

<<<<<<< HEAD:en/lessons/advanced/typespec.md
Writing specifications is nice, but sometimes our functions works with more complex data structures than simple numbers or collections. In that definition's case in `@spec` it could be hard to understand and/or change for other developers. Sometimes functions need to take in a large number of parameters or return complex data. A long parameters list is one of many potential bad smells in one's code. In object oriented-languages like Ruby or Java we could easily define classes that help us to solve this problem. Elixir hasn't classes but because is easy to extends that we could define our types.

Out of box Elixir contains some basic types like `integer` or `pid`. You  can find full list of available types in [documentation](https://hexdocs.pm/elixir/typespecs.html#types-and-their-syntax).

=======
Specifications are nice, but sometimes our functions work with more complex data structures than simple numbers or collections. In the case of those definitions, editing `@spec` could be hard to understand and/or change for other developers. Sometimes functions need to take in a large number of parameters or return complex data. A long parameter list is one of many potential bad smells in one's code. In object oriented-languages like Ruby or Java we could easily define classes that help us to solve this problem. Elixir does not have classes but because it is easy to extend, we could define our types.

Elixir contains some basic types out of the box like `integer` and `pid`. You  can find the full list of available types in the [documentation](https://hexdocs.pm/elixir/typespecs.html#types-and-their-syntax).
 
>>>>>>> 02901c69058414572e16bfe5d32615dac2323cd5:lessons/advanced/typespec.md
### Defining custom type

Let's modify our `sum_times` function and introduce some extra params:

```elixir
@spec sum_times(integer, %Examples{first: integer, last: integer}) :: integer
def sum_times(a, params) do
    for i <- params.first..params.last do
        i
    end
       |> Enum.map(fn el -> el * a end)
       |> Enum.sum
       |> round
end
```

<<<<<<< HEAD:en/lessons/advanced/typespec.md
We introduced a struct in `Examples` module that contains two fields `first` and `last`. That is simpler version of struct from `Range` module. We will talk about `structs` when we get into discussing [modules](../../basics/modules/#structs). Lets imagine that we need to specification with `Examples` struct in many places. It would be annoying to write long, complex specifications and could be a source of bugs. A solution to this problem is `@type`.

=======
We introduced a struct in the `Examples` module that contains two fields: `first` and `last`. It is a simpler version of a struct from the `Range` module. We will talk about `structs` when we get into discussing [modules](../../basics/modules/#structs). Lets imagine that we need to write specifications that utilize the `Examples` struct in many places. It would be annoying to write long, complex specifications and could be a source of bugs. A solution to this problem is `@type`.
 
>>>>>>> 02901c69058414572e16bfe5d32615dac2323cd5:lessons/advanced/typespec.md
Elixir has three directives for types:

  - `@type` – simple, public type. Internal structure of type is public.
  - `@typep` – type is private and could be used only in the module where is defined.
  - `@opaque` – type is public, but internal structure is private.

Let define our type:

```elixir
defmodule Examples do

    defstruct first: nil, last: nil

    @type t(first, last) :: %Examples{first: first, last: last}

    @type t :: %Examples{first: integer, last: integer}

end
```

We defined the type `t(first, last)` already, which is a representation of the struct `%Examples{first: first, last: last}`. At this point we see types could takes parameters, but we defined type `t` as well and this time it is a representation of the struct `%Examples{first: integer, last: integer}`.

<<<<<<< HEAD:en/lessons/advanced/typespec.md
What is a difference? First one represents the struct `Examples` of which the two keys could be any type. Second one represents struct which keys are `integers`. That means code like this:

=======
What is a difference? The first one represents the struct `Examples` of which the two keys could be any type. The second one represents a struct whose keys are `integers`. That means code like this:
  
>>>>>>> 02901c69058414572e16bfe5d32615dac2323cd5:lessons/advanced/typespec.md
```elixir
@spec sum_times(integer, Examples.t) :: integer
def sum_times(a, params) do
    for i <- params.first..params.last do
        i
    end
       |> Enum.map(fn el -> el * a end)
       |> Enum.sum
       |> round
end
```

Is equal to code like this:

```elixir
@spec sum_times(integer, Examples.t(integer, integer)) :: integer
def sum_times(a, params) do
    for i <- params.first..params.last do
        i
    end
       |> Enum.map(fn el -> el * a end)
       |> Enum.sum
       |> round
end
```

### Documentation of types

The last element that we need to talk about is how to document our types. As we know from the [documentation](../../basics/documentation) lesson we have the `@doc` and `@moduledoc` annotations to create documentation for functions and modules. For documenting our types we can use `@typedoc`:

```elixir
defmodule Examples do

    @typedoc """
        Type that represents Examples struct with :first as integer and :last as integer.
    """
    @type t :: %Examples{first: integer, last: integer}

end
```

Directive `@typedoc` is similar to `@doc` and `@moduledoc`.
