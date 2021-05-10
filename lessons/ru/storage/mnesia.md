---
version: 1.2.0
title: Mnesia
---

Mnesia &mdash; это распределённая система управления базами данных реального времени.

{% include toc.html %}

## Обзор

Mnesia &mdash; это система управления базами данных (СУБД), поставляемая вместе с Erlang Runtime System. Естественно, мы можем использовать её в Elixir.
Благодаря *реляционной гибридной объектной модели данных* Mnesia подходит для распределённых приложений любого масштаба.

## Когда использовать?

Вопрос выбора конкретной технологии зачастую сбивает с толку.
Если вы ответите "да" на любой из следующих вопросов, то это хороший знак, что стоит использовать Mnesia, а не ETS или DETS.

  - Нужен ли мне откат транзакций?
  - Нужен ли мне простой синтаксис для чтения и записи данных?
  - Нужно ли мне хранить данные в нескольких узлах?
  - Нужно ли мне выбирать, где хранить данные &mdash; в RAM или на диске?

## Схема

Mnesia &mdash; это часть ядра Erlang, а не Elixir, поэтому мы обращаемся к ней через двоеточие (см. урок: [Взаимодействие с Erlang](../../advanced/erlang/)):

```elixir

iex> :mnesia.create_schema([node()])

# или если вам по душе стиль Elixir

iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
```

В этом уроке мы будем использовать второй способ при работе с Mnesia API.
`Mnesia.create_schema/1` инициализирует новую пустую схему и передаёт список узлов.
В данном случае мы передаём узел, связанный с нашей IEx-сессией.

## Узлы

После выполнения команды `Mnesia.create_schema([node()])` в текущей директории вы увидите папку с именем **Mnesia.nonode@nohost**.
Наверняка, вам интересно, что же значит **nonode@nohost**, потому что мы не обсуждали это ранее.
Давайте посмотрим:

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

Когда мы из командной строки передаём опцию `--help` в IEx, мы видим список доступных опций.
Среди них есть `--name` и `--sname`, используемые для изменения информации о узлах.
Узел &mdash; это виртуальная машина Erlang, управляющая своими связями, сборкой мусора, планированием процессов, памятью и прочим.
По умолчанию узел называется **nonode@nohost**.

```shell
$ iex --name learner@elixirschool.com

Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex(learner@elixirschool.com)> Node.self
:"learner@elixirschool.com"
```

Теперь, как вы видите, текущий узел &mdash; это атом с именем `:"learner@elixirschool.com"`.
Если мы снова выполним `Mnesia.create_schema([node()])`, то мы увидим ещё одну папку с именем **Mnesia.learner@elixirschool.com**.
Цель всего этого довольно проста:
Узлы в Erlang используются для связи с другими узлами, чтобы разделять информацию и ресурсы.
Это работает не только в рамках одной машины, но также через LAN, интернет и т.д.

## Запуск Mnesia

Мы закончили базовую настройку нашей базы и теперь можем запустить Mnesia с помощью команды `Mnesia.start/0`.

```elixir
iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
:ok
iex> Mnesia.start()
:ok
```

Функция `Mnesia.start/0` является асинхронной.
Он запускает инициализацию существующих таблиц и возвращает атом `: ok`.
В случае, если нам нужно выполнить некоторые действия с существующей таблицей сразу после запуска Mnesia, нам нужно вызвать функцию `Mnesia.wait_for_tables/2`.
Это приостановит звонящего до тех пор, пока таблицы не будут инициализированы.
См. Пример в разделе [Инициализация и миграция](#data-initialization-and-migration).

Важно помнить, что при использовании Mnesia на двух и более узлах функция `Mnesia.start/1` должна выполняться на всех участвующих узлах.

## Создание таблиц

Для создания таблиц используется функция `Mnesia.create_table/2`.
Сейчас мы создадим таблицу `Person` и передадим ключевой список с её схемой.

```elixir
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:atomic, :ok}
```

Мы объявили колонки, используя атомы `:id`, `:name`, и `:job`.
Первый атом (в нашем случае `:id`) является первичным ключом.
Требуется хотя бы один дополнительный атрибут.

После выполнения `Mnesia.create_table/2` возвращает один из следующих ответов:

 - `{:atomic, :ok}`, если функция выполнилась успешно;
 - `{:aborted, Reason}` в случае ошибки.

В частности, если таблица уже существует, ответ будет в виде `{:already_exists, table}`. Таким образом, если мы попробуем пересоздать таблицу, то получим следующее:

```elixir
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:aborted, {:already_exists, Person}}
```

## "Грязный" способ

Сначала рассмотрим "грязный" способ чтения и записи.
Как правило, его не используют, потому что он не гарантирует результат. Однако он поможет нам комфортно работать с Mnesia во время обучения.
Добавим несколько записей в таблицу **Person**.

```elixir
iex> Mnesia.dirty_write({Person, 1, "Seymour Skinner", "Principal"})
:ok

iex> Mnesia.dirty_write({Person, 2, "Homer Simpson", "Safety Inspector"})
:ok

iex> Mnesia.dirty_write({Person, 3, "Moe Szyslak", "Bartender"})
:ok
```

... и для получения записей воспользуемся `Mnesia.dirty_read/1`:

```elixir
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

**Транзакции** используются для инкапсуляции чтения и записи в базу.
Транзакции &mdash; важная часть проектирования отказоустойчивых распределённых систем.
*Транзакция &mdash; механизм, с помощью которого серия операций в базе данных выполняется как единый функциональный блок*.
Для начала создадим анонимную функцию `data_to_write` и передадим её в `Mnesia.transaction`:

```elixir
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
Судя по ответу, данные были записаны в таблицу `Person`.
Чтобы убедиться, запросим эти данные другой транзакцией.
Для чтения мы используем `Mnesia.read/1` изнутри анонимной функции.

```elixir
iex> data_to_read = fn ->
...>   Mnesia.read({Person, 6})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_read)
{:atomic, [{Person, 6, "Monty Burns", "Businessman"}]}
```

Для редактирования достаточно вызвать `Mnesia.write/1` с ключом уже существующей записи.
Например, обновление записи `Hans` выглядело бы так:

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.write({Person, 5, "Hans Moleman", "Ex-Mayor"})
...>   end
...> )
```

## Использование индексов

Mnesia поддерживает создание индексов на неключевых колонках и позволяет запрашивать данные на их основе.
Например, можно добавить индекс для колонки `:job` таблицы `Person`:

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:atomic, :ok}
```

Возвращаемый результат идентичен результату функции `Mnesia.create_table/2`:

 - `{:atomic, :ok}`, если функция выполнилась успешно;
 - `{:aborted, Reason}` в случае ошибки.

В частности, если индекс уже существует, ответ будет в виде `{:already_exists, table, attribute_index}`. Таким образом, если мы попробуем пересоздать индекс, то получим следующее:

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:aborted, {:already_exists, Person, 4}}
```

После успешного создания индекса можно использовать его для чтения данных. Например, получим список директоров:

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.index_read(Person, "Principal", :job)
...>   end
...> )
{:atomic, [{Person, 1, "Seymour Skinner", "Principal"}]}
```

## Match и select

Mnesia поддерживает сложные запросы данных из таблиц в виде сопоставления и функций для выборки.

Функция `Mnesia.match_object/1` возвращает все записи, соответствующие образцу.
Если на колонках существуют индексы, она может использовать их для повышения эффективности запроса.
Для колонок, не участвующих в сопоставлении, используется `:_`.

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.match_object({Person, :_, "Marge Simpson", :_})
...>   end
...> )
{:atomic, [{Person, 4, "Marge Simpson", "home maker"}]}
```

Функция `Mnesia.select/2` позволяет составлять запросы с использованием операторов и функций Elixir или Erlang.
Например, выберем записи, у которых ключ больше 3:

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     {% raw %}Mnesia.select(Person, [{{Person, :"$1", :"$2", :"$3"}, [{:>, :"$1", 3}], [:"$$"]}]){% endraw %}
...>   end
...> )
{:atomic, [[7, "Waylon Smithers", "Executive assistant"], [4, "Marge Simpson", "home maker"], [6, "Monty Burns", "Businessman"], [5, "Hans Moleman", "unknown"]]}
```

Разберём по частям.
Первый атрибут &mdash; таблица `Person`, второй &mdash; кортеж вида `{match, [guard], [result]}`:

- `match` &mdash; то же самое, что передаётся в функцию `Mnesia.match_object/1`. Обратите внимание на специальные атомы вида `:"$n"`, используемые как позиционные параметры для колонок.
- `guard` &mdash; список кортежей с описанием функций-ограничителей. В нашем случае это встроенная функция `:>` (знак "больше") с первым позиционным параметром `:"$1"` и константой `3` в качестве атрибутов.
- `result` &mdash; список полей, возвращаемых запросом, в виде позиционных параметров. Специальный атом `:"$$"` обозначает любой символ. Например, можно использовать `[:"$1", :"$2"]`, чтобы вернуть первые два поля или `[:"$$"]` чтобы вернуть все.

Для более подробной информации можно обратиться к [документации Erlang Mnesia для функции select/2](http://erlang.org/doc/man/mnesia.html#select-2).

## Инициализация и миграция

У любого ПО наступает момент обновления и миграции существующих данных.
Например, во второй версии приложения может понадобиться добавить колонку `:age` в таблицу `Person`.
Мы не можем пересоздать существующую таблицу `Person`, но можем её изменить.
Для этого нам нужно знать, когда нужно преобразовать, что мы можем сделать при создании таблицы.
Для этого мы используем функцию `Mnesia.table_info/2`, чтобы получить информацию о текущей структуре таблицы, и функцию `Mnesia.transform_table/3`, чтобы привести её в новый вид.

Нижеприведённый код делает это по следующему принципу:

* Создаем таблицу с атрибутами второй версии: `[:id, :name, :job, :age]`
* Обрабатываем результат создания:
    * `{:atomic, :ok}`: создаем индексы на колонках `:job` и `:age`
    * `{:aborted, {:already_exists, Person}}`: смотрим, какие колонки заведены в текущей версии таблицы и действуем, исходя из этого:
        * если это список первой версии (`[:id, :name, :job]`), изменяем структуру таблицы, заполняем возраст значением по умолчанию 21 и добавляем индекс для колонки `:age`
        * если это список второй версии, ничего не делаем
        * иначе выходим

Если мы выполняем какие-либо действия с существующими таблицами сразу после запуска Mnesia с `Mnesia.start/0`, эти таблицы могут быть не инициализированы и недоступны.
В этом случае мы должны использовать функцию [`Mnesia.wait_for_tables/2`](http://erlang.org/doc/man/mnesia.html#wait_for_tables-2).
Это приостановит текущий процесс, пока таблицы не будут инициализированы или пока не истечет время ожидания.

Функция `Mnesia.transform_table/3` принимает имя таблицы, функцию, трансформирующую структуру таблицы, и новый список атрибутов.

```elixir
case Mnesia.create_table(Person, [attributes: [:id, :name, :job, :age]]) do
  {:atomic, :ok} ->
    Mnesia.add_table_index(Person, :job)
    Mnesia.add_table_index(Person, :age)
  {:aborted, {:already_exists, Person}} ->
    case Mnesia.table_info(Person, :attributes) do
      [:id, :name, :job] ->
        Mnesia.wait_for_tables([Person], 5000)
        Mnesia.transform_table(
          Person,
          fn ({Person, id, name, job}) ->
            {Person, id, name, job, 21}
          end,
          [:id, :name, :job, :age]
          )
        Mnesia.add_table_index(Person, :age)
      [:id, :name, :job, :age] ->
        :ok
      other ->
        {:error, other}
    end
end
```
