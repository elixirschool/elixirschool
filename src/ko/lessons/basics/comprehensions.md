---
version: 1.1.0
title: Comprehensions
---

List comprehension은 Elixir에서 열거형을 이용하여 반복하는 데 사용되는 Syntactic sugar입니다. 이번 강의에서는 반복과 제너레이션을 위해 어떻게 comprehension을 사용하는지에 대해 알아봅니다.

{% include toc.html %}

## 기본

Comprehension은 대체적으로 `Enum`과 `Stream` 반복보다 간결한 구문을 작성하기 위해 사용될 수 있습니다. 일단 간단한 comprehension 예제를 보고 차근차근 파헤쳐 봅시다.

```elixir
iex> list = [1, 2, 3, 4, 5]
iex> for x <- list, do: x*x
[1, 4, 9, 16, 25]
```

가장 먼저 눈여겨볼 것은 `for`의 사용과 제너레이터입니다. 제너레이터란 무엇일까요? 제너레이터란 List comprehension에서 볼 수 있는 `x <- [1, 2, 3, 4]`과 같은 표현식입니다. 이들은 다음 값을 생성해내는 역할을 맡고 있습니다.

다행스럽게도 comprehension은 리스트에 한정되지 않습니다. 사실 모든 열거형과 함께 사용할 수 있습니다.

```elixir
# 키워드 리스트
iex> for {_key, val} <- [one: 1, two: 2, three: 3], do: val
[1, 2, 3]

# 맵
iex> for {k, v} <- %{"a" => "A", "b" => "B"}, do: {k, v}
[{"a", "A"}, {"b", "B"}]

# 바이너리
iex> for <<c <- "hello">>, do: <<c>>
["h", "e", "l", "l", "o"]
```

Elixir의 다른 것들과 비슷하게, 제너레이터는 패턴 매칭에 의존하여 입력 값들의 세트를 왼쪽의 변수와 비교합니다. 패턴이 일치하지 않는 경우에는 해당 값은 무시됩니다.

```elixir
iex> for {:ok, val} <- [ok: "Hello", error: "Unknown", ok: "World"], do: val
["Hello", "World"]
```

여러 개의 제너레이터를 사용하여 중첩된 반복도 수행할 수 있습니다.

```elixir
iex> list = [1, 2, 3, 4]
iex> for n <- list, times <- 1..n do
...>   String.duplicate("*", times)
...> end
["*", "*", "**", "*", "**", "***", "*", "**", "***", "****"]
```

실행되고 있는 루프를 더 잘 표현하기 위해 `IO.puts`를 사용하여 두 개의 생성된 값들을 표시해 봅시다.

```elixir
iex> for n <- list, times <- 1..n, do: IO.puts "#{n} - #{times}"
1 - 1
2 - 1
2 - 2
3 - 1
3 - 2
3 - 3
4 - 1
4 - 2
4 - 3
4 - 4
```

List comprehension은 간편 표기법이며, 적절한 곳에만 사용되어야 합니다.

## 필터

필터는 comprehension에 사용되는 가드의 일종이라고 볼 수 있습니다. 필터된 값이 `false`나 `nil`을 반환하는 경우에 그 값은 최종 리스트에서 제외됩니다. 범위 내에서 루프를 돌면서 짝수에만 신경을 써 봅시다. 값이 짝수인지 아닌지 확인하기 위해 Integer 모듈의 `is_even/1` 함수를 사용하겠습니다.

```elixir
import Integer
iex> for x <- 1..10, is_even(x), do: x
[2, 4, 6, 8, 10]
```

제너레이터와 마찬가지로, 필터도 여러 개를 사용할 수 있습니다. 범위를 넓히고 짝수와 3의 배수만 남겨봅시다.

```elixir
import Integer
iex> for x <- 1..100,
...>   is_even(x),
...>   rem(x, 3) == 0, do: x
[6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 78, 84, 90, 96]
```

## `:into` 사용하기

리스트가 아닌 다른 것을 만들고 싶다면 어떻게 해야 할까요? `:into` 옵션이 있다면 할 수 있습니다! 일반적으로 우리가 흔히 겪는 것과 비슷하게, `:into`에는 `Collectable` 프로토콜을 구현하는 어떤 구조체든 사용할 수 있습니다.

`:into`를 사용하여 키워드 리스트로부터 맵을 만들어 봅시다.

```elixir
iex> for {k, v} <- [one: 1, two: 2, three: 3], into: %{}, do: {k, v}
%{one: 1, three: 3, two: 2}
```

바이너리는 `Collectable` 프로토콜을 지원하기 때문에 List comprehension과 `:into`를 사용하여 문자열을 만들 수 있습니다.

```elixir
iex> for c <- [72, 101, 108, 108, 111], into: "", do: <<c>>
"Hello"
```

여기까지입니다! List comprehension은 컬렉션 반복을 간결하게 만들어주는 쉬운 방법입니다.
