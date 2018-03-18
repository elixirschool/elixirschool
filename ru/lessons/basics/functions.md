---
version: 1.0.1
title: Функции
---

В Elixir, как и в многих других функциональных языках, функции являются полноценными объектами. В этом уроке мы рассмотрим типы функций в Elixir, чем они отличаются и как их использовать.

{% include toc.html %}

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
  def of([_ | tail]), do: 1 + of(tail)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### Наименования и арность функций

Ранее мы отмечали, что функции именуются путём сочетания имени и арности (количества аргументов). Это позволяет делать такое:

```elixir
defmodule Greeter2 do
  def hello(), do: "Hello, anonymous person!"   # hello/0
  def hello(name), do: "Hello, " <> name        # hello/1
  def hello(name1, name2), do: "Hello, #{name1} and #{name2}"
                                                # hello/2
end

iex> Greeter2.hello()
"Hello, anonymous person!"
iex> Greeter2.hello("Fred")
"Hello, Fred"
iex> Greeter2.hello("Fred", "Jane")
"Hello, Fred and Jane"
```

В комментариях к функциям мы привели их наименования. Первая функция не принимает аргументы, потому описывается как `hello/0`; вторая принимает один параметр, потому описывается как `hello/1`, и т.д. В отличие от перегрузки функций в некоторых других языках, в нашем случае функции стоит считать _разными_ . (Сопоставление с образцом, описанное ранее, применяется только в случае, когда для функций с _одинаковым_ количеством аргументов предоставлены несколько различных описаний.)

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
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### Ограничители

Мы уже затрагивали ограничители в главе [Управляющие конструкции](../control-structures), теперь же рассмотрим их применение в именованных функциях. Ограничители проверяются только после того как Elixir сопоставил функцию.

В следующем примере у нас есть две функции с одинаковыми сигнатурами. Мы используем ограничители для определения какую из них использовать на основе типа аргумента:

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase() <> name
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
  def hello(name, language_code \\ "en") do
    phrase(language_code) <> name
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
  def hello(names, language_code \\ "en") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code \\ "en") when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) iex:31: definitions with multiple clauses and default values require a header. Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b) do ... end

one should write:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end

def hello/2 has multiple clauses and defines defaults in one or more clauses
    iex:31: (module)
```

Elixir не поддерживает аргументы по умолчанию при наличии нескольких подходящих функций. Для решения этой проблемы мы добавляем определение функции с аргументами по умолчанию:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en")

  def hello(names, language_code) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code) when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "es"
"Hola, Sean, Steve"
```
