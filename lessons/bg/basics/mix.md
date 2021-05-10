---
version: 0.9.2
title: Mix
---

Преди да можем да навлезнем повече в Elixir, трябва първо да научим повече за mix. Ако знаете Ruby, то mix е Bundler, RubyGems и Rake в едно. Той е важна част от всеки Elixir проект и в този урок, ще разгледаме няколко от неговите възможностти. За да видите всичко, което mix предлага, просто изпълнете `mix help`.

Досега работихме само в `iex`, който има свойте лимитации. За да създадем един истински проект, трябва да разделим кода си в много файлове, за да го управляваме лесно; mix ни улеснява да постигнем това с проекти.

{% include toc.html %}

## Нови проекти

Mix ни дава `mix new` команда за лесно създаване на проект. Това ще генерира структурата на директорията и  всичко нужно. Нека пробваме:

```bash
$ mix new example
```

От output-a, можем да видим че mix създаде нашата директория и редица нужни файлове:

```bash
* creating README.md
* creating .gitignore
* creating .formatter.exs
* creating mix.exs
* creating lib
* creating lib/example.ex
* creating test
* creating test/test_helper.exs
* creating test/example_test.exs
```

В този урок, ще се фокусираме върху `mix.exs`.  Там конфигурираме нашата апликация, dependencies, среди и версия. Отворе файла във вашия любим текстов редактор и би трябвало да видите нещо такова(коментарите са премахнати за да е по-кратко):

```elixir
defmodule Example.Mix do
  use Mix.Project

  def project do
    [
      app: :example,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end
end
```

Първата секция която, ще разгледаме е `project`. Тук дефинираме името на проекта си(`app`), задаваме нашата версия (`version`), версията на Elixir (`elixir`) и dependencies (`deps`).

Секцията `application` се използва по време на генериране на нашата аплиция, което ще разгледаме сега.

## Интерактивност

Може да се наложи да ползваме `iex` в контекста на нашата апликация.  За щастие това е лесно с mix.  Можем да почнем нова `iex` сесия:

```bash
$ cd example
$ iex -S mix
```

Стартирането на `iex` така, ще зареди нашата аплицакия и всички dependencies.

## Компилация

Mix е умен и ще компилира вашите промени, когато е нужно, но може все пак да се наложи да се компилира експлицитно.  В тази част ще покрием как да компилираме нашия проект и какво прави това.

За да компилираме mix проект, просто трябва да изпълним `mix compile`:

```bash
$ mix compile
```

Понеже не сме добавяли неща в нашия проект(все още), output-a не е много вълнуващ, но трябва да компилира успешно:

```bash
Compiled lib/example.ex
Generated example app
```

Когато компилираме проект mix създава `_build` директория.  Ако погледнем в `_build` ще видим нашата компилирана апликация: `example.app`.

## Менажиране на dependencies

Нашите проекти нямат dependencies, за сега. Да продължим с дефинирането на dependencies и тяхното сваляне.

За да добавим добавим нов dependency, ни трябва първо да ги добавим в `mix.exs` в `deps` секцията. Нашия списък с dependencies се състои от tuples с две задължителни стойности и една по избор: името на пакета като атом, версията като низ, и допълнителни опции.

За този пример нека погледнем един проект с dependency, като [phoenix_slim](https://github.com/doomspork/phoenix_slim):

```elixir
def deps do
  [
    {:phoenix, "~> 1.1 or ~> 1.2"},
    {:phoenix_html, "~> 2.3"},
    {:cowboy, "~> 1.0", only: [:dev, :test]},
    {:slime, "~> 0.14"}
  ]
end
```

Както може би забелязахте, от dependencies по-горе, `cowboy` е нужен само по време на разработка и тестваме.

Веднъж щом дефинираме нашите dependencies има една финална стъпка: да ги свалим.  Това е аналогично на `bundle install`:

```bash
$ mix deps.get
```

Това беше!  Дефинирахме и свалихме нашите dependencies.  Сега сме подготвени да добавим dependencies, когато дойде времето.

## Среди

Mix, както и Bundler, поддържа различни среди.  Mix подразбиране работи с три среди:

+ `:dev` — Средата подразбиране.
+ `:test` — Използва се от `mix test`. Покрит в следващия урок.
+ `:prod` — Използва се когато рилийзнем апликацията си.

Текущата среда може да се достъпи с `Mix.env`.  Както се очаква, средата може да се смени с `MIX_ENV`:

```bash
$ MIX_ENV=prod mix compile
```