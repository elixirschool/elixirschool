---
layout: page
title: Specifications and types
category: advanced
order: 9
lang: ko
---

이번 수업에서 `@spec`과 `@type` 구문을 공부해보도록 하겠습니다. `@spec`이 문서화 도구가 코드를 분석해서 문서화에 힘을 실어준다면, `@type`은 읽고 이해하기에 더 쉬운 코드를 쓸 수 있게 도와주는 구문입니다.

{% include toc.html %}

## 소개

여러분들이 작성한 함수의 인터페이스를 설명하고 싶어하는 일은 그렇게 드물지 않습니다. 물론 이런 내용을 [@doc 주석](/ko/lessons/basic/documentation) 안에서 설명할 수도 있겠지만, 이런 정보는 다른 개발자들에게만 보일 뿐이지 컴파일 할 때 쓰이는 부분은 아닙니다. Elixir에 있는 `@spec`을 사용해서, 함수의 명세를 작성하고 컴파일러가 확인할 수 있도록 할 수 있습니다.

하지만 때로는 함수의 명세가 너무 크고 복잡해질 수 있습니다. 이러한 복잡함을 줄이기 위해, 커스텀 타입을 도입하는 쪽을 생각하고 계실텐데요. Elixir에는 `@type` 주석으로 커스텀 타입을 정의할 수 있습니다. 한편 Elixir는 여전히 동적 언어입니다. 이 말인즉슨, 타입에 관련된 모든 정보는 컴파일러가 확인하지 않을 것이며, 다른 도구에서만 사용할 것입니다.

## 스펙

Java나 Ruby를 사용해보신 분들이라면 specification을 `interface`처럼 생각하실 수 있습니다. Specification에서 함수의 인자나 리턴값이 어떤 타입일지를 정의합니다.

함수를 정의하는 코드 바로 위에 `@spec`을 쓰고, 그 뒤에 파라미터의 타입을 파라미터로 호출하듯 함수의 이름과 파라미터 타입, `::` 뒤에 리턴되는 값을 적어줍니다.

아례 예시를 한번 살펴보도록 하지요.

```elixir
@spec sum_product(integer) :: integer
def sum_product(a) do
    [1, 2, 3]
    |> Enum.map(fn el -> el * a end)
    |> Enum.sum
end
```

전부 다 괜찮아 보이고, 함수를 호출하면 올바른 값이 리턴되겠지요. 하지만 `Enum.sum` 함수는 `@spec`에서 예상했던 `integer`가 아니라 `number`를 리턴합니다. 이런 부분에서 버그가 생겨날 수 있어요! 코드를 정적 분석해주는 Dialyzer 같은 도구를 사용해서 이런 종류의 버그를 찾아낼 수 있습니다. 다른 수업에서 이런 정적 분석 도구를 사용하는 법에 대해서는 다루어 보겠습니다.
 
## 커스텀 타입

Writing specifications is nice, but sometimes our functions works with more complex data structures than simple numbers or collections. In that definition's case in `@spec` it could be very hard to understand and/or change for other developers. Sometimes functions need to take in a large number of parameters or return complex data. A long parameters list is one of many potential bad smells in one's code. In object oriented-languages like Ruby or Java we could easily define classes that help us to solve this problem. Elixir hasn't classes but because is easy to extends that we could define our types.

막 설치를 끝내고 난 Elixir에는 `integer`나 `pid` 같은 기본적인 타입이 있는데요. [공식 문서(Types and Their Syntax)](http://elixir-lang.org/docs/stable/elixir/typespecs.html#types-and-their-syntax)에서 사용할 수 있는 타입의 전체 목록을 찾아볼 수 있습니다.
 
### 커스텀 타입 정의하기

추가적으로 파라미터를 도입하는 쪽으로 `sum_times` 함수를 수정해보겠습니다.

```elixir
@spec sum_times(integer, %Examples{first: integer, last: integer}) :: integer
def sum_times(a, params) do
    for i <- params.first..params.last do
        i
    end
       |> Enum.map(fn el -> el * a end)
       |> Enum.sum
       |> round
end
```

We introduced a struct in `Examples` module that contains two fields `first` and `last`. That is simpler version of struct from `Range` module. We will talk about `structs` when we get into discussing [modules](lessons/basics/modules/#structs). Lets imagine that we need to specification with `Examples` struct in many places. It would be very annoying to write long, complex specifications and could be a source of bugs. A solution to this problem is `@type`.

Elixir에서 타입을 지정하는 방법에는 세 가지가 있습니다.

  - `@type` – 그냥 공개 타입입니다. 타입의 내부 구조까지도 공개합니다.
  - `@typep` – 공개하지 않은 타입이고, 이 타입을 정의하고 있는 모듈 안에서만 사용할 수 있습니다.
  - `@opaque` – 타입은 공개되어 있지만, 타입의 내부 구조는 숨겨져 있습니다.

Let define our type:

```elixir
defmodule Examples do

    defstruct first: nil, last: nil

    @type t(first, last) :: %Examples{first: first, last: last}

    @type t :: %Examples{first: integer, last: integer}

end
```

We defined the type `t(first, last)` already, which is a representation of the struct `%Examples{first: first, last: last}`. At this point we see types could takes parameters, but we defined type `t` as well and this time it is a representation of the struct `%Examples{first: integer, last: integer}`.   

What is a difference? First one represents the struct `Examples` of which the two keys could be any type. Second one represents struct which keys are `integers`. That means code like this:
  
```elixir
@spec sum_times(integer, Examples.t) :: integer
def sum_times(a, params) do
    for i <- params.first..params.last do
        i
    end
       |> Enum.map(fn el -> el * a end)
       |> Enum.sum
       |> round
end
```

Is equal to code like:

```elixir
@spec sum_times(integer, Examples.t(integer, integer)) :: integer
def sum_times(a, params) do
    for i <- params.first..params.last do
        i
    end
       |> Enum.map(fn el -> el * a end)
       |> Enum.sum
       |> round
end
```

### 타입 문서화하기

The last element that we need to talk about is how to document our types. As we know from [documentation](/lessons/basic/documentation) lesson we have `@doc` and `@moduledoc` annotations to create documentation for functions and modules. For documenting our types we can use `@typedoc`:

```elixir
defmodule Examples do
    
    @typedoc """
        Type that represents Examples struct with :first as integer and :last as integer.
    """
    @type t :: %Examples{first: integer, last: integer}

end
```

Directive `@typedoc` is similar to `@doc` and `@moduledoc`.
