%{
  version: "1.0.3",
  title: "Guardian (基礎)",
  excerpt: """
  [Guardian](https://github.com/ueberauth/guardian) 是一個基於 [JWT](https://jwt.io/) (JSON Web Tokens) 且被廣泛使用在身份驗證 (authentication) 的函式庫。
  """
}
---

## JWTs

JWT 可以為身份驗證提供含有豐富訊息的權杖 (token)。
在許多身份驗證系統僅提供對資源主體識別碼 (subject identifier) 存取的情況下，JWT 則以多樣化資訊的方式提供，例如： 

* 誰簽發的權杖
* 誰是權杖擁有者
* 何種系統應該使用此權杖
* 權杖簽發時間
* 權杖到期時間

除了這些欄位外，Guardian 還提供其他欄位以增進其功能性：

* 權杖是什麼類型
* 持有人 (bearer) 有什麼權限

這些只是 JWT 中的基本欄位，
可以自由增加應用程式所需的任何其他資訊，
但請記住保持簡短，因為 JWT 必須符合於 HTTP 標頭。

這種豐富性意味著可以將 JWT 作為涵蓋完整的憑證單元傳遞到系統中。

### 在哪裡使用它們

JWT 權杖可用於驗證應用程式的任何部分。

* 單頁應用程式
* 控制器 (經由瀏覽器 session)
* 控制器 (經由驗證標頭 - API)
* Phoenix Channels
* 服務 (Service) 對服務的請求
* 內部處理程序 (Inter-process)
* 第 3 方存取 (OAuth)
* 記住我 (Remember me) 功能
* 其它界面 - 原始 TCP, UDP, CLI, 等

JWT 權杖可以在應用程式中任何需要提供身份驗證處使用。

### 必須使用資料庫嗎？

無需通過資料庫追蹤 JWT，
可以簡單地依靠簽發和到期的時間戳記來控制存取。
往往，最後會使用資料庫來查詢使用者資源，但 JWT 本身並不需要它。

例如，如果要使用 JWT 驗證 UDP socket 上的通訊，則可能不會使用資料庫。
當簽發權杖時，將所有需要的資訊直接編碼到權杖中。
一旦驗證屬實後 (檢查它是被正確簽發的) 就可以了。

但是依然 _可以_ 使用資料庫來追踨 JWT。
如果這樣做，將有能力驗證權杖是否仍然有效 - 即 - 它尚未被撤銷。
或者，可以使用資料庫中的記錄來強制註銷使用者的所有權杖。
這在 Guardian 中使用 [GuardianDb](https://github.com/hassox/guardian_db) 就能簡單的實現。
GuardianDb 使用 Guardians '鉤子 (Hooks)' 來執行驗證檢查與資料庫的儲存和刪除，
在稍後將會介紹到。

## 設定

設定 Guardian 有很多選項，之後將會慢慢介紹它們，因此現在先從一個非常簡單的設定開始。

### 最簡設定

在開始前，需要一點設定。

#### 配置

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

這是為執行 Guardian 所要提供的最少資訊組成。
不應該將祕密金鑰 (secret key) 直接編碼到最上層的配置中，
每個環境都應該有自己的祕密金鑰。
在開發和測試中使用 Mix 環境來保密是很常見的。
然而在預備 (Staging) 和正式 (production) 環境時必須使用強健的祕密金鑰。
(例如
以 `mix phoenix.gen.secret` 生成)

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
Serializer 負責查找 `sub` (主體) 欄位中被標識的資源。
它可以從資料庫、API 甚至簡易字串中查找，
同時也負責將資源序列化到 `sub` 欄位。

這就是最簡易的配置。
如果需要，還可以做更多的設定，不過剛入門這樣就夠了。

#### 使用於應用程式

現在已經配置好使用 Guardian，接著需要將它整合到應用程式中。
由於這是最簡設定，首先考慮 HTTP 請求。

## HTTP requests

Guardian 提供了許多 Plugs，以便於整合到 HTTP 請求中。
可以在 [單獨課程](../../specifics/plug/) 了解 plug。
Guardian 不要求 Phoenix，但在接下來的範例中使用 Phoenix 將是最容易展示的。

整合到 HTTP 的最簡單方法是通過路由器。
由於 Guardian 的 HTTP 整合都基於 plugs，因此可以在任何可以使用 plug 的地方使用它們。

Guardian plug 的一般流程是：

1. 在請求中找到一個權杖(某處)並驗證它： `Verify*` plug
2. (可選) 載入在權杖中標識的資源：`LoadResource` plug
3. 確保請求有有效權杖，否則拒絕存取。`EnsureAuthenticated` plug

為了達到應用程式開發人員的所有需求，Guardian 分別地實現了這些階段。
要找到權杖，請使用 `Verify*` plug。

現在來建立一些管道 (pipelines)。

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

這些管道可用於組成不同的身份驗證需求。
第一個管道嘗試在 session 中首先查找權杖，然後回到到標頭。
如果有找到任何一個，將會載入資源。

第二個管道要求存在有效的、經過驗證的權杖，並且它具有 "存取 (access)" 類型。
要使用它們，請將它們添加到 scope 中。

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

如果存在，則上面的 login 路由將有個經過身份驗證的使用者。
第二個 scope 將確保所有操作都經由一個有效權杖。
其實 _不必_ 放在管道中，可以將它們放在控制器中以進行超靈活的自訂使用，不過現在是進行最簡設定，就先這樣使用。

到目前為止，還漏了一件事。
在 `EnsureAuthenticated` plug 上加入錯誤處理程序。
這是一個非常簡單的模組，可以回應

* `unauthenticated/2`
* `unauthorized/2`

這兩個函數都接收一個 Plug.Conn 結構和一個 params 映射，並應該處理它們各自的錯誤訊息。
你甚至可以使用 Phoenix 控制器！

#### 在控制器中

在控制器內部，有幾個選項可用於存取當前登入的使用者。
現在從最簡單的開始。

```elixir
defmodule MyApp.MyController do
  use MyApp.Web, :controller
  use Guardian.Phoenix.Controller

  def some_action(conn, params, user, claims) do
    # do stuff
  end
end
```

藉由使用 `Guardian.Phoenix.Controller` 模組，你的操作將接收兩個可以模式比對的附加參數。
請留意，如果沒有使用 `EnsureAuthenticated`，將可能有一個 nil user 和 claims。

其它 - 更靈活/更詳細的版本 - 使用 plug helpers。

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

登入和登出瀏覽器的 session 非常簡單。
在 login 控制器中：

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

使用 API ​​登入時，它略有不同，因為沒有 session，因此需要將原始權杖提供給用戶端。
對於 API 登入，可能會使用 `Authorization` 標頭為應用程式提供權杖。
當您不打算使用 session 時，這個方法很有用。

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

瀏覽器 session 登入實際上呼用 `encode_and_sign` ，因此可以以相同的方式使用它們。