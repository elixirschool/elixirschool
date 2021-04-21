%{
  version: "1.0.2",
  title: "스펙과 타입",
  excerpt: """
  이번 수업에서 `@spec`과 `@type` 구문을 공부해보도록 하겠습니다. `@spec`이 문서화 도구가 코드를 분석해서 문서화에 힘을 실어주는 구문이라면, `@type`은 읽고 이해하기에 더 쉬운 코드를 쓸 수 있게 도와주는 구문입니다.
  """
}
---

## 소개

여러분들이 작성한 함수의 인터페이스를 설명하고 싶어할 때가 종종 있습니다. 물론 이런 내용을 [@doc 주석](../../basics/documentation) 안에서 설명할 수도 있겠지만, 이런 정보는 다른 개발자들에게만 보일 뿐이지 컴파일 할 때 쓰이는 부분은 아닙니다. Elixir에 있는 `@spec`을 사용해서, 함수의 명세를 작성하고 컴파일러가 확인할 수 있도록 할 수 있습니다.

하지만 때로는 함수의 명세가 너무 크고 복잡해질 수 있습니다. 단순화를 위해, 커스텀 타입 도입을 고려할 수 있습니다. Elixir에는 `@type` 주석으로 커스텀 타입을 정의할 수 있습니다. 한편 Elixir는 여전히 동적 언어입니다. 이 말인즉슨, 타입에 관련된 모든 정보는 컴파일러가 확인하지 않을 것이며, 다른 도구에서만 사용할 것입니다.

## 스펙

Java나 Ruby를 사용해보신 분들이라면 specification을 `interface`처럼 생각하실 수 있습니다. Specification에서 함수의 인자나 리턴값이 어떤 타입일지를 정의합니다.

함수를 정의하는 코드 바로 위에 `@spec`을 쓰고, 그 뒤에 파라미터의 타입을 파라미터로 호출하듯 함수의 이름과 파라미터 타입, `::` 뒤에 리턴되는 값을 적어줍니다.

아례 예시를 한번 살펴보도록 하지요.

```elixir
@spec sum_product(integer) :: integer
def sum_product(a) do
  [1, 2, 3]
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
end
```

전부 다 괜찮아 보이고, 함수를 호출하면 올바른 값이 리턴되겠지요. 하지만 `Enum.sum` 함수는 `@spec`에서 예상했던 `integer`가 아니라 `number`를 리턴합니다. 이런 부분에서 버그가 생겨날 수 있어요! 코드를 정적 분석해주는 Dialyzer 같은 도구를 사용해서 이런 종류의 버그를 찾아낼 수 있습니다. 이런 정적 분석 도구를 사용하는 법에 대해서는 다른 수업에서 다루어 보겠습니다.

## 커스텀 타입

스펙을 작성하는 것도 좋지만, 때로는 우리들이 구현한 함수가 간단한 함수나 컬렉션보다 복잡한 자료 구조를 처리해야 할 수도 있습니다. 이런 함수를 `@spec`으로 정의한다면, 다른 개발자들이 이해하거나 수정하기가 힘들어질 수 있습니다. 종종 함수가 많은 파라메터를 필요로 하거나, 복잡한 데이터를 리턴해야 할 때가 있습니다. 하지만 파라메터 목록이 길어질수록 코드의 품질이 떨어질 가능성도 점점 커집니다. Ruby나 Java 같은 객체 지향 언어를 사용했더라면, 간편하게 클래스를 구현해서 문제를 해결할 수 있었을 것입니다. Elixir에서는 클래스가 없고, 대신에 타입을 정의해서 언어를 확장할 수 있습니다.

막 설치를 끝내고 난 Elixir에는 `integer`나 `pid` 같은 기본적인 타입이 있는데요. [공식 문서(Types and Their Syntax)](https://hexdocs.pm/elixir/typespecs.html#types-and-their-syntax)에서 사용할 수 있는 타입의 전체 목록을 찾아볼 수 있습니다.
 
### 커스텀 타입 정의하기

추가적으로 파라미터를 도입하는 쪽으로 `sum_times` 함수를 수정해보겠습니다.

```elixir
@spec sum_times(integer, %Examples{first: integer, last: integer}) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

`Range` 모듈 안에 있는 구조체를 단순하게 만들어, `Examples` 모듈 안에 `first`와 `last` 필드를 가진 구조체를 도입하였습니다. 구조체는 [모듈](../../basics/modules/#structs)에서 한번 이야기해 본 적이 있었습니다. 그런데, 코드의 여러 부분에서 `Examples` 구조체에 대한 스펙을 정의해야 하는 상황을 상상해 봅시다. 길고 복잡한 스펙을 쓰자니 성가실 뿐더러, 이 부분에서 버그가 생겨날 가능성이 커질 수도 있습니다. 이 문제를 해결하기 위해서 `@type`을 사용할 수 있습니다.

Elixir에서 타입을 지정하는 방법에는 세 가지가 있습니다.

  - `@type` – 그냥 공개 타입입니다. 타입의 내부 구조까지도 공개합니다.
  - `@typep` – 공개하지 않은 타입이고, 이 타입을 정의하고 있는 모듈 안에서만 사용할 수 있습니다.
  - `@opaque` – 타입은 공개되어 있지만, 타입의 내부 구조는 숨겨져 있습니다.

이제 타입을 정의해 봅시다.

```elixir
defmodule Examples do
  defstruct first: nil, last: nil

  @type t(first, last) :: %Examples{first: first, last: last}

  @type t :: %Examples{first: integer, last: integer}
end
```

구조체 `%Examples{first: first, last: last}`를 나타내는 타입 `t(first, last)`를 정의하였습니다. 여기에서 타입이 인수를 취할 수 있다는 걸 알 수 있지만, 이번에는 타입 `t`도 정의한 데다가 이번에는 `%Examples{first: integer, last: integer}` 구조체를 나타내는 타입입니다.

어떻게 다를까요? 첫번째는 아무 타입이나 가질 수 있는 두 키를 가진 `Example` 구조체입니다. 한편 두번째는 키가 정수(`integer`)인 구조체를 나타냅니다. 다시 말해 아래처럼 코드를 작성하면
  
```elixir
@spec sum_times(integer, Examples.t()) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

아래 코드와 같은 의미가 됩니다.

```elixir
@spec sum_times(integer, Examples.t(integer, integer)) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

### 타입 문서화하기

마지막으로 타입을 문서화하는 방법을 다루어 보겠습니다. [문서화](../../basics/documentation) 수업에서 함수와 모듈를 문서화할 때에는 `@doc`과 `@moduledoc`을 사용한다는 것을 배웠었지요. 타입을 문서화할 때에는 `@typedoc`을 사용할 수 있습니다.

```elixir
defmodule Examples do
  @typedoc """
      integer인 :first와 integer인 :last를 갖고 있는 Examples 구조체를 대표하는 타입.
  """
  @type t :: %Examples{first: integer, last: integer}
end
```

`@typedoc` 주석은 `@doc`이나 `@moduledoc`과 비슷합니다.
