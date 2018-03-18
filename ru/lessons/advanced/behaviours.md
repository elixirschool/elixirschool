---
version: 1.0.1
title: Поведения
---

В предыдущем уроке мы познакомились со спецификациями, теперь мы узнаем, как можно потребовать от модуля реализовывать определённые спецификации. В Elixir такая функциональность называется поведением.

{% include toc.html %}

## Использование

Иногда необходимо, чтобы модули реализовывали определённое публичное API. В Elixir это достигается при помощи поведений. Поведение выполняет две основные задачи:

+ Определяет набор функций, которые должны быть реализованы
+ Контролирует, чтобы эти функции действительно были реализованы

Elixir уже включает некоторое количество поведений, например `GenServer`, но в данном уроке мы сосредоточимся на создании нашего собственного поведения.

## Определяем поведение

Чтобы лучше понять поведения, определим поведение для модуля создающего рабочий процесс. Рабочие процессы должны будут реализовывать две функции: `init/1` и `perform/2`.

Для решения этой задачи используем директиву `@callback`, её синтаксис аналогичен директиве `@spec`. Директива помогает описать __требуемый__ метод. Для макросов существует другая директива &mdash; `@macrocallback`. Зададим методы `init/1` и `perform/2` для наших рабочих процессов:

```elixir
defmodule Example.Worker do
  @callback init(state :: term) :: {:ok, new_state :: term} | {:error, reason :: term}
  @callback perform(args :: term, state :: term) ::
              {:ok, result :: term, new_state :: term}
              | {:error, reason :: term, new_state :: term}
end
```

Здесь мы задали `init/1` как метод, который может принимать любое значение в качестве аргумента и возвращать кортеж вида `{:ok, state}` либо `{:error, reason}` &mdash; это довольно стандартное определение. Метод `perform/2` будет принимать аргументы для рабочего процесса вместе с заданным начальным состоянием. Мы ожидаем, что `perform/2` вернёт `{:ok, result, state}` либо `{:error, reason, state}`, подобно `GenServer`.

## Используем поведение

Теперь, когда мы определили поведение, можно использовать его для создания разнообразных модулей, реализующих общее публичное API. Добавить поведение в модуль можно при помощи атрибута `@behaviour`.

Используем поведение, создав модуль для скачивания и сохранения файла на диск:

```elixir
defmodule Example.Downloader do
  @behaviour Example.Worker

  def init(opts), do: {:ok, opts}

  def perform(url, opts) do
    url
    |> HTTPoison.get!()
    |> Map.fetch(:body)
    |> write_file(opts[:path])
    |> respond(opts)
  end

  defp write_file(:error, _), do: {:error, :missing_body}

  defp write_file({:ok, contents}, path) do
    path
    |> Path.expand()
    |> File.write(contents)
  end

  defp respond(:ok, opts), do: {:ok, opts[:path], opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

А как насчет рабочего процесса, который выполняет сжатие файлов, переданных ему в виде массива? Такое тоже возможно:

```elixir
defmodule Example.Compressor do
  @behaviour Example.Worker

  def init(opts), do: {:ok, opts}

  def perform(payload, opts) do
    payload
    |> compress
    |> respond(opts)
  end

  defp compress({name, files}), do: :zip.create(name, files)

  defp respond({:ok, path}, opts), do: {:ok, path, opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

Несмотря на то, что данные модули выполняют различные задачи, они реализуют одинаковое публичное API. Любой код может взаимодействовать с ними, заранее зная, что интерфейс будет соответствовать заданному шаблону. Это даёт нам возможность написать любое количество рабочих процессов, выполняющих различные задачи, но имеющих общий интерфейс.

Если же мы добавим в модуль поведение, но не реализуем все требуемые им функции, то получим предупреждение во время компиляции кода. Для того чтобы увидеть это в действии, модифицируем наш пример `Example.Compressor`, удалив из него функцию `init/1`:

```elixir
defmodule Example.Compressor do
  @behaviour Example.Worker

  def perform(payload, opts) do
    payload
    |> compress
    |> respond(opts)
  end

  defp compress({name, files}), do: :zip.create(name, files)

  defp respond({:ok, path}, opts), do: {:ok, path, opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

Теперь во время компиляции кода мы получим предупреждение вида:

```shell
lib/example/compressor.ex:1: warning: undefined behaviour function init/1 (for behaviour Example.Worker)
Compiled lib/example/compressor.ex
```

Это всё! Теперь вы готовы создавать и делиться своими поведениями с другими.
