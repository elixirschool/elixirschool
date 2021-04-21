%{
  version: "1.2.0",
  title: "测试",
  excerpt: """
  测试是软件开发重要的一部分，这节课我们会讲一下如何使用 ExUnit 测试 Elixir 代码，以及测试中的最佳实践方法。
  """
}
---

## ExUnit

Elixir 自带的测试框架是 ExUnit，它包括的功能足够我们充分测试自己的代码。在继续讲解之前，有一点要注意：测试是通过 Elixir 脚本来执行的，所以测试文件的后缀名必须是 `.exs`。在运行测试之前，我们要先用 `ExUnit.start()` 来启动 ExUnit，这一般在 `test/test_helper.exs` 已经帮我们做了。

上节课我们自动生成的示例项目中，mix 已经帮我们创建了一个简单的测试，你可以在 `test/example_test.exs` 文件中看到：

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :world
  end
end
```

执行 `mix test` 命令，我们就能运行项目的测试了，执行之后会看到类似下面的输出：

```shell
..

Finished in 0.03 seconds
2 tests, 0 failures
```

为什么在最后的测试输出里会有两个点？除了在 `test/example_test.exs` 的测试外，Mix 还在 `lib/example.ex` 里生成了一个文档测试。

### 断言（assert）

如果你之前写过测试，那对 `assert` 已经很熟悉了，在有些测试框架中， `should` 或者 `expect` 的功能和 `assert` 一样。

我们在测试文件中使用 `assert` 宏来检查表达式为真，如果表达式不为真，就会抛出异常，测试也就失败了。为了看看失败的情况，我们修改一下项目的测试，然后运行 `mix test`:


```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :word
  end
end
```

这次看到的输出和之前大不相同：

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

ExUnit 会告诉我们错误断言出现的行数，期望的值是什么，实际运行的值是什么。

### refute

`refute` 和 `assert` 的关系就像 `unless` 和 `if` 的关系一样，如果要保证某个表达式一定是假的，请使用 `refute`。

### assert_raise

有时候会断言某个错误被抛出，我们可以使用 `assert_raise` 做这件事，我们会在后面 Plug 的课程中看到 `assert_raise` 的例子。

### assert_receive

在 Elixir 语言中，会有很多 actors/processes 之间互相发送消息，因此有时候需要测试某些消息是否被发送。因为 ExUnit 是运行在自己的 process 的，因此可以像其他 process 那样接受消息。你可以使用 `assert_received` 来断言消息：

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

`assert_reveived` 并不会等待消息，如果需要，你可以使用 `assert_reveive` 并指定超时时间。

### capture_io 和 capture_log

使用 `ExUnit.CaptureIO` 可以在不改变原来应用的情况下，捕获应用的输出。只要把生成输出的函数作为参数传进去就行：

```elixir
defmodule OutputTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "outputs Hello World" do
    assert capture_io(fn -> IO.puts("Hello World") end) == "Hello World\n"
  end
end
```

`ExUnit.CaptureLog` 就是捕获 `Logger` 的输出。

## Test 配置

有时候我们需要在执行真正的测试之前做一下配置工作，我们可以使用 `setup` 和 `setup_all` 这两个宏。`setup` 在某个测试用例之前都会被运行，`setup_all` 只会在整套测试之前运行一次。它们两个的返回值是元组：`{:ok, state}`，其中 `state` 可以再后续的测试中被使用。

为了方便举例子，我们把测试代码修改一下，添加上 `setup_all`：

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

Elixir 对 mocking 的建议是：不要使用 mocking。你可能不自觉地想使用 mock，但是它不被 Elixir 社区推荐是有充分理由的。如果你代码遵循良好的设计原则，它们会很容易测试。

[这里这篇文章](http://blog.plataformatec.com.br/2015/10/mocks-and-explicit-contracts/)更详细的讨论。其中的要点是，定义对外代码的接口（行为），然后在测试时使用模拟的实现比直接在测试代码中 mock 一个依赖要好。

要切换这个行为的实现，首选的方式是把实现行为的模块名当作参数传递，并设定默认值。如果这样不行的话，可以用配置的方式来实现。这样，你不需要任何 Mocking 的库，只需要用到行为和回调就可以了。
