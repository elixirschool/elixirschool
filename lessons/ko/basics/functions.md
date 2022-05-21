%{
  version: "1.3.0",
  title: "함수",
  excerpt: """
  Elixir를 포함한 많은 함수형 언어에서, 함수들은 일급 시민입니다. 우리는 Elixir를 특별하게 해주는 함수의 유형에 대해 배우고, 그것을 어떻게 이용하는지 배울 것입니다.
  """
}
---

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

이미 짐작한 것처럼, 줄여쓰기를 했을 때 매개변수들은 `&1`, `&2`, `&3`, 등과 같이 다룰 수 있습니다.

## 패턴매칭

Elixir에서 패턴매칭은 단순히 변수를 다루는 데서 그치지 않고, 함수 시그니처에서도 적용될 수 있다는 것을 이 섹션에서 확인할 것입니다.

Elixir에서는 패턴매칭을 사용하여 매칭되는 옵션(매개변수의 집합)을 살펴보고, 첫번째로 매칭되는 옵션을 실행하기로 선택한다.

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:ok, _} -> IO.puts "This would be never run as previous will be matched beforehand."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
1
iex> handle_result.({:ok, some_result})
Handling result...
:ok
iex> handle_result.({:error})
An error has occurred!
:ok
```

## 이름이 있는 함수

차후에 쉽게 호출할 수 있도록 함수를 이름과 같이 정의할 수 있습니다. 이는 모듈 내에서 `def` 키워드로 정의됩니다. 지금은 이름이 있는 함수를 다루는 것에 집중하도록 하고, 다음 수업에서 모듈에 대해 더 배울 것입니다.

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

함수 이름을 주석으로 달아두었습니다. 첫 번째 구현은 인자를 받지 않습니다. 그래서 `hello/0`라 합니다. 두 번째는 하나의 인자를 받고 `hello/1`라 하고 계속 이런 식입니다. 다른 언어의 함수 오버로드와는 다르게 3개의 서로 _다른_ 함수가 존재합니다.(아까 전에 설명했던 패턴매칭은 인자 개수가 _같은_ 함수의 선언이 여러 번 있을 때만 적용됩니다.)

### 함수와 패턴 매칭
앞서 함수는 호출될 때 매개변수에 패턴매칭이 적용된다고 했습니다.  

함수가 매개변수로 맵을 필요로 하지만, 특정 키만을 사용한다고 가정해봅시다. 다음과 같이 해당 키의 존재로 매개변수를 패턴매칭할 수 있습니다. 

```elixir
defmodule Greeter1 do
  def hello(%{name: person_name}) do
    IO.puts "Hello, " <> person_name
  end
end
```

이제 Fred라는 이름의 사람을 표현한 맵이 있다고 가정해 봅시다.

```elixir
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"
...> }
```

아래는 `fred`맵을 사용해 `Greeter1.hello/1`을 호출했을 때의 결과입니다.

```elixir
# call with entire map
...> Greeter1.hello(fred)
"Hello, Fred"
```

`:name` 키를 포함하지 않는 맵을 사용하여 함수를 호출하면 어떻게 될까요?

```elixir
# call without the key we need returns an error
...> Greeter1.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter1.hello/1

    The following arguments were given to Greeter1.hello/1:

        # 1
        %{age: "95", favorite_color: "Taupe"}

    iex:12: Greeter1.hello/1

```

이러한 일이 발생하는 이유는 엘릭서가 호출되는 함수의 매개변수와 정의된 함수의 매개변수와 패턴매칭시키기 때문입니다.  

데이터가 `Greeter1.hello/1`에 도착했을 때의 모습을 생각해봅시다.

```Elixir
# incoming map
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"
...> }
```

`Greeter1.hello/1`은 다음과 같은 매개변수를 예상합니다.

```elixir
%{name: person_name}
```

`Greeter1.hello/`에서, 통과시킨 맵(`fred`)는 이 매개변수(`%{name: person_name}`)에 대해 평가됩니다.

```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

들어오는 맵에는 `name`에 대응하는 키가 있는 것을 알 수 있습니다.
매칭이 되었습니다. 그리고 이 성공적인 매칭의 결과로, 오른쪽 맵(`fred` 맵)의 `:name` 키에 해당하는 값이 왼쪽의 변수(`preson_name`)에 할당됩니다.

만약 Fred의 이름을 `person_name`에 할당하면서 전체 맵도 계속 유지하고 싶다면 어떨까요? 그에게 인사하고 난 후, `IO.inspect(fred)`를 하고 싶다고 가정해봅시다.
현재로서는 맵의 `:name` 키만 패턴 일치시키기 때문에, 해당 키의 값만 변수에 할당하며, 함수는 Fred의 나머지 부분을 알지 못합니다.

이것을 유지하기 위해서, 우리는 맵 전체를 자체 변수에 할당하여 사용할 수 있어야 합니다.

새로운 함수를 살펴봅시다.

```elixir
defmodule Greeter2 do
  def hello(%{name: person_name} = person) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

엘릭서는 매개변수가 들어오면 패턴매칭 시킨다는 것을 기억하세요. 그러므로 이번 경우에는, 양 측에서 들어오는 매개변수에 대해 패턴매칭시키고, 매칭되는 변수에 할당합니다.
먼저 오른쪽을 살펴봅시다.

```elixir
person = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

`person`은 전체 fred 맵에 대해 평가되고, 할당됩니다. 이번엔 다음 패턴매칭을 살펴봅시다.

```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

이 부분은 기존의 `Greeter1` 함수와 동일하게, 맵과 패턴매칭되고 Fred의 이름만 유지시킨다. 이를 통해 한 개의 변수가 아닌 두개의 변수를 사용할 수 있게 되었습니다.

1. `person`은 `%{name: "Fred", age: "95", favorite_color: "Taupe"}`을 나타냅니다.
2. `person_name`은 `"Fred"`를 나타냅니다.

이제 `Greeter2.hello/1`을 호출할 때, 우리는 Fred의 모든 정보를 사용할 수 있습니다.

```elixir
# call with entire person
...> Greeter2.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}
# call with only the name key
...> Greeter2.hello(%{name: "Fred"})
"Hello, Fred"
%{name: "Fred"}
# call without the name key
...> Greeter2.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter2.hello/1

    The following arguments were given to Greeter2.hello/1:

        # 1
        %{age: "95", favorite_color: "Taupe"}

    iex:15: Greeter2.hello/1
```

각 매개변수는 들어오는 데이터와 독립적으로 매칭되기 때문에, 엘릭서가 여러 깊이(depth)에서 패턴매칭을 할 수 있습니다. 또한, 할당된 변수들은 함수 내부에서 사용할 수 있습니다. 

만약 매개변수에서 `%{name: person_name}`와 `person`의 위치를 바꾸어도, 각각이 fred와 일치하기 때문에 우리는 같은 결과를 얻을 수 있습니다.

변수와 맵의 위치를 바꾸어봅시다.

```elixir
defmodule Greeter3 do
  def hello(person = %{name: person_name}) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

그리고 `Greeter2.hello/1`에서 사용한 것과 같은 데이터로 호출해 봅시다.

```elixir
# call with same old Fred
...> Greeter3.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}
```

`%{name: person_name} = person`와 비슷하게 생겨서 `person` 변수에 대해 `%{name: person_name}`이 패턴매칭된 것처럼 보이겠지만, 사실 그들은 전달된 인수에 대해 _각각_ 패턴매칭된 것입니다.

**요약:** 함수는 각 인수에 전달된 데이터를 독립적으로 패턴매칭시킵니다.
우리는 이를 사용하여 함수 안에서 사용할 개별 변수에 값을 할당할 수 있습니다.

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

[제어 구조](/ko/lessons/basics/control_structures) 강의에서 가드에 대해 간략하게 다뤘으니, 이제 이름이 있는 함수에 어떻게 적용할 수 있는지 알아보도록 하겠습니다. Elixir는 함수가 매치되면, 존재하는 모든 가드를 테스트합니다.

동일한 시그니쳐를 가진 두 함수가 정의된 다음의 예제에서, 인자의 타입에 따라 어떤 함수를 이용할 지 가드를 통해 결정합니다.

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names = Enum.join(names, ", ")
    
    hello(names)
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
    names = Enum.join(names, ", ")
    
    hello(names, language_code)
  end

  def hello(name, language_code \\ "en") when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) iex:8: def hello/2 defines defaults multiple times. Elixir allows defaults to be declared once per definition.
Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b \\ :default) do ... end

one should write:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end
```

Elixir에서는 여러 매칭 함수에 기본값 인자가 들어가는 것을 권장하지 않습니다. 혼동할 수 있기 때문입니다. 이를 다루기 위해서, 기본값 인자가 들어있는 함수 선언문을 추가해봅시다.

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en")

  def hello(names, language_code) when is_list(names) do
    names = Enum.join(names, ", ")
    
    hello(names, language_code)
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
