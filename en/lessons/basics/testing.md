---
version: 1.1.1
title: Testing
redirect_from:
  - /lessons/basics/testing/
---

Testing is an important part of developing software.  In this lesson we'll look at how to test our Elixir code with ExUnit and some best practices for doing so.

{% include toc.html %}

## ExUnit

Elixir's built-in test framework is ExUnit and it includes everything we need to thoroughly test our code.  Before moving on it is important to note that tests are implemented as Elixir scripts so we need to use the `.exs` file extension.  Before we can run our tests we need to start ExUnit with `ExUnit.start()`, this is most commonly done in `test/test_helper.exs`.

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

We can run our project's tests with `mix test`.  If we do that now we should see an output similar to:

```shell
..

Finished in 0.03 seconds
2 tests, 0 failures
```

Why there are two tests in output? Let's look at `lib/example.ex`. Mix created there another test for us, some doctest.

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

We use the `assert` macro to test that the expression is true.  In the event that it is not, an error will be raised and our tests will fail.  To test a failure let's change our sample and then run `mix test`:

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

ExUnit will tells us exactly where our failed assertions are, what the expected value was, and what the actual value was.

### refute

`refute` is to `assert` as `unless` is to `if`.  Use `refute` when you want to ensure a statement is always false.

### assert_raise

Sometimes it may be necessary to assert that an error has been raised.  We can do this with `assert_raise`.  We'll see an example of `assert_raise` in the next lesson on Plug.

### assert_receive

In Elixir, applications consist of actors/processes that send messages to each other, thus often you want to test the messages being sent. Since ExUnit runs in its own process it can receive messages just like any other process and you can assert on it with the `assert_received` macro:

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

Capturing an application's output is possible with `ExUnit.CaptureIO` without changing the original application. Simply pass the function generating the output in:

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

In some instances it may be necessary to perform setup before our tests.  To accomplish this we can use the `setup` and `setup_all` macros.  `setup` will be run before each test and `setup_all` once before the suite.  It is expected that they will return a tuple of `{:ok, state}`, the state will be available to our tests.

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

The simple answer to mocking in Elixir is: don't.  You may instinctively reach for mocks but they are highly discouraged in the Elixir community and for good reason.

For a longer discussion there is this [excellent article](http://blog.plataformatec.com.br/2015/10/mocks-and-explicit-contracts/). The gist is, that instead of mocking away dependencies for testing (mock as a *verb*), it has many advantages to explicitly define interfaces (behaviors) for code outside your application and using Mock (as a *noun*) implementations in your client code for testing.

To switch the implementations in your application code, the preferred way is to pass the module as arguments and use a default value. If that does not work, use the built-in configuration mechanism. For creating these mock implementations, you don't need a special mocking library, only behaviours and callbacks.
