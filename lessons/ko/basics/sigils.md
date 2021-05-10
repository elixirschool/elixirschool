---
version: 1.0.1
title: 시길
---

시길을 이용하고 만드는 법.

{% include toc.html %}

## 시길 개요

Elixir에서는 리터럴을 표현하거나 리터럴을 가지고 작업을 할 수 있도록 대체 문법을 제공합니다. 시길은 물결 문자 `~`와 그 뒤에 붙는 한 문자로 구성되어 있습니다. 몇 가지 시길은 Elixir 코어에서 기본적으로 제공되지만, 여러분이 언어를 확장할 필요가 있을 때 여러분만의 시길을 만들 수도 있습니다.

아래는 사용 가능한 시길의 목록입니다.

  - `~C`는 이스케이프나 내부 식 전개 **없이** 문자 리스트를 생성합니다
  - `~c`는 이스케이프나 내부 식 전개를 **하면서** 문자 리스트를 생성합니다
  - `~R`은 이스케이프나 내부 식 전개 **없이** 정규 표현식을 생성합니다
  - `~r`은 이스케이프나 내부 식 전개를 **하면서** 정규 표현식을 생성합니다
  - `~S`는 이스케이프나 내부 식 전개 **없이** 문자열을 생성합니다
  - `~s`는 이스케이프나 내부 식 전개를 **하면서** 문자열을 생성합니다
  - `~W`는 이스케이프나 내부 식 전개 **없이** 단어 리스트를 생성합니다
  - `~w`는 이스케이프나 내부 식 전개를 **하면서** 단어 리스트를 생성합니다
  - `~N`은 `NaiveDateTime` 구조체를 생성합니다.

사용 가능한 구분자의 목록은 다음과 같습니다.

  - `<...>` 꺾쇠 괄호 한 쌍
  - `{...}` 중괄호 한 쌍
  - `[...]` 대괄호 한 쌍
  - `(...)` 소괄호 한 쌍
  - `|...|` 파이프 한 쌍
  - `/.../` 슬래시 한 쌍
  - `"..."` 큰따옴표 한 쌍
  - `'...'` 작은따옴표 한 쌍

### 문자 리스트

`~c`와 `~C` 시길은 각각 문자 리스트를 생성합니다. 예를 들면,

```elixir
iex> ~c/2 + 7 = #{2 + 7}/
'2 + 7 = 9'

iex> ~C/2 + 7 = #{2 + 7}/
'2 + 7 = \#{2 + 7}'
```

소문자 `~c`는 수식을 계산하여 문자 리스트에 확장하지만, 대문자 시길 `~C`는 그렇지 않음을 알 수 있습니다. 앞으로 살펴볼 내장 시길에서도 소문자/대문자로 수식 확장을 하는가 안 하는가를 구별할 수 있을 것입니다.

### 정규 표현식

`~r`과 `~R` 시길은 정규 표현식을 나타내기 위해 사용됩니다. 정규 표현식은 바로 사용하기 위해 만들거나 `Regex` 함수 안에서 쓰기 위해 만듭니다. 예를 들면,

```elixir
iex> re = ~r/elixir/
~r/elixir/

iex> "Elixir" =~ re
false

iex> "elixir" =~ re
true
```

첫번째 동등 비교에서 `Elixir`는 정규 표현식과 일치하지 않음을 알 수 있습니다. 왜냐하면 그 단어는 첫 글자가 대문자이기 때문이죠. Elixir는 Perl 호환 정규 표현식 (PCRE)를 지원하기 때문에 시길 뒤에 `i`를 붙여서 대소문자 검사를 끌 수 있습니다.

```elixir
iex> re = ~r/elixir/i
~r/elixir/i

iex> "Elixir" =~ re
true

iex> "elixir" =~ re
true
```

더 나아가서, Elixir는 Erlang의 정규 표현식 라이브러리를 기반으로 만들어진 [Regex](https://hexdocs.pm/elixir/Regex.html) API를 제공합니다. 정규 표현식 시길을 사용하여 `Regex.split/2`를 사용해 봅시다.

```elixir
iex> string = "100_000_000"
"100_000_000"

iex> Regex.split(~r/_/, string)
["100", "000", "000"]
```

보다시피, 문자열 `"100_000_000"`이 `~r/_/` 시길 덕분에 밑줄을 기준으로 쪼개졌습니다. `Regex.split` 함수는 리스트를 반환합니다.

### 문자열

`~s`와 `~S` 시길은 문자열 데이터를 생성하는 데 사용됩니다. 예를 들면,

```elixir
iex> ~s/the cat in the hat on the mat/
"the cat in the hat on the mat"

iex> ~S/the cat in the hat on the mat/
"the cat in the hat on the mat"
```

차이는 무엇일까요? 차이는 앞에서 보았던 문자 리스트 시길과 비슷합니다. 정답은 식 전개와 이스케이프 시퀀스의 사용입니다. 다른 예를 한 번 들어보겠습니다.

```elixir
iex> ~s/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir school"

iex> ~S/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir \#{String.downcase \"SCHOOL\"}"
```

### 단어 리스트

단어 리스트 시길은 때때로 유용하게 사용됩니다. 이 시길은 작업 시간과 키 입력 횟수를 동시에 줄이며, 코드베이스의 복잡도를 확실하게 줄여줍니다. 이 간단한 예제를 보죠.

```elixir
iex> ~w/i love elixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love elixir school/
["i", "love", "elixir", "school"]
```

구분자 안에 쓰여진 것들이 공백에 의해 분리되어 리스트로 저장됨을 알 수 있습니다. 하지만 이 두 예제에서 차이점은 없어 보이네요. 이것 역시 차이점은 식 전개와 이스케이프 시퀀스에 있습니다. 다음 예제를 봅시다.

```elixir
iex> ~w/i love #{'e'}lixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love #{'e'}lixir school/
["i", "love", "\#{'e'}lixir", "school"]
```

### NaiveDateTime

[NaiveDateTime](https://hexdocs.pm/elixir/NaiveDateTime.html)으로 타임존 **없는** DateTime을 나타내는 구조체를 빠르게 만드는데 유용하게 사용할 수 있습니다.

대부분의 경우, `NaiveDateTime` 구조체를 직접 만드는 것은 피해야 합니다. 하지만, 패턴 매칭에는 매우 유용합니다. 예를 봅시다.

```elixir
iex> NaiveDateTime.from_iso8601("2015-01-23 23:50:07") == {:ok, ~N[2015-01-23 23:50:07]}
```

## 시길 만들기

Elixir의 목표 중 하나는 확장 가능한 프로그래밍 언어가 되는 것입니다. 여러분이 여러분만의 시길을 쉽게 만들 수 있다는 것이 놀랍지 않다고 느껴져야 합니다. 이 예제에서는 문자열을 대문자로 변환하는 시길을 만들어 볼 것입니다. Elixir 코어에는 이미 이러한 일을 하는 함수가 있기 때문에 (`String.upcase/1`), 그 함수를 시길로 감싸보겠습니다.

```elixir

iex> defmodule MySigils do
...>   def sigil_u(string, []), do: String.upcase(string)
...> end

iex> import MySigils
nil

iex> ~u/elixir school/
ELIXIR SCHOOL
```

먼저 `MySigils`라는 모듈을 만들고, 그 모듈 안에 `sigil_u`라는 함수를 만들었습니다. 기존의 시길중에 `~u` 시길이 없기 때문에 이것을 사용할 것입니다. `_u`는 물결 문자 다음에 `u`를 쓰고자 한다는 것을 의미합니다. 함수는 반드시 입력과 리스트, 이 두 개의 인자를 받아야 합니다.
