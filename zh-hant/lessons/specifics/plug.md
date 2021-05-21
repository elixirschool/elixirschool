---
version: 2.2.0
title: Plug
---

如果熟悉 Ruby，可以將 Plug 視為 Rack 再加上一點 Sinatra。
它為 Web 應用程式元件提供了一套規範與 Web 伺服器一組轉接器 (adapters)。
雖然不是 Elixir 核心的一部分，但 Plug 仍是 Elixir 的正式項目。

首先將建立一個最小的基於 Plug 的 Web 應用程式。
而之後，將學習 Plug 的路由器以及如何將 Plug 加入到現有的 Web 應用程式。

在設定了最小的 Web 應用程式之後，將了解 Plug 的路由器以及如何在單個 Web 應用程式中使用多個 plug。

{% include toc.html %}

## 前置作業

本課程假設你已經安裝了 Elixir 1.5 或更高版本，並且也安裝了`mix`。

首先建立一個帶有 supervision 樹的新 OTP 專案。

```shell
$ mix new example --sup
$ cd example
```

我們需要 Elixir 的應用程式中包含 supervision 樹，因為將使用 Supervisor 來啟動和執行 Cowboy2 伺服器。

## 耦合性

使用 mix 來加入相依關係很輕鬆。
要將 Plug 用作 Cowboy2 Web 伺服器的轉接器界面，需要安裝 `PlugCowboy` 套件：

將以下內容加入到 `mix.exs` 檔案中：

```elixir
def deps do
  [
    {:plug_cowboy, "~> 2.0"},
  ]
end
```

在命令列中，執行以下 mix 工作來引入這些新的耦合性：

```shell
$ mix deps.get
```

## Plug 規範

為了開始建立 Plug，需要知道並遵守 Plug 規範。
幸運的是，只有兩個函數是必須的：`init/1` 和 `call/2`。

這是一個簡單的 Plug，回傳 "Hello World！"：

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

將該檔案儲存到 `lib/example / hello_world_plug.ex`。

`init/1` 函數用於初始化 Plug 的選項。
它由一棵 supervision 樹呼用，這在下一節中有解釋。
現在，它將成為一個被忽略的空列表。

從 `init/1` 的回傳值最終會作為第二個引數傳遞給 `call/2`。

對於來自 Web 伺服器 Cowboy 的每個新請求都會呼用 `call/2` 函數。
它接收一個 `%Plug.Conn{}` 連接 (connection) 結構體作為它的第一個引數，並且期望回傳一個 `%Plug.Conn{}` 連接結構體。

## 配置專案的應用程式模組

需要指示應用程式在初始時啟動並監督 Cowboy Web 伺服器。

將會使用 [`Plug.Cowboy.child_spec/1`](https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html#child_spec/1) 函數來做這件事。

這個函數需要三個選項：

* `:scheme` - HTTP 或 HTTPS 作為一個 atom (`:http`, `:https`)
* `:plug` - plug 模組用作 Web 伺服器的界面。
你可以指定一個模組名稱，比如 `MyPlug`，或一個模組名稱和選項 `{MyPlug, plug_opts}` 的 tuple，其中 `plug_opts` 被傳遞給你的 plug 模組 `init/1` 函數。
* `:options` - 伺服器選項。
應該包括你希望伺服器監聽請求的埠號。


我們的 `lib/example/application.ex` 檔案應該在 `start/2`函數中實現子規範：

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

_註_：不需要在這裡呼用 `child_spec`，supervisor 將在啟動此處理程序時呼用此函數。
我們簡單地傳遞一個 tuple，其中包含想要子規範構建的模組，然後是所需的三個選項。

這會在應用程式的 supervision 樹下啟動一個 Cowboy2 伺服器。
它會啟動 Cowboy 在 HTTP 結構(scheme)下執行(也可以指定HTTPS)，並在給定的埠號 `8080` 、指定的 plug `Example.HelloWorldPlug`，作為任何接入 Web 請求的界面。

現在已經準備好執行應用程式並向其發送一些 Web 請求！請注意，因為使用 `--sup` 旗標生成了一個 OTP 應用程式，所以 `Example` 應用程式將由於 `application` 函數自動啟動。

在 `mix.exs` 中你應該會看到以下內容：
```elixir
def application do
  [
    extra_applications: [:logger],
    mod: {Example.Application, []}
  ]
end
```

現在已經準備好嘗試這個簡單的，基於 Plug 的 Web 伺服器。
在命令列上，執行：

```shell
$ mix run --no-halt
```

一旦所有內容編譯完成，出現 `[info]  Starting application...` 後，打開一個 Web 頁面
並將瀏覽器導引到 <http://127.0.0.1:8080>。
瀏覽器應該顯示如下：

```
Hello World!
```

## Plug.Router

對於大多數應用程式，如網站或 REST API，需要路由器將不同路徑和 HTTP vebs 的請求路由到不同的處理程序。
`Plug` 提供了一個路由器來做到這一點。
正如即將看到的，Elixir 中不需要像 Sinatra 這樣的框架，因為可以通過 Plug 不費力的實現。

在 `lib/example/router.ex` 上建立一個檔案來開始，並將以下內容複製進去：

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

這是一個最基本的簡易路由器，程式碼應該己經不言而喻了。
通過 `use Plug.Router` 涵蓋一些巨集，然後設定兩個內建的 Plugs： `:match` 和 `:dispatch`。
有兩條定義的路由，一條用於處理對 root 的 GET 請求，另一條用於配對所有其他請求，因此可以回傳 404 訊息。

回到 `lib/example/application.ex` 中，需要將 `Example.Router` 加到 Web 伺服器的 supervisor 樹中。
用新路由器替換 `Example.HelloWorldPlug` Plug：

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

再次啟動伺服器，如果它正在執行前一個，將其停止（按 `Ctrl+C` 兩次）。

現在在 Web 瀏覽器中，進到 <http://127.0.0.1:8080>。
它應該輸出 `Welcome`。
接著，換到 <http://127.0.0.1:8080/waldo> 或任何其他路徑。
它應該會輸出 `Oops!` 並回應 404 錯誤。

## 加入另一個 Plug

在給定的 Web 應用程式中使用多個 plug 是很常見的，每個 plug 都專用於自己的責任範圍。
例如，可能有一個處理路由的 plug，一個驗證傳入 Web 請求的 plug，一個驗證接入身份驗證請求的 plug 等。
在本節中，將定義一個 plug 來驗證傳入的請求參數，並將教會應用程式使用 _兩種_ plug - 路由器和身份驗證 plug。

想要建立一個 Plug 來驗證請求是否具有一些必需的參數組。
通過在 Plug 中實現驗證，可以確保只有有效的請求才能通過應用程式。
將預期 Plug 以兩個選項初始化： `:paths` 和 `:fields`。
這些將用來呈現邏輯應用路徑以及需要哪些欄位。

_註_：Plug 適用於所有請求，這就是為什麼需要過濾請求並只將我們的邏輯應用於其中的一部分。
要忽略請求，只需簡單通過連接即可。

首先查看已完成的 Plug，然後討論它是怎麼運作的。
現在在 `lib/example/plug/verify_request.ex` 中建立它：

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

首先要注意的是我們定義了一個新的例外 `IncompleteRequestError`，將在無效請求事件時觸發它。

Plug 的第二部分是 `call/2` 函數。
這是決定是否應用驗證邏輯的地方。
只有當請求的路徑包含在 `:paths` 選項中時，才會呼用 `verify_request!/2`。

Plug 的最後一部分是私有函數 `verify_request!/2`，它驗證被請求的 `:fields` 是否全部呈現。
如果有一些遺失了，將引發 `IncompleteRequestError`。

我們已經設定 Plug 來驗證對 `/upload` 的所有請求都包含 `"content"` 和 `"mimetype"`。
只有這樣路由程式碼才能被執行。

接下來，需要讓路由器認識新的 Plug。
編輯 `lib/example/router.ex` 並進行以下更改：

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

使用此程式碼，我們告訴應用程式在執行路由器中的程式碼 _之前_ 通過 `VerifyRequest` plug 發送傳入請求。
經由函數呼用：

```elixir
plug(
  VerifyRequest,
  fields: ["content", "mimetype"],
  paths: ["/upload"]
)
```
我們自動呼用(invoke) `VerifyRequest.init(fields: ["content", "mimetype"],
paths: ["/upload"])`。
這又將給定的選項傳遞給 `VerifyRequest.call(conn, opts)` 函數。

接著來看看這個 plug 於執行中的樣子！現在讓你的本機伺服器當機 (記住，只要按 `ctrl + c` 兩次就可以完成這件事)。
接著，重新啟動伺服器 (`mix run --no-halt`)。
現在在瀏覽器中到 <http://127.0.0.1:8080/upload>，將會清楚看到該頁面無法正常運作。只會看到瀏覽器提供的預設錯誤頁面。

接著經由存取 <http://127.0.0.1:8080/upload?content=thing1&mimetype=thing2> 來加入所需的參數。
這時應該看到 'Uploaded' 訊息。
當拋出一個錯誤時沒有收到 _任何_ 頁面並不是很好，所以之後將討論如何使用 plug 來進行錯誤處理。

## 使 HTTP 通訊埠為可配置 (Configurable)

當定義了 `Example` 模組和應用程式時，HTTP 通訊埠在模組中即被寫死 (hard-coded)。
通過將設罝選項置於配置檔案中來使通訊埠成為可配置的被認為是一種很好的做法。

將設置一個應用程式使用的環境變數在 `config/config.exs` 內。

```elixir
use Mix.Config

config :example, cowboy_port: 8080
```

接下來需要更新 `lib/example/application.ex`  的讀取通訊埠配值值，並將其傳遞給 Cowboy。
我們將定義一個私有函數來包覆該責任範圍

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

`Application.get_env` 的第三個引數是預設值，用於配置指令未定義時。

要執行應用程式可以使用：

```shell
$ mix run --no-halt
```

## 測試 Plug

感謝 `Plug.Test`，測試 Plug 非常直覺。
它包含許多方便的函數，使測試變得簡單。

將以下測試寫入 `test/example/router_test.exs`：

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

用這個執行它：

```shell
$ mix test test/example/router_test.exs
```

## Plug.ErrorHandler

之前注意到，在沒有必要參數的情況下存取 <http://127.0.0.1:8080/upload> 時，不會親切的見到錯誤頁面或合理的 HTTP 狀態回應 - 只會有瀏覽器帶有 `500 Internal Server Error` 的預設錯誤頁面。

現在經由加入 [`Plug.ErrorHandler`](https://hexdocs.pm/plug/Plug.ErrorHandler.html) 來解決這個問題。

首先，開啟 `lib/example/router.ex` 然後將以下內容寫入該檔案。

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

接著注意到，在最上方，多加入 `use Plug.ErrorHandler`。

這個 plug 將捕捉任何錯誤訊息，接著尋找函數 `handle_errors/2` 後呼用來處理錯誤訊息。

`handle_errors/2` 只會需要接受 `conn` 作為第一個參數，而後是一個帶有三個項目的映射 (`:kind`、 `:reason` 和 `:stack`) 作為第二個參數。

可以看到目前已經定義了一個非常簡單的 `handle_errors/2` 函數來觀察正在發生的事情。現在停止操作並重新啟動應用程式，看看它是如何運作的！

此時，當導引到 <http://127.0.0.1:8080/upload> 時，將看到一則親切的錯誤訊息。

如果這時候查看終端機，將看到如下內容：

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

此時，仍是發送 `500 Internal Server Error`。但可以通過在異常 (exception) 中加入 `:plug_status` 欄位來自定狀態代碼。現在打開 `lib/example/plug/verify_request.ex` 並加入以下內容：

```elixir
defmodule IncompleteRequestError do
  defexception message: "", plug_status: 400
end
```

重新啟動伺服器並更新頁面，現在將收到 `400 Bad Request`。

這個 plug 可以很容易地捕捉開發者修復問題所需的有用資訊，同時還能為終端使用者提供一個漂亮的頁面，讓它看起來不像我們的應用程式完全爆炸了！

## 可用的 Plugs

有許多 Plug 是隨插即用的。
完整清單可以在 Plug 文件中找到 [這裡](https://github.com/elixir-lang/plug#available-plugs)。
