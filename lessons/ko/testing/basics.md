%{
  version: "1.1.1",
  title: "테스트",
  excerpt: """
  소프트웨어 개발에서 테스트는 아주 중요합니다. 이번 수업에서는 ExUnit을 사용해서 Elixir 코드를 테스트하는 방법과 테스트하는 데 있어서 가장 효율적인 절차를 함께 살펴보도록 하겠습니다.
  """
}
---

## ExUnit

ExUnit은 우리가 짠 코드를 철저하게 테스트할 수 있는 모든 도구를 포함하고 있는 내장 테스트 프레임워크입니다. 시작하기 전에 먼저 이야기하자면, Elixir 스크립트로 테스트를 구현했기 때문에 `.exs` 파일 확장자를 사용하는 법을 알아둬야 합니다. 테스트를 실행하려면 `ExUnit.start()`로 ExUnit을 실행해야 하는데, 보통 `test/test_helper.exs` 파일에서 이 코드가 실행됩니다.

지난 수업에서 예제 프로젝트를 만들어 보았을 때, mix가 간단한 테스트를 이미 만들어놓았을 정도로 많은 도움이 되었습니다. `test/example_test.exs` 파일에서 확인해보도록 하지요.

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :world
  end
end
```

`mix test`를 입력하면 프로젝트에 있는 테스트를 실행할 수 있습니다. 지금 바로 테스트를 실행한다면 이런 결과를 볼 수 있겠네요.

```shell
..

Finished in 0.03 seconds
2 tests, 0 failures
```

어? 아웃풋이 두개네요? `lib/example.ex`를 확인해 봅시다. Mix가 여기에 다른 테스트를 만들어 놓았네요. doctest라 부릅니다.

```elixir
defmodule Example do
  @moduledoc """
  Documentation for Example.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Example.hello
      :world

  """
  def hello do
    :world
  end
end
```

### assert

테스트 코드를 써 보신 적이 있다면 `assert`라는 단어에 익숙할 겁니다. 몇몇 프레임워크에서는 `assert` 대신 `should`나 `expect`가 그 자리를 차지합니다.

해당 표현식이 참인지 테스트할 때 `assert` 매크로를 사용합니다. 참이 아니라면, 에러를 발생시키며 테스트가 실패합니다. 테스트가 실패하는 경우를 확인해보기 위해서 샘플 테스트 코드를 수정하고 `mix test`를 실행해봅시다.

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :word
  end
end
```

이제 다른 출력을 확인할 수 있습니다.

```shell
  1) test greets the world (ExampleTest)
     test/example_test.exs:5
     Assertion with == failed
     code:  assert Example.hello() == :word
     left:  :world
     right: :word
     stacktrace:
       test/example_test.exs:6 (test)

.

Finished in 0.03 seconds
2 tests, 1 failures
```

테스트에 실패했을 때 ExUnit은 실패한 `assert`가 있던 정확한 위치와 예상했던 값, 실제 결과를 알려줄 것입니다.

### refute

`if`에 `unless`가 있다면 `assert`에는 `refute`가 있습니다. 실행 결과가 항상 거짓일 때 `refute`를 사용하면 됩니다.

### assert_raise

에러가 발생하는 상황을 테스트로 작성해야 할 때가 있습니다. 이럴 때 `assert_raise`를 사용하면 됩니다. 나중에 Plug를 다룰 수업에서 `assert_raise`를 사용하는 예제를 살펴보겠습니다.

### assert_receive

메시지를 주고 받는 엑터와 프로세스로 구성된 Elixir 애플리케이션에서는 메시지를 보낸 후를 테스트 하고 싶을 때가 많습니다. ExUnit이 자신의 프로세스 안에서 실행되기 때문에 다른 프로세스 처럼 메시지를 받을 수 있고 `assert_receive` 매크로로 assert할 수 있습니다.

```elixir
defmodule SendingProcess do
  def run(pid) do
    send(pid, :ping)
  end
end

defmodule TestReceive do
  use ExUnit.Case

  test "receives ping" do
    SendingProcess.run(self())
    assert_received :ping
  end
end
```

`assert_received`는 메시지를 기다리지 않습니다. `assert_receive`는 타임아웃을 지정할 수 있습니다.

### capture_io, capture_log

애플리케이션 출력의 캡처는 원본 애플리케이션을 변경하지 않아도 `ExUnit.CaptureIO`로 할 수 있습니다. 출력을 만드는 함수를 넘겨보세요.

```elixir
defmodule OutputTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "outputs Hello World" do
    assert capture_io(fn -> IO.puts("Hello World") end) == "Hello World\n"
  end
end
```

비슷하게 `ExUnit.CaptureLog`는 `Logger`의 출력을 켑쳐합니다.

## 테스트 준비

몇몇 인스턴스를 테스트하려면 테스트하기 전에 준비 과정을 거치고 싶을 때가 있는데, 이럴 때에는 `setup`과 `setup_all` 매크로를 사용하면 됩니다. `setup`은 매 테스트를 수행하기 전에 실행되고, `setup_all`은 해당 테스트 스위트 전체를 수행하기 전에 실행됩니다. 여기에서 `{:ok, state}` 형식으로 된 튜플을 반환받아서 `state`를 테스트에서 사용할 수 있습니다.

예제로 한번 익혀볼 수 있게, `setup_all`을 쓰도록 코드를 수정해 봅시다.

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  setup_all do
    {:ok, recipient: :world}
  end

  test "greets", state do
    assert Example.hello() == state[:recipient]
  end
end
```

## 모의 객체 만들기

Elixir에서 모의 객체(mock)를 만들어서 테스트를 진행하는 가장 깔끔한 방법은 "안 하는 것"입니다. 다른 언어에서 테스트를 다루어 보셨다면 지금쯤 모의 객체를 다룰 때가 되었다고 본능적으로 느끼셨겠지만, Elixir 커뮤니티에서 사용하지 말자는 의견이 크기도 하고, 사용하지 않을 만한 멋진 이유도 있기 때문이에요.

더 긴 논의가 보고 싶으시면, 이 [훌륭한 글](http://blog.plataformatec.com.br/2015/10/mocks-and-explicit-contracts/)이 있습니다. 요약하면, 테스트를 위해 의존성을 모의 객체로 만드는 것 보다, 명시적으로 인터페이스(비헤이비어)를 선언하는 것이 애플리케이션 외부의 코드에서 사용할 때나 테스트를 위한 클라이언트 코드에서의 모의 객체 구현에 많은 이점이 있다는 것입니다.

애플리케이션 코드에서 구현을 바꾸려면, 올바른 방법은 모듈을 인자로 넘기고 기본 값을 사용하는 것입니다. 이렇게 할 수 없으면, 내장된 설정 메카니즘을 사용하세요. 모의 객체를 구현하기 위해 특별한 모의 객체 라이브러리를 사용할 필요가 없습니다. 그냥 비헤이비어와 콜백을 쓰세요.
