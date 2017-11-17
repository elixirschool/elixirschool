---
version: 1.2.0
title: Композиция
---

Мы все знаем из опыта, насколько неудобно хранить все функции в одном файле и одной области видимости. В этом уроке мы разберемся как группировать функции и определять специальный ассоциативный массив, известный как `struct`, для более эффективной организации кода.

{% include toc.html %}

## Модули

Модули позволяют организовывать функции по областям видимости. Кроме группировки функций, они позволяют определять именованные и закрытые функции, которые мы рассмотрели в [уроке о функциях](../functions/).

Давайте рассмотрим простой пример:

``` elixir
defmodule Example do
  def greeting(name) do
    "Hello #{name}."
  end
end

iex> Example.greeting "Sean"
"Hello Sean."
```

Можно создавать вложенные модули, что позволяет еще сильнее разбивать функциональность на пространства имен:

```elixir
defmodule Example.Greetings do
  def morning(name) do
    "Good morning #{name}."
  end

  def evening(name) do
    "Good night #{name}."
  end
end

iex> Example.Greetings.morning "Sean"
"Good morning Sean."
```

### Атрибуты модулей

Атрибуты модулей зачастую используются в языке как константы. Давайте рассмотрим простой пример:

```elixir
defmodule Example do
  @greeting "Hello"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

Важно помнить, что есть несколько зарезервированных названий атрибутов в Elixir. Три самые часто используемые:

+ `moduledoc` — Документирует текущий модуль.
+ `doc` — Документация функций и макросов.
+ `behaviour` — Использование OTP или определенного пользователем поведения.

## Структуры

Структура - специальный ассоциативный массив с определенным набором ключей и их значениями по умолчанию. Она должна быть определена в модуле, из которого и берет свое имя. Часто структура - это единственная вещь, определенная в модуле.

Для определения структуры мы используем конструкцию `defstruct` вместе с ключевым списком полей и значений по умолчанию:

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

Давайте создадим несколько структур:

```elixir
iex> %Example.User{}
%Example.User{name: "Sean", roles: []}

iex> %Example.User{name: "Steve"}
%Example.User{name: "Steve", roles: []}

iex> %Example.User{name: "Steve", roles: [:admin, :owner]}
%Example.User{name: "Steve", roles: [:admin, :owner]}
```

Обновление структуры работает так же, как и обновление ассоциативного массива:

```elixir
iex> steve = %Example.User{name: "Steve", roles: [:admin, :owner]}
%Example.User{name: "Steve", roles: [:admin, :owner]}
iex> sean = %{steve | name: "Sean"}
%Example.User{name: "Sean", roles: [:admin, :owner]}
```

Что еще более важно, структуры можно сопоставлять с ассоциативными массивами:

```elixir
iex> %{name: "Sean"} = sean
%Example.User{name: "Sean", roles: [:admin, :owner]}
```

## Композиция

Теперь, когда мы знаем как создавать модули и структуры в Elixir, давайте рассмотрим как подключать имеющуюся функциональность в них с помощью композиции. Язык предоставляет множество различных способов взаимодействия с другими модулями. Давайте рассмотрим их подробнее.

### `alias`

Позволяет использовать сокращенное именование модулей, используется довольно часто:

```elixir
defmodule Sayings.Greetings do
  def basic(name), do: "Hi, #{name}"
end

defmodule Example do
  alias Sayings.Greetings

  def greeting(name), do: Greetings.basic(name)
end

# Без alias

defmodule Example do
  def greeting(name), do: Sayings.Greetings.basic(name)
end
```

Если есть конфликт между двумя псевдонимами или нужно сделать псевдоним на произвольное имя - можно использовать опцию `:as`:

```elixir
defmodule Example do
  alias Sayings.Greetings, as: Hi

  def print_message(name), do: Hi.basic(name)
end
```

Также можно использовать эту возможность для нескольких модулей за раз:

```elixir
defmodule Example do
  alias Sayings.{Greetings, Farewells}
end
```

### `import`

Если нужно импортировать функции и макросы, вместо создания псевдонима модуля можно использовать `import/`:

```elixir
iex> last([1, 2, 3])
** (CompileError) iex:9: undefined function last/1
iex> import List
nil
iex> last([1, 2, 3])
3
```

#### Фильтрация

По умолчанию импортируются все функции и макросы, но можно сократить это количество с использованием опций `:only` и `:except`.

Для импорта определенных функций и макросов, мы должны предоставить пары имя/количество аргументов в `:only` и `:except`. Давайте начнем с импорта функции `last/1`:

```elixir
iex> import List, only: [last: 1]
iex> first([1, 2, 3])
** (CompileError) iex:13: undefined function first/1
iex> last([1, 2, 3])
3
```

Если импортировать все, кроме `last/1`, и попробовать тот же код, что и раньше:

```elixir
iex> import List, except: [last: 1]
nil
iex> first([1, 2, 3])
1
iex> last([1, 2, 3])
** (CompileError) iex:3: undefined function last/1
```

Вдобавок к указанию определенной сигнатуры функции, существует два специальных атома - `:functions` и `:macros`, которые импортируют только функции и макросы соответственно:

```elixir
import List, only: :functions
import List, only: :macros
```

### `require`

Важным, но реже применяемым, является вызов `require/2`. Он позволяет убедиться, что модуль скомпилирован и загружен. Это полезно в тех случаях, когда нужно обратиться к макросу модуля:

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

Если же мы попробуем обратиться к макросу, который еще не загружен, Elixir выдаст ошибку.

### `use`

С помощью макроса `use` мы можем использовать другой модуль, чтобы изменить определение нашего текущего модуля.
Когда мы вызываем `use` в коде, на самом деле мы обращаемся к функции обратного вызова `__using__/1`, объявленной в указанном модуле.
Результат выполнения макроса `__using__/1` становится частью определения нашего модуля.
Чтобы получше разобраться, как это работает, взглянем на простой пример:

```elixir
defmodule Hello do
  defmacro __using__(_opts) do
    quote do
      def hello(name), do: "Hi, #{name}"
    end
  end
end
```

Здесь мы создали модуль `Hello`, определяющий функцию обратного вызова `__using__/1`, внутри которой объявлена функция `hello/1`.
Создадим ещё один модуль, чтобы попробовать наш новый код:

```elixir
defmodule Example do
  use Hello
end
```

Запустив наш код в IEx, мы увидим, что функция `hello/1` доступна из модуля `Example`:

```elixir
iex> Example.hello("Sean")
"Hi, Sean"
```

Итак, мы видим, что `use` вызвала функцию обратного вызова `__using__/1` в `Hello`, а та, в свою очередь, добавила итоговый код в наш модуль.
Теперь, когда мы разобрали простой пример, обновим код, чтобы посмотреть, как `__using__/1` поддерживает опции.
Сделаем это, добавив опцию `greeting`:

```elixir
defmodule Hello do
  defmacro __using__(opts) do
    greeting = Keyword.get(opts, :greeting, "Hi")

    quote do
      def hello(name), do: unquote(greeting) <> ", " <> name
    end
  end
end
```

Также обновим модуль `Example`, включив в него свежесозданную опцию `greeting`:

```elixir
defmodule Example do
  use Hello, greeting: "Hola"
end
```

Запустив это в IEx, мы увидим, что приветствие изменилось:

```
iex> Example.hello("Sean")
"Hola, Sean"
```

Эти примеры были простыми, чтобы просто продемонстрировать, как работает `use`, однако это невероятно сильное средство из набора инструментов Elixir.
Продолжая изучать Elixir, обращайте внимание на `use`. Один пример, который точно попадётся на пути &mdash; это `use ExUnit.Case, async: true`.

**Примечание**: макросы `quote`, `alias`, `use`, `require` используются при работе с [метапрограммированием](../../advanced/metaprogramming).
