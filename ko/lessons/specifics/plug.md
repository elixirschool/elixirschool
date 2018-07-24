---
version: 1.2.0
title: Plug
---

Ruby를 잘 알고 계신다면 Plug는 여러 부분에서 Sinatra의 영향을 받은 Rack이라고 생각해도 좋습니다.
Plug는 Web 애플리케이션을 위한 명세와 Web 서버를 위한 어댑터를 제공합니다.
Plug는 Elixir 코어의 일부가 아닌, Elixir의 공식 프로젝트입니다.

작은 Plug 기반의 웹 애플리케이션을 만드는 것으로 시작해봅시다.
그러고 나면, Plug의 라우터와 기존의 웹 애플리케이션에 Plug를 추가하는 법을 알게 될 것입니다.

{% include toc.html %}

## 시작하기 전에

이 강의는 Elixir와 `mix`가 설치되어 있다고 가정합니다.

새 프로젝트를 만든적이 없다면 다음과 같이 입력하세요.

```shell
$ mix new example
$ cd example
```

## 의존성

mix를 사용하여 간단하게 설치할 수 있습니다.
Plug를 설치하기 위해서는 `mix.exs`에 두 가지 작은 수정을 해야 합니다.
우선 Plug와 Web 서버에 대한 의존성을 추가합니다. Web 서버는 Cowboy를 사용합니다.

```elixir
defp deps do
  [{:cowboy, "~> 1.1.2"},
   {:plug, "~> 1.3.4"}]
end
```

커맨드 라인에서 다음과 같은 mix 테스크를 실행해 새로운 의존성을 가져옵니다.

```shell
$ mix deps.get
```

## 명세

Plug를 만들기 위해서는 Plug의 명세를 알고 그것을 올바르게 따를 필요가 있습니다.
기쁘게도 필요한 것은 단 두 개의 함수, `init/1`과 `call/2` 뿐입니다.

다음은 "Hello World!"를 돌려주는 간단한 Plug입니다.

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

파일을 `lib/example/hello_world_plug.ex`에 저장합니다.

`init/1` 함수는 Plug의 옵션을 초기화할 때 사용됩니다. 이는 슈퍼바이저 트리에
의해서 호출되며, 이는 다음 장에서 설명합니다. 지금은 빈 리스트이므로 무시합시다.

`init/1`에 의해서 반환되는 값은 최종적으로 `call/2`의 두번째 인자로 넘겨집니다.

`call/2` 함수는 Cowboy로부터 넘어온 매 새로운 요청에 대해서 호출됩니다.
이는 `%Plug.Conn{}` 커넥션 구조체를 첫번째 인자로 받으며,
`%Plug.Conn{}` 커넥션 구조체를 반환해야 합니다.

## 프로젝트의 애플리케이션 모듈 설정하기

처음부터 Plug 애플리케이션을 만들었기 떄문에, 애플리케이션 모듈을 정의해야 합니다.
`lib/example.ex`를 수정해 시작하고 Cowboy를 관리하도록 합시다.

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

이는 Cowboy를 감독하고, `HelloWorldPlug`도 감독합니다.

`Plug.Adapters.Cowboy.child_spec/4` 호출에서 세번째 인수가 `Example.HelloWorldPlug.init/1`로 넘겨집니다.

여기서 끝이 아닙니다. `mix.exs`을 다시 열고, `application` 함수를 찾으세요.
지금은 두 가지가 필요합니다.
1) 시작해야하는 의존 애플리케이션 (`cowboy`,`logger`,`plug`) 목록과
2) 이 애플리케이션을 위한 설정, 이것도 자동으로 시작되어야합니다.
이를 위해 함수를 업데이트 해 봅시다.

```elixir
def application do
  [
    applications: [:cowboy, :logger, :plug],
    mod: {Example, []}
  ]
end
```

이제 최소한의 Plug 기반 웹 서버를 사용해 볼 준비가 되었습니다.
커맨드 라인에서 다음을 실행하십시오.

```shell
$ mix run --no-halt
```

일단 모든 것이 컴파일이 끝나고`[info] Started app`가 나타나면, 웹 브라우저에서
`127.0.0.1:8080`을 여세요. 다음 내용이 보일 것입니다.

```
Hello World!
```

## Plug.Router

웹 사이트 또는 REST API와 같은 대부분의 애플리케이션의 경우 라우터가 다른 경로 및 HTTP 메소드에 대한 요청을 다른 처리기로 라우팅해야합니다.
`Plug`는 이런 일을 할 수 있는 라우터를 제공합니다. 봐서 알 수 있듯이, Elixir에서는 Plug만으로 Sinatra가 하던 일을 할 수 때문에 Sinatra와 같은 프레임워크가 필요하지 않습니다.

시작해봅시다. `lib/example/router.ex` 파일을 만들어 다음 내용을 안에 넣으세요.

```elixir
defmodule Example.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Welcome"))
  match(_, do: send_resp(conn, 404, "Oops!"))
end
```

이것은 최소한의 라우터이지만 코드는 꽤 자명합니다.
`use plug.Router`를 통해 매크로를 넣어 `:match`와 `:dispatch`라는 내장 Plug를 설정했습니다.
루트에 대한 GET 요청을 처리하는 최상위 라우트와 다른 모든 요청과 매치해 404 메시지를 반환하는 두 번째 라우트가 정의되어 있습니다.

다시 `lib/example.ex`로 돌아가서, `Example.Router`를 웹 서버 슈퍼바이저 트리에 넣어 주어야 합니다.
`Example.HelloWorldPlug` plug를 새로운 라우터로 교체해 봅시다.

```elixir
def start(_type, _args) do
  children = [
    Plug.Adapters.Cowboy.child_spec(:http, Example.Router, [], port: 8080)
  ]

  Logger.info("Started application")
  Supervisor.start_link(children, strategy: :one_for_one)
end
```

서버를 재시작해 봅시다. 이전 서버가 실행중이라면 (`Ctrl + C`를 두 번 눌러) 중지하세요.

이제 췝브라우저에서 `127.0.0.1:8080`로 이동하세요.
`Welcome`이 출력될 것 입니다.
그런 다음`127.0.0.1:8080/waldo` 또는 다른 경로로 이동하십시오.
404 응답으로`Oops!`를 출력될 것 입니다.

## 다른 Plug 추가하기

일반적인 요청을 다루는 로직을 처리할 때, 모든 요청이나 요청의 일부를 가로채기 위해 Plug를 만드는 것이 일반적입니다.

이 예제에서 요청에 필요한 매개 변수가 있는지 확인하기 위한 Plug를 만듭니다.
Plug에서 검증을 구현하면 유효한 요청 만 애플리케이션에 적용될 수 있습니다.
Plug는 `:paths`와 `:fields` 옵션으로 초기화 되어야 합니다.
이것은 로직을 적용 할 경로(paths)와 필요한 필드(fields)를 나타냅니다.

_Note_ : Plug는 모든 요청에 적용되므로 요청을 필터링해 일부에만 로직을 적용할 필요가 있습니다.
요청을 무시하려면 그냥 연결을 넘겨주면 됩니다.

완성 된 Plug를 보고 어떻게 작동하는지 설명합니다.
`lib/example/plug/verify_request.ex`에 만들겠습니다.

```elixir
defmodule Example.Plug.VerifyRequest do
  defmodule IncompleteRequestError do
    @moduledoc """
    필요한 필드가 발견되지 않은 경우에 발생시킬 에러.
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

우선 주목해야 할 부분은 새로운 예외 `IncompleteRequestError`를 정의한다는 점과, 그 옵션 중에 `:plug_status`가 있다는 점입니다.
이벤트에서 예외가 발생한 경우 이 옵션이 사용되어 Plug가 HTTP 상태 코드를 돌려주게 됩니다.

그 다음은 `call/2` 메소드로,
이는 검증을 적용할지 말지를 결정하는 곳입니다.
요청 경로가 `:paths` 옵션에 포함되는 경우에만 `verify_request!/2`를 호출합니다.

마지막으로는 비공개 함수인 `verify_request!/2`로 필요한 `:fields`가 전부 존재하고 있는지를 확인합니다.
부족한 필드가 있는 경우에는 `Incompleterequesterror`를 발생시킵니다.

`/upload`에 대한 모든 요청에 `"content"` 와`"mimetype"` 둘 다 있는지 확인하기 위해 Plug를 설정했습니다.
확인된 경우에만 라우트 코드가 실행됩니다.

그런 다음, 라우터에게 새 Plug를 알려줄 필요가 있습니다.
`lib/example/router.ex`를 열어 다음과 같이 수정합니다.

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

  get("/", do: send_resp(conn, 200, "Welcome"))
  post("/upload", do: send_resp(conn, 201, "Uploaded"))
  match(_, do: send_resp(conn, 404, "Oops!"))
end
```

## HTTP 포트 설정하기

`Example` 모듈과 어플리케이션을 정의했을 때, HTTP 포트는 모듈에 하드 코딩되어 있습니다.
설정 파일에 포트를 설정하여 포트를 구성 할 수 있도록 하는 것도 생각 해볼 수 있습니다.

`mix.exs`의 `application` 부분을 변경하여 Elixir에게 애플리케이션에 대해서 알려주고, 환경변수를 설정하는 부분에서부터 시작해봅시다.
코드는 다음과 같이 수정될 것입니다.

```elixir
def application do
  [applications: [:cowboy, :logger, :plug], mod: {Example, []}, env: [cowboy_port: 8080]]
end
```

애플리케이션은 `mod : {Example, []}`으로 설정합니다.
`cowboy`, `logger`와 `plug` 애플리케이션을 시작하는 것도 알 수 있습니다.

다음으로 `lib/example.ex`를 업데이트하여 포트 설정 값을 읽어서 카우보이에게 넘겨 줄 필요가 있습니다.

```elixir
defmodule Example do
  use Application

  def start(_type, _args) do
    port = Application.get_env(:concoction, :cowboy_port, 8080)

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Example.Plug.Router, [], port: port)
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

`Application.get_env`의 세 번째 인자는 설정 디렉티브가 정의되지 않은 경우의 기본값입니다.

> (필수는 아님) `config/config.exs`에 `:cowboy_port`를 추가하세요.

```elixir
use Mix.Config

config :example, cowboy_port: 8080
```

이걸로 애플리케이션을 실행하기 위한 명령을 사용할 수 있습니다.

```shell
$ mix run --no-halt
```

## Plug의 테스트

Plug의 테스트는 `Plug.Test` 덕분에 무척 간단합니다.
테스트를 간편하게 만들어주는 편리한 함수가 다수 포함되어 있습니다.

라우터의 테스트를 이해할 수 있는지 확인해보세요.

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

## 사용 가능한 Plug

많은 Plug들을 어려운 설정 없이 사용할 수 있습니다.
전체 목록은 [여기](https://github.com/elixir-lang/plug#available-plugs)의 Plug 문서에서 찾을 수 있습니다.
