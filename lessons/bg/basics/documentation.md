%{
  version: "0.9.2",
  title: "Документация",
  excerpt: """
  Документиране на Elixir код.
  """
}
---

## Анотация

Колко коментари пишем и какво прави една документация добра, е доста спорен проблем в програмисткото общество. Въпреки това, всички можем да се съгласим, че документацията е важна, както за нас, така и за тези които работят с нашия код.

Elixir третира документацията като "*гражданин първи клас*", предлагайка различни функции за достъп и генериране на документация за вашите проекти. Elixir ни дава много различни атрибути да анотираме кода. Нека погледнем тези три начина:

  - `#` - За инлайн документация.
  - `@moduledoc` - За документация на модулно ниво.
  - `@doc` - За документация на фукционално ниво.

### Инлайн документация

Вероятно най-лесния начин да коментариате вашия код е с инлайн коментари. Подобно на Ruby или Питон, инлайн коментарите на Elixir се означават с `#`, или още известен като "диес".

```elixir
# Outputs 'Hello, chum.' to the console.
IO.puts "Hello, " <> "chum."
```

Когато Elixir изпълнява този скрипт, ще игнорира всичко от `#` до края на реда, третирайки го като ненужни данни. Коментара не добавя нищо към операцията или изпълнението на скрипта, но когато не е толкова ясно, какво точно се случва, програмиста би трябвало да разбере, четейки от коментара ви. Внимавайте да не прекалявате със едно редовите коментари! Прекалено много коментари из кода, може да го направи труден за проследяване, за това е най-добре да се използва умерено.

### Документиране на модули

Анотацията с `@moduledoc` позволява инлайн документация на модулно ниво. По принцип се поставя точно под `defmodule` декларацията в началото на файла. Долния пример показва коментар с `@moduledoc` декоратора.

```elixir
defmodule Greeter do
  @moduledoc """
  Provides a function `hello/1` to greet a human
  """

  def hello(name) do
    "Hello, " <> name
  end
end
```

Ние (или други) могат да достъпят тази документация, чрез помощната функция `h` в IEx.

```elixir
iex> c("greeter.ex", ".")
[Greeter]

iex> h Greeter

                Greeter

Provides a function hello/1 to greet a human
```

### Документиране на функции

Както Elixir ни дава възможността за анотация на модули, също така предлага подобни анотации за документиране на функции. Анотацията с `@doc` позволява за инлайн документиране на функции и се поставято точно над функцията, която документира.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

Ако влезнем отново в IEx и иползваме помощната команда (`h`) на функцията(като пред нея сложим модулът, в който е), би трябвало да видим следното:

```elixir
iex> c("greeter.ex")
[Greeter]

iex> h Greeter.hello

                def hello(name)

Prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"

iex>
```

Забележете как може да използвате markup в нашата документация и терминала ще го покаже? Освен че е готино допълнение към екосистемата на Elixir, става много по-интересно, когато се обърнем към ExDoc, за генериране на HTML документация.

**Бележка:** aнотацията със `@spec` се използва, за статично анализиране на кода. <!-- TODO: Remove this as a comment, once advanced/typespec  is translated
За да научите повече за нея, погледнете [Спесификации и типове](../../advanced/typespec). -->

## ExDoc

ExDoc е официален Elixir проект, който може да бъде намерен на [GitHub](https://github.com/elixir-lang/ex_doc). Той изкарва **HTML (HyperText Markup Language) и онлайн документация** за Elixir проект. Първо нека създадем Mix проект за нашата апликация:

```bash
$ mix new greet_everyone

* creating README.md
* creating .gitignore
* creating .formatter.exs
* creating mix.exs
* creating lib
* creating lib/greet_everyone.ex
* creating test
* creating test/test_helper.exs
* creating test/greet_everyone_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd greet_everyone
    mix test

Run "mix help" for more commands.

$ cd greet_everyone

```

Сега копирайте и поставете кода от урока за анотация с `@doc` във файл `lib/greeter.ex` и проверете, че всичко работи от командния ред. Сега след като работим с Mix проект, трябва да стартираме IEx по малко по-различен начин, чрез `iex -S mix`:

```bash
iex> h Greeter.hello

                def hello(name)

Prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"
```

### Инсталация

Сега сме готови да настроим ExDoc. Добавете двата нужни пакета, в `mix.exs` файла, за да започнем.

```elixir
  def deps do
    [{:earmark, "~> 0.1", only: :dev}, {:ex_doc, "~> 0.11", only: :dev}]
  end
```

`only: :dev` уточнява, че не искаме да се свалят и компилират тези пакети в production среда. Но защо Earmark? Earmark е Markdown парсър за Elixir, който се ползва от ExDoc, за обърне документацията в `@moduledoc` и `@doc` в HTML.

Важно е да се отбележи, че не сте задължени да ползвате Earmark. Може да го замените със други като Pandoc, Hoedown или Cmark; обаче ще се наложи да поконфигурирате малко повече, за което можете да прочетете [тук](https://github.com/elixir-lang/ex_doc#changing-the-markdown-tool). За този урок, ще се придържаме към Earmark.

### Генериране на документация

В продължение, изпълнете следните две команди:

```bash
$ mix deps.get # gets ExDoc + Earmark.
$ mix docs # makes the documentation.

Docs successfully generated.
View them at "doc/index.html".
```

Ако всичко е минало по план, би трябвало да виждате подобно съобщение, като примера по-горе. Нека погледнем в нашия Mix проект и би трябвало да видим, че има друга директория **doc/**. Вътре е нашата генерирана документация. Ако отворим index страницата в нашия браузър, би трябвало да видим следното:

![ExDoc Screenshot 1]({% asset documentation_1.png @path %})

Можем да видим, че Earmark е конвертирал нашия Markdown и ExDoc го показва в полезен формат.

![ExDoc Screenshot 2]({% asset documentation_2.png @path %})

Сега можем да качим това в Github, нашият website, или [HexDocs](https://hexdocs.pm/).

## Най-добри практики

Тъй като Elixir е доста млад език, много стандарти все още се откриват докакто системата расте. Общността, обаче полага усилия за да затвърди най-добир практики. За да прочетете повече за тях вижте [The Elixir Style Guide](https://github.com/niftyn8/elixir_style_guide).

  - Винаги документирайте модули.

```elixir
defmodule Greeter do
  @moduledoc """
  This is good documentation.
  """

end
```

  - Ако няма да документирате модул, **не** го оставяйте празно.

```elixir
defmodule Greeter do
  @moduledoc false

end
```

 - Когато споменавате фукнции, в модулната документация, използвайте backtick:

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 - Оставете празен ред под `@moduledoc`:

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  alias Goodbye.bye_bye
  # and so on...

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 - Използвайте markdown във функции, което ще го направи по-лесно да се чете чрез IEx или ExDoc.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

 - Опитайте се да добавите примери във вашата документация. Това също ви позволява да генерирате автоматични тестове от примерите в модули, функции или макрота с [ExUnit.DocTest][ExUnit.DocTest]. За да се направи това, трябва да извикате макрото `doctest/1` от вашия тест и да напишете примерите следвайки описанията в [официалната документаци][ExUnit.DocTest].

[ExUnit.DocTest]: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html
