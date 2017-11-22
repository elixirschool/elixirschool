---
version: 0.9.1
title: Plug
---

如果你熟悉 Ruby 你可以把 Plug 想成 Rack，再加上一点 Sinatra。它提供了编写 Web 应用组件的一组规范，以及接入 Web 服务器所需的一些适配器。虽然 Plug 不属于 Elixir 的核心库，但它依然是一个 Elixir 官方维护的项目。

{% include toc.html %}

## 安装

通过 mix 安装十分简单。为安装 Plug 我们要对 `mix.exs` 做两处修改。首先是将 Plug 和一个 Web 服务器(这里我们使用 Cowboy)加入依赖：

```elixir
defp deps do
  [{:cowboy, "~> 1.1.2"}, {:plug, "~> 1.3.4"}]
end
```

最后我们需要将 Plug 和 Web 服务器都加入 OTP 应用中。

```elixir
def application do
  [applications: [:cowboy, :logger, :plug]]
end
```

## Plug 规范

在着手创建 Plug 之前，我们需要了解并遵循 Plug 所指定的规范。虽然听起来很复杂, 但实际上只有两个函数是必须的：`init/1` 和 `call/2`。

其中 `init/1` 函数用来初始化该 Plug 的设置，其结果将作为 `call/2` 函数的第二个参数传入。`call/2` 的第一个参数是一个 `%Plug.Conn` 结构，同时它也应当返回一个该结构。

下面是一个简单的 Plug，它会返回 "Hello World"：

```elixir
defmodule HelloWorldPlug do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Hello World!")
  end
end
```

## 创建一个 Plug

这一次我们要创建一个 Plug 来验证请求中是否包含了指定的参数组。通过在一个 Plug 中实现验证功能，我们可以确保只有合法的请求才能进入我们的应用。我们要求这个 Plug 使用两个参数来初始化：`:paths` 和 `:fields`。这两个参数分别表示哪些路径需要被验证以及合法的请求需要包含哪些字段。

_注意_：Plug 会应用到所有的请求上，所以我们需要对请求进行过滤，只在其中一部分上执行所需的逻辑。对无需处理的情况我们直接返回传入的连接结构即可。

我们先看看完成后的 Plug，然后谈谈它是如何工作的。我们在 `lib/plug/verify_request.ex` 创建该 Plug：

```elixir
defmodule Example.Plug.VerifyRequest do
  import Plug.Conn

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

首先注意到我们定义了一个新的异常 `IncompleteRequestError` 并且设置了 `:plug_status`。这样 Plug 会在触发该异常时使用该参数的值作为 HTTP 状态码。

我们所写的 Plug 第二部分就是 `call/2` 函数。我们在这里决定是否执行验证逻辑。即只有当该请求的路径包含在我们指定的 `:paths` 选项中时才会执行 `verify_request!/2`。

最后一部分是私有函数 `verify_request!/2`，它会验证是否指定的 `:fields` 都存在于请求中。如果有缺失我们就抛出一个 `IncompleteRequestError`。

## 使用 Plug.Router

现在我们完成了 `VerifyRequest` plug，接下来该实现路由了。不过我们很快会发现，在 Elixir 里我们不再需要类似 Sinatra 的框架，因为 Plug 已经提供了这样的功能。

首先创建文件 `lib/plug/router.ex` 并拷贝如下代码：

```elixir
defmodule Example.Plug.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Welcome"))
  match(_, do: send_resp(conn, 404, "Oops!"))
end
```

这是一段十分精简同时又很易懂的路由代码。我们在 `use Plug.Router` 的同时也引入了一些宏，然后启用了两个自带的 Plug：`:match` 和 `:dispatch`。这里定义了两个路由项，一个处理访问根路径的请求，另一个会匹配其余所有的请求并返回 404 错误。

然后我们把 Plug 加入路由代码中：

```elixir
defmodule Example.Plug.Router do
  use Plug.Router

  alias Example.Plug.VerifyRequest

  plug(Plug.Parsers, parsers: [:urlencoded, :multipart])

  plug(
    VerifyRequest,
    fields: ["content", "mimetype"],
    paths: ["/upload"]
  )

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Welcome"))
  post("/upload", do: send_resp(conn, 201, "Uploaded"))
  match(_, do: send_resp(conn, 404, "Oops!"))
end
```

完成了！我们已经启用了刚刚编写的 Plug 来验证所有访问 `/upload` 的请求只有包括了 `content` 和 `mimetype` 时才会进一步执行路由部分的代码。

虽然现在 `/upload` 还没什么用，但我们已经了解了如何创建及整合 Plug。

## 运行我们的 Web 程序

要运行我们的应用我们需要先设置 Web 服务器，在这个例子中我们用 Cowboy。现在我们只做必要的几处修改，更多细节我们会在后面的课程中继续深入。

首先更新 `mix.exs` 中的 `application` 部分，提示 Elixir 我们应用的入口并配置一个环境变量。完成后这部分代码类似这样：

```elixir
def application do
  [applications: [:cowboy, :plug], mod: {Example, []}, env: [cowboy_port: 8080]]
end
```

接下来我们需要更新 `lib/example.ex` 来启动和监控 Cowboy：

```elixir
defmodule Example do
  use Application

  def start(_type, _args) do
    port = Application.get_env(:example, :cowboy_port, 8080)

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Example.Plug.Router, [], port: port)
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

现在可以通过如下命令来启动我们的应用：

```shell
$ mix run --no-halt
```

## 测试 Plug

借助 `Plug.Test` 我们可以很直观地测试 Plug。该模块包括了许多方便测试的函数。

看看你能否理解这段路由测试代码：

```elixir
defmodule RouterTest do
  use ExUnit.Case
  use Plug.Test

  alias Example.Plug.Router

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

## 可用的 Plug

有许多 Plugs 都是默认提供的。Plug [文档](https://github.com/elixir-lang/plug#available-plugs)里有完整的列表。
