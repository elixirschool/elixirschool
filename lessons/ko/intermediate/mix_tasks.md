%{
  version: "1.0.1",
  title: "커스텀 Mix 태스크",
  excerpt: """
  Elixir 프로젝트를 위한 커스텀 Mix 태스크 만들어 봅시다.
  """
}
---

## 소개

애플리케이션에 커스텀 Mix 태스크를 추가하여 기능을 확장하고자 하는 것은 흔한 일입니다. 프로젝트에 어떻게 Mix 태스크를 추가하는지 배우기 전에, 기존의 태스크를 한 번 확인해 봅시다.

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

위의 셸 명령에서 보다시피, Phoenix 프레임워크에는 새로운 프로젝트를 생성하는 커스텀 Mix 태스크가 있습니다. 프로젝트에 비슷한 것을 추가하고 싶다면 어떻게 해야 할까요? 좋은 소식은 할 수 있고 Elixir가 하기 쉽게 만들어 준다는 것입니다.

## 준비하기

매우 간단한 Mix 애플리케이션을 하나 만듭시다.

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

이제 Mix가 생성해 준 **lib/hello.ex** 파일에서 "Hello, World!"를 출력하는 간단한 함수를 만들어 봅시다.

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

## 커스텀 Mix 태스크

이제 커스텀 Mix 태스크를 만들어 봅시다. **hello/lib/mix/tasks/hello.ex**라는 디렉토리와 파일을 만들고, 그 안에 7 줄의 Elixir 코드를 넣으세요.

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Simply runs the Hello.say/0 command."
  def run(_) do
    # 앞서 만든 Hello.say() 함수 호출하기
    Hello.say()
  end
end
```

defmodule 구문을 `Mix.Tasks`와 명령줄에서 호출하고자 하는 이름으로 시작한다는 것에 주목하십시오. 두번째 줄에서는 `use Mix.Task`를 사용하여 이 네임스페이스에 `Mix.Task`의 동작을 가져옵니다. 그 다음에 run 함수를 선언하는데, 여기에서는 모든 매개변수를 무시합니다. 이 함수 안에서 `Hello` 모듈과 `say` 함수를 호출합니다.

## Mix 태스크 사용하기

우리가 만든 Mix 태스크를 확인해 봅시다. 여러분이 프로젝트 디렉토리 내에 있으면 잘 작동할 것입니다. 명령줄에서 `mix hello`를 실행하면 다음과 같은 내용이 출력됩니다.

```shell
$ mix hello
Hello, World!
```

Mix는 기본적으로 꽤 친절합니다. Mix는 모든 사람들이 가끔씩 철자를 틀리기도 한다는 것을 알고 있기 때문에 퍼지 문자열 매칭이라는 기술을 사용하여 명령어를 추천합니다.

```shell
$ mix hell
** (Mix) The task "hell" could not be found. Did you mean "hello"?
```

또한, 앞의 코드에서 `@shortdoc`이라는 새로운 모듈 속성을 사용했다는 것을 알아채셨습니까? 이 속성은 애플리케이션을 배포할 때 유용할 것입니다. 예를 들면 사용자가 터미널에서 `mix help` 명령을 실행할 때 말이지요.

```shell
$ mix help

mix app.start         # Starts all registered apps
...
mix hello             # Simply calls the Hello.say/0 function.
...
```
