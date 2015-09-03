# Testing

Testing is an important part of developing software.  In this lesson we'll look at how to test our Elixir code with ExUnit and some best practices for doing so.

## Table of Contents

- [ExTest](#extest)
	- [assert](#assert)
	- [refute](#refute)
	- [assert_raise](#assert_raise)
- [Test Setup](#test-setup)
- [Mocking](#mocking)
- [Best Practices](#best-practices)

## ExTest

Elixir's builtin test framework is ExUnit and it includes everything we need to thoroughly test our code.  Before moving on it is important to note that tests are implemented as Elixir scripts so we need to use the `.exs` file extension.  Before we can run our tests we need to start ExUnit with `ExUnit.start()`, this is most commonly done in `test/test_helper.exs`.

When we generated our project mix was helpful enough to create a simple test for us, we can find it at `test/concoction_test.exs`:

```elixir
defmodule ConcoctionTest do
  use ExUnit.Case

  test "the truth" do
    assert 1 + 1 == 2
  end
end
```

We can run our project's tests with `mix test`.  If we do that now we should see an output similar to:

```bash
Finished in 0.03 seconds (0.02s on load, 0.01s on tests)
1 tests, 0 failures
```

### assert

If you've written tests before then you're familiar with `assert`; in some frameworks `should` or `expect` fill the role of `assert`.  

We use the `assert` macro to test that the expression is true.  In the event that it is not, an error will be raise and our tests will fail.  To test a failure let's change our sample and then run `mix test`:

```elixir
defmodule ConcoctionTest do
  use ExUnit.Case

  test "the truth" do
    assert 1 + 1 == 3
  end
end
```

Now we should see a very different kind of output:

```bash
  1) test the truth (ConcoctionTest)
     test/concoction_test.exs:4
     Assertion with == failed
     code: 1 + 1 == 3
     lhs:  2
     rhs:  3
     stacktrace:
       test/concoction_test.exs:5

......

Finished in 0.03 seconds (0.02s on load, 0.01s on tests)
1 tests, 1 failures
```

ExUnit will tells us exactly where our failed assertions are, what the expected value was, and what the actual was.

### refute

`refute` is to `assert` as `unless` is to `if`.  Use `refute` when you want to ensure a statement is always false.

### assert_raise

Sometimes it may be necessary to assert that an error was been raised, we can do this with `assert_raise`.  We'll see an example of `assert_raise` in the next lesson on Plug.

## Test Setup

In some instances it may be necessary to perform setup before our tests.  To accomplish this we can use the `setup` and `setup_all` macros.  `setup` will be run before each test and `setup_all` once before the suite.  It is expected that they will return a tuple of `{:ok, state}`, the state will be available to our tests.

For the sake of example, we'll change our code to use `setup_all`:

```elixir
defmodule ConcoctionTest do
  use ExUnit.Case

  setup_all do
    {:ok, number: 2}
  end

  test "the truth", state do
    assert 1 + 1 == state[:number]
  end
end
```


## Mocking

The simple answer to mocking in Elixir: don't.  You may instintually reach for mocks but they are highly discouraged in the Elixir community and for good reason.  If you follow good design principles the resulting code will be is easy to test as individual components.

Resist the urge.

## Best Practices
