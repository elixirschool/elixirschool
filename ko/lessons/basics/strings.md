---
version: 1.1.1
title: 문자열
---

Elixir에서의 문자열, 문자 리스트, 문자소, 코드 포인트에 대해 다뤄 보겠습니다.

{% include toc.html %}

## Elixir에서의 문자열

Elixir에서 문자열은 바이트 시퀀스에 불과합니다. 다음의 예시를 봅시다.

```elixir
iex> string = <<104,101,108,108,111>>
"hello"
iex> string <> <<0>>
<<104, 101, 108, 108, 111, 0>>
```

문자열에 `0`이라는 바이트를 추가하면 IEx는 문자열을 바이너리인 것처럼 출력합니다. 이는 더이상 유효한 문자열이 아니기 때문입니다. 이 방법은 문자열을 표현하는 실제 바이트가 어떤 것인지를 확인할 때 유용합니다.

>NOTE: << >> 문법을 이용함으로써, 컴파일러에게 이 기호들로 감싸진 모든 원소들이 전부 바이트라고 알립니다.

## 문자 리스트

Elixir 내부에서, 문자열은 문자의 배열이라기보다는 바이트의 시퀀스로 나타납니다. 물론, 문자 리스트 타입은 별도로 있습니다. Elixir에서 문자열은 큰따옴표로 생성이 되지만, 문자 리스트는 작은따옴표로 생성됩니다.

과연 무슨 차이가 있을까요? 문자 리스트의 각 값은 바이너리로 표현되어 있는 각 문자의 유니코드의 코드포인트이며, 각 코드포인트는 UTF-8로 인코딩되어 있습니다. 그 내부를 보도록 하죠.

```elixir
iex(5)> 'hełło'
[104, 101, 322, 322, 111]
iex(6)> "hełło" <> <<0>>
<<104, 101, 197, 130, 197, 130, 111, 0>>
```

`322`는 ł를 표현하는 유니코드의 코드포인트이지만 UTF-8로 인코딩되므로 `197`, `130`으로 표현되어 있습니다.

Elixir로 프로그래밍할 때, 문자 리스트보다는 문자열을 자주 사용하게 됩니다. 문자 리스트의 지원은 몇몇 얼랭 모듈에 필요하기 때문에 포함되어 있습니다.

더 자세한 정보는 공식 [`시작 가이드`](http://elixir-lang.org/getting-started/binaries-strings-and-char-lists.html)를 참고하세요.

## 문자소와 코드 포인트

코드 포인트는 UTF-8 인코딩에 따라 하나 이상의 바이트로 나타낼 수 있는 유니코드 문자입니다. US ASCII 문자 집합에 속하지 않는 문자들은 항상 둘 이상의 바이트로 인코딩됩니다. 예를 들어, 물결 표시와 강조 부호가 들어간 라틴 문자(`á, ñ, è`)들은 보통 2바이트로 인코딩됩니다. 아시아 언어에서 사용하는 문자들은 보통 3 또는 4바이트로 인코딩됩니다. 문자소는 하나의 문자로 렌더링되는 여러 개의 코드 포인트로 구성되어 있습니다.

문자열 모듈은 이것들을 가져오기 위해, `graphemes/1`와 `codepoints/1`, 이렇게 두 가지 함수를 제공합니다. 다음의 예제에서 살펴보죠.

```elixir
iex> string = "\u0061\u0301"
"á"

iex> String.codepoints string
["a", "́"]

iex> String.graphemes string
["á"]
```

## 문자열 함수

문자열 모듈에서 가장 중요하고 쓸만한 몇 가지 함수들을 살펴보도록 합시다. 이 강좌에서는 사용할 수 있는 함수의 일부만 다룹니다. 사용할 수 있는 함수의 전체 목록을 보시려면, 공식 [`String`](https://hexdocs.pm/elixir/String.html) 문서를 확인하세요.

### `length/1`

문자열이 가지는 문자소의 개수를 반환합니다.

```elixir
iex> String.length "Hello"
5
```

### `replace/4`

문자열 내에서 발견되는 패턴을 다른 문자열로 치환하여 새 문자열을 반환합니다.

```elixir
iex> String.replace("Hello", "e", "a")
"Hallo"
```

### `duplicate/2`

n번 반복되는 새 문자열을 반환합니다.

```elixir
iex> String.duplicate "Oh my ", 3
"Oh my Oh my Oh my "
```

### `split/2`

문자열을 패턴에 따라 분리해 문자열의 리스트를 반환합니다.

```elixir
iex> String.split("Hello World", " ")
["Hello", "World"]
```

## 연습

문자열을 다룰 준비가 되셨다면, 바로 2개의 간단한 예제들을 다루도록 하겠습니다!

### 애너그램

A와 B를 재정렬하여 서로 같다는 것을 보일 수 있다면, A와 B는 애너그램이라 합니다. 다음의 예시를 보죠.

+ A = super
+ B = perus

문자열 A를 재정렬하면, 문자열 B를 얻을 수 있습니다. 반대로도 마찬가지입니다.

자, 그러면 Elixir에서 두 문자열이 애너그램인지 확인하고자 할 때, 어떤 방법이 있을까요? 가장 쉬운 접근 방식은 문자열들을 알파벳 순서대로 정렬하여 서로 같은지 확인하는 것입니다. 다음의 예제에서 확인해보죠.

```elixir
defmodule Anagram do
  def anagrams?(a, b) when is_binary(a) and is_binary(b) do
    sort_string(a) == sort_string(b)
  end

  def sort_string(string) do
    string
    |> String.downcase()
    |> String.graphemes()
    |> Enum.sort()
  end
end
```

먼저 `anagrams?/2`에 주목해보죠. 전달받고 있는 인자들이 2진수인지 아닌지 확인하고 있습니다. Elixir에서 전달받는 인자가 문자열인지 확인할 때 이렇게 한다고 보시면 됩니다.

그러고 나서, 문자열을 알파벳 순서로 정렬합니다. 우선 문자들을 소문자로 만든 뒤, `String.graphemes/1`을 사용하여 문자소 리스트를 얻습니다. 마지막으로 이 목록을 `Enum.sort/1`에 넘깁니다. 정말 직관적이지 않나요?

iex에서의 출력을 확인해봅시다.

```elixir
iex> Anagram.anagrams?("Hello", "ohell")
true

iex> Anagram.anagrams?("María", "íMara")
true

iex> Anagram.anagrams?(3, 5)
** (FunctionClauseError) no function clause matching in Anagram.anagrams?/2

    The following arguments were given to Anagram.anagrams?/2:

        # 1
        3

        # 2
        5

    iex:11: Anagram.anagrams?/2
** [역주] (함수절에러) 어떤 함수의 절도 Anagram.anagrams?/2에서 매치되지 않습니다
	iex:2: Anagram.anagrams?(3, 5)
```

방금 보신 것처럼, 마지막에서 호출한 `anagrams?`는 FunctionClauseError를 일으킵니다. 이 에러는 2진수가 아닌 인자를 받는 패턴을 만족하는 함수가 모듈에 없다는 것을 알려줍니다. 이는 정확히 의도적인 것이고, 두 문자열만 전달받는 기능 외에는 필요 없습니다.
