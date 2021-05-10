---
version: 1.0.1
title: 함수
---

Elixir를 포함한 많은 함수형 언어에서, 함수들은 일급 시민입니다. 우리는 Elixir를 특별하게 해주는 함수의 유형에 대해 배우고, 그것을 어떻게 이용하는지 배울 것입니다.

{% include toc.html %}

## 익명 함수

익명 함수는 말그대로 이름이 없습니다. `Enum` 수업에서 보았듯이, 함수는 빈번히 다른 함수로 넘겨지게 됩니다. Elixir에서 익명 함수를 정의하기 위해, `fn` 그리고 `end` 키워드가 필요합니다. 익명 함수 내에서 매개변수의 개수를 정의할 수 있으며, 함수의 몸체는 `->`로 구분됩니다.

기초적인 예제를 보도록 합시다.

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### &으로 줄여쓰기

Elixir로 프로그래밍 하다보면, 익명 함수를 이용하여 줄여쓰는 것을 흔히 볼 수 있습니다.

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

줄여쓰기를 했을 때 매개변수들은 `&1`, `&2`, `&3`, 등과 같이 다룰 수 있다고 추측할 수 있습니다.

## 패턴매칭

Elixir에서 패턴매칭은 단순히 변수를 다루는 데서 그치지 않고, 함수 시그니처에서도 적용될 수 있다는 것을 이 섹션에서 확인할 것입니다.

Elixir에서는 매칭하여 대응되는 함수를 불러일으키는 매개변수의 집합을 식별하기 위해 패턴매칭을 사용합니다.

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
1
iex> handle_result.({:ok, some_result})
Handling result...
:ok
iex> handle_result.({:error})
An error has occurred!
```

## 이름이 있는 함수

차후에 호출할 수 있도록 함수를 이름과 같이 정의할 수 있습니다. 이는 모듈 내에서 `def` 키워드로 정의됩니다. 지금은 이름이 있는 함수를 다루는 것에 집중하도록 하고, 다음 수업에서 모듈에 대해 더 배울 것입니다.

모듈 내에서 정의된 함수는 다른 모듈에서 접근이 가능하며, 이는 Elixir에서 특히 유용한 요소 중 하나입니다.

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

함수의 몸체를 한 줄로 쓰고 싶은 경우, 우리는 `do:`를 이용하여 축약할 수 있습니다.

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

패턴매칭에 대한 지식과 이름있는 함수를 이용하여 재귀를 맛보도록 하죠.

```elixir
defmodule Length do
  def of([]), do: 0
  def of([_ | tail]), do: 1 + of(tail)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### 함수 이름짓기와 인자 개수

앞서 함수는 주어진 이름과 인자 개수를 조합해 이름짓는다는 이야기를 했습니다. 이 말은 이렇게 할 수 있다는 이야기입니다.

```elixir
defmodule Greeter2 do
  def hello(), do: "Hello, anonymous person!"   # hello/0
  def hello(name), do: "Hello, " <> name        # hello/1
  def hello(name1, name2), do: "Hello, #{name1} and #{name2}"
                                                # hello/2
end

iex> Greeter2.hello()
"Hello, anonymous person!"
iex> Greeter2.hello("Fred")
"Hello, Fred"
iex> Greeter2.hello("Fred", "Jane")
"Hello, Fred and Jane"
```

함수 이름을 주석으로 달아두었습니다. 첫 번째 구현은 인자를 받지 않습니다. 그래서 `hello/0`라 합니다. 두 번째는 하나의 인자를 받고 `hello/1`라 하고 계속 이런 식입니다. 다른 언어의 함수 오버로드와는 다르게 3개의 서로 _다른_ 함수가 존재합니다.(아까 전에 설명했던 패턴매칭은 인자 개수가 같은 함수의 선언이 여러 번 있을 때만 적용됩니다.)

### Private 함수

다른 모듈에서 함수에 접근하는 것을 원하지 않는다면, 정의된 모듈 내에서만 호출될 수 있도록 private 함수를 이용할 수 있습니다. Elixir에서는 그것들을 `defp` 키워드를 이용하여 정의할 수 있습니다.

```elixir
defmodule Greeter do
  def hello(name), do: phrase <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### 가드

[제어 구조](../control-structures) 강의에서 가드에 대해 간략하게 다뤘으니, 이제 이름이 있는 함수에 어떻게 적용할 수 있는지 알아보도록 하겠습니다. Elixir에서 함수가 매치되기만 하면, 존재하는 어떤 가드든지 테스트될 것입니다.

동일한 시그니쳐를 가진 두 함수가 정의된 다음의 예제에서, 인자의 타입에 따라 어떤 함수를 이용할 지 가드를 통해 결정합니다.

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase() <> name
  end

  defp phrase, do: "Hello, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"
```

### 기본값 인자

인자에 기본값을 할당하고 싶다면, `인자 \\ 값` 문법을 이용할 수 있습니다.

```elixir
defmodule Greeter do
  def hello(name, language_code \\ "en") do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello("Sean", "en")
"Hello, Sean"

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.hello("Sean", "es")
"Hola, Sean"
```

가드 예제에 기본값 인자를 적용한 경우를 다뤄보도록 합시다. 아마 다음과 같이 나타낼 수 있을 겁니다.

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code \\ "en") when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) iex:31: definitions with multiple clauses and default values require a header. Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b) do ... end

one should write:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end

def hello/2 has multiple clauses and defines defaults in one or more clauses
    iex:31: (module)
```

Elixir에서는 여러 매칭 함수에 기본값 인자가 들어가는 것을 권장하지 않습니다. 혼동할 수 있기 때문입니다. 이를 다루기 위해서, 기본값 인자가 들어있는 함수 선언문을 추가해봅시다.

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en")

  def hello(names, language_code) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code) when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "es"
"Hola, Sean, Steve"
```
