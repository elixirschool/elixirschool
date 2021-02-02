%{
  version: "1.1.1",
  title: "Параллелизм",
  excerpt: """
  Одна из сильных сторон Elixir &mdash; поддержка параллелизма.
Благодаря Erlang VM (BEAM) параллелизм в Elixir легче, чем вы думали.
В основе модели параллелизма лежат акторы &mdash; процессы, взаимодействующие с другими процессами путём передачи сообщений.

В этом уроке мы познакомимся с модулями параллелизма, поставляемыми вместе с Elixir.
В следующей части мы также узнаем, каким способом они реализованы в OTP.
  """
}
---

## Процессы

Процессы в Erlang VM легковесны и выполняются на всех процессорах.
Они могут показаться похожими на нативные потоки, но они проще, и вполне нормально иметь тысячи параллельных процессов в одном приложении Elixir.

Простейший способ создать новый процесс это функция `spawn`, принимающая анонимную или именованную функцию.
Когда мы создаём новый процесс, он возвращает _Идентификатор процесса_, или PID, для однозначного определения внутри нашего приложения.

Для начала создадим модуль и опишем функцию, которую мы хотели бы запустить:

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

Чтобы выполнить функцию асинхронно, воспользуемся `spawn/3`:

```elixir
iex> spawn(Example, :add, [2, 3])
5
#PID<0.80.0>
```

### Передача сообщений

Для взаимодействия между собой процессы используют сообщения.
Для этого существует две части: `send/2` и `receive`.
Функция `send/2` позволяет отправлять сообщения PID'y.
Для получения и проверки сообщений используется `receive`.
Если при проверке совпадение не будет найдено, выполнение продолжится.

```elixir
defmodule Example do
  def listen do
    receive do
      {:ok, "hello"} -> IO.puts("World")
    end

    listen()
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

Стоит заметить, что функция `listen/0` рекурсивна (вызывает саму себя), что позволяет этому процессу обработать несколько сообщений.
Без этого вызова процесс завершит свою работу после обработки первого сообщения.

### Связывание процессов

Одна из проблем при использовании `spawn` &mdash; узнать о выходе процесса из строя.
Для этого мы свяжем наши процессы с помощью `spawn_link`.
Два связанных процесса будут получать друг от друга уведомления о завершении:

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)
end

iex> spawn(Example, :explode, [])
#PID<0.66.0>

iex> spawn_link(Example, :explode, [])
** (EXIT from #PID<0.57.0>) evaluator process exited with reason: :kaboom
```

Иногда мы не хотим, чтобы связанный процесс завершал текущий.
Для этого нужно перехватывать попытки завершения с помощью функции `Process.flag/2`.
Она использует функцию [process_flag/2](http://erlang.org/doc/man/erlang.html#process_flag-2) Erlang с флагом `trap_exit`. Если перехват включён (`trap_exit` равно `true`), перехваченные попытки будут получены в виде сообщения-кортежа: `{:EXIT, from_pid, reason}`.

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)

  def run do
    Process.flag(:trap_exit, true)
    spawn_link(Example, :explode, [])

    receive do
      {:EXIT, _from_pid, reason} -> IO.puts("Exit reason: #{reason}")
    end
  end
end

iex> Example.run
Exit reason: kaboom
:ok
```

### Мониторинг процессов

Но что делать, если мы не хотим связывать два процесса, но при этом хотим получать информацию? Можно воспользоваться `spawn_monitor` для мониторинга процесса.
При наблюдении за процессом мы получаем сообщения, если процесс выйдет из строя, без завершения текущего процесса и необходимости явно перехватывать попытки завершения.

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)

  def run do
    spawn_monitor(Example, :explode, [])

    receive do
      {:DOWN, _ref, :process, _from_pid, reason} -> IO.puts("Exit reason: #{reason}")
    end
  end
end

iex> Example.run
Exit reason: kaboom
:ok
```

## Агенты

Агенты &mdash; абстракция над фоновыми процессами, сохраняющими состояние.
Мы можем получить доступ к ним из другого процесса нашего приложения.
Состояние агента устанавливается равным возвращаемому значению нашей функции:

```elixir
iex> {:ok, agent} = Agent.start_link(fn -> [1, 2, 3] end)
{:ok, #PID<0.65.0>}

iex> Agent.update(agent, fn (state) -> state ++ [4, 5] end)
:ok

iex> Agent.get(agent, &(&1))
[1, 2, 3, 4, 5]
```

Если мы зададим имя агенту, то сможем обращаться к нему, используя имя, а не PID:

```elixir
iex> Agent.start_link(fn -> [1, 2, 3] end, name: Numbers)
{:ok, #PID<0.74.0>}

iex> Agent.get(Numbers, &(&1))
[1, 2, 3]
```

## Задачи

Задачи предоставляют возможность выполнять функцию в фоновом режиме и получать её значение потом.
Они могут быть особенно полезны при обработке дорогостоящих операций без блокировки выполнения приложения.

```elixir
defmodule Example do
  def double(x) do
    :timer.sleep(2000)
    x * 2
  end
end

iex> task = Task.async(Example, :double, [2000])
%Task{
  owner: #PID<0.105.0>,
  pid: #PID<0.114.0>,
  ref: #Reference<0.2418076177.4129030147.64217>
}

# Делаем что-нибудь

iex> Task.await(task)
4000
```
