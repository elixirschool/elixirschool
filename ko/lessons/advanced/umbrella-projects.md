---
layout: page
title: 엄브렐라 프로젝트
category: advanced
order: 8
lang: ko
---

때로는 프로젝트가 커지고 커져서 아주아주 커질 수도 있습니다. Mix 빌드 도구를 사용해서 작성한 코드를 여러 앱으로 나누고, 이렇게 Elixir 프로젝트가 계속해서 커져나가도 관리하기 쉽도록 유지할 수 있습니다.

{% include toc.html %}

## 시작하기

엄브렐라 프로젝트를 시작하려면 평범한 Mix 프로젝트를 시작할 때 입력했던 명령어에서 `--umbrella` 플래그만 덧붙여주면 됩니다. 이번 예제로는 머신 러닝 툴킷의 **껍데기**를 구현해보도록 하겠습니다. 왜 하필 머신 러닝 툴킷이냐고요? 그러지 말라는 법이 없잖아요? 머신 러닝 툴킷에는 다양한 학습 알고리즘과 유틸리티 함수가 필요하기 때문에 이번 예제에 적절하기 때문이에요.

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
# (역자) 엄브렐라 프로젝트의 최상위 경로에서
# "mix compile" 명령이나 "mix test" 명령을 실행하면
# apps/ 경로 안에 있는 각각 애플리케이션에 대해서도
# 해당 명령을 자동으로 실행합니다.
```

셸 명령어를 입력했을 때 결과에서 보신 것처럼, Mix가 디렉터리 두 개로 된 프로젝트의 작은 뼈대를 만들었습니다.

  - `apps/` - 서프 프로젝트(자녀 프로젝트)가 위치해 있는 곳
  - `config/` - 엄브렐라 프로젝트의 설정이 위치하는 곳


## Child projects

Let's change into the projects machine_learning_toolkit/app directory and create 3 normal applications using Mix as so:

```shell
$ mix new utilities --sup

* creating README.md
* creating .gitignore
* creating mix.exs
* creating config
* creating config/config.exs
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
* creating config
* creating config/config.exs
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

$ mix new svm --sup

* creating README.md
* creating .gitignore
* creating mix.exs
* creating config
* creating config/config.exs
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

We should now have a project tree like so:

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

If we change back to the umbrella projects root, we can see that we can call all the typical commands such as compile. As the sub projects are just normal applications, you can change into their directories and do all the same stuff as usual that Mix enables you to do.

```
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

You may think that interacting with the apps would be a little different in an umbrella project. Well believe it or not, you would be wrong! If we change directory into the top level directory, and start IEx with the `iex -S mix` we can interact with all the projects normally. Let's alter the contents of `apps/datasets/lib/datasets.ex` for this simple example.

```elixir
defmodule Datasets do
  def hello do
    IO.puts "Hello, I'm the datasets"
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
