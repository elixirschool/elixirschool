%{
  version: "1.0.1",
  title: "Behaviours",
  excerpt: """
  We learned about Typespecs in the previous lesson, here we'll learn how to require a module to implement those specifications.
  In Elixir, this functionality is referred to as behaviours.
  """
}
---

## Uses

Sometimes you want modules to share a public API, the solution for this in Elixir is behaviours.
Behaviours perform two primary roles:

+ Defining a set of functions that must be implemented
+ Checking whether that set was actually implemented

Elixir includes a number of behaviours such as `GenServer`, but in this lesson we'll focus on creating our own instead.

## Defining a behaviour

To better understand behaviours let's implement one for a worker module.
These workers will be expected to implement two functions: `init/1` and `perform/2`.

In order to accomplish this, we'll use the `@callback` directive with syntax similar to `@spec`.
This defines a __required__ function; for macros we can use `@macrocallback`.
Let's specify the `init/1` and `perform/2` functions for our workers:

```elixir
defmodule Example.Worker do
  @callback init(state :: term) :: {:ok, new_state :: term} | {:error, reason :: term}
  @callback perform(args :: term, state :: term) ::
              {:ok, result :: term, new_state :: term}
              | {:error, reason :: term, new_state :: term}
end
```

Here we've defined `init/1` as accepting any value and returning a tuple of either `{:ok, state}` or `{:error, reason}`, this is a pretty standard initialization.
Our `perform/2` function will receive some arguments for the worker along with the state we initialized, we'll expect `perform/2` to return `{:ok, result, state}` or `{:error, reason, state}` much like GenServers.

## Using behaviours

Now that we've defined our behaviour we can use it to create a variety of modules that all share the same public API.
Adding a behaviour to our module is easy with the `@behaviour` attribute.

Using our new behaviour let's create a module whose task will be downloading a remote file and saving it locally:

```elixir
defmodule Example.Downloader do
  @behaviour Example.Worker

  def init(opts), do: {:ok, opts}

  def perform(url, opts) do
    url
    |> HTTPoison.get!()
    |> Map.fetch(:body)
    |> write_file(opts[:path])
    |> respond(opts)
  end

  defp write_file(:error, _), do: {:error, :missing_body}

  defp write_file({:ok, contents}, path) do
    path
    |> Path.expand()
    |> File.write(contents)
  end

  defp respond(:ok, opts), do: {:ok, opts[:path], opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

Or how about a worker that compresses an array of files?  That's possible too:

```elixir
defmodule Example.Compressor do
  @behaviour Example.Worker

  def init(opts), do: {:ok, opts}

  def perform(payload, opts) do
    payload
    |> compress
    |> respond(opts)
  end

  defp compress({name, files}), do: :zip.create(name, files)

  defp respond({:ok, path}, opts), do: {:ok, path, opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

While the work performed is different, the public facing API isn't, and any code leveraging these modules can interact with them knowing they'll respond as expected.
This gives us the ability to create any number of workers, all performing different tasks, but conforming to the same public API.

If we happen to add a behaviour but fail to implement all of the required functions, a compile time warning will be raised.
To see this in action let's modify our `Example.Compressor` code by removing the `init/1` function:

```elixir
defmodule Example.Compressor do
  @behaviour Example.Worker

  def perform(payload, opts) do
    payload
    |> compress
    |> respond(opts)
  end

  defp compress({name, files}), do: :zip.create(name, files)

  defp respond({:ok, path}, opts), do: {:ok, path, opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

Now when we compile our code we should see a warning:

```shell
lib/example/compressor.ex:1: warning: undefined behaviour function init/1 (for behaviour Example.Worker)
Compiled lib/example/compressor.ex
```

That's it! Now we're ready to build and share behaviours with others.
