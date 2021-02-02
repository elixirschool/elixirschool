%{
  version: "1.4.1",
  title: "Модулі",
  excerpt: """
  Ми всі знаємо з досвіду, наскільки незручно зберігати всі функції в одному файлі і в одній області видимості.
В цьому уроці ми розберемося як групувати функції і визначати спеціальний асоціативний масив, відомий як `struct`, для більш ефективної організації коду.
  """
}
---

## Модулі

Модулі дозволяють організовувати функції по областях видимості.
Крім групування функцій, вони дозволяють визначати іменовані і приватні функції, які ми розглянули в [уроці про функції](../functions/).

Давайте розглянемо простий приклад:

``` elixir
defmodule Example do
  def greeting(name) do
    "Hello #{name}."
  end
end

iex> Example.greeting "Sean"
"Hello Sean."
```

Можна створювати вкладені модулі, що дозволяє ще сильніше розбивати функціональність на простори імен:

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

### Атрибути модулів

Атрибути модулів часто використовуються як константи.
Давайте розглянемо простий приклад:

```elixir
defmodule Example do
  @greeting "Hello"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

Важливо пам'ятати, що є кілька зарезервованих назв атрибутів в Elixir.
Три найбільш часто використовувані:

+ `moduledoc` — Документує поточний модуль.
+ `doc` — Документація функцій і макросів.
+ `behaviour` — Використання OTP або визначеної користувачем поведінки.

## Структури

Структура - спеціальний асоціативний масив з певним набором ключів і їх значеннями за замовчуванням.
Вона повинна бути визначеною в модулі, із якого і бере своє ім'я.
Часто структура - це єдина річ, визначена в модулі.

Для визначення структури ми використовуємо конструкцію `defstruct` разом з ключовим списком полів і значень за замовчуванням:

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

Давайте створимо кілька структур:

```elixir
iex> %Example.User{}
%Example.User<name: "Sean", roles: [], ...>

iex> %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [], ...>

iex> %Example.User{name: "Steve", roles: [:manager]}
%Example.User<name: "Steve", roles: [:manager]>
```

Оновлення структури працює так само, як і оновлення асоціативного масиву:

```elixir
iex> steve = %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [...], ...>
iex> sean = %{steve | name: "Sean"}
%Example.User<name: "Sean", roles: [...], ...>
```

Що ще більш важливо, структури можна зіставляти з асоціативними масивами:

```elixir
iex> %{name: "Sean"} = sean
%Example.User<name: "Sean", roles: [...], ...>
```

У Elixir 1.8 структури включають нестандартний самоаналіз.
Щоб зрозуміти, що це означає і як ми повинні використовувати це, розкглянемо наш приклад `sean`:

```elixir
iex> inspect(sean)
"%Example.User<name: \"Sean\", roles: [...], ...>"
```

Усі наші друзі присутні, і це добре для цього прикладу, але що, якщо ми мали б захищене поле, яке не хотіли б включати?
Нова особливість `@derive` дозволяє нам зробити це!
Давайте оновимо наш приклад так, щоб `roles` більше не були включеними в наш результат:

```elixir
defmodule Example.User do
  @derive {Inspect, only: [:name]}
  defstruct name: nil, roles: []
end
```

_Зауваження_: ми могли б також використати `@derive {Inspect, except: [:roles]}`, вони є еквівалентними.

Із нашим оновленим модулем давайте подивимося, що відбувається в `iex`:

```elixir
iex> sean = %Example.User{name: "Sean"}
%Example.User<name: "Sean", ...>
iex> inspect(sean)
"%Example.User<name: \"Sean\", ...>"
```

The `roles` are excluded from output!

## Композиція

Тепер, коли ми знаємо, як створювати модулі і структури в Elixir, давайте розглянемо як підключати існуючу функціональність до них за допомогою композиції.
Мова надає безліч різних способів взаємодії з іншими модулями.

### `alias`

Дозволяє використовувати скорочене іменування модулів, використовується досить часто:

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

Якщо є конфлікт між двома псевдонімами або потрібно зробити псевдонім на довільне ім'я - можна використовувати опцію `:as`:

```elixir
defmodule Example do
  alias Sayings.Greetings, as: Hi

  def print_message(name), do: Hi.basic(name)
end
```

Також можна використовувати скорочене іменування для декількох модулів за раз:

```elixir
defmodule Example do
  alias Sayings.{Greetings, Farewells}
end
```

### `import`

Якщо потрібно імпортувати функції, замість створення псевдоніма модуля можна використовувати `import`:

```elixir
iex> last([1, 2, 3])
** (CompileError) iex:9: undefined function last/1
iex> import List
nil
iex> last([1, 2, 3])
3
```

#### Фільтрація

За замовчуванням імпортуються всі функції і макроси, але можна фільтрувати їх із використанням опцій `:only` та `:except`.

Для імпорту певних функцій і макросів, ми повинні надати пари ім'я/кількість аргументів для `:only` та `:except`.
Давайте почнемо з імпорту функції `last/1`:

```elixir
iex> import List, only: [last: 1]
iex> first([1, 2, 3])
** (CompileError) iex:13: undefined function first/1
iex> last([1, 2, 3])
3
```

Якщо імпортувати все, крім `last/1`, і спробувати ті ж функції, що і раніше:

```elixir
iex> import List, except: [last: 1]
nil
iex> first([1, 2, 3])
1
iex> last([1, 2, 3])
** (CompileError) iex:3: undefined function last/1
```

До того ж до вказівки певної сигнатури функції, існує два спеціальних атома - `:functions` і `:macros`, які імпортують тільки функції і макроси відповідно:

```elixir
import List, only: :functions
import List, only: :macros
```

### `require`

Щоб повідомити Elixir, що ми збираємося використовувати макроси з іншого модуля, можна використовувати `require`.
Невелика відмінність від `import` полягає в тому, що `require` дозволяє використовувати тільки макроси зазначеного модуля, але не функції:

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

Якщо ж ми спробуємо звернутися до макросу, який ще не завантажений, Elixir видасть помилку.

### `use`

За допомогою макросу `use` ми можемо використовувати інший модуль, щоб змінити визначення нашого поточного модуля.
Коли ми викликаємо `use` в коді, насправді ми звертаємося до функції зворотного виклику `__using__/1`, оголошеної в зазначеному модулі.
Результат виконання макросу `__using__/1` стає частиною визначення нашого модуля.
Щоб краще розібратися, як це працює, поглянемо на простий приклад:

```elixir
defmodule Hello do
  defmacro __using__(_opts) do
    quote do
      def hello(name), do: "Hi, #{name}"
    end
  end
end
```

Тут ми створили модуль `Hello`, що визначає функцію зворотного виклику `__using__/1`, всередині якої оголошена функція `hello/1`.
Створимо ще один модуль, щоб спробувати наш новий код:

```elixir
defmodule Example do
  use Hello
end
```

Запустивши наш код в IEx, ми побачимо, що функція `hello/1` доступна з модуля `Example`:

```elixir
iex> Example.hello("Sean")
"Hi, Sean"
```

Отже, ми бачимо, що `use` викликала функцію зворотного виклику `__using__/1` в `Hello`, а та, в свою чергу, додала підсумковий код в наш модуль.
Тепер, коли ми розібрали простий приклад, оновимо код, щоб подивитися, як `__using__/1` підтримує опції.
Зробимо це, додавши опцію `greeting`:

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

Також оновимо модуль `Example`, включивши в нього новостворену опцію `greeting`:

```elixir
defmodule Example do
  use Hello, greeting: "Hola"
end
```

Запустивши це в IEx, ми побачимо, що вітання змінилося:

```elixir
iex> Example.hello("Sean")
"Hola, Sean"
```

Ці приклади були простими, щоб просто продемонструвати, як працює `use`, проте це неймовірно сильний засіб з набору інструментів Elixir.
Продовжуючи вивчати Elixir, звертайте увагу на `use`. Приклад, який точно трапиться на шляху &mdash; це `use ExUnit.Case, async: true`.

**Примітка**: макроси `quote`, `alias`, `use`, `require` використовуються при роботі з [метапрограмуванням](../../advanced/metaprogramming).
