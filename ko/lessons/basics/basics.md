---
layout: page
title: 기본
category: basics
order: 1
lang: ko
---

Elixir를 준비하고, 기본적인 타입과 연산을 배워봅시다.

{% include toc.html %}

## 준비

### Elixir 설치하기

Elixir-lang.org 홈페이지의 [Elixir 설치 가이드](http://elixir-lang.org/install.html)에서 각 운영체제별로 설치하는 방법을 알아볼 수 있습니다.

### 대화형 모드

Elixir를 설치하면 대화형 셸인 `iex`가 함께 설치됩니다. `iex`를 사용하여 Elixir 코드를 입력하면서 바로바로 실행할 수 있습니다.

`iex`를 실행하는 걸로 시작해보아요.

	Erlang/OTP 17 [erts-6.4] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

	Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
	iex>

## 기본 타입

### 정수

```elixir
iex> 255
255
iex> 0xFF
255
```

아래에서 보는 것처럼 2진수와 8진수, 16진수 숫자도 기본적으로 사용할 수 있습니다.

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### 부동 소수점

Elixir에서는 64비트 정밀도(double precision)로써 부동 소수점 숫자를 처리하고, `e`를 사용하여 10의 지수를 표현할 수도 있습니다. 부동 소수점 숫자를 표현할 때에는 소수점 앞뒤로 숫자가 한 개 이상 필요합니다.

```elixir
iex> 3.41
3.41
iex> .41
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```


### 불리언 대수

Elixir에서는 `true`와 `false`로 불리언 대수를 표현할 수 있습니다. `false`와 `nil`만 거짓으로 취급하며, 나머지는 전부 참으로 간주합니다.

```elixir
iex> true
true
iex> false
false
```

### 애텀

애텀은 이름이 그대로 값이 되는 상수입니다. Ruby에서 사용되는 심볼과 비슷한 느낌입니다.

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

참고: 불리언 값 `true`와 `false`도 애텀입니다. 각각 `:true`와 `:false`로도 표현할 수 있습니다.

```elixir
iex> true |> is_atom
true
iex> :true |> is_boolean
true
iex> :true === true
true
```

### 문자열

Elixir에서 문자열은 내부적으로 UTF-8로 인코딩되며, 큰따옴표 두 개로 감싸 표현합니다.

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

문자열 내부에서 줄바꿈과 이스케이프도 할 수 있습니다.

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

## 기본 연산

### 수치 연산자

Elixir에서 `+`와 `-`, `*`와 `/` 같은 보자마자 알 수 있는 기본적인 연산자를 사용할 수 있습니다. `/`는 항상 부동 소수점을 리턴한다는 점에 조심하세요.

```elixir
iex> 2 + 2
4
iex> 2 - 1
1
iex> 2 * 5
10
iex> 10 / 5
2.0
```

정수로 된 몫이나 나머지를 구하고 싶을 떼 Elixir에 내장된 함수 두 개를 유용하게 사용할 수 있습니다.

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### 불리언 대수 연산자

Elixir에서 불리언 대수 연산자로 `||`와 `&&`, `!`를 타입에 관계없이 사용할 수 있습니다.

```elixir
iex> -20 || true
-20
iex> false || 42
42

iex> 42 && true
true
iex> 42 && nil
nil

iex> !42
false
iex> !false
true
```

반면 `and`와 `or`, `not`은 **반드시** 첫번째 인수가 불리언 값(`true`나 `false`)이어야 합니다.

```elixir
iex> true and 42
42
iex> false or true
true
iex> not false
true
iex> 42 and true
** (ArgumentError) argument error: 42
iex> not 42
** (ArgumentError) argument error
```

### 비교 연산자

`==`, `!=`, `===`, `!==`, `<=`, `>=`, `<`, `>` 같은 다른 언어에서도 익숙했던 비교 연산자를 Elixir에서도 사용할 수 있습니다.

```elixir
iex> 1 > 2
false
iex> 1 != 2
true
iex> 2 == 2
true
iex> 2 <= 3
true
```

정수와 부동 소수점을 비교하는 것처럼 타입까지 깐깐하게 비교할 때에는 `===`을 사용합니다.

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Elixir에서 비교 연산자를 사용할 때, 타입에 관계 없이 비교할 수 있다는 점이 중요합니다. 정렬을 할 때 유용할 수도 있겠네요. 타입별로 정렬 순서까지 외워야 하는 건 아니지만, 타입별로 정렬을 할 수 있다는 점은 알아두는 게 좋습니다.

```
숫자 < 애텀 < 참조 < 함수 < 포트 < pid < 튜플 < 맵 < 리스트 < 비트스트링
```

이런 특징은 다른 언어에서는 찾아보기 힘든 재미있는 비교 연산을 문법에 맞게 사용할 수 있게 해 줍니다.

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### 문자열 내부 식 전개

Ruby를 사용한 적이 있다면 Elixir에서 문자열 내부에서 식 전개를 하는 모습이 익숙할 거예요.

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### 문자열 합치기

`<>` 연산자로 문자열을 합칠 수 있습니다:

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
