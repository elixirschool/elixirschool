%{
  version: "1.0.1",
  title: "Mox",
  excerpt: """
  Mox 是 Elixir 中用于设计并发 Mock 的工具。
  """
}
---

## 编写测试代码

测试和它们所依赖的 Mock ，在任何语言中一般都不算值得关注的亮点，因此关于这些知识的文章较少也许并不奇怪。
但是，在 Elixir 中 Mock  _绝对用得到_ ！
在 Elixir 中，使用 Mock 的具体方法可能与你熟悉的其他语言不同，但最终目的完全一样： Mock 可以任意重写内部函数的输出，从而允许你访问到代码中所有可能的执行路径。

在我们开始研究更复杂的用例之前，让我们先讨论一些可以提高代码可测试性的技术。
一种简单的策略是直接将依赖的模块作为参数传递给函数，而不是在函数内部硬编码这些模块。

例如，如果我们在函数内部硬编码了一个 http 客户端库：

```elixir
def get_username(username) do
  HTTPoison.get("https://elixirschool.com/users/#{username}")
end
```

我们可以将其替换为把这个 http 客户端库作为函数参数传入：

```elixir
def get_username(username, http_client) do
  http_client.get("https://elixirschool.com/users/#{username}")
end
```

或者我们也可以使用 [apply/3](https://hexdocs.pm/elixir/Kernel.html#apply/3) 函数来完成这个工作：

```elixir
def get_username(username, http_client) do
  apply(http_client, :get, ["https://elixirschool.com/users/#{username}"])
end
```

将模块作为参数传递有助于关注点分离，如果不拘泥于面向对象中的标准定义，我们可能会将这样的控制反转视为某种 [依赖注入](https://en.wikipedia.org/wiki/Dependency_injection) 。
为了测试 `get_username/2` 方法， 你只需要传入一个模块，确保其 `get` 方法可以返回你需要使用的值。

这个设计过于简单粗暴，因此只在函数能够被完全访问时可用（反过来，例如在私有函数中埋得很深的部分，即不可用）。

更灵活的方式是利用配置文件实现 Mock 。
也许你还没有意识到，但是 Elixir 程序确实在配置文件中动态维护状态。
除了对模块进行硬编码或将其作为参数传递，你也可以从配置文件中读取它。

```elixir
def get_username(username) do
  http_client().get("https://elixirschool.com/users/#{username}")
end

defp http_client do
  Application.get_env(:my_app, :http_client)
end
```

然后，在你的配置文件中写入：

```elixir
config :my_app, :http_client, HTTPoison
```

这种结构和对应的应用变量依赖，构成了以下所有内容的基础。

如果再往前想一步，你可以省略 `http_client/0` 函数并直接调用 `Application.get_env/2` ，或者更进一步，为 `Application.get_env/3` 提供第三个参数作为默认值，并且实现相同的效果。

利用应用变量，我们可以为每个环境定义特定的模块引用： 你可能会在 `dev` 环境中引用一个沙盒模块，而在 `test` 环境中使用一个内存模块。

当然，每个环境只有一个固定模块或许不够灵活：根据函数的不同使用方式，你可能需要返回不同的响应，来测试全部可能的执行路径。
很多人不知道的是， Elixir 程序可以在运行时 _动态修改_ 配置信息！
让我们把目光转向 [Application.put_env/4](https://hexdocs.pm/elixir/Application.html#put_env/4) 。

想象一下，你的应用程序需要根据 HTTP 请求是否成功而采取不同的响应。
我们可以创建多个模块，每个模块都有一个 `get/1` 函数。
一个模块返回一个 `:ok` 元组，另一个则返回一个 `:error` 元组。
然后，在调用 `get_username/1` 函数之前，可以使用 `Application.put_env/4` 来动态写入应用变量。
测试模块应该会类似于这样：

```elixir
# 不要这样写！
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

假设你已经在某处创建了所需的模块（ `HTTP200Mock` 和 `HTTP404Mock` ）。
我们在 [`setup`](https://hexdocs.pm/ex_unit/master/ExUnit.Callbacks.html#setup/1) 宏中，定义了一个 [`on_exit`](https://hexdocs.pm/ex_unit/master/ExUnit.Callbacks.html#on_exit/2) 函数回调，以确保 `:http_client` 在每次测试后，都能返回到之前的状态。

但是，类似上面的测试范式，往往 _并非_ 你应当遵守的最佳实践！
其原因可能不容易被发现。

首先，对于我们所定义的 `:http_client` 对应的 Mock 模块，无法保证它带有必要的功能接口： 在本例中，我们无法确保它具有我们所需要的 `get/1` 方法。

其次，上述测试在异步运行下，无法保证线程安全。
因为应用的状态在 _全局作用域_ 中共享， `:http_client` 很可能在某一组测试中被修改，但（同时运行的）另一组测试的正确运行，将会依赖 `:http_client` 被修改前的结果。
如果你测试代码时，测试用例 _在大部分情况下_ 会成功，但有时莫名其妙地失败，可能就是遇到了这种问题。

最后，这样的写法可能会让代码变得非常混乱，因为你将不得不在项目的某个位置中，填入大量的 Mock 模块。

虽然有许多问题，我们还是展示了上面的结构，因为它让我们聚焦于 Mock 的方法本身，这有助于我们了解 _真正_ 解决方案的工作原理。

## Mox : 所有问题的终极答案

在Elixir中使用 Mock 的首选工具是 [Mox](https://hexdocs.pm/mox/Mox.html) ，作者为 José Valim ，它解决了上面列出的所有问题。

记住：作为先决条件，我们的代码需要从配置文件中动态加载它所依赖的模块：

```elixir
def get_username(username) do
  http_client().get("https://elixirschool.com/users/#{username}")
end

defp http_client do
  Application.get_env(:my_app, :http_client)
end
```

然后你需要把 `mox` 加入项目的依赖项：

```elixir
# mix.exs
defp deps do
  [
    # ...
    {:mox, "~> 0.5.2", only: :test}
  ]
end
```

执行 `mix deps.get` 命令以完成安装。

然后，修改 `test_helper.exs` 文件来完成以下工作：

1. 定义一个或多个 Mock
2. 为 Mock 设置好相应的应用变量

```elixir
# test_helper.exs
ExUnit.start()

# 1. 定义动态 Mock 
Mox.defmock(HTTPoison.BaseMock, for: HTTPoison.Base)
# ... etc...

# 2. 覆盖原始应用变量（或将这部分加入到 config/test.exs 中）
Application.put_env(:my_app, :http_client, HTTPoison.BaseMock)
# ... etc...
```

关于 `Mox.defmock` 需要注意的几个重要事项：第一个参数名称可以是任意的。
在 Elixir 中，模块名只是原子 -- 你不需要主动创建对应的模块， 你只需要为这个模块“预留”一个确保不会重复的名字。
作为幕后工作， Mox 将会在BEAM中动态创建一个以这个名字命名的模块。

第二个麻烦的问题是 `for:` 引用的模块 _必须_ 是一种行为：它 _必须_ 定义相关回调函数。
Mox 在这个模块上使用自省（ introspection ），你只能在定义了 `@callback` 之后，定义模拟函数。
这就是使用 Mox 所约定的方式。
有时很难找到行为模块：例如， `HTTPoison` 依赖于 `HTTPoison.Base` ，但除非你查看它的源代码，否则你很难发现这一点。
如果你尝试为第三方包创建模拟，你可能会发现它不存在任何依赖的行为！
在这种情况下，您可能需要自定义对应的行为和 `@callback` 以满足约定的要求。

这里展现了一个重要的场景：您可能想要使用抽象层（又名 [indirection](https://en.wikipedia.org/wiki/Indirection) ），因此您的应用程序不 _直接_ 依赖于第三方包，但是您会依赖自己的模块，而该模块又依赖该包。
对于精心设计的应用程序来说，定义正确的“边界”很重要，但是 Mock 的机制不会改变，所以无需为此感到困扰。

最后，在你的测试模块中，你可以通过导入 `Mox` 并调用它的 `:verify_on_exit!` 函数，以使用你的 Mock 。
然后，您可以进行一次或多次对 `expect` 函数的调用，从而在模拟模块上，自由定义需要的返回值：

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

对于每个测试，我们引用 _同一个_ Mock 模块（在本例中为 `HTTPoison.BaseMock` ），并且我们使用 `expect` 函数来定义每个被调用函数的返回值。

使用 `Mox` 对于异步执行是安全的，它要求每个 Mock 都遵循一个约定。
由于这些 Mock 是“虚拟的”，因此不需要用户定义会使应用程序混乱的真实模块。

欢迎来到 Elixir Mock 的世界！
