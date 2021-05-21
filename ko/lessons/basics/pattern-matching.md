---
version: 1.0.1
title: 패턴 매칭
---

패턴 매칭은 Elixir의 강력한 기능입니다. 이를 이용하면 간단한 값, 자료 구조, 심지어는 함수까지도 매치시킬 수 있습니다. 이번 강의에서는 패턴 매칭이 어떻게 사용되는지 알아보기로 합니다.

{% include toc.html %}

## 매치 연산자

조금 꼬아 볼까요? Elixir에서 `=`는 사실 대수에서 등호와 같은 역할을 하는 매치 연산자입니다. 이것을 쓰면 전체 표현식이 방정식으로 바뀌고 Elixir가 왼쪽의 값과 오른쪽의 값을 매치시킵니다. 매치가 성공하면 방정식의 값을 반환하고, 그렇지 않을 경우 에러를 발생시킵니다. 아래 코드를 보십시오.

```elixir
iex> x = 1
1
```

이제 간단한 매칭을 한 번 해 봅시다.

```elixir
iex> 1 = x
1
iex> 2 = x
** (MatchError) no match of right hand side value: 1
```

이번에는 우리가 알고 있는 컬렉션들을 가지고 해 봅시다.

```elixir
# 리스트
iex> list = [1, 2, 3]
[1, 2, 3]
iex> [1, 2, 3] = list
[1, 2, 3]
iex> [] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

iex> [1 | tail] = list
[1, 2, 3]
iex> tail
[2, 3]
iex> [2 | _] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

# 튜플
iex> {:ok, value} = {:ok, "Successful!"}
{:ok, "Successful!"}
iex> value
"Successful!"
iex> {:ok, value} = {:error}
** (MatchError) no match of right hand side value: {:error}
```

## 핀 연산자

매치 연산자의 좌변에 변수가 포함되어 있을 때에는 값의 대입이 일어납니다. 하지만 경우에 따라서는, 변수에 새로운 값이 대입되는 것을 원치 않을 수도 있습니다. 이러한 상황에서는 핀 연산자 `^`를 사용해야 합니다.

핀 연산자를 이용하여 변수를 고정시키면 변수에 새 값을 대입하지 않고 기존의 값과 매칭을 하게 됩니다. 이것이 어떻게 동작하는지 봅시다.

```elixir
iex> x = 1
1
iex> ^x = 2
** (MatchError) no match of right hand side value: 2
iex> {x, ^x} = {2, 1}
{2, 1}
iex> x
2
```

Elixir 1.2에서는 맵의 키와 함수의 절에 대한 핀이 도입되었습니다.

```elixir
iex> key = "hello"
"hello"
iex> %{^key => value} = %{"hello" => "world"}
%{"hello" => "world"}
iex> value
"world"
iex> %{^key => value} = %{:hello => "world"}
** (MatchError) no match of right hand side value: %{hello: "world"}
```

아래는 함수의 절에 대한 핀 연산의 예입니다.

```elixir
iex> greeting = "Hello"
"Hello"
iex> greet = fn
...>   (^greeting, name) -> "Hi #{name}"
...>   (greeting, name) -> "#{greeting}, #{name}"
...> end
#Function<12.54118792/2 in :erl_eval.expr/5>
iex> greet.("Hello", "Sean")
"Hi Sean"
iex> greet.("Mornin'", "Sean")
"Mornin', Sean"
```
