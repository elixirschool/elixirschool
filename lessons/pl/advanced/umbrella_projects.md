%{
  version: "0.9.1",
  title: "Projekty zbiorcze",
  excerpt: """
  Z czasem projekt może stać się duży, naprawdę duży. Mix pozwala nam na podzielenie naszego projektu na mniejsze, łatwiejsze w utrzymaniu i zarządzaniu. Projekty, które składają się z wielu mniejszych pod projektów, nazywamy projektami zbiorczymi albo po angielsku _umbrella project_.
  """
}
---

## Wprowadzenie

Tworzenie projektu zbiorczego przebiega prawie tak samo, jak zwykłego, a jedyną różnicą jest flaga `--umbrella`. W naszym przykładzie stworzymy *powłokę* na potrzeby narzędzia do nauki maszynowej. Dlaczego właśnie nauka maszynowa? A czemu by nie? Tego typu projekty zawierają zazwyczaj wiele algorytmów i funkcji narzędziowych.

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

Jak widać po wpisach w konsoli, Mix stworzył niewielki szkielet projektu zawierający dwa katalogi:

  - `apps/` – gdzie będą znajdować się projekty potomne.
  - `config/` – gdzie przechowywana jest konfiguracja projektu zbiorczego.


## Projekty potomne

Przejdźmy do katalogu `machine_learning_toolkit/apps` i za pomocą Mixa stwórzmy trzy zwykłe projekty:

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

Nasze drzewo katalogów powinno wyglądać tak:

```shell
$ tree
.
├── README.md
├── apps
│   ├── datasets
│   │   ├── README.md
│   │   ├── config
│   │   │   └── config.exs
│   │   ├── lib
│   │   │   └── datasets.ex
│   │   ├── mix.exs
│   │   └── test
│   │       ├── datasets_test.exs
│   │       └── test_helper.exs
│   ├── svm
│   │   ├── README.md
│   │   ├── config
│   │   │   └── config.exs
│   │   ├── lib
│   │   │   └── svm.ex
│   │   ├── mix.exs
│   │   └── test
│   │       ├── svm_test.exs
│   │       └── test_helper.exs
│   └── utilities
│       ├── README.md
│       ├── config
│       │   └── config.exs
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

Jeżeli teraz wrócimy do katalogu projektu zbiorczego, będziemy mogli zobaczyć jak działają typowe zadania mixa jak kompilacja. Jako że projekty potomne to zwyczajne aplikacje to zawsze możemy też wejść do ich katalogów i bez żadnych problemów wywołać tam zadania mixa.

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

Jeżeli myślisz, że praca z projektami zbiorczymi w IEx różni się w jakiś sposób od pracy ze zwykłymi projektami, to jesteś w błędzie! Przejdźmy do głównego katalogu projektu i uruchommy IEx `iex -S mix` i już możemy pracować z projektem bez żadnych przeszkód. Na przykład zmieńmy zawartości pliku `apps/datasets/lib/datasets.ex`.

```elixir
defmodule Datasets do
  def hello do
    IO.puts("Hello, I'm the datasets")
  end
end
```

```shell
$ iex -S mix
Erlang/OTP 18 [erts-7.2.1] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

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
:world
```
