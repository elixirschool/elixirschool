---
version: 1.0.3
title: Користувацькі Mix завдання
---

Створюємо користувацькі Mix завдання для ваших Elixir проектів.

{% include toc.html %}

## Вступ

Бажання розширити функціонал своїх Elixir додатків шляхом додавання користувацьких Mix завдань є досить поширеним.
Перед тим, як ми дізнаємось як створювати особливі Mix завдання для наших проектів, давайте глянемо на вже існуюче завдання:

```shell
$ mix phoenix.new my_phoenix_app

* creating my_phoenix_app/config/config.exs
* creating my_phoenix_app/config/dev.exs
* creating my_phoenix_app/config/prod.exs
* creating my_phoenix_app/config/prod.secret.exs
* creating my_phoenix_app/config/test.exs
* creating my_phoenix_app/lib/my_phoenix_app.ex
* creating my_phoenix_app/lib/my_phoenix_app/endpoint.ex
* creating my_phoenix_app/test/views/error_view_test.exs
...
```

Як видно з результатів роботи вищевказаної консольної команди, каркас Phoenix має користувацьке Mix завдання для генерації нового проекту.
Що як ми б могли створювати щось подібне для наших проектів? Прекрасна новина в тому, що таки можемо, і в Elixir це зробити дуже легко.

## Налаштування

Давайте налаштуємо базовий Mix додаток.

```shell
$ mix new hello

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/hello.ex
* creating test
* creating test/test_helper.exs
* creating test/hello_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

cd hello
mix test

Run "mix help" for more commands.
```

Давайте створимо просту функцію для виведення "Hello, World!" в нашому файлі **lib/hello.ex**, який для нас згенерував Mix.

```elixir
defmodule Hello do
  @doc """
  Щоразу виводить `Hello, World!`.
  """
  def say do
    IO.puts("Hello, World!")
  end
end
```

## Користувацькі Mix завдання

Давайте створимо наше користувацьке Mix завдання.
Створіть папку **hello/lib/mix/tasks**.
Всередині створіть новий файл з назвою **hello.ex** та скопіюйте до нього код, наведений нижче:

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Simply calls the Hello.say/0 function."
  def run(_) do
    # викликає функцію Hello.say() з попереднього файлу
    Hello.say()
  end
end
```

Зауважте, як ми почали defmodule з `Mix.Tasks` й імені, за яким ми хочемо викликати завдання з командного рядку.
В другому рядку у нас `use Mix.Task`, що привносить поведінку `Mix.Task` у цей простір назв.
Потім ми оголошуємо функцію `run`, яка (поки що) ігнорує будь-які аргументи.
Всередині цієї функції ми викликаємо наш модуль `Hello` і його функцію `say`.

## Mix завдання в дії

Давайте перевіримо наше завдання mix.
Воно має працювати до тих пір, поки ми залишатимемося в цій папці.
Викличемо `mix hello` з командного рядка, і ми повинні побачити таке:

```shell
$ mix hello
Hello, World!
```

Mix за замовчуванням є дуже дружелюбним.
Він знає, що всі час від часу роблять помилки в написанні, тому використовує прийом з назвою "нечітке зіставлення рядків" для своїх рекомендацій:

```shell
$ mix hell
** (Mix) The task "hell" could not be found. Did you mean "hello"?
```

Також: чи ви помітили, що у нас з'явився новий атрибут в модулі, `@shortdoc`? Він стає в нагоді при доставці нашого додатку, наприклад коли користувач запускає в терміналі команду `mix help`.

```shell
$ mix help

mix app.start         # Starts all registered apps
...
mix hello             # Simply calls the Hello.say/0 function.
...
```

Зауваження: Наш код має скомпілюватися перед тим, як нові завдання з'являться в результаті виконання `mix help`.
Це можна зробити або виконавши `mix compile` напряму, або виконуючи конкретно наше завдання. Другий спосіб ми використали раніше для того щоб скомпілювати `mix hello`.
