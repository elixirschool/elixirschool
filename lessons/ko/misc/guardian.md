---
version: 1.0.1
title: Guardian (Basics)
---

[Guardian](https://github.com/ueberauth/guardian)은 [JWT](https://jwt.io/) (JSON Web Tokens) 에 기반한 널리 사용되는 인증 라이브러리입니다.

{% include toc.html %}

## JWT

JWT는 인증을 위한 풍부한 정보를 가진 토큰을 제공할 수 있습니다. 많은 인증 시스템이 자원에 대한 주 식별자에만 접근할 수 있는 반면 JWT는 다음과 같은 다른 정보도 제공합니다.

* 토큰을 발급한 사람
* 토큰을 사용할 사람
* 토큰을 사용할 시스템
* 발급된 시간
* 토큰이 만료되는 시간

이 필드 외에도 Guardian은 추가 기능을 사용하기 위한 몇 가지 다른 필드를 제공합니다.

* 토큰의 타입
* 권한

이것들은 JWT의 기본 필드일 뿐입니다. 애플리케이션에 필요한 정보를 자유롭게 추가 할 수 있습니다. JWT가 HTTP 헤더에 맞춰야하므로 짧게 작성해야하는 것만 주의하세요.

이러한 풍부함은 시스템에 JWT를 모든 부분을 포함한 자격 증명을 전달할 수 있음을 의미합니다.

### 어디에 사용해야 하나요

JWT 토큰은 애플리케이션의 모든 부분의 인증에 사용할 수 있습니다.

* 싱글 페이지 애플리케이션
* 컨트롤러 (브라우져 세션을 통해)
* 컨트롤러 (인증 헤더 - API를 통해)
* Phoenix 채널
* 서비스 간 요청
* 내부 프로세스
* 서드파티 접근(OAuth)
* 유저 기억 기능
* 다른 인터페이스 - 저수준 TCP, UDP, CLI, 등등

JWT 토큰은 애플리케이션의 인증이 필요한 모든 부분에 사용할 수 있습니다.

### 데이터베이스를 사용해야 하나요?

데이터베이스를 통해 JWT를 추적할 필요가 없습니다. 발급 및 만료 시간 타임스탬프만으로 액세스 제어를 할 수 있습니다. 종종 사용자 자원을 조회에 데이터베이스를 사용하게 되지만 JWT 자체에서는 필요하지 않습니다.

예를 들어, JWT를 사용하여 UDP 소켓에서 통신을 인증하려는 경우 데이터베이스를 사용하지 않을 가능성이 높습니다. 토큰을 발행할 때 토큰에 필요한 모든 정보를 직접 인코딩하세요. 올바르게 서명했는지 확인했다면 그걸로 됩니다.

하지만 데이터베이스를 사용해 JWT를 추적_할_ 수 있습니다. 이를 통해 토큰이 유효한지 즉 토큰이 취소되지 않았는지 확인할 수 있습니다. 또는 DB의 레코드를 사용하여 사용자 5의 모든 토큰에서 로그를 강제로 제거 할 수 있습니다. 이 작업은 Guardian에서 [GuardianDb](https://github.com/hassox/guardian_db)를 사용하여 간단하게 수행 할 수 있습니다. GuardianDb는 Guardian 'Hooks'를 사용하여 유효성 검사를 수행하고 DB에서 저장 및 삭제합니다. 나중에 다시 설명하겠습니다.

## 설정

Guardian 설정에는 여러 가지 옵션이 있습니다. 나중에 다루겠습니다만, 시작은 간단하게 합시다.

### 최소 설정

시작하려면 필요한 것들이 몇 가지 있습니다.

#### Configuration

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
# 공개하는 코드라면 각 환경 설정에서 덮어써야 합니다
config :guardian, Guardian,
  issuer: "MyAppId",
  secret_key: Mix.env(),
  serializer: MyApp.GuardianSerializer
```

Guardian을 작동시키기 위해 필요한 최소한의 정보들입니다. 비밀 키를 최상위 구성으로 직접 인코딩하면 안됩니다. 대신, 각 환경에는 자체 키가 있어야합니다. dev 환경과 테스트 환경에서는 Mix 환경을 사용하는 것이 일반적이지만, 스테이징과 프로덕션은 반드시 강한 비밀키를 사용하세요.(예를 들어 `mix phoenix.gen.secret`으로 생성된 값)

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
serializer는 `sub`(subject) 필드에서 식별 된 자원을 찾는 역할을 합니다. 이것은 db, API, 심지어 간단한 문자열에서 조회될 수 있습니다.
또한 자원을 `sub` 필드에 직렬화하는 역할을 합니다.

최소한의 구성은 이걸로 끝입니다. 필요하다면 할 수 있는 일은 더 많습니다만 시작은 이걸로 충분합니다.

#### 애플리케이션에서 사용하기

이제 Guardian을 사용하기 위한 구성이 완료되었으니 애플리케이션에 통합해 보겠습니다. 최소 설정이므로 먼저 고려해야 할 것은 HTTP 요청입니다.

## HTTP 요청

Guardian은 HTTP 요청에 쉽게 통합할 수 있도록 다양한 Plug를 제공합니다. [다른 강좌](../../specifics/plug/)에서 Plug를 배울 수 있습니다. Guardian은 Phoenix를 요구하지 않지만, 다음 예제에서는 가장 쉽게 보여주기 위해 Phoenix를 사용하겠습니다.

HTTP에 통합하는 가장 쉬운 방법은 라우터를 사용하는 것입니다. Guardian의 HTTP 통합은 모두 Plug 기반이기 때문에 Plug를 사용할 수 있는 곳이라면 어디서나 사용할 수  있습니다.

Guardian plug의 일반적인 흐름은 다음과 같습니다.

1. (어딘가의) 요청에서 토큰을 찾아 확인: `Verify*` plug
2. 선택적으로 토큰의 식별된 자원을 로드: `LoadResource` plug
3. 이 요청에 대한 토큰이 유효한지 확인하고 유효하지 않으면 엑세스 거부. `EnsureAuthenticated` plug

Guardian은 애플리케이션 개발자의 요구를 모두 충족시키기 위해 이러한 단계를 따로 구현합니다. 토큰을 찾으려면 `Verify *` Plug를 사용하세요.

파이프라인을 만들어 봅시다.

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

이 파이프라인은 조합해 여러 인증 요구사항에 사용할 수 있습니다. 첫 번째 파이프라인은 토큰을 찾으려 시도하고 해더를 돌려줍니다. 찾았다면 자원을 로드합니다.

두 번째 파이프라인은 유효하고 확인 된 토큰이 존재하고 "액세스" 유형이어야 한다는 것을 요구합니다. 이를 사용하려면 스코프에 추가하십시오.

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

위에 있는 로그인 라우트는 있다면 인증된 유저를 가지게 됩니다. 두 번째 스코프는 모든 액션에 대해 유효한 토큰이 있는지 확인합니다.
파이프라인에 넣을 _필요는_ 없습니다. 사용자 정의를 유연하게 하기 위해 컨트롤러에 배치할 수 있지만 여기서는 최소한의 설정만 하겠습니다.

한 부분 놓친 곳이 있습니다. `EnsureAuthenticated` plug에 추가한 에러 핸들러입니다. 이 모듈은 다음 함수에 반응하는 매우 간단한 모듈입니다.

* `unauthenticated/2`
* `unauthorized/2`

두 함수 모두 Plug.Conn 구조체와 params 맵을 받고 각각의 오류를 처리해야 합니다. Phoenix 컨트롤러를 사용할 수도 있긴 합니다!

#### In the controller

컨트롤러 안에서 지금 로그인한 유저를 접근하는 방법은 여러가지 있습니다. 가장 간단한 것 부터 시작해보죠.

```elixir
defmodule MyApp.MyController do
  use MyApp.Web, :controller
  use Guardian.Phoenix.Controller

  def some_action(conn, params, user, claims) do
    # do stuff
  end
end
```

`Guardian.Phoenix.Controller` 모듈을 사용하려면, 패턴매칭에 사용할 액션에 인자를 두개 추가할 필요가 있습니다. `EnsureAuthenticated`을 사용하지 않으면 nil 유저나 클레임을 받을 수 있다는 걸 기억하세요.

더 유연하고 장황한 다른 방법은 Plug 헬퍼를 사용하는 것입니다.

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

브라우저 세션에서의 로그인/로그아웃은 매우 간단합니다. 로그인 컨트롤러에서 이렇게 하세요.

```elixir
def create(conn, params) do
  case find_the_user_and_verify_them_from_params(params) do
    {:ok, user} ->
      # Use access tokens. Other tokens can be used, like :refresh etc
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

API 로그인을 사용할 때는 약간 다릅니다. 세션이 없을 때 원시 토큰을 다시 클라이언트에 제공해야 하기 때문이죠.
API 로그인의 경우 `Authorization` 헤더를 사용하여 애플리케이션에 토큰을 제공할 수 있습니다. 이 방법은 세션을 사용하지 않을 때 유용합니다.

```elixir
def create(conn, params) do
  case find_the_user_and_verify_them_from_params(params) do
    {:ok, user} ->
      {:ok, jwt, _claims} = Guardian.encode_and_sign(user, :access)

      conn
      |> respond_somehow(%{token: jwt})

    {:error, reason} ->
      nil
      # handle not verifying the user's credentials
  end
end

def delete(conn, params) do
  jwt = Guardian.Plug.current_token(conn)
  Guardian.revoke!(jwt)
  respond_somehow(conn)
end
```

브라우저 세션 로그인은 내부적으로 `encode_and_sign`을 호출하므로 같은 방식으로 사용할 수 있습니다.
