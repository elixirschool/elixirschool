---
version: 1.2.0
title: Plug
---

如果你熟悉 Ruby，Plug 可以被想成 Rack，再加上一点 Sinatra。它提供了编写 Web 应用组件的一组规范，以及接入 Web 服务器所需的一些适配器。虽然 Plug 不属于 Elixir 的核心库，但它依然是一个 Elixir 官方维护的项目。

我们先创建一个最简的 Plug web 应用。然后我们看看 Plug 的路由，以及如何把 Plug 添加到现有的 web 应用中。  

{% include toc.html %}

## 环境准备

本教程假设你已经安装了 1.4 版本以上的 Elixir，以及 `mix`。

如果你还没有创建一个初始项目，可以使用如下命令开始：  

```shell
$ mix new example
$ cd example
```

## 依赖

使用 mix 添加依赖简直易如反掌。要安装 Plug，我们只需要在 `mix.exs` 文件里面做两个小小的改动。第一个是把 Plug 和 web（我们在这里将使用 Cowboy）服务器添加到文件里面的依赖部分：  

```elixir
defp deps do
  [
    {:cowboy, "~> 1.1.2"},
    {:plug, "~> 1.3.4"}
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

因为我们的 Plug 应用从从头开始创建的，所以，我们要定义这个应用模块。修改 `lib/example.ex`，让它懂得启动并监管 Cowboy：  

```elixir
defmodule Example do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Example.HelloWorldPlug, [], port: 8080)
    ]

    Logger.info("Started application")

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

通过上面的配置，Cowboy 就在应用的监管下了，继而也监管着我们的 `HelloWorldPlug`。  

`Plug.Adapters.Cowboy.child_spec/4` 函数调用中的第三个参数，其实就是传到 `Example.HelloWorldPlug.init/1` 的配置。  

还差一点我们就配置完了。在打开文件 `mix.exs`，找到 `applications` 这个函数。我们需要配置我们的应用，让它能自动启动。  

经过如下的修改就可以了：  

```elixir
def application do
  [
    extra_applications: [:logger],
    mod: {Example, []}
  ]
end
```

现在，一个最简的，基于 Plug 的 web 服务已经准备就绪。在命令行运行：  

```shell
$ mix run --no-halt
```

等编译完成，`[info]  Started app` 在命令行出现后，打开浏览器访问 `127.0.0.1:8080`。浏览器页面就会显示：  

```
Hello World!
```

## Plug.Router

对于绝大多数的应用来说，比如一个网站，或者 REST API 服务，你会需要一个路由器把不同路径，不同 HTTP verb 的请求转到不同的逻辑处理业务上。`Plug` 也就提供了这么一个路由器。紧接着，我们就可以看到，Elixir 并不需要类似 Sinatra 这样一个框架，因为 Plug 已经免费提供给我们了。  

让我们创建一个文件 `lib/example/router.ex`，并把下面的代码复制进去：  

```elixir
defmodule Example.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Welcome"))
  match(_, do: send_resp(conn, 404, "Oops!"))
end
```

以上是一个最基本的路由器，但是整段代码应该来说还是容易理解的。我们通过 `use Plug.Router` 引用了一个宏，并配置了两个内置的 Plugs：`:match` 和 `:dispatch`。然后定义了两个路由，一个处理根目录的 GET 请求，第二个匹配了其它所有的请求并返回 404 消息。  

我们需要回到 `lib/example.ex` 文件，把 `Example.Router` 添加到 web 服务器的 supervisor tree 当中。把 `Example.HelloWorldPlug` 替换为新的路由：  

```elixir
def start(_type, _args) do
  children = [
    Plug.Adapters.Cowboy.child_spec(:http, Example.Router, [], port: 8080)
  ]

  Logger.info("Started application")
  Supervisor.start_link(children, strategy: :one_for_one)
end
```

重新启动服务器，如果前面启动的还没有停止，可以按 `Ctrl+C` 两次把它中止。  

现在，在浏览器输入 `127.0.0.1:8080`，就应该会出现 `Welcome` 字样。然后访问 `127.0.0.1:8080/waldo` 或者其它路径，返回就是 404 响应并出现 `Oops!` 字样。  

## 创建另一个 Plug

通常，我们会创建 Plug 来拦截所有或者某一类的请求，因为需要应用一些共通的逻辑到这些请求上。  

这一次，我们要创建一个 Plug 来验证请求中是否包含了指定的参数。通过在一个 Plug 中实现验证功能，我们可以确保只有合法的请求才能进入我们的应用。我们要求这个 Plug 使用两个参数来初始化：`:paths` 和 `:fields`。这两个参数分别表示哪些路径需要被验证以及合法的请求需要包含哪些字段。

_注意_：Plug 会应用到所有的请求上，所以我们需要对请求进行过滤，只在其中一部分上执行所需的逻辑。对无需处理的情况我们直接返回传入的连接结构即可。

我们先看看完成后的 Plug，然后谈谈它是如何工作的。我们在 `lib/example/plug/verify_request.ex` 创建该 Plug：

```elixir
defmodule Example.Plug.VerifyRequest do
  defmodule IncompleteRequestError do
    @moduledoc """
    Error raised when a required field is missing.
    """

    defexception message: "", plug_status: 400
  end

  def init(options), do: options

  def call(%Plug.Conn{request_path: path} = conn, opts) do
    if path in opts[:paths], do: verify_request!(conn.body_params, opts[:fields])
    conn
  end

  defp verify_request!(body_params, fields) do
    verified =
      body_params
      |> Map.keys()
      |> contains_fields?(fields)

    unless verified, do: raise(IncompleteRequestError)
  end

  defp contains_fields?(keys, fields), do: Enum.all?(fields, &(&1 in keys))
end
```

首先，注意到我们定义了一个新的异常 `IncompleteRequestError` 并且设置了 `:plug_status`。这样 Plug 会在触发该异常时使用该参数的值作为 HTTP 状态码。

我们所写的 Plug 第二部分就是 `call/2` 函数。我们在这里决定是否执行验证逻辑。即只有当该请求的路径包含在我们指定的 `:paths` 选项中时才会执行 `verify_request!/2`。

最后一部分是私有函数 `verify_request!/2`，它会验证是否指定的 `:fields` 都存在于请求中。如果有缺失我们就抛出一个 `IncompleteRequestError`。  

我们将把 Plug 配置为验证所有访问 `/upload` 的请求，看它是否包含 `"content"` 和 `"mimetype"`。只有满足条件的请求才会执行相应的代码。  

下面，我们就看看如何把这个路由配置到 Plug 上面去。编辑 `lib/example/router.ex` 并做出以下改变：  

```elixir
defmodule Example.Router do
  use Plug.Router
  use Plug.ErrorHandler

  alias Example.Plug.VerifyRequest

  plug(Plug.Parsers, parsers: [:urlencoded, :multipart])

  plug(
    VerifyRequest,
    fields: ["content", "mimetype"],
    paths: ["/upload"]
  )

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Welcome\n"))
  post("/upload", do: send_resp(conn, 201, "Uploaded\n"))
  match(_, do: send_resp(conn, 404, "Oops!\n"))
end
```

## HTTP 端口的可配置化

我们在前面定义 `Example` 模块和应用的时候，HTTP 端口是写死在模块代码里的。把 HTTP 端口放到配置文件，做成可配置化是比较好的做法。  

我们可以修改 `mix.exs` 的 `application` 部分，并设置一个应用的环境变量。经过以上更改，我们的代码应该变成以下的样子：  

```elixir
def application do
  [
    extra_applications: [:logger],
    mod: {Example, []},
    env: [cowboy_port: 8080]
  ]
end
```

我们的应用是通过 `mod: {Example, []}` 这一行来配置的。我们的应用在启动的同时，`cowboy`，`logger` 和 `plug` 这几个应用也被启动了。

下一步，我们需要更新 `lib/example.ex` 来读取端口的配置，并传给 Cowboy：  

```elixir
defmodule Example do
  use Application

  def start(_type, _args) do
    port = Application.get_env(:example, :cowboy_port, 8080)

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Example.Router, [], port: port)
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

`Application.get_env` 的第三个参数是默认值，当配置不存在的时候采用。  

>（可选）把 `:cowboy_port` 添加到 `config/config.exs` 里

```elixir
use Mix.Config

config :example, cowboy_port: 8080
```

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
      conn(:get, "/", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "returns uploaded" do
    conn =
      conn(:post, "/upload", "content=#{@content}&mimetype=#{@mimetype}")
      |> put_req_header("content-type", "application/x-www-form-urlencoded")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 201
  end

  test "returns 404" do
    conn =
      conn(:get, "/missing", "")
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

## 可用的 Plug

有许多 Plugs 都是默认提供的。Plug [文档](https://github.com/elixir-lang/plug#available-plugs)里有完整的列表。
