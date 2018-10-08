---
version: 1.2.0
title: Plug
---

如果熟悉 Ruby，可以將 Plug 視為 Rack 再加上一點 Sinatra。它為 Web 應用程式元件提供了一套規範與 Web 伺服器一組轉接器 (adapters) 。雖然不是 Elixir 核心的一部分，但 Plug 仍是 Elixir 的正式項目。

首先將建立一個最小的基於 Plug 的 Web 應用程式。而之後，將學習 Plug 的路由器以及如何將 Plug 加入到現有的 Web 應用程式。

{% include toc.html %}

## 前置作業

本課程假設你已經安裝了 Elixir 1.4 或更高版本，並且也安裝了`mix`。

如果還沒有已經的開始的專案，請建立一個像下面的專案：

```shell
$ mix new example
$ cd example
```

## 耦合性

用 mix 來加入耦合性很輕鬆。要安裝 Plug，需要對 `mix.exs` 檔案進行兩處小改動。
首先要做的是將 Plug 和一個 Web 伺服器（將使用 Cowboy）作為耦合性加入到檔案中：

```elixir
defp deps do
  [
    {:cowboy, "~> 1.1.2"},
    {:plug, "~> 1.3.4"}
  ]
end
```

在命令列中，執行以下 mix 工作來引入這些新的耦合性：

```shell
$ mix deps.get
```

## 規範

為了開始建立 Plug，需要知道並遵守 Plug 規範。幸運的是，只有兩個函數是必須的：`init/1`和`call/2`。
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

`init/1` 函數用於初始化 Plug 的選項。它由一棵 supervision 樹呼用，這在下一節中有解釋。
現在，它將成為一個被忽略的空列表。

從 `init/1` 的回傳值最終會作為第二個引數傳遞給 `call/2`。對於來自 Web 伺服器 Cowboy 的每個新請求都會呼用 `call/2` 函數。

它接收一個 `%Plug.Conn{}` connection 結構體作為它的第一個引數，並且期望回傳一個 `%Plug.Conn{}` connection 結構體。

## 配置專案的應用程式模組

由於從頭開始建立 Plug 應用程式，因此需要定義應用程式模組。
更新 `lib/example.ex` 後啟動並監督 Cowboy：

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

這會監督 Cowboy，並且反過來，監督 `HelloWorldPlug`。

在 `Plug.Adapters.Cowboy.child_spec/4` 呼用中，第三個引數將被傳遞給 `Example.HelloWorldPlug.init/1`。

還沒做完。再次打開 `mix.exs`，找到 `applications` 函數。需要為應用程式加入配置，這也會使它能自動啟動。

現在更新它來做到這一點：

```elixir
def application do
  [
    extra_applications: [:logger],
    mod: {Example, []}
  ]
end
```

現在已經準備好嘗試這個簡單的，基於 Plug 的 Web 伺服器。
在命令列上，執行：

```shell
$ mix run --no-halt
```

一旦所有內容編譯完成，出現 `[info]  Started app` 後，打開一個 Web
瀏覽器到 `127.0.0.1:8080`。它應該如下顯示：

```
Hello World!
```

## Plug.Router

對於大多數應用程式，如網站或 REST API，需要路由器將不同路徑和 HTTP vebs 的請求路由到不同的處理程序。

`Plug` 提供了一個路由器來做到這一點。正如即將看到的，Elixir 中不需要像 Sinatra 這樣的框架，因為可以通過 Plug 免費取得。

在 `lib/example/router.ex` 上建立一個檔案來開始，並將以下內容複製進去：

```elixir
defmodule Example.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Welcome"))
  match(_, do: send_resp(conn, 404, "Oops!"))
end
```

這是一個最基本的簡易路由器，程式碼應該己經不言而喻了。
通過 `use Plug.Router` 涵蓋一些巨集，然後設定兩個內建的 Plugs： `:match` 和 `:dispatch`。有兩條定義的路由，一條用於處理對 root 的 GET 請求，另一條用於配對所有其他請求，因此可以回傳 404 訊息。

回到 `lib/example.ex` 中，需要將 `Example.Router` 加到 Web 伺服器的 supervisor 樹中。用新路由器替換 `Example.HelloWorldPlug` Plug：

```elixir
def start(_type, _args) do
  children = [
    Plug.Adapters.Cowboy.child_spec(:http, Example.Router, [], port: 8080)
  ]

  Logger.info("Started application")
  Supervisor.start_link(children, strategy: :one_for_one)
end
```

再次啟動伺服器，如果它正在執行前一個，將其停止（按 `Ctrl+C` 兩次）。

現在在 Web 瀏覽器中，到  `127.0.0.1:8080`。它應該輸出 `Welcome`。然後，到 `127.0.0.1:8080/waldo` 或任何其他路徑。它應該會回應 404 錯誤並輸出 `Oops!` 。

## 加入另一個 Plug

通常建立 Plug 來攔截所有請求或一部分的請求，以處理常見的請求處理邏輯 (request handling logic)。

在這個範例中，將建立一個 Plug 來驗證請求是否含有被請求的參數。通過在 Plug 中實現驗證，可以確保只有有效的請求才能通過應用程式。將預期 Plug 以兩個選項初始化： `:paths` 和 `:fields`。這些將用來呈現邏輯應用的路徑以及需要哪些 fields。

_註_：Plug 適用於所有請求，這就是為什麼需要過濾請求並只將我們的邏輯應用於其中的一部分。

要忽略請求，只需簡單通過連接即可。首先查看已完成的 Plug，然後討論它是怎麼運作的。在 `lib/example/plug/verify_request.ex` 中建立它：

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

首先要注意的是我們定義了一個新的例外 `IncompleteRequestError` ，它的一個選項是 `:plug_status`。當可用時，Plug 使用此選項來設置發生例外事件時的 HTTP 狀態碼。

Plug 的第二部分是 `call/2` 函數。這是決定是否應用驗證邏輯的地方。只有當請求的路徑包含在 `:paths` 選項中時，才會呼用 `verify_request!/2`。

Plug 的最後一部分是私有函數 `verify_request!/2` ，它驗證被請求的 `:fields` 是否全部呈現。
如果有一些遺失了，將引發 `IncompleteRequestError`。

我們已經設定 Plug 來驗證對 `/upload` 的所有請求都包含 `"content"` 和 `"mimetype"`。只有這樣路由程式碼才能被執行。

接下來，需要讓路由器認識新的 Plug。
編輯 `lib/example/router.ex` 並進行以下更改：

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

## 使 HTTP 通訊埠為可配置 (Configurable)

當定義了 `Example` 模組和應用程式時，HTTP 通訊埠在模組中即被寫死 (hard-coded)。通過將設罝選項罝於配置檔案中來使通訊埠成為可配置的被認為是一種很好的做法。

首先更新 `mix.exs` 的 `application` 部分來使 Elixir 認識應用程式，並設置一個應用程式 env 變數。隨著這些改變，程式碼應該看起來像這樣：

```elixir
def application do
  [
    extra_applications: [:logger],
    mod: {Example, []},
    env: [cowboy_port: 8080]
  ]
end
```

應用程式使用 `mod: {Example, []}` 這一行來進行配置設定。
注意到同時還啟動了`cowboy`、`logger` 和 `plug` 應用程式。

接下來，需要更新 `lib/example.ex` 來讀取通訊埠配置值，並將其傳遞給 Cowboy：

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

`Application.get_env` 的第三個引數是預設值，用於配置指令未定義時。

> （可選擇）在 `config/config.exs` 中添加 `:cowboy_port`

```elixir
use Mix.Config

config :example, cowboy_port: 8080
```

要執行應用程式可以使用：

```shell
$ mix run --no-halt
```

## 測試 Plug

感謝 `Plug.Test`，測試 Plug 非常直覺。它包含許多方便的函數，使測試變得簡單。

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

用這個執行它：

```shell
$ mix test test/example/router_test.exs
```

## 可用的 Plugs

有許多 Plug 是隨插即用的。
完整清單可以在 Plug 文件中找到 [這裡](https://github.com/elixir-lang/plug#available-plugs)。