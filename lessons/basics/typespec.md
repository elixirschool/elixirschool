---
layout: page
title: Specifications and types
category: basics
order: 16
lang: en
---

If you want to define 'interface' like in Java or Ruby, Elixir contains syntax for that. More, if you want to define your custom type you can do that too. In this lesson we will learn about `@spec` and `@type` syntax.

{% include toc.html %}

## Introduction 

It's not uncommon you would like to describe interface of your function. Of course You can use [@doc annotation](/lessons/basic/documentation), but it is only information for other developers that is not checked in compilation time. For this purpose Elixir has `@spec` annotation to describe specification of function that will be checked by compiler.

However in some cases specification is going to be quite big and complicated. If you would like to reduce complexity, you want to introduce custom type definition. Elixir has `@type` annotation for that.

## Specification

If you have experience with Java or Ruby you could think about specification as an `interface`. Specification defines what is type of function parameters and return value.

Let's take a look at simple function that count number of workers in subdivisions of company division:

```elixir
@spec count_workers(Integer) :: Integer
def count_workers(divisionId) do
    list_subdivisions(divisionId)
    |> Enum.map(&number_of_workers/0)
    |> Enum.sum
end
```

When you run this code in iex you will see:

```elixir
iex> count_workers(1)

life.ex:45: Invalid type specification
```

That because `Enum.sum` return `number` not `Integer` and effective return type of `count_workers` is `number`. Because `number` is not `Integer` so we have error. How to fix it?

```elixir
@spec count_workers(Integer) :: Integer
def count_workers(divisionId) do
    list_subdivisions(divisionId)
    |> Enum.map(&numer_of_workers/0)
    |> Enum.sum
    |> round
end
```

We add call to `round` function that returns `Integer` and our code will works fine. `@spec` works for all version of function:

```elixir
@spec integral(Integer) :: Integer
def integral(x) when x == 0 do: 1
def integral(x) when x > 0 do: x * integral(x-1)
```

## Custom types

