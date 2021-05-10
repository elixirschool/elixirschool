---
version: 1.0.2
title: OTP 동시성
---

지난 강의에서는 Elixir의 동시성에 대해 살펴보았습니다만, 더 정밀한 조작이 필요한 경우가 있습니다. 그럴 때에는 Elixir의 바탕이 된 OTP 비헤이비어를 사용할 수 있습니다.

이번 강의에서는 가장 큰 부분인 GenServer에 대해서 다루겠습니다.

{% include toc.html %}

## GenServer

OTP 서버는 여러 콜백을 구현한 GenServer 비헤이비어가 포함된 모듈입니다. GenServer는 기본적으로 각 반복마다 한 요청을 처리해 갱신된 상태를 넘기는 반복문으로 구성됩니다.

GenServer API를 나타내기 위해, 값을 저장하고 빼낼 수 있는 기초적인 큐(queue)를 구현해보겠습니다.

GenServer를 시작하기 위해, 기동 하고 초기화 처리를 해야 합니다. 대부분의 경우, 프로세스를 연결해야 하므로 `GenServer.start_link/3`를 사용할 수 있습니다. 방금 언급한 함수를 이용할 때, 시작할 GenServer 모듈, 초기 인자, 그리고 GenServer 옵션들을 넘깁니다. 반환되는 값을 통해 초기 상태를 결정하는 `GenServer.init/1`로 인자들이 넘겨지게 될 것입니다. 넘겨지는 인자가 초기 상태가 되는 다음의 예제를 보겠습니다.

```elixir
defmodule SimpleQueue do
  use GenServer

  @doc """
  큐로 프로세스를 연결하세요. 이것은 헬퍼 함수 입니다.
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

GenServer와 동기적(함수를 호출하여 응답을 기다림)으로 데이터를 주고 받아야 할 때가 종종 있습니다. 동기 요청을 다루기 위해, `GenServer.handle_call/3` 콜백을 구현해야 합니다. 이는 요청, 함수를 호출하는 프로세스의 PID, 현재 상태를 인자로 가집니다. `{:reply, response, state}` 같은 튜플을 응답으로 반환하길 기대합니다.

패턴매칭을 이용하여, 다양한 요청과 상태에 따라 콜백을 정의할 수 있습니다. [`GenServer.handle_call/3`](https://hexdocs.pm/elixir/GenServer.html#c:handle_call/3) 문서에서 허용되는 반환 값의 전체 목록을 확인할 수 있습니다.

현재 큐의 상태를 보여주는 기능과 값을 제거하는 기능을 추가해, 동기 응답이 어떻게 동작하는지 보죠.

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
  def handle_call(:dequeue, _from, [value | state]) do
    {:reply, value, state}
  end

  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  ### Client API / Helper functions

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```

이제 SimpleQueue를 시작해 새로만든 dequeue 기능을 테스트해봅시다.

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

enqueue 기능을 비동기적으로 구현하여, 실행 중인 프로세스를 블록하지 않고 큐를 갱신해보겠습니다.

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
  def handle_call(:dequeue, _from, [value | state]) do
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

  ### Client API / Helper functions

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def enqueue(value), do: GenServer.cast(__MODULE__, {:enqueue, value})
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```

새로 만든 기능을 사용해보도록 하죠.

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

자세한 내용은 [GenServer](https://hexdocs.pm/elixir/GenServer.html#content) 공식 문서에서 확인해보세요.
