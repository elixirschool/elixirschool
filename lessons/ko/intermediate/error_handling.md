%{
  version: "1.0.1",
  title: "에러 처리",
  excerpt: """
  `{:error, reason}` 튜플을 반환하는 것이 더 흔하지만, Elixir는 예외를 지원합니다. 이번 강의에서는 에러를 어떻게 처리할 것인지, 에러를 처리하는 다양한 원리들을 다룰 것입니다.

일반적으로 Elixir에서는 `{:ok, result}`와 `{:error, reason}`을 반환하는 함수(`example/1`)와 각각 감싸지지 않은 `result`를 반환하는 함수와 에러를 발생시키는 함수(`example!/1`)를 생성하는 것이 관례입니다.

이번 강의에서는 후자를 집중해서 다루겠습니다.
  """
}
---

## 에러 처리

에러를 처리하기 전에, 에러를 생성해야 할 필요가 있습니다. 가장 간단한 방법은 `raise/1`를 사용하는 것입니다.

```elixir
iex> raise "Oh no!"
** (RuntimeError) Oh no!
```

에러의 유형과 메시지를 명시하고 싶다면, `raise/2`를 이용할 수 있습니다.

```elixir
iex> raise ArgumentError, message: "인자의 값이 올바르지 않습니다"
** (ArgumentError) 인자의 값이 올바르지 않습니다
```

에러가 일어나는 시점을 알고 있다면, 이를 `try/rescue`와 패턴매칭으로 다룰 수 있습니다.

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> end
An error occurred: Oh no!
:ok
```

하나의 rescue로 여러 개의 에러를 매치하는 것도 가능합니다.

```elixir
try do
  opts
  |> Keyword.fetch!(:source_file)
  |> File.read!()
rescue
  e in KeyError -> IO.puts("missing :source_file option")
  e in File.Error -> IO.puts("unable to read source file")
end
```

## After

간혹, 에러 발생여부와 상관없이 `try/rescue`가 끝난 뒤에 추가적인 액션을 수행해야 할 수도 있습니다. 그럴 경우에는 `try/after`를 씁니다. Ruby에 익숙하다면 `begin/rescue/ensure`와 비슷하고, Java에 익숙하다면 `try/catch/finally`와 비슷하다고도 할 수 있습니다.

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> after
...>   IO.puts "The end!"
...> end
An error occurred: Oh no!
The end!
:ok
```

파일을 닫거나, 접속을 종료해야 할 때 가장 많이 사용됩니다.

```elixir
{:ok, file} = File.open("example.json")

try do
  # 위험이 큰 함수를 실행
after
  File.close(file)
end
```

## 새로운 에러

Elixir가 `RuntimeError`와 같은 내장 에러 타입을 여럿 포함하고 있지만, 필요하다면 그에 맞는 에러를 만들 수 있어야 합니다. `defexception/1` 매크로를 이용하여 새로운 에러를 쉽게 만들 수 있습니다. `defexception/1` 매크로는 `:message` 옵션을 인자로 받아, 편리하게 기본 에러 메시지를 설정할 수 있습니다.

```elixir
defmodule ExampleError do
  defexception message: "an example error has occurred"
end
```

방금 정의한 새로운 에러를 접해보도록 하죠.

```elixir
iex> try do
...>   raise ExampleError
...> rescue
...>   e in ExampleError -> e
...> end
%ExampleError{message: "an example error has occurred"}
```

## Throws

Elixir에서 에러를 다루는 또 다른 방법은 `throw`와 `catch`입니다. 요즘 Elixir 코드에서는 많이 발견되지 않지만, 이들을 알고 이해하는 것이 중요합니다.

`throw/1` 함수는 `catch`에 특정한 값을 넘겨서 실행을 종료할 수 있게 합니다.

```elixir
iex> try do
...>   for x <- 0..10 do
...>     if x == 5, do: throw(x)
...>     IO.puts(x)
...>   end
...> catch
...>   x -> "Caught: #{x}"
...> end
0
1
2
3
4
"Caught: 5"
```

위에서 언급했다시피, `throw/catch`는 그리 많이 쓰이지 않으며, 라이브러리가 적당한 API를 제공하지 못할 때 임시방편으로 많이 쓰입니다.

## 종료하기

마지막으로 다루게 되는 Elixir의 에러는 `exit` 입니다. 프로세스가 죽을 때마다 발생하는 Exit 시그널은 Elixir의 무정지성으로 직결되는 가장 중요한 부분이기도 합니다.

명시적으로 종료하고자 할 때, `exit/1`을 쓸 수 있습니다.

```elixir
iex> spawn_link fn -> exit("oh no") end
** (EXIT from #PID<0.101.0>) evaluator process exited with reason: "oh no"
```

`try/catch`를 이용하여 종료를 잡아내는 것이 가능하지만, 그런 경우는 _극히_ 드뭅니다. 대부분의 경우, 수퍼바이저가 프로세스 종료를 다루도록 하는 것이 유리합니다.

```elixir
iex> try do
...>   exit "oh no!"
...> catch
...>   :exit, _ -> "exit blocked"
...> end
"exit blocked"
```
