---
version: 1.0.1
title: Custom Mix Tasks
redirect_from:
  - /lessons/basics/mix-tasks/
---

Creating custom Mix tasks for your Elixir projects.

{% include toc.html %}

## Introduction

It's not uncommon to want to extend your Elixir applications functionality by adding custom Mix tasks. Before we learn about how to create specific Mix tasks for our projects, let's look at one that already exists:

```shell
$ mix phoenix.new my_phoenix_app

* creating my_phoenix_app/config/config.exs
* creating my_phoenix_app/config/dev.exs
* creating my_phoenix_app/config/prod.exs
* creating my_phoenix_app/config/prod.secret.exs
* creating my_phoenix_app/config/test.exs
* creating my_phoenix_app/lib/my_phoenix_app.ex
* creating my_phoenix_app/lib/my_phoenix_app/endpoint.ex
* creating my_phoenix_app/test/views/error_view_test.exs
...
```

As we can see from the shell command above, The Phoenix Framework has a custom Mix task to generate a new project. What if we could create something similar for our project? Well the great news is we can, and Elixir makes this easy for us to do.

## Setup

Let's set up a very basic Mix application.

```shell
$ mix new hello

* creating README.md
* creating .gitignore
* creating mix.exs
* creating config
* creating config/config.exs
* creating lib
* creating lib/hello.ex
* creating test
* creating test/test_helper.exs
* creating test/hello_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

cd hello
mix test

Run "mix help" for more commands.
```

Now, in our **lib/hello.ex** file that Mix generated for us, let's create a simple function that will output "Hello, World!"

```elixir
defmodule Hello do
  @doc """
  Output's `Hello, World!` everytime.
  """
  def say do
    IO.puts("Hello, World!")
  end
end
```

## Custom Mix Task

Let's create our custom Mix task. Create a new directory and file **hello/lib/mix/tasks/hello.ex**. Within this file, let's insert these 7 lines of Elixir.

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Simply runs the Hello.say/0 command."
  def run(_) do
    # calling our Hello.say() function from earlier
    Hello.say()
  end
end
```

Notice how we start the defmodule statement with `Mix.Tasks` and the name we want to call from the command line. On the second line we introduce the `use Mix.Task` which brings the `Mix.Task` behaviour into the namespace. We then declare a run function which ignores any arguments for now. Within this function, we call our `Hello` module and the `say` function.

## Mix Tasks in Action

Let's checkout our mix task. As long as we are in the directory it should work. From the command line, run `mix hello`, and we should see the following:

```shell
$ mix hello
Hello, World!
```

Mix is quite friendly by default. It knows that everyone can make a spelling error now and then, so it uses a technique called fuzzy string matching to make recommendations:

```shell
$ mix hell
** (Mix) The task "hell" could not be found. Did you mean "hello"?
```

Did you also notice that we introduced an new module attribute, `@shortdoc`? This comes in handy when shipping our application, such as when a user runs the `mix help` command from the terminal.

```shell
$ mix help

mix app.start         # Starts all registered apps
...
mix hello             # Simply calls the Hello.say/0 function.
...
```
