%{
  version: "1.0.1",
  title: "Mox",
  excerpt: """
  Mox는 동시성 있는 목(mock) 설계를 위한 Elixir 라이브러리입니다.
  """
}
---

## 테스트 용이한 코드 작성하기

테스트와 테스트를 용이하게 해주는 목(mock)은 일반적으로 어떤 언어에서도 주목받는 하이라이트가 아닙니다. 그래서 비교적 덜 다뤄지는것도 별로 놀랄일은 아니죠.
하지만, Elixir에서는 _확실히_ 목을 사용할수 있습니다!
정확한 사용 방법은 다른 언어에서 익숙한 방식과 다를 수 있지만 궁극적인 목표는 동일합니다. 그것은 바로 목은 내부 함수의 출력을 흉내낼 수 있어 코드에서 가능한 모든 실행 경로를 확인할 수 있다는 것입니다.

더 복잡한 사용 사례에 들어가기 전에, 코드를 테스트하기 더 쉽게 만들어주는 몇 가지 기법을 이야기해 보죠.
간단한 전략은 함수 안에서 하드코딩된 모듈을 사용하는 대신 모듈을 함수 인자로 넘기는 것입니다.

예를 들어 다음처럼 함수 안에 하드코딩된 HTTP client가 있다고 해봅시다.

```elixir
def get_username(username) do
  HTTPoison.get("https://elixirschool.com/users/#{username}")
end
```

이렇게 하는 대신 다음처럼 HTTP client를 인자로 넘길 수 있습니다.

```elixir
def get_username(username, http_client) do
  http_client.get("https://elixirschool.com/users/#{username}")
end
```

혹은 [apply/3](https://hexdocs.pm/elixir/Kernel.html#apply/3) 함수를 사용해도 됩니다.

```elixir
def get_username(username, http_client) do
  apply(http_client, :get, ["https://elixirschool.com/users/#{username}"])
end
```

모듈을 인자로 전달하면 관심사를 분리하는데 도움이 됩니다. 객체 지향 개념의 장황함이란 함정에 빠지지 않도록 주의한다면 이러한 제어의 역전을 [의존성 주입](https://en.wikipedia.org/wiki/Dependency_injection)으로 이해 해봐도 괜찮습니다.
`get_username/2` 함수를 테스트하려면 검증에 필요한 값들을 반환하는 `get` 함수가 있는 모듈을 전달만 하면 됩니다.

이 구조는 매우 단순하여 대상 함수가 접근이 쉬운 경우에만 유용합니다(즉 내부 어딘가에 숨겨진 private 함수를 테스트하기엔 어렵습니다).

좀더 유연한 전략은 애플리케이션 설정(configuration)을 이용해야 합니다.
전혀 알아차리지 못했을 수도 있지만 사실 엘릭서 애플리케이션은 설정에 자신의 상태를 유지합니다.
따라서 모듈을 하드코딩하거나 함수 인자로 넘기지 않고 다음처럼 애플리케이션 config에서 읽어오게 할 수 있습니다.

```elixir
def get_username(username) do
  http_client().get("https://elixirschool.com/users/#{username}")
end

defp http_client do
  Application.get_env(:my_app, :http_client)
end
```

그런 다음 config 파일에는 다음과 같이 적습니다.

```elixir
config :my_app, :http_client, HTTPoison
```

이 구조, 그리고 애플리케이션 config에 대한 의존성은 앞으로 나올 모든 내용의 기초가 됩니다.

혹시 조금 깊게 생각하시는 분들을 위해 잠깐 짚고 넘어가자면, 물론 `http_client/0` 함수를 생략하고 `Application.get_env/2`를 직접 호출해도 됩니다. 또한 `Application.get_env/3`에 세 번째 인자를 기본값으로 넣고도 동일한 결과를 얻습니다.

애플리케이션 config를 활용하면 각 환경마다 특정 구현을 가질 수 있습니다. 이를 테면 `dev` 환경에서는 샌드박스 모듈을 참조하고 `test` 환경에서는 인메모리 모듈을 사용하는 식입니다.

하지만 환경당 하나의 고정된 모듈만 갖는 건 충분히 유연하지 않습니다. 함수가 사용되는 방식에 따라 모든 가능한 실행 경로를 테스트하기 위해 서로 다른 응답들이 필요할 수 있죠.
사람들 대부분이 잘 모르는 사실은 애플리케이션 설정이 런타임에 _변경_ 가능하다는 것입니다!
[Application.put_env/4](https://hexdocs.pm/elixir/Application.html#put_env/4)을 한번 읽어 보세요.

HTTP 요청의 성공 여부에 따라 애플리케이션이 다르게 동작해야 한다고 해 봅시다.
`get/1` 함수가 각각 있는 여러 모듈을 만듭니다.
한 모듈은 `:ok` 튜플, 다른 모듈은 `:error` 튜플을 반환합니다.
그런 다음 `Application.put_env/4`을 사용해 `get_username/1` 함수 호출 전에 설정을 준비합니다.
테스트 모듈은 다음과 같을 것입니다.

```elixir
# Don't do this!
defmodule MyAppTest do
  use ExUnit.Case

  setup do
    http_client = Application.get_env(:my_app, :http_client)
    on_exit(
      fn ->
        Application.put_env(:my_app, :http_client, http_client)
      end
    )
  end

  test ":ok on 200" do
    Application.put_env(:my_app, :http_client, HTTP200Mock)
    assert {:ok, _} = MyModule.get_username("twinkie")
  end

  test ":error on 404" do
    Application.put_env(:my_app, :http_client, HTTP404Mock)
    assert {:error, _} = MyModule.get_username("does-not-exist")
  end
end
```

필요한 모듈들(`HTTP200Mock`과 `HTTP404Mock`)은 생성되었다고 가정합니다.
[`on_exit`](https://hexdocs.pm/ex_unit/master/ExUnit.Callbacks.html#on_exit/2) 콜백을 [`setup`](https://hexdocs.pm/ex_unit/master/ExUnit.Callbacks.html#setup/1) 픽스쳐에 추가하여 각 테스트가 끝날때마다 `:http_client`가 이전의 상태로 돌아가도록 했습니다.

하지만 일반적으로 위와 같은 패턴을 따라야 하는건 아닙니다!
다음과 같은 몇가지 이유가 있는데, 당장은 그 이유들이 와닿지 않을 수도 있습니다.

우선 `:http_client`에 대해 정의한 모듈이 필요한 작업을 수행할 수 있다는 보장이 없습니다. 즉 모듈에 `get/1` 함수가 반드시 있어야 한다는 규약이 강제되지 않습니다.

두 번째로, 위 테스트는 비동기로 안전하게 실행될 수 없습니다.
애플리케이션의 상태는 애플리케이션 _전체_로 공유되기 때문에, 한 테스트에서 `:http_client`를 재정의하면 다른 (동시에 실행되는)테스트가 잘못된 결과를 받을 수도 있습니다.
테스트가 _평소에는_ 통과하는데 때때로 무작위로 실패하는 경우 이런 문제가 있는지 봐야합니다. 주의하세요!

마지막으로 이 접근법은 결국 애플리케이션을 목 모듈 더미 투성이로 지저분하게 만듭니다.

위 구조를 소개한 이유는 _진짜_ 솔루션이 작동하는 방식을 직관적으로 간략히 설명하여 이해를 돕고자 함입니다.

## Mox : 이 모든 문제들의 해결책

Elixir에서 목을 사용할 때 믿고 쓰는 패키지는 José Valim이 직접 만든 [Mox](https://hexdocs.pm/mox/Mox.html)입니다. 위에서 나열한 모든 문제들을 해결해 줍니다.

전제 조건을 기억하세요. 다음 코드처럼 설정된 모듈을 가져오기 위해 애플리케이션 config를 확인해야만 합니다.

```elixir
def get_username(username) do
  http_client().get("https://elixirschool.com/users/#{username}")
end

defp http_client do
  Application.get_env(:my_app, :http_client)
end
```

그리고 `mox`를 의존성 목록에 포함시켜야 합니다.

```elixir
# mix.exs
defp deps do
  [
    # ...
    {:mox, "~> 0.5.2", only: :test}
  ]
end
```

`mix deps.get`으로 패키지를 설치합니다.

이제, `test_helper.exs` 파일을 다음 2가지를 하도록 수정합니다.

1. 하나 이상의 목을 정의해야합니다.
2. 애플리케이션 config에 목을 설정해야 합니다.

```elixir
# test_helper.exs
ExUnit.start()

# 1. 동적으로 목 정의 
Mox.defmock(HTTPoison.BaseMock, for: HTTPoison.Base)
# ... etc...

# 2. 컨피그 설정값 재정의 (config/test.exs 에 추가한 것과 유사함)
Application.put_env(:my_app, :http_client, HTTPoison.BaseMock)
# ... etc...
```

`Mox.defmock`에 대해 주의해야 할 몇 가지 중요한 사항이 있습니다. 먼저 왼쪽편의 이름은 임의로 넣습니다.
Elixir의 모듈 이름은 아톰일 뿐이라, 모듈을 굳이 생성하지 않고 목 모듈의 이름을 "예약" 해 두는 것입니다.
보이지 않는 곳에서 Mox는 BEAM 안에 이 이름을 가진 목을 즉석에서 생성할 것입니다.

두 번째 유의할 점은 `for:`에서 참조하는 모듈이 _반드시_ 비헤이비어(behaviour)여야 한다는 점, 즉 _반드시_ 콜백들을 정의해야 한다는 뜻입니다.
Mox가 이 모듈을 인트로스펙션으로 사용하므로 `@callback` 이 정의된 목 함수들만 정의 가능하죠.
이것이 Mox가 규약을 강제하는 방식입니다.
비헤이비어 모듈을 찾는것이 어려울 때도 있습니다. 예를 들어 `HTTPoison`같은 경우 `HTTPosion.Base`이 비헤이비어지만 소스코드를 까보지 않으면 이같은 사실을 알기 힘듭니다.
어떤 라이브러리에 대한 목을 만들려고 하는데 해당 라이브러리엔 비헤이비어가 없을 수도 있습니다!
이러한 경우 직접 규약(contract)을 정의하고 그것을 충족하는 비헤이비어와 콜백들을 정의해야 할 것입니다.

이것은 중요한 요점을 시사하는데, 바로 추상화 계층(일명 [indirection](https://en.wikipedia.org/wiki/Indirection))을 사용하여 라이브러리 패키지에 _직접적으로_ 의존하는 대신 직접 작성한 모듈이 그 패키지를 사용하도록 하는게 좋다는 점입니다.
잘 만들어진 애플리케이션이 적절한 "바운더리"를 정의하는건 중요하지만 목의 메커니즘은 바뀌지 않았다는 점을 주의하세요.

마지막으로 테스트모듈에서 `Mox`를 import하여 `:verify_on_exit!` 함수를 호출합니다.
그럼 이제 `expect` 함수를 호출하여 목 모듈의 출력값을 자유롭게 정의합니다.

```elixir
defmodule MyAppTest do
  use ExUnit.Case, async: true
  # 1. Import Mox
  import Mox
  # 2. setup fixtures
  setup :verify_on_exit!

  test ":ok on 200" do
    expect(HTTPoison.BaseMock, :get, fn _ -> {:ok, "What a guy!"} end)

    assert {:ok, _} = MyModule.get_username("twinkie")
  end

  test ":error on 404" do
    expect(HTTPoison.BaseMock, :get, fn _ -> {:error, "Sorry!"} end)
    assert {:error, _} = MyModule.get_username("does-not-exist")
  end
end
```

각 테스트에 대해 동일한 목 모듈(여기서는 `HTTPoison.BaseMock`)을 참조하고 `expect` 함수를 사용하여 호출된 각 함수의 출력값을 정의합니다.

`Mox`는 안전하게 비동기 테스트에 쓸수 있고 각 목이 정해진 규약을 따르도록 합니다.
이 목들은 실제와 다를바 없어 모듈들을 정의해서 애플리케이션을 어수선하게 만들지 않아도 됩니다.

Elixir의 목 세계에 오신것을 환영합니다!
