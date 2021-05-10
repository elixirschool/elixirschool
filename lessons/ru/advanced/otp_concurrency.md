%{
  version: "1.0.3",
  title: "Параллелизм в OTP",
  excerpt: """
  Мы уже рассматривали абстракции языка Elixir для параллельного выполнения, но иногда нужна более широкая функциональность, и тогда мы обращаемся к поведениям OTP.

В этом уроке мы сосредоточимся на GenServer.
  """
}
---

## GenServer

Сервер OTP &mdash; это модуль с GenServer, который имплементирует набор функций обратного вызова (callback). На простейшем уровне GenServer &mdash; это один процесс, обрабатывающий в цикле по одному запросу за итерацию, сохраняя обновленное состояние.

Для демонстрации API GenServer мы реализуем базовую очередь для хранения и извлечения значений.

Для создания GenServer нужно запустить его и позаботиться об инициализации. В большинстве случаев мы хотим связать процессы, потому используем `GenServer.start_link/3`. Мы передаем туда запускаемый GenServer модуль, начальные аргументы и набор настроек для самого GenServer. Эти настройки будут переданы в `GenServer.init/1`, который и задает начальное состояние с помощью возвращаемого значения. В этом примере аргументы и будут начальным состоянием:

```elixir
defmodule SimpleQueue do
  use GenServer

  @doc """
  Запуск и линковка нашей очереди. Это вспомогательный метод.
  """
  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @doc """
  Функция обратного вызова для GenServer.init/1
  """
  def init(state), do: {:ok, state}
end
```

### Синхронные функции

Часто необходимо взаимодействовать с GenServer в синхронном формате, вызывая функцию и ожидая ее ответа. Для обработки синхронных запросов важно имплементировать метод `GenServer.handle_call/3`, который передает запрос, PID вызывающего процесса и текущее состояние. Ожидается, что будет возвращен кортеж `{:reply, response, state}`.

С помощью сопоставления с образцом можно определять функции обратного вызова для разных запросов и состояний. Полный список допустимых вариантов возврата есть в документации [`GenServer.handle_call/3`](https://hexdocs.pm/elixir/GenServer.html#c:handle_call/3).

Для демонстрации синхронных запросов давайте добавим возможность отображать текущее состояние очереди и удаление значений:

```elixir
defmodule SimpleQueue do
  use GenServer

  ### GenServer API

  @doc """
  Функция обратного вызова для GenServer.init/1
  """
  def init(state), do: {:ok, state}

  @doc """
  Функции обратного вызова для GenServer.handle_call/3
  """
  def handle_call(:dequeue, _from, [value | state]) do
    {:reply, value, state}
  end

  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  ### Клиентский API

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```

Давайте запустим наш SimpleQueue и проверим как работает новая функциональность:

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

### Асинхронные функции

Асинхронные запросы обрабатываются функциями обратного вызова `handle_cast/2`. Это работает приблизительно так же как и `handle_call/3`, но не получает данных об отправителе и такой метод не обязан ничего отвечать.

Мы реализуем функциональность добавления элемента в очередь асинхронно &mdash; обновляя очередь, но не блокируя вызывающий код:

```elixir
defmodule SimpleQueue do
  use GenServer

  ### GenServer API

  @doc """
  Функция обратного вызова для GenServer.init/1
  """
  def init(state), do: {:ok, state}

  @doc """
  Функции обратного вызова для GenServer.handle_call/3
  """
  def handle_call(:dequeue, _from, [value | state]) do
    {:reply, value, state}
  end

  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  @doc """
  Функция обратного вызова для GenServer.handle_cast/2
  """
  def handle_cast({:enqueue, value}, state) do
    {:noreply, state ++ [value]}
  end

  ### Клиентский API

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def enqueue(value), do: GenServer.cast(__MODULE__, {:enqueue, value})
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```

И попробуем эту новую функциональность:

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

Для получения дополнительной информации можно обратиться к официальной документации [GenServer](https://hexdocs.pm/elixir/GenServer.html#content).
