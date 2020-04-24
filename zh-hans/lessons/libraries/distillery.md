---
version: 2.0.1
title: Distillery (基础)
---

Distillery 是纯 Elixir 编写的发布管理工具。它可以让你在极少，甚至不需要配置的情况下生成发布包，并部署到其它环境。

## 什么是发布包？

一个发布包就是包含了 Erlang/Elixir 编译码的代码包（也就是 [BEAM](https://en.wikipedia.org/wiki/BEAM_(Erlang_virtual_machine)) [字节码](https://en.wikipedia.org/wiki/Bytecode)）。它里面还提供运行程序必须的脚本。

> 当你编写了一个或多个应用后，你或许想创造一个包含了这些应用和 Erlang/OTP 应用子集的完整系统。这个就是一个发布包。—— [Erlang 文档](http://erlang.org/doc/design_principles/release_structure.html)

> 发布包简化了应用测部署：它们是自包含的，并提供了启动所需的所有东西；还可以通过内置命名行脚本来轻松地管理它们，包括打开远程命令行，启动/停止/重启应用，后台启动，发送远程命令等。另外，它们还是可归档保存的成品，意味着你可以在未来任意时刻，通过这个压缩包恢复到旧版本的系统（除非和底层的 OS 或系统库不兼容）。发布包的使用是热更新或降级的必备条件，而这正是 Erlang VM 最强大的特性之一。—— [Distillery 文档](https://hexdocs.pm/distillery/introduction/understanding_releases.html)

一个发布包包含以下内容：

* /bin 文件夹
  * 这包含了整个应用启动的脚本。
* /lib 文件夹
  * 这包含了应用编译后的字节码，及其所有依赖。
* /releases 文件夹
  * 这包含了发布包，及其钩子和自定义命令的元数据。
* /erts-VERSION
  * 这是 Erlang 运行时环境。它可以让你的机器在没有安装 Erlang 或 Elixir 的情况下运行你的应用。

### 入门及安装

把 Distillery 当作依赖，添加到你项目里 的 `mix.exs` 文件里头。*注意* —— 如果你的是 umbrella 应用，请把它添加到项目根目录的 mix.exs 文件里。

```
defp deps do
  [{:distillery, "~> 2.0"}]
end
```

然后在命令行输入：

```
mix deps.get
```

```
mix compile
```


### 生成发布包

在命令行，运行

```
mix release.init
```

命令完成后会产生一个 `rel` 目录，并包含一些配置文件在里面。

然后运行 `mix release` 就可以生成一个发布包。

发布包一生成，命令行应该会出现以下指引。

```
==> Assembling release..
==> Building release book_app:0.1.0 using environment dev
==> You have set dev_mode to true, skipping archival phase
Release successfully built!
To start the release you have built, you can use one of the following tasks:

    # start a shell, like 'iex -S mix'
    > _build/dev/rel/book_app/bin/book_app console

    # start in the foreground, like 'mix run --no-halt'
    > _build/dev/rel/book_app/bin/book_app foreground

    # start in the background, must be stopped with the 'stop' command
    > _build/dev/rel/book_app/bin/book_app start

If you started a release elsewhere, and wish to connect to it:

    # connects a local shell to the running node
    > _build/dev/rel/book_app/bin/book_app remote_console

    # connects directly to the running node's console
    > _build/dev/rel/book_app/bin/book_app attach

For a complete listing of commands and their use:

    > _build/dev/rel/book_app/bin/book_app help
```

在命令行输入命令 ` _build/dev/rel/MYAPP/bin/MYAPP foreground` 就可以启动你的应用。当然，你需要把 MYAPP 替换为你的项目名称。这样我们就已经通过发布包来运行我们的应用了！

## 在 Phoenix 项目中使用 Distillery

如果你需要结合 Phoenix 来使用 Distillery，有一些额外的步骤需要执行。

首先，编辑 `config/prod.exs` 文件。把以下内容：

```
config :book_app, BookAppWeb.Endpoint,
  load_from_system_env: true,
  url: [host: "example.com", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"
```

更改为：

```
config :book_app, BookApp.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [host: "localhost", port: {:system, "PORT"}],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  root: ".",
  version: Application.spec(:book_app, :vsn)
```

这里做的修改是：
- `server` —— 在系统启动的时候，运行 Cowboy 应用的 http 服务
- `root` —— 配置系统根目录，也就是放置并提供静态文件的路径。
- `version` —— 当系统版本升级的时候，系统缓存就会被清除。
- `port` —— 根据 ENV 环境变量，在系统启动的时候设置端口，通过 `PORT=4001 _build/prod/rel/book_app/bin/book_app foreground`

如果执行上述命令的时候，系统由于找不到数据库而崩溃了。我们可以通过 Ecto `mix` 命令来修复这个错误。在命令行，输入：

```
MIX_ENV=prod mix ecto.create
```

这个命令可以帮你创建数据库。尝试重新启动系统，这时候应该正常了。但是，你会发现数据库的升级脚本还没有运行。通常，在开发阶段，这些升级脚本都是手动调用 `mix.ecto migrate` 来运行的。到了发布阶段，我们希望它能自动按照配置运行。

## 在生产环境运行数据库升级脚本

Distillery 可以让我们在发布生命周期的不同时刻执行代码。这些点被称之为 [boot-hooks](https://hexdocs.pm/distillery/1.5.2/boot-hooks.html)。Distillery 提供的钩子包括：

* pre_start
* post_start
* pre/post_configure
* pre/post_stop
* pre/post_upgrade

根据我们的需要，`post_start` 是在生产环境运行数据库升级脚本的点。我们先创建一个叫 `migrate` 的发布任务。这个任务是一个可以在命令行调用的模块函数入口，它包含了和系统应用去分开的代码。通常我们会把那些系统本身不需要运行的任务都放在这里。

```
defmodule BookAppWeb.ReleaseTasks do
  def migrate do
    {:ok, _} = Application.ensure_all_started(:book_app)

    path = Application.app_dir(:book_app, "priv/repo/migrations")

    Ecto.Migrator.run(BookApp.Repo, path, :up, all: true)
  end
end
```

*注意* 通常，好的做法是确保系统各部分都正常启动后，再运行这些升级脚本。[Ecto.Migrator](https://hexdocs.pm/ecto/2.2.8/Ecto.Migrator.html) 可以帮助我们连接数据库，然后运行脚本。

接着，创建新的文件 —— `rel/hooks/post_start/migrate.sh` 并加入如下代码：

```
echo "Running migrations"

bin/book_app rpc "Elixir.BookApp.ReleaseTasks.migrate"
```

我们需要使用 Erlang 的 `rpc` 模块，通过远程程序调用服务（Remote Produce Call）来正确执行代码。简单来说，它能让我们在远程节点执行函数调用，获取回结果。一般来说，我们的系统应用在生产环境都是运行在好几个不同的节点上面的。

最后，在 `rel/config.exs` 文件，我们加入如下钩子到 prod 的配置里。

把一下配置：

```
environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"TkJuF,3nc4)OWPBpPxPDb6mz$>)>a>/v/,l2}W*sUFaz<)bG,v*3pPESE,`XOk{,"
  set vm_args: "rel/vm.args"
end
```

替换为：

```
environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"TkJuF,3nc4)OWPBpPxPDb6mz$>)>a>/v/,l2}W*sUFaz<)bG,v*3pPESE,`XOk{,"
  set vm_args: "rel/vm.args"
  set post_start_hooks: "rel/hooks/post_start"
end
```

*注意* —— 这个钩子只在应用的 production 发布包里。如果我们使用默认的 development 发布包，它并不会运行。

## 自定义命令

当发布的时候，你可能没有权限运行 `mix` 命令因为在要部署的机器上并没有安装 `mix`。我们可以通过创建自定义命令来解决这个问题。

> 自定义命令是启动脚本的扩展。它和 foreground 或者 remote_console 的使用方法是一样的，也就是说，它们会成为启动脚本的一部分。就像钩子一样，它们能访问启动脚本的辅助函数和环境 —— [Distillery 文档](https://hexdocs.pm/distillery/1.5.2/custom-commands.html)

命令和发布任务一样是函数，但不同的地方在于它们是通过命令行执行，而不是通过发布脚本来运行。

既然我们能运行升级脚本了，我们或许还需要通过命令来为数据库提供基础数据。首先，在我们的发布任务模块添加一个新的函数。在 `BookAppWeb.ReleaseTasks`，加入以下代码：

```
def seed do
  seed_path = Application.app_dir(:book_app_web, "priv/repo/seeds.exs")
  Code.eval_file(seed_path)
end
```

接着，创建文件 `rel/commands/seed.sh` 并加入代码：

```
#!/bin/sh

release_ctl eval "BookAppWeb.ReleaseTasks.seed/0"
```


*注意* - `release_ctl()` 是 Distillery 提供的脚本，可以让我们在本地或者一个干净的节点运行命令。如果需要在一个运行中的节点执行命令，你需要使用 `release_remote_ctl()`。

需要了解更多 Distillery 的脚本，可以参考[这里](https://hexdocs.pm/distillery/extensibility/shell_scripts.html)

最后，在 `rel/config.exs` 文件里，加入：

```
release :book_app do
  ...
  set commands: [
    seed: "rel/commands/seed.sh"
  ]
end
```

谨记，需要运行 `MIX_ENV=prod mix release` 来重新生成发布包。一旦完成，你就可以在命令行运行 `PORT=4001 _build/prod/rel/book_app/bin/book_app seed`。
