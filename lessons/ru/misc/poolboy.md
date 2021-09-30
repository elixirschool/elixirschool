%{
  version: "1.2.0",
  title: "Poolboy",
  excerpt: """
  You can easily exhaust your system resources if you do not limit the maximum number of concurrent processes that your program can spawn.
  [Poolboy](https://github.com/devinus/poolboy) is a widely used lightweight, generic pooling library for Erlang that addresses this issue.
  """
}
---

## Зачем использовать Poolboy?

Возьмём конкретный пример.
Вам надо создать приложение для сохранения профилей пользователей в базу данных.
Если бы вы создавали по процессу на регистрацию каждого пользователя, вы бы генерировали неограниченное количество соединений.
В определённый момент эти соединения начали бы соперничать за ограниченные ресурсы сервера базы данных.
В итоге в приложении стали бы возникать таймауты и различные ошибки из-за перегрузки, появившейся вследствие такой конкуренции.

Решение такой проблемы — использовать пул процессов-обработчиков для ограничения количества одновременных соединений вместо создания процессов для регистрации каждого пользователя.
Так можно с лёгкостью избежать истощения системных ресурсов.

Для этого и нужен Poolboy.
It allows you to easily set up a pool of workers managed by a `Supervisor` without much effort on your part.
There are many libraries which use Poolboy under the covers.
For example,`redis_poolex` *(Redis connection pool)* is a popular library which uses Poolboy.

## Установка

Благодаря mix установка очень проста.
Нужно всего лишь добавить Poolboy в список зависимостей в `mix.exs`.

Для начала создадим приложение:

```shell
$ mix new poolboy_app --sup
```

Добавим Poolboy в список зависимостей `mix.exs`.

```elixir
defp deps do
  [{:poolboy, "~> 1.5.1"}]
end
```

Затем загрузим зависимости, включая Poolboy.
```shell
$ mix deps.get
```

## Настройка

Перед тем как начать пользоваться Poolboy, надо ознакомиться с возможностями его настройки:

* `:name` — наименование пула.
Область видимости может быть `:local`, `:global` или `:via`.
* `:worker_module` — модуль, представляющий рабочий процесс.
* `:size` — максимальный размер пула.
* `:max_overflow` — максимальное количество процессов-обработчиков, создаваемых, если в пуле закончились свободные процессы.
(необязательно)
* `:strategy` — `:lifo` или `:fifo`, определяет, в начало или в конец списка доступных процессов-обработчиков должен быть помещён создаваемый процесс.
По умолчанию `:lifo`.
(необязательно)

## Настройка Poolboy

Для примера создадим пул процессов-обработчиков, ответственных за обработку запросов на расчёт квадратного корня числа.
Пример намеренно выбран попроще, чтобы мы могли сфокусироваться на Poolboy.

Опишем модуль настройки Poolboy и добавим его как дочерний рабочий процесс при запуске нашего приложения.
Отредактируем `lib/poolboy_app/application.ex`:

```elixir
defmodule PoolboyApp.Application do
  @moduledoc false

  use Application

  defp poolboy_config do
    [
      name: {:local, :worker},
      worker_module: PoolboyApp.Worker,
      size: 5,
      max_overflow: 2
    ]
  end

  def start(_type, _args) do
    children = [
      :poolboy.child_spec(:worker, poolboy_config())
    ]

    opts = [strategy: :one_for_one, name: PoolboyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Первое, что мы сделали — объявили настройки для пула. Присвоили уникальное имя `:name`, установили локальную область видимости (`:scope`) и ограничили размер пула (`:size`) пятью процессами. Также в опции `:max_overflow` мы указали, что в случае, если все процессы-обработчики будут заняты, то можно создавать два дополнительных процесса, чтобы помочь разобраться с нагрузкой. *(`overflow`-процессы завершаются как только они выполнят свою работу.)*

Next, we added `:poolboy.child_spec/2` function to the array of children so that the pool of workers will be started when the application starts.
It takes two arguments: name of the pool, and pool configuration.

## Создание рабочего процесса
Модуль рабочего процесса будет простым GenServer'ом, который считает квадратный корень числа, затем останавливается на секунду и выводит pid процесса.
Создадим `lib/poolboy_app/worker.ex`:

```elixir
defmodule PoolboyApp.Worker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_call({:square_root, x}, _from, state) do
    IO.puts("process #{inspect(self())} считает квадратный корень из #{x}")
    Process.sleep(1000)
    {:reply, :math.sqrt(x), state}
  end
end
```

## Использование Poolboy

Теперь, когда у нас есть `PoolboyApp.Worker`, мы можем тестировать Poolboy.
Создадим простой модуль, генерирующий задачи при помощи Poolboy.
`:poolboy.transaction/3` - это функция, которую вы можете использовать для взаимодействия с рабочим пулом.
Создадим `lib/poolboy_app/test.ex`:

```elixir
defmodule PoolboyApp.Test do
  @timeout 60000

  def start do
    1..20
    |> Enum.map(fn i -> async_call_square_root(i) end)
    |> Enum.each(fn task -> await_and_inspect(task) end)
  end

  defp async_call_square_root(i) do
    Task.async(fn ->
      :poolboy.transaction(
        :worker,
        fn pid ->
          # Let's wrap the genserver call in a try - catch block. This allows us to trap any exceptions
          # that might be thrown and return the worker back to poolboy in a clean manner. It also allows
          # the programmer to retrieve the error and potentially fix it.
          try do
            GenServer.call(pid, {:square_root, i}) end
          catch
            e, r -> IO.inspect("poolboy transaction caught error: #{inspect(e)}, #{inspect(r)}")
            :ok
          end
        end,
        @timeout
      )
    end)
  end

  defp await_and_inspect(task), do: task |> Task.await(@timeout) |> IO.inspect()
end
```

Запустим тестовую функцию, чтобы увидеть результат.

```shell
$ iex -S mix
```

```elixir
iex> PoolboyApp.Test.start()
process #PID<0.182.0> calculating square root of 7
process #PID<0.181.0> calculating square root of 6
process #PID<0.157.0> calculating square root of 2
process #PID<0.155.0> calculating square root of 4
process #PID<0.154.0> calculating square root of 5
process #PID<0.158.0> calculating square root of 1
process #PID<0.156.0> calculating square root of 3
...
```

Если в пуле не останется свободных процессов, Poolboy вызовет таймаут после периода таймаута по умолчанию (пять секунд) и не будет принимать новые запросы.
В нашем примере мы увеличили период таймаута до минуты, чтобы показать, как можно менять это значение.
In case of this app, you can observe the error if you change the value of `@timeout` to less than 1000.

Несмотря на то, что мы пытаемся создать много процессов *(всего двадцать в примере выше)*, функция `:poolboy.transaction/3` ограничит общее количество созданных процессов до пяти *(плюс два процесса для обработки перегрузки)*, как мы и указали в настройках.
Все запросы будут обработаны пулом процессов вместо создания по процессу на каждый запрос.
