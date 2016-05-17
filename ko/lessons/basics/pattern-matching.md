---
layout: page
title: 패턴 매칭
category: basics
order: 4
lang: ko
---

패턴 매칭은 Elixir의 강력한 기능입니다. 이를 이용하면 간단한 값, 자료 구조, 심지어는 함수까지도 매치시킬 수 있습니다. 이번 레슨에서는 패턴 매칭이 어떻게 사용되는지 알아보기로 합니다.

{% include toc.html %}

## 매치 연산자

변화구를 받을 준비가 되셨습니까? Elixir에서 `=`는 사실 매치 연산자입니다. 매치 연산자를 통해서 값을 대입하고 나서 매치시킬 수 있습니다. 아래 코드를 보십시오.

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
iex> [1, 2, 3] = list
[1, 2, 3]
iex> [] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

iex> [1|tail] = list
[1, 2, 3]
iex> tail
[2, 3]
iex> [2|_] = list
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

우리는 방금 매치 연산자의 좌변에 변수가 포함되어 있을 때에는 값의 대입이 일어난다는 것을 알았습니다. 하지만 경우에 따라서는, 변수에 새로운 값이 대입되는 것을 원치 않을 수도 있습니다. 이러한 상황에서는 핀 연산자 `^`를 사용해야 합니다.

When we pin a variable we match on the existing value rather than rebinding to a new one.  Let's take a look at how this works:

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

Elixir 1.2 introduced support for pins in map keys and function clauses:

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

An example of pinning in a function clause:

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
