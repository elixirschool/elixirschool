%{
  version: "1.0.1",
  title: "비헤이비어",
  excerpt: """
  이전 강좌에서 타입스펙에 관해 배웠습니다. 여기서는 모듈에서 그 사양을 구현하도록 요구하는 방법을 배우겠습니다. Elixir에서 이 기능은 비헤이비어(behaviour)라는 이름으로 불립니다.
  """
}
---

## 용도

가끔 공개 API를 공유하기 위한 모듈을 만들어야 할 때가 있는데, 이를 위해 Elixir에서는 비헤이비어를 사용합니다. 비헤이비어가 하는 일은 크게 두 가지입니다.

+ 구현해야만 하는 함수(function)의 목록을 정의
+ 그 함수가 실제로 구현되었는지 확인

Elixir는 GenServer를 비롯해 비헤이비어를 여럿 가지고 있습니다만, 이 강좌에서는 그런 것을 사용하기 보단 직접 만드는것에 집중해 보겠습니다.

## 비헤이비어 정의하기

비헤이비어를 좀 더 잘 이해하기 위해 워커 모듈을 위한 비헤이비어를 구현해 보겠습니다. 이 워커는 `init/1`, `perform/2` 두 함수가 구현되어 있어야 합니다.

이를 충족하기 위해, `@spec`과 비슷한 문법을 가진 `@callback` 디렉티브를 사용하겠습니다. 이 디렉티브로 **반드시 구현**되어야 하는 함수를 정의합니다. 매크로는 `@macrocallback`를 사용해서 할 수 있습니다. 워커를 위해 `init/1`, `perform/2` 함수를 정의해 봅니다.

```elixir
defmodule Example.Worker do
  @callback init(state :: term) :: {:ok, new_state :: term} | {:error, reason :: term}
  @callback perform(args :: term, state :: term) ::
              {:ok, result :: term, new_state :: term}
              | {:error, reason :: term, new_state :: term}
end
```

여기에 정의된 `init/1`는 어떤 값을 받아 튜플 `{:ok, state}`나 `{:error, reason}`를 반환합니다. 이는 초기화에서 꽤 일반적인 패턴입니다. `perform/2` 함수는 어떤 인자를 받아 워커의 상태를 초기화합니다. `perform/2`는 `{:ok, result, state}`나 `{:error, reason, state}`를 반환하길 기대하고 이는 GenServer와 비슷합니다.

## 비헤이비어 사용하기

이제 비헤이비어를 정의했으니 공개 API를 공유하는 다양한 모듈에서 이를 사용할 수 있습니다. 비헤이비어를 모듈에 추가하는 것은 `@behaviour` 속성을 사용하면 쉽습니다.

새로운 비헤이비어를 사용해 원격에서 파일을 다운로드해 로컬에 저장하는 모듈 테스크를 만들어 봅시다.

```elixir
defmodule Example.Downloader do
  @behaviour Example.Worker

  def init(opts), do: {:ok, opts}

  def perform(url, opts) do
    url
    |> HTTPoison.get!()
    |> Map.fetch(:body)
    |> write_file(opts[:path])
    |> respond(opts)
  end

  defp write_file(:error, _), do: {:error, :missing_body}

  defp write_file({:ok, contents}, path) do
    path
    |> Path.expand()
    |> File.write(contents)
  end

  defp respond(:ok, opts), do: {:ok, opts[:path], opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

아니면 여러 파일을 압축하는 워커는 어떨까요? 그것도 가능합니다.

```elixir
defmodule Example.Compressor do
  @behaviour Example.Worker

  def init(opts), do: {:ok, opts}

  def perform(payload, opts) do
    payload
    |> compress
    |> respond(opts)
  end

  defp compress({name, files}), do: :zip.create(name, files)

  defp respond({:ok, path}, opts), do: {:ok, path, opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

워커의 수행 내용은 다르지만, 공개되는 API는 같고 이 모듈을 사용하는 코드에서는 예상대로 응답할 것을 알 수 있습니다. 이는 모두 다른 일을 하지만 같은 공개 API를 따르는 워커를 만들 수 있게 합니다.

비헤이비어를 추가할 때 모든 필요한 함수를 구현하는데 실패한다면, 컴파일 시에 경고가 발생합니다. 이 동작을 확인하기 위해 `Example.Compressor`코드에서 `init/1` 함수를 제거해 봅시다.

```elixir
defmodule Example.Compressor do
  @behaviour Example.Worker

  def perform(payload, opts) do
    payload
    |> compress
    |> respond(opts)
  end

  defp compress({name, files}), do: :zip.create(name, files)

  defp respond({:ok, path}, opts), do: {:ok, path, opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

이제 컴파일하면 필요한 함수가 구현되지 않았다는 경고를 확인할 수 있습니다.

```shell
lib/example/compressor.ex:1: warning: undefined behaviour function init/1 (for behaviour Example.Worker)
Compiled lib/example/compressor.ex
```

끝입니다! 이제 우리는 비헤이비어를 만들고 공유할 수 있습니다.
