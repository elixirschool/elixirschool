%{
  version: "1.0.3",
  title: "Erlang Interoperability",
  excerpt: """
  One of the added benefits to building on top of the Erlang VM (BEAM) is the plethora of existing libraries available to us.
  Interoperability allows us to leverage those libraries and the Erlang standard lib from our Elixir code.
  In this lesson we'll look at how to access functionality in the standard lib along with third-party Erlang packages.
  """
}
---

## Standard Library

Erlang's extensive standard library can be accessed from any Elixir code in our application.
Erlang modules are represented by lowercase atoms such as `:os` and `:timer`.

Let's use `:timer.tc` to time execution of a given function:

```elixir
defmodule Example do
  def timed(fun, args) do
    {time, result} = :timer.tc(fun, args)
    IO.puts("Time: #{time} μs")
    IO.puts("Result: #{result}")
  end
end

iex> Example.timed(fn (n) -> (n * n) * n end, [100])
Time: 8 μs
Result: 1000000
```

For a complete list of the modules available, see the [Erlang Reference Manual](http://erlang.org/doc/apps/stdlib/).

## Erlang Packages

In a prior lesson we covered Mix and managing our dependencies.
Including Erlang libraries works the same way.
In the event the Erlang library has not been pushed to [Hex](https://hex.pm) you can refer to the git repository instead:

```elixir
def deps do
  [{:png, github: "yuce/png"}]
end
```

Now we can access our Erlang library:

```elixir
png =
  :png.create(%{:size => {30, 30}, :mode => {:indexed, 8}, :file => file, :palette => palette})
```

## Notable Differences

Now that we know how to use Erlang we should cover some of the gotchas that come with Erlang interoperability.

### Atoms

Erlang atoms look much like their Elixir counterparts without the colon (`:`).
They are represented by lowercase strings and underscores:

Elixir:

```elixir
:example
```

Erlang:

```erlang
example.
```

### Strings

In Elixir when we talk about strings we mean UTF-8 encoded binaries.
In Erlang, strings still use double quotes but refer to char lists:

Elixir:

```elixir
iex> is_list('Example')
true
iex> is_list("Example")
false
iex> is_binary("Example")
true
iex> <<"Example">> === "Example"
true
```

Erlang:

```erlang
1> is_list('Example').
false
2> is_list("Example").
true
3> is_binary("Example").
false
4> is_binary(<<"Example">>).
true
```

It's important to note that many older Erlang libraries may not support binaries so we need to convert Elixir strings to char lists.
Thankfully this is easy to accomplish with the `to_charlist/1` function:

```elixir
iex> :string.words("Hello World")
** (FunctionClauseError) no function clause matching in :string.strip_left/2

    The following arguments were given to :string.strip_left/2:

        # 1
        "Hello World"

        # 2
        32

    (stdlib) string.erl:1661: :string.strip_left/2
    (stdlib) string.erl:1659: :string.strip/3
    (stdlib) string.erl:1597: :string.words/2

iex> "Hello World" |> to_charlist() |> :string.words
2
```

### Variables

In Erlang, variables begin with an uppercase letter and re-binding is not allowed.

Elixir:

```elixir
iex> x = 10
10

iex> x = 20
20

iex> x1 = x + 10
30
```

Erlang:

```erlang
1> X = 10.
10

2> X = 20.
** exception error: no match of right hand side value 20

3> X1 = X + 10.
20
```

That's it! Leveraging Erlang from within our Elixir applications is easy and effectively doubles the number of libraries available to us.
