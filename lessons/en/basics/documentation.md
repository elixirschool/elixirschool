%{
  version: "1.1.1",
  title: "Documentation",
  excerpt: """
  Documenting Elixir code.
  """
}
---

## Annotation

How much we comment and what makes quality documentation remains a contentious issue within the programming world.
However, we can all agree that documentation is important for ourselves and those working with our codebase.

Elixir treats documentation as a *first-class citizen*, offering various functions to access and generate documentation for your projects.
The Elixir core provides us with many different attributes to annotate a codebase.
Let's look at 3 ways:

- `#` - For inline documentation.
- `@moduledoc` - For module-level documentation.
- `@doc` - For function-level documentation.

### Inline Documentation

Probably the simplest way to comment your code is with inline comments.
Similar to Ruby or Python, Elixir's inline comment is denoted with a `#`, frequently known as a *pound*, or a *hash* depending on where you are from in the world.

Take this Elixir Script (greeting.exs):

```elixir
# Outputs 'Hello, chum.' to the console.
IO.puts("Hello, " <> "chum.")
```

Elixir, when running this script will ignore everything from `#` to the end of the line, treating it as throwaway data.
It may add no value to the operation or performance of the script, however when it's not so obvious what is happening a programmer should know from reading your comment.
Be mindful not to abuse the single line comment! Littering a codebase could become an unwelcome nightmare for some.
It is best used in moderation.

### Documenting Modules

The `@moduledoc` annotator allows for inline documentation at a module level.
It typically sits just under the `defmodule` declaration at the top of a file.
The example below shows a one line comment within the `@moduledoc` decorator.

```elixir
defmodule Greeter do
  @moduledoc """
  Provides a function `hello/1` to greet a human
  """

  def hello(name) do
    "Hello, " <> name
  end
end
```

We (or others) can access this module documentation using the `h` helper function within IEx.
We can see this for ourselves if we put our `Greeter` module into a new file, `greeter.ex` and compile it:

```elixir
iex> c("greeter.ex", ".")
[Greeter]

iex> h Greeter

                Greeter

Provides a function hello/1 to greet a human
```

*Note*: we don't need to manually compile our files as we did above if we're working within the context of a mix project. You can use `iex -S mix` to load the IEx console for the current project if you're working in a mix project.

### Documenting Functions

Just as Elixir gives us the ability for module level annotation, it also enables similar annotations for documenting functions.
The `@doc` annotator allows for inline documentation at a function level.
The `@doc` annotator sits just above the function it is annotating.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message.

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

If we kick into IEx again and use the helper command (`h`) on the function prepended with the module name, we should see the following:

```elixir
iex> c("greeter.ex", ".")
[Greeter]

iex> h Greeter.hello

                def hello(name)

  @spec hello(String.t()) :: String.t()

Prints a hello message.

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"

iex>
```

Notice how you can use markup within our documentation and the terminal will render it? Apart from really being cool and a novel addition to Elixir's vast ecosystem, it gets much more interesting when we look at ExDoc to generate HTML documentation on the fly.

**Note:** the `@spec` annotation is used to statically analyze code.
To learn more about it, check out the [Specifications and types](/en/lessons/advanced/typespec) lesson.

## ExDoc

ExDoc is an official Elixir project that can be found on [GitHub](https://github.com/elixir-lang/ex_doc).
It produces **HTML (HyperText Markup Language) and online documentation** for Elixir projects.
First let's create a Mix project for our application:

```bash
$ mix new greet_everyone

* creating README.md
* creating .formatter.exs
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/greet_everyone.ex
* creating test
* creating test/test_helper.exs
* creating test/greet_everyone_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd greet_everyone
    mix test

Run "mix help" for more commands.

$ cd greet_everyone

```

Now copy and paste the code from the `@doc` annotator lesson into a file called `lib/greeter.ex` and make sure everything is still working from the command line.
Now that we are working within a Mix project we need to start IEx a little differently using the `iex -S mix` command sequence:

```elixir
iex> h Greeter.hello

                def hello(name)

  @spec hello(String.t()) :: String.t()

Prints a hello message.

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"
```

### Installing

Assuming all is well and we're seeing the output above, we are now ready to set up ExDoc.
In the `mix.exs` file, add the `:ex_doc` dependency to get started.

```elixir
  def deps do
    [{:ex_doc, "~> 0.21", only: :dev, runtime: false}]
  end
```

We specify the `only: :dev` key-value pair as we don't want to download and compile the `ex_doc` dependency in a production environment.

`ex_doc` will also add another library for us, Earmark.

Earmark is a Markdown parser for the Elixir programming language that ExDoc utilizes to turn our documentation within `@moduledoc` and `@doc` to beautiful looking HTML.

It is worth noting at this point that you can change the markup tool to Cmark if you wish, but you will need to do a little more configuration which you can read about [here](https://hexdocs.pm/ex_doc/ExDoc.Markdown.html#module-using-cmark).
For this tutorial, we'll just stick with Earmark.

### Generating Documentation

Carrying on, from the command line run the following two commands:

```bash
$ mix deps.get # gets ExDoc + Earmark.
$ mix docs # makes the documentation.

Docs successfully generated.
View them at "doc/index.html".
```

If everything went to plan, you should see a similar message as to the output message in the above example.
Let's now look inside our Mix project and we should see that there is another directory called **doc/**.
Inside is our generated documentation.
If we visit the index page in our browser we should see the following:

![ExDoc Screenshot 1](/images/documentation_1.png)

We can see that Earmark has rendered our Markdown and ExDoc is now displaying it in a useful format.

![ExDoc Screenshot 2](/images/documentation_2.png)

We can now deploy this to GitHub, our own website, or more commonly [HexDocs](https://hexdocs.pm/).

## Best Practice

Documentation should be added within the Best Practices Guidelines of the language.
Since Elixir is a fairly young language many standards are still to be discovered as the ecosystem grows.
The community, however, tried to establish best practices.
To read more about best practices see [The Elixir Style Guide](https://github.com/niftyn8/elixir_style_guide).

- Always document a module.

```elixir
defmodule Greeter do
  @moduledoc """
  This is good documentation.
  """

end
```

- If you do not intend to document a module, **do not** leave it blank.
Consider annotating the module `false`, like so:

```elixir
defmodule Greeter do
  @moduledoc false

end
```

- When referring to functions within module documentation, use backticks like so:

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

- Separate any and all code one line under the `@moduledoc` as so:

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  alias Goodbye.bye_bye
  # and so on...

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

- Use Markdown within docs.
It will make it easier to read either via IEx or ExDoc.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

- Try to include some code examples in your documentation.
This also allows you to generate automatic tests from the code examples found in a module, function, or macro with [ExUnit.DocTest][].
In order to do that, you need to invoke the `doctest/1` macro from your test case and write your examples according to some guidelines as detailed in the [official documentation][ExUnit.DocTest].

[ExUnit.DocTest]: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html
