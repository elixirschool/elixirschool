%{
  version: "1.2.0",
  title: "Тестирование",
  excerpt: """
  Тестирование &mdash; важная часть разработки.
В этом уроке мы узнаем, как тестировать наш Elixir-код с использованием ExUnit, а также познакомимся с некоторыми отличными приёмами.
  """
}
---

## ExUnit

В Elixir есть встроенный фреймворк для тестирования &mdash; ExUnit, который включает всё необходимое для тщательного тестирования нашего кода.
Перед тем как двигаться дальше, стоит отметить, что тесты реализованы в виде скриптов Elixir, поэтому нам нужно использовать расширение `.exs`.
Для того, чтобы выполнять тесты, нужно запустить ExUnit с помощью вызова `ExUnit.start()`, обычно это делается в `test/test_helper.exs`.

Когда мы сгенерировали пример проекта из прошлого урока, Mix сделал для нас тест, который можно найти в `test/example_test.exs`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :world
  end
end
```

Тесты проекта можно запустить с помощью команды `mix test`.
Если мы выполним её, то увидим примерно следующее:

```shell
..

Finished in 0.03 seconds
2 tests, 0 failures
```

Откуда в выводе появился второй тест? Кроме теста в `test/example_test.exs`, Mix также сгенерировал тест для документации в `lib/example.ex`.

```elixir
defmodule Example do
  @moduledoc """
  Documentation for Example.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Example.hello
      :world

  """
  def hello do
    :world
  end
end
```

### assert

Если вы когда-либо ранее писали тесты, вы должны быть знакомы с `assert`; в некоторых фреймворках роль `assert` выполняют `should` или `expect`.

Макрос `assert` используется, чтобы проверить, что выражение истинно.
В случае, если это не так, возникнет ошибка, а тесты завершатся с ошибкой.
Давайте изменим наш пример и запустим `mix test`, чтобы протестировать ошибку:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :word
  end
end
```

Сейчас мы увидим другой результат:

```shell
  1) test greets the world (ExampleTest)
     test/example_test.exs:5
     Assertion with == failed
     code:  assert Example.hello() == :word
     left:  :world
     right: :word
     stacktrace:
       test/example_test.exs:6 (test)

.

Finished in 0.03 seconds
2 tests, 1 failures
```

ExUnit покажет, какое именно утверждение было ошибочным, какое значение ожидалось, и какое было получено на самом деле.

### refute

Макрос `refute` относится к `assert` также, как `unless` к `if`.
Используйте `refute`, если вы хотите убедиться, что выражение всегда ложно.

### assert_raise

Иногда необходимо проверить, возникла ли в коде ошибка.
Это можно сделать с помощью `assert_raise`.
Мы столкнёмся с примером применения `assert_raise` в следующем уроке о Plug.

### assert_receive

В Elixir приложения состоят из процессов-акторов, которые отправляют сообщения друг другу, и довольно часто нужно протестировать, что сообщения отправляются.
Так как ExUnit работает в собственном процессе, он может получать сообщения. Именно получение сообщений этим процессом можно проверить с помощью `assert_received`:

```elixir
defmodule SendingProcess do
  def run(pid) do
    send(pid, :ping)
  end
end

defmodule TestReceive do
  use ExUnit.Case

  test "receives ping" do
    SendingProcess.run(self())
    assert_received :ping
  end
end
```

`assert_received` не ждет сообщений по умолчанию, но можно указать время ожидания.

### capture_io и capture_log

Получение вывода приложения возможно с использованием `ExUnit.CaptureIO` без изменения кода приложения.
Просто передайте функцию, генерирующую вывод в качестве параметра:

```elixir
defmodule OutputTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "outputs Hello World" do
    assert capture_io(fn -> IO.puts("Hello World") end) == "Hello World\n"
  end
end
```

`ExUnit.CaptureLog` &mdash; эквивалент отправки вывода приложения в `Logger`.

## Настройка теста

В некоторых случаях перед тестами необходимо произвести настройку.
Сделать это можно с помощью макросов `setup` и `setup_all`.
Макрос `setup` вызывается перед каждым тестом, а `setup_all` &mdash; один раз перед всем набором.
Ожидается, что они вернут кортеж вида `{:ok, state}`, `state` будет доступен для наших тестов.

В качестве примера изменим наш код и воспользуемся `setup_all`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  setup_all do
    {:ok, recipient: :world}
  end

  test "greets", state do
    assert Example.hello() == state[:recipient]
  end
end
```

## Использование заглушек

Простой совет касательно использования заглушек в Elixir: не делайте этого.
Возможно, вам по привычке захочется воспользоваться заглушкой (mock), но это крайне не приветствуется сообществом Elixir по веским причинам.

Эта тема раскрыта подробнее в [отличной статье](http://blog.plataformatec.com.br/2015/10/mocks-and-explicit-contracts/).
Суть в том, что вместо того, чтобы подменять методы для тестирования, создавайте интерфейсы в коде вне приложения и используйте объекты-заглушки, которые будут реализовывать этот интерфейс в процессе тестирования.

Для переключения между реализациями в коде предложения рекомендуется передавать модули в качестве аргументов функции и использовать значения по умолчанию.
Если этот вариант не подходит, можно использовать встроенные механизмы конфигурации.
Для создания такого подхода к заглушкам не нужна специальная библиотека. Достаточно функционала языка: поведений и функций обратного вызова.
