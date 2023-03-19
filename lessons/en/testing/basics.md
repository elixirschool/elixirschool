%{
  version: "1.2.1",
  title: "Testing",
  excerpt: """
  Testing is an important part of developing software.
  In this lesson we'll look at how to test our Elixir code with ExUnit and some best practices for doing so.
  """
}
---

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
We'll see an example of `assert_raise` in the lesson on Plug.

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

## Test Mocks

We want to be careful of how we think about “mocking”. When we mock certain interactions by creating unique function stubs in a given test example, we establish a dangerous pattern. We couple the run of our tests to the behavior of a particular dependency, like an API client. We avoid defining shared behavior among our stubbed functions. We make it harder to iterate on our tests.

Instead, the Elixir community encourages us to change the way we think about test mocks; that we think about a mock as a noun, instead of a verb.

For a longer discussion on this topic, see this [excellent article](http://blog.plataformatec.com.br/2015/10/mocks-and-explicit-contracts/).

The gist is, that instead of mocking away dependencies for testing (mock as a *verb*), it has many advantages to explicitly define interfaces (behaviors) for code outside your application and use mock (as a *noun*) implementations in your code for testing.

To leverage this "mocks-as-a-noun" pattern you can:

* Define a behaviour that is implemented both by the entity for which you'd like to define a mock *and* the module that will act as the mock.
* Define the mock module
* Configure your application code to use the mock in the given test or test environment, for example by passing the mock module into a function call as an argument or by configuring your application to use the mock module in the test environment.

For a deeper dive into test mocks in Elixir, and a look at the Mox library that allows you to define concurrent mock, check out our lesson on Mox [here](/en/lessons/testing/mox)
