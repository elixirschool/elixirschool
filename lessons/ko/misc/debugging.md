%{
  version: "1.0.1",
  title: "디버깅",
  excerpt: """
  버그는 필연적으로 어느 프로젝트에나 있습니다. 그래서 디버그가 필요합니다. 이 강좌에서는 Elixir 코드를 디버깅하는 법과 정적 분석 도구를 사용해 버그의 가능성을 찾는 법을 배워보도록 하겠습니다.
  """
}
---

# Dialyxir와 Dialyzer

[Dialyzer](http://erlang.org/doc/man/dialyzer.html), 얼랭 프로그램을 위한 모순 분석기(**DI**screpancy **A**na**LYZ**er for **ER**lang programs)는 정적 코드 분석을 위한 도구입니다. 말하자면 코드를 _읽지만_  코드를 _실행해서_ 분석하지는 않습니다. 버그나, 죽어있거나 사용하지 않거나, 도달할 수 없는 코드를 찾습니다.

[Dialyxir](https://github.com/jeremyjh/dialyxir)는 Elixir에서 Dialyzer를 간편히 사용하기 위한 mix 테스크입니다.

사양은 Dialyzer같은 도구가 코드를 이해하기 쉽게 해 줍니다. 사람이 읽고 이해할 수 있으면 되는 문서와는 다르게(물론 있고 잘 쓰여있어야 합니다), `@spec`은 더 형식적인 문법을 사용해 기계적으로 해석할 수 있습니다.


프로젝트에 Dialyxir를 추가해봅시다. 제일 간단한 방법은 의존성을 `mix.exs` 파일에 넣는 것입니다.

```elixir
defp deps do
  [{:dialyxir, "~> 0.4", only: [:dev]}]
end
```

그리고 다음을 실행하세요.

```shell
$ mix deps.get
...
$ mix deps.compile
```

첫 번째 명령어는 Dialyxir를 다운로드하고 설치할 것입니다. Hex도 같이 설치할 것인지 물어볼 수도 있습니다. 두 번째 명령어는 Dialyxir 애플리케이션을 컴파일할 것 입니다. Dialyxir를 전역으로 설치하고 싶으면, [문서](https://github.com/jeremyjh/dialyxir#installation)를 읽어보세요.

마지막으로 Dialyzer를 실행해 PLT(Persistent Lookup Table)를 다시 빌드합니다. Erlang이나 Elixir의 새버전을 설치할 때마다 이 작업이 필요합니다. 다행이도, Dialyzer는 사용할 때마다 표준 라이브러리를 분석 하려하지 않습니다. 전부 다운로드하는데에는 조금 시간이 걸립니다.

```shell
$ mix dialyzer --plt
Starting PLT Core Build ... this will take awhile
dialyzer --build_plt --output_plt /.dialyxir_core_18_1.3.2.plt --apps erts kernel stdlib crypto public_key -r /Elixir/lib/elixir/../eex/ebin /Elixir/lib/elixir/../elixir/ebin /Elixir/lib/elixir/../ex_unit/ebin /Elixir/lib/elixir/../iex/ebin /Elixir/lib/elixir/../logger/ebin /Elixir/lib/elixir/../mix/ebin
  Creating PLT /.dialyxir_core_18_1.3.2.plt ...
...
 done in 5m14.67s
done (warnings were emitted)
```

## 코드의 정적 분석

이제 Dialyxir를 사용할 준비가 되었습니다.

```shell
$ mix dialyzer
...
examples.ex:3: Invalid type specification for function 'Elixir.Examples':sum_times/1. The success typing is (_) -> number()
...
```

Dialyzer의 메세지는 명확합니다. `sum_times/1`함수의 반환값이 선언과 다르다고 합니다. 이것은 `Enum.sum/1`이 `integer`가 아닌 `number`를 반환하지만 `sum_times/1`은 `integer` 를 반환하기 때문입니다.

`number`는 `integer`가 아니기 때문에 에러가 발생합니다. 어떻게 고칠 수 있을까요? `number`를 `integer`로 바꾸기위해 `round/1`을 사용할 필요가 있습니다.

```elixir
@spec sum_times(integer) :: integer
def sum_times(a) do
  [1, 2, 3]
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

확인해 봅시다.

```shell
$ mix dialyzer
...
  Proceeding with analysis... done in 0m0.95s
done (passed successfully)
```

사양과 정적 분석 도구로 코드를 스스로 테스트하고 버그가 적게 유지할 수 있습니다.

# 디버깅

정적분석만으로 충분하지 않을 때가 있습니다. 버그를 찾기 위해 실행 흐름을 이해할 필요가 있을 때가 있는데, 이럴 때 가장 쉬운 방법은 코드의 흐름과 값을 확인하기 위해 `IO.puts/2`같은 출력문을 사용하는 것이지만, 이 기술은 원시적이고 한계가 있습니다. 고맙게도 Elixir 코드를 디버깅하기위해 Erlang의 디버거를 사용할 수 있습니다.

기초적인 모듈이 있다고 합시다.

```elixir
defmodule Example do
  def cpu_burns(a, b, c) do
    x = a * 2
    y = b * 3
    z = c * 5

    x + y + z
  end
end
```


`iex`를 실행합니다.

```bash
$ iex -S mix
```

그리고 디버거를 실행합니다.

```elixir
iex > :debugger.start()
{:ok, #PID<0.307.0>}
```

Erlang `:debugger` 모듈로 디버거에 접근할 수 있습니다. `start/1` 함수를 사용해 설정할 수 있습니다.

+ 파일 경로를 넘기면 외부 설정 파일을 사용할 수 있습니다.
+ 인자가 `:local`나 `:global`이라면 디버거는 다음과 같이 동작합니다.
    + `:global` – 디버거는 모든 알려진 노드에 대해 코드를 중단합니다. 기본값입니다.
    + `:local` – 디버거는 현제 노드에 대해서만 코드를 중단합니다.

다음 단계에서 디버거에 위의 모듈을 붙여보겠습니다.

```elixir
iex > :int.ni(Example)
{:module, Example}
```

`:int` 모듈은 브레이크 포인트를 만들고 코드 실행 단계를 따라갈 수 있게 하는 인터프리터입니다.

디버거를 시작하면 이런 창을 볼 수 있습니다.

![Debugger Screenshot 1](/images/debugger_1.png)

모듈을 디버거에 붙인 다음 왼쪽에 있는 메뉴에서 사용 가능합니다.

![Debugger Screenshot 2](/images/debugger_2.png)

## 브레이크 포인트 만들기

브레이크 포인트는 코드에서 실행을 중단할 지점입니다. 브레이크 포인트를 만드는 두 가지 방법이 있습니다.

+ 코드에서 `:int.break/2`하기
+ 디버거 UI

IEx에서 브레이크 포인트를 만들어 봅시다.

```elixir
iex > :int.break(Example, 8)
:ok
```

이 명령은 `Example` 모듈의 8번째 줄에 브레이크 포인트를 설정합니다. 이제 함수를 실행해 봅시다.

```elixir
iex > Example.cpu_burns(1, 1, 1)
```

실행은 IEx에서 멈추고 이런 디버거 화면이 보일 것입니다.

![Debugger Screenshot 3](/images/debugger_3.png)

그리고 창이 하나 더 열리고 소스 코드가 나타날 것입니다.

![Debugger Screenshot 4](/images/debugger_4.png)

이 창에서는 변수의 값을 볼 수 있고, 다음 줄로 넘어가거나 식을 평가해볼 수 있습니다. `:int.disable_break/2`로 브레이크 포인트를 비활성화 할 수 있습니다.

```elixir
iex > :int.disable_break(Example, 8)
:ok
```

브레이크 포인트를 다시 활성화하려면 `:int.enable_break/2`를 부르거나 이렇게 브레이크 포인트를 제거할 수 있습니다.

```elixir
iex > :int.delete_break(Example, 8)
:ok
```

같은 조작이 디버거 창에서도 가능합니다. 상위 메뉴 __Break__ 에서 __Line Break__ 를 선택해 브레이크 포인트를 설정합니다. 코드가 없는 줄을 선택하면 브레이크 포인트는 무시되지만, 디버거 창에서는 나타납니다. 3 종류의 브레이크 포인트가 있습니다.

+ Line breakpoint — 특정 줄에 도달했을 때, 디버거가 실행을 정지합니다. `:int.break/2`로 설정합니다.
+ Conditional breakpoint — line breakpoint와 비슷하지만 디버거가 특정 조건을 만족했을 때만 정지합니다. 조건은 `:int.get_binding/2`으로 설정합니다.
+ Function breakpoint — 디버거는 함수의 첫 번째 줄에서 실행을 정지합니다. `:int.break_in/3`으로 설정합니다.

이게 전부입니다! 즐거운 디버깅되세요!
