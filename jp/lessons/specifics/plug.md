---
version: 1.1.2
title: Plug
redirect_from:
  - /lessons/specifics/plug/
---

Rubyをよくご存知なら、PlugはところどころSinatraの面影をもつRackだと考えることができます。

PlugはWebアプリケーションのための仕様と、Webサーバーのためのアダプタを提供します。Elixirのコアの一部ではなく、公式のElixirプロジェクトです。

Plugをつかって最小限のWebアプリケーションの開発を始めることができます。
そして、Plugのrouterや既存のWebアプリケーションにPlugを追加する方法を学んでいきましょう。

{% include toc.html %}

## 前提条件

本チュートリアルでは、elixir 1.4以上がインストールされていることとmixがインストールされていることを前提とします。
まだプロジェクトを開始したことがない場合は、次のようにプロジェクトを作成してください。

```shell
$ mix new example
$ cd example
```

## 依存関係

インストールはmixを使えばとても簡単です。

Plugをインストールするには`mix.exs`に2つの小さな変更を行う必要があります。
始めに、PlugとWebサーバーの両方を依存関係として追加します。WebサーバーはCowboyを使います:

```elixir
defp deps do
  [{:cowboy, "~> 1.1.2"}, {:plug, "~> 1.3.4"}]
end
```

次にコマンドラインに以下のコマンドを入力して依存関係をダウンロードしてください。

```shell
$ mix deps.get
```

## 仕様

Plugを作り始めるためには、Plugの仕様を知り、それを正しく守る必要があります。

ありがたいことに、必要なのは2つの関数、`init/1`と`call/2`だけです。

以下は、"Hello World!"を返す単純なPlugです:

```elixir
defmodule Example.HelloWorldPlug do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Hello World!")
  end
end
```

`lib/example/hello_world_plug.ex` という名前で保存しましょう。

`init/1`関数はPlugのオプションを初期化するのに用いられます。そのオプションは次のセクションでご紹介するSupervisor treeから呼び出されます。ここでは、空のリストを渡します。

`init/1`関数の戻り値は最終的に`call/2`関数の2つ目の引数として渡されます。

`call/2`関数はリクエストのたびにCowboyなどのウェブサーバーから呼び出される。`call/2`関数は`%Plug.Conn{}`構造体を第一引数として受け取り、`%Plug.Conn{}`構造体を返します。

## プロジェクトのアプリケーションモジュールの設定

Plugアプリケーションを一から作り始めるには、アプリケーションモジュールを定義する必要があります。`lib/example.ex`を編集しCowboyによって起動します。

```elixir
defmodule Example do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Example.HelloWorldPlug, [], port: 8080)
    ]

    Logger.info "Started application"

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

これはCowboyによって管理し、次にHelloWorldPlugによって管理する。

`Plug.Adapters.Cowboy.child_spec/4`が呼ばれるとき、第三引数は`Example.HelloWorldPlug.init/1`関数に渡される。

次に、`mix.exs`を再度開き`applications`関数に、アプリケーションを自動起動するための設定を追加します。

```elixir
def application do
  [
    extra_applications: [:logger],
    mod: {Example, []}
  ]
end
```

これでPlugを使ったシンプルなWebサーバーを実行する準備ができました。次のコマンドで実行します

```shell
$ mix run --no-halt
```

1度コンパイルが終了すると、`[info] Started app`が表示され`127.0.0.1:8080`をブラウザで開くと次のように表示されます

```
Hello World!
```

## Plug.Routerの使用

多くのWebサイトやREST APIなどのアプリケーションのように、リクエストをパスやHTTPメソッドによって制御するルーターが欲しくなるでしょう。そのため`Plug`はルーターを備えています。ElixirにはPlugがあるので、Sinatraのようなフレームワークは必要ありません。

手始めに、`lib/plug/router.ex`というファイルを作り、以下をコピーしましょう:

```elixir
defmodule Example.Plug.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Welcome"))
  match(_, do: send_resp(conn, 404, "Oops!"))
end
```

これは必要最小限のルータですが、コード自身がうまく中身を説明してくれているはずです。`use Plug.Router`でマクロをいくつか読み込み、それから2つの組み込みのPlug、`:match`と`:dispatch`を配置します。2つのルータが定義され、1つはルート(`/`)へのGETリクエストを制御します。2つ目ではそれ以外の全てのリクエストにマッチして、404メッセージを返すことができます。

`lib/example.ex`にもどり、`Example.Router`をWebサーバーの管理下に追加してください。そして、`Example.HelloWorldPlug`Plugを新しいルータに退避させてください

```elixir
def start(_type, _args) do
  children = [
    Plug.Adapters.Cowboy.child_spec(:http, Example.Router, [], port: 8080)
  ]
  Logger.info "Started application"
  Supervisor.start_link(children, strategy: :one_for_one)
end
```

サーバーが起動している場合は一度終了して(Ctrl+C を二回押してください)サーバーを再度起動してください。

そしてもう一度ブラウザで`127.0.0.1:8080`を開くと`Welcome`と表示されます。そして、`127.0.0.1:8080/waldo`など、適当なパスを開くと`Oops!`と404ステータスのレスポンスが表示されます。

## Plugの追加

これは基本的なPlugのリクエストやリクエストのサブセットに割り込みを追加してリクエストを処理する仕組みです。

この例では必要なパラメータがリクエストに含まれているかどうかを検証するPlugを作ります。このPlugを実装することでアプリケーションに正しいリクエストのみ通す事ができます。このPlugの初期化には2つのオプション`:paths`と`fields`を期待します。これらはどのパスにどのフィールドが必要かというしょりを表しています。

Note: Plugは全てのリクエストにおいて適用されます。そのため、リクエストのフィルタリングはそれらのサブセットにのみ適用します。無視するためには単純にconnectionを引き渡します。

出来上がったPlugからどのように動くか説明していきます。`lib/plug/verify_request.ex`を作りましょう。

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

    unless verified, do: IncompleteRequestError
  end

  defp contains_fields?(keys, fields), do: Enum.all?(fields, &(&1 in keys))
end
```

まずに新しく`:plug_status`オプションを持つ`IncompleteRequestError`という例外を定義しました。このオプションはPlugの例外イベントが起きたときHTTPステータスコードを設定するために使われます。

次にPlugの`call/2`を見ていく。ここでリクエストの検証処理を実行するかどうかを決めています。リクエストのパスが`:paths`オプションに含まれている場合のみ`verify_request!/2`関数を実行します。

最後に、Plugは`verify_request!/2`関数で`:fields`オプションに含まれるキーがすべてリクエストパラメータに存在するか検証します。見つからないキーが合った場合は`IncompleteRequestError`を挙げます。

私達のPlugでは`/upload`パスへのすべてのリクエストに`"content"`と`"mimetype"`のパラメータが含まれていることを検証するようにします。含まれているときのみルーティングを実行します。

次に、ルーターに先程作ったPlugを追加していきます。再び`lib/example/router.ex`を編集し、以下のように変更します。

```elixir
defmodule Example.Router do
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

  get("/", do: send_resp(conn, 200, "Welcome\n"))
  post("/upload", do: send_resp(conn, 201, "Uploaded\n"))
  match(_, do: send_resp(conn, 404, "Oops!\n"))
end
```

## HTTPポート番号を設定可能にする

`Example`モジュールとアプリケーションの定義に戻ります。HTTPポート番号はモジュールに直接書き込まれていました。それは設定ファイルにポート番号を設定するのがおすすめです。

`mix.exs`の`application`関数を更新してElixirにアプリケーションの実行環境と環境変数を設定しましょう。

```elixir
def application do
  [
    extra_applications: [:logger],
    mod: {Example, []},
    env: [cowboy_port: 8080]
  ]
end
```

私達のアプリケーションは`mod: {Example, []}`の行で設定されます。また、一緒に`cowboy`、`logger`および`plug`アプリケーションを`起動します。

次に、`lib/example.ex`を編集してポート番号の設定値を読み込みCowboyに渡すようにする必要があります

```elixir
def Example do
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

`Application.get_env`関数の第三引数には設定値がない場合のためのデフォルト値を渡します。

> (オプション) `:cowboy_port` を `config/config.exs` に追加してください。

```elixir
use Mix.Config

config :example, cowboy_port: 8080
```

そして次のコマンドでアプリケーションを実行できます。

```shell
$ mix run --no-halt
```

## Plugのテスト

Plugのテストは`Plug.Test`のおかげでとても容易です。テストを簡単にするための便利な関数が多く含まれています。


次のテストを`test/example/router_test.exs`に記述してください

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

次のコマンドで実行します

```shell
$ mix test test/example/router_test.exs
```

## 利用可能なPlug

多くのPlugが難しい設定なしに利用可能です。一覧は[ここ](https://github.com/elixir-lang/plug#available-plugs)のPlugのドキュメントにあります。
