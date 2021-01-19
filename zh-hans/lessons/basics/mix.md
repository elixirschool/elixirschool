---
version: 1.1.1
title: Mix
---

在更深入了解 Elixir 之前，我们必须先学习 mix。如果你熟悉 Ruby 的话，mix 就是 Bundler，RubyGems 和 Rake 的结合。mix 对于开发 Elixir 至关重要，我们在这篇课程只会介绍它的部分特性。要查看 Mix 在当前环境中提供的所有内容，请运行 `mix help`。

直到现在，我们还一直用 `iex` 和 Elixir 打交道，这种方法明显是有局限的。在编写大型项目的时候，为了方便管理，我们会把代码分成不同的文件，mix 就是为了管理项目而生的。

{% include toc.html %}

## 新建项目

要创建一个新的项目，只要运行 `mix new` 命令就行，非常简单。这个命令能帮我们自动生成项目的目录和一些标准的模板文件。很容易理解吧，那我们开始创建项目：

```bash
$ mix new example
```

从终端上的输出，我们可以看到 mix 已经帮我们创建了目录和模板文件：

```bash
* creating README.md
* creating .gitignore
* creating .formatter.exs
* creating mix.exs
* creating lib
* creating lib/example.ex
* creating test
* creating test/test_helper.exs
* creating test/example_test.exs
```

这篇课程我们只关心 `mix.exs` 这个文件，因为我们会用这个文件配置应用、依赖、环境信息还有版本。用你最喜欢的编辑器打开这个文件，你会看到类似下面的内容（简洁起见，注释已经删除）：

```elixir
defmodule Example.Mix do
  use Mix.Project

  def project do
    [
      app: :example,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end
end
```

我们先来看 `project` 这部分的内容，我们在 `app` 变量定义了应用名称，`version` 定义版本号，`elixir` 定义 Elixir 的版本号，以及 `deps` 定义我们的依赖。

下面还会讲到，`application` 部分的内容在生产应用文件的时候会用到。

## 交互

有时候需要用 `iex` 和我们的项目交互，幸运的是，mix 支持这个功能。编译了项目之后，我们用下面的命令打开一个新的 `iex` 会话：

```bash
$ cd example
$ iex -S mix
```

这样 `iex` 启动的时候会把你的应用和依赖都加载到当前环境（这样你可以直接在 `iex` 中导入和运行编译好的代码）。

## 编译

Mix 很智能，能够在需要的时候自动编译你的改动，不过有时候还是要手动编译项目。这个部分，我们就讲讲如何编译项目，以及编译的时候都做了什么。

只要在项目的根目录运行 `mix compile` 命令，就能编译我们的项目：  
**注意：项目的混合任务只能从项目根目录中获得，否则只有全局的 Mix 任务可用**

```bash
$ mix compile
```

因为我们的项目没有多少内容，尽管编译成功，但是并没有很多内容输出：

```bash
Compiled lib/example.ex
Generated example app
```

当我们编译项目时，mix 会自动创建一个 `_build` 目录，查看 `_build` 目录，你会看到已经编译好的文件： `example.app`。

## 管理依赖

我们的项目现在还没有任何依赖，不过很快就会有了。所以我们就提前讲讲如何定义依赖以及获取依赖。

要增加新的依赖，我们首先要把它添加到 `mix.exs` 文件的 `deps` 部分，所有的依赖组成了一个列表，每个项是一个二元元祖：第一个值是原子表示的包名称，第二个是包的版本号，版本号可以省略。

我们找了一个有依赖的项目 [phoenix_slim](https://github.com/doomspork/phoenix_slim) 作为例子：

```elixir
def deps do
  [
    {:phoenix, "~> 1.1 or ~> 1.2"},
    {:phoenix_html, "~> 2.3"},
    {:cowboy, "~> 1.0", only: [:dev, :test]},
    {:slime, "~> 0.14"}
  ]
end
```

你也许已经看出来了，`cowboy` 这个依赖只有在开发和测试环境才需要。

定义好依赖，还有最后一个步骤：获取依赖。这和 `bundle install` 的效果一样：

```bash
$ mix deps.get
```

好了！我们已经定义并且获取了项目的依赖。这样有新依赖的时候，我们就知道怎么去处理了。

## 环境管理

和 Bundler 很相似，mix 也支持不同的环境。默认情况下，开箱即用的 mix 有三种配置环境：

+ `:dev` — 默认的环境
+ `:test` — 测试环境，使用 `mix test` 后面会讲到
+ `:prod` — 生产环境，把应用上线到生产环境下的配置项

可以从 `Mix.env` 变量中获取当前的环境，而且环境也可以通过 `MIX_ENV` 环境变量来配置：

```bash
$ MIX_ENV=prod mix compile
```
