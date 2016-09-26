---
layout: page
title: OTP 슈퍼바이저
category: advanced
order: 5
lang: ko
---

슈퍼바이저(Supervisor)는 다른 프로세스의 감시라는 단 하나의 목적에 특화된 프로세스입니다. 자식 프로세스가 실패하면 자동으로 재시작해주는 것으로 장애에 대한 내성이 높은(Fault-tolerant) 애플리케이션을 만들 수 있게 해줍니다.

{% include toc.html %}

## 설정

슈퍼바이저의 마법은 `Supervisor.start_link` 함수의 내부에 있습니다. 슈퍼바이저와 그자식 프로세스를 실행하면서, 슈퍼바이저가 자식 프로세스를 관리하기 위해 사용할 전략을 정의할 수 있습니다.

자식 프로세스는 리스트와 `Supervisor.Spec`에 포함된 `worker/3` 함수를 사용해서 정의됩니다. `worker/3` 함수는 모듈, 인자, 옵션을 받습니다. 내부적으로 `worker/3`는 초기화할 때 주어진 인자를 사용해서 `start_link/3`을 호출합니다.

[OTP의 동시성](/ko/lessons/advanced/otp-concurrency)에서 구현한 SimpleQueue를 사용해서 시작해봅시다.

```elixir
import Supervisor.Spec

children = [
  worker(SimpleQueue, [], [name: SimpleQueue])
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

프로세스가 정지하거나 종료되면, 슈퍼바이저는 아무 일도 없었던 것처럼 프로세스를 재기동할 것입니다.

### 전략

현재 슈퍼바이저가 사용 가능한 4개의 재기동 전략이 있습니다.

+ `:one_for_one` - 실패한 자식 프로세스만을 재기동합니다.

+ `:one_for_all` - 실패한 이벤트에 포함되어 있는 모든 자식 프로세스를 재기동합니다.

+ `:rest_for_one` - 실패한 프로세스와 그 프로세스보다 이후에 생성된 모든 프로세스를 재기동합니다.

+ `:simple_one_for_one` - 자식 프로세스가 동적으로 추가된다면 최적입니다. 슈퍼바이저는 자식을 단 하나만 가져야 합니다.

### 중첩

워커 프로세스에 이어서, 슈퍼바이저를 관리(supervise)해 슈퍼바이저 트리를 생성하도록 할 수도 있습니다. `worker/3`을 `supervisor/3`으로 변경하기만 하면 됩니다.

```elixir
import Supervisor.Spec

children = [
  supervisor(ExampleApp.ConnectionSupervisor, [[name: ExampleApp.ConnectionSupervisor]]),
  worker(SimpleQueue, [[], [name: SimpleQueue]])
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

## Task 슈퍼바이저

Task는 전용 슈퍼바이저인 `Task.Supervisor`를 가지고 있습니다. 동적으로 태스크를 생성하도록 설계되어 있으며, 내부적으로 `:simple_one_for_one`을 사용합니다.

### 설정하기

`Task.Supervisor`를 사용하는 것은 다른 슈퍼바이저를 사용하는 것과 별반 다르지 않습니다.

```elixir
import Supervisor.Spec

children = [
  supervisor(Task.Supervisor, [[name: ExampleApp.TaskSupervisor]]),
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

### 관리되는 태스크

슈퍼바이저가 시작된 상태에서 `start_child/2` 함수를 사용해서 관리되는(supervised) 태스크를 생성할 수 있습니다.

```elixir
{:ok, pid} = Task.Supervisor.start_child(ExampleApp.TaskSupervisor, fn -> background_work end)
```

태스크가 도중에 정지한다면 그 즉시 재기동됩니다. 이는 받아야 할 접속이 있거나, 백그라운드 작업을 수행하는 경우에 특히 유용할 것입니다.
