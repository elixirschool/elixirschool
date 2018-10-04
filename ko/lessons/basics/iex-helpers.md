---
version: 1.0.1
title: IEx Helpers
---

{% include toc.html %}

## 개요

Elixir를 사용하기 시작하면 IEx는 가장 좋은 친구가 되어 줍니다.
IEx는 REPL이며, 새로운 코드를 확인하거나, 개발을 진행할 때 이를 쉽게 만들어주는 많은 고급 기능을 가지고 있습니다.
이 강의를 통해 많은 내장 헬퍼들을 알아보겠습니다.

### 자동 완성

쉘에서 작업하는 동안 익숙하지 않은 새로운 모듈을 사용하는 경우가 있습니다.
어떤 것들이 사용가능한지 이해할 때에는 자동 완성 기능이 무척 유용합니다.
아무 모듈 이름을 적고 `.`을 입력한 뒤 `Tab`을 눌러보세요.

```elixir
iex> Map. # Tab을 누르세요
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
replace!/3           replace/3            split/2
take/2               to_list/1            update!/3
update/4             values/1
```

그러면 지금 사용 가능한 함수와 각각의 애리티를 확인할 수 있습니다.

### `.iex.exs`

IEx는 새로 시작할 때마다 `.iex.exs` 설정 파일을 찾습니다. 현재 폴더에 존재하지 않는 경우, 현재 사용자의 홈 폴더(`~/.iex.exs`)를 확인하게 됩니다.

설정 옵션과 이 파일 내에 정의되어 있는 코드는 IEx 쉘이 시작할 때부터 사용할 수 있습니다. 예를 들어, IEx에서 몇몇 헬퍼 함수들을 쓰길 원한다면, `.iex.exs` 파일을 열고 변경을 하면 됩니다.

몇몇 헬퍼 메소드를 포함하는 모듈을 추가하는 것으로 시작해보죠. 

```elixir
defmodule IExHelpers do
  def whats_this?(term) when is_nil(term), do: "Type: Nil"
  def whats_this?(term) when is_binary(term), do: "Type: Binary"
  def whats_this?(term) when is_boolean(term), do: "Type: Boolean"
  def whats_this?(term) when is_atom(term), do: "Type: Atom"
  def whats_this?(_term), do: "Type: Unknown"
end
```

이제 IEx를 실행하면 IExHelpers 모듈을 곧바로 사용할 수 있습니다. IEx를 열고 새 헬퍼들을 사용해보도록 하죠.

```elixir
$ iex
{{ site.erlang.OTP }} [{{ site.erlang.erts }}] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex> IExHelpers.whats_this?("a string")
"Type: Binary"
iex> IExHelpers.whats_this?(%{})
"Type: Unknown"
iex> IExHelpers.whats_this?(:test)
"Type: Atom"
```

위에서 볼 수 있듯 헬퍼들을 불러하기 위해서 어떠한 특별한 작업도 필요하지 않으며, IEx가 이를 대신 해줍니다.

### `h`

`h`는 Elixir 쉘이 주는 가장 유용한 도구 중 하나입니다.
언어에서 문서를 굉장히 중요하게 다루기 때문에, 어떤 코드의 문서도 이 헬퍼를 통해서 바로 접근할 수 있습니다.
간단하게 확인해볼 수 있습니다.

```elixir
iex> h Enum
                                      Enum

Provides a set of algorithms that enumerate over enumerables according to the
Enumerable protocol.

┃ iex> Enum.map([1, 2, 3], fn(x) -> x * 2 end)
┃ [2, 4, 6]

Some particular types, like maps, yield a specific format on enumeration. For
example, the argument is always a {key, value} tuple for maps:

┃ iex> map = %{a: 1, b: 2}
┃ iex> Enum.map(map, fn {k, v} -> {k, v * 2} end)
┃ [a: 2, b: 4]

Note that the functions in the Enum module are eager: they always start the
enumeration of the given enumerable. The Stream module allows lazy enumeration
of enumerables and provides infinite streams.

Since the majority of the functions in Enum enumerate the whole enumerable and
return a list as result, infinite streams need to be carefully used with such
functions, as they can potentially run forever. For example:

┃ Enum.each Stream.cycle([1, 2, 3]), &IO.puts(&1)
```

그리고 이 기능을 쉘의 자동 완성 기능과 함께 사용할 수도 있습니다.
처음으로 Map을 알아본다고 생각해봅시다.

```elixir
iex> h Map
                                      Map

A set of functions for working with maps.

Maps are key-value stores where keys can be any value and are compared using
the match operator (===). Maps can be created with the %{} special form defined
in the Kernel.SpecialForms module.

iex> Map.
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
split/2              take/2               to_list/1
update!/3            update/4             values/1

iex> h Map.merge/2
                             def merge(map1, map2)

Merges two maps into one.

All keys in map2 will be added to map1, overriding any existing one.

If you have a struct and you would like to merge a set of keys into the struct,
do not use this function, as it would merge all keys on the right side into the
struct, even if the key is not part of the struct. Instead, use
Kernel.struct/2.

Examples

┃ iex> Map.merge(%{a: 1, b: 2}, %{a: 3, d: 4})
┃ %{a: 3, b: 2, d: 4}
```

이처럼 모듈에 어떤 함수들이 있는지 확인할 수 있을 뿐만이 아니라, 예제를 포함하는 각 함수의 문서에도 접근할 수 있습니다.

### `i`

`i` 헬퍼에 대해서 알아보기 위해 새로 배운 `h`를 사용해봅시다.

```elixir
iex> h i

                                  def i(term)

Prints information about the given data type.

iex> i Map
Term
  Map
Data type
  Atom
Module bytecode
  /usr/local/Cellar/elixir/1.3.3/bin/../lib/elixir/ebin/Elixir.Map.beam
Source
  /private/tmp/elixir-20160918-33925-1ki46ng/elixir-1.3.3/lib/elixir/lib/map.ex
Version
  [9651177287794427227743899018880159024]
Compile time
  no value found
Compile options
  [:debug_info]
Description
  Use h(Map) to access its documentation.
  Call Map.module_info() to access metadata.
Raw representation
  :"Elixir.Map"
Reference modules
  Module, Atom
```

이를 통해 `Map`의 소스코드가 어디에 존재하고 모듈이 어디를 참조하는지를 포함한 많은 정보를 알 수 있습니다. 이는 커스텀 또는 외래 데이터 타입이나 새 함수를 조사할 때 유용합니다.

각각의 내용이 복잡할 수 있습니다만, 크게 보면 다음과 같은 관련 정보를 얻을 수 있습니다.

- 애텀 데이터 타입이며
- 소스 코드가 어디에 위치하는지
- 버전과 컴파일 옵션이 무엇인지
- 일반적인 설명
- 어떻게 접근할 수 있는지
- 참조하고 있는 모듈은 어떤 것이 있는지

이는 활용할 정보를 알려주며, 전혀 모르고 접근하는 것보다도 낫습니다.

### `r`

특정 모듈을 재컴파일 하고 싶은 경우에 `r` 헬퍼를 사용할 수 있습니다. 코드를 좀 변경하고, 우리가 추가한 새 함수를 실행하고 싶다고 해봅시다. 이를 위해서는 변경사항을 저장하고, r을 사용하여 재컴파일을 해야 합니다.

```elixir
iex> r MyProject
warning: redefining module MyProject (current version loaded from _build/dev/lib/my_project/ebin/Elixir.MyProject.beam)
  lib/my_project.ex:1

{:reloaded, MyProject, [MyProject]}
```

### `t`

`t` 헬퍼는 주어진 모듈에서 사용 가능한 타입을 알려줍니다.

```elixir
iex> t Map
@type key() :: any()
@type value() :: any()
```

이제 `Map`이 구현에서 key와 value 타입을 정의하고 있다는 것을 확인했습니다.
`Map`의 소스를 확인해보면 다음처럼 되어 있을 것입니다.

```elixir
defmodule Map do
# ...
  @type key :: any
  @type value :: any
# ...
```

이는 각 구현에서 key와 value에 어떤 타입도 사용할 수 있다는 것을 알려주는 간단한 예제입니다만, 알아두면 유용합니다.

이 멋진 내장 헬퍼들을 통해 코드가 어떻게 동작하는지를 쉽게 확인하고 배울 수 있습니다. IEx는 개발자들을 돕는 매우 강력하고 견고한 도구입니다. 이러한 도구들을 사용하면 조사하고 만드는 것이 훨씬 즐거울 수 있습니다.
