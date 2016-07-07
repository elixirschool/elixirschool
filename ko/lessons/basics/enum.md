---
layout: page
title: Enum
category: basics
order: 3
lang: ko
---

컬렉션들을 열거하기 위한 일련의 알고리즘.

{% include toc.html %}

## Enum

`Enum` 모듈은 우리가 지난 강의에서 배웠던 컬렉션들을 이용하기 위한 100가지 이상의 함수들을 포함하고 있습니다.

이 강의에서는 그 함수들 중에서도 일부분을 다룰 것입니다. 전체적인 부분을 학습하실 분들께서는 공식 [`Enum`](http://elixir-lang.org/docs/stable/elixir/Enum.html) 문서를 보시면 되겠습니다; 지연 열거(lazy enumeration)를 이용하시려면 [`Stream`](http://elixir-lang.org/docs/stable/elixir/Stream.html) 모듈을 이용해보세요.


### all?

흔히들 `Enum` 모듈을 이용할 때 `all?`을 사용하면, 컬렉션의 아이템에 적용할 함수를 넘기게 됩니다. 컬렉션의 모든 요소가 `true`로 평가되지 않으면, `all?`은 `false`를 반환할 것입니다:

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

위에서 설명한 것과는 다르게, `true`로 평가되는 아이템이 하나라도 있으면 `any?`는 `true`를 반환할 것입니다:

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk

컬렉션을 작은 묶음으로 쪼개야 할 필요가 있다면, `chunk`는 여러분이 찾고 있을 그 함수라 할 수 있습니다:

```elixir
iex> Enum.chunk([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

`chunk`에는 몇 가지 옵션이 있습니다만, 여기서는 이에 대해 다루지 않을 것입니다. 더 알아보고자 하신다면 [`chunk/2`](http://elixir-lang.org/docs/stable/elixir/Enum.html#chunk/2) 공식 문서를 참고해보세요.

### chunk_by

컬렉션을 크기가 아닌 다른 기준에 근거해서 묶을 필요가 있다면, `chunk_by`를 사용할 수 있습니다:

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
```

### each

새로운 값을 만들어내지 않고 컬렉션에 대해 반복하는 건 중요할 수도 있습니다. 이런 경우에는 `each`를 사용합니다:

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
```

__참고__: `each` 메서드는 `:ok`라는 애텀을 반환합니다.
ㄹ
### map

각 아이템마다 함수를 적용하여 새로운 컬렉션을 만들어내고자 한다면 `map` 함수를 써보세요:

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

컬렉션 내의 `최소(min)` 값을 찾아보세요:

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

### max

컬렉션 내의 `최대(max)` 값을 반환합니다:

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

### reduce

`reduce`를 이용하면, 컬렉션을 하나의 값으로 추려낼 수 있습니다. 이를 이용하려면, 선택사항으로 축적자를(예를 들면 `10`) 함수에 전달합니다; 만약 축적자가 제공되지 않는다면, 컬렉션의 첫번째 원소가 대신 그 역할을 합니다:  

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16
iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6
```

### sort

두 가지 `sort` 함수들을 이용하면, 쉽게 컬렉션들을 정렬할 수 있습니다. 정렬되는 순서를 결정하기 위해, 첫번째 옵션으로 Elixir에서 정의된 타입 정렬 순서를 이용합니다.

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

또 하나의 옵션은 우리에게 정렬 함수를 제공할 수 있게 합니다:

```elixir
# with our function
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# without
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq

우리는 `uniq`를 이용하여 컬렉션 내의 중복요소를 제거할 수 있습니다:

```elixir
iex> Enum.uniq([1, 2, 2, 3, 3, 3, 4, 4, 4, 4])
[1, 2, 3, 4]
```
