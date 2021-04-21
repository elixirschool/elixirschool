%{
  version: "1.0.1",
  title: "GenStage",
  excerpt: """
  이 강좌에서는 GenStage가 어떤 역할을 하고, 애플리케이션에서 어떻게 사용하는지 자세히 살펴보도록 하겠습니다.
  """
}
---

## 소개

그래서 GenStage가 뭔가요? 공식 문서에 따르면, "Elixir를 위한 사양 및 계산 흐름" 입니다. 구체적으로는 어떤 뜻일까요?

이것은 GenStage가 개별 프로세스에서 독립적인 단계에 의해 수행 될 작업의 파이프라인을 정의할 수 있는 방법을 제공한다는 의미입니다. 이전에 파이프 라인으로 작업한 적이 있다면 이러한 개념 중 일부는 익숙할 수 있습니다.

어떻게 동작하는지 더 잘 이해하기 위해, 간단한 프로듀서-컨슈머 플로우를 생각해보겠습니다.

```
[A] -> [B] -> [C]
```

이 예제에서는 3개의 단계가 있습니다. `A` 프로듀서, `B` 프로듀서-컨슈머, `C` 컨슈머입니다. `A`는 `B`에 의해 소비되는 값을 생성하고 `B`는 약간의 작업을 수행하고 우리의 소비자 `C`가 받는 새로운 값을 반환합니다. 다음 단락에서 보시겠지만 단계의 역할은 중요합니다.

예는 1 대 1 생산자 대 소비자이지만 특정 단계에서 여러 프로듀서와 여러 컨슈머를 둘 수 있습니다.

이러한 개념을보다 잘 설명하기 위해 GenStage로 파이프 라인을 만들어 보겠습니다. 그전에 GenStage가 의존하는 역할에 대해 알아 보겠습니다.

## Consumers and Producers

읽은 것처럼 단계의 역할은 중요합니다. GenStage 사양은 세 가지 역할로 나뉩니다.

+ `:producer` - 소스. 프로듀서는 컨슈머의 요구를 기다리고 요청한 이벤트로 응답합니다.

+ `:producer_consumer` - 소스인 동시에 싱크. 프로듀서-컨슈머는 다른 컨슈머의 요구에 응답 할 수 있을 뿐 아니라 프로듀서로부터의 이벤트를 요청할 수 있습니다.

+ `:consumer`- 싱크. 프로듀서에게 데이터를 요청하고 수신하는 컨슈머입니다.

프로듀서가 수요를 __기다리고__ 있다는 것을 눈치채셨나요? GenStage를 통해 컨슈머는 업스트림으로 수요를 보내고 프로듀서의 데이터를 처리합니다. 이것은 역압으로 알려진 메커니즘을 용이하게합니다. 역압은 컨슈머가 바쁠 때 과압하지 않도록 프로듀서에게 부담을 줍니다.

이제 GenStage 내의 역할을 다뤘습니다.

## 시작하기

이 예제에서는 숫자를 넣어 짝수를 정렬하고 출력하는 GenStage 애플리케이션을 만들어 보겠습니다.

이 애플리케이션에서는 3개의 GenStage 롤을 사용할 것입니다. 프로듀서는 숫자를 세고 넣는 역할을 합니다. 프로듀서-컨슈머를 사용하여 짝수만 필터링하고 나중에 다운스트림의 요구에 응답합니다. 마지막으로 남은 숫자를 표시하는 컨슈머를 만듭니다.

슈퍼바이저 트리가 있는 프로젝트를 생성하는 것부터 시작해 보겠습니다.

```shell
$ mix new genstage_example --sup
$ cd genstage_example
```

`mix.exs`의 의존성에 `gen_stage`을 넣어 갱신합니다.

```elixir
defp deps do
  [
    {:gen_stage, "~> 0.11"}
  ]
end
```

더 진행하기 전에 의존성을 받아 컴파일을 해둡시다.

```shell
$ mix do deps.get, compile
```

이제 프로듀서를 만들 준비가 되었습니다.

## Producer

GenStage 애플리케이션의 첫 걸음은 프로듀서를 만드는 것 부터 시작합니다. 전에 말했던 것처럼 정적인 숫자의 스트림을 넣는 프로듀서를 만들고 싶습니다. 프로듀서 파일을 생성합시다.

```shell
$ mkdir lib/genstage_example
$ touch lib/genstage_example/producer.ex
```

이제 코드를 추가할 수 있습니다.

```elixir
defmodule GenstageExample.Producer do
  use GenStage

  def start_link(initial \\ 0) do
    GenStage.start_link(__MODULE__, initial, name: __MODULE__)
  end

  def init(counter), do: {:producer, counter}

  def handle_demand(demand, state) do
    events = Enum.to_list(state..(state + demand - 1))
    {:noreply, events, state + demand}
  end
end
```

여기서 주의해야 할 제일 중요한 부분은 `init/1`과 `handle_demand/2`입니다. `init/1`에서는 다른 GenServer에서 했던 것처럼 초기 상태를 설정했지만 주목해야 하는 것은 자신을 프로듀서로 표시한 것입니다. `init/1` 함수의 응답은 GenStage가 프로세스를 분류하기 위해 사용하는 것입니다.

`handle_demand/2` 함수는 우리 프로듀서에서 제일 중요하며, 모든 GenStage 프로듀서에 의해 구현되어야하는 곳입니다. 여기서 우리는 컨슈머가 요구하는 일련의 숫자를 반환하고 카운터를 증가시킵니다. 위의 코드에서 컨슈머의 요구인 `demand`는 처리할 수있는 이벤트의 수를 나타내는 정수이며 기본값은 1000입니다.

## Producer Consumer

이제 숫자를 생성하는 프로듀서에서 프로듀서-컨슈머로 넘어 갑시다. 프로듀서에게 숫자를 요청하고, 홀수를 걸러 내고, 요구에 응답하기를 원합니다.

```shell
$ touch lib/genstage_example/producer_consumer.ex
```

예제 코드를 참고해 파일을 갱신해 봅시다.

```elixir
defmodule GenstageExample.ProducerConsumer do
  use GenStage

  require Integer

  def start_link do
    GenStage.start_link(__MODULE__, :state_doesnt_matter, name: __MODULE__)
  end

  def init(state) do
    {:producer_consumer, state, subscribe_to: [GenstageExample.Producer]}
  end

  def handle_events(events, _from, state) do
    numbers =
      events
      |> Enum.filter(&Integer.is_even/1)

    {:noreply, numbers, state}
  end
end
```

프로듀서-컨슈머의 `init/1`에 새로운 옵션이 들어가고 함수`handle_events/3`를 추가한 것을 눈치 채셨나요? `subscribe_to` 옵션을 통해 GenStage가 특정 프로듀서와 통신하도록 지시합니다.

`handle_events/3` 함수는 들어오는 이벤트를 받고, 처리하고, 변형 된 세트를 반환하는 주력 도구입니다. 앞으로 보실 컨슈머는 거의 같은 방식으로 구현되지만 중요한 차이점은 `handle_events/3` 함수가 반환하는 것과 사용 방법입니다. 프로세스의 레이블을 producer_consumer라 표시할 때, 튜플의 두 번째 인자인 숫자는 다운스트림 컨슈머의 요구를 충족시키는 데 사용되지만, 컨슈머는 이 값을 버립니다.

## Consumer

마지막으로 컨슈머만 남았습니다. 시작해보죠.

```shell
$ touch lib/genstage_example/consumer.ex
```

컨슈머와 프로듀서-컨슈머는 아주 비슷하기 때문에 코드도 그렇게 다르지 않을 것입니다.

```elixir
defmodule GenstageExample.Consumer do
  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, :state_doesnt_matter)
  end

  def init(state) do
    {:consumer, state, subscribe_to: [GenstageExample.ProducerConsumer]}
  end

  def handle_events(events, _from, state) do
    for event <- events do
      IO.inspect({self(), event, state})
    end

    # As a consumer we never emit events
    {:noreply, [], state}
  end
end
```

이전 단락에서 살펴본 것처럼, 컨슈머는 이벤트를 발생시키지 않으므로 튜플의 두 번째 값도 버려집니다.

## 전부 다 합치기

이제 프로듀서, 프로듀서-컨슈머, 컨슈머를 만들었으니 전부 다 합쳐야 합니다.

`lib/genstage_example/application.ex` 파일을 열어 슈퍼바이저 트리에 새 프로세스를 넣어봅시다.

```elixir
def start(_type, _args) do
  import Supervisor.Spec, warn: false

  children = [
    worker(GenstageExample.Producer, [0]),
    worker(GenstageExample.ProducerConsumer, []),
    worker(GenstageExample.Consumer, [])
  ]

  opts = [strategy: :one_for_one, name: GenstageExample.Supervisor]
  Supervisor.start_link(children, opts)
end
```

전부 제대로 되었다면, 프로젝트를 실행해 잘 돌아가는 것을 확인할 수 있습니다.

```shell
$ mix run --no-halt
{#PID<0.109.0>, 2, :state_doesnt_matter}
{#PID<0.109.0>, 4, :state_doesnt_matter}
{#PID<0.109.0>, 6, :state_doesnt_matter}
...
{#PID<0.109.0>, 229062, :state_doesnt_matter}
{#PID<0.109.0>, 229064, :state_doesnt_matter}
{#PID<0.109.0>, 229066, :state_doesnt_matter}
```

해냈습니다! 애플리케이션은 예상한 대로 홀수만 생략하고 매우 __빠릅니다__.

이 지점에서 동작하는 파이프라인이 있습니다. 숫자를 넣는 프로듀서와, 홀수를 버리는 프로듀서-컨슈머, 이 모든 걸 표시하고 플로우를 계속하는 컨슈머가 있습니다.  소개에서 이야기했지만, 한 개 이상의 프로듀서나 컨슈머도 있을 수 있습니다. 한번 봅시다.

## 여러 프로듀서나 컨슈머

예제의 `IO.inspect/1` 출력을 조사해 보면 모든 이벤트가 단일 PID로 처리되는 것을 알 수 있습니다. `lib/genstage_example/application.ex`를 조금 수정해 여러 워커를 사용하도록 바꿔봅시다.

```elixir
children = [
  worker(GenstageExample.Producer, [0]),
  worker(GenstageExample.ProducerConsumer, []),
  worker(GenstageExample.Consumer, [], id: 1),
  worker(GenstageExample.Consumer, [], id: 2)
]
```

이제 두 컨슈머를 설정했으니 애플리케이션을 실행하여 어떻게 되는지 봅시다.

```shell
$ mix run --no-halt
{#PID<0.120.0>, 2, :state_doesnt_matter}
{#PID<0.121.0>, 4, :state_doesnt_matter}
{#PID<0.120.0>, 6, :state_doesnt_matter}
{#PID<0.120.0>, 8, :state_doesnt_matter}
...
{#PID<0.120.0>, 86478, :state_doesnt_matter}
{#PID<0.121.0>, 87338, :state_doesnt_matter}
{#PID<0.120.0>, 86480, :state_doesnt_matter}
{#PID<0.120.0>, 86482, :state_doesnt_matter}
```

보시는 것처럼, 여러 PID를 가지고 있습니다. 코드 한 줄을 추가해 컨슈머 ID를 부여했습니다.

## Use Cases

GenServer를 살펴보고 첫 예제 애플리케이션을 만들었으니, _실제_론 어떻게 사용하는지 알아봅시다.

+ 데이터 트렌스폼 파이프라인 - 프로듀서는 간단한 숫자 생성기일 필요는 없습니다. 데이터베이스나 아파치 카프카같은 다른 곳에서 이벤트를 만들 수 있습니다. 프로듀서-컨슈머, 컨슈머와의 조합으로 메트릭을 처리, 정렬, 카탈로그, 저장할 수 있습니다.

+ 작업 큐 - 이벤트가 무엇이든 가능하므로 여러 컨슈머가 처리할 작업의 단위를 생성할 수 있습니다.

+ 이벤트 처리 - 데이터 파이프라인과 비슷하게 소스에서 실시간으로 넣는 이벤트에 대해 수신, 처리, 정렬, 행동을 할 수 있습니다.

이는 GenStage가 할 수 있는 일의 __일부__일 뿐입니다.
