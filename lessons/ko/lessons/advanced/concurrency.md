%{
  version: "1.1.0",
  title: "동시성",
  excerpt: """
  Elixir의 매력적인 부분 중 하나는 동시성(Concurrency) 지원입니다. Erlang VM (BEAM) 덕분에, Elixir에서의 동시성은 여러분이 생각하는 것보다 간단합니다. 동시성 모델은 액터(Actor) 모델에 의존하고 있습니다. 액터는 메시지를 전달하여 다른 프로세스들과 통신하는 독립적인 프로세스입니다.

이번 강의에서는, Elixir에 탑재된 동시성 모듈에 대해 알아보겠습니다. 이어질 챕터에서는 이를 구현하는 OTP 비헤이비어(OTP behavior)를 다루도록 하겠습니다.
  """
}
---

## 프로세스

Erlang VM 위에서 돌아가는 프로세스들은 가벼우며 모든 CPU에 걸쳐서 동작합니다. 네이티브 스레드와 비슷하지만 더 단순하며, Elixir 어플리케이션에서 수 천개의 프로세스가 동시에 실행되는 것이 흔합니다.

새로운 프로세스를 생성하는 가장 쉬운 방법은 `spawn`입니다. `spawn`은 익명 함수나 이름이 있는 함수를 인자로 받습니다. 프로세스를 새로 생성할 때 해당 프로세스가 어플리케이션 내에서 유일한지 식별하기 위해 **프로세스 식별자**, 다시 말해, PID를 반환합니다.

시작하기 전에, 모듈을 생성하고 그 내부에서 실행할 함수를 정의합시다.

```elixir
defmodule Example do
  def add(a, b) do
    IO.puts(a + b)
  end
end

iex> Example.add(2, 3)
5
:ok
```

방금 정의한 함수를 비동기적으로 평가할 때는, `spawn/3`를 사용합니다.

```elixir
iex> spawn(Example, :add, [2, 3])
5
#PID<0.80.0>
```

### 메시지 전달

프로세스끼리 통신할 때 메시지 전달을 이용합니다. 메시지 전달은 주로 `send/2`, `receive`로 이루어 집니다. `send/2`함수는 PID에 메시지를 전달할 수 있게 해줍니다. 메시지를 전달받을 때는 `receive`로 메시지를 매칭합니다. 매칭되는 것이 없다면, 인터럽트되지 않은 채로 실행이 계속됩니다.

```elixir
defmodule Example do
  def listen do
    receive do
      {:ok, "hello"} -> IO.puts("World")
    end

    listen
  end
end

iex> pid = spawn(Example, :listen, [])
#PID<0.108.0>

iex> send pid, {:ok, "hello"}
World
{:ok, "hello"}

iex> send pid, :ok
:ok
```

`listen/0` 함수를 재귀적으로 호출하므로 여러 메시지를 처리할 수 있습니다. 스스로 호출하지 않으면 프로세스는 첫 메시지를 처리한 후에 종료될 것입니다.

### 프로세스 연결

`spawn`을 다룰 때 유념할 점은 프로세스가 비정상적으로 종료(crash)되었는지 여부를 판단하는 것입니다. 이를 위해서는 `spawn_link`를 통해 프로세스를 서로 연결할 수 있습니다. 이렇게 연결된 두 프로세스는 상대방 프로세스로부터 종료 신호를 수신할 수 있게 됩니다.

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)
end

iex> spawn(Example, :explode, [])
#PID<0.66.0>

iex> spawn_link(Example, :explode, [])
** (EXIT from #PID<0.57.0>) evaluator process exited with reason: :kaboom
```

가끔은 연결된 프로세스로 인해 현재의 프로세스가 함께 종료되는 것을 막아야할 때도 있습니다. 이를 위해서는 종료 신호를 인지하여 이를 적절하게 처리해 주어야 하는데 이 때 사용되는 것이 `Process.flag/2`입니다. 이 예시 모듈에서는 얼랭(erlang)의 [process_flag/2](http://erlang.org/doc/man/erlang.html#process_flag-2) 함수를 이용해서 `trap_exit` 플래그를 처리합니다. 종료 신호를 trap할 때(`trap_exit`를 `true`로 설정했을 때), 다음과 같은 튜플 메시지를 수신하게 될 것입니다. `{:EXIT, from_pid, reason}`
- [역주] trap 명령은 시스템에서 비동기적으로 발생하는 신호를 잡아서 필요한 작업을 수행하게 해주는 명령입니다.

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)

  def run do
    Process.flag(:trap_exit, true)
    spawn_link(Example, :explode, [])

    receive do
      {:EXIT, from_pid, reason} -> IO.puts("Exit reason: #{reason}")
    end
  end
end

iex> Example.run
Exit reason: kaboom
:ok
```

### 프로세스 모니터링

두 프로세스를 서로 연결하고 싶지 않지만, 이에 대한 정보를 계속해서 받고자 한다면 어떻게 하면 될까요? 이런 경우에는 `spawn_monitor`로 프로세스를 모니터링할 수 있습니다. 프로세스를 모니터링하면, 구동 중인 프로세스를 충돌시키거나 종료신호를 명시적으로 trap할 필요 없이 프로세스가 충돌 여부를 알려주는 메시지를 얻게 됩니다.

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)

  def run do
    {pid, ref} = spawn_monitor(Example, :explode, [])

    receive do
      {:DOWN, ref, :process, from_pid, reason} -> IO.puts("Exit reason: #{reason}")
    end
  end
end

iex> Example.run
Exit reason: kaboom
:ok
```

## 에이전트

에이전트(Agent)는 상태를 유지하는 백그라운드 프로세스를 추상화한 것입니다. 어플리케이션이나 노드 내부에 있는 다른 프로세스에서 접근할 수 있습니다. 다음의 예시에서, 에이전트의 상태는 함수의 반환 값으로 설정되어 있습니다.

```elixir
iex> {:ok, agent} = Agent.start_link(fn -> [1, 2, 3] end)
{:ok, #PID<0.65.0>}

iex> Agent.update(agent, fn (state) -> state ++ [4, 5] end)
:ok

iex> Agent.get(agent, &(&1))
[1, 2, 3, 4, 5]
```

에이전트에 이름을 부여하면, PID 대신 이름으로 참조할 수 있습니다.

```elixir
iex> Agent.start_link(fn -> [1, 2, 3] end, name: Numbers)
{:ok, #PID<0.74.0>}

iex> Agent.get(Numbers, &(&1))
[1, 2, 3]
```

## 태스크

태스크(task)는 백그라운드에서 함수를 실행하여, 그 반환 값을 나중에 찾을 수 있게 해줍니다. 특히, 어플리케이션 실행 중 블로킹하지 않고 비싼 연산을 처리할 때 유용합니다.

```elixir
defmodule Example do
  def double(x) do
    :timer.sleep(2000)
    x * 2
  end
end

iex> task = Task.async(Example, :double, [2000])
%Task{pid: #PID<0.111.0>, ref: #Reference<0.0.8.200>}

# 다른 작업을 수행합니다

iex> Task.await(task)
4000
```
