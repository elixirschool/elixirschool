---
version: 1.2.0
title: 自定义 Mix 任务
---

为你的 Elixir 项目创建 Mix 自定义任务。

{% include toc.html %}

## 简介

通过增加自定义 Mix 任务来扩展你的 Elixir 项目是很常见的需求。在我们学习如何给我们的项目创建特定 Mix 任务之前，让我们来看一个已经存在的任务：

```shell
$ mix phx.new my_phoenix_app

* creating my_phoenix_app/config/config.exs
* creating my_phoenix_app/config/dev.exs
* creating my_phoenix_app/config/prod.exs
* creating my_phoenix_app/config/prod.secret.exs
* creating my_phoenix_app/config/test.exs
* creating my_phoenix_app/lib/my_phoenix_app.ex
* creating my_phoenix_app/lib/my_phoenix_app/endpoint.ex
* creating my_phoenix_app/test/views/error_view_test.exs
...
```

正如上面我们看到的 shell 命令，Phoenix 有一个自定义的 Mix 任务去生成一个新项目。要是我们也能给自己的项目创建类似的东西该多好啊，不是吗?　不卖关子啦，好消息是我们不仅可以这样做，而且用 Elixir做会非常容易。

## 起步

首先创建一个基本的 Mix 项目。

```shell
$ mix new hello

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/hello.ex
* creating test
* creating test/test_helper.exs
* creating test/hello_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

cd hello
mix test

Run "mix help" for more commands.
```

在 Mix 为我们生成的 **lib/hello.ex** 文件中，创建一个会输出 "Hello, World!" 的函数。

```elixir
defmodule Hello do
  @doc """
  每次调用都会输出 `Hello, World!`
  """
  def say do
    IO.puts("Hello, World!")
  end
end
```

## 自定义 Mix 任务

来创建我们的自定义 Mix 任务吧。新建一个目录以及文件 **hello/lib/mix/tasks/hello.ex**。在这个文件里，写以下７行代码。

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Simply runs the Hello.say/0 command."
  def run(_) do
    # 调用我们刚才创建的　Hello.say 函数
    Hello.say()
  end
end
```

注意我们 defmodule 用 `Mix.Tasks` 开头，后接我们想在命令行里执行任务时用的名字。然后第二行我们用 `use Mix.Task` 把 `Mix.Task` 这个 behaviour 引入当前命名空间。然后我们定义了一个忽略所有参数的 run 函数。在这个函数里我们调用了 `Hello` module 里的　`say` 函数。

## 加载您的应用程序

Mix 不会自动启动我们的应用程序或它的任何依赖，这对于许多 Mix 任务的使用情况来说是没有问题的，但是如果我们需要使用 Ecto 并与数据库交互呢？在这种情况下，我们需要确保 Ecto.Repo 背后的应用程序已经启动。我们有 2 种方法来处理这个问题：显式启动一个应用，或者我们可以启动我们的应用，而我们的应用又会启动其他应用。

让我们看看如何更新我们的 Mix 任务来启动我们的应用和依赖。

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Simply calls the Hello.say/0 function."
  def run(_) do
    # This will start our application
    Mix.Task.run("app.start")

    Hello.say()
  end
end
```

## Mix 任务实战

来看看我们的 Mix 任务。首先保证在命令行中我们处在这个任务能起作用的目录，然后敲 `mix hello`，我们应该会看到下面的结果：

```shell
$ mix hello
Hello, World!
```

Mix 默认非常友好。它知道人非圣贤孰能无过，也许不经意间你就会打错字，所以 Mix 会用字符串模糊匹配来给你推荐：

```shell
$ mix hell
** (Mix) The task "hell" could not be found. Did you mean "hello"?
```

不知道你有没有注意到我们刚刚用了一个新的模块属性(module attribute)？就是 `@shortdoc`，这个属性在我们发布应用的时候非常有用，比如一个用户在命令行里敲 `mix help` 的时候。

```shell
$ mix help

mix app.start         # Starts all registered apps
...
mix hello             # Simply calls the Hello.say/0 function.
...
```

注意：我们的代码必须先编译后，新任务才会出现在 `mix help` 输出中。
我们可以直接运行 `mix compile` 或者像运行 `mix hello` 那样运行我们的任务，这样就会触发编译。
