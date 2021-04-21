%{
  version: "2.2.0",
  title: "Plug",
  excerpt: """
  Rubyをよくご存知なら、PlugはところどころSinatraの面影をもつRackだと考えることができます。

  PlugはWebアプリケーションのための仕様と、Webサーバーのためのアダプタを提供します。Elixirのコアの一部ではなく、公式のElixirプロジェクトです。

  このレッスンではElixirのライブラリの `PlugCowboy` を使って、シンプルなHTTPサーバーを一から構築します。
  CowboyはErlang用のシンプルなHTTPサーバーであり、PlugはそのWebサーバー用の接続アダプターを提供します。

  Plugをつかって最小限のWebアプリケーションの開発を始めることができます。
  そして、Plugのrouterや既存のWebアプリケーションにPlugを追加する方法を学んでいきましょう。
  """
}
---

## 前提条件

本チュートリアルでは、Elixir 1.5以上と、 `mix` がインストールされていることを前提とします。

まず、スーパーバイザーツリーを使用して、新規のOTPプロジェクトを作成します。

```shell
$ mix new example --sup
$ cd example
```

Cowboy2サーバーの起動と実行にはスーパーバイザーを使用するので、Elixirアプリにスーパーバイザーを含める必要があります。

## 依存関係

インストールはmixを使えばとても簡単です。

Cowboy2ウェブサーバー用のアダプタインターフェースとしてPlugを使用するには、 `PlugCowboy` パッケージをインストールする必要があります:

以下を `mix.exs` に追加してください:

```elixir
def deps do
  [
    {:plug_cowboy, "~> 2.0"},
  ]
end
```

コマンドラインで次のmixタスクを実行して、これらの新しい依存関係をダウンロードしてください。

```shell
$ mix deps.get
```

## 仕様

Plugを作り始めるためには、Plugの仕様を知り、それを正しく守る必要があります。

ありがたいことに、必要なのは2つの関数、 `init/1` と `call/2` だけです。

以下は、"Hello World!"を返す単純なPlugです:

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

`lib/example/hello_world_plug.ex` という名前で保存しましょう。

`init/1` 関数はPlugのオプションを初期化するのに用いられます。
そのオプションは次のセクションでご紹介するスーパーバイザーツリーから呼び出されます。
ここでは、空のリストを渡します。

`init/1` 関数の戻り値は最終的に `call/2` 関数の2つ目の引数として渡されます。

`call/2` 関数はリクエストのたびにCowboyから呼び出されます。 `call/2` 関数は `%Plug.Conn{}` 構造体を第一引数として受け取り、 `%Plug.Conn{}` 構造体を返します。

## プロジェクトのアプリケーションモジュールの設定

アプリケーションの起動時にCowboy Webサーバーを起動して監視するようにアプリケーションに指示する必要があります。

[`Plug.Cowboy.child_spec/1`](https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html#child_spec/1) 関数を使って実現させます。

この関数には3つのオプションがあります。

- `:scheme` - HTTP、またはHTTPSのアトム (`:http`, `:https`)
- `:plug` - Webサーバーのインターフェースとして使用されるPlugモジュール。
  `MyPlug` のようなモジュール名、またはモジュール名とオプション `{MyPlug, plug_opts}` のタプルを指定することができます。ここで `plug_opts` はPlugモジュールの `init/1` 関数に渡されます。
- `:options` - サーバーオプション。
  サーバーが要求するポート番号を含める必要があります。

`lib/example/application.ex` ファイルは、その `start/2` 関数でchild specを実装するべきです:

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

_注記_: ここで `child_spec` を呼び出す必要はありません。この関数は、このプロセスを開始するスーパーバイザーによって呼び出されます。
child specを構築したいモジュールと、それから必要な3つのオプションを使ってタプルを渡すだけです。

これで我々のアプリのスーパーバイザーツリーの下にCowboy2サーバーが起動します。

与えられたポート `8080` 上でHTTPスキーマ（HTTPSを指定することもできます）でCowboyを起動します。 `Example.HelloWorldPlug` をあらゆるウェブリクエストのインターフェースとして指定します。

これで、アプリを実行してWebリクエストを送信する準備が整いました。 `--sup` フラグを使ってOTPアプリを生成したので、 `application` 関数のおかげで `Example` アプリケーションが自動的に起動することに注意してください。

次に、 `mix.exs` を再度開き `applications` 関数に、アプリケーションを自動起動するための設定を追加します。

`mix.exs` では、以下のようになるはずです:

```elixir
def application do
  [
    extra_applications: [:logger],
    mod: {Example.Application, []}
  ]
end
```

これでPlugを使ったシンプルなWebサーバーを実行する準備ができました。
次のコマンドで実行します:

```shell
$ mix run --no-halt
```

1度コンパイルが終了すると、 `[info] Starting application...` が表示され `http://127.0.0.1:8080` をブラウザで開くと次のように表示されます

```
Hello World!
```

## Plug.Routerの使用

多くのWebサイトやREST APIなどのアプリケーションのように、リクエストをパスやHTTP関数によって制御するルーターが欲しくなるでしょう。そのため `Plug` はルーターを備えています。ElixirにはPlugがあるので、Sinatraのようなフレームワークは必要ありません。

手始めに、 `lib/example/router.ex` というファイルを作り、以下をコピーしましょう:

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

これは必要最小限のルータですが、コード自身がうまく中身を説明してくれているはずです。`use Plug.Router`でマクロをいくつか読み込み、それから2つの組み込みのPlug、 `:match` と `:dispatch` を配置します。
2つのルータが定義され、1つはルート(`/`)へのGETリクエストを制御します。2つ目ではそれ以外の全てのリクエストにマッチして、404メッセージを返すことができます。

`lib/example/application.ex` にもどり、 `Example.Router` をWebサーバーの管理下に追加してください。そして、 `Example.HelloWorldPlug` Plugを新しいルータに退避させてください。

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

サーバーが起動している場合は一度終了して(`Ctrl+C` を二回押してください)サーバーを再度起動してください。

そしてもう一度ブラウザで `127.0.0.1:8080` を開くと `Welcome` と表示されます。そして、 `127.0.0.1:8080/waldo` など、適当なパスを開くと `Oops!` と404ステータスのレスポンスが表示されます。

## Plugの追加

Webアプリケーションでは複数のPlugを使用するのが一般的です。各Plugはそれぞれの責任に専念しています。

たとえば、ルーティングを処理するPlug、Webリクエストを検証するPlug、リクエストを認証するPlugなどがあります。

このセクションでは、受信するリクエストパラメータを検証するためのPlugを定義し、私たちのアプリケーションに、ルータと検証Plugの両方を使うように定義します。

リクエストにいくつかの必須パラメータがあるかどうかを検証するPlugを作成したいと思います。

プラグインで検証を実装することで、有効なリクエストだけがアプリケーションに渡ることを保証できます。

このPlugの初期化には、 `:paths` と `:fields` の2つのオプションを期待します。

これらは、どのパスに、どのフィールドが必須かを表します。

_注記_: Plugは全てのリクエストにおいて適用されます。そのため、リクエストのフィルタリングはそれらのサブセットにのみ適用します。無視するためには単純にconnectionを引き渡します。

まず、完成したPlugを見てから、それがどのように機能するのかを説明します。

`lib/example/plug/verify_request.ex` を作成しましょう。

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

最初に注意することは、無効なリクエストの場合に発生する新しい例外 `IncompleteRequestError` を定義したことです。

次にPlugの `call/2` を見ていきます。
ここでリクエストの検証処理を実行するかどうかを決めています。
リクエストのパスが `:paths` オプションに含まれている場合のみ `verify_request!/2` 関数を実行します。

最後に、Plugは `verify_request!/2` 関数で `:fields` オプションに含まれるキーの全てがリクエストパラメータに存在するか検証します。
見つからないキーがあった場合は `IncompleteRequestError` を投げます。

私達のPlugでは `/upload` パスへの全てのリクエストに `"content"` と `"mimetype"` のパラメータが含まれていることを検証するようにします。
含まれているときのみルーティングを実行します。

次に、ルーターに先程作ったPlugを追加していきます。
`lib/example/router.ex` を編集し、以下のように変更します。

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

このコードを使って、ルータのコードを通して実行される _前_ に `VerifyRequest` Plugを通して受信したリクエストを送るようにアプリケーションに伝えています。
関数呼び出しを介して:

```elixir
plug VerifyRequest, fields: ["content", "mimetype"], paths: ["/upload"]
```

`VerifyRequest.init(fields: ["content", "mimetype"], paths: ["/upload"])` を自動的に呼び出します。
これは順番に `VerifyRequest.call(conn, opts)` 関数に与えられたオプションを渡します。

このPlugの動作を見てみましょう。先に進んでローカルサーバーをクラッシュさせてください（覚えておいてください、これは `ctrl + c`を2回押すことによって行われます）。

そしてサーバーを再起動します（`mix run --no-halt`）。

ブラウザで<http://127.0.0.1:8080/upload>に表示すると、ページが機能していないことがわかります。ブラウザから提供されるデフォルトのエラーページが表示されます。

それでは<http://127.0.0.1:8080/upload?content=thing1&mimetype=thing2>にアクセスして、必要なパラメータを追加しましょう。これで 'Uploaded'というメッセージが表示されるはずです。

エラーが発生したときに _何かしらの_ ページが表示されないのは素晴らしいことではありません。後でPlugを使ってエラーを処理する方法を見ます。

## HTTPポート番号を設定可能にする

`Example` モジュールとアプリケーションの定義に戻ります。HTTPポート番号はモジュールに直接書き込まれていました。
それは設定ファイルにポート番号を設定するのがおすすめです。

アプリケーションの環境変数を `config/config.exs` に設定します。

```elixir
use Mix.Config

config :example, cowboy_port: 8080
```

次に、 `lib/example/application.ex` を編集してポート番号の設定値を読み込みCowboyに渡すようにする必要があります

その処理を任せるプライベート関数を定義します。

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

`Application.get_env` 関数の第三引数には設定値がない場合のためのデフォルト値を渡します。

そして次のコマンドでアプリケーションを実行できます。

```shell
$ mix run --no-halt
```

## Plugのテスト

Plugのテストは `Plug.Test` のおかげでとても容易です。
テストを簡単にするための便利な関数が多く含まれています。

次のテストを `test/example/router_test.exs` に記述してください

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

次のコマンドで実行します

```shell
$ mix test test/example/router_test.exs
```

## Plug.ErrorHandler

予期したパラメータを指定せずに<http://127.0.0.1:8080/upload>にアクセスしたときに、わかりやすいエラーページや適切なHTTPステータスが表示されず、ブラウザのデフォルトのエラーページに `500 Internal Server Error` が表示されています。

[`Plug.ErrorHandler`](https://hexdocs.pm/plug/Plug.ErrorHandler.html) を追加して、それを修正しましょう。

まずはじめに、 `lib/example/router.ex` を開いて、そのファイルに次のように書きます。

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

一番上に、`use Plug.ErrorHandler` が追加されています。

このPlugはエラーを検出し、それを処理するために呼び出す関数 `handle_errors/2` を探します。

`handle_errors/2` は最初の引数として `conn` を受け入れ、2番目の引数として3つのアイテム（ `:kind` 、 `:reason` 、そして `:stack` ）を持つマップを受け取るだけです。

何が起こっているのかを見るために、非常に単純な `handle_errors/2` 関数を定義しました。これがどのように機能するかを確認するために、もう一度アプリを停止して再起動しましょう。

さて、あなたが<http://127.0.0.1:8080/upload>にアクセスするとき、あなたはわかりやすいエラーメッセージを見るでしょう。

ターミナルを見ると、次のようになります。

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

現時点では、まだ `500 Internal Server Error` が返されています。例外に `:plug_status` フィールドを追加することでステータスコードをカスタマイズできます。 `lib/example/plug/verify_request.ex` を開いて以下を追加してください:

```elixir
defmodule IncompleteRequestError do
  defexception message: "", plug_status: 400
end
```

サーバーを再起動して更新すると、今度は `400 Bad Request` を返します。

このPlugを使用すると、開発者が問題を解決するために必要な有用な情報を簡単に見つけることができます。また、エンドユーザーにわかりやすいページを提供することもできます。

## 利用可能なPlug

多くのPlugが難しい設定なしに利用可能です。一覧は[ここ](https://github.com/elixir-lang/plug#available-plugs)のPlugのドキュメントにあります。
