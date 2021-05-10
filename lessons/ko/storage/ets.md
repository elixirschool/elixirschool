%{
  version: "1.1.0",
  title: "Erlang Term Storage (ETS)",
  excerpt: """
  Erlang Term Storage, 줄여서 ETS는 OTP 내부에 포함된 강력한 저장용 엔진으로, Elixir에서 이용할 수 있습니다. 이 강의에서는 ETS를 호출하는 방법과 애플리케이션에서 사용하는 방법에 관해서 설명합니다.
  """
}
---

## 개요

ETS는 Elixir나 Erlang에서 객체를 메모리에 담아둘 수 있는 견고한 저장소입니다. ETS는 큰 데이터를 저장할 수 있으며, 상수 시간 접근을 제공합니다.

ETS의 테이블은 각각의 프로세스에 의해서 생성, 소유됩니다. 테이블을 소유하는 프로세스가 죽으면, 테이블도 함께 파괴됩니다. 초기 상태에서 ETS는 노드마다 1400개까지로 제한되어 있습니다.

## 테이블 생성

테이블은 `new/2`로 생성합니다. 이 함수는 테이블 이름과 옵션을 받으며, 뒤에서 설명할 함수들에서 사용할 수 있는 테이블 ID를 돌려줍니다.

예를 들어 사용자를 이름으로 관리하고 검색하는 테이블을 만들어 보죠.

```elixir
iex> table = :ets.new(:user_lookup, [:set, :protected])
8212
```

GenServer처럼 ID 대신에 이름을 사용해서 ETS 테이블에 접근하는 방법이 있습니다. `:named_table` 옵션을 사용하면 이름을 통해 테이블에 접근할 수 있습니다.

```elixir
iex> :ets.new(:user_lookup, [:set, :protected, :named_table])
:user_lookup
```

### 테이블의 타입

ETS에서 사용할 수 있는 테이블의 타입은 4개가 있습니다.

+ `set` — 기본 테이블 타입입니다. 각 키당 하나의 값을 가지며, 키는 중복될 수 없습니다.
+ `ordered_set` — `set`과 비슷합니다만, Erlang/Elixir의 용어로 정렬할 수 있습니다. 다만, `ordered_set` 내부에서의 키의 비교는 다르게 동작한다는 점을 알아 둘 필요가 있습니다. 동등하다고 판단되는 경우에는 별도로 매치하지 않습니다. 예를 들어, 1과 1.0은 동등하다고 취급합니다.
+ `bag` — 키에 많은 객체를 저장할 수 있습니다만, 하나의 객체에는 하나의 인스턴스만을 가질 수 있습니다.
+ `duplicate_bag` — 키에 많은 객체를 저장할 수 있으며, 중복을 허용합니다.

### 접근 제어

ETS에서의 접근 제어는 모듈 내부의 접근 제어와 닮았습니다.

+ `public` - 모든 프로세스에서 읽기/쓰기가 가능합니다.
+ `protected` - 모든 프로세스에서 읽기가 가능합니다. 소유하고 있는 프로세스에서만 쓰기가 가능합니다. 이것이 기본 옵션입니다.
+ `private` - 읽기/쓰기 모두 소유하고 있는 프로세스로 제한됩니다.

## 경쟁 상태

하나 이상의 프로세스가 `:public`을 통한 접근이나 테이블을 소유하고 있는 프로세스에 메시지를 보내는 방식을 통해, 테이블에 쓰기가 가능할 때 경쟁 상태가 발생할 수 있습니다. 예를 들면 두 프로세스가 동시에 카운터 값으로 `0`을 읽고, 증가시키고, `1`을 저장한다고 합시다. 그 결과, 한번의 증가분만 반영됩니다.

카운터에 관해서는 명확하게, [:ets.update_counter/3](http://erlang.org/doc/man/ets.html#update_counter-3)이 원자성을 보장하는 변경/읽기를 제공합니다. 하지만 다른 경우에도 "리스트에 있는 `:results` 키의 값에 이 값을 더하라" 처럼, 소유 프로세스가 메세지에 대해 원자성을 보장하는 연산으로 만들 필요가 있을지도 모릅니다.

## 데이터 추가

ETS에는 스키마가 없습니다. 유일한 제약은 첫 번째 원소가 키로 된 튜플을 저장해야 한다는 점입니다. 새로운 데이터를 추가할 때에는 `insert/2`를 사용합니다.

```elixir
iex> :ets.insert(:user_lookup, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
true
```

`insert/2`를 `set`이나 `ordered_set`에 사용하면, 기존의 데이터를 대체합니다. 이를 피하려면 키가 존재하는 경우에 `false`를 돌려주는 `insert_new/2`를 사용하세요.

```elixir
iex> :ets.insert_new(:user_lookup, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
false
iex> :ets.insert_new(:user_lookup, {"3100", "", ["Elixir", "Ruby", "JavaScript"]})
true
```

## 데이터 검색

ETS는 저장한 데이터를 검색하기 위해서 편리하고 유연한 방법을 몇 가지 제공하고 있습니다. 키에 여러 형태의 패턴 매칭을 통해 검색하는 방법에 대해 알아봅시다.

가장 효율이 높고, 이상적인 검색 방법은 키를 사용하는 검색입니다. 이는 편리하지만 매칭은 테이블을 한번 전부 검색해야 하므로, 거대한 데이터 집합에는 신중하게 접근할 필요가 있습니다.

### 키 검색

키가 주어진 경우에는 `lookup/2`를 사용해서 모든 레코드를 검색할 수 있습니다.

```elixir
iex> :ets.lookup(:user_lookup, "doomspork")
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

### 간단한 매칭

ETS는 Erlang에서 만들어졌으므로 매치 변수가 _약간_ 구식으로 보일 수 있다는 점을 경고하며 시작하겠습니다.

매치 내에서 변수를 사용할 경우에는 `:"$1"`、`:"$2"`、`:"$3"` 등의 애텀을 사용합니다. 변수의 숫자는 결과의 위치를 가리키며, 매치의 위치가 아닙니다. 흥미가 없는 값에 대해서는 `:_` 변수를 사용합니다.

값으로 매칭을 하는 것도 가능합니다만, 변수만이 결과로 돌아옵니다. 값과 변수를 함께 사용하면 어떻게 되는지 확인해 보죠.

```elixir
iex> :ets.match(:user_lookup, {:"$1", "Sean", :_})
[["doomspork"]]
```

변수가 결과 리스트의 순서에 어떤 영향을 주는지 다음 예제를 봅시다.

```elixir
iex> :ets.match(:user_lookup, {:"$99", :"$1", :"$3"})
[["Sean", ["Elixir", "Ruby", "Java"], "doomspork"],
 ["", ["Elixir", "Ruby", "JavaScript"], "3100"]]
```

리스트가 아닌 본래의 객체를 원하는 경우에는 어떻게 하면 좋을까요? `match_object/2`를 사용하면 어떤 변수를 사용했는지에 관계없이, 객체 전체를 반환해줍니다.

```elixir
iex> :ets.match_object(:user_lookup, {:"$1", :_, :"$3"})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]

iex> :ets.match_object(:user_lookup, {:_, "Sean", :_})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

### 고급 검색

단순한 매치를 사용하는 경우에 대해서 배웠습니다. 좀 더 SQL 질의와 비슷한 건 없을까요? 다행스럽게도 더 강력한 구문을 사용할 수도 있습니다. 데이터를 `select/2`로 검색하려면, 3개의 인자를 가지는 튜플 리스트를 만들어야 합니다. 이 튜플은 패턴, 0이나 다수의 가드, 그리고 반환 형식을 표현합니다.

매치 변수와 2개의 새로운 변수, `:"$$"`와 `:"$_"`는 돌려주는 값을 만들 때 사용할 수 있습니다. 이 새로운 변수는 반환 값을 생성할 때에 사용할 수 있는 짧은 표현으로, `:"$$"`은 결과 리스트를 `:$_`는 본래의 데이터 객체를 돌려줍니다.

아까의 `match/2`의 예제를 `select/2`를 사용하도록 바꿔봅시다.

```elixir
iex> :ets.match_object(:user_lookup, {:"$1", :_, :"$3"})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]

{% raw %}iex> :ets.select(:user_lookup, [{{:"$1", :_, :"$3"}, [], [:"$_"]}]){% endraw %}
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"spork", 30, ["ruby", "elixir"]}]
```

`select/2`는 레코드를 좀 더 정밀하게 다룰 수 있게 해줍니다만, 구문이 무척 불친절하며 점점 불편해질 뿐입니다. 이를 제어하기 위해서 ETS 모듈은 `fun2ms/1`를 가지고 있으며, 이는 함수를 매치 스펙(match_spec)으로 변환해 줍니다. `fun2ms/1`를 사용하면 좀 더 알아보기 쉬운 함수 구문으로 질의를 작성할 수 있습니다.

`fun2ms/1`와 `select/2`를 사용하여 2개 이상의 언어를 알고 있는 모든 사용자를 찾아봅시다.

```elixir
iex> fun = :ets.fun2ms(fn {username, _, langs} when length(langs) > 2 -> username end)
{% raw %}[{{:"$1", :_, :"$2"}, [{:>, {:length, :"$2"}, 2}], [:"$1"]}]{% endraw %}

iex> :ets.select(:user_lookup, fun)
["doomspork", "3100"]
```

매치 스펙에 대해서 좀 더 배워보고 싶으신가요? Erlang 공식 문서에서 [match_spec](http://www.erlang.org/doc/apps/erts/match_spec.html)을 확인해보세요.

## 데이터 삭제

### 레코드 제거

레코드를 제거하는 일도 `insert/2` 할 때나 `lookup/2` 할 때처럼 간단합니다. `delete/2`로 테이블과 키를 지정하기만 하면 됩니다. 이 함수는 지정된 키와 값을 모두 삭제합니다.

```elixir
iex> :ets.delete(:user_lookup, "doomspork")
true
```

### 테이블 제거

ETS 테이블은 부모 프로세스가 종료될 때까지 가비지 컬렉션이 동작하지 않습니다. 때때로 소유하고 있는 프로세스를 종료하지 않고, 테이블 전체를 삭제해야 하는 경우도 있습니다. 그런 경우에는 `delete/1`을 사용할 수 있습니다.

```elixir
iex> :ets.delete(:user_lookup)
true
```

## ETS의 사용 예시

지금까지 배운 내용을 활용해서, 비싼 처리를 위한 간단한 캐시를 만들어 봅시다. 모듈과 함수, 인자, 옵션을 받는 `get/4` 함수를 구현합니다. 옵션은 아직 `:ttl`만 신경 쓰면 됩니다.

이 예제에는 ETS 테이블이 슈퍼바이저라는 다른 프로세서의 일부로서 생성되었다고 가정합니다.

```elixir
defmodule SimpleCache do
  @moduledoc """
  비용이 비싼 함수 호출을 위한 단순한 ETS 기반 캐시
  """

  @doc """
  캐시된 값을 검색하거나, 주어진 함수를 캐시해서 값을 반환합니다.
  """
  def get(mod, fun, args, opts \\ []) do
    case lookup(mod, fun, args) do
      nil ->
        ttl = Keyword.get(opts, :ttl, 3600)
        cache_apply(mod, fun, args, ttl)

      result ->
        result
    end
  end

  @doc """
  캐시된 결과를 검색하여, 유효한지 확인합니다.
  """
  defp lookup(mod, fun, args) do
    case :ets.lookup(:simple_cache, [mod, fun, args]) do
      [result | _] -> check_freshness(result)
      [] -> nil
    end
  end

  @doc """
  결과의 유효기간을 현재 시스템의 시간과 비교합니다.
  """
  defp check_freshness({mfa, result, expiration}) do
    cond do
      expiration > :os.system_time(:seconds) -> result
      :else -> nil
    end
  end

  @doc """
  함수를 추가하고, 유효기간을 설정하고, 결과를 캐시합니다.
  """
  defp cache_apply(mod, fun, args, ttl) do
    result = apply(mod, fun, args)
    expiration = :os.system_time(:seconds) + ttl
    :ets.insert(:simple_cache, {[mod, fun, args], result, expiration})
    result
  end
end
```

캐시의 동작을 확인하기 위해서, 시스템 시간과 10초의 TTL을 반환하는 함수를 사용합니다. 아래의 예제에서 볼 수 있듯, 값이 파기될 때까지 캐시된 결과가 돌아옵니다.

```elixir
defmodule ExampleApp do
  def test do
    :os.system_time(:seconds)
  end
end

iex> :ets.new(:simple_cache, [:named_table])
:simple_cache
iex> ExampleApp.test
1451089115
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089119
iex> ExampleApp.test
1451089123
iex> ExampleApp.test
1451089127
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089119
```

10초 뒤에 다시 실행하면, 새로운 결과를 돌려받을 수 있습니다.

```elixir
iex> ExampleApp.test
1451089131
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089134
```

보신 것처럼, 확장할 수 있고 고속으로 동작하는 캐시를 외부 의존성 없이 구현할 수 있습니다. 이것은 ETS의 다양한 사용법 중 일부에 지나지 않습니다.

## 디스크 기반 ETS

ETS는 인-메모리 데이터 저장소라는 것을 알고 있습니다만, 디스크를 사용한 저장소가 필요한 경우에는 어떻게 하면 좋을까요? 이럴 때에는 디스크 기반 저장소인 Disk Based Term Storage(DBTS)를 사용할 수 있습니다. ETS와 DETS의 API는 테이블 생성을 제외하면 호환됩니다. DETS는 `open_file/2`를 사용하고 `:named_table` 옵션을 사용하지 않습니다.

```elixir
iex> {:ok, table} = :dets.open_file(:disk_storage, [type: :set])
{:ok, :disk_storage}
iex> :dets.insert_new(table, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
true
iex> select_all = :ets.fun2ms(&(&1))
[{:"$1", [], [:"$1"]}]
iex> :dets.select(table, select_all)
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

`iex`를 종료한 뒤에 폴더를 확인해보세요. `disk_storage`라는 파일이 새롭게 생성되어 있을 것입니다.

```shell
$ ls | grep -c disk_storage
1
```

마지막으로 DETS는 ETS와는 다르게 `orderd_set`은 지원하지 않으며 `set`, `bag`, 그리고 `duplicate_bag`만 지원합니다.
