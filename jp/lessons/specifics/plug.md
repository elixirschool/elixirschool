---
layout: page
title: Plug
category: specifics
order: 1
lang: jp
---

Rubyをよくご存知なら、PlugはところどころSinatraの面影をもつRackだと考えることができます。PlugはWebアプリケーションのための仕様と、Webサーバーのためのアダプタを提供します。Elixirのコアの一部ではなく、公式のElixirプロジェクトです。

{% include toc.html %}

## インストール

インストールはmixを使えばとても簡単です。Plugをインストールするには`mix.exs`に2つの小さな変更を行う必要があります。始めに、PlugとWebサーバーの両方を依存関係として追加します。WebサーバーはCowboyを使います:

```elixir
defp deps do
  [{:cowboy, "~> 1.0.0"},
   {:plug, "~> 1.0"}]
end
```

あとは、WebサーバーとPlugを共にOTPアプリケーションへと追加するだけです:

```elixir
def application do
  [applications: [:cowboy, :logger, :plug]]
end
```

## 仕様

Plugを作り始めるためには、Plugの仕様を知り、それを正しく守る必要があります。ありがたいことに、必要なのは2つの関数、`init/1`と`call/2`だけです。

`init/1`関数はPlugのオプションを初期化するのに用いられ、そのオプションは`call/2`関数の2つ目の引数として渡されます。初期化されたオプションに加えて、`call/2`関数は`%Plug.Conn`を最初の引数として受け取り、接続を返すことが想定されています。

以下は、"Hello World!"を返す単純なPlugです:

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

## Plugの作成

この例では、リクエストが幾つかの必要な引数を持っているかどうかを確かめるPlugを作ります。Plugにバリデーションを実装することで、有効なリクエストのみがアプリケーションに渡されるのを確実にすることができます。ここで作るPlugは2つのオプション、`:paths`と`:fields`で初期化されると想定します。これらはロジックを適用するパスと、必要なフィールドを表しています。

_注記_: Plugは全てのリクエストに適用されます。これが、リクエストの選別処理をし、その一部にのみロジックを適用させる理由です。リクエストを無視するには、単にその接続をやり過ごします。

実装の済んだPlugを見ていくことから始めて、それがどう動いているかを議論していきます。Plugを`lib/plug/verify_request.ex`に作ります:

```elixir
defmodule Example.Plug.VerifyRequest do
  import Plug.Conn

  defmodule IncompleteRequestError do
    @moduledoc """
    必要なフィールドが見つからない時に発生させるエラー。
    """

    defexception message: "", plug_status: 400
  end

  def init(options), do: options

  def call(%Plug.Conn{request_path: path} = conn, opts) do
    if path in opts[:paths], do: verify_request!(conn.body_params, opts[:fields])
    conn
  end

  defp verify_request!(body_params, fields) do
    verified = body_params
               |> Map.keys
               |> contains_fields?(fields)
    unless verified, do: raise IncompleteRequestError
  end

  defp contains_fields?(keys, fields), do: Enum.all?(fields, &(&1 in keys))
end
```

最初に注目すべきは、新しい例外`IncompleteRequestError`を定義していることと、そのオプションの1つが`:plug_status`であることです。このオプションが利用可能なら、万が一例外が発生した場合に、PlugがHTTPステータスコードを設定するのに用います。

2つめの箇所は`call/2`メソッドで、これは検証ロジックを適用するかどうかを制御する場所になります。リクエストパスが`:paths`オプションに含まれている時だけ、`verify_request!/2`を呼び出します。

最後の箇所はプライベート関数の`verify_request!/2`で、必要な`:fields`が全て存在しているかどうかを検証します。万が一いくつか欠けている場合は、`Incompleterequesterror`を発生させます。

## Plug.Routerの使用

`VerifyRequest`Plugができたので、ルータへと進みましょう。ElixirにはSinatraのようなフレームワークが必要なさそうに思えつつありますが、ルーターはPlugを使えば無料で手に入ります。

手始めに、`lib/plug/router.ex`のファイルを作り、以下をコピーしましょう:

```elixir
defmodule Example.Plug.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/", do: send_resp(conn, 200, "Welcome")
  match _, do: send_resp(conn, 404, "Oops!")
end
```

これは必要最小限のルータですが、コード自身がうまく中身を説明してくれているはずです。`use Plug.Router`でマクロをいくつか読み込み、それから2つの組み込みのPlug、`:match`と`:dispatch`を配置します。2つのルータが定義され、1つはルートのGETの戻り値を制御します。2つめではそれ以外の全てのリクエストにマッチして、404メッセージを返すことができます。

このルータにPlugを追加しましょう:

```elixir
defmodule Example.Plug.Router do
  use Plug.Router

  alias Example.Plug.VerifyRequest

  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug VerifyRequest, fields: ["content", "mimetype"],
                      paths:  ["/upload"]
  plug :match
  plug :dispatch

  get "/", do: send_resp(conn, 200, "Welcome")
  post "/upload", do: send_resp(conn, 201, "Uploaded")
  match _, do: send_resp(conn, 404, "Oops!")
end
```

完了です！Plugを配置して、`/upload`へのリクエストが`"content"`と`"mimetype"`を両方とも含むことを確かめ、含む場合のみルートのコードが実行されるようにしました。

今のところ`/upload`エンドポイントはあまり役に立ちませんが、Plugを作り、結合する方法については理解しました。

## Webアプリの実行

アプリケーションを実行するには、その前にWebサーバ、ここではCowboyのセットアップと設定を行う必要があります。今のところは、ただ実行するのに必要なだけの変更をコードに行うだけですが、後のレッスンで詳細を掘り下げていきます。

`mix.exs`の`application`部分を更新して、Elixirにアプリケーションについて教えるとともにアプリケーションの環境変数を設定することから始めましょう。これらの変更で、コードはこのようになるはずです:

```elixir
def application do
  [applications: [:cowboy, :plug],
   mod: {Example, []},
   env: [cowboy_port: 8080]]
end
```

次に、Cowboyを起動し管理するため、`lib/example.ex`を更新する必要があります:

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

> (オプション) `:cowboy_port` を `config/config.exs` に追加してください。

```elixir
use Mix.Config

config :example, cowboy_port: 8080
```

これで、アプリケーションを起動するために、以下のコマンドを使用できます:

```shell
$ mix run --no-halt
```

## Plugのテスト

Plugのテストは`Plug.Test`のおかげでとても容易です。テストを簡単にするための便利な関数が多く含まれています。

ルータのテストを理解できるかどうか確かめてください:

```elixir
defmodule RouterTest do
  use ExUnit.Case
  use Plug.Test

  alias Example.Plug.Router

  @content "<html><body>Hi!</body></html>"
  @mimetype "text/html"

  @opts Router.init([])

  test "returns welcome" do
    conn = conn(:get, "/", "")
           |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "returns uploaded" do
    conn = conn(:post, "/upload", "content=#{@content}&mimetype=#{@mimetype}")
           |> put_req_header("content-type", "application/x-www-form-urlencoded")
           |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 201
  end

  test "returns 404" do
    conn = conn(:get, "/missing", "")
           |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end
```

## 利用可能なPlug

多くのPlugが難しい設定なしに利用可能です。一覧は[ここ](https://github.com/elixir-lang/plug#available-plugs)のPlugのドキュメントにあります。
