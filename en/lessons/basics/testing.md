---
version: 1.2.0
title: Testing
---

Testing is an important part of developing software.
In this lesson we'll look at how to test our Elixir code with ExUnit and some best practices for doing so.

{% include toc.html %}

## ExUnit

Elixir's built-in test framework is ExUnit and it includes everything we need to thoroughly test our code.
Before moving on it is important to note that tests are implemented as Elixir scripts so we need to use the `.exs` file extension.
Before we can run our tests we need to start ExUnit with `ExUnit.start()`, this is most commonly done in `test/test_helper.exs`.

When we generated our example project in the previous lesson, mix was helpful enough to create a simple test for us, we can find it at `test/example_test.exs`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :world
  end
end
```

We can run our project's tests with `mix test`.
If we do that now we should see an output similar to:

```shell
..

Finished in 0.03 seconds
2 tests, 0 failures
```

Why are there two dots in the test output? Besides the test in `test/example_test.exs`, Mix also generated a doctest in `lib/example.ex`.

```elixir
defmodule Example do
  @moduledoc """
  Documentation for Example.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Example.hello
      :world

  """
  def hello do
    :world
  end
end
```

### assert

If you've written tests before then you're familiar with `assert`; in some frameworks `should` or `expect` fill the role of `assert`.

We use the `assert` macro to test that the expression is true.
In the event that it is not, an error will be raised and our tests will fail.
To test a failure let's change our sample and then run `mix test`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :word
  end
end
```

Now we should see a different kind of output:

```shell
  1) test greets the world (ExampleTest)
     test/example_test.exs:5
     Assertion with == failed
     code:  assert Example.hello() == :word
     left:  :world
     right: :word
     stacktrace:
       test/example_test.exs:6 (test)

.

Finished in 0.03 seconds
2 tests, 1 failures
```

ExUnit will tell us exactly where our failed assertions are, what the expected value was, and what the actual value was.

### refute

`refute` is to `assert` as `unless` is to `if`.
Use `refute` when you want to ensure a statement is always false.

### assert_raise

Sometimes it may be necessary to assert that an error has been raised.
We can do this with `assert_raise`.
We'll see an example of `assert_raise` in the next lesson on Plug.

### assert_receive

In Elixir, applications consist of actors/processes that send messages to each other, therefore you will want to test the messages being sent.
Since ExUnit runs in its own process it can receive messages just like any other process and you can assert on it with the `assert_received` macro:

```elixir
defmodule SendingProcess do
  def run(pid) do
    send(pid, :ping)
  end
end

defmodule TestReceive do
  use ExUnit.Case

  test "receives ping" do
    SendingProcess.run(self())
    assert_received :ping
  end
end
```

`assert_received` does not wait for messages, with `assert_receive` you can specify a timeout.

### capture_io and capture_log

Capturing an application's output is possible with `ExUnit.CaptureIO` without changing the original application.
Simply pass the function generating the output in:

```elixir
defmodule OutputTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "outputs Hello World" do
    assert capture_io(fn -> IO.puts("Hello World") end) == "Hello World\n"
  end
end
```

`ExUnit.CaptureLog` is the equivalent for capturing output to `Logger`.

## Test Setup

In some instances it may be necessary to perform setup before our tests.
To accomplish this we can use the `setup` and `setup_all` macros.
`setup` will be run before each test and `setup_all` once before the suite.
It is expected that they will return a tuple of `{:ok, state}`, the state will be available to our tests.

For the sake of example, we'll change our code to use `setup_all`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  setup_all do
    {:ok, recipient: :world}
  end

  test "greets", state do
    assert Example.hello() == state[:recipient]
  end
end
```

## Mocking

Tests and the mocks that facilitate them are usually not the attention-grabbing highlights of any language, so it is perhaps not surprising that there is less written about them. There is [one article](http://blog.plataformatec.com.br/2015/10/mocks-and-explicit-contracts/) about mocks in Elixir, written by José Valim himself. It is almost required reading in the Elixir canon, but it may leave you feeling confused if you don't follow how or why it differentiates between mocks as a noun vs. mocks as verb.

To clarify: you can _absolutely_ use mocks in Elixir! The exact methodology may be different from what you are familiar with in other languages, but the ultimate goal is the same.

Before we get into more complex use cases, let's talk about some techniques that can help us make our code more testable.  One simple tactic is to pass a module to a function rather than hard-coding the module inside the function.

Instead of code like this, where we have hard-coded the HTTP client used:
```elixir
def get_username(username) do
  HTTPoison.get("https://elixirschool.com/users/#{username}")
end
```
We could instead do something more like this:
```elixir
def get_username(username, http_client) do
  http_client.get("https://elixirschool.com/users/#{username}")
end
```

Or perhaps using the [apply/3](https://hexdocs.pm/elixir/Kernel.html#apply/3) function to accomplish the same:

```elixir
def get_username(username, http_client) do
  apply(http_client, :get, ["https://elixirschool.com/users/#{username}"])
end
```

Passing the module as an argument helps separate concerns and if we don't get too tripped up on the object-oriented verbiage, we might recognize this inversion of control as a kind of [Dependency Injection](https://en.wikipedia.org/wiki/Dependency_injection).  To test the `get_username/2` method, you would only need to pass in a module whose `get` function returned the value needed for your assertions.

This construct is very simple, so it is only useful when the function is highly accessible (and not, for example, buried somewhere deep within a private function).

A more flexible tactic relies on the application configuration. Perhaps you didn't even realize it, but an Elixir application maintains state in its configuration. Rather than hard-coding a module or passing it as an argument, you can read it from the application config.

```elixir
def get_username(username) do
  http_client().get("https://elixirschool.com/users/#{username}")
end

defp http_client do
  Application.get_env(:my_app, :http_client)
end
```

Then, in your config file:

```elixir
config :my_app, :http_client, HTTPoison
```

This construct and its reliance on the application config forms the basis of everything that follows.

If you are prone to overthinking, yes, you could omit the `http_client/0` function and call `Application.get_env/2` directly, and yes, you could also provide a default third argument to `Application.get_env/3` and achieve the same result.

This technique allows us to have specific implementations of the module for each environment; in José's article, he referenced a sandbox module for the `dev` environment while the `test` environment used an in-memory module.

However, having only one fixed module per environment may not be flexible enough: depending on how your function is used, you may need to return different responses in order to test all possible execution paths. What most people don't know is that you can _change_ the application configuration at run-time! Let's take a look at [Application.put_env/3](https://hexdocs.pm/elixir/Application.html#put_env/4).

Imagine that your application needed to act differently depending on whether or not the HTTP request was successful. We could create multiple modules, each with a `get/1` function. One module could return an `:ok` tuple, the other could return an `:error` tuple.  Then we could use `Application.put_env/3` to set the configuration prior to calling our `get_username/1` function.  Our test module might look something like this:

```elixir
# Don't do this!
defmodule MyAppTest do
  use ExUnit.Case

  setup do
    http_client = Application.get_env(:my_app, :http_client)
    on_exit(
      fn ->
        Application.put_env(:my_app, :http_client, http_client)
      end
    )
  end

  test ":ok on 200" do
    Application.put_env(:my_app, :http_client, HTTP200Mock)
    assert {:ok, _} = MyModule.get_username("twinkie")
  end

  test ":error on 404" do
    Application.put_env(:my_app, :http_client, HTTP404Mock)
    assert {:error, _} = MyModule.get_username("does-not-exist")
  end
end
```

It is assumed that you have created the required modules somewhere (`HTTP200Mock` and `HTTP404Mock`). We added a little `on_exit` callback to make sure that `:http_client` gets returned to its previous state after each test.

However, usually a pattern like the above is _NOT_ something you should follow! It is only when we look very carefully at the problems that can arise that we can understand the objections in José's article and only then can we understand his solution (more on that in moment).

First of all, there is nothing guaranteeing that the modules we define for our `:http_client` can do what they need to do: there is no enforcement of a contract here that requires the modules have a `get/1` function.

Second, tests like the above cannot be safely run asynchronously. Because the application's state is shared by the _entire_ application, it is entirely possible that you override the `:http_client` in one test while some other test (running simultaneously) expects a different result. You may have encountered problems like this when test runs _usually_ pass, but sometimes inexplicably fail. Beware!

Thirdly, this approach can get messy because you can end up with a bunch of mock modules stuffed into your application somewhere. Yuck.

We demonstrate the structure above because it outlines the approach in a fairly straight-forward manner that helps us understand a bit more about how the _real_ solution works.

### Mox : The Solution to all the Problems

The go-to package for working with mocks in Elixir is [Mox](https://hexdocs.pm/mox/Mox.html), authored by José Valim himself, and it solves all the problems outlined above.

First, include `mox` in your dependencies:
```elixir
# mix.exs
defp deps do
  [
    # ...
    {:mox, "~> 0.5.2", only: [:test], runtime: false}
  ]
end
```
and install it with `mix deps.get`.

Next, modify your `test_helper.exs` so it does 3 things:

1. it must start the Mox app
2. it must define one or more mocks
3. it must set the application config with the mock

```elixir
# test_helper.exs
ExUnit.start(exclude: [:skip])

# 1. Start the mox app
Mox.Server.start_link([])

# 2. define dynamic mocks
Mox.defmock(HTTPoison.BaseMock, for: HTTPoison.Base)
# ... etc...

# 3. Override the config settings (similar to adding these to `config/test.exs`)
Application.put_env(:my_app, :http_client, HTTPoison.BaseMock)
# ... etc...
```

A couple important things to note about `Mox.defmock`: the left-side name is arbitrary. Module names in Elixir are just atoms -- you don't have to create a module anywhere, all you are doing is "reserving" a name for the mock module. Behind the scenes, Mox will create a module with this name on the fly inside the BEAM.

The second tricky thing is that the module referenced by `for:` _must_ be a behaviour; it _must_ define callbacks. Mox uses introspection on this module and you can only define mock functions when a `@callback` has been defined.  This is how Mox enforces a contract.  Sometimes it can be difficult to find the behaviour module: `HTTPoison` for example, relies on `HTTPoison.Base`, but you might not know that unless you look through its source code.

This brings up an important point (and one that José discussed in his article): you may want to use a layer of abstraction (a.k.a. [indirection](https://en.wikipedia.org/wiki/Indirection)) so your application doesn't depend on a third party package _directly_, but instead you would use your own module which in turn uses the package. In the article, José discusses defining the proper "boundaries". It's worth reading it through more carefully, but the mechanics of mocks do not change.

Finally, in your test modules, you can put your mocks to use by importing `Mox` and calling its `:verify_on_exit!` function. Then you are free to define return values on your mock modules using the `expect` macro:

```elixir
defmodule MyAppTest do
  use ExUnit.Case
  # 1. Import Mox
  import Mox
  # 2. setup fixtures
  setup :verify_on_exit!

  test ":ok on 200" do
    HTTPoison.BaseMock
    |> expect(:get, fn _ -> {:ok, "What a guy!"} end)

    assert {:ok, _} = MyModule.get_username("twinkie")
  end

  test ":error on 404" do
    HTTPoison.BaseMock
    |> expect(:get, fn _ -> {:error, "Sorry!"} end)
    assert {:error, _} = MyModule.get_username("does-not-exist")
  end
end
```

For each test, we reference the _same_ mock module (`HTTPoison.BaseMock` in this example), and we use the `expect` macro to define the return values for each function called.

Using `Mox` is safe for asynchronous execution, and it requires that each mock follows a contract. And since these mocks are "virtual", there is no need to define actual modules that would clutter up your application.

Welcome to mocks in Elixir!
