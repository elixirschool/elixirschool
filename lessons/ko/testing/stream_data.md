%{
  version: "1.1.1",
  title: "StreamData",
  excerpt: """
  [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html)과 같은 예제 기반 테스트는 코드가 생각한 대로 동작하는지 확인하는 훌륭한 도구입니다. 그러나 예제 기반 테스트에는 몇 가지 단점이 있습니다.

* 몇 가지 입력만 테스트하기 때문에 엣지 케이스를 놓치기 쉽습니다.
* 요구사항을 충분히 고려하지 않고 테스트를 작성할 수 있습니다.
* 하나의 함수에 대해 여러 예제를 사용하는 경우 테스트가 장황해질 수 있습니다.

이 단원에서는 [StreamData](https://github.com/whatyouhide/stream_data)가 이러한 단점을 어떻게 극복하는지 알아보겠습니다.
  """
}
---

## StreamData가 무엇입니까?

[StreamData](https://github.com/whatyouhide/stream_data)는 상태를 가지지 않는 속성 기반 테스트 라이브러리입니다.

StreamData는 기본적으로 매번 랜덤 데이터를 사용하여 각 테스트를 [100회](https://hexdocs.pm/stream_data/ExUnitProperties.html#check/1-options) 실행합니다.
테스트가 실패하면 StreamData는 입력값을 테스트가 실패한 가장 작은 값으로 [축소](https://hexdocs.pm/stream_data/StreamData.html#module-shrinking)합니다.
이는 코드를 디버깅할 때 도움이 됩니다!
만약 50개의 항목이 있는 리스트로부터 함수가 종료되고 그 원인이 하나의 항목일 때 StreamData는 문제가 되는 항목을 찾는데 도움이 될 수 있습니다.

이 테스트 라이브러리에는 두 개의 주요 모듈이 있습니다.
[`StreamData`](https://hexdocs.pm/stream_data/StreamData.html)는 랜덤 데이터 스트림을 생성합니다.
[`ExUnitProperties`](https://hexdocs.pm/stream_data/ExUnitProperties.html)는 생성된 데이터를 입력으로 사용하여 함수에 대해 테스트를 수행하도록 합니다.

입력을 모르면서 어떻게 함수를 의미 있게 테스트할 수 있는지 궁금할 것입니다. 읽어보십시오!

## StreamData 설치

첫째, 새로운 Mix 프로젝트를 만듭니다.
만약 도움이 필요하다면 [New Projects](https://elixirschool.com/en/lessons/basics/mix/#new-projects)를 참조하십시오.

둘째, StreamData를 `mix.exs` 파일의 의존성으로 추가합니다:

```elixir
defp deps do
  [{:stream_data, "~> x.y", only: :test}]
end
```

라이브러리의 [설치 지침](https://github.com/whatyouhide/stream_data#installation)에 있는 버전으로 `x`와 `y`를 바꿔줍니다.

셋째, 터미널에서 이 커맨드 라인을 실행하세요:

```shell
mix deps.get
```

## StreamData 사용

StreamData의 특징을 설명하기 위해, 값을 반복하는 몇 가지 간단한 유틸리티 함수를 작성할 것입니다.
우리가 [`String.duplicate/2`](https://hexdocs.pm/elixir/String.html#duplicate/2)와 같은 함수를 원하지만, 문자열, 리스트, 튜플을 복제하는 함수를 원한다고 해봅시다.

### Strings

먼저 문자열을 반복하는 함수를 작성해 봅시다.
함수에 대한 요구사항은 무엇일까요?

1. 첫 번째 인자는 문자열이어야 합니다.
우리가 복제할 문자열입니다.
2. 두 번째 인자는 음이 아닌 정수여야 합니다.
첫 번째 인자를 얼마나 반복할지 나타냅니다.
3. 함수는 문자열을 반환해야 합니다.
새 문자열은 원래 문자열을 단지 0회 이상 반복한 것입니다.
4. 원래 문자열이 비어있다면, 반환되는 문자열 또한 비어있어야 합니다.
5. 두 번째 인자가  `0`이면, 반환되는 문자열은 비어있어야 합니다.

이 함수를 실행하면, 이렇게 보입니다.

```elixir
Repeater.duplicate("a", 4)
# "aaaa"
```

엘릭서는 이를 수행할 수 있는 `String.duplicate/2` 함수가 있습니다.
새로운 `duplicate/2` 함수는 단지 그 함수로 위임할 것입니다:

```elixir
defmodule Repeater do
  def duplicate(string, times) when is_binary(string) do
    String.duplicate(string, times)
  end
end
```

성공 경로는 [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html)를 가지고 테스트하기 쉬워야 합니다.

```elixir
defmodule RepeaterTest do
  use ExUnit.Case

  describe "duplicate/2" do
    test "creates a new string, with the first argument duplicated a specified number of times" do
      assert "aaaa" == Repeater.duplicate("a", 4)
    end
  end
end
```

하지만 그것은 종합적인 테스트가 아닙니다.  
두 번째 인자가 `0`일 때는 어떻게 해야 할까요?
첫 번째 인자가 빈 문자열일 경우 출력은 어떻게 해야 하나요?
빈 문자열을 반복한다는 것은 무슨 의미일까요?
이 함수는 UTF-8 문자와 어떻게 동작해야 하나요?
이 함수는 큰 문자열 입력에 동작하나요?

엣지 케이스와 큰 문자열을 테스트하기 위해 더 많은 예제를 작성할 수 있습니다.
그러나 StreamData를 사용하여 많은 코드 없이 이 함수를 엄격하게 테스트할 수 있는지 확인해 보겠습니다.

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "첫 번째 인자를 지정된 수만큼 복제된 새 문자열을 만듭니다" do
      check all str <- string(:printable),
                times <- integer(),
                times >= 0 do

        assert ??? == Repeater.duplicate(str, times)
      end
    end
  end
end
```

무엇에 쓰이는 건가요?

* `test`를 [`property`](https://github.com/whatyouhide/stream_data/blob/v0.4.2/lib/ex_unit_properties.ex#L109)로 대체했습니다. 이렇게 하면 테스트 중인 속성을 문서화할 수 있습니다.
* [`check/1`](https://hexdocs.pm/stream_data/ExUnitProperties.html#check/1)은 테스트에서 사용할 데이터를 설정할 수 있는 매크로입니다.
* [`StreamData.string/2`](https://hexdocs.pm/stream_data/StreamData.html#string/2)는 임의의 문자열을 생성합니다. 
`use ExUnitProperties`에서 [StreamData 함수를 가져오기](https://github.com/whatyouhide/stream_data/blob/v0.4.2/lib/ex_unit_properties.ex#L109) 때문에 `string/2`를 호출할 때 모듈 이름을 생략할 수 있습니다.
* `StreamData.integer/0`은 임의의 정수를 생성합니다.
* `times >= 0`은 일종의 가드문과 같습니다.
테스트에서 사용하는 임의의 정수가 0보다 크거나 같음을 보장합니다.
[`SreamData.positive_integer/0`](https://hexdocs.pm/stream_data/StreamData.html#positive_integer/0)가 존재하지만 `0`은 함수에서 허용하는 값이기 때문에 우리가 원하는 것이 아닙니다.

`???`는 제가 덧붙인 슈도코드일 뿐입니다.
정확히 무엇을 검증해야 할까요?
다음과 같이 쓸 _수_ 있습니다.

```elixir
assert String.duplicate(str, times) == Repeater.duplicate(str, times)
```

...하지만 그것은 실제 함수의 구현을 이용하는 것일 뿐, 도움이 되지 않습니다. 문자열의 길이를 비교하여 검증을 느슨하게 할 수 있습니다.

```elixir
expected_length = String.length(str) * times
actual_length =
  str
  |> Repeater.duplicate(times)
  |> String.length()

assert actual_length == expected_length
```

나아지긴 했지만, 이상적이진 않습니다.
이 함수가 생성한 임의의 문자열이 길이만 일치한다면 테스트는 통과할 것입니다.

우리는 정말로 두 가지를 확인하고 싶습니다.

1. 우리의 함수가 생성한 문자열의 길이가 올바른지.
2. 최종 문자열의 내용은 반복되는 원래 문자열인지.

이것은 단지 속성을 [다시 표현하는](https://www.propertesting.com/book_what_is_a_property.html#_alternate_wording_of_properties) 또 다른 방법입니다.
우리는 이미 #1을 검증할 코드가 있습니다. #2를 검증하기 위해 최종 문자열을 원래 문자열로 나누고, 0개 이상의 빈 문자열이 남아 있는지 확인합니다.

```elixir
list =
  str
  |> Repeater.duplicate(times)
  |> String.split(str)

assert Enum.all?(list, &(&1 == ""))
```

우리의 주장을 종합해 봅시다.

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "첫 번째 인자를 지정된 수만큼 복제된 새 문자열을 만듭니다" do
      check all str <- string(:printable),
                times <- integer(),
                times >= 0 do
        new_string = Repeater.duplicate(str, times)

        assert String.length(new_string) == String.length(str) * times
        assert Enum.all?(String.split(new_string, str), &(&1 == ""))
      end
    end
  end
end
```

원래 테스트와 비교하면 StreamData 버전이 두 배나 길다는 것을 알 수 있습니다.
그러나, 원래 테스트에 더 많은 테스트 케이스를 추가할 때쯤이면...

```elixir
defmodule RepeaterTest do
  use ExUnit.Case

  describe "문자열 복제하기" do
    test "첫 번째 인자를 두 번째 인자만큼 복제한다" do
      assert "aaaa" == Repeater.duplicate("a", 4)
    end

    test "첫 번째 인자가 빈 문자열인 경우 빈 문자열을 반환합니다" do
      assert "" == Repeater.duplicate("", 4)
    end

    test "두 번째 인자가 0인 경우 빈 문자열을 반환합니다" do
      assert "" == Repeater.duplicate("a", 0)
    end

    test "긴 문자열도 동작합니다" do
      alphabet = "abcdefghijklmnopqrstuvwxyz"

      assert "#{alphabet}#{alphabet}" == Repeater.duplicate(alphabet, 2)
    end
  end
end
```

StreamData 버전이 실제로 더 짧습니다.
또한 StreamData는 개발자가 테스트하는 것을 잊어버릴 수 있는 엣지 케이스 테스트도 포함합니다.

### Lists

이제 리스트를 반복하는 함수를 작성해 봅시다.
우리는 이 함수가 다음과 같이 동작하기를 원합니다.

```elixir
Repeater.duplicate([1, 2, 3], 3)
# [1, 2, 3, 1, 2, 3, 1, 2, 3]
```

다음은 올바르지만, 다소 비효율적인 구현입니다.

```elixir
defmodule Repeater do
  def duplicate(list, 0) when is_list(list) do
    []
  end

  def duplicate(list, times) when is_list(list) do
    list ++ duplicate(list, times - 1)
  end
end
```

StreamData 테스트는 다음과 같이 쓰일 것입니다.

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "원본 리스트로 지정된 수만큼 반복되는 새 리스트를 만듭니다" do
      check all list <- list_of(term()),
                times <- integer(),
                times >= 0 do
        new_list = Repeater.duplicate(list, times)

        assert length(new_list) == length(list) * times

        if length(list) > 0 do
          assert Enum.all?(Enum.chunk_every(new_list, length(list)), &(&1 == list))
        end
      end
    end
  end
end
```

임의의 타입과 임의의 길이를 가지는 리스트를 만들기 위해 `StreamData.list_of/1`와 `StreamData.term/0`을 사용하였습니다.

문자열 반복의 속성기반 테스트와 마찬가지로, 새 리스트의 길이를 원본 리스트의 길이에서 `times`로 곱한 값과 비교합니다.
두 번째 주장은 몇 가지 설명이 필요합니다.

1. 새로운 리스트를 여러 리스트로 나누고, 각 리스트는 `list`와 같은 수의 요소를 가지고 있습니다.
2. 그다음 각 분할된 리스트가 `list`와 같은지 확인합니다.

다르게 표현하자면, 원래 리스트가 최종 리스트에 적절한 횟수로 나타나는지 확인하고, _다른_ 요소들이 최종 목록에 나타나지 않는지 확인합니다.

왜 이런 조건을 두어야 할까요?
첫 번째 주장과 조건부가 결합하여 원래 리스트와 최종 리스트가 모두 비어 있게 되면, 더 이상 리스트를 비교할 필요가 없습니다.
게다가 `Enum.chunk_every/2`는 두 번째 인자가 양의 정수여야 합니다.

### Tuples

마지막으로 튜플의 요소를 반복하는 함수를 구현해봅시다.
함수는 다음과 같이 동작해야 합니다.

```elixir
Repeater.duplicate({:a, :b, :c}, 3)
# {:a, :b, :c, :a, :b, :c, :a, :b, :c}
```

우리가 접근할 수 있는 한 가지 방법은 튜플을 리스트로 변환하고 리스트를 복제한 다음 다시 데이터 구조를 튜플로 변환하는 것입니다.

```elixir
defmodule Repeater do
  def duplicate(tuple, times) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> Repeater.duplicate(times)
    |> List.to_tuple()
  end
end
```

어떻게 테스트할 수 있을까요?
지금까지와는 조금 다르게 접근해 봅시다.
문자열과 리스트의 경우 최종 데이터의 길이와 데이터 내용에 관해 주장했습니다.
튜플도 같은 방식으로 접근할 수 있지만, 테스트 코드가 그렇게 간단하지는 않을 것입니다.

튜플에서 수행할 두 가지 순차적인 작업을 고려해보세요.

1. 튜플에서 `Repeater.duplicate/2`를 호출하고 결과를 리스트로 변환합니다.
2. 튜플을 리스트로 변환하고 리스트를 `Repeater.duplicate/2`로 전달합니다.

이것은 ["다른 경로, 같은 목적지"](https://fsharpforfunandprofit.com/posts/property-based-testing-2/#different-paths-same-destination)라고 불리는 Scott Wlaschin의 패턴의 적용입니다.
저는 이 두 가지 작업이 모두 같은 결과를 가져오길 기대합니다.
이 접근법을 우리의 테스트에서 사용해봅시다.

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "원본 튜플을 지정된 수만큼 반복되는 새 튜플을 만듭니다" do
      check all t <- tuple({term()}),
                times <- integer(),
                times >= 0 do
        result_1 =
          t
          |> Repeater.duplicate(times)
          |> Tuple.to_list()

        result_2 =
          t
          |> Tuple.to_list()
          |> Repeater.duplicate(times)

        assert result_1 == result_2
      end
    end
  end
end
```

## 요약

이제 문자열, 리스트, 튜플을 반복하는 세 개의 함수가 있습니다.
우리의 구현의 올바름을 높은 수준으로 확신할 수 있는 몇 가지 속성 기반 테스트가 있습니다.

여기 우리의 최종 애플리케이션 코드입니다.

```elixir
defmodule Repeater do
  def duplicate(string, times) when is_binary(string) do
    String.duplicate(string, times)
  end

  def duplicate(list, 0) when is_list(list) do
    []
  end

  def duplicate(list, times) when is_list(list) do
    list ++ duplicate(list, times - 1)
  end

  def duplicate(tuple, times) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> Repeater.duplicate(times)
    |> List.to_tuple()
  end
end
```

다음은 속성 기반 테스트들입니다.

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "첫 번째 인자를 지정된 수만큼 복제된 새 문자열을 만듭니다" do
      check all str <- string(:printable),
                times <- integer(),
                times >= 0 do
        new_string = Repeater.duplicate(str, times)

        assert String.length(new_string) == String.length(str) * times
        assert Enum.all?(String.split(new_string, str), &(&1 == ""))
      end
    end

    property "원본 리스트로 지정된 수만큼 반복되는 새 리스트를 만듭니다" do
      check all list <- list_of(term()),
                times <- integer(),
                times >= 0 do
        new_list = Repeater.duplicate(list, times)

        assert length(new_list) == length(list) * times

        if length(list) > 0 do
          assert Enum.all?(Enum.chunk_every(new_list, length(list)), &(&1 == list))
        end
      end
    end

    property "원본 튜플을 지정된 수만큼 반복되는 새 튜플을 만듭니다" do
      check all t <- tuple({term()}),
                times <- integer(),
                times >= 0 do
        result_1 =
          t
          |> Repeater.duplicate(times)
          |> Tuple.to_list()

        result_2 =
          t
          |> Tuple.to_list()
          |> Repeater.duplicate(times)

        assert result_1 == result_2
      end
    end
  end
end
```

터미널 커맨드 라인에 입력하여 테스트를 실행할 수 있습니다.

```shell
mix test
```

각 StreamData 테스트는 기본적으로 100번 실행되는 것을 기억하세요.
또한 StreamData의 랜덤 데이터 중 일부는 다른 데이터보다 생성하는 데 오랜 시간이 걸립니다.
누적 효과로 인해 예제 기반 테스트보다 더 느리게 실행될 것입니다.

그런데도 속성 기반 테스트는 예제 기반 테스트를 멋지게 보완했습니다.
그것은 다양한 입력을 다루는 간결한 테스트를 작성할 수 있게 해줍니다.
테스트 실행 간의 상태를 유지할 필요가 없다면, StreamData는 속성 기반 테스트를 작성할 수 있는 멋진 구문을 제공합니다.
