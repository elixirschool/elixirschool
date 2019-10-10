---
version: 1.0.3
title: Guardian (Basics)
---

[Guardian](https://github.com/ueberauth/guardian)は、[JWT](https://jwt.io/)（JSON Web Tokens）に基づく、広く使用されている認証ライブラリです。

{% include toc.html %}

## JWT

JWT は認証用の豊富なトークンを提供できます。
多くの認証システムがリソースへの subject identifier だけへのアクセスを提供しますが、JWT はそれに加えてこれらの情報を提供します。

- 誰がトークンを発行したか
- 誰のためのトークンなのか
- どのシステムで使うトークンなのか
- いつ発行されたか
- いつ有効期限切れになるか

これらの項目に加えて、Guardian は機能追加を容易にするために、これらのフィールドを提供します。

- トークンのタイプ
- 所有者の権限

これらは JWT の基本的な項目にすぎません。
アプリケーションに必要な追加情報を自由に追加できます。
JWT は HTTP ヘッダーに収まる必要があるため、短くすることを忘れないでください。

この情報の豊富さは、完全な認証情報として、JWT をシステムに渡すことができることを意味します。

### どこで使うか

JWT トークンを利用して、アプリケーションのあらゆる部分を認証することができます。

- シングルページアプリケーション
- Controllers (ブラウザセッション経由)
- Controllers (API の認証ヘッダ経由)
- Phoenix Channels
- サービス間通信
- プロセス間通信
- 第三者アクセス (OAuth)
- ログインしたままにする
- その他 - raw TCP, UDP, CLI, etc

JWT トークンは、認証を提供する必要があるアプリケーションのあらゆる場所で使用することができます。

### データベースを使う必要がありますか？

データベースを介して JWT を追跡する必要はありません。
アクセスを制御するために、発行済みのタイムスタンプと有効期限のタイムスタンプを使用することができます。
多くの場合、データベースを使用してユーザーリソースを検索することになりますが、JWT 自体はそれを要求しません。
たとえば、UDP ソケットで通信を認証するために JWT を使用しようとしているのであれば、おそらくデータベースを使用しないでしょう。
あなたがトークンを発行するとき、あなたが必要とするすべての情報を直接トークンにエンコードします。
(正しく署名されているのか調べることで)有効なのか確認したのであれば、トークンの発行は完了です。

ただし、JWT を追跡するためにデータベースを使用することは **可能** です。
そうすれば、トークンがまだ有効であるー失効してないーことが確認できます。
または、データベース内のレコードを使用して、すべてのトークンを強制的にログアウトさせることもできます。
これは、[GuardianDb](https://github.com/hassox/guardian_db)を使用して、Guardian で簡単に行えます。
GuardianDb は、Guardian の `Hooks` を使用して検証を行い、保存およびデータベースからの削除を行います。
これについては後で説明します。

## セットアップ

Guardian をセットアップするための多くのオプションがあります。設定は色々ありますが、簡単な設定から始めましょう。

### 最小限のセットアップ

セットアップを始めるために、あなたが必要とするものがいくつかあります。

#### 設定

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

`config/config.ex`

```elixir
# in each environment config file you should overwrite this if it's external
config :guardian, Guardian,
  issuer: "MyAppId",
  secret_key: Mix.env(),
  serializer: MyApp.GuardianSerializer
```

これは、Guardian が動作するために必要最低限の情報です。
あなたの秘密鍵をトップレベルの設定に直接エンコードしてはいけません。
代わりに、各環境が秘密鍵を持つべきです。
dev と test は、機密保持のために Mix 環境を使うのが一般的です。
ただし、ステージングと本番では、機密保持をより強力にする必要があります。
(例
`mix phoenix.gen.secret` で機密情報を生成)

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

あなたの Serializer は `sub` （件名）フィールドで識別されるリソースを見つける責務があります。
これはデータベース、API、あるいは単純な文字列からの検索です。
それはまたリソースを `sub` フィールドにシリアライズする役割も果たします。

これで最小構成は終わりです。
必要であれば他にも設定は可能ですが、始めるにはこれで十分です。

#### アプリケーションでの利用

Guardian を使用するための構成が整ったので、それをアプリケーションで利用できるようにする必要があります。
これが最小の設定なので、まず HTTP リクエストを考えましょう。

## HTTP リクエスト

Guardian は、HTTP リクエストとの連携を容易にするために多数の Plug を提供しています。
Plug については [別レッスン](../../specifics/plug/) で学ぶことができます。

Guardian は Phoenix を必要としませんが、以下の例で Phoenix を使用するのが、最も簡単に試すことができます。

HTTP と連携する最も簡単な方法は router 経由です。
Guardian の HTTP との連携は全て Plug に基づいているため、Plug を使用できるところならどこでもこれらを使用できます。

Guardian Plug の一般的な流れは次のとおりです。

1. リクエストのどこかにあるトークンを見つけてそれを検証します： `Verify*` Plug
2. オプションで、トークンで識別されたリソースをロードします： `LoadResource` Plug
3. リクエストのための有効なトークンがあることを確認し、そうでない場合はアクセスを拒否します： `EnsureAuthenticated` Plug

アプリケーション開発者のすべてのニーズを満たすために、Guardian はこれらのフェーズを別々に実装します。
トークンを見つけるには `Verify*` Plug を使います。

pipeline をいくつか作成しましょう。

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

これらの pipeline を使用して、さまざまな認証要件を構成することができます。
最初の pipeline は、セッション内で最初にトークンを見つけ、見つからなかった場合はヘッダーを確認します。
トークンが見つかった場合は、リソースが読み込まれます。

2 番目の pipeline では、有効で検証済みのトークンが存在し、それのタイプが "access" であることが必要です。
これらの Plug を使用するには、それらを自分の scope に追加します。

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

上記の login の route は、認証されたユーザーであれば利用することができます。
2 番目の scope は、すべてのアクションに、有効なトークンが渡されるようにします。
あなたは Plug を pipeline に入れる必要は _ありません_。あなたは非常に柔軟なカスタマイズのためにコントローラーに Plug を入れることができますが、我々は最小限のセットアップをしています。

やり残していることが一つあります。
エラーハンドラは `EnsureAuthenticated` Plug に追加しました。
これは以下に対応する非常に単純なモジュールです。

- `unauthenticated/2`
- `unauthorized/2`

これらの関数は両方とも Plug.Conn の構造体と、Map の params を受け取り、それぞれのエラーを処理します。

Phoenix controller を使うこともできます！

#### Controller

コントローラの内部には、現在ログインしているユーザ情報にアクセスする方法について、いくつかの選択肢があります。
最も簡単なものからやってみましょう。

```elixir
defmodule MyApp.MyController do
  use MyApp.Web, :controller
  use Guardian.Phoenix.Controller

  def some_action(conn, params, user, claims) do
    # do stuff
  end
end
```

`Guardian.Phoenix.Controller` モジュールを使うことで、あなたのアクションはパターンマッチできる 2 つの追加の引数を受け取ります。
もしあなたが `VerifyAuthenticated` を使っていなかったら、あなたは nil ユーザを持っているかもしれないことを忘れないでください。

もう 1 つの - より柔軟で冗長なバージョン - は Plug ヘルパーを使うことです。

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

#### Login/Logout

ブラウザセッションへのログインとログアウトはとても簡単です。
ログインコントローラで：

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

API のログインを使用する場合、セッションがなく、生のトークンをクライアントに返す必要があるため、少し異なります。
API のログインの場合、おそらくあなたのアプリケーションにトークンを提供するために `Authorization` ヘッダを使うでしょう。
この方法は、セッションを使用しない場合に便利です。

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

ブラウザセッションのログインは内部的に `encode_and_sign` を呼び出すので、同じように使うことができます。
