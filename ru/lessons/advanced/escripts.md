---
version: 1.0.2
title: Исполняемые файлы
---

Для сборки исполняемых файлов в Elixir мы будем использовать escript.
Escript создаёт исполняемый файл, который может быть запущен на любой системе с предустановленным Erlang.

{% include toc.html %}

## Начало работы

Для создания исполняемого файла с помощью escript нужно сделать совсем немного: имплементировать метод `main/1` и обновить наш Mixfile.

Начнём с создания модуля, используемого в качестве точки входа в наш исполняемый файл.
Именно здесь мы и создадим `main/1`:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    # Делаем что-нибудь
  end
end
```

Далее нам надо обновить наш Mixfile &mdash; включить `:escript` для нашего проекта, а также указать `:main_module`:

```elixir
defmodule ExampleApp.Mixfile do
  def project do
    [app: :example_app, version: "0.0.1", escript: escript()]
  end

  defp escript do
    [main_module: ExampleApp.CLI]
  end
end
```

## Разбор аргументов

Наше приложение настроено, и теперь мы можем заняться разбором аргументов из командной строки.
Для этого воспользуемся `OptionParser.parse/2` Elixir'а с опцией `:switches` и укажем, что наш флаг логического типа:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    args
    |> parse_args
    |> response
    |> IO.puts()
  end

  defp parse_args(args) do
    {opts, word, _} =
      args
      |> OptionParser.parse(switches: [upcase: :boolean])

    {opts, List.to_string(word)}
  end

  defp response({opts, word}) do
    if opts[:upcase], do: String.upcase(word), else: word
  end
end
```

## Сборка

Как только мы закончили настройку нашего приложения для использования escript, до сборки исполняемого файла остался всего один шаг с Mix:

```bash
$ mix escript.build
```

Давайте попробуем:

```bash
$ ./example_app --upcase Hello
HELLO

$ ./example_app Hi
Hi
```

Вот и всё.
Мы только что сделали наш первый исполняемый файл на Elixir, используя escript.
