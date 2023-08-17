%{
  version: "1.1.1",
  title: "OTP Distribution",
  excerpt: """
  하나 혹은 여러 호스트에 분산되어있는 서로 다른 노드들의 집합에서 Elixir 앱을 실행시킬 수 있습니다.
  Elixir에서는 이 단원에서 설명할 몇 가지의 매커니즘을 통해 이러한 노드들 간의 통신을 할 수 있습니다.
  """
}
---

## 노드 간 통신

Elixir는 Erlang VM에서 실행됩니다. 즉 Erlang의 강력한 [분산 기능](http://erlang.org/doc/reference_manual/distributed.html)에 접근이 가능하다는 뜻이죠.

> 하나의 분산 Erlang 시스템은 서로 간에 통신하는 다수의 Erlang 런타임 시스템들로 구성됩니다.
각 런타임 시스템을 노드라고 부릅니다.

이름이 지정된(명명된) Erlang 런타임 시스템이 곧 노드입니다.
`iex` 세션을 열고 다음과 같이 이름을 지정하는 식으로 노드를 시작해볼 수 있습니다.

```bash
iex --sname alex@localhost
iex(alex@localhost)>
```

다른 터미널 창에서 다른 노드를 열어봅시다.

```bash
iex --sname kate@localhost
iex(kate@localhost)>
```

이 두 노드들은 서로에게 `Node.spawn_link/2` 를 사용해 메시지를 전송할 수 있습니다.

### Node.spawn_link/2 를 사용한 통신

이 함수는 다음 2개의 인자를 받습니다.

* 연결하고자 하는 노드의 이름
* 연결한 노드에서 돌아가는 원격 프로세스에 의해 실행될 함수

함수는 원격 노드에 커넥션을 만들고 주어진 함수를 해당 노드에서 실행하면서 연결된 프로세스의 PID를 반환합니다.

Kate라는 사람을 소개하는 법을 알고 있는 `Kate` 모듈을 `kate` 노드에 정의해 보겠습니다.

```elixir
iex(kate@localhost)> defmodule Kate do
...(kate@localhost)>   def say_name do
...(kate@localhost)>     IO.puts "Hi, my name is Kate"
...(kate@localhost)>   end
...(kate@localhost)> end
```

#### 메시지 전송

이제 우리는 [`Node.spawn_link/2`](https://hexdocs.pm/elixir/Node.html#spawn_link/2) 를 사용해 `alex` 노드를 시켜서 `kate` 노드에게 `say_name/0` 함수를 실행하도록 해볼 수 있습니다.

```elixir
iex(alex@localhost)> Node.spawn_link(:kate@localhost, fn -> Kate.say_name end)
Hi, my name is Kate
#PID<10507.132.0>
```

#### I/O 와 Nodes에 대한 참고사항

유의할 점은, `Kate.say_name/0` 이 원격 노드에서 실행되었더라도, 로컬(호출한) 노드가 `IO.puts`의 출력 결과를 받았다는 것입니다.
그 이유는 로컬 노드가 **그룹 리더**이기 때문입니다.
Erlang VM은 프로세스들을 통해 I/O를 관리합니다.
그 덕분에 `IO.puts` 같은 I/O 작업을 분산 노드 간에 실행할 수 있습니다.
이러한 분산 프로세스들은 I/O 프로세스 그룹 리더에 의해 관리됩니다.
그룹 리더는 항상 해당 프로세스를 스폰한 노드입니다.
따라서 위에서 `alex` 노드가 `spawn_link/2` 함수를 호출한 노드이기 때문에 해당 노드가 그룹 리더이고, `IO.puts`의 출력 결과가 해당 노드의 표준 출력 스트림에 바로 나타나게 되는 것입니다.

#### 메시지에 응답하기

메시지를 받은 수신자 노드가 어떤 *응답*을 발신자 노드에게 다시 보내도록 하려면 어떻게 해야 할까요? 간단한 `receive/1`과 [`send/3`](https://hexdocs.pm/elixir/Process.html#send/3) 구성을 통해 정확히 그것을 해낼 수 있습니다.

`alex` 노드가 `kate`노드에 링크를 스폰하고 `kate`노드에서 익명 함수를 실행하도록 할 것입니다.
그 익명함수는 메시지 하나와 `alex` 노드의 PID를 기술한 특정 튜플을 메시지로 받기 위해 수신 대기하고 있을 것입니다.
그리고 메시지를 받으면 `send`로 `alex` 노드의 PID에 응답 메시지를 보낼 것입니다.

```elixir
iex(alex@localhost)> pid = Node.spawn_link :kate@localhost, fn ->
...(alex@localhost)>   receive do
...(alex@localhost)>     {:hi, alex_node_pid} -> send alex_node_pid, :sup?
...(alex@localhost)>   end
...(alex@localhost)> end
#PID<10467.112.0>
iex(alex@localhost)> pid
#PID<10467.112.0>
iex(alex@localhost)> send(pid, {:hi, self()})
{:hi, #PID<0.106.0>}
iex(alex@localhost)> flush()
:sup?
:ok
```

#### 서로 다른 네트워크에 위치한 노드들 간의 통신에 대한 참고사항

서로 다른 네트워크에 위치한 노드 간에 메시지를 전송하려면, 공통의 쿠키를 가지고 이름 지정 노드들을 시작해야 합니다.

```bash
iex --sname alex@localhost --cookie secret_token
```

```bash
iex --sname kate@localhost --cookie secret_token
```

같은 `cookie`를 가지고 시작된 노드들만 서로 간에 성공적으로 연결될 수 있습니다.

#### Node.spawn_link/2 한계점

`Node.spawn_link/2`는 노드 간의 관계와 노드 간에 메시지를 보낼 수 있는 방법을 잘 보여주지만 분산된 노드에서 실행되는 애플리케이션에 대해서는 사실 올바른 선택이 아닙니다.
`Node.spawn_link/2`는 고립된 프로세스, 즉 감독되지 않는 프로세스를 생성합니다.
감독되는 비동기 프로세스를 노드 간에 생성할 방법만 있었다면...

## 분산 태스크

[분산된 태스크](https://hexdocs.pm/elixir/Task.html#module-distributed-tasks)는 노드 간에도 감독되는 태스크들을 생성할 수 있게 해줍니다.
우리는 분산된 태스크를 이용해 사용자가 분산 노드들 간에 `iex` 세션을 통해 서로 채팅을 할 수 있도록 하는 간단한 슈퍼바이저 애플리케이션을 만들어볼 것입니다.

### 슈퍼바이저 애플리케이션 정의

다음과 같이 앱을 생성합시다.

```shell
mix new chat --sup
```

### 슈퍼바이저 트리에 Task 슈퍼바이저 추가하기

Task 슈퍼바이저는 task들을 동적으로 관리합니다.
주로 그 자신의 슈퍼바이저 *밑에서* 자식은 없이 시작되고, 이후에 여러 task들을 관리하는 데 사용될 수 있습니다.

우리의 app 슈퍼비전 트리에 `Chat.TaskSupervisor`라는 이름으로 Task 슈퍼바이저를 하나 추가해 봅시다.

```elixir
# lib/chat/application.ex
defmodule Chat.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Chat.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: Chat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

이제 우리의 애플리케이션이 주어진 노드에서 시작될 때마다 `Chat.Supervisor`가 실행되고 task들을 관리할 것이라는 것을 압니다.

### 관리되는 Task를 통해 메시지 전송하기

관리되는 태스크를 [`Task.Supervisor.async/5`](https://hexdocs.pm/elixir/Task.Supervisor.html#async/5) 함수를 이용해 시작해 봅시다.

이 함수는 다음 4개의 인자를 받아야 합니다.

* 해당 태스크를 관리할 슈퍼바이저
원격 노드의 태스크를 관리하길 원한다면 `{SupervisorName, remote_node_name}` 같은 튜플 형태로 넘겨질 수도 있습니다.
* 실행할 함수가 위치한 모듈의 이름
* 실행시키고자 하는 함수 이름
* 해당 함수에 넘겨질 인자들

5번째 선택적 인자로 종료 옵션을 나타내는 값을 줄 수 있습니다.
여기서 고려할 사항은 아닙니다.

우리의 Chat 애플리케이션은 단순합니다.
그것은 원격 노드에 메시지를 보내고 원격 노드는 `IO.puts` 를 통해 원격 노드의 STDOUT에 응답합니다.

먼저 원격 노드에서 우리의 태스크가 실행할 `Chat.receive_message/1` 함수를 정의해 봅시다.  

```elixir
# lib/chat.ex
defmodule Chat do
  def receive_message(message) do
    IO.puts message
  end
end
```

다음은, `Chat` 모듈에게 관리되는 태스크를 이용해 원격 노드에 메시지를 보내는 법을 가르쳐 보죠.
이 프로세스를 수행할 `Chat.send_message/` 메소드를 정의합니다.

```elixir
# lib/chat.ex
defmodule Chat do
  ...

  def send_message(recipient, message) do
    spawn_task(__MODULE__, :receive_message, recipient, [message])
  end

  def spawn_task(module, fun, recipient, args) do
    recipient
    |> remote_supervisor()
    |> Task.Supervisor.async(module, fun, args)
    |> Task.await()
  end

  defp remote_supervisor(recipient) do
    {Chat.TaskSupervisor, recipient}
  end
end
```

한번 실행시켜 봅시다.

한 터미널 창에서, 명명된 `iex` 세션에 우리의 chat 앱을 띄웁니다.

```bash
iex --sname alex@localhost -S mix
```

새 터미널 창을 열고 다른 이름의 노드에 앱을 실행합니다.

```bash
iex --sname kate@localhost -S mix
```

이제, `alex` 노드에서 `kate` 노드로 메시지를 보내볼 수 있습니다.

```elixir
iex(alex@localhost)> Chat.send_message(:kate@localhost, "hi")
:ok
```

`kate` 창으로 옮기면 다음 메시지를 볼 수 있을 겁니다.

```elixir
iex(kate@localhost)> hi
```

`kate` 노드가 `alex` 노드에게 응답도 할수 있습니다.

```elixir
iex(kate@localhost)> hi
Chat.send_message(:alex@localhost, "how are you?")
:ok
iex(kate@localhost)>
```

그리고 그것은 `alex` 노드의 `iex` 세션에서 보여지겠지요.

```elixir
iex(alex@localhost)> how are you?
```

코드를 다시 자세히 살펴보며 어떤 일이 있었던건지 분석해 보겠습니다.

우리의 관리되는 태스크를 실행할 원격 노드의 이름과 원격 노드에 보낼 메시지를 인자로 받는 함수 `Chat.send_message/2`가 있습니다.

그 함수는 주어진 이름으로 비동기 태스크를 원격 노드에서 실행시킬 `spawn_task/4` 함수를 호출하는데, 해당 태스크는 원격 노드의 `Chat.TaskSupervisor`에 의해서 관리되게 됩니다.
여기서 `Chat.TaskSupervisor` 이름의 태스크 슈퍼바이저가 원격 노드에서 실행되고 있다는 것을 아는 이유는 그 노드 *또한* 우리의 Chat 애플리케이션의 인스턴스를 실행하고 있고 `Chat.TaskSupervisor`가 Chat 앱의 슈퍼비전 트리의 일부로 시작되었기 때문입니다.

우리는 `Chat.TaskSupervisor`에게 `Chat.receive_message` 함수를 `send_message/2`에서부터 `spawn_task/4`로 전달된 메시지를 한 인자로 받아 실행시킬 태스크를 관리하도록 지시하고 있습니다.

결국 `Chat.receive_message("hi")` 가 원격 노드인 `kate` 에서 호출되고, 해당 노드의 STDOUT 스트림에 `"hi"`라는 메시지를 출력시키게 됩니다.
이 경우에 태스크는 원격 노드에서 관리되기 때문에 해당 노드가 이 I/O 프로세스의 그룹 관리자가 됩니다.

### 원격 노드에서 메시지 응답하기

Chat 앱을 좀더 똑똑하게 만들어 보겠습니다.
지금까지는 사용자 수에 상관없이 명명된 `iex` 세션에서 애플리케이션을 실행하고 채팅을 시작할 수 있었습니다.
하지만 거기에 소외되고 싶지 않은 Moebi라는 이름의 중형견이 있다고 해봅시다.
Moebi는 Chat 앱에 끼고 싶지만 그는 개라서 슬프게도 타이핑 치는 법을 모릅니다.
따라서 Moebi를 대신해 `moebi@localhost`로 명명된 노드로 전송된 모든 메시지에 응답하도록 `Chat` 모듈을 가르칠 것입니다.
Moebi에게 뭐라고 말하던 그는 `"chicken?"` 이라고 대답할 것입니다. 그의 진정한 소망은 치킨을 먹는 것이기 때문이죠.

이전 `send_message/2` 함수의 또 다른 버전을 정의해 `recipient` 인자에 패턴 매칭하도록 해보겠습니다.
만약 수신자(recipient)가 `:moebi@localhost` 라면, 다음을 수행합니다.

* `Node.self()`를 이용해 현재 노드의 이름을 얻습니다.
* 현재 노드 이름, 즉 발신자의 이름을 새 함수 `receive_message_for_moebi/2`에 전달합니다. 그러면 해당 노드에 응답 메시지를 보낼 수 있습니다.

```elixir
# lib/chat.ex
...
def send_message(:moebi@localhost, message) do
  spawn_task(__MODULE__, :receive_message_for_moebi, :moebi@localhost, [message, Node.self()])
end
```

다음으로 `moebi` 노드의 STDOUT 스트림에 `IO.puts`로 메시지를 출력하고 발신자에게 응답 메시지를 보내는 `receive_message_for_moebi/2` 함수를 정의합니다.

```elixir
# lib/chat.ex
...
def receive_message_for_moebi(message, from) do
  IO.puts message
  send_message(from, "chicken?")
end
```

이것은 즉 원래의 메시지를 보낸 (발신자)노드 이름으로 `send_message/2` 함수를 호출함으로써, 원격 노드에게 다시 관리되는 태스크를 해당 발신자 노드에 생성하라고 지시하는 것입니다.

실행 시켜 보겠습니다.
3개의 터미널 창에서 각각 다른 이름으로 노드를 엽니다.

```bash
iex --sname alex@localhost -S mix
```

```bash
iex --sname kate@localhost -S mix
```

```bash
iex --sname moebi@localhost -S mix
```

`alex`가 `moebi`에게 메시지를 보내도록 해보겠습니다.

```elixir
iex(alex@localhost)> Chat.send_message(:moebi@localhost, "hi")
chicken?
:ok
```

`alex` 노드가 `"chicken?"` 이라는 응답을 받은 것을 볼 수 있습니다.
`kate` 노드를 연다면, 아무 메시지도 받지 않은 것을 확인할 수 있는데, `alex`나 `moebi` 둘 다 그녀에게는 보내지 않았기 때문입니다. (미안해요 `kate`)
And if we open the `moebi` node's terminal window, we'll see the message that the `alex` node sent:

```elixir
iex(moebi@localhost)> hi
```

## 분산 코드 테스트하기

`send_message` 함수의 간단한 테스트를 작성해 봅시다.

```elixir
# test/chat_test.exs
defmodule ChatTest do
  use ExUnit.Case, async: true
  doctest Chat

  test "send_message" do
    assert Chat.send_message(:moebi@localhost, "hi") == :ok
  end
end
```

`mix test`를 통해 테스트를 실행하면, 다음 에러 메시지와 함께 실패하는 것을 볼 수 있습니다.

```elixir
** (exit) exited in: GenServer.call({Chat.TaskSupervisor, :moebi@localhost}, {:start_task, [#PID<0.158.0>, :monitor, {:sophie@localhost, #PID<0.158.0>}, {Chat, :receive_message_for_moebi, ["hi", :sophie@localhost]}], :temporary, nil}, :infinity)
         ** (EXIT) no connection to moebi@localhost
```

이 에러의 의미는 지극히 타당합니다. 실행되고 있지 않은 `moebi@localhost` 노드에 당연히 연결할 수 없습니다.

다음의 몇 단계를 수행함으로써 이 테스트를 통과시킬 수는 있습니다.

* 새 터미널 창을 열고 다음처럼 명명 노드를 실행합니다: `iex --sname moebi@localhost -S mix`
* 본래의 터미널로 돌아가 테스트를 실행하되 `iex` session에서 명명된 노드를 통해 실행합니다: `iex --sname sophie@localhost -S mix test`

이것은 너무 번잡하며 분명 자동화된 테스트 과정으로 여겨지지도 않을 겁니다.

여기서 우리가 취할 수 있는 다음 2가지 접근법이 있습니다.

1. 분산된 노드를 필요로 하는 테스트들을 해당 필요한 노드가 실행되지 않았으면 제외하도록 조건을 겁니다.
2. 테스트 환경에서 원격 노드에 태스크를 생성하는 것을 피하도록 애플리케이션을 설정합니다

첫 번째 접근법을 한 번 봅시다.

### Tag를 이용해 조건적으로 테스트 제외

테스트에 다음처럼 `ExUnit`의 tag를 추가합니다.

```elixir
# test/chat_test.exs
defmodule ChatTest do
  use ExUnit.Case, async: true
  doctest Chat

  @tag :distributed
  test "send_message" do
    assert Chat.send_message(:moebi@localhost, "hi") == :ok
  end
end
```

그리고 test helper에 만약 테스트가 명명된 노드에서 실행되는 게 *아니*라면 해당 태그들이 붙은 테스트들을 제외하도록 조건문을 추가합니다.

```elixir
# test/test_helper.exs
exclude =
  if Node.alive?, do: [], else: [distributed: true]

ExUnit.start(exclude: exclude)
```

노드가 살아있는지(alive)를 확인합니다.
다시 말해 해당 노드가 분산 시스템의 일부인지를 [`Node.alive?`](https://hexdocs.pm/elixir/Node.html#alive?/0)로 확인합니다.
아니라면, `ExUnit`이 `distributed: true` 태그인 테스트들은 스킵하도록 합니다.
그 반대의 경우엔 테스트를 제외하지 않도록 합니다.

이제 군더더기 없이 `mix test`를 실행하면 다음을 보게 될 겁니다.

```bash
mix test
Excluding tags: [distributed: true]

Finished in 0.02 seconds
1 test, 0 failures, 1 excluded
```

그리고 만약 분산 테스트를 실행하고 싶다면, 그저 이전 섹션에서 설명했던 단계들을 수행하면 됩니다. 즉, `moebi@localhost` 노드를 실행, *그리고* `iex` 통해 명명된 노드에서 테스트 실행.

다른 접근방식도 한번 보겠습니다. 애플리케이션 설정으로 각기 다른 환경에서 다르게 동작하도록 하는 방식입니다.

### 환경별 애플리케이션 설정

`Task.Supervisor`가 관리되는 태스크를 원격 노드에서 실행하도록 하는 코드 부분은 다음과 같습니다.

```elixir
# app/chat.ex
def spawn_task(module, fun, recipient, args) do
  recipient
  |> remote_supervisor()
  |> Task.Supervisor.async(module, fun, args)
  |> Task.await()
end

defp remote_supervisor(recipient) do
  {Chat.TaskSupervisor, recipient}
end
```

`Task.Supervisor.async/5`는 첫 번째 인자로 사용하고자 하는 슈퍼바이저를 받고 있습니다.
만약 우리가 함수에 `{SupervisorName, location}` 튜플을 넘긴다면, 슈퍼바이저를 주어진 원격 노드에서 실행할 것입니다.
하지만 `Task.Supervisor`에 슈퍼바이저 이름만 첫 번째 인자로 전달하면, 그 슈퍼바이저가 태스크를 로컬에서만 관리하게 될 것입니다.

`remote_supervisor/1` 함수를 환경별로 설정할 수 있도록 만들어 봅시다.
개발 환경에서는 `{Chat.TaskSupervisor, recipient}`를 반환하고 테스트 환경에서는 `Chat.TaskSupervisor`를 반환할 것입니다.

애플리케이션 변수를 통해 이것을 설정합니다.

`config/dev.exs` 파일을 만들고 다음을 추가합니다.

```elixir
# config/dev.exs
import Config
config :chat, remote_supervisor: fn(recipient) -> {Chat.TaskSupervisor, recipient} end
```

`config/test.exs` 파일을 만들어 다음을 추가합니다.

```elixir
# config/test.exs
import Config
config :chat, remote_supervisor: fn(_recipient) -> Chat.TaskSupervisor end
```

`config/config.exs` 에서는 다음 부분은 주석 해제해야 합니다.

```elixir
import Config
import_config "#{config_env()}.exs"
```

마지막으로 `Chat.remote_supervisor/1` 함수를 우리의 새로운 애플리케이션 변수에 저장된 함수를 찾아서 사용하도록 변경합니다.

```elixir
# lib/chat.ex
defp remote_supervisor(recipient) do
  Application.get_env(:chat, :remote_supervisor).(recipient)
end
```

## 결론

Erlang VM의 힘 덕분에 가능한 Elixir의 기본 분산 기능은 Elixir를 강력한 도구로 만들어주는 특징 중 하나입니다.
분산 컴퓨팅을 처리하는 Elixir의 능력을 활용해 동시적으로 백그라운드 잡을 실행하거나, 고성능 애플리케이션을 지원하거나, 고비용의 명령을 실행하는 것을 상상해보세요.

이 단원에서 Elixir의 분산처리 개념에 대한 기초적 소개와 분산된 애플리케이션 구축을 시작하기 위해 필요한 도구에 대해 배웠습니다.
관리되는 태스크를 이용해 분산된 애플리케이션의 여러 노드 간에 메시지를 전송할 수 있습니다.
