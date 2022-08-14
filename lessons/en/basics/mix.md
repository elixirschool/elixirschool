%{
  version: "1.1.2",
  title: "Mix",
  excerpt: """
  Before we can dive into the deeper waters of Elixir we first need to learn about Mix.
  If you're familiar with Ruby, Mix is Bundler, RubyGems, and Rake combined.
  It's a crucial part of any Elixir project and in this lesson we're going to explore just a few of its great features.
  To see all that Mix has to offer in the current environment run `mix help`.

Until now we've been working exclusively within `iex` which has limitations
  In order to build something substantial we need to divide our code up into many files to effectively manage it; Mix lets us do that with projects.
  """
}
---

## New Projects

When we're ready to create a new Elixir project, Mix makes it easy with the `mix new` command.
This will generate our project's folder structure and necessary boilerplate.
This is pretty straightforward, so let's get started:

```bash
mix new example
```

From the output we can see that Mix has created our directory and a number of boilerplate files:

```bash
* creating README.md
* creating .formatter.exs
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/example.ex
* creating test
* creating test/test_helper.exs
* creating test/example_test.exs
```

In this lesson we're going to focus our attention on `mix.exs`.
Here we configure our application, dependencies, environment, and version.
Open the file in your favorite editor, you should see something like this (comments removed for brevity):

```elixir
defmodule Example.MixProject do
  use Mix.Project

  def project do
    [
      app: :example,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end
end
```

The first section we'll look at is `project`.
Here we define the name of our application (`app`), specify our version (`version`), Elixir version (`elixir`), and finally our dependencies (`deps`).

The `application` section is used during the generation of our application file which we'll cover next.

## Interactive

It may be necessary to use `iex` within the context of our application.
Thankfully for us, Mix makes this easy.
We can start a new `iex` session:

```bash
cd example
iex -S mix
```

Starting `iex` this way will load your application and dependencies into the current runtime.

## Compilation

Mix is smart and will compile your changes when necessary, but it may still be necessary to explicitly compile your project.
In this section we'll cover how to compile our project and what compilation does.

To compile a Mix project we only need to run `mix compile` in our base directory:
**Note: Mix tasks for a project are available only from the project root directory, only global Mix tasks are available otherwise.**

```bash
mix compile
```

There isn't much to our project so the output isn't too exciting but it should complete successfully:

```bash
Compiled lib/example.ex
Generated example app
```

When we compile a project, Mix creates a `_build` directory for our artifacts.
If we look inside `_build` we will see our compiled application: `example.app`.

## Managing Dependencies

Our project doesn't have any dependencies but will shortly, so we'll go ahead and cover defining dependencies and fetching them.

To add a new dependency we need to first add it to our `mix.exs` in the `deps` section.
Our dependency list is comprised of tuples with two required values and one optional: the package name as an atom, the version string, and optional options.

For this example let's look at a project with dependencies, like [phoenix_slim](https://github.com/doomspork/phoenix_slim):

```elixir
def deps do
  [
    {:phoenix, "~> 1.1 or ~> 1.2"},
    {:phoenix_html, "~> 2.3"},
    {:cowboy, "~> 1.0", only: [:dev, :test]},
    {:slime, "~> 0.14"}
  ]
end
```

As you probably discerned from the dependencies above, the `cowboy` dependency is only necessary during development and test.

Once we've defined our dependencies there is one final step: fetching them.
This is analogous to `bundle install`:

```bash
mix deps.get
```

That's it! We've defined and fetched our project dependencies.
Now we're prepared to add dependencies when the time comes.

## Environments

Mix, much like Bundler, supports differing environments.
Out of the box Mix is configured to have three environments:

- `:dev` — The default environment.
- `:test` — Used by `mix test`. Covered further in our next lesson.
- `:prod` — Used when we ship our application to production.

The current environment can be accessed using `Mix.env`.
As expected, the environment can be changed via the `MIX_ENV` environment variable:

```bash
MIX_ENV=prod mix compile
```
