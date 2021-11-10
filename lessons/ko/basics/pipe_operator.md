%{
  version: "1.0.1",
  title: "파이프 연산자",
  excerpt: """
  파이프 연산자 `|>`는 수식의 결과를 다른 수식의 첫 번째 매개변수로 전달합니다.
  """
}
---

## 소개

프로그래밍을 하다보면 코드가 지저분해질 수 있습니다. 함수의 호출이 따라가기 힘들 정도로 많이 중첩되어 지저분해질 정도로요. 아래 중첩된 함수 호출을 생각해 봅시다.

```elixir
foo(bar(baz(new_function(other_function()))))
```

여기서, `other_function/0`의 값은 `new_function/1`로 전달되고, `new_function/1`에서 `baz/1`로, `baz/1`에서 `bar/1`로, 그리고 마지막으로 `bar/1`의 결과가 `foo/1`로 전달됩니다. Elixir에서는 이런 문법적인 혼란을 해소하기 위한 유용한 수단으로서 파이프 연산자를 제공합니다. `|>` 처럼 생긴 파이프 연산자는 **수식으로부터 결과를 받아서 다음 수식으로 전달합니다**. 이번에는 위의 코드를 바탕으로 파이프 연산자를 이용하여 다시 작성한 코드를 봅시다.

```elixir
other_function() |> new_function() |> baz() |> bar() |> foo()
```

파이프가 왼쪽에서 결과를 받아 오른쪽으로 넘깁니다.

## 예제

이 예제를 위해 Elixir의 String 모듈을 이용하겠습니다.

- 문자열 토큰화하기 (느슨하게)

```shell
iex> "Elixir rocks" |> String.split()
["Elixir", "rocks"]
```

- 모든 토큰을 대문자로 만들기

```shell
iex> "Elixir rocks" |> String.upcase() |> String.split()
["ELIXIR", "ROCKS"]
```

- 문자열 끝 부분 검사하기

```shell
iex> "elixir" |> String.ends_with?("ixir")
true
```

## 좋은 습관

함수의 인자 개수가 1 이상이면 반드시 괄호를 쓰세요. 이는 Elixir에게는 큰 문제가 되지 않지만 다른 프로그래머가 여러분의 코드를 잘못 이해할 수도 있기 때문입니다. 이는 파이프 연산자를 사용할 때에도 그렇습니다. 예를 들어, 세 번째 예제에서 `String.ends_with?/2`의 괄호를 지우면 아래와 같은 경고를 보게 됩니다.

```shell
iex> "elixir" |> String.ends_with? "ixir"
warning: parentheses are required when piping into a function call. For example:
# [역주] 경고: 함수 호출을 파이프로 연결할 때에는 괄호를 사용하세요. 예를 들면,

foo 1 |> bar 2 |> baz 3

is ambiguous and should be written as
# [역주] 위 코드는 모호하므로 아래와 같이 작성되어야 합니다.

foo(1) |> bar(2) |> baz(3)

true
```
