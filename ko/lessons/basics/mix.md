---
layout: page
title: Mix
category: basics
order: 9
lang: ko
---

Elixir의 바다에 더 깊이 빠져들기 전에 먼저 mix를 공부해봐야 할 필요가 있어요. Ruby에 익숙하신 분들이시라면 mix를 보셨을 때 Bundler와 RubyGem, Rake를 합쳐놓았다는 느낌을 받으실 거예요. Elixir로 프로젝트를 진행하는 데 정말 중요한 부분이라, 이번 강의에서는 mix가 갖고 있는 멋진 기능을 익혀보도록 하겠습니다. `mix help` 를 실행하면 mix가 할 수 있는 모든 기능을 보실 수 있습니다.

여태까지 우리는 공부해오면서 여러 제약이 있는 `iex` 안에서만 작업해 왔었지요. 그렇지만 실제로 돌아가는 무엇인가를 만들어내기 위해서는 코드를 효율적으로 관리하도록 많은 파일로 나눌 필요가 있습니다. mix는 이렇게 프로젝트를 효율적으로 관리해낼 수 있게 해 줍니다.

## Table of Contents

- [New Projects](#new-project)
- [Compilation](#compilation)
- [Interactive](#interactive)
- [Manage Dependencies](#manage-dependencies)
- [Environments](#environments)

## New Projects

When we're ready to create a new Elixir project, mix makes it easy with the `mix new` command.  This will generate our project's folder structure and necessary boilerplate.  This is pretty straight forward, so let's get started:

```bash
$ mix new example
```

From the output we can see that mix has created our directory and a number of boilerplate files:

```bash
* creating README.md
* creating .gitignore
* creating mix.exs
* creating config
* creating config/config.exs
* creating lib
* creating lib/example.ex
* creating test
* creating test/test_helper.exs
* creating test/example_test.exs
```

In this lesson we're going to focus our attention on `mix.exs`.  Here we configure our application, dependencies, environment, and version.  Open the file in your favorite editor, you should see something like this (comments removed for brevity):

```elixir
defmodule Example.Mixfile do
  use Mix.Project

  def project do
    [app: :example,
     version: "0.0.1",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    []
  end
end
```

The first section we'll look at is `project`.  Here we define the name of our application (`app`), specify our version (`version`), Elixir version (`elixir`), and finally our dependencies (`deps`).

The `application` section is used during the generation of our application file which we'll cover next.

## Interactive

It may be necessary to use `iex` within the context of our application.  Thankfully for us, mix makes this easy.  We can start a new `iex` session:

```bash
$ iex -S mix
```

Starting `iex` this way will load your application and dependencies into the current runtime.

## Compilation

Mix is smart and will compile your changes when necessary, but it may still be necessary explicitly compile your project.  In this section we'll cover how to compile our project and what compilation does.

To compile a mix project we only need to run `mix compile` in our base directory:

```bash
$ mix compile
```

There isn't much to our project so the output isn't too exciting but it should complete successfully:

```bash
Compiled lib/example.ex
Generated example app
```

When we compile a project mix creates a `_build` directory for our artifacts.  If we look inside `_build` we will see our compiled application: `example.app`.

## Manage Dependencies

Our project doesn't have any dependencies but will shortly, so we'll go ahead and cover defining dependencies and fetching them.

To add a new dependency we need to first add it to our `mix.exs` in the `deps` section.  Our dependency list is comprised of tuples with two required values and one optional: The package name as an atom, the version string, and optional options.

For this example let's look at a project with dependencies, like [phoenix_slim](https://github.com/doomspork/phoenix_slim):

```elixir
def deps do
  [{:phoenix, "~> 0.16"},
   {:phoenix_html, "~> 2.1"},
   {:cowboy, "~> 1.0", only: [:dev, :test]},
   {:slim_fast, ">= 0.6.0"}]
end
```

As you probably discerned from the dependencies above, the `cowboy` dependency is only necessary during development and test.

Once we've defined our dependencies there is one final step, fetching them.  This is analogous to `bundle install`:

```bash
$ mix deps.get
```

That's it!  We've defined and fetched our project dependencies.  Now we're prepared to add dependencies when the time comes.

## Environments

Mix, much like Bundler, supports differing environments.  Out of the box mix works with three environments:

+ `:dev` — The default environment.
+ `:test` — Used by `mix test`. Covered further in our next lesson.
+ `:prod` — Used when we ship our application to production.

The current environment can be accessed using `Mix.env`.  As expected, the environment can be changed via the `MIX_ENV` environment variable:

```bash
$ MIX_ENV=prod mix compile
```
