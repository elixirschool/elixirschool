%{
  version: "1.2.0",
  title: "Mnesia",
  excerpt: """
  Mnesia — це розподілена система керування базами даних у режимі реального часу.
  """
}
---

## Огляд

Mnesia — це система керування базами даних (СКБД), що входить до складу Середовища виконання Erlang, і яку ми можемо природно використовувати з Elixir. Саме гібридна реляційно-об'єктна модель даних Mnesia робить її придатною для розробки розподілених застосунків будь-якого масштабу.

## Коли використовувати?

Визначення того, коли використовувати певну технологію, часто є заплутаним питанням. Якщо ви можете відповісти «так» на будь-яке з наступних питань, то це гарна ознака того, що варто використовувати Mnesia замість ETS або DETS.

- Чи потрібно мені відкочувати транзакції?
- Чи потрібен мені простий у використанні синтаксис для читання та запису даних?
- Чи варто мені зберігати дані на кількох вузлах, а не на одному?
- Чи потрібен мені вибір, де зберігати інформацію (ОЗП чи диск)?

## Схема

Оскільки Mnesia є частиною ядра Erlang, а не Elixir, нам потрібно отримати до неї доступ за допомогою синтаксису з двокрапкою (див. Урок: [Взаємодія з Erlang](/uk/lessons/intermediate/erlang)):

```elixir

iex> :mnesia.create_schema([node()])

# або якщо вам більше до вподоби "стиль" Elixir...

iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
```

У цьому уроці ми використовуватимемо останній підхід під час роботи з API Mnesia. `Mnesia.create_schema/1` ініціалізує нову порожню схему та передає список вузлів. У цьому випадку ми передаємо вузол, пов'язаний з нашим сеансом IEx.

## Вузли

Після виконання команди `Mnesia.create_schema([node()])` через IEx ви повинні побачити папку з назвою **Mnesia.nonode@nohost** або подібну у вашому поточному робочому каталозі. Вам може бути цікаво, що означає **nonode@nohost**, оскільки ми раніше з цим не стикалися. Давайте подивимося.

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

Коли ми передаємо опцію `--help` командному рядку IEx, відображаються всі можливі опції. Ми бачимо, що існують опції `--name` та `--sname` для призначення імені вузлам. Вузол — це просто запущена Віртуальна машина Erlang (Erlang Virtual Machine), яка обробляє власні комунікації, збирання сміття, планування процесів, пам'ять та багато іншого. Вузол за замовчуванням називається **nonode@nohost**.

```shell
$ iex --name learner@elixirschool.com

Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex(learner@elixirschool.com)> Node.self
:"learner@elixirschool.com"
```

Як ми тепер бачимо, вузол, який ми запускаємо, — це атом під назвою `:"learner@elixirschool.com"`. Якщо ми знову запустимо `Mnesia.create_schema([node()])`, ми побачимо, що він створив ще одну папку під назвою **Mnesia.learner@elixirschool.com.** Мета цього досить проста. Вузли в Erlang використовуються для підключення до інших вузлів, щоб спільно використовувати (розподіляти) інформацію та ресурси. Це не обов'язково має бути обмежено тією ж машиною і може обмінюватися даними через локальну мережу, інтернет тощо.

## Запуск Mnesia

Тепер, коли ми розібралися з основами та налаштували базу даних, ми можемо запустити СУБД Mnesia за допомогою команди `Mnesia.start/0`.

```elixir
iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
:ok
iex> Mnesia.start()
:ok
```

Функція `Mnesia.start/0` є асинхронною. Вона запускає ініціалізацію існуючих таблиць та повертає атом `:ok`. У випадку, коли нам потрібно виконати деякі дії з існуючою таблицею одразу після запуску Mnesia, нам потрібно викликати функцію `Mnesia.wait_for_tables/2`. Вона призупинить процес-викликувач, доки таблиці не будуть ініціалізовані. Див. приклад у розділі [Ініціалізація та міграція даних](#data-initialization-and-migration).

Варто пам'ятати, що під час запуску розподіленої системи з двома або більше вузлами-учасниками, функція `Mnesia.start/1` має бути виконана на всіх вузлах-учасниках.

## Створення таблиць

Функція `Mnesia.create_table/2` використовується для створення таблиць у нашій базі даних. Нижче ми створюємо таблицю з назвою `Person`, а потім передаємо список ключових слів, що визначає схему таблиці.

```elixir
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:atomic, :ok}
```

Ми визначаємо стовпці за допомогою атомів `:id`, `:name` та `:job`. Перший атом (у цьому випадку `:id`) є первинним ключем. Потрібен принаймні один додатковий атрибут.

Коли ми виконуємо `Mnesia.create_table/2`, вона поверне одну з наступних відповідей:

`{:atomic, :ok}`, якщо функція виконана успішно

`{:aborted, Reason}`, якщо функція завершилася невдачею

Зокрема, якщо таблиця вже існує, причина матиме вигляд `{:already_exists, table}`, тому, якщо ми спробуємо створити цю таблицю вдруге, ми отримаємо:

```elixir
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:aborted, {:already_exists, Person}}
```

## Брудний спосіб

Спочатку ми розглянемо брудний спосіб читання та запису в таблицю Mnesia. Загалом його слід уникати, оскільки успіх не гарантований, але це має допомогти нам навчитися та з комфортом працювати з Mnesia. Додаймо кілька записів до нашої таблиці `Person`.

```elixir
iex> Mnesia.dirty_write({Person, 1, "Seymour Skinner", "Principal"})
:ok

iex> Mnesia.dirty_write({Person, 2, "Homer Simpson", "Safety Inspector"})
:ok

iex> Mnesia.dirty_write({Person, 3, "Moe Szyslak", "Bartender"})
:ok
```

...а для отримання записів ми можемо використовувати `Mnesia.dirty_read/1`:

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

Якщо ми спробуємо запитати запис, якого не існує, Mnesia відповість порожнім списком.

## Транзакції

Традиційно ми використовуємо транзакції для інкапсуляції наших операцій читання та запису в базу даних. Транзакції є важливою частиною проектування відмовостійких, високорозподілених систем. Транзакція Mnesia — *механізм, завдяки якому набір операцій з базою даних може бути виконаний як єдиний функціональний блок*. Спочатку ми створюємо анонімну функцію, в цьому випадку `data_to_write`, а потім передаємо її функції `Mnesia.transaction`.

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

Виходячи з цього повідомлення, ми можемо сміливо припустити, що ми записали дані до нашої таблиці Person. Давайте тепер використаємо транзакцію для читання з бази даних, щоб переконатися. Ми використаємо `Mnesia.read/1` для читання з бази даних, але знову ж таки з анонімної функції.

```elixir
iex> data_to_read = fn ->
...>   Mnesia.read({Person, 6})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_read)
{:atomic, [{Person, 6, "Monty Burns", "Businessman"}]}
```

Зверніть увагу, що якщо ви хочете оновити дані, вам просто потрібно викликати `Mnesia.write/1` з тим самим ключем, що й у існуючого запису. Отже, щоб оновити запис для Ганса, ви можете зробити так:

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.write({Person, 5, "Hans Moleman", "Ex-Mayor"})
...>   end
...> )
```

## Використання індексів

Mnesia підтримує індекси для неключових стовпців, і дані можна запитувати за цими індексами. Отже, ми можемо додати індекс до стовпця `:job` таблиці `Person`:

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:atomic, :ok}
```

Результат подібний до того, що повертає `Mnesia.create_table/2`:

- `{:atomic, :ok}` якщо функція виконана успішно
- `{:aborted, Reason}` якщо функція не виконала свою роботу

Зокрема, якщо індекс вже існує, причина матиме вигляд `{:already_exists, table, attribute_index}`, тому, якщо ми спробуємо додати цей індекс вдруге, ми отримаємо:

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:aborted, {:already_exists, Person, 4}}
```

Після успішного створення індексу ми можемо прочитати його та отримати список усіх директорів:

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.index_read(Person, "Principal", :job)
...>   end
...> )
{:atomic, [{Person, 1, "Seymour Skinner", "Principal"}]}
```

## Зіставлення та вибірка

Mnesia підтримує складні запити для отримання даних із таблиці у формі функцій зіставлення та ad-hoc вибірки.

Функція `Mnesia.match_object/1` повертає всі записи, що відповідають заданому шаблону. Якщо будь-який зі стовпців у таблиці має індекси, вона може використовувати їх для підвищення ефективності запиту. Використовуйте спеціальний атом `:_` для позначення стовпців, які не беруть участі у зіставленні.

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.match_object({Person, :_, "Marge Simpson", :_})
...>   end
...> )
{:atomic, [{Person, 4, "Marge Simpson", "home maker"}]}
```

Функція `Mnesia.select/2` дозволяє вам задати власний запит, використовуючи будь-який оператор або функцію мовою Elixir (або, якщо на те пішло, Erlang). Розглянемо приклад вибірки всіх записів, ключ яких перевищує 3:

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.select(Person, [{{Person, :"$1", :"$2", :"$3"}, [{:>, :"$1", 3}], [:"$$"]}])
...>   end
...> )
{:atomic, [[7, "Waylon Smithers", "Executive assistant"], [4, "Marge Simpson", "home maker"], [6, "Monty Burns", "Businessman"], [5, "Hans Moleman", "unknown"]]}
```

Давайте розберемося. 
Перший атрибут — це таблиця `Person`, другий атрибут — це кортеж виду: `{match, [guard], [result]}`:

- `match` — це те саме, що ви передали б функції `Mnesia.match_object/1`; однак, зверніть увагу на спеціальні атоми `:"$n"`, які вказують позиційні параметри, що використовуються рештою запиту
- `guard` — це список кортежів, який визначає, які захисні функції (guard functions) слід застосувати. У цьому випадку це вбудована функція `:>` (більше ніж) з першим позиційним параметром `:"$1"` та константою `3` як атрибутами
- `result` — це список полів, які повертаються запитом, у вигляді позиційних параметрів спеціального атома `:"$$"` для посилання на всі поля. Таким чином, ви можете використовувати `[:"$1", :"$2"]` для повернення перших двох полів або `[:"$$"]` для повернення всіх полів

Для отримання додаткової інформації див. [документацію Erlang Mnesia для select/2](https://www.erlang.org/doc/apps/mnesia/mnesia.html#select/2).

## Ініціалізація та міграція даних

У кожному програмному рішенні настає час, коли вам потрібно оновити програмне забезпечення та перенести дані, що зберігаються у вашій базі даних. Наприклад, ми можемо захотіти додати стовпець `:age` до нашої таблиці `Person` у версії v2 нашого застосунку. Ми не можемо створити таблицю `Person` після її створення, але ми можемо її трансформувати. Для цього нам потрібно знати, коли саме здійснювати трансформацію, що ми можемо визначити під час створення таблиці. Для цього ми можемо використовувати функцію `Mnesia.table_info/2` для отримання поточної структури таблиці та функцію `Mnesia.transform_table/3` для її трансформації до нової структури.

Код нижче робить це, реалізуючи таку логіку:

- Створити таблицю з атрибутами v2: `[:id, :name, :job, :age]`
- Обробити результат створення:
  - `{:atomic, :ok}`: ініціалізувати таблицю, створивши індекси для `:job` та `:age`
  - `{:aborted, {:already_exists, Person}}`: перевірити атрибути поточної таблиці та діяти відповідно:
    - якщо це список v1 (`[:id, :name, :job]`), перетворити таблицю, вказавши всім вік 21 рік, та додати новий індекс для `:age`
    - якщо це список v2, нічого не робити, все гаразд
    - якщо це щось інше, відступити

Якщо ми виконуємо будь-які дії з існуючими таблицями одразу після запуску Mnesia з `Mnesia.start/0`, ці таблиці можуть бути неініціалізовані та недоступні.
У такому випадку нам слід використовувати функцію [`Mnesia.wait_for_tables/2`](http://erlang.org/doc/man/mnesia.html#wait_for_tables-2).
Вона призупинить поточний процес, доки таблиці не будуть ініціалізовані або доки не буде досягнуто тайм-ауту.

Функція `Mnesia.transform_table/3` приймає як атрибути назву таблиці, функцію, яка перетворює запис зі старого формату в новий, та список нових атрибутів.

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
