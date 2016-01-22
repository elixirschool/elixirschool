---
layout: page
title: Documentation
category: basics
order: 10
lang: en
---

Documenting Elixir code.

## Table of Contents.

- [Annotation](#annotation)
  - [Inline Documentation](#inline-documentation)
  - [Documenting Modules](#documenting-modules)
  - [Documenting Functions](#documenting-functions)
- [ExDoc](#exdoc)
  - [Installing](#installing)
  - [Generating Documentation](#generating-documentation)
- [Best Practice](#best-practice)


## Annotation

How much we comment and what makes quality documentation remains a contentious issue within the programming world. However, we can all agree that documentation is important for ourselves and those working with our codebase. 

Elixir treats documentation as a *first-class citizen*, offering various functions to access and generate documentation for your projects. The Elixir core provides us with many different attributes to annotate a codebase. Let's look at 3 ways:

  - `#`- For inline documentation.
  - `@moduledoc` - For module level documentation.
  - `@doc` - For function level documentation.

### Inline Documentation

Probably the simplist way to comment your code is with inline comments. Similar to Ruby or Python, Elixir's inline comment is denoted with a `#`, frequently known as a *pound*, or a *hash* depending on where you are from in the world. 

Take this Elixir Script (greeting.exs):

```elixir
# Outputs 'Hello, chum.' to the console.
IO.puts "Hello, " <> "chum."
```

Elixir, when running this script will ignore everything from `#` to the end of the line, treating it as throw away data. It may add no value to the operation or performance of the script, however when it's not so obvious what is going happening a programmer should know from reading your comment. Be mindful not to abuse the single line comment! Littering a codebase could become an unwelcome nightmare for some. It is best used in moderation.

### Documenting Modules

The `@moduledoc` annotator allows for inline documentation at a module level. It typically sits just under the `defmodule` decalation at the top of a file. The below example shows a one line comment within the `@moduledoc` decorator.

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

```bash
~/$ iex

Interactive Elixir (1.2.0) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)> c("greeter.ex")
[Greeter]

iex(2)> h Greeter

                Greeter                                     

Provides a function hello/1 to greet a human
```

### Documenting Functions

Just as Elixir gives us the ability for module level annotation, it also gives use similar annotations for documenting functions. The `@doc` annotator allows for inline documentation at a function level. The `@doc` annotator sits just above the function it is annotating.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """

  Prints a hello message

  ## Parameters

    - name (string): The name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  def hello(name) do
    "Hello, " <> name
  end
end
```

If we kick into IEx again and use the helper command (`h`) on the function prepended with the module name, we should see the following.

```bash
~/$ iex

Interactive Elixir (1.2.0) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)> c("greeter.ex")
[Greeter]

iex(2)> h Greeter.hello

                def hello(name)                                 

`hello/1` prints a hello message

Parameters

  • name (string): The name of the person.

Examples

  iex> Greeter.hello("Sean") 
  "Hello, Sean"

  iex> Greeter.hello("pete") 
  "Hello, pete"

iex(3)> 
```

Notice how you can use markup within out documentation and the terminal will render it? Apart from really being cool and a novel addition to Elixir's vast ecosystem, it gets much more interesting when we look at ExDoc to generate HTML documentation on the fly.

## ExDoc

ExDoc is an official Elixir project that **produces HTML (HyperText Markup Language and online documentation for Elixir projects** that can be found on [GitHub](https://github.com/elixir-lang/ex_doc). First lets create a Mix project for our application:

```bash
~/$ mix new greet_everyone                 

* creating README.md
* creating .gitignore
* creating mix.exs
* creating config
* creating config/config.exs
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
~/$ cd greet_everyone

```

Now copy and paste the code from the `@doc` annotator lesson into a file called `lib/greeter.ex` and make sure everything is still working from the command line. Now that we are working within a Mix project we need to start IEx a little differently using the `iex -S mix` sequence:

```bash
greet_everyone/$ ~ iex -S mix # loads the mix project into IEx

Interactive Elixir (1.2.0) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)> h Greeter.hello

                def hello(name)                                 

Prints a hello message

Parameters

  • name (string): The name of the person.

Examples

  iex> Greeter.hello("Sean") 
  "Hello, Sean"

  iex> Greeter.hello("pete") 
  "Hello, pete"

iex(2)> 
```

### Installing

Assuming all being well, and we're seeing the output above suggests that we are ready to set up ExDoc. Within our `mix.exs` file add the two required dependencies to get started; `:earmark` and `:ex_doc`.

```elixir
  def deps do
    [{:earmark, "~> 0.1", only: :dev},
    {:ex_doc, "~> 0.11", only: :dev}]
  end
```

We specify the `only: :dev` key-value pair as we don't want to download and compile these dependencies in a production environment. But why Earmark? Earmark is an markdown parser for the elixir programming language that ExDoc utilises to turn our documentation within `@moduledoc` and `@doc` to beautiful looking HTML. 

It is worth noting at this point, that you are not forced to use Earmark. You can change the markup tool to others such as Pandoc or Hoedown; however you will need to do a little more configuration which you can read about [here](https://github.com/elixir-lang/ex_doc#changing-the-markdown-tool). For this tutorial, we'll just stick with Earmark.

### Generating Documentation

Carrying on, from the command line run the following two commands:

```bash
greet_everyone/$ ~ mix deps.get # gets ExDoc + Earmark.
greet_everyone/$ ~ mix docs # makes the documentation.

Docs successfully generated.
View them at "doc/index.html".

greet_everyone/$ ~
```

Hopefully, if everything went to plan, you should see a similar message as to the output message in the above example. Let's now look inside our Mix project and we should see that there is another directory called **doc/**. Inside is our generated documentation. If we visit the index page in our browser we should see the following:

![ExDoc Screenshot 1]({{ site.url }}/assets/documentation_1.png)

We can see that Earmark has rendered our markdown and ExDoc is now displaying it in a useful format.

![ExDoc Screenshot 2]({{ site.url }}/assets/documentation_2.png)

We can now deploy this to GitHub, our own website, more commonly [HexDocs](https://hexdocs.pm/).

## Best Practice

Adding documentation shoud be added within the Best practices guidelines of the language. Since Elixir is a fairly young language many standards are still to be discovered as the ecosystem grows. The community however has made efforts to establish best practices. To read more about best practices see: https://github.com/niftyn8/elixir_style_guide

  - Always document a module.

```elixir
defmodule Greeter do
  @moduledoc """
  This is good documentation.
  """
  
end
```

  - If you do not intend to document a module, **do not** leave it blank. Instead mark the module as `false` as so:

```elixir
defmodule Greeter do
  @moduledoc false
  
end
```

 - When you are referring to functions within your module documentation, use backticks like so:

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  
  This module also has a `hello/1` function.
  """
  
  def hello(name) do
    IO.puts "Hello, " <> name
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
    IO.puts "Hello, " <> name
  end
end
```

 - Use markdown within functions that will make it easier to read either via IEx or ExDoc.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """

  Prints a hello message

  ## Parameters

    - name (string): The name of the person.

  ## Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"

  """
  def hello(name) do
    "Hello, " <> name
  end
end
```
