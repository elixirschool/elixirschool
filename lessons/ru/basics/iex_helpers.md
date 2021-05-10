---
version: 1.0.2
title: IEx функции
---

{% include toc.html %}

## Введение

Когда вы начинаете писать код на Elixir, IEx - ваш лучший друг.
Это REPL и она имеет много дополнительных возможностей, которые сделают жизнь легче когда осваиваете новый код или по ходу работы.
В ней множество встроенных функций-помощников и мы пройдем их в этом уроке.

### Автодополнение

Когда идет работа в командной строке, вы часто можете использовать новый незнакомый модуль.
Чтобы понять что в нем доступно, функционал автодополнения вам в помощь.
Просто введите название модуля, затем `.` и нажмите `Tab`:

```elixir
iex> Map. # нажмите Tab
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
replace!/3           replace/3            split/2
take/2               to_list/1            update!/3
update/4             values/1
```

Теперь мы знаем какие функции там есть и их арность!

### `.iex.exs`

Каждый раз когда запускается IEx, система ищет файл конфигурации `.iex.exs`.
Если его нет в текущей директории, тогда идет поиск в домашней директории (`~/.iex.exs`) будет использован как резервный.

Опции конфигурации и код объявленный в этом файле будет доступен нам когда IEx запустится.
Например, если мы хотим добавить функцию-помощник в IEx, мы можем открыть `.iex.exs` и внести изменения.

Начнем с добавления модуля с несколькими такими помощниками:

```elixir
defmodule IExHelpers do
  def whats_this?(term) when is_nil(term), do: "Type: Nil"
  def whats_this?(term) when is_binary(term), do: "Type: Binary"
  def whats_this?(term) when is_boolean(term), do: "Type: Boolean"
  def whats_this?(term) when is_atom(term), do: "Type: Atom"
  def whats_this?(_term), do: "Type: Unknown"
end
```

Теперь когда мы запустим IEx, наш модуль IExHelpers будет доступен.
Откройте IEx и давайте повызываем новые функции:

```elixir
$ iex
{{ site.erlang.OTP }} [{{ site.erlang.erts }}] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex> IExHelpers.whats_this?("a string")
"Type: Binary"
iex> IExHelpers.whats_this?(%{})
"Type: Unknown"
iex> IExHelpers.whats_this?(:test)
"Type: Atom"
```

Как мы видим, нам не нужно делать что-то дополнительно чтобы импортировать наши помощники, IEx делает это за нас.

### `h`

`h` это один из часто используемых инструментов в командной строке Elixir.
Поскольку в языке есть поддержка документации первого класса, эта документация будет доступна для любого кода, к которому доберется эта функция-помощник.
В действии это просто:

```elixir
iex> h Enum
                                      Enum

Provides a set of algorithms that enumerate over enumerables according to the
Enumerable protocol.

┃ iex> Enum.map([1, 2, 3], fn(x) -> x * 2 end)
┃ [2, 4, 6]

Some particular types, like maps, yield a specific format on enumeration.
For example, the argument is always a {key, value} tuple for maps:

┃ iex> map = %{a: 1, b: 2}
┃ iex> Enum.map(map, fn {k, v} -> {k, v * 2} end)
┃ [a: 2, b: 4]

Note that the functions in the Enum module are eager: they always start the
enumeration of the given enumerable.
The Stream module allows lazy enumeration
of enumerables and provides infinite streams.

Since the majority of the functions in Enum enumerate the whole enumerable and
return a list as a result, infinite streams need to be carefully used with such
functions, as they can potentially run forever.
For example:

┃ Enum.each Stream.cycle([1, 2, 3]), &IO.puts(&1)
```

И теперь мы можем даже комбинировать это с автодополнением.
Представьте что мы видим впервые модуль Map:

```elixir
iex> h Map
                                      Map

A set of functions for working with maps.

Maps are key-value stores where keys can be any value and are compared using
the match operator (===).
Maps can be created with the %{} special form defined
in the Kernel.SpecialForms module.

iex> Map.
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
split/2              take/2               to_list/1
update!/3            update/4             values/1

iex> h Map.merge/2
                             def merge(map1, map2)

Merges two maps into one.

All keys in map2 will be added to map1, overriding any existing one.

If you have a struct and you would like to merge a set of keys into the struct,
do not use this function, as it would merge all keys on the right side into the
struct, even if the key is not part of the struct.
Instead, use
Kernel.struct/2.

Examples

┃ iex> Map.merge(%{a: 1, b: 2}, %{a: 3, d: 4})
┃ %{a: 3, b: 2, d: 4}
```

Как мы видим документация доступна не только для модулей, но и для отдельных функций, множество которых имеют примеры использования.

### `i`

Давайте применим новые знания о помощнике `h` чтобы узнать о функции-помощнике `i`:

```elixir
iex> h i

                                  def i(term)

Prints information about the given data type.

iex> i Map
Term
  Map
Data type
  Atom
Module bytecode
  /usr/local/Cellar/elixir/1.3.3/bin/../lib/elixir/ebin/Elixir.Map.beam
Source
  /private/tmp/elixir-20160918-33925-1ki46ng/elixir-1.3.3/lib/elixir/lib/map.ex
Version
  [9651177287794427227743899018880159024]
Compile time
  no value found
Compile options
  [:debug_info]
Description
  Use h(Map) to access its documentation.
  Call Map.module_info() to access metadata.
Raw representation
  :"Elixir.Map"
Reference modules
  Module, Atom
```

Теперь мы узнали о `Map` включая где находится исходный код и модули на которые `Map` ссылается.
Это довольно полезно при изучении пользовательских, чужих типов данных и новых функций.

Отдельные заголовки могут быть неочевидными, но с высокого уровня можно получить уместную информацию:

- Тип данных - атом
- Где находится исходный код
- Версия и опции при компиляции
- Общее описание
- Как получить документацию о модуле
- На какие другие модули ссылается

Это уже дает нам много для работы, лучше чем идти вслепую.

### `r`

Если мы хотим перекомпилировать определенный модуль, можем использовать функцию `r`.
Предположим, мы изменили код и ходим вызвать новую функцию, которую только что добавили.
Чтобы сделать это нужно сохранить изменения и перекомпилировать с `r`:

```elixir
iex> r MyProject
warning: redefining module MyProject (current version loaded from _build/dev/lib/my_project/ebin/Elixir.MyProject.beam)
  lib/my_project.ex:1

{:reloaded, MyProject, [MyProject]}
```

### `t`

Помощник `t` показывает о доступных типах модуля:

```elixir
iex> t Map
@type key() :: any()
@type value() :: any()
```

И мы знаем что `Map` определяет `key` и `value` типы в ее реализации.
Если проверим в исходном коде `Map`:

```elixir
defmodule Map do
# ...
  @type key :: any
  @type value :: any
# ...
```

Это простой пример показывает что `key` и `value` в зависимости от реализации могут быть `any` типа, полезно знать.
Используя все эти встроенные плюшки мы можем легко осваивать новый код и изучать как работают вещи.
IEx очень мощный и надежный инструмент который дает дополнительную силу разработчикам.
С этим набором инструментов, изучение и программирование может быть еще веселее!
