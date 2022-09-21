%{
  version: "2.2.1",
  title: "Plug",
  excerpt: """
  Если вы знакомы с Ruby, то считайте, что Plug это Rack с лёгким налётом Sinatra.
  Он предоставляет спецификацию для компонентов веб-приложений и адаптеров для веб-серверов.
  Хотя Plug и не является частью ядра Elixir, это официальный проект от той же команды.

  В этом уроке мы создадим простой HTTP-сервер с нуля, используя для этого библиотеку Elixir PlugCowboy.
  Cowboy - это простой HTTP-сервер для Erlang, и Plug предоставит нам интерфейс подключения для этого веб-сервера.

После того, как мы настроим наше простенькое рабочее веб-приложение, мы узнаем о маршрутизаторе Plug и о том, как использовать несколько модулей Plug в одном веб-приложении
  """
}
---

## Перед установкой

Чтобы следовать инструкциям этого урока, вам понадобятся установленный Elixir версии 1.5 или выше и `mix`.

Мы начнем с создания нового OTP-проекта с деревом супервизора.

```shell
mix new example --sup
cd example
```

Нам нужно, чтобы наше приложение Elixir включало дерево супервизора, потому что мы будем использовать супервизор для запуска нашего сервера Cowboy2.

## Зависимости

Добавлять новые зависимости при помощи mix невероятно легко.
Чтобы использовать Plug в качестве интерфейса подключения для веб-сервера Cowboy2, нам необходимо установить пакет PlugCowboy:

Добавьте в файл `mix.exs` следующее:

```elixir
def deps do
  [
    {:plug_cowboy, "~> 2.0"},
  ]
end
```

Выполните следующую команду в терминале, чтобы mix скачал и установил новые зависимости:

```shell
mix deps.get
```

## Спецификация

Чтобы создавать собственные Plug модули, нужно придерживаться спецификации.
К счастью, необходимо реализовать всего две функции: `init/1` и `call/2`.

Вот пример простого Plug модуля, который возвращает "Привет Мир!":

```elixir
defmodule Example.HelloWorldPlug do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Привет Мир!\n")
  end
end
```

Сохраним файл как `lib/example/hello_world_plug.ex`.

Функция `init/1` используется для инициализации параметров нашего модуля `Plug`.
Она вызывается супервизором, это будет объяснено в следующей секции.
Пока что в качестве параметров будет пустой список.

Значение, возвращаемое `init/1`, передается в качестве второго аргумента в функцию `call/2`.

Функция `call/2` вызывается для каждого нового запроса, приходящего от веб-сервера Cowboy.
Она получает структуру `%Plug.Conn{}` в качества первого аргумента, и ожидается, что она также вернёт соединение (структуру того типа `%Plug.Conn{}`).

## Настройка Application-модуля приложения

Мы должны дать команду "запуск" нашему приложению и контролировать веб-сервер Cowboy, когда приложение начнёт работать.

Мы реализуем это при помощи функции [`Plug.Cowboy.child_spec/1`](https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html#child_spec/1) .

Эта функция принимает три аргумента:

* `:scheme` - HTTP или HTTPS как атом (`:http`, `:https`)
* `:plug` - модуль Plug, который будет использоваться в качестве интерфейса для веб-сервера.
Можете уточнить имя модуля (например, `MyPlug`), или кортеж из имени модуля и опцией `{MyPlug, plug_opts}`, где `plug_opts` будут переданы в функцию `init/1` вашего модуля Plug.
* `:options` - опции сервера.
Здесь следует указать номер порта, который вы хотите задать вашему серверу для ожидания запросов.

В файле `lib/example/application.ex` следует реализовать описание дочернего процесса при помощи его функции `start/2`.

```elixir
defmodule Example.Application do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Example.HelloWorldPlug, options: [port: 8080]}
    ]
    opts = [strategy: :one_for_one, name: Example.Supervisor]

    Logger.info("Starting application...")

    Supervisor.start_link(children, opts)
  end
end
```

_Примечание_: Здесь нам не нужно вызывать `child_spec`, эта функция будет вызвана супервизором, запускающим этот процесс.
Здесь мы просто передаём кортеж: модуль, который мы хотим использовать для дочернего процесса, и три обязательных аргумента.

Это запустит веб-сервер `Cowboy2` под супервизором.
В свою очередь, Cowboy начнёт работу по протоколу HTTP (можно также указать HTTPS) с использованием указанного порта (8080) и с модулем Plug (Example.HelloWorldPlug) в качестве интерфейса для входящих веб-запросов.

Теперь всё готово к запуску нашего первого веб-приложения, созданного на базе `Plug`. Учтите, что из-за того, что мы создали OTP-проект с деревом супервизора (передав аргумент `--sup`), наше приложение `Example` запустится автоматически из-за функции `application`.

В файле `mix.exs` должны быть следующие строчки:

```elixir
def application do
  [
    extra_applications: [:logger],
    mod: {Example.Application, []}
  ]
end
```

Теперь мы готовы запустить наше простенькое рабочее веб-приложение.
В командной строке выполним:

```shell
mix run --no-halt
```

Как только все скомпилируется и выведется сообщение `[info]  Starting application...`, откройте
в браузере  <http://127.0.0.1:8080>.
Там должно появиться следующее:

```
Привет Мир!
```

## Использование Plug.Router

Для большинства приложений, таких как веб-сайты и REST API, понадобится что-то, что будет перенаправлять запросы к определенным ресурсам на соответствующие обработчики в коде.
Специально для этого в `Plug` существует маршрутизатор (или роутер).
Как мы сейчас увидим, фреймворк типа `Sinatra` в `Elixir` не требуется, так как мы получаем его возможности вместе с `Plug`.

Для начала создадим файл `lib/example/router.ex` и скопируем в него следующий код:

```elixir
defmodule Example.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Добро пожаловать")
  end

  match _ do
    send_resp(conn, 404, "Ой!")
  end
end
```

Это самая простая реализация модуля `Router`, её код довольно очевиден.
Мы подключили необходимые макросы с помощью инструкции `use Plug.Router` и задействовали встроенные модули `Plug`: `:match` и `:dispatch`.
В коде задано два предопределённых пути маршрутизации: один, для обработки `GET`-запросов к родительскому узлу `'/'`, и второй, для обработки всех остальных запросов, возвращающий сообщение об ошибке `404`.

Вернемся теперь к `lib/example.ex` и добавим `Example.Router` к дочерним процессам веб-сервера.
Поменяем `Example.HelloWorldPlug` на наш новый роутер:

```elixir
def start(_type, _args) do
  children = [
    {Plug.Cowboy, scheme: :http, plug: Example.Router, options: [port: 8080]}
  ]
  opts = [strategy: :one_for_one, name: Example.Supervisor]

  Logger.info("Starting application...")

  Supervisor.start_link(children, opts)
end
```

Запустим веб-сервер (в случае, если предыдущий сервер еще работает, его можно остановить, дважды нажав `Ctrl+C`).

Теперь откроем <http://127.0.0.1:8080> в браузере.
Мы должны увидеть сообщение `Добро пожаловать`.
Попробуем открыть <http://127.0.0.1:8080/waldo> или любой другой ресурс.
Должна появиться 404 ошибка с текстом `Ой!`.

## Создание еще одного модуля Plug

Считается обычной практикой использовать в одном веб-приложении несколько модулей Plug, каждый из которых занимается своим делом.
Например, у нас может быть был модуль, отвечающий за маршрутизацию; модуль, отвечающий за валидацию входящих веб-запросов; модуль, отвечающий за аутентификацию входящих запросов и так далее.
В данном разделе мы создадим модуль Plug, который будет проверять параметры входящих запросов (модуль-валидатор) и мы научим наше веб-приложение использовать оба наших модуля Plug -- маршрутизатор и валидатор.

Нам нужно создать модуль Plug, который проверяет, соответствует ли запрос какому-то заданному набору параметров.
Только валидные (соответствующие всему набору параметров) запросы будут переданы нашему приложению, если мы реализуем проверку валидности в модуле Plug.
Этот модуль Plug должен быть инициализирован с двумя опциями: `:paths` и `:fields`.
Эти опции задают пути, у которых будет проверяться логика, и поля, которые будут необходимы для проверки.

_Примечание_: В веб-приложении модули Plug применяются ко всем запросом, из-за чего мы будем фильтровать запросы и применять нашу логику валидации только к некоторым из этих запросов.
Чтобы проигнорировать запрос, мы просто пробрасываем соединение дальше.

Сначала мы покажем реализацию такого модуля Plug, а потом разберём его работу.
Создаём модуль в файле `lib/example/plug/verify_request.ex`:

```elixir
defmodule Example.Plug.VerifyRequest do
  defmodule IncompleteRequestError do
    @moduledoc """
    Если у запроса отсутствует один из требуемых параметров - возникает исключение.
    """

    defexception message: ""
  end

  def init(options), do: options

  def call(%Plug.Conn{request_path: path} = conn, opts) do
    if path in opts[:paths], do: verify_request!(conn.params, opts[:fields])
    conn
  end

  defp verify_request!(params, fields) do
    verified =
      params
      |> Map.keys()
      |> contains_fields?(fields)

    unless verified, do: raise(IncompleteRequestError)
  end

  defp contains_fields?(keys, fields), do: Enum.all?(fields, &(&1 in keys))
end
```

В первую очередь, нужно обратить внимание на то, что здесь мы задали новое исключение `IncompleteRequestError`. Оно вызывается в случае получения невалидного запроса.

Вторая часть модуля это функция `call/2`.
В этой функции мы определяем, нужно или нет применять нашу логику валидации.
Мы вызываем `verify_request!/2` только в случае, если путь запроса содержится в `:paths`.

Последняя часть описываемого модуля Plug — закрытая функция `verify_request!/2`, которая проверяет наличие у запроса всех требуемых параметров из аргумента `:fields`.
В случае отсутствия любого из параметров, вызывается исключение `IncompleteRequestError`.

Мы настроили наш модуль `Plug` так, чтобы проверять, что все запросы к пути `/upload` содержат параметры `"content"` и `"mimetype"`.
Только в случае прохождения этой проверки может быть выполнен код маршрутизатора, связанный с такими запросами.

Теперь нужно сообщить маршрутизатору о новом Plug-модуле.
Отредактируем `lib/example/router.ex` следующим образом:

```elixir
defmodule Example.Router do
  use Plug.Router

  alias Example.Plug.VerifyRequest

  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug VerifyRequest, fields: ["content", "mimetype"], paths: ["/upload"]
  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Добро пожаловать")
  end

  get "/upload" do
    send_resp(conn, 201, "Загружено")
  end

  match _ do
    send_resp(conn, 404, "Ой!")
  end
end
```

В этом участке кода мы указываем нашему веб-приложению перенаправлять входящие запросы через модуль Plug `VerifyRequest` _до того_, как будет выполнен код в модуле-маршрутизаторе.
Это осуществляется вызовом следующей функции:

```elixir
plug VerifyRequest, fields: ["content", "mimetype"], paths: ["/upload"]
```

Здесь автоматически вызывается `VerifyRequest.init(fields: ["content", "mimetype"], paths: ["/upload"])`.
Заданные опции передаются в функцию `VerifyRequest.call(conn, opts)`.

Пришло время посмотреть на работу нашего модуля Plug. Остановите свой локальный сервер (для тех, кто забыл: нажмите `ctrl + c` два раза).
Затем перезагрузите сервер (`mix run --no-halt`).
Перейдите по адресу  <http://127.0.0.1:8080/upload> и вы увидите, что эта страница просто не отображается. Вам будет показана стандартная страница с ошибкой.

Теперь давайте передадим требуемые параметры через запрос <http://127.0.0.1:8080/upload?content=thing1&mimetype=thing2>. Сейчас мы должны увидеть наше сообщение 'Загружено'.

То, что мы _вообще не получаем никакую страницу_ в случае получения ошибочного запроса, нехорошо. Мы разберёмся, как обрабатывать подобные ошибки, несколько позже.

## Делаем HTTP порт конфигурируемым

Когда мы создавали наше приложение `Example`, HTTP порт был "зашит" в коде.
Считается хорошим тоном делать порт конфигурируемым при помощи файлов настроек.

Мы установим переменную среды приложения в `config/config.exs`

```elixir
use Mix.Config

config :example, cowboy_port: 8080
```

Дальше нам нужно обновить `lib/example/application.ex`, получить номер порта и передать это значение веб-серверу Cowboy.
Здесь мы зададим приватную функцию `cowboy_port`, которая будет выполнять эту работу.

```elixir
defmodule Example.Application do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Example.Router, options: [port: cowboy_port()]}
    ]
    opts = [strategy: :one_for_one, name: Example.Supervisor]

    Logger.info("Starting application...")

    Supervisor.start_link(children, opts)
  end

  defp cowboy_port, do: Application.get_env(:example, :cowboy_port, 8080)
end
```

Третий аргумент в `Application.get_env` — это порт по умолчанию на случай, если настройка не объявлена.

Теперь для запуска приложения можно использовать команду:

```shell
mix run --no-halt
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

  @content "<html><body>Привет!</body></html>"
  @mimetype "text/html"

  @opts Router.init([])

  test "returns Добро пожаловать" do
    conn =
      :get
      |> conn("/", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "returns Загружено" do
    conn =
      :get
      |> conn("/upload?content=#{@content}&mimetype=#{@mimetype}")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 201
  end

  test "returns 404" do
    conn =
      :get
      |> conn("/missing", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end
```

И запустим командой:

```shell
mix test test/example/router_test.exs
```

## Plug.ErrorHandler

Ранее мы заметили, что когда мы перешли на <http://127.0.0.1:8080/upload> без ожидаемых параметров, мы не получили удобную страницу с ошибкой или разумный статус HTTP - просто страницу с ошибкой c `500 Internal Server Error`.

Давайте исправим это сейчас, добавив [`Plug.ErrorHandler`](https://hexdocs.pm/plug/Plug.ErrorHandler.html).

Сначала откройте `lib/example/router.ex`, а затем напишите в этот файл следующее.

```elixir
defmodule Example.Router do
  use Plug.Router
  use Plug.ErrorHandler

  alias Example.Plug.VerifyRequest

  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug VerifyRequest, fields: ["content", "mimetype"], paths: ["/upload"]
  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Добро пожаловать")
  end

  get "/upload" do
    send_resp(conn, 201, "Загружено")
  end

  match _ do
    send_resp(conn, 404, "Ой!")
  end

  defp handle_errors(conn, %{kind: kind, reason: reason, stack: stack}) do
    IO.inspect(kind, label: :kind)
    IO.inspect(reason, label: :reason)
    IO.inspect(stack, label: :stack)
    send_resp(conn, conn.status, "Something went wrong")
  end
end
```

Обратите внимание, что в начале листинга мы указываем `use Plug.ErrorHandler`.

Этот модуль Plug обрабатывает все ошибки, а потом вызывает функцию `handle_errors/2`, которая займётся обработкой всех ошибок.

Функция `handle_errors/2` принимает два параметра: `conn` и ассоциативный массив с тремя элементами (`:kind`, `:reason` и `:stack`).

Мы задали очень простую функцию `handle_errors/2`, чтобы были лучше видно происходящее в приложении. Теперь давайте остановим и перезагрузим наше веб-приложение, чтобы увидеть работу этой функции.

По переходу на адрес <http://127.0.0.1:8080/upload> вы увидите заданное вами сообщение об ошибке.

Если обратить внимание на терминал, в котором запущен сервер, то там можно разглядеть что-то наподобие:

```shell
kind: :error
reason: %Example.Plug.VerifyRequest.IncompleteRequestError{message: ""}
stack: [
  {Example.Plug.VerifyRequest, :verify_request!, 2,
   [file: 'lib/example/plug/verify_request.ex', line: 23]},
  {Example.Plug.VerifyRequest, :call, 2,
   [file: 'lib/example/plug/verify_request.ex', line: 13]},
  {Example.Router, :plug_builder_call, 2,
   [file: 'lib/example/router.ex', line: 1]},
  {Example.Router, :call, 2, [file: 'lib/plug/error_handler.ex', line: 64]},
  {Plug.Cowboy.Handler, :init, 2,
   [file: 'lib/plug/cowboy/handler.ex', line: 12]},
  {:cowboy_handler, :execute, 2,
   [
     file: '/path/to/project/example/deps/cowboy/src/cowboy_handler.erl',
     line: 41
   ]},
  {:cowboy_stream_h, :execute, 3,
   [
     file: '/path/to/project/example/deps/cowboy/src/cowboy_stream_h.erl',
     line: 293
   ]},
  {:cowboy_stream_h, :request_process, 3,
   [
     file: '/path/to/project/example/deps/cowboy/src/cowboy_stream_h.erl',
     line: 271
   ]}
]
```

В данный момент мы все еще возвращаем `500 Internal Server Error`. Мы можем настроить код состояния HTTP, добавив поле `: plug_status` к нашему исключению. Откройте `lib/example/plug/verify_request.ex` и добавьте следующее:

```elixir
defmodule IncompleteRequestError do
  defexception message: "", plug_status: 400
end
```

Перезагрузите сервер и обновите страницу, теперь вы получите ответ `400 Bad Request`.

Этот модуль Plug облегчает работу разработчикам, позволяя им получать полезную информацию для исправлению ошибок, и в то же время этот модуль показывает нашим пользователям красивую страничку с ошибкой вместо стандартной "ничего не работает".

## Доступные модули Plug

Много модулей `Plug` доступно для использования сразу "из коробки".
Полный список можно найти в документации по `Plug` — [здесь](https://github.com/elixir-lang/plug#available-plugs).
