%{
  version: "1.1.1",
  title: "OTP 슈퍼바이저",
  excerpt: """
  슈퍼바이저(Supervisor)는 다른 프로세스의 감시라는 단 하나의 목적에 특화된 프로세스입니다.
  자식 프로세스가 실패하면 자동으로 재시작해주는 것으로 장애에 대한 내성이 높은(Fault-tolerant) 애플리케이션을 만들 수 있게 해줍니다.
  """
}
---

## 설정

슈퍼바이저의 마법은 `Supervisor.start_link/2` 함수의 내부에 있습니다. 
슈퍼바이저와 자식 프로세스를 실행하면서, 슈퍼바이저가 자식 프로세스를 관리하기 위해 사용할 전략을 정의할 수 있습니다.

[OTP 동시성](/ko/lessons/advanced/otp_concurrency)에서 구현한 SimpleQueue를 사용해서 시작해봅시다.

`mix new simple_queue --sup` 으로 슈퍼바이저 트리가 포함된 새로운 프로젝트를 생성합니다.
`SimpleQueue` 모듈에 대한 코드는 `lib/simple_queue.ex` 파일에 있고, 슈퍼바이저 코드는 `lib/simple_queue/application.ex` 파일에 추가될 것입니다.

자식 프로세스들은 다음과 같이 모듈 이름 리스트로 정의되거나,

```elixir
defmodule SimpleQueue.Application do
  use Application

  def start(_type, _args) do
    children = [
      SimpleQueue
    ]

    opts = [strategy: :one_for_one, name: SimpleQueue.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

혹은 구성 옵션을 포함하고 싶다면 다음처럼 튜플로 된 리스트로 정의됩니다.

```elixir
defmodule SimpleQueue.Application do
  use Application

  def start(_type, _args) do
    children = [
      {SimpleQueue, [1, 2, 3]}
    ]

    opts = [strategy: :one_for_one, name: SimpleQueue.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

`iex -S mix`로 실행해보면 `SimpleQueue`가 자동으로 시작된걸 다음처럼 확인해 볼 수 있습니다.

```elixir
iex> SimpleQueue.queue
[1, 2, 3]
```

`SimpleQueue` 프로세스가 정지하거나 종료되면, 슈퍼바이저는 마치 아무 일도 없었던 것처럼 프로세스를 재기동할 것입니다.

### 전략

현재 슈퍼바이저가 사용 가능한 3개의 재시작 전략이 있습니다.

+ `:one_for_one` - 실패한 자식 프로세스만을 재기동합니다.

+ `:one_for_all` - 실패한 이벤트에 포함되어 있는 모든 자식 프로세스를 재기동합니다.

+ `:rest_for_one` - 실패한 프로세스와 그 프로세스보다 이후에 생성된 모든 프로세스를 재기동합니다.

## 자식 명세

슈퍼바이저는 자신이 기동된 후 자식 프로세스들을 어떻게 시작/중단/재시작 할지 반드시 알고 있어야 합니다.
각 자식 모듈에는 이 동작들을 정의하는 `child_spec/1` 함수가 있어야 합니다.
`use GenServer`, `use Supervisor`, `use Agent` 매크로들은 자동으로 이 메소드를 정의해줍니다.(`SimpleQueue` 모듈은 `use GenServer`가 있으니 변경이 필요 없습니다.)
만약 직접 정의하고자 한다면, `child_spec/1` 함수는 다음처럼 옵션들로 된 맵을 반환해야 합니다.

```elixir
def child_spec(opts) do
  %{
    id: SimpleQueue,
    start: {__MODULE__, :start_link, [opts]},
    shutdown: 5_000,
    restart: :permanent,
    type: :worker
  }
end
```

+ `id` - 필수 키.
슈퍼바이저가 자식 명세를 식별하는데 사용됩니다.

+ `start` - 필수 키.
슈퍼바이저에 의해 기동될때 호출하는 모듈/함수/인자

+ `shutdown` - 선택적 키.
자식 프로세스가 종료될때의 동작을 정의합니다.
가능한 옵션은 다음과 같습니다.

  + `:brutal_kill` - 자식 프로세스를 즉시 강제종료합니다.

  + 양의 정수 - 슈퍼바이저가 자식 프로세스를 강제종료하기 전 기다리는 시간(밀리초). 프로세스가 `:worker` 타입이면, 5000이 기본값.

  + `:infinity` -  슈퍼바이저가 자식 프로세스를 강제종료 하기 전 무기한 대기합니다.
`:supervisor` 프로세스 타입의 기본값입니다.
`:worker` 타입에는 권장되지 않습니다.

+ `restart` - 선택적 키. 다음과 같은 자식 프로세스 충돌을 처리하는 몇가지 접근법이 있습니다.

  + `:permanent` - 자식 프로세스는 항상 재시작됩니다.
모든 프로세스의 기본값.

  + `:temporary` - 자식 프로세스는 절대 재시작되지 않습니다.

  + `:transient` - 자식 프로세스가 비정상적으로 종료된 경우에만 재시작됩니다.

+ `type` - 선택적 키.
프로세스들은 `:worker` 타입 혹은 `:supervisor` 타입일 수 있습니다.
기본값은 `:worker` 입니다.

## DynamicSupervisor

슈퍼바이저들은 보통 앱 시작시 실행할 자식 리스트를 가지고 실행합니다.
하지만 때때로 관리 대상 자식 프로세스를 앱 시작시에는 모르는 상태일 수 있습니다. (예를 들면, 각 유저가 사이트에 접속하는걸 처리할 새로운 프로세스를 각각 만드는 웹 애플리케이션이 있습니다.)
이런한 경우 필요에 따라 자식 프로세스를 실행하는 슈퍼바이저가 있어야 할 것입니다.
DynamicSupervisor가 바로 이럴 때 사용됩니다.

자식 프로세스를 지정하지 않을 것이기에 슈퍼바이저를 위한 런타임 옵션들만 정의하면 됩니다.
DynamicSupervisor는 슈퍼비전 전략의 `:one_for_one`만 지원합니다.

```elixir
options = [
  name: SimpleQueue.Supervisor,
  strategy: :one_for_one
]

DynamicSupervisor.start_link(options)
```

그런 다음 새 SimpleQueue를 동적으로 시작하기 위해 슈퍼바이저와 자식 명세를 인자로 받는 `start_child/2`를 사용합니다.(위에서도 말했듯이 `SimpleQueue`는 `use GenServer`가 있으므로 자식 명세가 이미 정의되어 있습니다.)

```elixir
{:ok, pid} = DynamicSupervisor.start_child(SimpleQueue.Supervisor, SimpleQueue)
```

## Task 슈퍼바이저

Task는 전용 슈퍼바이저인 `Task.Supervisor`를 가지고 있습니다. 
동적으로 태스크를 생성하도록 설계되어 있으며, 내부적으로 `DynamicSupervisor`를 사용합니다.

### 설정하기

`Task.Supervisor`를 사용하는 것은 다른 슈퍼바이저를 사용하는 것과 별반 다르지 않습니다.

```elixir
children = [
  {Task.Supervisor, name: ExampleApp.TaskSupervisor, restart: :transient}
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

`Supervisor`와 `Task.Supervisor`의 중요한 차이점은 기본 재시작 전략이 `:temporary` (태스크를 절대 재시작하지 않음)라는 점입니다.

### 관리되는 태스크

슈퍼바이저가 시작된 상태에서 `start_child/2` 함수를 사용해서 관리되는(supervised) 태스크를 생성할 수 있습니다.

```elixir
{:ok, pid} = Task.Supervisor.start_child(ExampleApp.TaskSupervisor, fn -> background_work end)
```

태스크가 도중에 정지한다면 그 즉시 재기동됩니다.
이는 받아야 할 접속이 있거나, 백그라운드 작업을 수행하는 경우에 특히 유용할 것입니다.
