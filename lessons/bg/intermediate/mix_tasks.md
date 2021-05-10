%{
  version: "0.9.1",
  title: "Mix Tasks",
  excerpt: """
  Създаване на Mix tasks за вашите Elixir проекти.
  """
}
---

## Въведение

Не е необичайно да искате да добавите функционалност към вашата Elixir апликация, чрез Mix tasks. Преди да се научим, как да създаваме Mix tasks за нашите проекти, нека да погледнем съществуващите:

```shell
$ mix phx.new my_phoenix_app

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

Както можем да видим от командата по-горе, Phoenix фреймуъркът има Mix task за генериране на нов проект. Ами ако можехме да създадем нещо подобно за нашия проект? Добрата новина, е че можем и Elixir прави това много лесно за нас.

## Настройване

Нека създадем проста Mix апликация.

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

Нека направим проста функция, която просто ще покаже "Hello, World!", в **lib/hello.ex** файлът, който Mix генерира за нас.

```elixir
defmodule Hello do
  @doc """
  Output's `Hello, World!` everytime.
  """
  def say do
    IO.puts("Hello, World!")
  end
end
```

## Наш  Mix Task

Нека създадем наш Mix task. Създайте нова директория и файл **hello/lib/mix/tasks/hello.ex**. В този файл, добавете тези 7 реда Elixir:

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Simply runs the Hello.say/0 command."
  def run(_) do
    # calling our Hello.say() function from earlier
    Hello.say()
  end
end
```

Забележете как добавяме `Mix.Tasks` към defmodule и името, с което ще го извикаме от командния ред. На втория ред, добавяме `use Mix.Task`, който добавя `Mix.Task` функционалност в namespace-a. След това декларираме функция, която игнорира аргументи за сега. В тази функция, извикваме нашия `Hello` модул и `say` функцията.

## Mix Tasks в действие

Нека изпробваме нашия mix task. Стига да сме в директорията, би трябвало да работи. От командния ред, изпълнете `mix hello`, и би трябвало да видите следното:

```shell
$ mix hello
Hello, World!
```

Mix знае, че всеки може да допусне грешка от време на време, за това използва техника наречена fuzzy string matching за да предложи поправка:

```shell
$ mix hell
** (Mix) The task "hell" could not be found. Did you mean "hello"?
```

Забелязахте ли, че също така добавихме нов модулен атрибут `@shortdoc`? Това влиза в помощ, когато изпълняваме `mix help` от терминала.

```shell
$ mix help

mix app.start         # Starts all registered apps
...
mix hello             # Simply calls the Hello.say/0 function.
...
```
