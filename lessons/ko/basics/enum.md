---
version: 1.7.0
title: Enum
---

열거 가능한 것들을 열거하기 위한 일련의 알고리즘.

{% include toc.html %}

## Enum

`Enum` 모듈은 우리가 지난 강의에서 배웠던 열거 가능한 것들을 이용하기 위한 70개를 넘는 함수들을 포함하고 있습니다.
[이전 강의](../collections/)에서 배웠던 튜플을 제외한 모든 컬렉션들은 열거 가능합니다.

이 강의에서는 그 함수들 중에서도 일부분만 다루지만 실제로 시험해 가며 해보도록 하겠습니다.
IEx에서 조금 시험에 보죠.

```elixir
iex> Enum.__info__(:functions) |> Enum.each(fn({function, arity}) ->
...>   IO.puts "#{function}/#{arity}"
...> end)
all?/1
all?/2
any?/1
any?/2
at/2
at/3
...
```

이를 통해 확실히 아주 많은 기능이 있다는 것을 알 수 있습니다. 그리고 각 기능은 분명한 이유가 있습니다.
열거형은 함수형 프로그래밍의 핵심이며, 방금 본 문서화 같은 다른 Elixir의 자랑과 함께 열거형은 개발에 매우 도움이 됩니다.

전체 목록을 보시려면 공식 [`Enum`](https://hexdocs.pm/elixir/Enum.html) 문서를 보시면 됩니다. 지연 열거(lazy enumeration)는 [`Stream`](https://hexdocs.pm/elixir/Stream.html) 모듈을 이용해보세요.


### all?

`Enum` 모듈의 대부분의 함수를 사용할 때와 마찬가지로, `all?/2`을 사용할 때는 컬렉션의 아이템에 적용할 함수를 넘기게 됩니다.
컬렉션의 모든 요소가 `true`로 평가되지 않으면, `all?/2`은 `false`를 반환할 것입니다.

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

위의 것과 다르게, `true`로 평가되는 아이템이 하나라도 있으면 `any?/2`는 `true`를 반환할 것입니다.

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk_every

컬렉션을 작은 묶음으로 쪼개야 한다면, `chunk_every/2`가 찾고 있을 그 함수입니다.

```elixir
iex> Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

`chunk_every/4`에는 몇 가지 옵션이 있습니다만, 여기서는 이에 대해 다루지 않을 것입니다. 더 알아보고자 하신다면 [`chunk_every/4` 공식 문서](https://hexdocs.pm/elixir/Enum.html#chunk_every/4)를 참고해보세요.

### chunk_by

컬렉션을 크기가 아닌 다른 기준에 근거해서 묶을 필요가 있다면, `chunk_by/2`를 사용할 수 있습니다.
열거할 수 있는 컬렉션과 함수를 받아와서, 주어진 함수의 결과값이 변할 때마다 그룹을 새로 시작합니다.

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
iex> Enum.chunk_by(["one", "two", "three", "four", "five", "six"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"], ["six"]]
```

### map_every

가끔 컬렉션의 묶음을 뽑아내는 것만으로는 정확히 원하는 것을 얻기 힘들 때가 있습니다.
`map_every/3`은 그런 경우에 매우 유용할 수 있습니다. 모든 `n`번째 아이템을 가져오며, 항상 첫번째 것에도 적용합니다.

```elixir
# 매 세번째 아이템에 함수를 적용합니다
iex> Enum.map_every([1, 2, 3, 4, 5, 6, 7, 8], 3, fn x -> x + 1000 end)
[1001, 2, 3, 1004, 5, 6, 1007, 8]
```

### each

새로운 값을 만들어내지 않고 컬렉션에 대해 반복하는 건 중요할 수도 있습니다. 이런 경우에는 `each/2`를 사용합니다.

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
:ok
```

__참고__: `each/2` 함수는 `:ok`라는 애텀을 반환합니다.

### map

각 아이템마다 함수를 적용하여 새로운 컬렉션을 만들어내고자 한다면 `map/2` 함수를 써보세요.

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

`min/1`은 컬렉션 내의 최소값을 찾습니다.

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

`min/2`는 같은 일을 합니다만, 열거할 컬렉션이 비어있는 경우에 반환할 최소값을 익명 함수로 지정할 수 있습니다.

```elixir
iex> Enum.min([], fn -> :foo end)
:foo
```

### max

`max/1`은 컬렉션 내의 최대값을 반환합니다.

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

`max/2`는 `max/1`에 대해서 `min/2`와 `min/1`의 관계처럼 동작합니다.

```elixir
Enum.max([], fn -> :bar end)
:bar
```

### filter

`filter/2` 함수를 이용하면, 주어진 함수를 사용하여 'true'로 평가되는 요소만 포함하도록 컬렉션을 필터링합니다.

```elixir
iex> Enum.filter([1, 2, 3, 4], fn(x) -> rem(x, 2) == 0 end)
[2, 4]
```

### reduce

`reduce/3`를 이용하면, 컬렉션을 하나의 값으로 추려낼 수 있습니다.
이를 이용하려면, 선택사항으로 축적자를(예를 들면 `10`) 함수에 전달합니다. 축적자를 제공하지 않으면, 열거할 목록의 첫 번째 원소가 그 역할을 대신합니다.

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16

iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6

iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
```

### sort

두 정렬 함수를 이용하면, 쉽게 컬렉션들을 정렬할 수 있습니다.

`sort/1`은 정렬 순서로 Erlang의 [텀(Term) 순서](http://erlang.org/doc/reference_manual/expressions.html#term-comparisons)를 사용합니다.

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

한편 `sort/2`는 직접 정렬 함수를 만들 수 있습니다.

```elixir
# 함수 사용
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# 함수를 사용하지 않음
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

편의를 위해, `sort/2`에 정렬 함수 대신 `:asc`, `:desc`를 넘길 수 있습니다.

```elixir
Enum.sort([2, 3, 1], :desc)
[3, 2, 1]
```

### uniq

`uniq/1`를 이용하여 열거 가능한 집합 내의 중복요소를 제거할 수 있습니다.

```elixir
iex> Enum.uniq([1, 2, 3, 2, 1, 1, 1, 1, 1])
[1, 2, 3]
```

### uniq_by

`uniq_by/2`도 열거 가능한 집합에서 중복을 제거합니다만, 고유한지를 비교할 함수를 넘길 수 있습니다.

```elixir
iex> Enum.uniq_by([%{x: 1, y: 1}, %{x: 2, y: 1}, %{x: 3, y: 3}], fn coord -> coord.y end)
[%{x: 1, y: 1}, %{x: 3, y: 3}]
```

### Enum에서의 캡처 연산자(&) 사용

Elixir의 Enum 모듈에 있는 많은 함수는 넘겨받은 열거 가능한 집합의 각 요소에 작용하는 익명 함수를 인수로 받습니다.

이러한 익명 함수는 종종 캡처 연산자(&)를 사용하여 간결하게 작성할 수 있습니다.

캡처 연산자가 어떻게 Enum 모듈과 함께 구현에 사용되는지 예제를 통해 알아봅시다.
아래에 있는 코드들은 동작이 같습니다.

#### 익명 함수에 캡처 연산자 사용하기

밑의 일반적인 예제는 익명함수를 `Enum.map/2`에 넘기는 표준적인 구문입니다.

```elixir
iex> Enum.map([1,2,3], fn number -> number + 3 end)
[4, 5, 6]
```

이제 캡처 연산자(&)로 구현합니다. 숫자 리스트([1,2,3])의 각 요소를 캡처하고 매핑 함수를 통해 전달 될 때 변수 &1에 각 요소를 할당합니다.

```elixir
iex> Enum.map([1,2,3], &(&1 + 3))
[4, 5, 6]
```

좀 더 리팩토링을 하자면, 캡처 연산자를 미리 익명 함수를 변수에 할당하고 `Enum.map/2` 함수에서 호출하게 할 수 있습니다.

```elixir
iex> plus_three = &(&1 + 3)
iex> Enum.map([1,2,3], plus_three)
[4, 5, 6]
```

#### 이름이 있는 함수에 캡처 연산자 사용하기

먼저 이름이 있는 함수를 만들고 `Enum.map/2`에 정의 된 익명 함수 내에서 호출해 보겠습니다.

```elixir
defmodule Adding do
  def plus_three(number), do: number + 3
end

iex>  Enum.map([1,2,3], fn number -> Adding.plus_three(number) end)
[4, 5, 6]
```

이제 캡처 연산자를 사용해 리팩터를 해보죠.

```elixir
iex> Enum.map([1,2,3], &Adding.plus_three(&1))
[4, 5, 6]
```

명시적으로 변수를 캡처하지 않고, 이름이 있는 함수를 직접 호출하면 가장 간결하게 작성할 수 있습니다.

```elixir
iex> Enum.map([1,2,3], &Adding.plus_three/1)
[4, 5, 6]
```
