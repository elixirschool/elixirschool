%{
  author: "Sean Callan",
  author_link: "https://github.com/doomspork",
  date: ~D[2018-12-04],
  tags: ["til"],
  title: "TIL about `IO.inspect/2`'s `:label` opt",
  excerpt: """
  Did you know you could label your output?  Neither did we!  Check out today's TIL to learn more.
  """
}

---

If you've ever found yourself debugging Elixir then you're probably familiar with `IO.inspect/2` but just in case let's see an example of how we might use it:

```elixir
defmodule Example do
  def sanitize_params(params) do
    params
    |> IO.inspect()
    |> Map.take(["quantity", "price"])
    |> IO.inspect()
    |> Enum.into(%{}, fn {k, v} -> {k, String.to_integer(v)} end)
  end
end
```

Our function is simple: Given a map, take some keys, and cast them to integers; for this example we won't worry about invalid inputs and error handling.

Let's see the output in `IEx`:

```elixir
iex> params = %{"price" => "100", "quantity" => "1", "onsale" => true}
iex> Example.sanitize_params(params)
%{"onsale" => true, "price" => "100", "quantity" => "1"}
%{"price" => "100", "quantity" => "1"}
%{"price" => 100, "quantity" => 1}
```

Looking at the code and output side-by-side, we can pretty easily follow along but without that we have to remember what and where we put our `IO.inspect/2` calls for the output to be meaningful.
Can you imagine situations where there's __a lot__ more output on the screen and the code isn't as simple?

Allow me to introduce you to our new friend the `:label` option!
Let's revisit our previous code, introduce the ever helpful `:label` option, and jump straight into the `IEx` output:

```elixir
defmodule Example do
  def sanitize_params(params) do
    params
    |> IO.inspect(label: "input")
    |> Map.take(["quantity", "price"])
    |> IO.inspect(label: "Map.take/2")
    |> Enum.into(%{}, fn {k, v} -> {k, String.to_integer(v)} end)
  end
end
```

```elixir
iex> params = %{"price" => "100", "quantity" => "1", "onsale" => true}
iex> Example.sanitize_params(params)
input: %{"onsale" => true, "price" => "100", "quantity" => "1"}
Map.take/2: %{"price" => "100", "quantity" => "1"}
%{"price" => 100, "quantity" => 1}
```

Whoa!
Our debugging output now has labels that make tracing our code _so_ much easier.
It gets better too!
Labels don't have to be preset, we can use our captured values for dynamic labels:

```elixir
iex> Enum.each(%{"a" => 1, "b" => 2, "c" => 3}, fn {k, v} -> IO.inspect(v, label: k) end)
a: 1
b: 2
c: 3
```

How cool is that?!

Did you know about `:label` before?
If so, have you found it as useful as we have?
