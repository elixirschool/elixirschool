---
layout: page
title: OTP 동시성
category: advanced
order: 5
lang: ko
---

지난 강의에서는 Elixir의 동시성에 대해 살펴보았습니다. 그러나, 여기서 더 정밀한 조작이 필요할 때도 있는데, 이런 경우에는 Elixir에 내장된 OTP 비헤이비어가 있습니다.

이번 강의에서는 두 가지 중요한 부분인 GenServers와 GenEvents에 대해서 다루겠습니다.

{% include toc.html %}

## GenServer

OTP 서버는 여러가지 콜백들을 구현하는 GenServer 비헤이비어가 포함된 모듈입니다. GenServer는 기본적으로 매 반복마다 상태를 갱신하면서 한 요청을 처리하는 반복문으로 구성됩니다.

GenServer API를 나타내기 위해, 값을 저장하고 빼낼 수 있는 기초적인 큐(queue)를 구현해보겠습니다.

GenServer를 시작하기 위해, 초기화 부분을 건드려야 합니다. 대부분의 경우, `GenServer.start_link/3`로 프로세스들을 연결하고 싶을 것입니다. 방금 언급한 함수를 이용하고자 할 때, 사용중인 모듈(GenServer), 초기화시키기 위한 인자, 그리고 GenServer의 여러가지 옵션들을 넘기게 되죠. 인자들은 반환되는 값을 통해 초기 상태를 결정하는 `GenServer.init/1`로 넘겨지게 될 것입니다. 넘겨지는 인자가 초기 상태가 되는 다음의 예제를 보겠습니다:


```elixir
defmodule SimpleQueue do
  use GenServer

  @doc """
  큐로 프로세스를 연결하세요. 이것은 헬퍼 메서드 입니다.
  """
  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @doc """
  GenServer.init/1 callback
  """
  def init(state), do: {:ok, state}
end
```


### 동기 함수

함수를 호출하여 응답을 기다리면서 GenServer와 동기적으로 데이터를 주고 받는 것이 정말 중요합니다. 동기 요청을 다루기 위해, `GenServer.handle_call/3` 콜백을 구현해야 합니다. 이는 요청, 함수를 호출하는 프로세스의 PID, 현재 상태를 인자로 가집니다. `{:reply, response, state}` 같은 튜플을 응답으로 반환하길 기대합니다.

패턴매칭을 이용하여, 다양한 요청과 상태에 따라 콜백을 정의할 수 있습니다. [`GenServer.handle_call/3`](http://elixir-lang.org/docs/v1.1/elixir/GenServer.html#c:handle_call/3) 문서에서 허용되는 반환 값의 전체적인 리스트를 확인할 수 있습니다.

현재 큐의 상태를 보여주는 코드와 값을 제거하는 코드를 포함시켜, 동기 응답이 어떻게 동작하는지 보죠:


```elixir
defmodule SimpleQueue do
  use GenServer
  
  ### GenServer API

  @doc """
  GenServer.init/1 callback
  """
  def init(state), do: {:ok, state}

  @doc """
  GenServer.handle_call/3 callback
  """
  def handle_call(:dequeue, _from, [value|state]) do
    {:reply, value, state}
  end
  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  ### Client API / Helper methods

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```


이제 SimpleQueue를 가지고 dequeue 기능을 테스트해봅시다.


```elixir
iex> SimpleQueue.start_link([1, 2, 3])
{:ok, #PID<0.90.0>}
iex> SimpleQueue.dequeue
1
iex> SimpleQueue.dequeue
2
iex> SimpleQueue.queue
[3]
```

### 비동기 함수

비동기적인 요청은 `handle_cast/2` 콜백으로 다룰 수 있습니다. `handle_call/3`처럼 작동하지만, 함수를 호출하는 프로세스를 인자로 받지 않으며, 응답도 보내지 않습니다.

enqueue 기능을 비동기적으로 구현하여, 실행 중인 프로세스를 블록하지 않고 큐를 갱신해보겠습니다:

```elixir
defmodule SimpleQueue do
  use GenServer

  ### GenServer API

  @doc """
  GenServer.init/1 callback
  """
  def init(state), do: {:ok, state}

  @doc """
  GenServer.handle_call/3 callback
  """
  def handle_call(:dequeue, _from, [value|state]) do
    {:reply, value, state}
  end
  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  @doc """
  GenServer.handle_cast/2 callback
  """
  def handle_cast({:enqueue, value}, state) do
    {:noreply, state ++ [value]}
  end

  ### Client API / Helper methods

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end
  def queue, do: GenServer.call(__MODULE__, :queue)
  def enqueue(value), do: GenServer.cast(__MODULE__, {:enqueue, value})
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```

새로 만든 기능을 사용해보도록 하죠:

```elixir
iex> SimpleQueue.start_link([1, 2, 3])
{:ok, #PID<0.100.0>}
iex> SimpleQueue.queue
[1, 2, 3]
iex> SimpleQueue.enqueue(20)
:ok
iex> SimpleQueue.queue
[1, 2, 3, 20]
```

자세한 내용은 [GenServer](http://elixir-lang.org/docs/v1.1/elixir/GenServer.html#content) 공식 문서에서 확인해보세요.

## GenEvent

GenServer가 상태를 유지하고 요청들을 동기/비동기적으로 처리하는 프로세스라는 것을 앞서 배웠습니다. 그렇다면, GenEvent는 뭘까요? GenEvent는 들어오는 이벤트를 수신하고 데이터를 전달받는 소비자에 알림을 주는 범용 이벤트 매니저입니다. 핸들러를 이용하여 이벤트의 흐름을 동적으로 제어할 수 있습니다

### 이벤트 처리하기

여러분도 짐작 가시듯이, GenEvents에서 가장 중요한 콜백은 `handle_event/2`입니다. 이벤트와 핸들러의 현재 상태를 수신하고, `{:ok, state}`와 같은 튜플을 반환합니다.

GenEvent의 기능을 보이기 위해 두 개의 핸들러를 만들어 봅시다. 하나는 메시지를 계속해서 로깅하도록 하고, 다른 하나는 로깅을 (이론적으로)유지시키는 겁니다:

```elixir
defmodule LoggerHandler do
  use GenEvent

  def handle_event({:msg, msg}, messages) do
    IO.puts "Logging new message: #{msg}"
    {:ok, [msg|messages]}
  end
end

defmodule PersistenceHandler do
  use GenEvent

  def handle_event({:msg, msg}, state) do
    IO.puts "Persisting log message: #{msg}"

    # 메시지를 저장합니다

    {:ok, state}
  end
end
```

### 핸들러 호출하기

GenEvents는 `handle_event/2` 뿐만 아니라 `handle_call/2`도 지원합니다. `handle_call/2`가 있다면, 동기적으로 오가는 특정 메시지들을 핸들러로 다룰 수 있습니다.

현재 메시지 로그를 가져오는 메소드를 포함하도록 `LoggerHandler`를 수정해봅시다:

```elixir
defmodule LoggerHandler do
  use GenEvent

  def handle_event({:msg, msg}, messages) do
    IO.puts "Logging new message: #{msg}"
    {:ok, [msg|messages]}
  end

  def handle_call(:messages, messages) do
    {:ok, Enum.reverse(messages), messages}
  end
end
```

### GenEvent 사용하기

핸들러가 준비되어 있다면, 몇 가지 GenEvent 함수에 익숙해져야 할 필요가 있습니다. 가장 중요한 함수는 세 가지입니다: `add_handler/3`, `notify/2`, 그리고 `call/4`이죠. 각각 핸들러를 추가할 수 있고, 새로운 메시지를 브로드캐스트할 수 있고, 특정 핸들러의 함수를 호출할 수 있습니다.

모두 적용해보면, 다음과 같이 핸들러들이 작동되는 것을 볼 수 있습니다:

```elixir
iex> {:ok, pid} = GenEvent.start_link([])
iex> GenEvent.add_handler(pid, LoggerHandler, [])
iex> GenEvent.add_handler(pid, PersistenceHandler, [])

iex> GenEvent.notify(pid, {:msg, "Hello World"})
Logging new message: Hello World
Persisting log message: Hello World

iex> GenEvent.call(pid, LoggerHandler, :messages)
["Hello World"]
```

[GenEvent](http://elixir-lang.org/docs/v1.1/elixir/GenEvent.html#content) 공식 문서에서 콜백의 목록과 GenEvent의 기능들을 확인해보세요.
