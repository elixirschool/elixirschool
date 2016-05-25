---
layout: page
title: 커스텀 Mix 태스크
category: basics
order: 15
lang: ko
---

여러분의 Elixir 프로젝트를 위한 커스텀 Mix 태스크 만들기.

{% include toc.html %}

## 소개

여러분의 애플리케이션에 커스텀 Mix 태스크를 추가하여 기능을 확장하고자 하는 것은 흔한 일입니다. 우리의 프로젝트에 어떻게 Mix 태스크를 추가하는지 배우기 전에, 이미 존재하는 것을 한 번 봅시다.

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

위의 셸 명령에서 보다시피, Phoenix 프레임워크에는 새로운 프로젝트를 생성하는 커스텀 Mix 태스크가 있습니다. 만약에 우리가 비슷한 것을 우리의 프로젝트에 추가하고 싶다면 어떨까요? 좋은 소식이 있다면, 우리도 그렇게 할 수 있다는 것이고, Elixir를 이용하면 정말 쉽게 할 수 있다는 것입니다.

## 준비하기

매우 간단한 Mix 애플리케이션을 하나 만듭시다.

```shell
$ mix new hello

* creating README.md
* creating .gitignore
* creating mix.exs
* creating config
* creating config/config.exs
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

이제, Mix가 생성해 준 **lib/hello.ex** 파일에서 "Hello, World!"를 출력하는 간단한 함수를 만들어 봅시다.

```elixir
defmodule Hello do

  @doc """
  Output's `Hello, World!` everytime.
  """
  def say do
    IO.puts "Hello, World!"
  end
end
```

## 커스텀 Mix 태스크

이제 우리의 커스텀 Mix 태스크를 만들어 봅시다. **hello/lib/mix/tasks/hello.ex**라는 디렉토리와 파일을 만들고, 그 안에 7 줄의 Elixir 코드를 작성하세요.

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Simply runs the Hello.say/0 command."
  def run(_) do
    Hello.say # 앞서 만든 Hello.say() 함수 호출하기
  end
end
```

Notice how we start the defmodule statement with `Mix.Tasks` and the name we want to call from the command line. One the second line we introduce the `use Mix.Task` which brings the `Mix.Task` behaviour into the namespace. We then declare a run function which ignores any arguements for now. Within this function, we call our `Hello` module and the `say` function.

## Mix Tasks in Action

Let's checkout our mix task. As long as we are in the directory it should work. From the command line, run `mix hello`, and we should see the following:

```shell
$ mix hello
Hello, World!
```

Mix is quite friendly by default. It knows that everyone can make a spelling error now and then, so it uses a technique called fuzzy string matching to make recommendations:

```shell
$ mix hell
** (Mix) The task "hell" could not be found. Did you mean "hello"?
```

Did you also notice that we introduced an new module attribute, `@shortdoc`? This comes in handy when shipping our application, such as when a user runs the `mix help` command from the terminal.

```shell
$ mix help

mix app.start         # Starts all registered apps
...
mix hello             # Simply calls the Hello.say/0 function.
...
```
