%{
  version: "1.0.2",
  title: "메타 프로그래밍",
  excerpt: """
  메타 프로그래밍은 코드를 사용해서 코드를 작성하는 방법입니다. 이를 통해 Elixir에서는 필요에 따라 언어를 확장할 수 있으며, 동적으로 코드를 변경할 수도 있습니다. Elixir가 어떤 식으로 표현되고 있는지를 확인하는 부분부터 시작해서, 이를 변경하고 확장하는 법을 배워보겠습니다.

주의: 메타 프로그래밍은 다루기 어려우며, 필요할 때에만 사용해야 합니다. 과도한 사용은 이해하기도 어렵고 디버깅하기도 어려운 복잡한 코드를 만듭니다.
  """
}
---

## Quote

메타 프로그래밍의 첫번째 단계는 표현식이 어떻게 나타나는지를 이해하는 것입니다. Elixir 코드는 내부적으로 추상 문법 트리(Abstract Syntax Tree, AST)로 표현하는데, 이는 함수 이름과 메타 데이터, 함수의 인자를 포함하는 튜플로 이루어져 있습니다.

이러한 내부 구조를 확인하기 위해서 Elixir는 `quote/2` 함수를 제공합니다. `quote/2`를 사용해서 Elixir의 코드의 기저에 있는 표현식으로 변환할 수 있습니다.

```elixir
iex> quote do: 42
42
iex> quote do: "Hello"
"Hello"
iex> quote do: :world
:world
iex> quote do: 1 + 2
{:+, [context: Elixir, import: Kernel], [1, 2]}
iex> quote do: if value, do: "True", else: "False"
{:if, [context: Elixir, import: Kernel],
 [{:value, [], Elixir}, [do: "True", else: "False"]]}
```

처음의 3개는 튜플을 반환하지 않는 것을 확인하셨나요? 이 함수를 호출했을 때 자기 자신을 반환하는 리터럴이 다섯 가지 존재합니다.

```elixir
iex> :atom
:atom
iex> "string"
"string"
iex> 1 # All numbers
1
iex> [1, 2] # Lists
[1, 2]
iex> {"hello", :world} # 2 element tuples
{"hello", :world}
```

## Unquote

이제 코드의 내부 구조를 확인해 볼 수 있게 되었습니다만, 수정은 어떻게 할 수 있을까요? 새 코드나 값을 주입하기 위해서는 `unquote/1`를 사용합니다. `unquote/1`를 호출하면 호출된 값이 평가되어 AST에 주입됩니다. `unquote/1`의 동작을 확인하기 위해서 예를 몇 개 들어보죠.

```elixir
iex> denominator = 2
2
iex> quote do: divide(42, denominator)
{:divide, [], [42, {:denominator, [], Elixir}]}
iex> quote do: divide(42, unquote(denominator))
{:divide, [], [42, 2]}
```

첫 번째 예제에서는 변수 `denominator`는 결과로 반환되는 AST가 변수에 접근하기 위한 튜플을 포함하게끔 만들어져 있습니다. `unquote/1` 예제에서 생성된 코드는 위에서 본 코드 대신 `denominator`의 값을 포함하고 있습니다.

## 매크로

`quote/2`와 `unquote/1`에 대해서 이해했다면, 이제 매크로에 뛰어들 시간입니다. 모든 메타 프로그래밍과 마찬가지로, 매크로는 정말 필요할 때에만 사용해야 합니다.

매크로는 간단하게 설명하자면 애플리케이션 코드에 삽입할 수 있도록 감싸진 표현식을 반환하도록 설계된 특별한 함수입니다. 함수처럼 호출하는 것이 아니라, 명령문을 감싸진 표현식으로 대체하는 모습을 상상해주세요. 매크로만 있다면 Elixir를 확장하거나, 애플리케이션에 동적으로 코드를 추가할 수 있습니다.

`defmacro/2`를 사용해서 매크로를 정의해보죠. Elixir의 많은 부분들도 매크로로 구성되어 있습니다. 예를 들기 위해서 매크로로 `unless`를 구현해 보겠습니다. 매크로는 감싸진 표현식을 반환해야 한다는 점을 잊지 마세요.

```elixir
defmodule OurMacro do
  defmacro unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end
```

그럼 만든 모듈을 가져와서 사용해보죠.

```elixir
iex> require OurMacro
nil
iex> OurMacro.unless true, do: "Hi"
nil
iex> OurMacro.unless false, do: "Hi"
"Hi"
```

매크로는 애플리케이션의 코드를 대체하므로, 컴파일 시에 이를 제어할 수 있습니다. `Logger` 모듈에서 이에 적당한 예제를 찾아볼 수 있습니다. 로깅이 비활성화되어 있다면, 코드가 주입되지 않으며 로깅을 위한 어떤 참조나 함수 호출도 포함되지 않습니다. 이는 함수의 내부가 NOP(처리하지 않음)이더라도, 함수 호출에 대한 오버헤드가 존재하는 다른 언어와 다릅니다.

실제로 확인하기 위해서, 활성화/비활성화가 가능한 간단한 로거를 만들어 봅시다.

```elixir
defmodule Logger do
  defmacro log(msg) do
    if Application.get_env(:logger, :enabled) do
      quote do
        IO.puts("Logged message: #{unquote(msg)}")
      end
    end
  end
end

defmodule Example do
  require Logger

  def test do
    Logger.log("This is a log message")
  end
end
```

로깅을 활성화하면, `test` 함수는 다음과 같은 모습이 됩니다.

```elixir
def test do
  IO.puts("Logged message: #{"This is a log message"}")
end
```

로깅을 비활성화하는 경우, 코드는 다음처럼 생성됩니다.

```elixir
def test do
end
```

## 디버깅

좋아요. 이제 `quote/2`, `unquote/1`의 사용법과 매크로 작성법을 배웠습니다. 하지만 큰 덩어리의 감싸진 코드가 있고 그걸 이해해야 한다면 어떻게 해야할까요? 이 경우 `Macro.to_string/2`를 사용할 수 있습니다. 이 예제를 살펴봅시다.

```elixir
iex> Macro.to_string(quote(do: foo.bar(1, 2, 3)))
"foo.bar(1, 2, 3)"
```

그리고 매크로로 생성된 코드를 확인하고 싶다면, 코드를 `Macro.expand/2`, `Macro.expand_once/2`로 합칠 수 있습니다. 이 함수는 주어진 감싸진 코드로 매크로를 확장합니다. 첫 번째는 여러 번 확장됩니다. 하지만 뒤에 것은 한번만 확장됩니다. 예를 들어, 이 전 단락의 `unless` 예제를 수정해 봅시다.

```elixir
defmodule OurMacro do
  defmacro unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end

require OurMacro

quoted =
  quote do
    OurMacro.unless(true, do: "Hi")
  end
```

```elixir
iex> quoted |> Macro.expand_once(__ENV__) |> Macro.to_string |> IO.puts
if(!true) do
  "Hi"
end
```

같은 코드를 `Macro.expand/2`로 실행하면, 흥미로운 결과가 나옵니다.

```elixir
iex> quoted |> Macro.expand(__ENV__) |> Macro.to_string |> IO.puts
case(!true) do
  x when x in [false, nil] ->
    nil
  _ ->
    "Hi"
end
```

Elixir에서 `if`는 매크로라 했던 것을 기억하시나요? 여기에서 기저의 `case` 구문으로 확장되는 것을 확인할 수 있습니다.

### Private 매크로

일반적이지는 않지만, Elixir는 Private 매크로도 지원합니다. `defmacrop`를 사용해서 정의할 수 있으며, 정의된 모듈에서만 호출할 수 있습니다. Private 매크로는 반드시 호출되기 전에 정의되어야 합니다.

### 청결한 매크로(Macro Hygiene)

청결한 매크로는 전개했을 때, 호출된 컨텍스트와 어떻게 상호작용할까요? 기본적으로 Elixir 매크로는 청결하며 컨텍스트와 충돌하지 않습니다.

```elixir
defmodule Example do
  defmacro hygienic do
    quote do: val = -1
  end
end

iex> require Example
nil
iex> val = 42
42
iex> Example.hygienic
-1
iex> val
42
```

`val`을 조작하고 싶은 경우에는 어떻까요? 청결하지 않은 변수를 원한다는 것을 알리기 위해서 `var!/2`를 사용하면 됩니다. `var!/2`를 사용하도록 예제를 고쳐봅시다.

```elixir
defmodule Example do
  defmacro hygienic do
    quote do: val = -1
  end

  defmacro unhygienic do
    quote do: var!(val) = -1
  end
end
```

컨텍스트와 어떻게 상호작용하는지를 비교해보세요.

```elixir
iex> require Example
nil
iex> val = 42
42
iex> Example.hygienic
-1
iex> val
42
iex> Example.unhygienic
-1
iex> val
-1
```

매크로에서 `var!/2`를 사용하는 것으로 매크로에게 `val` 값을 넘기지 않고, 이를 조작하였습니다. 청결하지 않은 매크로를 사용하는 것은 최소화해야 합니다. `var!/2`를 사용하는 것은 변수 해결시에 충돌이 발생할 위험성을 증가시키게 됩니다.

### 바인딩

이미 `unquote/1`라는 편리한 매크로를 배웠습니다만, 이외에도 코드에 값을 주입하는 바인딩이라는 방법이 있습니다. 변수 바인딩을 통해 매크로의 내부에 여러 변수를 포함하고, 한번만 quote 되도록 보장하는 것으로 예상치 못한 재평가를 회피할 수 있습니다. 바인딩된 변수를 사용하려면 `quote/2`의 `bind_quoted` 옵션에 키워드 리스트를 넘겨주면 됩니다.

`bind_quote`의 이점을 직접 확인해보기 위해서 재평가 문제가 있는 예제를 봅시다. 식을 두번 출력하는 단순한 매크로입니다.

```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote do
      IO.puts(unquote(expr))
      IO.puts(unquote(expr))
    end
  end
end
```

현재 시스템 시간을 넘기고, 같은 내용이 두 번 출력될 것이라고 기대합니다.

```elixir
iex> Example.double_puts(:os.system_time)
1450475941851668000
1450475941851733000
```

시간이 다릅니다! 무슨 일이 있었던 걸까요? `unquote/1`를 같은 표현식에 여러 번 사용하는 것은 재평가를 발생시키며 예상치 못한 결과를 가져옵니다. `bind_quoted`를 사용해서 예제를 변경해봅시다.

```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote bind_quoted: [expr: expr] do
      IO.puts(expr)
      IO.puts(expr)
    end
  end
end

iex> require Example
nil
iex> Example.double_puts(:os.system_time)
1450476083466500000
1450476083466500000
```

`bind_quoted`를 통해 기대하는 결과를 얻었습니다. 같은 시간이 두 번 출력됩니다.

여기까지 Elixir를 필요에 맞게 확장하기 위한 도구인 `quote/2`, `unquote/1`, `defmacro/2`에 대해서 배웠습니다.
