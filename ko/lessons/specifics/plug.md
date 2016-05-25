---
layout: page
title: Plug
category: specifics
order: 1
lang: ko
---

Ruby를 잘 알고 계신다면 Plug는 여러 부분에서 Sinatra의 영향을 받은 Rack이라고 생각해도 좋습니다. Plug는 Web 애플리케이션을 위한 명세와 Web 서버를 위한 어댑터를 제공합니다. Elixir 코어의 일부가 아닌, Elixir의 공식 프로젝트입니다.

{% include toc.html %}

## 설치하기

mix를 사용하여 간단하게 설치할 수 있습니다. Plug를 설치하기 위해서는 `mix.exs`에 두 가지 작은 수정을 해야 합니다. 우선 Plug와 Web 서버에 대한 의존성을 추가합니다. Web 서버는 Cowboy를 사용합니다:

```elixir
defp deps do
  [{:cowboy, "~> 1.0.0"},
   {:plug, "~> 1.0"}]
end
```

다음으로 Web 서버와 Plug를 함께 OTP 애플리케이션에 추가만 하면 됩니다:

```elixir
def application do
  [applications: [:cowboy, :logger, :plug]]
end
```

## 명세

Plug를 만들기 위해서는 Plug의 명세를 알고 그것을 올바르게 따를 필요가 있습니다. 기쁘게도 필요한 것은 단 두 개의 함수, `init/1`과 `call/2` 뿐입니다.

`init/1` 함수는 Plug의 옵션을 초기화하기 위해서 사용되며, 그 옵션은 `call/2` 함수의 두 번째 인수로 넘겨집니다. `call/2` 함수는 초기화된 옵션과 함께 `%Plug.Conn`를 첫 번째 인수로 하고, 커넥션을 돌려줄 것이라고 가정하고 있습니다.

다음은 "Hello World!"를 돌려주는 간단한 Plug입니다:

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

## Plug 만들기

이 예제에서는 요청이 몇몇 필요한 인수를 가졌는지 아닌지를 확인하는 Plug를 만듭니다. Plug에 검증 기능을 구현하여 유효한 요청만을 애플리케이션에 넘겨줄 수 있습니다. 여기에서 만드는 Plug는 두 개의 옵션, `:paths`와 `:fields`로 초기화된다고 가정합니다. 이들은 검증을 적용할 경로와 필요한 필드를 가리킵니다.

_노트_: Plug는 모든 요청에 대해서 사용됩니다. 이것이 각 요청을 확인하고, 실제로 필요한 일부에 대해서만 검증을 적용하는 이유입니다. 요청을 가공하지 않으려면 그저 그 커넥션을 무시하세요.

구현이 끝난 Plug를 살펴보면서 그것이 실제로 어떻게 동작하는지를 설명해나가겠습니다. Plug를 `lib/plug/verify_request.ex`에 만듭니다:

```elixir
defmodule Example.Plug.VerifyRequest do
  import Plug.Conn

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
    verified = body_params
               |> Map.keys
               |> contains_fields?(fields)
    unless verified, do: raise IncompleteRequestError
  end

  defp contains_fields?(keys, fields), do: Enum.all?(fields, &(&1 in keys))
end
```

우선 주목해야 할 부분은 새로운 예외 `IncompleteRequestError`를 정의한다는 점과, 그 옵션 중에 `:plug_status`가 있다는 점입니다. 이벤트에서 예외가 발생한 경우 이 옵션이 사용되어 Plug가 HTTP 상태 코드를 돌려주게 됩니다. 

그 다음은 `call/2` 메소드로, 이는 검증을 적용할지 말지를 결정하는 곳입니다. 요청 경로가 `:paths` 옵션에 포함되는 경우에만 `verify_request!/2`를 호출합니다.

마지막으로는 비공개 함수인 `verify_request!/2`로 필요한 `:fields`가 전부 존재하고 있는지를 확인합니다. 만약 부족한 필드가 있는 경우에는 `Incompleterequesterror`를 발생시킵니다.

## Plug.Router 사용

`VerifyRequest` Plug가 완성되었으므로 라우터로 넘어가 봅시다. Plug가 라우터를 무료로 제공하고 있으므로 Elixir에서는 Sinatra와 같은 프레임워크를 필요로 하지 않습니다.

우선 `lib/plug/router.ex`를 만들고 다음의 코드를 복사하세요:

```elixir
defmodule Example.Plug.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/", do: send_resp(conn, 200, "Welcome")
  match _, do: send_resp(conn, 404, "Opps!")
end
```

이것은 가장 작은 크기의 라우터입니다만, 코드 자체가 자기 자신을 잘 설명하고 있습니다. `use Plug.Router`에서 매크로를 몇 개 불러오고, 2개의 내장 Plug, `:match`와 `:dispatch`를 불러옵니다. 2개의 라우터가 정의되고, 하나는 최상위 경로로 들어오는 GET의 반환 값을 제어합니다. 두 번째 라우터는 그 이외의 모든 요청에 대해서 404 메시지를 반환하고 있습니다.

이 라우터에 Plug를 추가해보죠:

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
  match _, do: send_resp(conn, 404, "Opps!")
end
```

끝입니다! Plug를 끼워넣어, `/upload`에 대한 요청이 `"content"`와 `"mimetype"`를 포함하고 있는지를 확인한 뒤, 포함하고 있을 때만 라우터의 코드가 실행되도록 만들었습니다. 

이 자체로는 `/upload` 라우터가 그다지 유용하지는 않습니다만, Plug를 만들고 결합하는 방법에 관해서는 확인할 수 있었습니다.

## Web 애플리케이션의 실행

애플리케이션을 실행하려면, 우선 Web 서버, 여기에서는 Cowboy의 설치와 설정을 해야 합니다. 지금 시점에서는 단순히 동작할 수 있도록 필요한 수정을 적용할 뿐입니다만, 이후의 레슨에서 더 자세히 살펴볼 것입니다.

`mix.exs`의 `application` 부분을 변경하여 Elixir에게 애플리케이션에 대해서 알려주고, 환경변수를 설정하는 부분에서부터 시작해봅시다. 코드는 다음과 같이 수정될 것입니다:

```elixir
def application do
  [applications: [:cowboy, :plug],
   mod: {Example, []},
   env: [cowboy_port: 8080]]
end
```

그리고 Cowboy를 실행하고 관리하기 위해서 `lib/example.ex`를 수정해야 합니다:

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

이걸로 애플리케이션을 실행하기 위한 명령을 사용할 수 있습니다:

```shell
$ mix run --no-halt
```

## Plug의 테스트

Plug의 테스트는 `Plug.Test` 덕분에 무척 간단합니다. 테스트를 간편하게 만들어주는 편리한 함수가 다수 포함되어 있습니다.

라우터의 테스트를 이해할 수 있는지 확인해보세요:

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

## 사용 가능한 Plug

많은 Plug들을 어려운 설정 없이 사용할 수 있습니다. 목록은 [여기](https://github.com/elixir-lang/plug#available-plugs)의 Plug 문서에서 찾을 수 있습니다.
