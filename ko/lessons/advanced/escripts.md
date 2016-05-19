---
layout: page
title: 실행 파일
category: advanced
order: 3
lang: ko
---

escript를 사용하여 Elixir로 짠 코드를 실행 파일로 빌드할 수 있습니다. 이렇게 빌드한 실행 파일은 Erlang이 설치된 모든 시스템에서 실행할 수 있게 됩니다.

{% include toc.html %}

## 시작하기

escript로 실행 파일을 만들어내기 위해 해야 할 일은 얼마 없어요. 그냥 `main/1` 메서드를 구현하고 Mixfile을 수정해주기만 하면 됩니다.

실행 파일에서 출발점 역할을 하는 모듈을 만드는 것부터 시작해봅시다. 바로 이 모듈에다가 `main/1`을 구현할 거예요.

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    # 뭐라도 해보자
  end
end
```

그 다음 Mixfile에서 메인 모듈(`:main_module`)로 지정해 주고 이를 `:escript` 옵션으로 프로젝트 설정에 덧붙여주면 됩니다.

```elixir
defmodule ExampleApp.Mixfile do
  def project do
    [app: :example_app,
     version: "0.0.1",
     escript: escript]
  end

  def escript do
    [main_module: ExampleApp.CLI]
  end
end
```

## 명령행에서 주어진 인수 처리하기

애플리케이션을 준비한다면 이제는 명령행에서 주어지는 인수를 다루는 법을 살펴볼 때가 되었습니다. Elixir에서는 `OptionParser.parse/2`를 사용하여 인수를 처리할 수 있는데요, 우리가 명령행에서 불리언 값으로 인수를 받을 것을 `:switches` 옵션에서 설정할 수 있습니다.

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    args
    |> parse_args
    |> response
    |> IO.puts
  end

  defp parse_args(args) do
    {opts, word, _} =
      args
      |> OptionParser.parse(switches: [upcase: :boolean])

    {opts, List.to_string(word)}
  end

  defp response({opts, "Hello"}), do: response({opts, "World"})
  defp response({opts, word}) do
    if opts[:upcase], do: word = String.upcase(word)
    word
  end
end
```

## 빌드하기

애플리케이션이 escript를 사용하도록 설정을 끝내고 나면, mix를 사용해서 실행파일을 한방에 시원하게 만들 수 있습니다.

```elixir
$ mix escript.build
```

이제 시운전을 한번 해 봅시다.

```elixir
$ ./example_app --upcase Hello
WORLD

$ ./example_app Hi
Hi
```

바로 이렇게요. escript를 사용하여 첫 Elixir 실행 파일을 빌드하는 법을 알아보았습니다.
