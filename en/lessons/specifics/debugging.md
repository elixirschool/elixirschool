---
version: 1.0.1
title: Debugging
redirect_from:
  - /lessons/specifics/debugging/
---

Bugs are an inherent part of any project, that's why we need debugging. In this lesson we'll learn about debugging Elixir code as well as static analysis tools to help find potential bugs.

{% include toc.html %}

# Dialyxir and Dialyzer

The [Dialyzer](http://erlang.org/doc/man/dialyzer.html), a **DI**screpancy **A**nal**YZ**er for **ER**lang programs is a tool for static code analysis. In other words they _read_ but do not _run_ code and analyse it e.g. looking for some bugs, dead, unnecessary or unreachable code.

The [Dialyxir](https://github.com/jeremyjh/dialyxir) is a mix task to simplify usage of Dialyzer in Elixir.

Specification helps tools like Dialyzer to understand code better. Unlike documentation that is readable and understandable only for other humans (if only exists and is good written), `@spec` use more formal syntax and could be understand by machine.

Let's add Dialixyr to our project. The simplest way is to add dependency to `mix.exs` file:

```elixir
defp deps do
  [{:dialyxir, "~> 0.4", only: [:dev]}]
end
```

Then we call:

```shell
$ mix deps.get
...
$ mix deps.compile
```

The first command will download and install Dialyxir. You may be asked to install Hex along with it. The second compiles the Dialyxir application. If you want to install Dialyxir globally, please read its [documentation](https://github.com/jeremyjh/dialyxir#installation).

The last step is to run Dialyzer to rebuild the PLT (Persistent Lookup Table). You need to do this every time after installation of a new version of Erlang or Elixir. Fortunately, Dialyzer will not try to analyze standard library every time that you try to use it. It takes a few minutes for the download to complete.

```shell
$ mix dialyzer --plt
Starting PLT Core Build ... this will take awhile
dialyzer --build_plt --output_plt /.dialyxir_core_18_1.3.2.plt --apps erts kernel stdlib crypto public_key -r /Elixir/lib/elixir/../eex/ebin /Elixir/lib/elixir/../elixir/ebin /Elixir/lib/elixir/../ex_unit/ebin /Elixir/lib/elixir/../iex/ebin /Elixir/lib/elixir/../logger/ebin /Elixir/lib/elixir/../mix/ebin
  Creating PLT /.dialyxir_core_18_1.3.2.plt ...
...
 done in 5m14.67s
done (warnings were emitted)
```

## Static analysis of code

Now we're ready to use Dialyxir:

```shell
$ mix dialyzer
...
examples.ex:3: Invalid type specification for function 'Elixir.Examples':sum_times/1. The success typing is (_) -> number()
...
```

The message from Dialyzer is clear: the return type of our function `sum_times/1` is different than declared. This is because `Enum.sum/1` returns a `number` and not a `integer` but the return type of `sum_times/1` is `integer`.

Since `number` is not `integer` we get an error. How do we fix it? We need to use the `round/1` function to change our `number` to an `integer`:

```elixir
@spec sum_times(integer) :: integer
def sum_times(a) do
  [1, 2, 3]
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
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

Using specifications with tools to perform static code analysis helps us make code that is self-tested and contains less bugs.

# Debugging

Sometimes static analysis of code is not enough. It may be necessary to understand the execution flow in order to find bugs. The simplest way is to put output statements in our code like `IO.puts/2` to track values and code flow, but this technique is primitive and has limitations. Thankfully for us, we can use the Erlang debugger to debug our Elixir code.

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

The Erlang `:debugger` module provides access to the debugger. We can use the `start/1` function to configure it:

+ An external configuration file can be used by passing the file path.
+ If the argument is `:local` or `:global` then debugger will:
    + `:global` – debugger will interpret code on all known nodes. This is default value.
    + `:local` – debugger will interpret code only on current node.

The next step is to attach our module to debugger:

```elixir
iex > :int.ni(Example)
{:module, Example}
```

The `:int` module is an interpreter that gives us the ability to create breakpoints and step through the execution of the code.

When you start the debugger you will see a new window like this:

![Debugger Screenshot 1]({% asset_path "debugger_1.png" %})

After we've attached our module to the debugger it will be available in the menu on the left:

![Debugger Screenshot 2]({% asset_path "debugger_2.png" %})

## Creating breakpoints

A breakpoint is a point in the code where execution will be halted. We have two ways of creating breakpoints:

+ `:int.break/2` in our code
+ The debugger's UI

Let's try to create a breakpoint in IEx:

```elixir
iex > :int.break(Example, 8)
:ok
```

This sets a breakpoint on line 8 of the `Example` module. Now when we call our function:

```elixir
iex > Example.cpu_burns(1, 1, 1)
```

Execution will be paused in IEx and the debugger window should look like this:

![Debugger Screenshot 3]({% asset_path "debugger_3.png" %})

An additional window with our source code will appear:

![Debugger Screenshot 4]({% asset_path "debugger_4.png" %})

In this window we can look up the value of variables, step forward to next line, or evaluate expressions. `:int.disable_break/2` can be called in order to disable a breakpoint:

```elixir
iex > :int.disable_break(Example, 8)
:ok
```

To re-enable a breakpoint we can call `:int.enable_break/2` or we can remove a breakpoint like this:

```elixir
iex > :int.delete_break(Example, 8)
:ok
```

The same operations are available in the debugger window. In the top menu, __Break__, we can select __Line Break__ and setup breakpoints. If we select a line that does not contain code then breakpoints will be ignored, but it will appear in the debugger window. There are three types of breakpoints:

+ Line breakpoint — debugger suspends execution when we reach the line, setup with `:int.break/2`
+ Conditional breakpoint — similar to the line breakpoint but the debugger suspends only when the specified condition is reached, these are setup using `:int.get_binding/2`
+ Function breakpoint — debugger will suspend on first line of a function, configured using `:int.break_in/3`

That's all! Happy debugging!
