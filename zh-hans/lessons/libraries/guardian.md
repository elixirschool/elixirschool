---
version: 1.0.3
title: Guardian（基础）
---

[Guardian](https://github.com/ueberauth/guardian) 是一个广泛使用的，基于 [JWT](https://jwt.io/) (JSON Web Tokens) 的验证程序库。  

{% include toc.html %}

## JWTs

一个 JWT 能为验证提供一个包含了丰富的信息的令牌。不像其它验证系统，可能只提供了资源主体的标识符，JWTs 除此之外还能提供如下信息：  

* 谁签发的令牌  
* 令牌的拥有者是谁  
* 哪个系统使用这个令牌  
* 令牌签发的时间  
* 令牌过期的时间  

除了这些字段以外，Guardian 还提供了另一些字段来辅助其它一些功能的使用：  

* 令牌的类型是什么  
* 令牌的拥有者具有哪些权限  

这些只是 JWT 里面的基础字段。你可以任意添加你的应用需要的额外信息到里面。要记住的是保持 JWT 简短，因为它是需要通过 HTTP header 传递的。  

JWT 内涵的丰富性意味着你可以把它当作完整的认证信息在系统内传递。  

### 使用场景

JWT 令牌可以被用来认证系统的任何一个部分。  

* 单页应用  
* 控制器（通过浏览器会话）  
* 控制器（通过 API 的验证 headers）  
* Phoenix Channels
* 服务之间的请求  
* 进程间通信  
* 第三方访问（OAuth）  
* “记住我”功能  
* 其它接口 - 原始的 TCP，UDP，CLI 等

JWT 令牌可以用在任何需要提供可验证的身份认证信息之处。  

### 我需要使用数据库吗？

你不需要使用数据库来跟踪 JWT 的使用情况。简单的依靠发放日期和过期时间来控制访问就可以了。通常可能你会使用数据库来查询用户的资源，但是 JWT 本身并不需要使用数据库。  

例如，如果你想使用 JWT 来验证 UDP 通信，你不太需要用上数据库。在发放 JWT 的时候，直接包含所有需要的信息到令牌里面就可以了。只要它是可信的（检查它有正确的签名信息），就没问题。  

但是，你也可以使用数据库来跟踪 JWT。这样的好处是，你可以验证令牌是否还是有效，没有被吊销的。或者你还可以通过检查存储在数据库的记录，一次过强制登出所有的用户。使用 [GuardianDb](https://github.com/hassox/guardian_db) 能非常容易地实现上面的功能。GuardianDb 使用 Guardians 'Hooks' 来实现验证检查，数据库的保存和删除操作。稍后会介绍。  

## 配置

配置 Guardian 有好几种方式。我们都会一一介绍，先从最简单的开始。  

### 最简配置

你需要更改好几个配置。  

#### 文件配置

`mix.exs`

```elixir
def application do
  [
    mod: {MyApp, []},
    applications: [:guardian, ...]
  ]
end

def deps do
  [
    {guardian: "~> x.x"},
    ...
  ]
end
```

`config/config.exs`

```elixir
# 修改所有外部的配置文件
config :guardian, Guardian,
  issuer: "MyAppId",
  secret_key: Mix.env(),
  serializer: MyApp.GuardianSerializer
```

以上就是 Guardian 所需的最基本的信息。把密钥（secret key）直接写在配置文件里面并不是好的做法，而是每个环境应该有自己的密钥。在开发和测试环境使用 Mix 环境变量是比较常见的做法。但是，在预发和生产环境，就必须使用强密钥（比如，使用 `mix phoenix.gen.secret` 来生成）。  

`lib/my_app/guardian_serializer.ex`

```elixir
defmodule MyApp.GuardianSerializer do
  @behaviour Guardian.Serializer

  alias MyApp.Repo
  alias MyApp.User

  def for_token(user = %User{}), do: {:ok, "User:#{user.id}"}
  def for_token(_), do: {:error, "Unknown resource type"}

  def from_token("User:" <> id), do: {:ok, Repo.get(User, id)}
  def from_token(_), do: {:error, "Unknown resource type"}
end
```

你的 seralizer 负责根据 `sub`（主体）字段找到相应的资源。它可以是从数据库查找，调用 API 获取，或者只是返回简单的字符串。它同时也负责把资源序列化为 `sub` 字段值。  

这就是最简配置了。虽然还有更多其它选项，但是这样起步已经足够了。  

## 应用集成

现在 Guardian 的配置已经准备好了，就可以和我们的应用集成起来了。我们先看看如何在 HTTP 请求中使用。  

### HTTP 请求

Guardian 提供了好一些和 HTTP 请求集成的 Plugs。你可以从[另一章课程](../../specifics/plug/)中了解 Plug。Guardian 不是必须和 Phoenix 集成，但是最容易的。  

最简单的和 HTTP 集成的方式是通过路由器。因为 Guardian 的 HTTP 集成是基于 plugs 的，所以你可以在任何用 plug 的地方使用它。  

Guardian plug 使用的一般流程是这样的：  
1. 从请求（任何地方）中找到令牌，并验证：`Verify*` plugs  
2. 可选地从令牌中获取相应的资源：`LoadResource` plug  
3. 确保请求中包含有效的令牌，如果没有，拒绝访问：`EnsureAuthenticated` plug

为了满足应用开发者的需求，Guardian 分开实现了这些不同的阶段。使用 `Verify*` plugs 可以获取令牌。  

我们创建一些 Phoenix 管道（pipelines）来看看如何操作。  

```elixir
pipeline :maybe_browser_auth do
  plug(Guardian.Plug.VerifySession)
  plug(Guardian.Plug.VerifyHeader, realm: "Bearer")
  plug(Guardian.Plug.LoadResource)
end

pipeline :ensure_authed_access do
  plug(Guardian.Plug.EnsureAuthenticated, %{"typ" => "access", handler: MyApp.HttpErrorHandler})
end
```

这些管道可以被实现成不同的组合来满足各种验证的业务场景。第一个首先尝试从会话中获取令牌，如果没有的话就从 header 从找。如果找到了，它会帮你定位对应的资源。  

第二个管道确保必须有一个有效的令牌存在，并且是“access”类型。把这些 piplines 加到 scope 里就可以使用了。  

```elixir
scope "/", MyApp do
  pipe_through([:browser, :maybe_browser_auth])

  get("/login", LoginController, :new)
  post("/login", LoginController, :create)
  delete("/login", LoginController, :delete)
end

scope "/", MyApp do
  pipe_through([:browser, :maybe_browser_auth, :ensure_authed_access])

  resource("/protected/things", ProtectedController)
end
```

上面的 login 路由如果发现请求里带有验证通过的用户信息的话，会注入相应的用户。第二个 scope 则确保必须有有效的令牌才能通过后续的操作。你不是_必须_把它们配置在管道中，你还可以很灵活地配置到控制器（controller）里。不过这里是最简配置，所以才这样操作。

往事具备，只差东风了。就是添加到 `EnsureAuthenticated` plug 的错误处理。这是一个简单的模块：  

* `unauthenticated/2`
* `unauthorized/2`

这两个函数都同样接收 Plug.Conn 这个结构体，和一个参数映射表，并且处理相应的错误。你甚至还可以使用 Phoenix 的控制器！  

### 和控制器结合

在控制器里，有好几种方式从中获取当前登录的用户。我们先看最简单的方法。  

```elixir
defmodule MyApp.MyController do
  use MyApp.Web, :controller
  use Guardian.Phoenix.Controller

  def some_action(conn, params, user, claims) do
    # do stuff
  end
end
```

通过 `Guardian.Phoenix.Controller` 模块，你的操作（actions）可以获得额外两个参数。要记住的是，如果没有使用 `EnsureAuthenticated`，你获得的可能是空的 user 和 claims 值。  

另一种更灵活，或者说繁琐的方式是，使用 plug 辅助函数。  

```elixir
defmodule MyApp.MyController do
  use MyApp.Web, :controller

  def some_action(conn, params) do
    if Guardian.Plug.authenticated?(conn) do
      user = Guardian.Plug.current_resource(conn)
    else
      # No user
    end
  end
end
```

### 登入/登出

登入，和登出浏览器会话非常容易实现。在你的 login 控制器里：  

```elixir
def create(conn, params) do
  case find_the_user_and_verify_them_from_params(params) do
    {:ok, user} ->
      # Use access tokens.
      # Other tokens can be used, like :refresh etc
      conn
      |> Guardian.Plug.sign_in(user, :access)
      |> respond_somehow()

    {:error, reason} ->
      nil
      # handle not verifying the user's credentials
  end
end

def delete(conn, params) do
  conn
  |> Guardian.Plug.sign_out()
  |> respond_somehow()
end
```

当通过 API 登录的时候，处理的方式会有点不同。因为当前并没有会话，你还必须把原始的令牌返回给客户端。要处理 API 登录，你需要从 `Authorization` header 中获取令牌。这种方式对不需要保持和使用会话是可行的。  

```elixir
def create(conn, params) do
  case find_the_user_and_verify_them_from_params(params) do
    {:ok, user} ->
      {:ok, jwt, _claims} = Guardian.encode_and_sign(user, :access)
      conn |> respond_somehow(%{token: jwt})

    {:error, reason} ->
      # handle not verifying the user's credentials
  end
end

def delete(conn, params) do
  jwt = Guardian.Plug.current_token(conn)
  Guardian.revoke!(jwt)
  respond_somehow(conn)
end
```

浏览器会话登录实际上会调用 `encode_and_sign` 这个函数，所以你这样调用也是可以的。  
