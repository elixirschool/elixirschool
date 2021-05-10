%{
  version: "1.1.1",
  title: "제어 구조",
  excerpt: """
  이번 강의에서는 우리가 Elixir에서 사용할 수 있는 제어 구조들에 대해 알아봅니다.
  """
}
---

## if 와 unless

여러분은 이전에 `if/2`를 본 적이 있을 것입니다. 그리고 Ruby를 써 본 적이 있다면 `unless/2`에도 익숙하겠지요. Elixir에서도 이 둘은 거의 똑같이 동작하지만, 언어 구조가 아닌 매크로로서 정의되어 있습니다. [Kernel module](https://hexdocs.pm/elixir/Kernel.html)에서 이것들이 어떻게 정의되어 있는지 볼 수 있습니다.

Elixir에서는 `nil`과 부울 값 `false`만이 거짓으로 간주됨을 유의하십시오.

```elixir
iex> if String.valid?("Hello") do
...>   "Valid string!"
...> else
...>   "Invalid string."
...> end
"Valid string!"

iex> if "a string value" do
...>   "Truthy"
...> end
"Truthy"
```

`unless/2`를 쓰는 법은 `if/2`와 같지만 정반대로 동작합니다.

```elixir
iex> unless is_integer("hello") do
...>   "Not an Int"
...> end
"Not an Int"
```

## case

여러 패턴에 대해 매치해야 한다면 `case/2`를 이용할 수 있습니다.

```elixir
iex> case {:ok, "Hello World"} do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```

`_` 변수는 `case/2` 구문에서 중요한 요소입니다. 이것이 없으면 일치하는 패턴을 찾지 못했을 때 오류가 발생합니다.

```elixir
iex> case :even do
...>   :odd -> "Odd"
...> end
** (CaseClauseError) no case clause matching: :even

iex> case :even do
...>   :odd -> "Odd"
...>   _ -> "Not Odd"
...> end
"Not Odd"
```

`_`를 "그 외의 모든 것"에 매치되는 `else`처럼 생각하십시오.

`case/2`는 패턴 매칭에 의존하기 때문에 같은 규칙과 제약이 모두 적용됩니다. 기존의 변수에 매치하고자 한다면 핀 연산자 `^/1`를 사용해야 합니다.

```elixir
iex> pie = 3.14
3.14
iex> case "cherry pie" do
...>   ^pie -> "Not so tasty"
...>   pie -> "I bet #{pie} is tasty"
...> end
"I bet cherry pie is tasty"
```

`case/2`의 또다른 멋진 점은 가드 구문을 지원한다는 것입니다.

_이 예제는 Elixir [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#case) 가이드에서 그대로 가져온 것입니다._

```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "Will match"
...>   _ ->
...>     "Won't match"
...> end
"Will match"
```
[Expressions allowed in guard clauses](https://hexdocs.pm/elixir/guards.html#list-of-allowed-expressions) 공식 문서를 참고하십시오.

## cond

값이 아닌 조건식에 매치해야 할 때에는 `cond/1`를 사용하면 됩니다. 이는 다른 언어의 `else if`나 `elsif`와 유사합니다.

_이 예제는 Elixir [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#cond) 가이드에서 그대로 가져온 것입니다._

```elixir
iex> cond do
...>   2 + 2 == 5 ->
...>     "This will not be true"
...>   2 * 2 == 3 ->
...>     "Nor this"
...>   1 + 1 == 2 ->
...>     "But this will"
...> end
"But this will"
```

`case/2`와 마찬가지로, `cond/1`도 일치하는 조건식이 없을 경우 에러를 발생시킵니다. 이를 해결하려면 `true` 조건식을 정의합니다.

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```

## with

특별한 구문인 `with/1`는 중첩된 `case/2` 구문이 쓰일만한 곳이나 깔끔하게 파이프 연산을 할 수 없는 상황에서 유용합니다. `with/1`식은 키워드, 제너레이터, 그리고 식으로 구성되어 있습니다.

제너레이터에 대해서는 [List Comprehension](../comprehensions/) 강의에서 살펴 볼 것이지만, 지금은 `<-`의 오른쪽을 왼쪽과 비교하기 위해 [패턴 매칭](../pattern-matching/)을 사용한다는 것만 알아두시면 됩니다.

일단 `with/1`의 간단한 예제를 보고 차근차근 알아보기로 합시다.

```elixir
iex> user = %{first: "Sean", last: "Callan"}
%{first: "Sean", last: "Callan"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
"Callan, Sean"
```

식의 매치가 실패하는 경우에는 매치되지 않은 값이 반환됩니다.

```elixir
iex> user = %{first: "doomspork"}
%{first: "doomspork"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
:error
```

이제 `with/1`가 없는 더 큰 예제를 보고, 이것을 어떻게 리팩토링할 수 있는지 봅시다.

```elixir
case Repo.insert(changeset) do
  {:ok, user} ->
    case Guardian.encode_and_sign(user, :token, claims) do
      {:ok, token, full_claims} ->
        important_stuff(token, full_claims)

      error ->
        error
    end

  error ->
    error
end
```

`with/1`를 도입하면 더 짧으면서도 이해하기 쉬운 코드를 작성할 수 있습니다.

```elixir
with {:ok, user} <- Repo.insert(changeset),
     {:ok, token, full_claims} <- Guardian.encode_and_sign(user, :token, claims) do
  important_stuff(token, full_claims)
end
```


Elixir 1.3부터 `with/1`구문에서 `else`를 사용할 수 있습니다.

```elixir
import Integer

m = %{a: 1, c: 3}

a =
  with {:ok, res} <- Map.fetch(m, :a),
       true <- is_even(res) do
    IO.puts("Divided by 2 it is #{div(res, 2)}")
    :even
  else
    :error ->
      IO.puts("We don't have this item in map")
      :error

    _ ->
      IO.puts("It's not odd")
      :odd
  end
```

이는 오류를 처리할 때 `case`같은 패턴매칭을 사용할 수 있도록 도와줍니다. 넘겨지는 값은 첫 번째 매치하지 않은 표현식입니다.
