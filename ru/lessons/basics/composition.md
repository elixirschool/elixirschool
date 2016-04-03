---
layout: page
title: Композиция
category: basics
order: 8
lang: ru
---

Мы все знаем из опыта, насколько неудобно хранить все функции в одном файле и одной области видимости. В этом уроке мы разберемся как группировать функции и определять специальный ассоциативный массив, называющийся `struct`, для более эффективной организации кода.

## Содержание

- [Модули](#section-1)
  - [Атрибуты модулей](#section-2)
- [Структуры](#section-3)
- [Композиция](#section-4)
  - [`alias`](#alias)
  - [`import`](#import)
  - [`require`](#require)
  - [`use`](#use)

## Модули

Модули - лучший способ для организации функций по областям видимости. Кроме группировки функций они позволяют определять именованные и закрытые функции, которые мы рассмотрели в предыдущем уроке.

Давайте рассмотрим простой пример:

``` elixir
defmodule Example do
  def greeting(name) do
    ~s(Hello #{name}.)
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
+ `doc` — Документация для функций и макросов.
+ `behaviour` — Использование OTP или определенного пользователем поведения.

## Структуры

Структура - специальный ассоциативный массив с определенным набором ключей и их значениями по умолчанию. Она должна быть определена в модуле, из которого и берет свое имя. Часто структура - это единственная вещь, определенная в модуле.

Для определения структуры мы используем конструкцию `defstruct` вместе с списком с ключами полей и значений по умолчанию:

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
  def greeting(name), do: Saying.Greetings.basic(name)
end
```

Если есть конфликт между двумя псевдонимами или нужно сделать псевдоним на произвольное имя - можно использовать переключатель `:as`:

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

Если удобнее импортировать функции и макросы в текущую область видимости вместо короткой записи - можно использовать `import/`:

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

Если импортировать все кроме `last/1` и попробовать тот же код, что и раньше:

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

Важным, но реже применяемым, является вызов `require/2`. Он позволяет убедится, что модуль скомпилирован и загружен. Это полезно в тех случаях, когда нужно обратится к макросу:

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

Если же мы попробуем обратится к макросу, который еще не загружен, Elixir выдаст ошибку.

### `use`

Подключает модуль в текущий контекст. Это применяется в случаях, когда модулю нужна какая-либо подготовка. Используя `use`, мы вызываем функцию `__using__` из этого модуля, и он может изменить текующий контекст:

```elixir
defmodule MyModule do
  defmacro __using__(opts) do
    quote do
      import MyModule.Foo
      import MyModule.Bar
      import MyModule.Baz

      alias MyModule.Repo
    end
  end
end
```
