---
version: 1.2.0
title: Plug
---

Если вы знакомы с `Ruby`, то можете думать о `Plug` как о комбинации `Rack` и `Sinatra`. Это набор договорённостей и спецификаций для модулей, используемых в веб-приложениях, а также адаптеры соединений для различных веб-серверов. Хотя `Plug` и не является частью ядра `Elixir`, это официальный проект от той же команды.

Мы начнем с создания минимального рабочего веб-приложения с использованием `Plug`. После этого мы познакомимся с роутерами и узнаем, как добавить `Plug` к уже существующему приложению.

{% include toc.html %}

## Перед установкой

Чтобы следовать инструкциям этого урока, вам понадобятся установленный Elixir версии 1.4 или выше и `mix`.

Если у вас еще нет проекта, создайте его:

```shell
$ mix new example
$ cd example
```

## Зависимости

Добавлять новые зависимости при помощи `mix` невероятно легко. Чтобы установить `Plug` достаточно сделать пару изменений в файле `mix.exs`.
Для начала добавим в него сам `Plug`, а также веб-сервер (мы будет использовать `Cowboy`).

```elixir
defp deps do
  [
    {:cowboy, "~> 1.1.2"},
    {:plug, "~> 1.3.4"}
  ]
end
```

Выполните следующую команду в терминале, чтобы `mix` скачал и установил новые зависимости:

```shell
$ mix deps.get
```

## Спецификация

Чтобы создавать собственные модули `Plug`, нужно придерживаться спецификации. К счастью, необходимо реализовать всего две функции: `init/1` и `call/2`.

Вот пример простого модуля `Plug`, который возвращает "Hello World!":

```elixir
defmodule Example.HelloWorldPlug do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Hello World!\n")
  end
end
```

Сохраним файл как `lib/example/hello_world_plug.ex`.

Функция `init/1` используется для инициализации параметров нашего модуля `Plug`. Она вызывается супервизором, который мы увидим в следующей секции. Пока что в качестве параметров будет пустой список.

Значение, возвращаемое `init/1`, передается в качестве второго аргумента в функцию `call/2`.

Функция `call/2` вызывается для каждого нового запроса, приходящего от веб-сервера &mdash; `Cowboy`.
Она получает структуру `%Plug.Conn` в качества своего первого аргумента, и ожидается, что она также вернёт соединение (структуру того же типа).

## Настройка Application-модуля приложения

Так как мы создаём Plug-приложение с нуля, нам придется создать еще и Application-модуль.
Добавим в `lib/example.ex` старт веб-сервера `Cowboy`:

```elixir
defmodule Example do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Example.HelloWorldPlug, [], port: 8080)
    ]

    Logger.info("Started application")

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

Это запустит `Cowboy` под супервизором, который в свою очередь запустит `HelloWorldPlug` в качестве дочернего процесса.

В вызове `Plug.Adapters.Cowboy.child_spec/4` третий аргумент будет передан в `Example.HelloWorldPlug.init/1`.

Но это еще не все. Откроем `mix.exs` снова и найдем там функцию `applications`.
Нужно сделать так, чтобы наше приложение автоматически запускалось.

Для этого изменим файл следующим образом:

```elixir
def application do
  [
    extra_applications: [:logger],
    mod: {Example, []}
  ]
end
```

Теперь всё готово к запуску нашего первого веб-приложения, созданного на базе `Plug`. В командной строке выполним:

```shell
$ mix run --no-halt
```

Как только все скомпилируется, и выведется сообщение `[info]  Started app`, откройте в браузере `127.0.0.1:8080`. Там должно появиться следующее:

```
Hello World!
```

## Использование Plug.Router

Для большинства приложений, таких как веб-сайты и REST API, понадобится что-то, что будет перенаправлять запросы к определенным ресурсам на соответствующие обработчики в коде.
Специально для этого в `Plug` существует маршрутизатор (или роутер). Как мы сейчас увидим, фреймворк типа `Sinatra` в `Elixir` не требуется, так как мы получаем его возможности вместе с `Plug`

Для начала создадим файл `lib/plug/router.ex` и скопируем в него следующий код:

```elixir
defmodule Example.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Welcome"))
  match(_, do: send_resp(conn, 404, "Oops!"))
end
```

Это самая простая реализация модуля `Router`, её код довольно очевиден.
Мы подключили необходимые макросы с помощью инструкции `use Plug.Router` и задействовали встроенные модули `Plug`: `:match` и `:dispatch`. В коде задано два предопределённых пути маршрутизации: один, для обработки `GET`-запросов к родительскому узлу `'/'`, и второй, для обработки всех остальных запросов, возвращающий сообщение об ошибке `404`.

Вернемся теперь к `lib/example.ex` и добавим `Example.Router` к дочерним процессам веб-сервера.
Поменяем `Example.HelloWorldPlug` на наш новый роутер:

```elixir
def start(_type, _args) do
  children = [
    Plug.Adapters.Cowboy.child_spec(:http, Example.Router, [], port: 8080)
  ]

  Logger.info("Started application")
  Supervisor.start_link(children, strategy: :one_for_one)
end
```

Запустим веб-сервер (в случае, если предыдущий сервер еще работает, его можно остановить, дважды нажав `Ctrl+C`).

Теперь откроем `127.0.0.1:8080` в браузере.
Мы должны увидеть сообщение `Welcome`.
Попробуем открыть `127.0.0.1:8080/waldo` или любой другой ресурс.
Должна появиться 404 ошибка с текстом `Oops!`.

## Создание еще одного модуля Plug

Очень часто Plug-модули используются для обработки всех или части входящих запросов в соответствии с общей логикой.

Для примера создадим модуль `Plug`, проверяющий наличие всех заданных параметров у входящего запроса. Реализуя такую проверку в виде модуля `Plug`, мы можем быть уверены, что приложением будут обрабатываться только корректные запросы. Ожидается, что наш модуль будет инициализироваться с двумя аргументами: `:paths` и `:fields`. Первый будет содержать те пути запросов, к которым мы применяем нашу проверку, а второй &mdash; наличие каких именно параметров у входящего запроса требуется контролировать.

_Примечание_: модули `Plug` применяются ко всем запросам подряд, именно поэтому мы реализуем фильтрацию запросов и применяем нашу логику только к определённому их подмножеству. Чтобы проигнорировать запрос, мы просто передаём входящее соединение (структуру `%Plug.Conn`) далее без изменений.

Сначала мы покажем реализацию такого модуля `Plug`, а потом разберём его работу. Создаём модуль в файле `lib/example/plug/verify_request.ex`:

```elixir
defmodule Example.Plug.VerifyRequest do
  defmodule IncompleteRequestError do
    @moduledoc """
    Если у запроса отсутствует один из требуемых параметров - возникает исключение.
    """

    defexception message: "", plug_status: 400
  end

  def init(options), do: options

  def call(%Plug.Conn{request_path: path} = conn, opts) do
    if path in opts[:paths], do: verify_request!(conn.body_params, opts[:fields])
    conn
  end

  defp verify_request!(body_params, fields) do
    verified =
      body_params
      |> Map.keys()
      |> contains_fields?(fields)

    unless verified, do: raise(IncompleteRequestError)
  end

  defp contains_fields?(keys, fields), do: Enum.all?(fields, &(&1 in keys))
end
```

Первое, что необходимо отметить &mdash; мы определили новое исключение `IncompleteRequestError`, и что один из его параметров это `:plug_status`. Если этот параметр доступен, модуль `Plug` использует его, чтобы установить код состояния для `HTTP` ответа в случае возникновения исключения.

Вторая часть модуля, это функция `call/2`. Именно тут определяется, нужно ли вообще проверять данный запрос. Мы вызываем функцию `verify_request!/2` только в том случае, если путь запроса содержится в аргументе `:paths`.

Последняя часть описываемого модуля Plug &mdash; закрытая функция `verify_request!/2`, которая проверяет наличие у запроса всех требуемых параметров из аргумента `:fields`. В случае отсутствия любого из параметров, вызывается исключение `IncompleteRequestError`.

Мы настроили наш модуль `Plug` так, чтобы проверять, что все запросы к пути `/upload` содержат параметры `"content"` и `"mimetype"`. Только в случае прохождения этой проверки может быть выполнен код маршрутизатора, связанный с такими запросами.

Теперь нужно сообщить маршрутизатору о новом Plug-модуле.
Отредактируем `lib/example/router.ex` следующим образом:

```elixir
defmodule Example.Router do
  use Plug.Router
  use Plug.ErrorHandler

  alias Example.Plug.VerifyRequest

  plug(Plug.Parsers, parsers: [:urlencoded, :multipart])

  plug(
    VerifyRequest,
    fields: ["content", "mimetype"],
    paths: ["/upload"]
  )

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Welcome\n"))
  post("/upload", do: send_resp(conn, 201, "Uploaded\n"))
  match(_, do: send_resp(conn, 404, "Oops!\n"))
end
```

## Делаем HTTP порт конфигурируемым

Когда мы создавали наше приложение, HTTP порт был "зашит" в коде.
Считается хорошим тоном делать порт конфигурируемым при помощи файлов настроек.

Начнём с изменения блока `application` в файле `mix.exs` для того, чтобы предоставить среде `Elixir` информацию о нашем приложении и установить для приложения переменную среды `env`. Отредактированный код данного блока будет выглядеть следующим образом:

```elixir
def application do
  [
    extra_applications: [:logger],
    mod: {Example, []},
    env: [cowboy_port: 8080]
  ]
end
```

Непосредственно нашего приложения касается строка `mod: {Example, []}`. Обратите внимание, что мы также запускаем приложения `cowboy`, `logger` и `plug`.

Далее необходимо добавить в файл `lib/example.ex` чтение номера порта из настроек и передачу его в `Cowboy`:

```elixir
defmodule Example do
  use Application

  def start(_type, _args) do
    port = Application.get_env(:example, :cowboy_port, 8080)

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Example.Router, [], port: port)
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

Третий аргумент в `Application.get_env` &mdash; это порт по умолчанию на случай, если настройка не объявлена.

> (Необязательно) добавить параметр `:cowboy_port` в файл `config/config.exs`

```elixir
use Mix.Config

config :example, cowboy_port: 8080
```

Теперь для запуска приложения можно использовать команду:

```shell
$ mix run --no-halt
```

## Тестирование модуля Plug

Тестировать модули `Plug` легко благодаря наличию `Plug.Test`.
Этот модуль предоставляет множество функций для упрощения тестирования.

Напишем следующий тест в `test/example/router_test.exs`:

```elixir
defmodule Example.RouterTest do
  use ExUnit.Case
  use Plug.Test

  alias Example.Router

  @content "<html><body>Hi!</body></html>"
  @mimetype "text/html"

  @opts Router.init([])

  test "returns welcome" do
    conn =
      conn(:get, "/", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "returns uploaded" do
    conn =
      conn(:post, "/upload", "content=#{@content}&mimetype=#{@mimetype}")
      |> put_req_header("content-type", "application/x-www-form-urlencoded")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 201
  end

  test "returns 404" do
    conn =
      conn(:get, "/missing", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end
```

И запустим командой:

```shell
$ mix test test/example/router_test.exs
```

## Доступные модули Plug

Много модулей `Plug` доступно для использования сразу "из коробки". Полный список можно найти в документации по `Plug` &mdash; [здесь](https://github.com/elixir-lang/plug#available-plugs).
