---
layout: page
title: Plug
category: specifics
order: 1
lang: ru
---

Если вы знакомы с `Ruby`, то можете думать о `Plug` как о комбинации `Rack` и `Sinatra`. Во-первых, `Plug` это набор договорённостей и спецификаций, позволяющих создавать универсальные компонуемые модули, иcпользуемые в веб-приложениях. Во-вторых, адаптеры соединений для различных веб-серверов на платформе `Erlang VM`. Хотя `Plug` и не является частью ядра `Elixir`, это официальный проект от той же команды.

{% include toc.html %}

## Установка

Plug устанавливается с помощью `mix`. Для установки `Plug` необходимо внести два небольших изменения в наш файл `mix.exs`. Первое, что необходимо сделать, это добавить `Plug` и выбранный веб-сервер (мы будем использовать [`Cowboy`](https://github.com/ninenines/cowboy)) в качестве зависимостей:

```elixir
defp deps do
  [{:cowboy, "~> 1.0.0"},
   {:plug, "~> 1.0"}]
end
```

Во-вторых, нужно добавить веб-сервер и `Plug` к нашему `OTP` приложению:

```elixir
def application do
  [applications: [:cowboy, :logger, :plug]]
end
```

## Спецификация

Чтобы создавать собственные модули `Plug`, нужно придерживаться спецификации. К счастью, необходимо реализовать всего две функции: `init/1` и `call/2`.

Функция `init/1` используется для инициализации параметров нашего модуля `Plug`, эти параметры передаются в качестве второго аргумента в функцию `call/2`. В дополнение к инициализированным параметрам, функция `call/2` получает структуру `%Plug.Conn` в качества своего первого аргумента, и ожидается, что она также вернёт соединение (структуру того же типа).

Вот пример простого модуля `Plug`, который возвращает "Hello World!":

```elixir
defmodule HelloWorldPlug do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Hello World!")
  end
end
```

## Создание модуля Plug

Для примера создадим модуль `Plug`, проверяющий наличие всех заданных параметров у входящего запроса. Реализуя такую проверку в виде модуля `Plug`, мы можем быть уверены, что приложением будут обрабатываться только корректные запросы. Ожидается, что наш модуль будет инициализироваться с двумя аргументами: `:paths` и `:fields`. Первый будет содержать те пути запросов, к которым мы применяем нашу проверку, а второй &mdash; наличие каких именно параметров у входящего запроса требуется контролировать.

_Примечание_: модули `Plug` применяются ко всем запросам подряд, именно поэтому мы реализуем фильтрацию запросов и применяем нашу логику только к определённому их подмножеству. Чтобы проигнорировать запрос, мы просто передаём входящее соединение (структуру `%Plug.Conn`) далее без изменений.

Сначала мы покажем реализацию такого модуля `Plug`, а потом разберём его работу. Создаём модуль в файле `lib/plug/verify_request.ex`:

```elixir
defmodule Example.Plug.VerifyRequest do
  import Plug.Conn

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
    verified = body_params
               |> Map.keys
               |> contains_fields?(fields)
    unless verified, do: raise IncompleteRequestError
  end

  defp contains_fields?(keys, fields), do: Enum.all?(fields, &(&1 in keys))
end
```

Первое, что необходимо отметить &mdash; мы определили новое исключение `IncompleteRequestError`, и что один из его параметров это `:plug_status`. Если этот параметр доступен, модуль `Plug` использует его, чтобы установить код состояния для `HTTP` ответа в случае возникновения исключения.

Вторая часть модуля, это функция `call/2`. Именно тут определяется, нужно ли вообще проверять данный запрос. Мы вызываем функцию `verify_request!/2` только в том случае, если путь запроса содержится в аргументе `:paths`.

Последняя часть описываемого модуля Plug &mdash; закрытая функция `verify_request!/2`, которая проверяет наличие у запроса всех требуемых параметров из аргумента `:fields`. В случае отсутствия любого из параметров, вызывается исключение `IncompleteRequestError`.

## Использование Plug.Router

Теперь, когда готов модуль `VerifyRequest`, можно перейти к написанию маршрутизатора. Как мы сейчас увидим, фреймворк типа `Sinatra` в `Elixir` не требуется, так как мы получаем его возможности вместе с `Plug`.

Для начала давайте создадим файл `lib/plug/router.ex` и скопируем в него следующий код:

```elixir
defmodule Example.Plug.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/", do: send_resp(conn, 200, "Welcome")
  match _, do: send_resp(conn, 404, "Oops!")
end
```

Это самая простая реализация модуля `Router`, её код довольно очевиден. Мы подключили необходимые макросы с помощью инструкции `use Plug.Router` и задействовали встроенные модули `Plug`: `:match` и `:dispatch`. В коде задано два предопределённых пути маршрутизации: один, для обработки `GET`-запросов к родительскому узлу '/', и второй, для обработки всех остальных запросов, возвращающий сообщение об ошибке `404`.

Давайте добавим созданный нами модуль `Plug` к коду данного маршрутизатора:

```elixir
defmodule Example.Plug.Router do
  use Plug.Router

  alias Example.Plug.VerifyRequest

  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug VerifyRequest, fields: ["content", "mimetype"],
                      paths:  ["/upload"]
  plug :match
  plug :dispatch

  get "/", do: send_resp(conn, 200, "Welcome")
  post "/upload", do: send_resp(conn, 201, "Uploaded")
  match _, do: send_resp(conn, 404, "Oops!")
end
```

Вот и всё! Мы настроили наш модуль `Plug` так, чтобы проверять, что все запросы к пути `/upload` содержат параметры `"content"` и `"mimetype"`. Только в случае прохождения этой проверки может быть выполнен код маршрутизатора, связанный с такими запросами.

На данный момент, наша реализация `/upload` не очень полезна, но мы разобрались как создавать и использовать собственный модуль `Plug`.

## Запускаем наше веб-приложение

Перед тем как наше приложение может быть запущено, необходимо установить и настроить веб-сервер, в данном случае это `Cowboy`. Сейчас мы просто внесём все необходимые изменения в последующий код, а с деталями будем разбираться в других уроках.

Начнём с изменения блока `application` в файле `mix.exs` для того, чтобы предоставить среде `Elixir` информацию о нашем приложении и установить для приложения переменную среды `env`. Отредактированный код данного блока будет выглядеть следующим образом:

```elixir
def application do
  [applications: [:cowboy, :plug],
   mod: {Example, []},
   env: [cowboy_port: 8080]]
end
```

Далее необходимо обновить файл `lib/example.ex` для запуска и надзора за веб-сервером `Cowboy`:

```elixir
defmodule Example do
  use Application

  def start(_type, _args) do
    port = Application.get_env(:example, :cowboy_port, 8080)

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Example.Plug.Router, [], port: port)
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

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

Тестировать модули `Plug` легко благодаря наличию [`Plug.Test`](https://hexdocs.pm/plug/Plug.Test.html). Этот модуль предоставляет множество функций для упрощения тестирования.

Посмотрим, сможете ли вы самостоятельно разобраться с кодом для тестирования маршрутизатора ниже:

```elixir
defmodule RouterTest do
  use ExUnit.Case
  use Plug.Test

  alias Example.Plug.Router

  @content "<html><body>Hi!</body></html>"
  @mimetype "text/html"

  @opts Router.init([])

  test "returns welcome" do
    conn = conn(:get, "/", "")
           |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "returns uploaded" do
    conn = conn(:post, "/upload", "content=#{@content}&mimetype=#{@mimetype}")
           |> put_req_header("content-type", "application/x-www-form-urlencoded")
           |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 201
  end

  test "returns 404" do
    conn = conn(:get, "/missing", "")
           |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end
```

## Доступные модули Plug

Много модулей `Plug` доступно для использования сразу "из коробки". Полный список можно найти в документации по `Plug` &mdash; [здесь](https://github.com/elixir-lang/plug#available-plugs).
