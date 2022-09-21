%{
  version: "2.2.0",
  title: "Plug",
  excerpt: """
  Ruby를 잘 알고 계신다면 Plug는 여러 부분에서 Sinatra의 영향을 받은 Rack이라고 생각해도 좋습니다.
  Plug는 Web 애플리케이션 컴포넌트를 위한 명세와 Web 서버를 위한 어댑터를 제공합니다.
  Plug는 Elixir 코어의 일부는 아니지만, Elixir의 공식 프로젝트입니다.

  `PlugCowboy` 라이브러리를 이용해 간단한 HTTP 서버를 밑바닥부터 만드는 것으로 시작해봅시다.
  Cowboy는 Erlang으로 된 간단한 웹서버이며 Plug는 해당 웹서버에 대한 커넥션 어댑터를 제공해줍니다.

기본적인 웹 애플리케이션을 준비하고 난 뒤, Plug의 라우터와 웹 애플리케이션 하나에 여러 plug를 사용하는 법을 배웁니다
  """
}
---

## 시작하기 전에

이 튜토리얼에서는 Elixir 1.5 버전 이상과 `mix`가 설치되어 있다고 가정합니다.

슈퍼비전 트리가 있는 새 OTP 프로젝트를 만드는 것으로 시작해 봅시다.

```shell
mix new example --sup
cd example
```

슈퍼바이저를 이용해서 Cowboy2 웹서버를 시작하고 실행할 것이기 때문에 슈퍼비전 트리를 포함한 Elixir 앱이 필요합니다.

## 의존성

의존성은 mix를 사용하여 간단하게 추가할 수 있습니다.
Plug를 Cowboy2의 어댑터 인터페이스로 사용하기 위해서는 `PlugCowboy` 패키지를 설치해야 합니다.

다음과 같이 `mix.exs` 파일에 추가해주세요.

```elixir
def deps do
  [
    {:plug_cowboy, "~> 2.0"},
  ]
end
```

커맨드 라인에서 다음과 같은 mix 테스크를 실행해 새로운 의존성을 가져옵니다.

```shell
mix deps.get
```

## Plug 명세

Plug를 만들기 위해서는 Plug의 명세를 알고 그것을 올바르게 따를 필요가 있습니다.
다행스럽게도 필요한 것은 단 두 개의 함수, `init/1`과 `call/2` 뿐입니다.

다음은 "Hello World!"를 돌려주는 간단한 Plug입니다.

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

파일을 `lib/example/hello_world_plug.ex`에 저장합니다.

`init/1` 함수는 Plug의 옵션을 초기화할 때 사용됩니다.
이는 슈퍼바이저 트리에 의해서 호출되는데, 이에 대해서는 다음 섹션에서 설명합니다.
일단 지금은 빈 리스트이므로 무시합시다.

`init/1`에 의해서 반환되는 값은 최종적으로 `call/2`의 두번째 인자로 넘겨집니다.

`call/2` 함수는 Cowboy로부터 넘어온 모든 새로운 요청에 대해서 각각 호출됩니다.
Cowboy는 `%Plug.Conn{}` 커넥션 구조체를 첫번째 인자로 받으며, `%Plug.Conn{}` 커넥션 구조체를 반환해야 합니다.

## 프로젝트의 애플리케이션 모듈 설정하기

애플리케이션이 시작될 때 Cowboy 웹 서버를 시작하고 모니터링하도록 해야 합니다.

이는 [`Plug.Cowboy.child_spec/1`](https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html#child_spec/1) 함수를 사용해서 할 수 있습니다.

이 함수는 다음 3가지 옵션을 받습니다.

* `:scheme` - HTTP 혹은 HTTPS 아톰 (`:http`, `:https`)
* `:plug` - 웹서버의 인터페이스로 사용될 plug 모듈. `MyPlug`처럼 모듈 이름만 적거나 `{MyPlug, plug_opts}`처럼 모듈 이름과 옵션으로 된 튜플을 명시 가능합니다. `plug_opts`는 plug모듈의 `init/1` 함수로 넘겨지게 됩니다.
* `:options` - 서버 옵션. 서버가 요청을 수신할 포트 번호를 포함하고 있어야 합니다.

`lib/example/application.ex` 파일은 `start/2` 함수에서 위 child spec을 구현해야 합니다.

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

_참고_: 이 프로세스를 시작하는 슈퍼바이저가 호출할 것이기 때문에, `child_spec` 을 여기서 직접 호출할 필요는 없습니다.
그저 child spec을 만드려는 모듈과 그에 필요한 3개의 옵션으로 묶인 튜플을 넘깁니다.

이렇게 슈퍼비전 트리 아래에 Cowboy2 서버를 실행시킵니다.
지정한 포트 `8080`과 HTTP 스키마(HTTPS를 지정할 수도 있음)로 Cowboy를 실행하고, `Example.HelloWorldPlug`를 들어오는 모든 웹 요청을 담당하는 인터페이스로 지정합니다.

이제 앱을 실행하고 웹 요청을 보낼 준비가 되었습니다! OTP 앱을 `--sup` 플래그로 생성했으니, `application` 함수 덕분에 `Example` 애플리케이션이 자동으로 실행되는 점을 유의하세요.

`mix.exs`를 열면 아래와 같은 내용을 볼 수 있습니다.

```elixir
def application do
  [
    extra_applications: [:logger],
    mod: {Example.Application, []}
  ]
end
```

이제 최소한의 Plug 기반 웹 서버를 사용해 볼 준비가 되었습니다.
커맨드 라인에서 다음을 실행하십시오.

```shell
mix run --no-halt
```

일단 모든 것이 컴파일이 끝나고`[info] Started app`가 나타나면, 웹 브라우저에서
<http://127.0.0.1:8080>을 여세요. 다음 내용이 보일 것입니다.

```
Hello World!
```

## Plug.Router

웹 사이트 또는 REST API와 같은 대부분의 애플리케이션의 경우처럼 한 라우터가 서로 다른 경로들과 서로 다른 HTTP 메소드에 대한 요청을 각각 다른 처리기들로 라우팅 해야 할 것입니다.
`Plug`는 이런 일을 할 수 있는 라우터를 제공합니다. 봐서 알 수 있듯이, Elixir에서는 Plug만으로 Sinatra가 하던 일을 할 수 때문에 Sinatra와 같은 프레임워크가 필요하지 않습니다.

시작해봅시다. `lib/example/router.ex` 파일을 만들어 다음 내용을 안에 넣으세요.

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

이것은 굉장히 최소한의 라우터이지만 코드는 꽤 자명합니다.
`use plug.Router`를 통해 매크로를 넣어 `:match`와 `:dispatch`라는 내장 Plug를 설정했습니다.
루트에 대한 GET 요청을 처리하는 최상위 라우트와 다른 모든 요청과 매치해 404 메시지를 반환하는 두 번째 라우트가 정의되어 있습니다.

다시 `lib/example/application.ex`로 돌아가서, `Example.Router`를 웹 서버 슈퍼바이저 트리에 넣어 주어야 합니다.
`Example.HelloWorldPlug` plug를 새로운 라우터로 교체해 봅시다.

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

서버를 재시작해 봅시다. 이전 서버가 실행중이라면 (`Ctrl + C`를 두 번 눌러) 중지하세요.

이제 췝브라우저에서 <http://127.0.0.1:8080>로 이동하세요.
`Welcome`이 출력될 것 입니다.
그런 다음 <http://127.0.0.1:8080/waldo> 또는 다른 경로로 이동하십시오.
404 응답으로`Oops!`를 출력될 것 입니다.

## 다른 Plug 추가하기

일반적으로 웹 애플리케이션에서는 여러 개의 Plug를 사용하고, Plug에는 각자 담당하는 역할이 있습니다.
이를테면 라우팅을 처리하는 Plug, 들어오는 웹 요청이 유효한지 검증하는 Plug, 들어오는 요청을 인증하는 Plug 등이 있을 수 있습니다.
이 섹션에서는 들어오는 요청 속 매개변수가 유효한지를 검사하는 Plug를 정의하고, 애플리케이션이 라우터 Plug와 유효성 검사 Plug를 _모두_ 사용하도록 해보겠습니다.

요청에 필요한 매개 변수가 있는지 확인하기 위한 Plug를 만들고자 합니다.
Plug 안에서 유효성 검증을 구현하면 유효한 요청 만 애플리케이션에 전달 될 수 있습니다.
Plug는 `:paths`와 `:fields` 옵션으로 초기화 되어야 합니다.
이것은 로직을 적용 할 경로(paths)와 필요한 필드(fields)를 나타냅니다.

_참고_ : Plug는 모든 요청에 적용되므로 요청을 필터링해 일부에만 로직을 적용할 필요가 있습니다.
요청을 무시하려면 그냥 연결을 그대로 넘겨주면 됩니다.

완성 된 Plug를 보고 어떻게 작동하는지 설명하겠습니다.
`lib/example/plug/verify_request.ex`에 만들겠습니다.

```elixir
defmodule Example.Plug.VerifyRequest do
  defmodule IncompleteRequestError do
    @moduledoc """
    필요한 필드가 발견되지 않은 경우에 발생시킬 에러.
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

우선 주목해야 할 부분은 유효하지 않은 요청의 경우에 발생시킬 새로운 예외 `IncompleteRequestError`를 정의한다는 점입니다.

그 다음은 `call/2` 함수로,
이는 검증 로직을 적용할지 말지를 결정하는 곳입니다.
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

이 코드에서는 애플리케이션에게 router안의 다른 코드 실행 _전에_ `VerifyRequest` plug로 요청을 전달하도록 하고 있습니다.

다음 함수를 통해서,

```elixir
plug VerifyRequest, fields: ["content", "mimetype"], paths: ["/upload"]
```

자동으로 `VerifyRequest.init(fields: ["content", "mimetype"], paths: ["/upload"])`을 호출합니다.
이것은 차례로 `VerifyRequest.call(conn, opts)` 함수에 주어진 옵션을 전달합니다.

이제 plug가 동작하는것을 보겠습니다. 로컬 서버를 강제 종료 시킵니다. ('ctrl + c' 두번 눌러서 종료가 된다는 점을 기억해주세요).
그 다음, 서버를 재시작합니다. (`mix run --no-halt`).
이제 브라우저에서 <http://127.0.0.1:8080/upload>로 가보면 해당 페이지는 동작하지 않습니다. 브라우저에서 제공하는 디폴트 에러 페이지를 보게 될 것입니다.

이제 필요한 파라미터를 추가해서 <http://127.0.0.1:8080/upload?content=thing1&mimetype=thing2>로 가봅시다.
'Uploaded' 메시지를 보게 될 것입니다.

오류가 발생했을 때 _아무런_ 페이지도 표시되지 않는 것은 좋지 않습니다. Plug를 사용하여 오류를 처리하는 방법은 나중에 살펴보겠습니다.

## HTTP 포트 설정하기

`Example` 모듈과 어플리케이션을 정의했을 때, HTTP 포트는 모듈에 하드 코딩되어 있습니다.
설정 파일에 포트를 설정하여 포트를 구성 할 수 있도록 하는 것이 모범 사례로 생각됩니다.

`config/config.exs` 안에 애플리케이션 환경 변수 하나를 설정할 것입니다.

```elixir
use Mix.Config

config :example, cowboy_port: 8080
```

그 다음, `lib/example/application.ex`를 업데이트해서 port 설정값을 읽고 Cowboy로 그것을 보내도록 합니다.
private 함수를 정의해서 이 책임을 감싸도록 하겠습니다.

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

`Application.get_env`의 세 번째 인자는 설정 지시자가 정의되지 않은 경우의 기본값입니다.

이걸로 애플리케이션을 실행하기 위한 명령을 사용할 수 있습니다.

```shell
mix run --no-halt
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

테스트는 다음 처럼 실행해 볼 수 있습니다.

```shell
mix test test/example/router_test.exs
```

## Plug.ErrorHandler

앞에서 <http://127.0.0.1:8080/upload>경로에 필요한 파라미터 없이 가는 경우, 친숙한 에러 페이지나 합리적인 HTTP 상태코드를 받지 못한다고 했습니다.
그저 브라우저의 디폴트 에러 페이지와 `500 Internal Server Error` 메시지 뿐이었죠.

[`Plug.ErrorHandler`](https://hexdocs.pm/plug/Plug.ErrorHandler.html)를 통해 이것을 고쳐 봅시다.

먼저, `lib/example/router.ex` 를 열고 다음과 같이 적어봅시다.

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

가장 위에 `use Plug.ErrorHandler`를 추가했다는 것을 알아차릴 것입니다.

이 플러그는 어떤 에러든 잡아서, `handle_errors/2` 함수를 찾아 호출해 그것을 처리하도록 합니다.

`handle_errors/2` 는 `conn`을 첫 번째 파라미터, 3개 아이템(`:kind`, `:reason`, `:stack`)이 들어간 map을 2번째 파라미터로 받습니다.

무슨 일이 벌어지는지 살펴보기 위해 매우 간단한 `handle_errors/2` 함수를 정의했습니다.
앱을 중단하고 다시 시작해서 이것이 동작하는지 봅시다!

이제 <http://127.0.0.1:8080/upload>로 가보면, 친숙한 에러 메시지를 볼 수 있습니다.

터미널을 보면 다음과 같은 메시지를 보게 될 겁니다.

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

아직 `500 Internal Server Error` 에러 메시지를 보내고 있습니다. 예외 모듈에 `:plug_status` 필드를 추가하면 상태 코드를 변경할 수 있습니다.
`lib/example/plug/verify_request.ex` 파일을 열고 다음을 추가하세요.

```elixir
defmodule IncompleteRequestError do
  defexception message: "", plug_status: 400
end
```

서버를 재시작하고 새로고침하면, 이제 `404 Bad Request` 메시지를 볼 수 있게 됩니다.

이 plug를 사용하면 개발자가 문제를 해결하는 데 필요한 유용한 정보를 쉽게 파악할 수 있을 뿐만 아니라 최종 사용자에게 멋진 페이지를 제공하여 앱이 완전히 망가진 것처럼은 보이지 않도록 할 수 있습니다!

## 사용 가능한 Plug

많은 Plug들을 어려운 설정 없이 사용할 수 있습니다.
전체 목록은 [여기](https://github.com/elixir-lang/plug#available-plugs)의 Plug 문서에서 찾을 수 있습니다.
