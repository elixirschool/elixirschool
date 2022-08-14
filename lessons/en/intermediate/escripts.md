%{
  version: "1.0.2",
  title: "Executables",
  excerpt: """
  To build executables in Elixir we will be using escript.
  Escript produces an executable that can be run on any system with Erlang installed.
  """
}
---

## Getting Started

To create an executable with escript there are only a few things we need to do: implement a `main/1` function and update our Mixfile.

We'll start by creating a module to serve as the entry point to our executable.
This is where we'll implement `main/1`:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    # Do stuff
  end
end
```

Next we need to update our Mixfile to include the `:escript` option for our project along with specifying our `:main_module`:

```elixir
defmodule ExampleApp.Mixproject do
  def project do
    [app: :example_app, version: "0.0.1", escript: escript()]
  end

  defp escript do
    [main_module: ExampleApp.CLI]
  end
end
```

## Parsing Args

With our application set up we can move on to parsing the command line arguments.
To do this we'll use Elixir's `OptionParser.parse/2` with the `:switches` option to indicate that our flag is boolean:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    args
    |> parse_args()
    |> response()
    |> IO.puts()
  end

  defp parse_args(args) do
    {opts, word, _} =
      args
      |> OptionParser.parse(switches: [upcase: :boolean])

    {opts, List.to_string(word)}
  end

  defp response({opts, word}) do
    if opts[:upcase], do: String.upcase(word), else: word
  end
end
```

## Building

Once we've finished configuring our application to use escript, building our executable is a breeze with Mix:

```bash
mix escript.build
```

Let's take it for a spin:

```bash
$ ./example_app --upcase Hello
HELLO

$ ./example_app Hi
Hi
```

That's it.
We've built our first executable in Elixir using escript.
