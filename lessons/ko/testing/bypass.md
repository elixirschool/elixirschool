%{
  version: "1.0.1",
  title: "Bypass",
  excerpt: """
  애플리케이션을 테스트할 때 외부 서비스에 요청해야 하는 경우가 종종 있습니다. 
  예상치 못한 서버 오류와 같은 다양한 상황을 시뮬레이션 하고싶을 수도 있습니다. 
  Elixir는 이러한 상황을 효율적으로 처리하기 위해 약간의 도움이 필요합니다.

  이 단원에서는 [bypass](https://github.com/PSPDFKit-labs/bypass)가 테스트에서 이러한 요청을 빠르고 쉽게 처리하는데 있어서 어떻게 도움이 되는지 탐구할 것입니다.
  """
}
---

## Bypass란 무엇인가요? 

[Bypass](https://github.com/PSPDFKit-labs/bypass)는 "클라이언트 요청에 대해 미리 준비된 응답을 반환하기 위해 실제 HTTP 서버 대신 설치할 수 있는 커스텀 plug를 신속하게 만드는 방법" 이라고 설명하고 있습니다.

무슨 뜻일까요?
속을 들여다보면 Bypass는 요청들을 수신하고 응답하는 외부 서버로 가장하는 하나의 OTP 애플리케이션입니다. 
미리 정의된 응답들로 응답함으로써, 예상 시나리오와 함께 마주하게 될 예상치 못한 서비스 중단 및 오류와 같은 가능성을 어떠한 외부 요청 없이도 모두 테스트할 수 있습니다.

## Bypass 사용하기

Bypass의 기능을 더 잘 설명하기 위해, 여기서 domain 목록에 ping을 날려 그들이 온라인 상태인지 확인하는 간단한 유틸리티 애플리케이션을 작성해 볼 것입니다.
이를 위해 새로운 수퍼바이저 프로젝트를 생성하고 설정 가능한 간격으로 도메인 목록을 확인하는 GenServer를 만듭니다.
테스트에서 Bypass를 이용하여 애플리케이션이 다양한 결과에 대해 잘 동작하는지 검증할 수 있습니다.

_참고_: 최종 코드로 바로 건너뛰고 싶으면, Elixir School 레포 [Clinic](https://github.com/elixirschool/clinic)로 가서 한 번 살펴보세요.

이 시점에서 새로운 Mix 프로젝트를 만드는 것과 의존성들을 추가하는 것에는 익숙하다고 보기에 테스트할 코드 부분들에만 집중할 것입니다. 
빠른 복습이 필요하면 [Mix](https://elixirschool.com/en/lessons/basics/mix)레슨의 [New Projects](https://elixirschool.com/en/lessons/basics/mix/#new-projects) 섹션을 참고하세요.

도메인들에 보낼 요청을 만드는 것을 처리할 새로운 모듈을 하나 만드는 것으로 시작해 봅시다.
[HTTPoison](https://github.com/edgurgel/httpoison)을 써서 `ping/1` 함수를 정의합시다.
`ping/1` 함수는 URL를 인자로 받아, HTTP 200 요청이면 `{:ok, body}`를 반환하고 다른 모든 요청은 `{:error, reason}`을 반환하도록 합니다.

```elixir
defmodule Clinic.HealthCheck do
  def ping(urls) when is_list(urls), do: Enum.map(urls, &ping/1)

  def ping(url) do
    url
    |> HTTPoison.get()
    |> response()
  end

  defp response({:ok, %{status_code: 200, body: body}}), do: {:ok, body}
  defp response({:ok, %{status_code: status_code}}), do: {:error, "HTTP Status #{status_code}"}
  defp response({:error, %{reason: reason}}), do: {:error, reason}
end
```

여기서 GenServer를 만들지 _않는다는_ 것을 알아차릴텐데, 그것은 다음의 정당한 이유가 있습니다.
GenServer에서 기능(관심사)을 분리함으로써, 동시성에 대한 장애물 없이 코드를 테스트할 수 있습니다.

코드가 준비되면 테스트를 시작해야 합니다. 
Bypass를 사용하기 전에 그것이 실행 중이라고 보장해야 합니다. 
그렇게 하려면 다음과 같이 `test/test_helper.exs`를 업데이트 해보겠습니다.

```elixir
ExUnit.start()
Application.ensure_all_started(:bypass)
```
이제 테스트 중에 Bypass가 실행될 것임을 알고 있으므로 `test/clinic/health_check_test.exs` 으로 이동하여 설정을 완료하겠습니다. 
Bypass가 요청들에 접근하도록 준비하려면 테스트 셋업 콜백에서 연결을 `Bypass.open/1` 를 이용해 열어야 합니다.

```elixir
defmodule Clinic.HealthCheckTests do
  use ExUnit.Case

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end
end
```

여기서는 Bypass에 default port를 사용하도록 의존하는데, 바꿔야 할 필요가 있다면(뒤의 섹션에서 그렇게 하겠지만)
우리는 `Bypass.open/1`에 `:port` 옵션과 값을 `Bypass.open(port: 1337)`처럼 줄 수 있습니다.
이제 우리는 Bypass가 작동하게 할 준비가 됐습니다. 먼저, 다음과 같이 성공하는 요청부터 시작해 보겠습니다.

```elixir
defmodule Clinic.HealthCheckTests do
  use ExUnit.Case

  alias Clinic.HealthCheck

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "request with HTTP 200 response", %{bypass: bypass} do
    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(conn, 200, "pong")
    end)

    assert {:ok, "pong"} = HealthCheck.ping("http://localhost:#{bypass.port}")
  end
end
```

테스트는 충분히 간단하고 실행해보면 통과하는걸 볼 수 있지만, 각 부분이 무엇을 하는지 한 번 살펴봅시다.
먼저 test에서 보이는 것은 `Bypass.expect/2` 함수입니다.

```elixir
Bypass.expect(bypass, fn conn ->
  Plug.Conn.resp(conn, 200, "pong")
end)
```

`Bypass.expect/2`는 Bypass 커넥션과, 커넥션을 변경하고 반환할 1-arity 함수를 인자로 받습니다.
이것은 해당 요청이 기대한 요청인지 검증할 수 있는 기회가 됩니다.
테스트 url에 `/ping` 을 포함시키고 request path와 HTTP method를 검증하도록 업데이트 합시다.

```elixir
test "request with HTTP 200 response", %{bypass: bypass} do
  Bypass.expect(bypass, fn conn ->
    assert "GET" == conn.method
    assert "/ping" == conn.request_path
    Plug.Conn.resp(conn, 200, "pong")
  end)

  assert {:ok, "pong"} = HealthCheck.ping("http://localhost:#{bypass.port}/ping")
end
```

테스트의 마지막 부분에서 `HealthCheck.ping/1`을 사용하고 응답을 검사했는데, `bypass.port`는 무엇일까요?
Bypass는 실제로 로컬 port를 수신대기하며 해당 요청들을 가로채기 때문에, 
`Bypass.open/1`에 옵션을 주지 않은 우리는 `bypass.port`를 써서 포트 기본값을 조회했습니다.

다음은 오류에 관한 테스트 케이스 추가입니다.
첫 번째 테스트에 사소한 변경만 해주는 걸로 시작할 수 있습니다.
status code로 500을 반환하고 `{:error, reason}` 튜플을 반환하는지 검증합니다.

```elixir
test "request with HTTP 500 response", %{bypass: bypass} do
  Bypass.expect(bypass, fn conn ->
    Plug.Conn.resp(conn, 500, "Server Error")
  end)

  assert {:error, "HTTP Status 500"} = HealthCheck.ping("http://localhost:#{bypass.port}")
end
```

이 테스트 케이스에는 특별할 것이 없으므로 바로 다음으로 넘어갑시다. 다음은 예상치 못한 서버 중단의 경우입니다. 
우리가 가장 관심있는 요청들입니다.
이를 달성하기 위해 `Bypass.expect/2`를 사용하지 않고 `Bypass.down/1`을 이용해 커넥션을 강제 종료 시킵니다.

```elixir
test "request with unexpected outage", %{bypass: bypass} do
  Bypass.down(bypass)

  assert {:error, :econnrefused} = HealthCheck.ping("http://localhost:#{bypass.port}")
end
```

테스트를 실행해 보면 모든것이 기대한대로 통과하는 것을 볼 수 있습니다!
`HealthCheck` 모듈이 테스트 되었으므로 이제 GenServer 기반의 스케쥴러와 함께 테스트하는 경우로 넘어갈 수 있습니다.

## 여러 외부 호스트

이 프로젝트에서는 스케줄러를 베어본으로 유지하고 `Process.send_after/3`를 이용해 반복 확인을 실행할 것입니다. 
`Process` 모듈에 대해서 더 알고싶다면 [documentation](https://hexdocs.pm/elixir/Process.html)을 참고하세요.
스케줄러는 다음 3가지 옵션을 필요로 합니다. sites 모음, 도메인 확인 간격, `ping/1`을 구현하는 모듈.
모듈을 전달함으로써 기능과 GenServer를 더 잘 분리하여 각각을 더 잘 테스트 할 수 있게 해줍니다.

```elixir
def init(opts) do
  sites = Keyword.fetch!(opts, :sites)
  interval = Keyword.fetch!(opts, :interval)
  health_check = Keyword.get(opts, :health_check, HealthCheck)

  Process.send_after(self(), :check, interval)

  {:ok, {health_check, sites}}
end
```

이제 `send_after/2`로 보내진 `:check` 메시지를 처리하기 위해 `handle_info/2` 함수를 정의해야 합니다. 
단순하게 하기 위해 `HealthCheck.ping/1`에 사이트들을 넘기고 
결과를 로그로 `Logger.info`, 오류는 `Logger.error`로 남겨보겠습니다.  

이후에 리포팅 기능은 개선할 수 있도록 코드를 작성합니다.

```elixir
def handle_info(:check, {health_check, sites}) do
  sites
  |> health_check.ping()
  |> Enum.each(&report/1)

  {:noreply, {health_check, sites}}
end

defp report({:ok, body}), do: Logger.info(body)
defp report({:error, reason}) do
  reason
  |> to_string()
  |> Logger.error()
end
```

앞에서 논의한 대로 `HealthCheck.ping/1`에 사이트들을 전달하고 그 결과를 `Enum.each/2`로 순회하며 `report/1` 함수를 각각 적용합니다. 
이 함수들로 스케줄러는 완성되었고 이제 테스트에 집중할 수 있습니다.

스케줄러는 Bypass를 필요로 하지 않으므로 단위 테스트에 너무 집중하지는 않을것입니다. 따라서 바로 다음의 최종 코드로 넘어갈 수 있습니다. 

```elixir
defmodule Clinic.SchedulerTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  alias Clinic.Scheduler

  defmodule TestCheck do
    def ping(_sites), do: [{:ok, "pong"}, {:error, "HTTP Status 404"}]
  end

  test "health checks are run and results logged" do
    opts = [health_check: TestCheck, interval: 1, sites: ["http://example.com", "http://example.org"]]

    output =
      capture_log(fn ->
        {:ok, _pid} = GenServer.start_link(Scheduler, opts)
        :timer.sleep(10)
      end)

    assert output =~ "pong"
    assert output =~ "HTTP Status 404"
  end
end
```

`TestCheck`으로 상태 확인의 테스트 구현을 이용하며 
적절한 메시지들이 로깅되었는지 검증하기 위해 `CaptureLog.capture_log/1`를 이용합니다.

이제 동작하는 `Scheduler`와 `HealthCheck` 모듈이 각각 있으므로 모든것이 잘 동작하는지 검증하는 통합 테스트를 작성해 봅시다.
이 테스트를 위해 Bypass가 필요하며 각 테스트마다 여러 Bypass 요청들을 처리해야 합니다. 어떻게 하는지 보겠습니다.

이전의 `bypass.port`를 기억하시나요? 여러 사이트처럼 흉내내고 싶다면, `:port` 옵션이 유용합니다.
짐작하셨겠지만 각각 다른 포트를 사용하여 여러 Bypass 연결을 생성할 수 있습니다. 이러한 연결은 독립적인 사이트들을 시뮬레이션합니다.
업데이트된 `test/clinic_test.exs` 파일을 다시 보는걸로 시작해보겠습니다.

```elixir
defmodule ClinicTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  alias Clinic.Scheduler

  test "sites are checked and results logged" do
    bypass_one = Bypass.open(port: 1234)
    bypass_two = Bypass.open(port: 1337)

    Bypass.expect(bypass_one, fn conn ->
      Plug.Conn.resp(conn, 500, "Server Error")
    end)

    Bypass.expect(bypass_two, fn conn ->
      Plug.Conn.resp(conn, 200, "pong")
    end)

    opts = [interval: 1, sites: ["http://localhost:1234", "http://localhost:1337"]]

    output =
      capture_log(fn ->
        {:ok, _pid} = GenServer.start_link(Scheduler, opts)
        :timer.sleep(10)
      end)

    assert output =~ "[info]  pong"
    assert output =~ "[error] HTTP Status 500"
  end
end
```

위 테스트에서 딱히 놀라운 것은 없어야 할 것입니다. `setup`에서 단일 Bypass 커넥션을 생성하는 대신, 2개를 생성해서 각각 1234와 1337를 포트로 지정했습니다.
다음은 `Bypass.expect/2` 호출을 보면, `SchedulerTest`에서 봤던 코드랑 같은, 스케줄러를 시작하고 적절한 메시지 로그를 검증하는 코드가 보입니다.

이게 끝입니다! 우리는 도메인에 문제가 있는 경우 계속해서 알려주는 유틸리티를 구축했으며 외부 서비스로 더 나은 테스트를 작성하기 위해 Bypass를 사용하는 방법을 배웠습니다.
