---
version: 2.2.0
title: Plug
---

如果你熟悉 Ruby，你可以把 Plug 想成 Rack，再加上一点 Sinatra。它提供了编写 Web 应用组件的一组规范，以及接入 Web 服务器所需的一些适配器。虽然 Plug 不属于 Elixir 的核心库，但它依然是一个 Elixir 官方维护的项目。

通过本课程，我们会使用 `PlugCowboy` 来从零开始打造一个简单的 HTTP 服务器。Cowboy 是一个为 Erlang 打造的简单的 HTTP 服务器。而 Plug 则为我们提供了它的 connection 适配。

当极简的 web 应用配置好后，我们将学习 Plug 的 router 以及如何在单个 web 应用内使用多个 plugs。

{% include toc.html %}

## 环境准备

本教程假设你已经安装了 1.5 版本以上的 Elixir，以及 `mix`。

先从创建一个带 supervision tree 的 OTP 项目开始：

```shell
$ mix new example --sup
$ cd example
```

我们的 Elixir 应用需要包含 supervision tree 是因为我们需要用到 Supervisor 来启动和运行我们的 Cowboy2 服务器。

## 依赖

使用 mix 添加依赖简直易如反掌。要使用 Plug 作为 Cowboy2 服务器的接口适配器，我们需要安装 `PlugCowboy` 包：

添加下面的内容到你的 `mix.exs` 文件里面的依赖部分：

```elixir
def deps do
  [
    {:plug_cowboy, "~> 2.0"},
  ]
end
```

然后，在命令行运行下面的 mix 任务拉取新添加的依赖：

```shell
$ mix deps.get
```

## Plug 规范

在着手创建 Plug 之前，我们需要了解并遵循 Plug 所指定的规范。虽然听起来很复杂, 但实际上只有两个函数是必须的：`init/1` 和 `call/2`。

下面是一个简单的 Plug，它会返回 "Hello World"：

```elixir
defmodule Example.HelloWorldPlug do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Hello World!\n")
  end
end
```

把上面的内容保存到文件 `lib/example/hello_world_plug.ex`。

`init/1` 函数使用来初始化 Plug 的配置。它会被 supervision tree 调用。现在，它只是一个空列表，并不会有什么影响。

从 `init/1` 返回的值最终会作为第二个参数，传入到 `call/2` 中。

在我们的 web 服务器，Cowboy，接收到每一个新的请求的时候，调用 `call/2` 这个函数。这个函数的第一个参数是 `%Plug.Conn{}` 这个连接结构体，它也应该返回一个 `%Plug.Conn{}` 连接结构体。

## 配置项目的应用模块

我们需要在应用启动的时候，告知它启动并监控 Cowboy web 服务器。

这是通过 [`Plug.Cowboy.child_spec/1`](https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html#child_spec/1) 函数来实现。

这个函数期望接收三个配置选项：

* `:scheme` - 原子类型的 HTTP or HTTPS 配置（`:http`, `:https`）
* `:plug` - 在 web 服务器中用作为接口的 plug 模块。你可以指定模块的名字，比如 `MyPlug`，或者是模块名字和配置的元组 `{MyPlug, plug_opts}`，`plug_opts` 将会传入 plug 模块的 `init/1` 函数。
* `:options` - 服务器配置。需要包含服务器监听和接收请求的端口号。

`lib/example/application.ex` 文件需要在 `start/2` 函数内定义好子进程 Spec：

```elixir
defmodule Example.Application do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Example.HelloWorldPlug, options: [port: 8080]}
    ]
    opts = [strategy: :one_for_one, name: Example.Supervisor]

    Logger.info("Starting application...")

    Supervisor.start_link(children, opts)
  end
end
```

**注意：**我们并不需要显式地调用 `child_spec` ，这个函数会在 Supervisor 启动进程时自动调用。所以，我们只需要提供一个包括需要启动的模块名，以及启动需要的配置选项。

这段代码将在我们应用的 supervision tree 下启动了 Cowboy2 服务器。它在 `8080` 端口下，以 HTTP 模式运行启动了 Cowboy 服务（当然你也可以指定为 HTTPS）。`Example.HelloWorldPlug` 被设定为处理收到的任何网络请求的接口。

现在我们可以启动我们的应用，并且发送一些网络请求给它处理了！要注意，因为我们通过 `--sup` 标签生成了 OTP 应用，`application` 函数使得我们的 `Example` 应用能自动启动。

在 `mix.exs` 文件内，代码如下：

```elixir
def application do
  [
    extra_applications: [:logger],
    mod: {Example.Application, []}
  ]
end
```

现在，一个最简的，基于 Plug 的 web 服务已经准备就绪。在命令行运行：

```shell
$ mix run --no-halt
```

等编译完成，`[info]  Starting application...` 在命令行出现后，打开浏览器访问 <http://127.0.0.1:8080>。浏览器页面就会显示：

```
Hello World!
```

## Plug.Router

对于绝大多数的应用来说，比如一个网站，或者 REST API 服务，你会需要一个路由器把不同路径，不同 HTTP verb 的请求转到不同的逻辑处理业务上。`Plug` 也就提供了这么一个路由器。紧接着，我们就可以看到，Elixir 并不需要类似 Sinatra 这样一个框架，因为 Plug 已经免费提供给我们了。

让我们创建一个文件 `lib/example/router.ex`，并把下面的代码复制进去：

```elixir
defmodule Example.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Welcome")
  end

  match _ do
    send_resp(conn, 404, "Oops!")
  end
end
```

以上是一个最基本的路由器，但是整段代码应该来说还是容易理解的。我们通过 `use Plug.Router` 引用了一个宏，并配置了两个内置的 Plugs：`:match` 和 `:dispatch`。然后定义了两个路由，一个处理根目录的 GET 请求，第二个匹配了其它所有的请求并返回 404 消息。

我们需要回到 `lib/example/application.ex` 文件，把 `Example.Router` 添加到 web 服务器的 supervisor tree 当中。把 `Example.HelloWorldPlug` 替换为新的路由：

```elixir
def start(_type, _args) do
  children = [
    {Plug.Cowboy, scheme: :http, plug: Example.Router, options: [port: 8080]}
  ]
  opts = [strategy: :one_for_one, name: Example.Supervisor]

  Logger.info("Starting application...")

  Supervisor.start_link(children, opts)
end
```

重新启动服务器，如果前面启动的还没有停止，可以按 `Ctrl+C` 两次把它中止。

现在，在浏览器输入 <http://127.0.0.1:8080>，就应该会出现 `Welcome` 字样。然后访问 <http://127.0.0.1:8080/waldo> 或者其它路径，返回就是 404 响应并出现 `Oops!` 字样。

## 创建另一个 Plug

在一个 web 应用中使用多个 plug 是很常见的。因为每一个 plug 只专注于它自身提供的功能。比如，我们可能有一个 plug 处理路由，一个 plug 验证请求的正确性，一个 plug 负责权限认证等。本小节，我们会再定义一个用于检查请求参数的 plug，并配置我们的应用同时使用 router 和 validation 这两个 plug。

我们要创建一个 Plug 来验证请求中是否包含了指定的参数。通过在一个 Plug 中实现验证功能，我们可以确保只有合法的请求才能进入我们的应用。我们要求这个 Plug 使用两个参数来初始化：`:paths` 和 `:fields`。这两个参数分别表示哪些路径需要被验证以及合法的请求需要包含哪些字段。

_注意_：Plug 会应用到所有的请求上，所以我们需要对请求进行过滤，只在其中一部分上执行所需的逻辑。对无需处理的情况我们直接返回传入的连接结构即可。

我们先看看完成后的 Plug，然后谈谈它是如何工作的。我们在 `lib/example/plug/verify_request.ex` 创建该 Plug：

```elixir
defmodule Example.Plug.VerifyRequest do
  defmodule IncompleteRequestError do
    @moduledoc """
    Error raised when a required field is missing.
    """

    defexception message: ""
  end

  def init(options), do: options

  def call(%Plug.Conn{request_path: path} = conn, opts) do
    if path in opts[:paths], do: verify_request!(conn.params, opts[:fields])
    conn
  end

  defp verify_request!(params, fields) do
    verified =
      params
      |> Map.keys()
      |> contains_fields?(fields)

    unless verified, do: raise(IncompleteRequestError)
  end

  defp contains_fields?(keys, fields), do: Enum.all?(fields, &(&1 in keys))
end
```

首先，注意到我们定义了一个新的异常 `IncompleteRequestError`。这样 Plug 会在触发该异常时使用该参数的值作为 HTTP 状态码。

我们所写的 Plug 第二部分就是 `call/2` 函数。我们在这里决定是否执行验证逻辑。即只有当该请求的路径包含在我们指定的 `:paths` 选项中时才会执行 `verify_request!/2`。

最后一部分是私有函数 `verify_request!/2`，它会验证是否指定的 `:fields` 都存在于请求中。如果有缺失我们就抛出一个 `IncompleteRequestError`。

我们将把 Plug 配置为验证所有访问 `/upload` 的请求，看它是否包含 `"content"` 和 `"mimetype"`。只有满足条件的请求才会执行相应的代码。

下面，我们就看看如何把这个路由配置到 Plug 上面去。编辑 `lib/example/router.ex` 并做出以下改变：

```elixir
defmodule Example.Router do
  use Plug.Router

  alias Example.Plug.VerifyRequest

  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug VerifyRequest, fields: ["content", "mimetype"], paths: ["/upload"]
  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Welcome")
  end

  get "/upload" do
    send_resp(conn, 201, "Uploaded")
  end

  match _ do
    send_resp(conn, 404, "Oops!")
  end
end
```

通过这段代码，我们的应用在运行 router 的代码前，会把接收到的请求先通过 `VerifyRequest` plug。这是由以下函数调用实现的：

 ```elixir
plug(
  VerifyRequest,
  fields: ["content", "mimetype"],
  paths: ["/upload"]
)
```

这会去自动调用 `VerifyRequest.init(fields: ["content", "mimetype"],
paths: ["/upload"])`。接着就会把参数传给 `VerifyRequest.call(conn, opts)` 函数调用。

让我们来试验一下这个 Plug！停掉正在运行的代码后（可按两次 `ctrl + c`）, 再重启服务（`mix run --no-halt`）。接下来，我们试着在浏览器中访问 <http://127.0.0.1:8080/upload> ，你会发现这个页面不能正常运作。只有浏览器提供的默认错误页面。现在，我们试着在路径后添加必须的参数 <http://127.0.0.1:8080/upload?content=thing1&mimetype=thing2>。加上必须的参数之后，我们应该就可以看到”Uploaded“的信息了。

但是，出错之后看不到任何页面显然并不是一个好的方式，我们稍后会讨论处理 Plug 错误的方法。

## HTTP 端口的可配置化

我们在前面定义 `Example` 模块和应用的时候，HTTP 端口是写死在模块代码里的。把 HTTP 端口放到配置文件，做成可配置化是比较好的做法。

我们把应用的环境变量设置到 `config/config.exs`

```elixir
use Mix.Config

config :example, cowboy_port: 8080
```

下一步，我们需要更新 `lib/example/application.ex` 来读取端口的配置，并传给 Cowboy。我们定义一个私有的函数来专门负责这部分功能。

```elixir
defmodule Example.Application do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Example.Router, options: [port: cowboy_port()]}
    ]
    opts = [strategy: :one_for_one, name: Example.Supervisor]

    Logger.info("Starting application...")

    Supervisor.start_link(children, opts)
  end

  defp cowboy_port, do: Application.get_env(:example, :cowboy_port, 8080)
end
```

`Application.get_env` 的第三个参数是默认值，当配置不存在的时候采用。

我们可以通过下面的命令来启动应用：

```shell
$ mix run --no-halt
```

## 测试 Plug

借助 `Plug.Test` 我们可以很直观地测试 Plug。该模块包括了许多方便测试的函数。

把下面这段路由测试代码写到 `test/example/router_test.exs`：

```elixir
defmodule Example.RouterTest do
  use ExUnit.Case
  use Plug.Test

  alias Example.Router

  @content "<html><body>Hi!</body></html>"
  @mimetype "text/html"

  @opts Router.init([])

  test "returns welcome" do
    conn =
      :get
      |> conn("/", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "returns uploaded" do
    conn =
      :get
      |> conn("/upload?content=#{@content}&mimetype=#{@mimetype}")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 201
  end

  test "returns 404" do
    conn =
      :get
      |> conn("/missing", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end
```

运行以下的命令进行测试：

```shell
$ mix test test/example/router_test.exs
```

## Plug.ErrorHandler

我们之前不带参数访问 <http://127.0.0.1:8080/upload> 时，无法看到友好错误页面或有效的 HTTP 状态 —— 只有浏览器的 `500 Internal Server Error` 默认错误页面。我们可以借助 [`Plug.ErrorHandler`](https://hexdocs.pm/plug/Plug.ErrorHandler.html) 来解决这个问题。
首先，打开 `lib/example/router.ex` ，修改代码如下。

```elixir
defmodule Example.Router do
  use Plug.Router
  use Plug.ErrorHandler

  alias Example.Plug.VerifyRequest

  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug VerifyRequest, fields: ["content", "mimetype"], paths: ["/upload"]
  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Welcome")
  end

  get "/upload" do
    send_resp(conn, 201, "Uploaded")
  end

  match _ do
    send_resp(conn, 404, "Oops!")
  end

  defp handle_errors(conn, %{kind: kind, reason: reason, stack: stack}) do
    IO.inspect(kind, label: :kind)
    IO.inspect(reason, label: :reason)
    IO.inspect(stack, label: :stack)
    send_resp(conn, conn.status, "Something went wrong")
  end
end
```

在模块的一开始，我们加上了 `use Plug.ErrorHandler`. 这个 Plug 会捕捉所有的错误然后调用函数 `handle_errors/2` 来处理这些错误。`handle_errors` 的第一个参数为 `conn`，第二个参数是一个包括 `:kind`，`:reason` 和 `:stack` 键值的映射。
上面的例子中，我们定义了一个非常简单的 `handle_errors` 来检查出错时的各种信息。现在，我们重启服务来试验这段代码！

现在，你再访问 <http://127.0.0.1:8080/upload>，我们会看到“Something went wrong”的错误信息。回到代码终端，你会看到如下的信息：

```shell
kind: :error
reason: %Example.Plug.VerifyRequest.IncompleteRequestError{message: ""}
stack: [
  {Example.Plug.VerifyRequest, :verify_request!, 2,
   [file: 'lib/example/plug/verify_request.ex', line: 23]},
  {Example.Plug.VerifyRequest, :call, 2,
   [file: 'lib/example/plug/verify_request.ex', line: 13]},
  {Example.Router, :plug_builder_call, 2,
   [file: 'lib/example/router.ex', line: 1]},
  {Example.Router, :call, 2, [file: 'lib/plug/error_handler.ex', line: 64]},
  {Plug.Cowboy.Handler, :init, 2,
   [file: 'lib/plug/cowboy/handler.ex', line: 12]},
  {:cowboy_handler, :execute, 2,
   [
     file: '/path/to/project/example/deps/cowboy/src/cowboy_handler.erl',
     line: 41
   ]},
  {:cowboy_stream_h, :execute, 3,
   [
     file: '/path/to/project/example/deps/cowboy/src/cowboy_stream_h.erl',
     line: 293
   ]},
  {:cowboy_stream_h, :request_process, 3,
   [
     file: '/path/to/project/example/deps/cowboy/src/cowboy_stream_h.erl',
     line: 271
   ]}
]
```

现在，我们还是回送了 `500 Internal Server Error` 这样的信息。通过添加 `:plug_status` 字段到我们的异常，我们就可以定制状态码。打开 `lib/example/plug/verify_request.ex`，更改如下：

```elixir
defmodule IncompleteRequestError do
  defexception message: "", plug_status: 400
end
```

重启服务器，刷新页面，就会出现 `400 Bad Request` 这样的消息了。

这个 Plug 可以让开发者非常容易地查看有用的错误信息，从而解决问题。同时也给终端用户一个良好的页面体验，而不至于觉得整个网站垮掉！

## 可用的 Plug

有许多 Plugs 都是默认提供的。Plug [文档](https://github.com/elixir-lang/plug#available-plugs)里有完整的列表。
