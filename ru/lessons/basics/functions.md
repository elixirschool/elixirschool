---
layout: page
title: Функции
category: basics
order: 7
lang: ru
---

В Elixir, как и в многих других функциональных языках, функции являются полноценными объектами. В этом уроке мы рассмотрим типы функций в Elixir, чем они отличаются и как их использовать.

## Содержание

- [Анонимные функции](#section-1)
  - [Краткий синтаксис](#section-2)
- [Сопоставление с образцом](#section-3)
- [Именованные функции](#section-4)
  - [Закрытые функции](#section-5)
  - [Ограничители](#section-6)
  - [Аргументы по умолчанию](#section-7)

## Анонимные функции

Как и следует из названия, у анонимной функции нет имени. В уроке `Enum` было показано что они часто используются в качестве параметров других функций. Для определения анонимной функции в Elixir используются ключевые слова `fn` и `end`. Между ними можно определить любое количество параметров и тел функции (function body), разделённых `->`.

Давайте рассмотрим простой пример:

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### Краткий синтаксис

Анонимные функции используются в языке очень часто. Потому для них было создано специальное сокращение:

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

Как вы уже могли догадаться, в сокращенной версии параметры доступны как  `&1`, `&2`, `&3` и так далее.

## Сопоставление с образцом

Сопоставление с образцом в Elixir применяется не только для сопоставления переменных. Этот же инструмент используется в объявлении функций.

Elixir использует сопоставление с образцом для определения первого подходящего набора параметров и вызывает соответствующую имплементацию:

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
iex> handle_result.({:ok, some_result})
Handling result...

iex> handle_result.({:error})
An error has occurred!
```

## Именованные функции

Можно определять именованные функции для дальнейшего их вызова по этим именам. Эти функции объявляются с помощью ключевого слова `def` в контексте модуля. Про модули будет подробнее рассказано в следующих уроках, в этом мы сосредоточимся только на именованных функциях.

Функции, определенные в модуле, доступны из других модулей:

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

Если функция однострочная, то ее описание можно сократить с использованием `do:`:

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

Уже разобравшись в сопоставлении с образцом, давайте рассмотрим пример рекурсии с использованием именованных функций:

```elixir
defmodule Length do
  def of([]), do: 0
  def of([_|t]), do: 1 + of(t)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### Закрытые функции

Когда мы не хотим давать доступ к функции из других модулей, мы определяем закрытые (private) функции. Они могут быть вызваны только из этого же модуля. Такие функции определяются с помощью `defp`:

```elixir
defmodule Greeter do
  def hello(name), do: phrase <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) undefined function: Greeter.phrase/0
    Greeter.phrase()
```

### Ограничители

Мы уже затрагивали ограничители в главе [Управляющие конструкции](../control-structures.md), теперь же рассмотрим их применение в именованных функциях. Ограничители проверяются только после того как Elixir сопоставил функцию.

В следующем примере у нас есть две функции с одинаковыми сигнатурами. Мы используем ограничители для определения какую из них использовать на основе типа аргумента:

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase <> name
  end

  defp phrase, do: "Hello, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"
```

### Аргументы по умолчанию

Когда мы хотим иметь некое значение по умолчанию у аргумента - используется синтаксис `argument \\ value`:

```elixir
defmodule Greeter do
  def hello(name, country \\ "en") do
    phrase(country) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello("Sean", "en")
"Hello, Sean"

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.hello("Sean", "es")
"Hola, Sean"
```

Когда мы используем одновременно ограничители и аргументы по умолчанию, то все перестает работать. Давайте посмотрим как это выглядит:

```elixir
defmodule Greeter do
  def hello(names, country \\ "en") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(country)
  end

  def hello(name, country \\ "en") when is_binary(name) do
    phrase(country) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) def hello/2 has default values and multiple clauses, define a function head with the defaults
```

Elixir не поддерживает аргументы по умолчанию при наличии нескольких подходящих функций. Для решения этой проблемы мы добавляем определение функции с аргументами по умолчанию:

```elixir
defmodule Greeter do
  def hello(names, country \\ "en")
  def hello(names, country) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(country)
  end

  def hello(name, country) when is_binary(name) do
    phrase(country) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "es"
"Hola, Sean, Steve"
```
