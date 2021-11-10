%{
  version: "1.0.1",
  title: "Mox",
  excerpt: """
  Mox is a library for designing concurrent mocks in Elixir.
  """
}
---

## Writing Testable Code

Tests and the mocks that facilitate them are usually not the attention-grabbing highlights of any language, so it is perhaps not surprising there is less written about them.
However you can _absolutely_ use mocks in Elixir!
The exact methodology may be different from what you are familiar with in other languages, but the ultimate goal is the same: mocks can simulate the output of internal functions and thereby allow you to assert against all possible execution paths in your code.

Before we get into more complex use cases, let's talk about some techniques that can help us make our code more testable.
One simple tactic is to pass a module to a function rather than hard-coding the module inside the function.

For example, if we had hard-coded an HTTP client inside a function:

```elixir
def get_username(username) do
  HTTPoison.get("https://elixirschool.com/users/#{username}")
end
```

We could instead pass the HTTP client module as an argument like this:

```elixir
def get_username(username, http_client) do
  http_client.get("https://elixirschool.com/users/#{username}")
end
```

Or we could use the [apply/3](https://hexdocs.pm/elixir/Kernel.html#apply/3) function to accomplish the same:

```elixir
def get_username(username, http_client) do
  apply(http_client, :get, ["https://elixirschool.com/users/#{username}"])
end
```

Passing the module as an argument helps separate concerns and if we don't get too tripped up on the object-oriented verbiage in the definition, we might recognize this inversion of control as a kind of [Dependency Injection](https://en.wikipedia.org/wiki/Dependency_injection).
To test the `get_username/2` method, you would only need to pass in a module whose `get` function returned the value needed for your assertions.

This construct is very simple, so it is only useful when the function is highly accessible (and not, for example, buried somewhere deep within a private function).

A more flexible tactic relies on the application configuration.
Perhaps you didn't even realize it, but an Elixir application maintains state in its configuration.
Rather than hard-coding a module or passing it as an argument, you can read it from the application config.

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

Leveraging the application config allows us to have specific implementations of the module for each environment; you might reference a sandbox module for the `dev` environment while the `test` environment might use an in-memory module.

However, having only one fixed module per environment may not be flexible enough: depending on how your function is used, you may need to return different responses in order to test all possible execution paths.
What most people don't know is that you can _change_ the application configuration at run-time!
Let's take a look at [Application.put_env/4](https://hexdocs.pm/elixir/Application.html#put_env/4).

Imagine that your application needed to act differently depending on whether or not the HTTP request was successful.
We could create multiple modules, each with a `get/1` function.
One module could return an `:ok` tuple, the other could return an `:error` tuple.
Then we could use `Application.put_env/4` to set the configuration prior to calling our `get_username/1` function.
Our test module might look something like this:

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

It is assumed that you have created the required modules somewhere (`HTTP200Mock` and `HTTP404Mock`).
We added an [`on_exit`](https://hexdocs.pm/ex_unit/master/ExUnit.Callbacks.html#on_exit/2) callback to the [`setup`](https://hexdocs.pm/ex_unit/master/ExUnit.Callbacks.html#setup/1) fixture to ensure that the `:http_client` gets returned to its previous state after each test.

However, a pattern like the above is usually _NOT_ something you should follow!
The reasons for this may not be immediately obvious.

First of all, there is nothing guaranteeing that the modules we define for our `:http_client` can do what they need to do: there is no enforcement of a contract here that requires the modules have a `get/1` function.

Second, tests like the above cannot be safely run asynchronously.
Because the application's state is shared by the _entire_ application, it is entirely possible that when you override the `:http_client` in one test, some other test (running simultaneously) expects a different result.
You may have encountered problems like this when test runs _usually_ pass, but sometimes inexplicably fail. Beware!

Thirdly, this approach can get messy because you can end up with a bunch of mock modules stuffed into your application somewhere. Yuck.

We demonstrate the structure above because it outlines the approach in a fairly straight-forward manner that helps us understand a bit more about how the _real_ solution works.

## Mox : The Solution to all the Problems

The go-to package for working with mocks in Elixir is [Mox](https://hexdocs.pm/mox/Mox.html), authored by José Valim himself, and it solves all the problems outlined above.

Remember: as a pre-requisite, our code must look to the application config to get its configured module:

```elixir
def get_username(username) do
  http_client().get("https://elixirschool.com/users/#{username}")
end

defp http_client do
  Application.get_env(:my_app, :http_client)
end
```

Then you may include `mox` in your dependencies:

```elixir
# mix.exs
defp deps do
  [
    # ...
    {:mox, "~> 0.5.2", only: :test}
  ]
end
```

Install it with `mix deps.get`.

Next, modify your `test_helper.exs` so it does 2 things:

1. it must define one or more mocks
2. it must set the application config with the mock

```elixir
# test_helper.exs
ExUnit.start()

# 1. define dynamic mocks
Mox.defmock(HTTPoison.BaseMock, for: HTTPoison.Base)
# ... etc...

# 2. Override the config settings (similar to adding these to config/test.exs)
Application.put_env(:my_app, :http_client, HTTPoison.BaseMock)
# ... etc...
```

A couple important things to note about `Mox.defmock`: the left-side name is arbitrary.
Module names in Elixir are just atoms -- you don't have to create a module anywhere, all you are doing is "reserving" a name for the mock module.
Behind the scenes, Mox will create a module with this name on the fly inside the BEAM.

The second tricky thing is that the module referenced by `for:` _must_ be a behaviour: it _must_ define callbacks.
Mox uses introspection on this module and you can only define mock functions when a `@callback` has been defined.
This is how Mox enforces a contract.
Sometimes it can be difficult to find the behaviour module: `HTTPoison` for example, relies on `HTTPoison.Base`, but you might not know that unless you look through its source code.
If you are trying to create a mock for a 3rd-party package, you may discover that no behaviour exists!
In those cases you may need to define your own behaviour and callbacks to satisfy the need for a contract.

This brings up an important point: you may want to use a layer of abstraction (a.k.a. [indirection](https://en.wikipedia.org/wiki/Indirection)) so your application doesn't depend on a third party package _directly_, but instead you would use your own module which in turn uses the package.
It is important for a well-crafted application to define the proper "boundaries", but the mechanics of mocks do not change, so don't let that trip you up.

Finally, in your test modules, you can put your mocks to use by importing `Mox` and calling its `:verify_on_exit!` function.
Then you are free to define return values on your mock modules using one or more calls to the `expect` function:

```elixir
defmodule MyAppTest do
  use ExUnit.Case, async: true
  # 1. Import Mox
  import Mox
  # 2. setup fixtures
  setup :verify_on_exit!

  test ":ok on 200" do
    expect(HTTPoison.BaseMock, :get, fn _ -> {:ok, "What a guy!"} end)

    assert {:ok, _} = MyModule.get_username("twinkie")
  end

  test ":error on 404" do
    expect(HTTPoison.BaseMock, :get, fn _ -> {:error, "Sorry!"} end)
    assert {:error, _} = MyModule.get_username("does-not-exist")
  end
end
```

For each test, we reference the _same_ mock module (`HTTPoison.BaseMock` in this example), and we use the `expect` function to define the return values for each function called.

Using `Mox` is safe for asynchronous execution, and it requires that each mock follows a contract.
Since these mocks are "virtual", there is no need to define actual modules that would clutter up your application.

Welcome to mocks in Elixir!
