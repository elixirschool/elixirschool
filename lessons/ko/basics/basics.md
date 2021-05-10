%{
  version: "1.1.2",
  title: "기본",
  excerpt: """
  Elixir를 시작합시다. 기본적인 타입과 연산자를 배워봅시다.
  """
}
---
<<<<<<< HEAD
version: 1.3.0
title: 기본
---

Elixir를 시작합시다. 기본적인 타입과 연산자를 배워봅시다.

{% include toc.html %}
=======
>>>>>>> f749d641 (Update KO to NimblePublisher format)

## 시작하기

### Elixir 설치하기

elixir-lang.org 홈페이지의 [Installing Elixir](http://elixir-lang.org/install.html) 가이드에서 운영체제별로 설치하는 방법을 알아볼 수 있습니다.

Elixir를 설치하고 나서 어떤 버전이 설치되었는지 손쉽게 찾을 수 있습니다.

    $ elixir -v
    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}]  [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Elixir {{ site.elixir.version }}

### 대화형 모드 건드려보기

Elixir를 설치하면 대화형 셸인 `IEx`가 함께 설치됩니다. `IEx`를 사용하여 Elixir 코드를 입력하면서 바로바로 실행할 수 있습니다.

`iex`를 실행하는 걸로 시작해보아요.

    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}]  [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
    iex>

주의: 윈도우 PowerShell에서는 `iex.bat`으로 입력해야 합니다.

여기서 계속 나아가봅시다. 간단한 코드를 조금 써 보면서 체험해보세요.

```elixir
iex> 2+3
5
iex> 2+3 == 5
true
iex> String.length("The quick brown fox jumps over the lazy dog")
43
```

여기서 입력해 본 모든 코드를 이해하지 못하더라도 벌써부터 걱정하지 마시고, 어떤 느낌인지 감만 잡아보세요.

## 기본적인 데이터 타입

### 정수

```elixir
iex> 255
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

### 실수

Elixir에서 실수는 소수점 뒤로 숫자가 적어도 하나 필요합니다. 실수는 배정밀도(64 bit double precision)로 부동 소수점 숫자를 처리하고, `e`를 사용하여 10의 지수를 표현할 수도 있습니다.

```elixir
iex> 3.14
3.14
iex> .14
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```


### 부울 값

Elixir에서는 `true`와 `false`로 부울 값을 표현할 수 있습니다. `false`와 `nil`만 거짓으로 취급하며, 나머지는 전부 참으로 간주합니다.

```elixir
iex> true
true
iex> false
false
```

### 애텀

애텀은 이름이 그대로 값이 되는 상수입니다.
Ruby에서 사용되는 심볼과 비슷한 느낌입니다.

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

부울 값 `true`와 `false`도 애텀입니다. 각각 `:true`와 `:false`로도 표현할 수 있습니다.

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

Elixir에서 사용하는 모듈의 이름도 애텀입니다.
`Myapp.MyModule`는 올바른 애텀입니다. 아직 정의하지 않았다고 하더라도 올바른 애텀입니다.

```elixir
iex> is_atom(MyApp.MyModule)
true
```

애텀은 Erlang 라이브러리에서 모듈을 (내장된 것도 포함해서) 참조할 때에도 사용합니다.

```elixir
iex> :crypto.strong_rand_bytes 3
<<23, 104, 108>>
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

Elixir에는 이보다 더 복잡한 데이터 타입도 있습니다. 이런 부분은 [컬렉션](../collections/)이나 [함수](../functions/)를 다룰 때 조금 더 알아보도록 하겠습니다.

## 기본적인 연산

### 수치 연산

Elixir에서 `+`, `-`, `*`, `/` 같은 보자마자 알 수 있는 기본적인 연산자를 사용할 수 있습니다. `/`는 항상 실수를 반환한다는 점에 조심하세요.

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

정수로 된 몫이나 나머지 (예: 모듈로 연산)를 구하고 싶을 때 Elixir에 내장된 함수 두 개를 유용하게 사용할 수 있습니다.

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### 논리 연산

Elixir에서 논리 연산자로 `||`와 `&&`, `!`를 타입에 관계없이 사용할 수 있습니다.
논리 연산은 모든 타입을 지원합니다.

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

반면 `and`, `or`, `not`은 **반드시** 첫번째 인자가 부울 값(`true`나 `false`)이어야 합니다.

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

주의: Elixir의 `and`와 `or`는 사실 Erlang의 `andalso`와 `orelse`에 대응합니다.

### 비교 연산

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

정수와 실수의 타입까지 엄격하게 비교할 때에는 `===`을 사용합니다.

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Elixir에서 비교 연산자를 사용할 때, 타입에 관계없이 비교할 수 있다는 점이 중요합니다. 정렬을 할 때 유용할 수도 있겠네요. 타입별로 정렬 순서까지 외워야 하는 건 아니지만, 타입별로 정렬을 할 수 있다는 점은 알아두는 게 좋습니다.

```elixir
숫자 < 애텀 < 참조 < 함수 < 포트 < pid < 튜플 < 맵 < 리스트 < 비트스트링
```

이런 특징은 다른 언어에서는 찾아보기 힘든 신기하지만 문법에 맞는 비교 연산을 사용할 수 있게 해 줍니다.

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### 문자열 내부 식 전개

Ruby를 사용한 적이 있다면 Elixir의 문자열 내부 식 전개는 익숙해 보일 것입니다.

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### 문자열 합치기

`<>` 연산자로 문자열을 합칠 수 있습니다.

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
