---
layout: page
title: Debugging
category: specifics
order: 6
lang: en
---

Bugs are an inherent part of any project. That why we need to debugging. In this lesson we will learn about debugging Elixir code and tools for static analysis that helps to find bugs. 

{% include toc.html %}

# Dialyxir and Dialyzer

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

## Debugging

Sometimes static analysis of code is not enough. We need to know what is a real flow of code, because we would like find bugs. Simplest way is to put in code `IO.puts` to track values and code flow, but this technique is pretty primitive and limited. In Elixir we have could use erlang debugger to debug code. 

Let’s look at a basic module:

```elixir
defmodule Example do

  def cpu_burns(a, b, c) do
    x = a * 2
    y = b * 3
    z = c * 5
    
    x + y + z
  end

end
```

Then run `iex`:
 
```bash
$ iex -S mix
```

And run debugger:

```elixir
iex > :debugger.start()
{:ok, #PID<0.307.0>}
```

The `:debugger` is Erlang module that give us access to debugger. Next step is to attach our module to debugger:

```elixir
iex > :int.ni(Example)
{:module, Example}
```

The `:int` is an interpreter that gives us possibility to create breakpoint and stepwise execution of code. 

When you start debugger you will see new window like this:

![Debugger Screenshot 1]({{ site.url }}/assets/debugger_1.png)

After attaching our module to debugger it is available in menu on left side:

![Debugger Screenshot 2]({{ site.url }}/assets/debugger_2.png)

### Creating breakpoints

We have two ways to create breakpoint, place where debugger will suspend code execution

+ we could call `:int.break/2`,
+ we could use debugger window.

Let's try to create breakpoint from iex:

```elixir
iex > :int.break(Example, 8)
:ok
```

We set breakpoint in line 8 of module `Example` (it is `x + y + z` line). And now when we call our function:
 
```elixir
iex > Example.cpu_burns(1, 1, 1)
```

The iex suspends and no result appeared, but in debugger window we see:

![Debugger Screenshot 3]({{ site.url }}/assets/debugger_3.png)

In addition the window with source code of our module appeared:

![Debugger Screenshot 4]({{ site.url }}/assets/debugger_4.png)

In this window we could find current value of variables, go forward to next line or evaluate expressions. When we would like to disable breakpoint we could write:

```elixir
iex > :int.disable_break(Example, 8)
:ok
```

To enable breakpoint we call `:int.enable_break/2` or when we would like to remove breakpoint:

```elixir
iex > :int.delete_break(Example, 8)
:ok
```

The same operations are available from debugger window. In top menu __Break__ we should select __Line Break__ and setup breakpoint. If we select line that not contains code then breakpoint will be ignored, but it appear in debugger window. There are three types of breakpoints:

+ Line breakpoint – debugger suspend execution when we reach line; we set it up by `:int.break/2`,
+ Conditional breakpoint – like line breakpoint but debugger suspend only when specified condition is reached; we use `:int.get_binding/2`,
+ Function breakpoint – debugger suspend on first line of function; we use `:int.break_in/3`.

Line breakpoints and function breakpoint don't need extra work if we would like to set them up. We just put module name and line or module name, function name and arity and we are ready. However conditional breakpoint  

