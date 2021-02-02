%{
  version: "1.0.0",
  title: "Mnesia",
  excerpt: """
  Mnesia는 실시간 분산 데이터베이스 관리 시스템을 담당하고 있습니다.
  """
}
---

## 개론

Mnesia는 Elixir에서 이미 사용하고 있는 Erlang 런타임 시스템에서 동작하는 데이터베이스 관리 시스템(DBMS)입니다. Mnesia의 *관계 모델과 객체 모델을 섞어둔 하이브리드 모델*은 어떤 크기의 분산 애플리케이션이든 개발할 수 있게 해줍니다.

## 언제 사용해야 하나요?

어떤 기술을 사용해야 하는지 결정하는 것은 무척 혼란스러운 과정입니다. 아래의 질문들에서 '네'라고 대답할 수 있다면, ETS나 DETS 대신에 Mnesia를 사용할 타이밍이라는 좋은 신호라고 할 수 있습니다.

  - 트랜잭션 롤백 기능이 필요한가요?
  - 데이터를 읽고 쓸 때, 더 나은 문법을 원하시나요?
  - 여러 노드에 걸쳐서 데이터를 저장해야 할 필요가 있나요?
  - 정보를 어디(RAM이나 디스크)에 저장할지에 대한 옵션이 필요한가요?

## 스키마

Mnesia는 Elixir의 한 부분이라기보다는 Erlang 핵심의 일부이므로, 우리는 콜론 문법을 사용해야 합니다.(다음 강의를 참고하세요. [Erlang 상호운용](../../advanced/erlang/))

```elixir

iex> :mnesia.create_schema([node()])

# 또는 Elixir처럼 사용하고 싶다면...

iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
```

이 강의에서는 Mnesia API를 사용할 때에 후자의 방법을 사용할 것입니다. `Mnesia.create_schema/`는 새로운 스키마를 생성하며, 노드 리스트를 집어 넣습니다. 여기에서는 IEx 세션과 연결된 노드 리스트를 넘겼습니다.

## 노드들

일단 IEx를 통해 `Mnesia.create_schema([node()])`를 실행하면, **Mnesia.nonode@nohost**라고 불리는 폴더나 현재 작업 폴더와 비슷한 폴더를 볼 수 있을 것입니다. **Mnesia.nonode@nohost**가 무슨 의미인지 의문을 가질 수 있습니다만, 이는 이 노드에 이름이 없다는 의미입니다. 좀 더 자세히 살펴보죠.

```shell
$ iex --help
Usage: iex [options] [.exs file] [data]

  -v                버전을 출력합니다.
  -e "command"      주어진 command를 실행합니다. (*)
  -r "file"         주어진 파일/패턴을 불러옵니다. (*)
  -S "script"       주어진 스크립트를 찾아서 실행합니다. (*)
  -pr "file"        주어진 파일/패턴을 찾아서 병렬로 실행합니다. (*)
  -pa "path"        주어진 경로를 Erlang 코드 경로의 앞에 추가합니다. (*)
  -pz "path"        주어진 경로를 Erlang 코드 경로의 뒤에 추가합니다. (*)
  --app "app"       주어진 앱과 그 의존성을 가지고 시작합니다. (*)
  --erl "switches"  넘겨진 값들을 가지고 Erlang을 실행합니다. (*)
  --name "name"     분산된 노드를 만들고 이름을 할당합니다.
  --sname "name"    분산된 노드를 만들고 짧은 이름을 할당합니다.
  --cookie "cookie" 이 분산된 노드를 위해 쿠키를 설정합니다.
  --hidden          숨겨진 노드를 만듭니다.
  --werl            Erlang의 GUI 윈도우 쉘을 사용합니다(윈도우즈 전용)
  --detached        콘솔로부터 분리된 Erlang VM을 시작합니다.
  --remsh "name"    원격 쉘을 사용하여 노드에 연결합니다.
  --dot-iex "path"  .iex.exs 파일의 기본 설정을 덮어씁니다;
                    경로는 공백일 수 있으며, 이 경우 아무 파일도 불러오지 않습니다.

** (*) 표시가 된 경우 1개 이상의 옵션을 넘길 수 있습니다.
** .exs 파일이나 -- 뒤에 오는 옵션들은 실행된 코드에 넘겨집니다.
** ELIXIR_ERL_OPTIONS나 --erl 옵션을 통해서 VM에게 옵션을 넘길 수 있습니다.
```

IEx에게 `--help` 옵션을 함께 넘기면, 가능한 모든 옵션의 목록을 확인할 수 있습니다. 이 목록 중에 노드에 정보를 추가하기 위한 `--name`와 `--sname`가 있는 것을 확인하실 수 있습니다. 노드는 그저 Erlang 가상머신의 통신, 가비지 컬렉션, 스케줄링, 메모리 등을 관리합니다. 이 노드의 이름은 기본값으로 **nonode@nohost**라고 지정되어 있습니다.

```shell
$ iex --name learner@elixirschool.com

Erlang/OTP 18 [erts-7.2.1] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex(learner@elixirschool.com)> Node.self
:"learner@elixirschool.com"
```

여기에서 볼 수 있듯, 지금 실행 중인 노드의 이름은  `:"learner@elixirschool.com"`라는 애텀입니다. 우리가 `Mnesia.create_schema([node()])`를 다시 실행한다면 이제 **Mnesia.learner@elixirschool.com**라는 이름의 다른 폴더를 생성하는 것을 확인할 수 있습니다. 왜 이렇게 하는지는 무척 간단한 이유가 있습니다. Erlang에서의 노드는 (분산된) 정보나 자원을 공유하기 위해서 다른 노드들을 연결하곤 합니다. 이는 같은 기기에서 동작할 필요가 없으며, LAN이나 인터넷 등을 통해서 연결될 수도 있습니다.

## Mnesia 시작하기

이제 기본 배경에 대한 것을 알게 되었으니, 데이터베이스를 만들고 Mnesia DBMS를 `Mnesia.start/0` 명령을 통해서 시작해보죠.

```elixir
iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
:ok
iex> Mnesia.start()
:ok
```

분산 시스템을 2개 이상의 노드에서 동작시키는 경우, `Mnesia.start/1` 함수는 모든 노드에서 실행되어야 한다는 점을 잊지 마세요.

## 테이블 만들기

`Mnesia.create_table/2` 함수는 데이터베이스에 테이블을 생성하기 위해서 사용됩니다. 다음을 통해서 `Person`이라는 테이블을 생성하고, 스키마를 정의하기 위해서 키워드 리스트를 넘겨보겠습니다.

```elixir
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:atomic, :ok}
```

애텀 `:id`, `:name`, `:job`를 사용해서 컬럼을 정의합니다. `Mnesia.create_table/2`를 실행하면 다음 중 하나가 응답으로 돌아올 것입니다.

 - `{:atomic, :ok}` 함수가 성공적으로 실행되었을 때.
 - `{:aborted, Reason}` 함수가 실패했을 때.

일반적으로, 테이블이 이미 존재하면, `{:already_exists, table}` 형식의 응답이 됩니다. 그래서 두 번째 생성을 시도한다면 이런 결과를 얻게 됩니다.

```elixir
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:aborted, {:already_exists, Person}}
```

## 좋지 않은 방식

우선 Mnesia 테이블을 읽고 쓰는 좋지 않은 방식에 대해서 알아봅시다. 이는 실행 결과의 성공을 보장해주지 않기 때문에 특별한 이유가 없다면 사용을 피해야 합니다. 그렇지만 Mnesia를 사용해서 작업하는 방법을 배우고 익숙해지는 데에는 도움이 될 겁니다. 우선 **Person** 테이블에 정보를 추가해 봅시다.

```elixir
iex> Mnesia.dirty_write({Person, 1, "Seymour Skinner", "Principal"})
:ok

iex> Mnesia.dirty_write({Person, 2, "Homer Simpson", "Safety Inspector"})
:ok

iex> Mnesia.dirty_write({Person, 3, "Moe Szyslak", "Bartender"})
:ok
```

...그리고 `Mnesia.dirty_read/1`을 사용해서 이 정보들을 가져와 봅시다.

```elixir
iex> Mnesia.dirty_read({Person, 1})
[{Person, 1, "Seymour Skinner", "Principal"}]

iex> Mnesia.dirty_read({Person, 2})
[{Person, 2, "Homer Simpson", "Safety Inspector"}]

iex> Mnesia.dirty_read({Person, 3})
[{Person, 3, "Moe Szyslak", "Bartender"}]

iex> Mnesia.dirty_read({Person, 4})
[]
```

존재하지 않는 레코드에 대해서 질의를 던지면, Mnesia는 빈 리스트를 반환합니다.

## 트랜잭션

일반적으로 **트랜잭션**은 데이터베이스에 대한 읽기/쓰기 작업을 캡슐화하기 위해서 사용됩니다. 트랜잭션은 높은 장애 복원력과 고도로 분산된 시스템을 실현하기 위한 중요한 부분을 담당하고 있습니다. Mnesia의 *트랜잭션은 데이터베이스 조작 명령들을 하나의 함수 블록인 것처럼 동작합니다*. 우선 익명 함수를 하나 만들고, `date_to_write`라는 변수에 저장한 뒤, 이것을 `Mnesia.transaction`에 넘깁시다.

```elixir
iex> data_to_write = fn ->
...>   Mnesia.write({Person, 4, "Marge Simpson", "home maker"})
...>   Mnesia.write({Person, 5, "Hans Moleman", "unknown"})
...>   Mnesia.write({Person, 6, "Monty Burns", "Businessman"})
...>   Mnesia.write({Person, 7, "Waylon Smithers", "Executive assistant"})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_write)
{:atomic, :ok}
```

이 트랜잭션 메시지를 통해서 데이터들이 안전하게 `Person` 테이블에 저장되었음을 추정할 수 있습니다. 그러면 확인을 위해서 데이터베이스에서 트랜잭션을 사용해서 데이터를 읽어봅시다. `Mnesia.read/1`를 통해서 데이터를 읽어올 수 있으며, 다시 한 번 강조하지만, 익명 함수로 감싸주세요.

```elixir
iex> data_to_read = fn ->
...>   Mnesia.read({Person, 6})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_read)
{:atomic, [{Person, 6, "Monty Burns", "Businessman"}]}
```

데이터를 업데이트할 때, `Mnesia.write/1`만 존재하는 키로 호출하면 되는 것에 주의하세요. 그래서 Hans의 데이터를 업데이트하려면 이렇게 하면 됩니다.

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.write({Person, 5, "Hans Moleman", "Ex-Mayor"})
...>   end
...> )
```

## 인덱스 사용하기

Mnesia 키가 아닌 컬럼에 인덱스를 지원하고 이 데이터에 대해 쿼리를 던질 수 있습니다. `Person` 테이블의 `:job` 컬럼에 인덱스를 추가해 봅시다.

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:atomic, :ok}
```

`Mnesia.create_table/2`의 결과와 비슷해 보입니다.

 - `{:atomic, :ok}` 함수가 성공적으로 실행됨
 - `{:aborted, Reason}` 함수가 실패함

일반적으로 키가 이미 존재하면, `{:already_exists, table, attribute_index}` 형식의 응답이 돌아옵니다. 이 인덱스를 한번 더 넣으려 하면, 이런 결과를 받게 됩니다.

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:aborted, {:already_exists, Person, 4}}
```

인덱스가 성공적으로 생성되면, 이를 읽을 수 있고, 모든 교장의 목록을 검색할 수 있습니다.

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.index_read(Person, "Principal", :job)
...>   end
...> )
{:atomic, [{Person, 1, "Seymour Skinner", "Principal"}]}
```

## 일치와 선택

Mnesia는 테이블에서 데이터를 검색하는 복잡한 쿼리를 매칭과 에드훅 형식의 함수로 지원합니다.

`Mnesia.match_object/1` 함수는 주어진 패턴으로 일치된 모든 데이터를 반환합니다. 테이블에 있는 인덱스를 가진 컬럼이라면 인덱스를 사용해 쿼리를 더 효과적으로 만들 수 있습니다. 일치에 사용하지 않는 컬럼은 특별한 애텀 `:_` 지정할 수 있습니다.

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.match_object({Person, :_, "Marge Simpson", :_})
...>   end
...> )
{:atomic, [{Person, 4, "Marge Simpson", "home maker"}]}
```

`Mnesia.select/2` 함수로 Elixir(나 Erlang)의 연산자, 함수를 사용해 직접 쿼리를 정의할 수 있습니다. 키가 3보다 큰 모든 레코드를 찾는 예제를 살펴봅시다.

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     {% raw %}Mnesia.select(Person, [{{Person, :"$1", :"$2", :"$3"}, [{:>, :"$1", 3}], [:"$$"]}]){% endraw %}
...>   end
...> )
{:atomic, [[7, "Waylon Smithers", "Executive assistant"], [4, "Marge Simpson", "home maker"], [6, "Monty Burns", "Businessman"], [5, "Hans Moleman", "unknown"]]}
```

풀어 봅시다. 첫 번째 인자는 테이블 `Person` 입니다. 두 번째 인자는 `{match, [guard], [result]}` 형식입니다.

- `match`는 `Mnesia.match_object/1` 함수에 넘기는 것과 동일합니다. 하지만 쿼리의 나머지에 사용하는 파라미터의 위치를 지정하는 특수 애텀 `:"$n"`에 주의하세요.
- `guard` 리스트는 적용할 가드 함수를 지정하는 튜플의 리스트입니다. 이 경우에는 `:>` (더 큼) 빌트인 함수, 위치 파라미터 `:"$1"`, 상수 `3`이 인자로 사용되었습니다.
- `result` 리스트는 쿼리가 반환하는 필드 리스트입니다. 위치 파라미터 형식에서 특수 에텀 `:"$$"`은 참조할 수 있는 모든 필드를 나타냅니다. `[:"$1", :"$2"]`로 처음 두 필드만 반환하거나 `[:"$$"]`로 모든 필드를 반환할 수 있습니다.

더 자세한 내용은 [Erlang Mnesia 문서의 select/2](http://erlang.org/doc/man/mnesia.html#select-2)를 참조하세요.

## 데이터 초기화와 이관

모든 소프트웨어 제품이 그렇듯이 소프트웨어를 업그레이드하고 데이터베이스에 저장된 데이터를 이관해야할 때가 있습니다. 예를 들어 앱을 v2로 버전업하면서 `Person` 테이블의 `:age` 컬럼을 추가해야 한다고 해봅시다. 테이블이 이미 있으므로 `Person` 테이블을 만들수는 없지만 변환할 수는 있습니다. 이를 위해서는 테이블을 생성할 때 무엇을 할 수 있는 지, 언제 변환해야 하는 지 알아야 합니다. `Mnesia.table_info/2` 함수를 사용해 현재 테이블의 구조를 검색하고 `Mnesia.transform_table/3`로 새 구조로 변환할 수 있습니다.

아래에 있는 코드는 다음 로직을 구현합니다.

* v2 인자 `[:id, :name, :job, :age]`로 테이블 생성
* 생성 결과를 처리
    * `{:atomic, :ok}`: `:job`, `:age`에 인덱스를 생성해 테이블 초기화
    * `{:aborted, {:already_exists, Person}}`: 현재 테이블에 어떤 인자가 있고 올바르게 동작하는지 확인
        * v1의 목록(`[:id, :name, :job]`)이라면 모든 레코드의 나이를 21를 설정하고 `:age`에 새 인덱스를 설정해 변환
        * v2의 목록이라면 아무것도 하지 않음
        * 다른 결과면 종료

`Mnesia.transform_table/3` 함수는 테이블 이름, 이전 레코드를 새 레코드로 변환하는 함수, 새 인자의 리스트를 인자로 받습니다.

```elixir
iex> case Mnesia.create_table(Person, [attributes: [:id, :name, :job, :age]]) do
...>   {:atomic, :ok} ->
...>     Mnesia.add_table_index(Person, :job)
...>     Mnesia.add_table_index(Person, :age)
...>   {:aborted, {:already_exists, Person}} ->
...>     case Mnesia.table_info(Person, :attributes) do
...>       [:id, :name, :job] ->
...>         Mnesia.transform_table(
...>           Person,
...>           fn ({Person, id, name, job}) ->
...>             {Person, id, name, job, 21}
...>           end,
...>           [:id, :name, :job, :age]
...>           )
...>         Mnesia.add_table_index(Person, :age)
...>       [:id, :name, :job, :age] ->
...>         :ok
...>       other ->
...>         {:error, other}
...>     end
...> end
```
