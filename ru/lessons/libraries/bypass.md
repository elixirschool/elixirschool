---
version: 1.0.0
title: Bypass
---

При тестировании приложений часто идет речь о запросах к внешним сервисам.
Мы даже можем захотеть имитировать такие различные ситуации, как ошибки со стороны сервера.
Реализация подобного подхода в Elixir требует дополнительных инструментов.

В этом уроке мы рассмотрим, как библиотека [bypass](https://github.com/PSPDFKit-labs/bypass) может помочь с таким тестированием.

{% include toc.html %}

## Что такое Bypass?

[Bypass](https://github.com/PSPDFKit-labs/bypass) описывается как "быстрый способ создать заглушку, которая может быть использована вместо реального HTTP-сервера для возврата подготовленных ответов на запросы клиентов".

Что это значит?
Под капотом Bypass — OTP-приложение, которое имитирует внешний веб-сервер, слушающий и отвечающий на запросы.
Используя предопределённые ответы, мы можем проверить любые возможные сценарии — как неожиданные отказы сервисов и ошибки, так и ожидаемые стандартные ситуации. И всё это без выполнения внешних запросов к реальному сервису.

## Использование Bypass

Чтобы лучше продемонстрировать возможности Bypass, мы напишем простую утилиту для проверки работоспособности списка сайтов.
Для этого мы создадим новый проект с супервизором и GenServer-ом для проверки доменов по настраиваемому интервалу времени.
Используя Bypass в тестах, мы сможем проверить, что приложение корректно работает в разных ситуациях.

_Замечание_: Если хотите посмотреть финальный код, его можно найти в репозитории Elixir School [Clinic](https://github.com/elixirschool/clinic).

К этому моменту вы должны уметь создавать новый Mix проект и добавлять необходимые зависимости, потому сфокусируемся именно на тестируемых частях.

Если нужно вспомнить, как это делается, можно заглянуть в раздел [Создание проекта](../../basics/mix/#Создание-проекта) соответствующего урока [Mix](../../basics/mix/).

Давайте начнём с создания нового модуля, который будет выполнять сами запросы к доменам.
Используя [HTTPoison](https://github.com/edgurgel/httpoison) мы создадим функцию `ping/1`, которая принимает URL и возвращает `{:ok, body}` для ответов с кодом 200 и `{:error, reason}` для остальных:

```elixir
defmodule Clinic.HealthCheck do
  def ping(urls) when is_list(urls), do: Enum.map(urls, &ping/1)

  def ping(url) do
    url
    |> HTTPoison.get()
    |> response()
  end

  defp response({:ok, %{status_code: 200, body: body}}), do: {:ok, body}
  defp response({:ok, %{status_code: status_code}}), do: {:error, "HTTP Status #{status_code}"}
  defp response({:error, %{reason: reason}}), do: {:error, reason}
end
```

Стоит заметить, что мы _не_ используем GenServer и для этого есть причина:
Вынося функциональность из GenServer, мы имеем возможность протестировать наш код без лишней сложности.

Код готов, пора приступить к тестам.
Для начала работы с Bypass нужно убедиться, что он работает.
Для этого, приведем `test/test_helper.exs` к такому виду:

```elixir
ExUnit.start()
Application.ensure_all_started(:bypass)
```

Теперь, когда понятно, что Bypass в тестах запущен, пора перейти к самому тесту `test/clinic/health_check_test.exs` и закончить настройку.
Для подготовки Bypass к приёму запросов, нужно вызвать `Bypass.open/1`, что может быть выполнено в рамках настройки теста:

```elixir
defmodule Clinic.HealthCheckTests do
  use ExUnit.Case

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end
end
```

Пока мы будем использовать Bypass по его порту по умолчанию, но если нужно будет его изменить (что мы сделаем позднее), можно передать параметр `:port` функции `Bypass.open/1`. Например, `Bypass.open(port: 1337)`.
Теперь мы готовы работать с Bypass.
Начнём с проверки успешного сценария:

```elixir
defmodule Clinic.HealthCheckTests do
  use ExUnit.Case

  alias Clinic.HealthCheck

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "отвечает с HTTP кодом 200", %{bypass: bypass} do
    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(conn, 200, "pong")
    end)

    assert {:ok, "pong"} = HealthCheck.ping("http://localhost:#{bypass.port}")
  end
end
```

Тест прост, и если мы его запустим, он пройдет. Но давайте посмотрим, что делает каждая часть кода.
Первое же, что мы видим в тесте — вызов функции `Bypass.expect/2`:

```elixir
Bypass.expect(bypass, fn conn ->
  Plug.Conn.resp(conn, 200, "pong")
end)
```

`Bypass.expect/2` принимает подключение к Bypass и функцию с одним аргументом, которая изменит подключение и вернёт его. Также это позволяет проверять, что это тот запрос, который мы ожидали. Давайте обновим тест для проверки, что это GET-запрос к пути `/ping`:

```elixir
test "отвечает с HTTP кодом 200", %{bypass: bypass} do
  Bypass.expect(bypass, fn conn ->
    assert "GET" == conn.method
    assert "/ping" == conn.request_path
    Plug.Conn.resp(conn, 200, "pong")
  end)

  assert {:ok, "pong"} = HealthCheck.ping("http://localhost:#{bypass.port}/ping")
end
```

В последней части теста мы используем `HealthCheck.ping/1` и проверяем, что ответ правилен, как и ожидалось. Но что такое `bypass.port`?
Bypass слушает на локальном порту и принимает эти запросы. И мы используем `bypass.port` для получения номера порта по умолчанию, так как мы не определили его самостоятельно в `Bypass.open/1`.

Следующая часть — добавить тестовые сценарии для ошибок.
Мы можем начать с теста, похожего на наш первый с небольшими изменениями: вернуть 500 код ответа и проверить, что вернулся кортеж `{:error, reason}`:

```elixir
test "request with HTTP 500 response", %{bypass: bypass} do
  Bypass.expect(bypass, fn conn ->
    Plug.Conn.resp(conn, 500, "Server Error")
  end)

  assert {:error, "HTTP Status 500"} = HealthCheck.ping("http://localhost:#{bypass.port}")
end
```

В этом сценарии нет ничего особенного, так что пора перейти к следующему: неожиданный отказ сервера.
Для этого мы не будем использовать `Bypass.expect/2` — вместо этого `Bypass.down/1` будет полезен для сброса соединения:

```elixir
test "request with unexpected outage", %{bypass: bypass} do
  Bypass.down(bypass)

  assert {:error, :econnrefused} = HealthCheck.ping("http://localhost:#{bypass.port}")
end
```

Если мы запустим новые тесты, они все пройдут успешно, как и ожидалось!
Теперь, когда модуль `HealthCheck` протестирован, мы можем перейти к следующей части — протестировать его вместе с планировщиком, основанным на GenServer.

## Несколько внешних сайтов

Для этого проекта мы остановимся на минимальном планировщике и будем использовать `Process.send_after/3` для запуска повторяющихся проверок.
Больше об этом подходе можно узнать в [документации](https://hexdocs.pm/elixir/Process.html) модуля `Process`.
В этом приложении нам нужно три вещи: набор сайтов, интервал времени между проверками и модуль, который реализует `ping/1`.
С помощью передачи модуля, мы дополнительно разносим функциональность и GenServer, что позволяет лучше изолировать тестируемые части приложения:

```elixir
def init(opts) do
  sites = Keyword.fetch!(opts, :sites)
  interval = Keyword.fetch!(opts, :interval)
  health_check = Keyword.get(opts, :health_check, HealthCheck)

  Process.send_after(self(), :check, interval)

  {:ok, {health_check, sites}}
end
```

Теперь нужно определить функцию `handle_info/2` для получения сообщения `:check` отправленного с помощью `send_after/2`.
Для упрощения всего мы будем передавать список сайтов в функцию `HealthCheck.ping/1` и выводить результат либо с помощью `Logger.info`, либо `Logger.error`.
Код будет написан с учетом того, что позже его можно будет улучшить.

```elixir
def handle_info(:check, {health_check, sites}) do
  sites
  |> health_check.ping()
  |> Enum.each(&report/1)

  {:noreply, {health_check, sites}}
end

defp report({:ok, body}), do: Logger.info(body)
defp report({:error, reason}) do
  reason
  |> to_string()
  |> Logger.error()
end
```

Как уже обсуждалось, мы передаём сайты в `HealthCheck.ping/1` и проходим по результатам с помощью `Enum.each/2`, вызывая функцию `report/1` для каждого.
Теперь, когда планировщик готов, можно начать его тестировать.

Мы не будем слишком много заниматься тестированием планировщика, так как это не связано с Bypass. Перейдем сразу к финальному коду:

```elixir
defmodule Clinic.SchedulerTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  alias Clinic.Scheduler

  defmodule TestCheck do
    def ping(_sites), do: [{:ok, "pong"}, {:error, "HTTP Status 404"}]
  end

  test "проверки работоспособности работают и результаты записаны" do
    opts = [health_check: TestCheck, interval: 1, sites: ["http://example.com", "http://example.org"]]

    output =
      capture_log(fn ->
        {:ok, _pid} = GenServer.start_link(Scheduler, opts)
        :timer.sleep(10)
      end)

    assert output =~ "pong"
    assert output =~ "HTTP Status 404"
  end
end
```

Мы полагаемся на тест реализации `TestCheck` одновременно с `CaptureLog.capture_log/1` для проверки, что соответствующие вызовы логированы.

Теперь у нас есть работающие модули `Scheduler` и `HealthCheck`. Давайте напишем интеграционный тест для проверки, что всё работает вместе. Нам понадобится Bypass для этого теста и нам придётся работать с несколькими Bypass запросами в рамках одного теста. Давайте посмотрим, как это сделать.

Помните `bypass.port` из более ранней части? Когда нам нужно работать с несколькими сайтами, опция `:port` незаменима. Как можно было уже догадаться, можно создать несколько Bypass-подключений — каждое со своим портом, которые будут имитировать разные сайты. Мы начнем с изучения обновленного `test/clinic_test.exs`:

```elixir
defmodule ClinicTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  alias Clinic.Scheduler

  test "сайты проверены и результаты записаны" do
    bypass_one = Bypass.open(port: 1234)
    bypass_two = Bypass.open(port: 1337)

    Bypass.expect(bypass_one, fn conn ->
      Plug.Conn.resp(conn, 500, "Server Error")
    end)

    Bypass.expect(bypass_two, fn conn ->
      Plug.Conn.resp(conn, 200, "pong")
    end)

    opts = [interval: 1, sites: ["http://localhost:1234", "http://localhost:1337"]]

    output =
      capture_log(fn ->
        {:ok, _pid} = GenServer.start_link(Scheduler, opts)
        :timer.sleep(10)
      end)

    assert output =~ "[info]  pong"
    assert output =~ "[error] HTTP Status 500"
  end
end
```

В этом тесте не должно быть ничего неожиданного. Вместо создания одного `Bypass`-подключения в `setup`, мы создаем два с передачей им портов 1234 и 1337. Дальше — вызовы `Bypass.expect/2` и тот же код, что был у нас в `SchedulerTest` для запуска планировщика и проверки, что соответствующие сообщения записываются в лог.

Вот и всё! Мы написали небольшую утилиту для информирования о проблемах с доменами и изучили, как использовать Bypass для написания тестов работы с внешними сервисами.
