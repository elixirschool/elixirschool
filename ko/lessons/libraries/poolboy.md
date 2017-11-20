---
version: 1.0.1
title: Poolboy
---

동시에 실행 되는 프로세스를 임의로 실행하도록 허용하면 시스템 리소스를 쉽게 소모할 수 있습니다. Poolboy는 워커 풀을 만들어 동시에 실행 되는 프로세스의 수를 제한해 오버헤드가 발생하지 않도록 합니다.

{% include toc.html %}

## 왜 Poolboy를 사용하나요?

잠시 구체적인 예를 생각해 봅시다. 사용자 프로필 정보를 데이터베이스에 저장하기 위한 애플리케이션을 작성한다고 합시다. 모든 사용자 등록에 대해 각각 프로세스를 만들면 무한한 연결 수를 만들게 됩니다. 어떤 시점에서 이러한 연결은 데이터베이스 서버에서 사용할 수있는 제한된 리소스를 놓고 경합하기 시작합니다. 결국 애플리케이션은 이런 경합으로 발생하는 오버헤드로 인해 시간 초과 및 다양한 예외가 발생하게 됩니다.

이 문제의 해결책은 사용자 등록을 위한 프로세스를 각각 만드는 대신 한정된 연결 수를 사용하는 워커(프로세스)들을 사용하는 것입니다. 그러면 시스템 자원이 모두 소모되는 것을 쉽게 피할 수 있습니다.

여기서 Poolboy가 필요합니다. 수동으로 처리하기 위해 고생할 필요없이 `Supervisor`가 관리하는 워커 풀을 만듭니다. 많은 라이브러리가 내부적으로 Poolboy를 사용하고 있습니다. 예를 들어 `postgrex`의 연결 풀 *(PostgreSQL을 사용할 때 Ecto가 사용함)*,`redis_poolex` *(Redis 연결 풀)*가 Poolboy를 사용하는 인기있는 라이브러리중의 일부입니다.

## 설치하기

설치는 mix로 간편하게 할 수 있습니다. 해야 할 일은 `mix.exs`에 Poolboy를 의존성으로 추가하는 것 뿐입니다.

애플리케이션을 먼저 만들어 봅시다.

```bash
$ mix new poolboy_app --sup
$ mix deps.get
```

`mix.exs`에 Poolboy를 의존성으로 추가합니다.

```elixir
defp deps do
  [{:poolboy, "~> 1.5.1"}]
end
```

그리고 Poolboy를 OTP 애플리케이션에 추가합니다.

```elixir
def application do
  [applications: [:logger, :poolboy]]
end
```

## 설정 옵션

Poolboy를 사용하려면 다양한 설정 옵션에 대해 조금은 알아야합니다.

* `:name` - 풀 이름. `:local`, `:global`, `:via` 스코프를 사용할 수 있습니다.
* `:worker_module` - 워커를 나타내는 모듈.
* `:size` - 최대 풀 크기.
* `:max_overflow` - 풀이 비었을 때 생성하는 워커의 최대 개수. (선택적)
* `:strategy` - `:lifo`나 `:fifo`, 체크인한 워커를 가능한 워커의 처음에 위치시킬지 마지막에 위치시킬지 결정합니다. 기본값은 `:lifo`. (선택적)

## Poolboy 설정

이 예제에서는 숫자의 제곱근을 계산하라는 요청을 처리하는 워커 풀을 만듭니다. Poolboy에 집중하기 위해 예제를 간략하게 했습니다.

애플리케이션을 시작할 때 Poolboy 설정 옵션을 정의하고 거기에 자식 워커를 추가해 봅시다.

```elixir
defmodule PoolboyApp do
  use Application

  defp poolboy_config do
    [{:name, {:local, :worker}}, {:worker_module, Worker}, {:size, 5}, {:max_overflow, 2}]
  end

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      :poolboy.child_spec(:worker, poolboy_config, [])
    ]

    opts = [strategy: :one_for_one, name: PoolboyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

처음 정의해야할 것은 풀의 설정 옵션입니다. 고유한 풀 `:name`을 할당하고, `:scope`를 로컬로 설정하고 풀의 `:size`를 총 5개로 설정했습니다. 또 모든 워커가 부하를 받고있는 경우,`:max_overflow` 옵션을 사용하여 부하를 돕는 두 개의 워커를 추가로 생성하도록 합니다. *(`overflow`로 만들어진 워커는 일을 마치면 사라집니다.)*

그런 다음, `poolboy.child_spec/3` 함수를 자식 리스트에 추가해 워커 풀이 애플리케이션이 시작될 때 시작되도록 합니다.

`child_spec/3` 함수는 풀의 이름, 풀 설정, `worker.start_link`에 넘겨질 인자를 받습니다. 이 경우, 넘겨질 인자는 그냥 빈 리스트입니다.

## 워커 생성하기

워커 모듈은 숫자의 제곱근을 계산하고 1초 쉰 다음에 워커의 pid를 출력하는 단순한 GenServer입니다.

```elixir
defmodule Worker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, [])
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_call({:square_root, x}, _from, state) do
    IO.puts("process #{inspect(self)} calculating square root of #{x}")
    :timer.sleep(1000)
    {:reply, :math.sqrt(x), state}
  end
end
```

## Poolboy 사용하기

`Worker`가 생겼으니, 이제 Poolboy를 테스트할 수 있습니다. `:poolboy.transaction` 함수를 사용해 동시에 실행되는 프로세스를 생성하는 간단한 모듈을 만들어 봅시다.

```elixir
defmodule Test do
  @timeout 60000

  def start do
    tasks =
      Enum.map(1..20, fn i ->
        Task.async(fn ->
          :poolboy.transaction(:worker, &GenServer.call(&1, {:square_root, i}), @timeout)
        end)
      end)

    Enum.each(tasks, fn task -> IO.puts(Task.await(task, @timeout)) end)
  end
end
```
사용할 수 있는 풀 워커가 없다면, Poolboy는 타임아웃 기본값(5 초)이 지난 후에 타임아웃 하고 새로운 요청을 받지 않습니다. 이 예제에서는 타임아웃 기본값을 변경하는 법을 설명하기 위해, 타임아웃 기본값을 1분으로 늘렸습니다.

여러 프로세스를 만들려고 해도 *(위 예제에서 총 20 개)* `:poolboy.transaction` 함수는 생성할 프로세스를 설정에서 지정한 총 다섯 개 *(경우에 따라 두 개의 오버플로 워커를 추가)*로 제한합니다. 모든 요청은 요청마다 새 프로세스를 작성하는 것이 아니라 작업자 풀에서 처리됩니다.
