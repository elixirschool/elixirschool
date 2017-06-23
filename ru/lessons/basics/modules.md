---
version: 1.1.0
layout: page
title: Композиция
category: basics
order: 8
lang: ru
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

Макрос `use` вызывает специальный макрос `__using__/1` из указанного модуля. Вот пример:

```elixir
# lib/use_import_require/use_me.ex
defmodule UseImportRequire.UseMe do
  defmacro __using__(_) do
    quote do
      def use_test do
        IO.puts "use_test"
      end
    end
  end
end
```

добавляем следующую строку в UseImportRequire:

```elixir
use UseImportRequire.UseMe
```

UseImportRequire.UseMe определяет функцию use_test/0 посредством вызова макроса `__using__/1`.

Это всё, что `use` делает. Однако, часто для макроса `__using__` вызывается `alias`, `require`, или `import`. Это, в свою очередь, создает псевдонимы или импорты в используемом модуле. Данная возможность позволяет использовать модуль для определения политики о том как следует ссылаться на его функции и макросы. Может оказаться довольно гибким, что `__using__/1` имеет возможность устанавливать ссылки на другие модули и подмодули.

Фреймворк Phoenix использует `use` и `__using__/1`, чтобы сократить необходимость в повторных псевдонимах и импорте вызовов в определенных пользователем модулях.

Вот хороший и короткий пример из модуля Ecto.Migration:

```elixir
defmacro __using__(_) do
  quote location: :keep do
    import Ecto.Migration
    @disable_ddl_transaction false
    @before_compile Ecto.Migration
  end
end
```

Макрос `Ecto.Migration.__using__/1` содержит вызов импорта, поэтому, когда происходит вызов `use Ecto.Migration`, также вызывается `import Ecto.Migration`. Вдобавок, он устанавливает свойство модуля, которое будет использовано для управления поведением Ecto.

Напоминаем: макрос `use` просто вызывает макрос `__using__/1` указанного модуля. Чтобы узнать, что он делает, необходимо изучить `__using__/1`.

**Примечание**: макросы `quote`, `alias`, `use`, `require` используются при работе с [метапрограммированием](../../advanced/metaprogramming).
