---
version: 2.2.0
title: Plug
---

Rubyをよくご存知なら、PlugはところどころSinatraの面影をもつRackだと考えることができます。

PlugはWebアプリケーションのための仕様と、Webサーバーのためのアダプタを提供します。Elixirのコアの一部ではなく、公式のElixirプロジェクトです。

このレッスンではElixirのライブラリの `PlugCowboy` を使って、シンプルなHTTPサーバを一から構築します。
CowboyはErlang用のシンプルなHTTPサーバーであり、PlugはそのWebサーバー用の接続アダプターを提供します。

Plugをつかって最小限のWebアプリケーションの開発を始めることができます。
そして、Plugのrouterや既存のWebアプリケーションにPlugを追加する方法を学んでいきましょう。

{% include toc.html %}

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

ありがたいことに、必要なのは2つの関数、`init/1`と`call/2`だけです。

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

`init/1`関数はPlugのオプションを初期化するのに用いられます。
そのオプションは次のセクションでご紹介するSupervisor treeから呼び出されます。
ここでは、空のリストを渡します。

`init/1`関数の戻り値は最終的に`call/2`関数の2つ目の引数として渡されます。

`call/2`関数はリクエストのたびにCowboyなどのウェブサーバーから呼び出されます。`call/2`関数は`%Plug.Conn{}`構造体を第一引数として受け取り、`%Plug.Conn{}`構造体を返します。

## プロジェクトのアプリケーションモジュールの設定

アプリケーションの起動時にCowboy Webサーバーを起動して監視するようにアプリケーションに指示する必要があります。

[`Plug.Cowboy.child_spec/1`](https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html#child_spec/1) 関数を使って実現させます。

この関数には3つのオプションがあります。

* `:scheme` - HTTP、またはHTTPS のアトム (`:http`, `:https`)
* `:plug` - Webサーバーのインターフェースとして使用されるプラグモジュール。
`MyPlug`のようなモジュール名、またはモジュール名とオプション`{MyPlug, plug_opts}`のタプルを指定することができます。ここで`plug_opts`はプラグモジュールの `init/1` 関数に渡されます。
* `:options` - サーバーオプション。
サーバーが要求するポート番号を含める必要があります。

私たちの `lib/example/application.ex` ファイルは、その `start/2` 関数でchild specを実装するべきです：

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

_注記_：ここで `child_spec`を呼び出す必要はありません。この関数は、このプロセスを開始するスーパーバイザーによって呼び出されます。
child specを構築したいモジュールと、それから必要な3つのオプションを使ってタプルを渡すだけです。

これで我々のアプリのスーパーバイザーツリーの下にCowboy2サーバーが起動します。

与えられたポート `8080` 上でHTTPスキーマ（HTTPSを指定することもできます）でCowboyを起動します。`Example.HelloWorldPlug`をあらゆるウェブリクエストのインターフェースとして指定します。

これで、アプリを実行してWebリクエストを送信する準備が整いました。 `--sup`フラグを使ってOTPアプリを生成したので、`application` 関数のおかげで `Example`アプリケーションが自動的に起動することに注意してください。

次に、`mix.exs`を再度開き`applications`関数に、アプリケーションを自動起動するための設定を追加します。

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

1度コンパイルが終了すると、`[info]  Starting application...`が表示され`http://127.0.0.1:8080`をブラウザで開くと次のように表示されます

```
Hello World!
```

## Plug.Routerの使用

多くのWebサイトやREST APIなどのアプリケーションのように、リクエストをパスやHTTP関数によって制御するルーターが欲しくなるでしょう。そのため`Plug`はルーターを備えています。ElixirにはPlugがあるので、Sinatraのようなフレームワークは必要ありません。

手始めに、`lib/example/router.ex`というファイルを作り、以下をコピーしましょう:

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

これは必要最小限のルータですが、コード自身がうまく中身を説明してくれているはずです。`use Plug.Router`でマクロをいくつか読み込み、それから2つの組み込みのPlug、`:match`と`:dispatch`を配置します。
2つのルータが定義され、1つはルート(`/`)へのGETリクエストを制御します。2つ目ではそれ以外の全てのリクエストにマッチして、404メッセージを返すことができます。

`lib/example/application.ex` にもどり、`Example.Router`をWebサーバーの管理下に追加してください。そして、`Example.HelloWorldPlug`Plugを新しいルータに退避させてください

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

そしてもう一度ブラウザで`127.0.0.1:8080`を開くと`Welcome`と表示されます。そして、`127.0.0.1:8080/waldo`など、適当なパスを開くと`Oops!`と404ステータスのレスポンスが表示されます。

## Plugの追加

Webアプリケーションでは複数のPlugを使用するのが一般的です。各Plugはそれぞれの責任に専念しています。

たとえば、ルーティングを処理するPlug、Webリクエストを検証するPlug、リクエストを認証するPlugなどがあります。

このセクションでは、受信するリクエストパラメータを検証するためのPlugを定義し、私たちのアプリケーションに、ルータと検証プラグの両方を使うように定義します。

リクエストにいくつかの必須パラメータがあるかどうかを検証するPlugを作成したいと思います。

プラグインで検証を実装することで、有効なリクエストだけがアプリケーションに渡ることを保証できます。

このPlugの初期化には、`:paths` と `:fields` の2つのオプションを期待します。

これらは、どのパスに、どのフィールドが必須かを表します。

_注記_：Plugは全てのリクエストにおいて適用されます。そのため、リクエストのフィルタリングはそれらのサブセットにのみ適用します。無視するためには単純にconnectionを引き渡します。

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

最初に注意することは、無効なリクエストの場合に発生する新しい例外 `IncompleteRequestError`を定義したことです。

次にPlugの`call/2`を見ていく。
ここでリクエストの検証処理を実行するかどうかを決めています。
リクエストのパスが`:paths`オプションに含まれている場合のみ`verify_request!/2`関数を実行します。

最後に、Plugは`verify_request!/2`関数で`:fields`オプションに含まれるキーの全てがリクエストパラメータに存在するか検証します。
見つからないキーがあった場合は`IncompleteRequestError`を投げます。

私達のPlugでは`/upload`パスへの全てのリクエストに`"content"`と`"mimetype"`のパラメータが含まれていることを検証するようにします。
含まれているときのみルーティングを実行します。

次に、ルーターに先程作ったPlugを追加していきます。
`lib/example/router.ex`を編集し、以下のように変更します。

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
関数呼び出しを介して：

```elixir
plug VerifyRequest, fields: ["content", "mimetype"], paths: ["/upload"]
```

`VerifyRequest.init(fields: ["content", "mimetype"], paths: ["/upload"])` を自動的に呼び出します。
これは順番に `VerifyRequest.call(conn, opts)` 関数に与えられたオプションを渡します。

このPlugの動作を見てみましょう。先に進んでローカルサーバをクラッシュさせてください（覚えておいてください、これは `ctrl + c`を2回押すことによって行われます）。

そしてサーバを再起動します（`mix run --no-halt`）。

ブラウザで<http://127.0.0.1:8080/upload>に表示すると、ページが機能していないことがわかります。ブラウザから提供されるデフォルトのエラーページが表示されます。

それでは<http://127.0.0.1:8080/upload?content=thing1&mimetype=thing2>にアクセスして、必要なパラメータを追加しましょう。これで 'Uploaded'というメッセージが表示されるはずです。

エラーが発生したときに _any_ ページが表示されないのは素晴らしいことではありません。後でPlugを使ってエラーを処理する方法を見ます。

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
