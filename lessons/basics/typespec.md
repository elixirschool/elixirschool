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

If you have experience with Java or Ruby you could think about specification as an `interface`. Specification defines what should be type of function parameters and return value.

To define input and output types we use `@spec` directive placed right before function definition and taking as a _params_ name of function, list of parameter types, and after `::` type of return value.  

Let's take a look at example:

```elixir
@spec sum_product(integer) :: integer
def sum_product(a) do
    [1, 2, 3]
    |> Enum.map(fn el -> el * a end)
    |> Enum.sum
end
```

Everything looks ok and when we call valid result will be return, but function `Enum.sum` returns `number` not `integer` as we expected in `@spec`. It could be source of bugs!

### Dialyxir and Dialyzer

The [Dialyzer](http://erlang.org/doc/man/dialyzer.html), a **DI**screpancy **A**nal**YZ**er for **ER**lang programs is a tool for static code analysis. In other words they _read_ but not _run_ code and analyse it e.g. looking for some bugs, dead, unnecessary or unreachable code.
   
The [Dialyxir](https://github.com/jeremyjh/dialyxir) is a mix task simplify usage of Dialyzer in Elixir.  

Specification helps tools like Dialyzer to understand code better. Unlike documentation that is readable and understandable only for other humans (if only exists and is good written), `@spec` use more formal syntax and could be understand by machine.

Let's add Dialixyr to our project. The simples way is to add dependency to `mix.exs` file:
 
```elixir
defp deps do
  [{:dialyxir, "~> 0.3.5", only: [:dev]}]
end
```

Then we call:

```shell
$ mix deps.get
...
$ mix deps.compile
```

First command download and install Dialyxir. You could be asked for installing Hex. Second compile Dialyxir app. If you want to install Dialyxir as global app, please read [documentation](https://github.com/jeremyjh/dialyxir#installation).

Last step is to run Dialyzer to rebuild PLT. You need to do this every time after installation of new version of Erlang or Elixir. Thanks to this Dialyzer will not be try to analyse standard library every time that you try to use it. It takes few minutes.

```shell
$ mix dialyzer.plt
Starting PLT Core Build ... this will take awhile
dialyzer --build_plt --output_plt /.dialyxir_core_18_1.3.2.plt --apps erts kernel stdlib crypto public_key -r /Elixir/lib/elixir/../eex/ebin /Elixir/lib/elixir/../elixir/ebin /Elixir/lib/elixir/../ex_unit/ebin /Elixir/lib/elixir/../iex/ebin /Elixir/lib/elixir/../logger/ebin /Elixir/lib/elixir/../mix/ebin
  Creating PLT /.dialyxir_core_18_1.3.2.plt ...
...
 done in 5m14.67s
done (warnings were emitted)
```

### Static analysis of code
 
Now, when we have Dialyxir on board we could run it:
 
```shell
$ mix dialyzer
...
examples.ex:3: Invalid type specification for function 'Elixir.Examples':sum_times/1. The success typing is (_) -> number()
...
```

Communicate is clear. Return type of our function `sum_times/1` is different than declared. That because `Enum.sum` return `number` not `integer` and effective return type of `sum_times/1` is `number`. Because `number` is not `integer` so we have error. How to fix it? We could add `round` function that change `number` to `integer`:

```elixir
@spec sum_times(integer) :: integer
def sum_times(a) do
    [1, 2, 3]
    |> Enum.map(fn el -> el * a end)
    |> Enum.sum
    |> round
end
```

Finally:

```shell
$ mix dialyzer
...
  Proceeding with analysis... done in 0m0.95s
done (passed successfully)
```

Using specifications with tools to static code analysis helps us to make code that is self tested and contains less bugs.  

## Custom types

