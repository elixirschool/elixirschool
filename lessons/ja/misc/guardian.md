%{
  version: "1.0.3",
  title: "Guardian (Basics)",
  excerpt: """
  [Guardian](https://github.com/ueberauth/guardian)は、[JWT](https://jwt.io/)（JSON Web Tokens）に基づく、広く使用されている認証ライブラリです。
  """
}
---

## JWT

JWTは認証用の豊富なトークンを提供できます。
多くの認証システムがリソースへのsubject identifierだけへのアクセスを提供しますが、JWTはそれに加えてこれらの情報を提供します。

- 誰がトークンを発行したか
- 誰のためのトークンなのか
- どのシステムで使うトークンなのか
- いつ発行されたか
- いつ有効期限切れになるか

これらの項目に加えて、Guardianは機能追加を容易にするために、これらのフィールドを提供します。

- トークンのタイプ
- 所有者の権限

これらはJWTの基本的な項目にすぎません。
アプリケーションに必要な追加情報を自由に追加できます。
JWTはHTTPヘッダーに収まる必要があるため、短くすることを忘れないでください。

この情報の豊富さは、完全な認証情報として、JWTをシステムに渡すことができることを意味します。

### どこで使うか

JWTトークンを利用して、アプリケーションのあらゆる部分を認証することができます。

- シングルページアプリケーション
- Controllers (ブラウザセッション経由)
- Controllers (APIの認証ヘッダ経由)
- Phoenix Channels
- サービス間通信
- プロセス間通信
- 第三者アクセス (OAuth)
- ログインしたままにする
- その他 - raw TCP, UDP, CLI, etc

JWTトークンは、認証を提供する必要があるアプリケーションのあらゆる場所で使用することができます。

### データベースを使う必要がありますか？

データベースを介してJWTを追跡する必要はありません。
アクセスを制御するために、発行済みのタイムスタンプと有効期限のタイムスタンプを使用することができます。
多くの場合、データベースを使用してユーザーリソースを検索することになりますが、JWT自体はそれを要求しません。
たとえば、UDPソケットで通信を認証するためにJWTを使用しようとしているのであれば、おそらくデータベースを使用しないでしょう。
あなたがトークンを発行するとき、あなたが必要とするすべての情報を直接トークンにエンコードします。
(正しく署名されているのか調べることで)有効なのか確認したのであれば、トークンの発行は完了です。

ただし、JWTを追跡するためにデータベースを使用することは **可能** です。
そうすれば、トークンがまだ有効であるー失効してないーことが確認できます。
または、データベース内のレコードを使用して、すべてのトークンを強制的にログアウトさせることもできます。
これは、[GuardianDb](https://github.com/hassox/guardian_db)を使用して、Guardianで簡単に行えます。
GuardianDbは、Guardianの `Hooks` を使用して検証を行い、保存およびデータベースからの削除を行います。
これについては後で説明します。

## セットアップ

Guardianをセットアップするための多くのオプションがあります。設定は色々ありますが、簡単な設定から始めましょう。

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

`config/config.exs`

```elixir
# in each environment config file you should overwrite this if it's external
config :guardian, Guardian,
  issuer: "MyAppId",
  secret_key: Mix.env(),
  serializer: MyApp.GuardianSerializer
```

これは、Guardianが動作するために必要最低限の情報です。
あなたの秘密鍵をトップレベルの設定に直接エンコードしてはいけません。
代わりに、各環境が秘密鍵を持つべきです。
devとtestは、機密保持のためにMix環境を使うのが一般的です。
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

あなたのSerializerは `sub` （件名）フィールドで識別されるリソースを見つける責務があります。
これはデータベース、API、あるいは単純な文字列からの検索です。
それはまたリソースを `sub` フィールドにシリアライズする役割も果たします。

これで最小構成は終わりです。
必要であれば他にも設定は可能ですが、始めるにはこれで十分です。

#### アプリケーションでの利用

Guardianを使用するための構成が整ったので、それをアプリケーションで利用できるようにする必要があります。
これが最小の設定なので、まずHTTPリクエストを考えましょう。

## HTTPリクエスト

Guardianは、HTTPリクエストとの連携を容易にするために多数のPlugを提供しています。
Plugについては [別レッスン](../../specifics/plug/) で学ぶことができます。

GuardianはPhoenixを必要としませんが、以下の例でPhoenixを使用するのが、最も簡単に試すことができます。

HTTPと連携する最も簡単な方法はrouter経由です。
GuardianのHTTPとの連携は全てPlugに基づいているため、Plugを使用できるところならどこでもこれらを使用できます。

Guardian Plugの一般的な流れは次のとおりです。

1. リクエストのどこかにあるトークンを見つけてそれを検証します： `Verify*` Plug
2. オプションで、トークンで識別されたリソースをロードします： `LoadResource` Plug
3. リクエストのための有効なトークンがあることを確認し、そうでない場合はアクセスを拒否します： `EnsureAuthenticated` Plug

アプリケーション開発者のすべてのニーズを満たすために、Guardianはこれらのフェーズを別々に実装します。
トークンを見つけるには `Verify*` Plugを使います。

pipelineをいくつか作成しましょう。

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

これらのpipelineを使用して、さまざまな認証要件を構成することができます。
最初のpipelineは、セッション内で最初にトークンを見つけ、見つからなかった場合はヘッダーを確認します。
トークンが見つかった場合は、リソースが読み込まれます。

2番目のpipelineでは、有効で検証済みのトークンが存在し、それのタイプが "access" であることが必要です。
これらのPlugを使用するには、それらを自分のscopeに追加します。

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

上記のloginのrouteは、認証されたユーザーであれば利用することができます。
2番目のscopeは、すべてのアクションに、有効なトークンが渡されるようにします。
あなたはPlugをpipelineに入れる必要は _ありません_ 。あなたは非常に柔軟なカスタマイズのためにコントローラーにPlugを入れることができますが、我々は最小限のセットアップをしています。

やり残していることが一つあります。
エラーハンドラは `EnsureAuthenticated` Plugに追加しました。
これは以下に対応する非常に単純なモジュールです。

- `unauthenticated/2`
- `unauthorized/2`

これらの関数は両方ともPlug.Connの構造体と、Mapのparamsを受け取り、それぞれのエラーを処理します。

Phoenix controllerを使うこともできます！

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

`Guardian.Phoenix.Controller` モジュールを使うことで、あなたのアクションはパターンマッチできる2つの追加の引数を受け取ります。
もしあなたが `VerifyAuthenticated` を使っていなかったら、あなたはnilユーザを持っているかもしれないことを忘れないでください。

もう1つの - より柔軟で冗長なバージョン - はPlugヘルパーを使うことです。

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

APIのログインを使用する場合、セッションがなく、生のトークンをクライアントに返す必要があるため、少し異なります。
APIのログインの場合、おそらくあなたのアプリケーションにトークンを提供するために `Authorization` ヘッダを使うでしょう。
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
