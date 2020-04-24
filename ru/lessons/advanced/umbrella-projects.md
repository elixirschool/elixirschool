---
version: 1.0.3
title: Зонтичные проекты
---

Со временем ваш проект может вырасти до очень больших размеров.
Для таких случаев инструмент `Mix` позволяет разделить код проекта на несколько приложений и сделать ваши проекты на `Elixir` более управляемыми по мере развития.

{% include toc.html %}

## Введение

Зонтичный проект создаётся так же, как и любой другой `Mix` проект, только необходимо передать `--umbrella` в качестве дополнительного параметра при создании нового проекта.
Для этого примера мы собираемся создать *оболочку* для системы машинного обучения.
Почему именно система машинного обучения?  А почему бы и нет? Такой проект нередко состоит из целого набора различных алгоритмов обучения и вспомогательных инструментов.

```shell
$ mix new machine_learning_toolkit --umbrella

* creating .gitignore
* creating README.md
* creating mix.exs
* creating apps
* creating config
* creating config/config.exs

Your umbrella project was created successfully.
Inside your project, you will find an apps/ directory
where you can create and host many apps:

    cd machine_learning_toolkit
    cd apps
    mix new my_app

Commands like "mix compile" and "mix test" when executed
in the umbrella project root will automatically run
for each application in the apps/ directory.
```

Как вы можете увидеть из результатов выполнения команды в консоли, `Mix` создал для нас небольшой проект-заготовку с двумя директориями:

  - `apps/` &mdash; тут будут находиться наши подпроекты
  - `config/` &mdash; тут будет располагаться конфигурация наших зонтичных проектов


## Подпроекты

Давайте перейдём в директорию `machine_learning_toolkit/apps` нашего примера, и создадим там три обычных приложения с помощью `Mix`, следующим образом:

```shell
$ mix new utilities

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/utilities.ex
* creating test
* creating test/test_helper.exs
* creating test/utilities_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd utilities
    mix test

Run "mix help" for more commands.


$ mix new datasets

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/datasets.ex
* creating test
* creating test/test_helper.exs
* creating test/datasets_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd datasets
    mix test

Run "mix help" for more commands.

$ mix new svm

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/svm.ex
* creating test
* creating test/test_helper.exs
* creating test/svm_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd svm
    mix test

Run "mix help" for more commands.
```

В результате структура проекта должна получиться такой:

```shell
$ tree
.
├── README.md
├── apps
│   ├── datasets
│   │   ├── README.md
│   │   ├── lib
│   │   │   └── datasets.ex
│   │   ├── mix.exs
│   │   └── test
│   │       ├── datasets_test.exs
│   │       └── test_helper.exs
│   ├── svm
│   │   ├── README.md
│   │   ├── lib
│   │   │   └── svm.ex
│   │   ├── mix.exs
│   │   └── test
│   │       ├── svm_test.exs
│   │       └── test_helper.exs
│   └── utilities
│       ├── README.md
│       ├── lib
│       │   └── utilities.ex
│       ├── mix.exs
│       └── test
│           ├── test_helper.exs
│           └── utilities_test.exs
├── config
│   └── config.exs
└── mix.exs
```

Если мы перейдём обратно, к корню зонтичного проекта, то выяснится, что мы можем использовать там любые команды, например, компиляцию.
Так как все подпроекты это обычные приложения, вы можете перейти в их директории, и выполнять все те действия, которые вам позволяет `Mix`.

```bash
$ mix compile

==> svm
Compiled lib/svm.ex
Generated svm app

==> datasets
Compiled lib/datasets.ex
Generated datasets app

==> utilities
Compiled lib/utilities.ex
Generated utilities app

Consolidated List.Chars
Consolidated Collectable
Consolidated String.Chars
Consolidated Enumerable
Consolidated IEx.Info
Consolidated Inspect
```

## IEx

Вы можете подумать, что взаимодействие с приложениями в зонтичном проекте будет немного отличаться.
На самом деле это не так! Если мы перейдём в корневую директорию проекта и запустим `IEx` командой `iex -S mix` &mdash; мы сможем нормально взаимодействовать со всеми проектами.
Давайте, для примера, изменим код приложения `apps/datasets/lib/datasets.ex`:

```elixir
defmodule Datasets do
  def hello do
    IO.puts("Hello, I'm the datasets")
  end
end
```

```shell
$ iex -S mix
Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

==> datasets
Compiled lib/datasets.ex
Consolidated List.Chars
Consolidated Collectable
Consolidated String.Chars
Consolidated Enumerable
Consolidated IEx.Info
Consolidated Inspect
Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)

iex> Datasets.hello
Hello, I'm the datasets
:ok
```
