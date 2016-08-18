---
layout: page
title: 컬렉션
category: basics
order: 2
lang: ko
---

리스트, 튜플, 키워드, 맵 그리고 컴비네이터.

{% include toc.html %}

## 리스트

리스트(list)는 값들의 간단한 컬렉션입니다. 리스트는 여러 타입을 포함할 수 있으며 중복된 값들도 포함할 수 있습니다.

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir는 연결 리스트로서의 리스트를 구현합니다. 따라서 리스트의 길이를 구하는 것은 `O(n)` 연산이고, 이 때문에 보통 리스트의 앞에 값을 추가하는 것이 뒤에 추가하는 것보다 빠릅니다.

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> ["π"] ++ list
["π", 3.14, :pie, "Apple"]
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```


### 리스트 이어붙이기

리스트는 `++/2` 연산자를 이용해서 서로 이어붙일 수 있습니다.

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

### 리스트 빼기

`--/2` 연산자를 이용하면 리스트에 대한 뺄셈 연산이 가능합니다. 존재하지 않는 값은 빼도 안전합니다.

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

**참고:** 값을 매치시킬 때에는 [엄격한 비교](../basics/#comparison)를 사용합니다.

### Head / Tail

리스트를 사용할 때 리스트의 머리와 꼬리를 가지고 작업을 하는 경우가 많습니다. 머리는 리스트의 맨 첫 번째 원소이고, 꼬리는 그 나머지 원소들입니다. Elixir에서는 이러한 작업을 위해 `hd`와 `tl` 이 두 개의 유용한 메서드를 제공합니다.

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

앞서 언급한 함수들과 더불어서, `cons` 연산자 `|`를 이용할 수도 있습니다. 이러한 패턴은 차후 레슨에서 보게 될 것입니다.

> [역주] : `cons`는 Lisp 계열 언어에서 애텀과 리스트를 연결할 때 쓰이는 연산입니다. 첫번째 매개변수로 주어지는 애텀을 두번째 매개변수로 주어지는 리스트의 head 부분에 삽입하게 됩니다. `(cons 1 (2 3)) == (cons 1 (cons 2 (cons 3 nil))))`

```elixir
iex> [h|t] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> h
3.14
iex> t
[:pie, "Apple"]
```

## 튜플

튜플(tuples)은 리스트와 비슷하지만 메모리에 연속적으로 저장됩니다. 이 때문에 튜플의 길이를 구하는 것은 빠르지만 수정하는 것은 비용이 비쌉니다. 새로운 튜플이 통째로 메모리에 복사되어야 하기 때문이지요. 튜플은 중괄호를 사용해서 정의합니다.

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

튜플은 함수가 추가 정보를 반환하는 수단으로 자주 사용됩니다. 이것의 유용함은 패턴 매칭(pattern matching)을 배울 때 더 명확해질 것입니다.

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## 키워드 리스트

키워드(keywords)와 맵(maps)은 Elixir의 연관 컬렉션입니다. Elixir에서 키워드 리스트란 첫번째 원소가 atom인 특별한 튜플들의 리스트입니다. 따라서 키워드 리스트는 리스트와 성능이 비슷합니다.

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

키워드 리스트의 아래 세 가지 특징은 매우 중요합니다.

+ 모든 키는 atom입니다.
+ 키는 정렬되어 있습니다.
+ 키는 중복될 수 있습니다.

이러한 이유 때문에 키워드 리스트는 함수에 옵션을 전달하는 데 가장 많이 사용됩니다.

## 맵

Elixir에서 맵(maps)은 매우 유용한 키-값 저장소입니다. 키워드 리스트와는 다르게 맵의 키는 어떤 타입이든 될 수 있고 순서를 따르지 않습니다. 맵은 `%{}` 문법을 이용해서 정의할 수 있습니다.

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

Elixir 1.2부터는 변수를 맵의 키로 사용할 수 있습니다.

```elixir
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
```

만약 중복된 키가 맵에 추가되면 이전의 값을 새 값으로 교체합니다.

```elixir
iex> %{:foo => "bar", :foo => "hello world"}
%{foo: "hello world"}
```

위의 출력에서 볼 수 있듯이, 모든 키가 atom인 맵을 정의하기 위한 특별한 문법도 존재합니다.

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}

iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```

맵에는 또다른 특별한 문법이 있는데, 이로써 애텀 키를 통해 맵 내부를 열람하거나 수정할 수 있습니다.

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{map | foo: "baz"}
%{foo: "baz", hello: "world"}
iex> map.hello
"world"
```
