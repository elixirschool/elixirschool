---
layout: page
title: 시길
category: basics
order: 10
lang: ko
---

시길을 이용하고 만드는 법.

{% include toc.html %}

## 시길 개요

Elixir에서는 리터럴을 표현하거나 리터럴을 가지고 작업을 하기위한 대체 문법을 제공합니다. 시길은 물결 문자 `~`와 그 뒤에 붙는 한 문자로 구성되어 있습니다. 몇 가지 시길은 Elixir 코어에서 기본적으로 제공되지만, 여러분이 언어를 확장할 필요가 있을 때 여러분만의 시길을 만들 수도 있습니다.

아래는 사용 가능한 시길의 목록입니다.

  - `~C`는 이스케이프나 내부 식 전개 **없이** 문자 리스트를 생성합니다
  - `~c`는 이스케이프나 내부 식 전개를 **하면서** 문자 리스트를 생성합니다
  - `~R`는 이스케이프나 내부 식 전개 **없이** 정규 표현식을 생성합니다
  - `~r`는 이스케이프나 내부 식 전개를 **하면서** 정규 표현식을 생성합니다
  - `~S`는 이스케이프나 내부 식 전개 **없이** 문자열을 생성합니다
  - `~s`는 이스케이프나 내부 식 전개를 **하면서** 문자열을 생성합니다
  - `~W`는 이스케이프나 내부 식 전개 **없이** 단어 리스트를 생성합니다
  - `~w`는 이스케이프나 내부 식 전개를 **하면서** 단어 리스트를 생성합니다

사용 가능한 구분자의 목록은 다음과 같습니다.

  - `<...>` 꺽쇠 괄호 한 쌍
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
'2 + 7 = #{2 + 7}'
```

소문자 `~c`는 수식을 계산하여 문자 리스트에 확장하지만, 대문자 시길 `~C`는 그렇지 않음을 알 수 있습니다. 
We can see the lowercased `~c` interpolates the calculation, whereas the uppercased `~C` sigil does not. We will see that this uppercase / lowercase sequence is a common theme throughout the built in sigils.

### Regular Expressions

The `~r` and `~R` sigils are used to represent Regular Expressions. We create them either on the fly or for use within the `Regex` functions. For example:

```elixir
iex> re = ~r/elixir/
~/elixir

iex> "Elixir" =~ re
false

iex> "elixir" =~ re
true
```

We can see that in the first test for equality, that `Elixir` does not match with the regular expression. This is because it is capitalized. Because Elixir supports Perl Compatible Regular Expressions (PCRE), we can append `i` to the end of our sigil to turn off case sensitivity.

```elixir
iex> re = ~r/elixir/i
~/elixir

iex> "Elixir" =~ re
true

iex> "elixir" =~ re
true
```

Further, Elixir provides the [Regex](http://elixir-lang.org/docs/stable/elixir/Regex.html) API which is built on top of Erlang's regular expression library. Let's implement `Regex.split/2` using a regex sigil:

```elixir
iex> string = "100_000_000"
"100_000_000"

iex> Regex.split(~r/_/, string)
["100", "000", "000"]
```

As we can see, the string `"100_000_000"` is split on the underscore thanks to our `~r/_/` sigil. The `Regex.split` function returns a list.

### String

The `~s` and `~S` sigils are used to generate string data. For example:

```elixir
iex> ~s/the cat in the hat on the mat/
"the cat in the hat on the mat"

iex> ~S/the cat in the hat on the mat/
"the cat in the hat on the mat"
```
But what is the difference? The difference is similar to the Character List sigil that we looked at. The answer is interpolation and the use of escape sequences. If we take another example:

```elixir
iex> ~s/welcome to elixir #{String.downcase "school"}/
"welcome to elixir school"

iex> ~S/welcome to elixir #{String.downcase "school"}/
"welcome to elixir \#{String.downcase \"school\"}"
```

### Word List

The word list sigil can come in very handy time to time. It can save both time, keystrokes and arguably reduce the complexity within the codebase. Take this simple example:

```elixir
iex> ~w/i love elixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love elixir school/
["i", "love", "elixir", "school"]
```

We can see that what is typed between the delimiters is separated by whitespace into a list. However, there is no difference between these two examples. Again, the difference comes with the interpolation and escape sequences. Take the following example:

```elixir
iex> ~w/i love #{'e'}lixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love #{'e'}lixir school/
["i", "love", "\#{'e'}lixir", "school"]
```

## Creating Sigils

One of the goals of Elixir is to be an extensible programming language. It should come as no surprise then that you can easily create your own custom sigils. In this example, we will create a sigil to convert a string to uppercase. As there is already a function for this in the Elixir Core (`String.upcase/1`), we will wrap our sigil around that function.

```elixir

iex> defmodule MySigils do
...>   def sigil_u(string, []), do: String.upcase(string)
...> end

iex> import MySigils
nil

iex> ~u/elixir school/
ELIXIR SCHOOL
```

First we define a module called `MySigils` and within that module, we created a function called `sigil_u`. As there is no existing `~u` sigil in the existing sigil space, we will use it. The `_u` indicates that we wish use `u` as the character after the tilde. The function definition must take two arguments, an input and a list.
