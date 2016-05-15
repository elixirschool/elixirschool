---
layout: page
title: Testing
category: basics
order: 12
lang: vi
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

  test "the truth" do
    assert 1 + 1 == 2
  end
end
```

We can run our project's tests with `mix test`.  If we do that now we should see an output similar to:

```shell
Finished in 0.03 seconds (0.02s on load, 0.01s on tests)
1 tests, 0 failures
```

### assert

If you've written tests before then you're familiar with `assert`; in some frameworks `should` or `expect` fill the role of `assert`.

We use the `assert` macro to test that the expression is true.  In the event that it is not, an error will be raised and our tests will fail.  To test a failure let's change our sample and then run `mix test`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "the truth" do
    assert 1 + 1 == 3
  end
end
```

Now we should see a very different kind of output:

```shell
  1) test the truth (ExampleTest)
     test/example_test.exs:5
     Assertion with == failed
     code: 1 + 1 == 3
     lhs:  2
     rhs:  3
     stacktrace:
       test/example_test.exs:6

......

Finished in 0.03 seconds (0.02s on load, 0.01s on tests)
1 tests, 1 failures
```

ExUnit will tells us exactly where our failed assertions are, what the expected value was, and what the actual was.

### refute

`refute` is to `assert` as `unless` is to `if`.  Use `refute` when you want to ensure a statement is always false.

### assert_raise

Sometimes it may be necessary to assert that an error has been raised, we can do this with `assert_raise`.  We'll see an example of `assert_raise` in the next lesson on Plug.

## Test Setup

In some instances it may be necessary to perform setup before our tests.  To accomplish this we can use the `setup` and `setup_all` macros.  `setup` will be run before each test and `setup_all` once before the suite.  It is expected that they will return a tuple of `{:ok, state}`, the state will be available to our tests.

For the sake of example, we'll change our code to use `setup_all`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  setup_all do
    {:ok, number: 2}
  end

  test "the truth", state do
    assert 1 + 1 == state[:number]
  end
end
```

## Mocking

The simple answer to mocking in Elixir: don't.  You may instinctively reach for mocks but they are highly discouraged in the Elixir community and for good reason.  If you follow good design principles the resulting code will be easy to test as individual components.

Resist the urge.
