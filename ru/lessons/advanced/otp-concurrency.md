---
layout: page
title: Параллелизм в OTP
category: advanced
order: 5
lang: ru
---

Мы уже рассматривали абстракции языка Elixir для параллельного выполнения, но иногда нужна более широкая функциональность и тогда мы обращаемся к поведениям OTP в языке.

В этом уроке мы сосредоточимся на двух важных частях: GenServer и GenEvent.

{% include toc.html %}

## GenServer

Сервер OTP &mdash; это модуль с GenServer, который имплементирует набор функций обратного вызова (callback). На простейшем уровне GenServer &mdash; это цикл, который обрабатывает один запрос за итерацию, сохраняя обновленное состояние.

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

С помощью сопоставления с образцом можно определять функции обратного вызова для разных запросов и состояний. Полный список допустимых вариантов возврата есть в документации [`GenServer.handle_call/3`](http://elixir-lang.org/docs/v1.1/elixir/GenServer.html#c:handle_call/3).

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
  def handle_call(:dequeue, _from, [value|state]) do
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
  def handle_call(:dequeue, _from, [value|state]) do
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

Для получения дополнительной информации можно обратиться к официальной документации [GenServer](http://elixir-lang.org/docs/v1.1/elixir/GenServer.html#content).

## GenEvent

Мы уже изучили, что GenServer - это процессы, которые могут поддерживать состояние и обрабатывать синхронные и асинхронные запросы. Что же такое GenEvent? GenEvent &mdash; это обобщённые менеджеры событий, которые получают входящие сообщения и сообщают о них подписчикам. Они предоставляют механизм динамического добавления и удаления обработчиков к потоку событий.

### Обработка событий

Самым важным обработчиком обратного вызова в GenEvent является `handle_event/2`. Он получает событие и текущее состояние обработчика. Предполагается, что он вернет кортеж `{:ok, state}`.

Для демонстрации функциональности GenEvent давайте начнем с создания двух обработчиков: одного для хранения истории сообщений и второго для их сохранения (теоретически):

```elixir
defmodule LoggerHandler do
  use GenEvent

  def handle_event({:msg, msg}, messages) do
    IO.puts "Вывожу новое сообщение: #{msg}"
    {:ok, [msg|messages]}
  end
end

defmodule PersistenceHandler do
  use GenEvent

  def handle_event({:msg, msg}, state) do
    IO.puts "Сохраняю сообщение: #{msg}"

    # Сохранение сообщения

    {:ok, state}
  end
end
```

### Вызов обработчиков

Вдобавок к `handle_event/2`, GenEvent кроме всего прочего поддерживает и `handle_call/2`. С помощью `handle_call/2` можно обработать особые синхронные сообщения.

Давайте добавим к `LoggerHandler` метод для получения текущей истории сообщений:

```elixir
defmodule LoggerHandler do
  use GenEvent

  def handle_event({:msg, msg}, messages) do
    IO.puts "Вывожу новое сообщение: #{msg}"
    {:ok, [msg|messages]}
  end

  def handle_call(:messages, messages) do
    {:ok, Enum.reverse(messages), messages}
  end
end
```

### Использование GenEvent

С уже готовыми обработчиками нужно разобраться как использовать остальные функции GenEvent. Тремя основными функциями являются `add_handler/3`, `notify/2`, и `call/4`. Они соответственно позволяют: добавлять обработчики, рассылать новые сообщения и вызывать особые функции-обработчики.

Если использовать их вместе, то можно увидеть наши обработчики в действии:

```elixir
iex> {:ok, pid} = GenEvent.start_link([])
iex> GenEvent.add_handler(pid, LoggerHandler, [])
iex> GenEvent.add_handler(pid, PersistenceHandler, [])

iex> GenEvent.notify(pid, {:msg, "Hello World"})
Вывожу новое сообщение: Hello World
Сохраняю сообщение: Hello World

iex> GenEvent.call(pid, LoggerHandler, :messages)
["Hello World"]
```

В официальной документации по [GenEvent](http://elixir-lang.org/docs/v1.1/elixir/GenEvent.html#content) есть полный список функций обратного вызова и функциональности GenEvent.
