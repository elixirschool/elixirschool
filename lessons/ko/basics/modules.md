%{
  version: "1.2.1",
  title: "모듈",
  excerpt: """
  모든 함수가 같은 파일과 같은 표현 범위 안에 둔다면 함수 하나하나를 통제하기가 굉장히 힘들다는 것을 우리는 경험을 통해 알고 있습니다. 이번 수업에서는 함수를 묶고 구조체라는 특별한 맵을 통해 작성한 코드를 더욱 효율적으로 관리하는 법을 알아보도록 하겠습니다.
  """
}
---

## 모듈

모듈은 이름공간 안에 함수를 구성할 수 있도록 해줍니다. 함수를 묶을 수 있는 것에서 한 걸음 더 나아가, [함수 수업](../functions/)에서 다루었던 이름이 있는 함수와 private 함수를 정의할 수도 있게 됩니다.

기본적인 예제를 살펴보도록 하지요.

``` elixir
defmodule Example do
  def greeting(name) do
    "Hello #{name}."
  end
end

iex> Example.greeting "Sean"
"Hello Sean."
```

모듈 안에다가 모듈을 포개 넣어 기능에 따라 이름공간을 더 확장할 수도 있습니다.

```elixir
defmodule Example.Greetings do
  def morning(name) do
    "Good morning #{name}."
  end

  def evening(name) do
    "Good night #{name}."
  end
end

iex> Example.Greetings.morning "Sean"
"Good morning Sean."
```

### 모듈 속성

모듈 속성은 Elixir에서는 일반적으로 상수로 가장 널리 사용됩니다. 간단한 예제를 살펴보도록 하지요.

```elixir
defmodule Example do
  @greeting "Hello"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

Elixir에서 여러가지 다른 용도로 사용하는 속성도 있다는 점을 알아두세요. 이런 속성 중 가장 널리 알려진 속성을 이야기하자면, 아래처럼 세 가지를 꼽을 수 있겠습니다.

+ `moduledoc` — 현재 모듈을 설명하는 문서입니다.
+ `doc` — 함수와 매크로를 설명하는 문서입니다.
+ `behaviour` — OTP나 사용자가 따로 정의할 수 있는 비헤이비어에서 사용됩니다.

## 구조체 {#structs}

구조체는 키와 기본값 쌍으로 이루어진 특별한 맵입니다. 구조체는 자신이 정의된 모듈의 이름을 가져오기 때문에, 정의할 때 반드시 모듈 안에서 정의해야 합니다. 모듈 안에다가 구조체 하나만 정의하는 일도 자주 있습니다.

`defstruct`와 함께 필드와 기본값으로 이루어진 키워드 리스트로 구조체를 정의할 수 있습니다.

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

구조체를 몇 개 만들어봅시다.

```elixir
iex> %Example.User{}
%Example.User<name: "Sean", roles: [], ...>

iex> %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [], ...>

iex> %Example.User{name: "Steve", roles: [:manager]}
%Example.User<name: "Steve", roles: [:manager]>
```

구조체의 내용도 맵과 같은 방법으로 변경할 수 있습니다.

```elixir
iex> steve = %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [...], ...>
iex> sean = %{steve | name: "Sean"}
%Example.User<name: "Sean", roles: [...], ...>
```

여기서 제일 중요한 부분은, 맵에 대해서도 구조체를 매칭할 수 있다는 점입니다.

```elixir
iex> %{name: "Sean"} = sean
%Example.User<name: "Sean", roles: [...], ...>
```

## 컴포지션

이제 모듈과 구조체를 만드는 법을 배웠으니, 지금부터는 그 안에 이미 있는 기능들을 컴포지션을 사용해 추가하는 법을 배워봅시다. Elixir에는 다른 모듈과 상호작용할 수 있는 여러가지 방법이 있습니다.

### `alias`

모듈 이름에 별칭(alias)을 지어줄 수 있습니다. Elixir 코드에서 꽤 자주 사용됩니다.

```elixir
defmodule Sayings.Greetings do
  def basic(name), do: "Hi, #{name}"
end

defmodule Example do
  alias Sayings.Greetings

  def greeting(name), do: Greetings.basic(name)
end

# 별칭을 사용하지 않는 경우

defmodule Example do
  def greeting(name), do: Sayings.Greetings.basic(name)
end
```

동일한 별칭끼리 충돌이 생길 수 있거나 완전히 다른 별칭을 지어주고 싶을 때에는, `:as` 옵션을 사용하여 별칭을 다르게 정할 수 있습니다.

```elixir
defmodule Example do
  alias Sayings.Greetings, as: Hi

  def print_message(name), do: Hi.basic(name)
end
```

여러 모듈에 한번에 별칭을 설정할 수도 있습니다.

```elixir
defmodule Example do
  alias Sayings.{Greetings, Farewells}
end
```

### `import`

모듈에 별칭을 지어주는 것보다 해당 모듈 안에 있는 함수와 매크로를 불러오고(import) 싶을 때에는 `import/`를 사용할 수 있습니다.

```elixir
iex> last([1, 2, 3])
** (CompileError) iex:9: undefined function last/1
iex> import List
nil
iex> last([1, 2, 3])
3
```

#### 불러올 함수와 매크로 선택하기

기본적으로는 모든 함수와 매크로가 불려오지만 `:only`나 `:except` 옵션을 사용해서 특정 함수나 매크로만 불러올 수 있습니다.

특정 함수나 매크로를 불러오려면, `:only`와 `:except`에 이름/인자 개수 쌍을 넘겨 주면 됩니다. `last/1` 함수만 불러오는 것부터 시작해보도록 하지요.

```elixir
iex> import List, only: [last: 1]
iex> first([1, 2, 3])
** (CompileError) iex:13: undefined function first/1
iex> last([1, 2, 3])
3
```

`last/1`을 뺀 모든 함수와 매크로를 불러온다면 어떻게 될까요? 아까처럼 함수를 호출해 봅시다.

```elixir
iex> import List, except: [last: 1]
nil
iex> first([1, 2, 3])
1
iex> last([1, 2, 3])
** (CompileError) iex:3: undefined function last/1
```

불러올 조건에 이름/인자 개수 쌍을 건네줄 수도 있지만, 여기서 한걸음 더 나아가서 `:functions`와 `:macros`라는 특별한 애텀을 사용해 함수만, 혹은 매크로만 불러오게 할 수도 있습니다.

```elixir
import List, only: :functions
import List, only: :macros
```

### `require`

`require/2`는 위에 언급된 것들에 비해서는 덜 자주 사용되지만 그래도 중요합니다. 어떤 모듈을 필요하다고 선언(require)하면 컴파일을 한 뒤에 불러오게 됩니다. 특정 모듈에 있는 매크로에 접근할 때 굉장히 유용하게 사용할 수 있습니다.

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

아직 로드되지 않은 매크로에 접근하려고 하면 Elixir에서 오류를 일으킵니다.

### `use`

`use` 매크로로 현재 모듈의 정의를 다른 모듈이 수정할 수 있게 합니다.
코드에서 `use`를 호출하면 실제로 제공된 모듈에 의해 정의된 `__using__/1` 콜백을 호출합니다.
`__using__/1` 매크로의 결과는 모듈 정의의 일부가 됩니다.
이것이 어떻게 작동하는지 더 잘 이해하기 위해 간단한 예를 살펴 보겠습니다.

```elixir
defmodule Hello do
  defmacro __using__(_opts) do
    quote do
      def hello(name), do: "Hi, #{name}"
    end
  end
end
```

여기서 내부에서 `hello/1` 함수를 정의하는 `__using__/1` 콜백을 가진 `Hello` 모듈을 만들었습니다.
이 새로운 코드를 시험해 볼 수 있도록 새 모듈을 만들어 보겠습니다.

```elixir
defmodule Example do
  use Hello
end
```

우리가 IEx에서 코드를 시험해 보면 `hello/1`이 `Example` 모듈에서 사용 가능하다는 것을 알 수 있습니다.

```elixir
iex> Example.hello("Sean")
"Hi, Sean"
```

여기서 `use`가 `Hello`에서 `__using__/1` 콜백을 호출하고 결과 코드를 모듈에 추가 한 것을 볼 수 있습니다.
이제 기본 예제를 설명 했으므로 코드를 갱신하여 `__using__/1`이 옵션을 지원하는 방법을 살펴 보겠습니다.
`greeting` 옵션을 추가해 보겠습니다.

```elixir
defmodule Hello do
  defmacro __using__(opts) do
    greeting = Keyword.get(opts, :greeting, "Hi")

    quote do
      def hello(name), do: unquote(greeting) <> ", " <> name
    end
  end
end
```

새로 만든 `greeting` 옵션을 넣기 위해 `Example` 모듈을 갱신해 봅시다.

```elixir
defmodule Example do
  use Hello, greeting: "Hola"
end
```

IEx에서 확인해 보면, 인사말이 변경되었음을 확인하실 수 있습니다.

```
iex> Example.hello("Sean")
"Hola, Sean"
```

이것들은 `use`가 어떻게 작동하는지 보여주는 간단한 예제이지만 Elixir 툴박스에서 매우 강력한 도구입니다.
Elixir를 계속 공부하신다면 `use`를 여기저기서 보게 될 것 입니다. 한 가지 예를 들면 `use ExUnit.Case, async: true`입니다.

**주의**: `quote`, `alias`, `use`, `require`는 [메타 프로그래밍](../../advanced/metaprogramming)에서 사용한 매크로입니다.
