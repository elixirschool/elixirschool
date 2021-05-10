%{
  version: "1.0.1",
  title: "Erlang 상호 운용",
  excerpt: """
  Erlang VM (BEAM) 위에서 작업하면서 추가된 이점 중 하나는 기존의 다양한 라이브러리를 사용할 수 있다는 점입니다. 상호 운용성은 우리의 Elixir 코드에서 이러한 라이브러리들과 Erlang 표준 라이브러리를 사용할 수 있도록 해줍니다. 이번 강의에서는 서드파티 Erlang 패키지와 더불어 표준 라이브러리의 기능에 접근하는 법을 알아봅니다.
  """
}
---

## 표준 라이브러리

Erlang의 방대한 표준 라이브러리는 애플리케이션의 어떤 Elixir 코드에서든지 접근할 수 있습니다. Erlang 모듈은 `:os`와 `:timer`와 같이 소문자 애텀으로 표현됩니다.

`:timer.tc`를 사용하여 주어진 함수의 실행 시간을 재 봅시다.

```elixir
defmodule Example do
  def timed(fun, args) do
    {time, result} = :timer.tc(fun, args)
    IO.puts("Time: #{time} μs")
    IO.puts("Result: #{result}")
  end
end

iex> Example.timed(fn (n) -> (n * n) * n end, [100])
Time: 8 μs
Result: 1000000
```

사용할 수 있는 모든 모듈의 목록은 [Erlang Reference Manual](http://erlang.org/doc/apps/stdlib/)을 참조하십시오.

## Erlang 패키지

앞의 강의에서 Mix를 다루고 의존성을 관리하는 법을 배웠습니다. Erlang 라이브러리를 포함시키는 것도 같은 방법으로 합니다. Erlang 라이브러리가 [Hex](https://hex.pm)에 게시되지 않았을 때에는 대신 git 저장소를 참조할 수도 있습니다.

```elixir
def deps do
  [{:png, github: "yuce/png"}]
end
```

이제 우리가 포함시킨 Erlang 라이브러리를 사용할 수 있습니다.

```elixir
png =
  :png.create(%{:size => {30, 30}, :mode => {:indexed, 8}, :file => file, :palette => palette})
```

## 눈에 띄는 차이점

Erlang을 어떻게 사용하는지 배웠기 때문에, 이제 Erlang 상호 운용을 하면서 자주 발생하는 실수들을 알아야 합니다.

### 애텀

Erlang의 애텀은 Elixir의 것과 상당히 비슷하지만 콜론 (`:`)이 없습니다. Erlang에서 애텀은 소문자 문자열과 언더스코어로 나타냅니다.

Elixir:

```elixir
:example
```

Erlang:

```erlang
example.
```

### 문자열

Elixir에서 문자열에 대한 이야기를 할 때는 UTF-8로 인코딩된 바이너리를 의미합니다. Erlang에서도 문자열은 쌍따옴표를 사용하지만, 이는 문자 리스트를 가리킵니다.

Elixir:

```elixir
iex> is_list('Example')
true
iex> is_list("Example")
false
iex> is_binary("Example")
true
iex> <<"Example">> === "Example"
true
```

Erlang:

```erlang
1> is_list('Example').
false
2> is_list("Example").
true
3> is_binary("Example").
false
4> is_binary(<<"Example">>).
true
```

한 가지 중요한 점은, 대부분의 오래된 Erlang 라이브러리는 바이너리를 지원하지 않기 때문에 Elixir 문자열을 문자 리스트로 변환해야 한다는 것입니다. 다행스럽게도 이 작업은 `to_charlist/1` 함수를 이용하여 손쉽게 할 수 있습니다.

```elixir
iex> :string.words("Hello World")
** (FunctionClauseError) no function clause matching in :string.strip_left/2

    The following arguments were given to :string.strip_left/2:

        # 1
        "Hello World"

        # 2
        32

    (stdlib) string.erl:1661: :string.strip_left/2
    (stdlib) string.erl:1659: :string.strip/3
    (stdlib) string.erl:1597: :string.words/2

iex> "Hello World" |> to_charlist |> :string.words
2
```

### 변수

Elixir:

```elixir
iex> x = 10
10

iex> x1 = x + 10
20
```

Erlang:

```erlang
1> X = 10.
10

2> X1 = X + 1.
11
```

이게 전부 입니다! 우리의 Elixir 애플리케이션에서 Erlang을 사용하는 것은 쉬우면서도 우리가 사용할 수 있는 라이브러리의 수를 두 배 가까이 늘려 줍니다.
