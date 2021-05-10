%{
  version: "1.4.1",
  title: "Модули",
  excerpt: """
  Мы все знаем из опыта, насколько неудобно хранить все функции в одном файле и одной области видимости.
В этом уроке мы разберемся как группировать функции и определять специальный ассоциативный массив, известный как `struct`, для более эффективной организации кода.
  """
}
---

## Модули

Модули позволяют организовывать функции по областям видимости.
Кроме группировки функций, они позволяют определять именованные и закрытые функции, которые мы рассмотрели в [уроке о функциях](../functions/).

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

Атрибуты модулей зачастую используются в языке как константы.
Давайте рассмотрим простой пример:

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

Структура - специальный ассоциативный массив с определенным набором ключей и их значениями по умолчанию.
Она должна быть определена в модуле, из которого и берет свое имя.
Часто структура - это единственная вещь, определенная в модуле.

Для определения структуры мы используем конструкцию `defstruct` вместе с ключевым списком полей и значений по умолчанию:

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

Давайте создадим несколько структур:

```elixir
iex> %Example.User{}
%Example.User<name: "Sean", roles: [], ...>

iex> %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [], ...>

iex> %Example.User{name: "Steve", roles: [:manager]}
%Example.User<name: "Steve", roles: [:manager]>
```

Обновление структуры работает так же, как и обновление ассоциативного массива:

```elixir
iex> steve = %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [...], ...>
iex> sean = %{steve | name: "Sean"}
%Example.User<name: "Sean", roles: [...], ...>
```

Что еще более важно, структуры можно сопоставлять с ассоциативными массивами:

```elixir
iex> %{name: "Sean"} = sean
%Example.User<name: "Sean", roles: [...], ...>
```

Начиная с Elixir 1.8 структуры включают в себя пользовательскую интроспекцию. Чтобы понять, что она значит и как следует её использовать, давайте выведем значение переменной `sean`:

```elixir
iex> inspect(sean)
"%Example.User<name: \"Sean\", roles: [...], ...>"
```

В выводе видны все наши поля, что, конечно, хорошо для примера, но что если у нас есть защищённое поле, которое мы не хотим показывать?
Новая директива `@derive` позволяет сделать это!
Давайте обновим пример, чтобы ключ `roles` больше не включался в вывод:

```elixir
defmodule Example.User do
  @derive {Inspect, only: [:name]}
  defstruct name: nil, roles: []
end
```

_Примечание_: также можно использовать `@derive {Inspect, except: [:roles]}` — это то же самое, что и выше.

После обновления модуля давайте посмотрим, что сейчас будет происходить в `iex`:

```elixir
iex> sean = %Example.User<name: "Sean", roles: [...], ...>
%Example.User<name: "Sean", ...>
iex> inspect(sean)
"%Example.User<name: \"Sean\", ...>"
```

Ключ `roles` больше не показывается в выводе!

## Композиция

Теперь, когда мы знаем как создавать модули и структуры в Elixir, давайте рассмотрим как подключать имеющуюся функциональность в них с помощью композиции. Elixir предоставляет множество различных способов взаимодействия с другими модулями.

### alias

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

### import

Если нужно импортировать функции, вместо создания псевдонима модуля можно использовать `import`:

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

Для импорта определенных функций и макросов, мы должны предоставить пары имя/количество аргументов в `:only` и `:except`.
Давайте начнем с импорта функции `last/1`:

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

### require

Чтобы сообщить Elixir, что мы собираемся использовать макросы из другого модуля, можно использовать `require`.
Небольшое отличие от `import` заключается в том, что `require` позволяет использовать только макросы указанного модуля, но не функции.

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

Если же мы попробуем обратиться к макросу, который еще не загружен, Elixir выдаст ошибку.

### use

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
