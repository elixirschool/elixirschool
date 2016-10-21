---
layout: page
title: Mnesia
category: specifics
order: 5
lang: ru
---

Mnesia &mdash; это распределённая система управления базами данных реального времени.

{% include toc.html %}

## Обзор

Mnesia &mdash; это система управления базами данных (СУБД), поставляемая вместе с Erlang Runtime System. Естественно, мы можем использовать её в Elixir. Благодаря *реляционной гибридной объектной модели данных* Mnesia подходит для распределённых приложений любого масштаба.

## Когда использовать?

Вопрос выбора конкретной технологии зачастую сбивает с толку. Если вы ответите "да" на любой из следующих вопросов, то это хороший знак, что стоит использовать Mnesia, а не ETS или DETS.

  - Нужен ли мне откат транзакций?
  - Нужен ли мне простой синтаксис для чтения и записи данных?
  - Нужно ли мне хранить данные в нескольких нодах?
  - Нужно ли мне выбирать, где хранить данные &mdash; в RAM или на диске?

## Схема

Mnesia &mdash; это часть ядра Erlang, а не Elixir, поэтому мы обращаемся к ней через двоеточие (см. урок: [Взаимодействие с Erlang](../../advanced/erlang/)):

```shell

iex> :mnesia.create_schema([node()])

# или если вам по душе стиль Elixir

iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
```

В этом уроке мы будем использовать второй способ при работе с Mnesia API. `Mnesia.create_schema/1` инициализирует новую пустую схему и передаёт список нод. В данном случае мы передаём ноду, связанную с нашей IEx-сессией.

## Ноды

После выполнения команды `Mnesia.create_schema([node()])` в текущей директории вы увидите папку с именем **Mnesia.nonode@nohost**. Наверняка, вам интересно, что же значит **nonode@nohost**, потому что мы не обсуждали это ранее. Давайте посмотрим:

```shell
$ iex --help
Usage: iex [options] [.exs file] [data]

  -v                Prints version
  -e "command"      Evaluates the given command (*)
  -r "file"         Requires the given files/patterns (*)
  -S "script"       Finds and executes the given script
  -pr "file"        Requires the given files/patterns in parallel (*)
  -pa "path"        Prepends the given path to Erlang code path (*)
  -pz "path"        Appends the given path to Erlang code path (*)
  --app "app"       Start the given app and its dependencies (*)
  --erl "switches"  Switches to be passed down to Erlang (*)
  --name "name"     Makes and assigns a name to the distributed node
  --sname "name"    Makes and assigns a short name to the distributed node
  --cookie "cookie" Sets a cookie for this distributed node
  --hidden          Makes a hidden node
  --werl            Uses Erlang's Windows shell GUI (Windows only)
  --detached        Starts the Erlang VM detached from console
  --remsh "name"    Connects to a node using a remote shell
  --dot-iex "path"  Overrides default .iex.exs file and uses path instead;
                    path can be empty, then no file will be loaded

** Options marked with (*) can be given more than once
** Options given after the .exs file or -- are passed down to the executed code
** Options can be passed to the VM using ELIXIR_ERL_OPTIONS or --erl
```

Когда мы из командной строки передаём опцию `--help` в IEx, мы видим список доступных опций. Среди них есть `--name` и `--sname`, используемые для изменения информации о нодах. Нода &mdash; это виртуальная машина Erlang, управляющая своими связями, сборкой мусора, планированием процессов, памятью и прочим. По умолчанию нода называется **nonode@nohost**.

```shell
$ iex --name learner@elixirschool.com

Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex(learner@elixirschool.com)> Node.self
:"learner@elixirschool.com"
```

Теперь, как вы видите, текущая нода &mdash; это атом с именем `:"learner@elixirschool.com"`. Если мы снова выполним `Mnesia.create_schema([node()])`, то мы увидим ещё одну папку с именем **Mnesia.learner@elixirschool.com**. Цель всего этого довольно проста: ноды в Erlang используются для связи с другими нодами, чтобы разделять информацию и ресурсы. Это работает не только в рамках одной машины, но также через LAN и интернет.

## Запуск Mnesia

Мы закончили базовую настройку нашей базы и теперь можем запустить Mnesia с помощью команды `Mnesia.start/0`.

```shell
iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node])
:ok
iex> Mnesia.start()
:ok
```

Важно помнить, что при использовании Mnesia на двух и более нодах функцию `Mnesia.start/1` надо выполнить на каждой из них.

## Создание таблиц

Для создания таблиц используется функция `Mnesia.create_table/2`. Сейчас мы создадим таблицу `Person` и передадим ключевой список с её схемой.

```shell
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:atomic, :ok}
```

Мы объявили колонки, используя атомы `:id`, `:name`, и `:job`. После выполнения `Mnesia.create_table/2` возвращает один из следующих ответов:

 - `{:atomic, :ok}`, если функция выполнилась успешно;
 - `{:aborted, Reason}` в случае ошибки.

## "Грязный" способ

Сначала рассмотрим "грязный" способ чтения и записи. Как правило, его не используют, потому что он не гарантирует результат. Однако он поможет нам комфортно работать с Mnesia во время обучения. Добавим несколько записей в таблицу **Person**:

```shell
iex> Mnesia.dirty_write({Person, 1, "Seymour Skinner", "Principal"})
:ok

iex> Mnesia.dirty_write({Person, 2, "Homer Simpson", "Safety Inspector"})
:ok

iex> Mnesia.dirty_write({Person, 3, "Moe Szyslak", "Bartender"})
:ok
```

Для получения записей воспользуемся `Mnesia.dirty_read/1`:

```shell
iex> Mnesia.dirty_read({Person, 1})
[{Person, 1, "Seymour Skinner", "Principal"}]

iex> Mnesia.dirty_read({Person, 2})
[{Person, 2, "Homer Simpson", "Safety Inspector"}]

iex> Mnesia.dirty_read({Person, 3})
[{Person, 3, "Moe Szyslak", "Bartender"}]

iex> Mnesia.dirty_read({Person, 4})
[]
```

При запросе несуществующей записи Mnesia вернёт пустой список.

## Транзакции

**Транзакции** используются для инкапсуляции чтения и записи в базу. Транзакции &mdash; важная часть проектирования отказоустойчивых распределённых систем. *Транзакция &mdash; механизм, с помощью которого серия операций в базе данных выполняется как единый функциональный блок*. Для начала создадим анонимную функцию `data_to_write` и передадим её в `Mnesia.transaction`:

```shell
iex> data_to_write = fn ->
...>   Mnesia.write({Person, 4, "Marge Simpson", "home maker"})
...>   Mnesia.write({Person, 5, "Hans Moleman", "unknown"})
...>   Mnesia.write({Person, 6, "Monty Burns", "Businessman"})
...>   Mnesia.write({Person, 7, "Waylon Smithers", "Executive assistant"})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_write)
{:atomic, :ok}
```

Судя по ответу, данные были записаны в таблицу `Person`. Чтобы убедиться, запросим эти данные другой транзакцией. Для чтения мы используем `Mnesia.read/1` изнутри анонимной функции.

```shell
iex> data_to_read = fn ->
...>   Mnesia.read({Person, 6})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_read)
{:atomic, [{Person, 6, "Monty Burns", "Businessman"}]}
```
