---
version: 1.0.0
layout: page
title: Enum
category: basics
order: 3
lang: ko
---

컬렉션들을 열거하기 위한 일련의 알고리즘.

{% include toc.html %}

## Enum

`Enum` 모듈은 우리가 지난 강의에서 배웠던 컬렉션들을 이용하기 위한 100개 조금 넘는 함수들을 포함하고 있습니다.

이 강의에서는 그 함수들 중에서도 일부분만 다루지만 실제로 시험해 가며 해보도록 하겠습니다.
IEx에서 조금 시험에 보죠.

```elixir
iex
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

이를 통해 아주 많은 기능이 있고 기능마다 분명한 이유가 있음이 자명해 졌습니다.
열거형은 함수형 프로그래밍의 핵심이며, 놀랍도록 유용합니다.
방금 본 문서화 같은 다른 Elixir의 자랑과 함께 열거형은 개발에 매우 도움이 됩니다.

전체 목록을 보시려면 공식 [`Enum`](https://hexdocs.pm/elixir/Enum.html) 문서를 보시면 됩니다. 지연 열거(lazy enumeration)는 [`Stream`](https://hexdocs.pm/elixir/Stream.html) 모듈을 이용해보세요.


### all?

흔히들 `Enum` 모듈을 이용할 때 `all?`을 사용하면, 컬렉션의 아이템에 적용할 함수를 넘기게 됩니다. 컬렉션의 모든 요소가 `true`로 평가되지 않으면, `all?`은 `false`를 반환할 것입니다.

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

위의 것과 다르게, `true`로 평가되는 아이템이 하나라도 있으면 `any?`는 `true`를 반환할 것입니다.

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk

컬렉션을 작은 묶음으로 쪼개야 할 필요가 있다면, `chunk`가 찾고 있을 그 함수입니다.

```elixir
iex> Enum.chunk([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

`chunk`에는 몇 가지 옵션이 있습니다만, 여기서는 이에 대해 다루지 않을 것입니다. 더 알아보고자 하신다면 [`chunk/2`](https://hexdocs.pm/elixir/Enum.html#chunk/2) 공식 문서를 참고해보세요.

### chunk_by

컬렉션을 크기가 아닌 다른 기준에 근거해서 묶을 필요가 있다면, `chunk_by/2`를 사용할 수 있습니다. 열거할 수 있는 컬렉션과 함수를 받아와서, 주어진 함수의 결과값이 변할 때마다 그룹을 새로 시작합니다.

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
iex> Enum.chunk_by(["one", "two", "three", "four", "five", "six"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"], ["six"]]
```

### map_every

가끔 컬랙션을 뽑아내는 것으로 정확히 원하는 것을 얻기 힘들 때가 있습니다. `map_every/3`은 그런 경우에 매우 유용할 수 있습니다. 컬랙션이 정렬 되어있다면 원하는 아이템만 고를 수 있습니다.

```elixir
iex> Enum.map_every([1, 2, 3, 4], 2, fn x -> x * 2 end)
[2, 2, 6, 4]
```

### each

새로운 값을 만들어내지 않고 컬렉션에 대해 반복하는 건 중요할 수도 있습니다. 이런 경우에는 `each`를 사용합니다.

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
:ok
```

__참고__: `each` 메서드는 `:ok`라는 애텀을 반환합니다.

### map

각 아이템마다 함수를 적용하여 새로운 컬렉션을 만들어내고자 한다면 `map` 함수를 써보세요.

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

`min/1`은 컬렉션 내의 `최소(min)` 값을 찾습니다.

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

`min/2`는 같은 일을 합니다만, 넘겨진 익명 함수로 `Enum`의 기본 값을 지정할 수 있습니다.

```elixir
iex> Enum.min([], fn -> :foo end)
:foo
```

### max

`max/1`은 컬렉션 내의 `최대(max)` 값을 반환합니다.

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

`max/2`는 같은 일을 하고 `min/2`처럼 동작해, 넘겨진 익명 함수로 `Enum`의 기본 값을 지정할 수 있습니다.

```elixir
Enum.max([], fn -> :bar end)
:bar
```

### reduce

`reduce`를 이용하면, 컬렉션을 하나의 값으로 추려낼 수 있습니다. 이를 이용하려면, 선택사항으로 축적자를(예를 들면 `10`) 함수에 전달합니다. 축적자를 제공하지 않으면, 컬렉션의 첫 번째 원소가 그 역할을 대신합니다.

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16
iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6
iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
```

### sort

두 가지 `sort` 함수들을 이용하면, 쉽게 컬렉션들을 정렬할 수 있습니다. 정렬되는 순서를 결정하기 위해, 첫번째 옵션으로 Elixir에서 정의된 타입 정렬 순서를 이용합니다.

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

또 하나의 옵션은 정렬 함수를 제공할 수 있게 합니다.

```elixir
# 함수 사용
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# 함수를 사용하지 않음
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq_by

`uniq_by/2`를 이용하여 컬렉션 내의 중복요소를 제거할 수 있습니다.

```elixir
iex> Enum.uniq_by([1, 2, 3, 2, 1, 1, 1, 1, 1], fn x -> x end)
[1, 2, 3]
```

이 함수는 전에는 `uniq/1`이었지만, Elixir 1.4에서 폐기예정이 되었습니다. 하지만 아직 (경고는 나오지만) 사용할 수 있습니다.
