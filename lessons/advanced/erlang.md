# Elixir + Erlang

One of the added benefits to building on top of the ErlangVM is the plethora of existing libraries available to us.  Interoperability allows us to leverage those libraries and the Erlang standard lib from our Elixir code.  In this lesson we'll look at how to access functionality in the standard lib along with third-party Erlang packages.

## Table of Contents

- [Standard Library](#standard-library)
- [Erlang Packages](#erlang-packages)

## Standard Library

Erlang's extensive standard library can be accessed from any Elixir code in our application.  Erlang modules are represented by lowercase atoms such as `:os` and `:timer`.

Let's use `:timer.tc` to time execution of a given function:

```elixir
defmodule Example do
	def timed(fun, args) do
		{time, result} = :timer.tc(fun, args)
		IO.puts "Time: #{time}ms"
		IO.puts "Result: #{result}"
	end
end

iex> Example.timed(fn (n) -> (n * n) * n end, [100])
Time: 8ms
Result: 1000000
```

For a complete list of the modules available, see the [Erlang Reference Manual](http://erlang.org/doc/apps/stdlib/).

## Erlang Packages

In a prior lesson we covered Mix and managing our dependencies, including Erlang libraries works the same way.  In the event the Erlang library has not been pushed to [Hex](hex.pm) you can refer the git repo instead:

```elixir
def deps do
  [{:png, github: "yuce/png"}]
end
```

Now we can access our Erlang library:

```elixir
png = :png.create(#{:size => {30, 30},
                    :mode => {:indexed, 8},
                    :file => file,
                    :palette => palette}),
```

That's it!  Leveraging Erlang from within our Elixir applications is easy and effectively doubles the number of libraries available to us.