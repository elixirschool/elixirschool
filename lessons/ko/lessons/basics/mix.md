%{
  version: "1.0.2",
  title: "Mix",
  excerpt: """
  Elixir의 바다에 더 깊이 빠져들기 전에 먼저 mix를 공부해봐야 할 필요가 있어요. Ruby에 익숙하신 분들이시라면 mix를 보셨을 때 Bundler와 RubyGem, Rake를 합쳐놓았다는 느낌을 받으실 거예요. Elixir로 프로젝트를 진행하는 데 정말 중요한 부분이라, 이번 강의에서는 mix가 갖고 있는 멋진 기능을 익혀보도록 하겠습니다. `mix help` 를 실행하면 mix가 할 수 있는 모든 기능을 보실 수 있습니다.

여태까지 우리는 공부해오면서 여러 제약이 있는 `iex` 안에서만 작업해 왔었지요. 그렇지만 실제로 돌아가는 무엇인가를 만들어내기 위해서는 코드를 효율적으로 관리하도록 많은 파일로 나눌 필요가 있습니다. mix는 이렇게 프로젝트를 효율적으로 관리해낼 수 있게 해 줍니다.
  """
}
---

## 프로젝트 시작하기

Elixir를 사용하여 프로젝트를 시작할 때, `mix new` 명령을 사용하여 새 프로젝트를 손쉽게 준비할 수 있습니다. 이 명령은 새로 만들어질 프로젝트의 폴더 구조와 공통적으로 필요한 파일들을 만들어냅니다. 참 솔직해서 알기 쉽네요. 이제 시작해봅시다.

```bash
$ mix new example
```

출력하는 걸 보면 mix가 폴더와 함께 공통적으로 필요한 틀을 준비해낸 것을 확인할 수 있습니다.

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

이번 수업에서는 `mix.exs` 파일에만 관심을 두고 살펴보도록 하겠습니다. 이 파일에서 우리가 방금 시작한 프로젝트와 프로젝트가 필요로 하는 의존성과 환경, 버전을 이해할 수 있습니다. 가장 좋아하는 에디터로 이 파일을 열었다면 이렇게 보일 것입니다. 주석은 생략하겠습니다.

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

이 파일의 처음에 있는 `project`를 살펴봅시다. 이곳에는 이 프로젝트에서 만들고자 하는 애플리케이션의 이름(`app`)과 버전(`version`), 이 프로그램이 사용하는 Elixir 버전(`elixir`)과 의존성을 설정할 수 있습니다.

`appliciation`은 애플리케이션 파일을 생성해낼 때 쓰이는 부분인데, 조금 있다가 알아보도록 하겠습니다.

## 대화형 셸에서 만나보기

응용 프로그램을 사용하고 설정할 수 있는 환경에서 `iex`을 사용하면 편할 때가 올 수도 있습니다. 다행스럽게도 mix를 사용해서 간단하게 사용할 수 있습니다. `iex` 세션을 이렇게 실행하실 수 있습니다.

```bash
$ cd example
$ iex -S mix
```

그러면, 현재 애플리케이션과 의존성을 현재 런타임으로 불러와 `iex`를 실행할 수 있습니다.

## 컴파일하기

Mix는 바뀌는 부분이 있을 때 필요할 때마다 컴파일할 수 있을 정도로 똑똑합니다. 하지만 명확하게 프로젝트를 컴파일하고 싶을 때가 있을 지도 모릅니다. 여기서는 컴파일이 무엇인지, 또 프로젝트를 어떻게 컴파일하는지를 다루어 보겠습니다.

mix 프로젝트를 컴파일하려면 프로젝트의 맨 위 디렉터리에서 `mix compile`이라고 치기만 하면 됩니다.

```bash
$ mix compile
```

프로젝트 안에 파일이 아주 많은 건 아니라 출력되는 내용이 그다지 재미있어 보이지는 않습니다. 그렇지만 컴파일이 잘 진행되었네요.

```bash
Compiled lib/example.ex
Generated example app
```

프로젝트를 컴파일하고 나면 mix가 컴파일 결과물을 `_build`라는 폴더를 만들어 담아둡니다. `_build` 폴더 안을 들여다 보면 컴파일된 애플리케이션인 `example.app`을 확인할 수 있습니다.

## 의존성 관리하기

이 프로젝트가 아직까지는 아무런 의존성을 갖고 있지 않지만 머지않아 갖게 되겠지요. 의존성을 관리하고 가져오는 길로 곧장 가 보도록 하겠습니다.

의존성을 더해 주려면 먼저 `mix.exs` 파일의 `deps` 단락에다가 내용을 채워넣으면 됩니다. 반드시 있어야 하는 값 둘(atom으로 된 패키지 이름과 버전 문자열)과 옵션으로 이루어진 튜플 여러 개로 의존성 리스트를 채워나갈 수 있습니다.

의존성을 가진 [phoenix_slim](https://github.com/doomspork/phoenix_slim) 프로젝트를 한번 예로 들어서 살펴보겠습니다.

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

위에 있는 의존성을 보면 `cowboy`는 개발하고 테스트 할 때에만 필요하다는 걸 알 수 있습니다.

의존성을 다 정해주고 나면 이제 해야 할 일은 가져오는 거, 딱 하나밖에 안 남았습니다. `bundle install`와 비슷한 일을 하지요.

```bash
$ mix deps.get
```

다 되었습니다! 프로젝트에 필요한 의존성을 정하고 가져왔습니다. 이제 필요할 때라면 언제라도 의존성을 추가할 수 있게 되었습니다.

## 실행 환경

Ruby에서 사용되는 Bundler처럼 mix는 실행 환경을 설정하고 바꿀 수 있습니다. mix로 크게 별다른 설정 없이 바로 사용할 수 있는 환경에는 세 가지가 있습니다.

+ `:dev` — 기본적으로 적용하는 환경입니다.
+ `:test` — `mix test`를 실행할 때 사용합니다. 바로 다음 수업에서 다루겠습니다.
+ `:prod` — 실제 프로덕션에 애플리케이션을 내놓을 때 사용합니다.

현재 실행 환경은 코드 내부에서 `Mix.env`를 통해 접근할 수 있습니다. 예상대로, `MIX_ENV` 환경변수를 통해 실행 환경을 변경할 수 있습니다.

```bash
$ MIX_ENV=prod mix compile
```
