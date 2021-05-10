---
version: 1.2.0
title: Пользовательские Mix-задачи
---

Создание пользовательских Mix-задач для ваших Elixir проектов.

{% include toc.html %}

## Введение

Обычной практикой считается расширение возможностей приложений Elixir при помощи пользовательских Mix-задач.
Прежде чем мы научимся создавать Mix-задачи специально для наших проектов, давайте взглянем на одну уже существующую:

```shell
$ mix phx.new my_phoenix_app

* creating my_phoenix_app/config/config.exs
* creating my_phoenix_app/config/dev.exs
* creating my_phoenix_app/config/prod.exs
* creating my_phoenix_app/config/prod.secret.exs
* creating my_phoenix_app/config/test.exs
* creating my_phoenix_app/lib/my_phoenix_app.ex
* creating my_phoenix_app/lib/my_phoenix_app/endpoint.ex
* creating my_phoenix_app/test/views/error_view_test.exs
...
```

Как можно понять из вышеуказанной консольной команды, у фреймворка Phoenix есть Mix-задача для генерации нового проекта.
Можем ли мы сделать что-то похожее для нашего проекта? Отличная новость &mdash; мы можем, и это очень просто благодаря Elixir.

## Настройка

Давайте создадим простое Mix-приложение.

```shell
$ mix new hello

* creating README.md
* creating .formatter.exs
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/hello.ex
* creating test
* creating test/test_helper.exs
* creating test/hello_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

cd hello
mix test

Run "mix help" for more commands.
```

Теперь в сгенерированном файле **lib/hello.ex** создадим простую функцию, которая выводит на экран "Hello, World!".

```elixir
defmodule Hello do
  @doc """
  Выводит на экран `Hello, World!`.
  """
  def say do
    IO.puts("Hello, World!")
  end
end
```

## Пользовательские Mix-задачи

Давайте создадим пользовательскую Mix-задачу.
Создайте новую директорию и файл **hello/lib/mix/tasks/hello.ex**.
В этом файле напишем следующие 7 строк кода на Elixir.

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Просто вызывает функцию Hello.say/0."
  def run(_) do
    # вызываем функцию Hello.say(), описанную ранее
    Hello.say()
  end
end
```

Обратите внимание: мы начинаем выражение `defmodule` с `Mix.Tasks` и имени, при помощи которого мы хотим вызывать нашу команду.
На второй строке мы используем `use Mix.Task`, чтобы добавить поведение `Mix.Task` в наше пространство имён.
Далее напишем функцию, которая пока не принимает аргументы.
Внутри этой функции вызовем функцию `say` модуля `Hello`.

## Загрузка вашего приложения

Mix не запускает наше приложение автоматически или какие-либо его зависимости, что хорошо для многих сценариев использования задач Mix, но что, если нам нужно использовать Ecto и взаимодействовать с базой данных? В этом случае нам нужно убедиться, что приложение, стоящее за Ecto.Repo, запущено. У нас есть два способа справиться с этим: явная инициализация конкретного приложения или инициализация всего нашего приложения, которое, в свою очередь, инициализирует все остальные зависимости.

Давайте посмотрим, как мы можем обновить нашу Mix-задачу, чтобы запустить наше приложение и зависимости:

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Simply calls the Hello.say/0 function."
  def run(_) do
    # This will start our application
    Mix.Task.run("app.start")

    Hello.say()
  end
end
```

## Использование Mix-задач

Давайте проверим.
Мы находимся в той же директории, поэтому задача должна сработать.
Выполним `mix hello` в командной строке и увидим следующее:

```shell
$ mix hello
Hello, World!
```

Mix обладает достаточно дружественным интерфейсом.
Он понимает, что все порой допускают ошибки, и поэтому использует технику неполного соответствия строк, чтобы предлагать рекомендации:

```shell
$ mix hell
** (Mix) The task "hell" could not be found. Did you mean "hello"?
```

Наверняка вы заметили новый атрибут `@shortdoc`. Он может пригодится при использовании нашего приложения, например, когда пользователь выполнит команду `mix help` в терминале.

```shell
$ mix help

mix app.start         # Starts all registered apps
...
mix hello             # Просто выполняет команду Hello.say/0.
...
```

Обратите внимание: наш код должен быть скомпилирован, прежде чем новые задачи появятся в выводе `mix help`.
Это можно сделать либо запустив `mix compile` напрямую, либо запустив нашу задачу, как мы сделали с `mix hello`, что запустит компиляцию за нас.
