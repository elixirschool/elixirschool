---
layout: page
title: Executables
category: advanced
order: 2
lang: en
---

To build executables in Elixir we will be using escript.  Escript produces an executables that can be run on any system with Erlang installed.

## Table of Contents

- [Getting Started](#getting-started)
- [Parsing Args](#parsing-args)
- [Building](#building)

## Getting Started

To create an executable with escript there are only a few things we need to do: implement a `main/1` method and update our Mixfile.

We'll start by creating a module to serve as the entry point to our executable, this is where we'll implement `main/1`:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    # Do stuff
  end
end
```

Next we need to update our Mixfile to include the `:escript` option for our project along with specifying our `:main_module`:

```elixir
defmodule ExampleApp.Mixfile do
  def project do
    [app: :example_app,
     version: "0.0.1",
     escript: escript]
  end

  def escript do
    [main_module: ExampleApp.CLI]
  end
end
```

## Parsing Args

With our application setup we can move on to parsing the command line arguments.  To do this we'll use Elixir's `OptionParser.parse/2` and the `:switches` option to indicate that our flag is boolean:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    args
    |> parse_args
    |> response
    |> IO.puts
  end

  defp parse_args(args) do
    {opts, word, _} =
      args
      |> OptionParser.parse(switches: [upcase: :boolean])

    {opts, List.to_string(word)}
  end

  defp response({opts, "Hello"}), do: response({opts, "World"})
  defp response({opts, word}) do
    if opts[:upcase], do: word = String.upcase(word)
    word
  end
end
```

## Building

Once we've finished configuring our application to use escript, building our executable is a breeze with mix:

```elixir
$ mix escript.build
```

Let's take it for a spin:

```elixir
$ ./example_app --upcase Hello
WORLD

$ ./example_app Hi
Hi
```

That's it, we've built our first executable in Elixir using escript.
