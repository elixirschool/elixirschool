---
layout: page
title: Functions
category: basics
order: 7
lang: ko
---

엘릭서를 포함한 많은 함수형 언어에서, 함수들은 일급 시민입니다. 우리는 엘릭서를 특별하게 해주는 함수의 유형에 대해 배우고, 그것을 어떻게 이용하는지 배울 것입니다.
In Elixir and many functional languages, functions are first class citizens.  We will learn about the types of functions in Elixir, what makes them different, and how to use them.

## 목차

- [Anonymous functions](#anonymous-functions)
  - [The & shorthand](#the--shorthand)
- [Pattern matching](#pattern-matching)
- [Named functions](#named-functions)
  - [Private functions](#private-functions)
  - [Guards](#guards)
  - [Default arguments](#default-arguments)

## 익명 함수
## Anonymous functions

이름이 암시하는 것과 같이, 익명 함수는 이름이 없습니다. `Enum` 수업에서 보았듯이, 함수는 빈번히 다른 함수로 넘겨지게 됩니다. 엘릭서에서 익명 함수를 정의하기 위해, 우리는 `fn` 그리고 `end` 키워드가 필요합니다. 익명 함수 내에서 우리는 매개변수의 개수를 정의할 수 있고, 함수의 몸체는 `->`로 구분됩니다.
Just as the name implies, an anonymous function has no name.  As we saw in the `Enum` lesson, they are frequently passed to other functions.  To define an anonymous function in Elixir we need the `fn` and `end` keywords.  Within these we can define any number of parameters and function bodies separated by `->`.

기초적인 예제를 보도록 하죠:
Let's look at a basic example:

```elixirre
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### &으로 줄여쓰기
### The & shorthand

엘릭서에서 줄여쓰기할 경우, 익명함수를 쓰는 것은 흔히 보이는 사례입니다:
Using anonymous functions is such a common practice in Elixir there is shorthand for doing so:

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

여러분께서 추측하셨겠듯이, 줄여쓰기를 했을 때 매개변수들은 `&1`, `&2`, `&3`, 등과 같이 다룰 수 있습니다.
As you probably already guessed, in the shorthand version our parameters are available to us as `&1`, `&2`, `&3`, and so on.

## 패턴 매칭
## Pattern matching

엘릭서에서 패턴 매칭은 단순히 변수를 다루는 데서 그치지 않고, 함수의 시그니쳐에서도 적용될 수 있다는 것을 이 섹션에서 확인할 것입니다.
Pattern matching isn't limited to just variables in Elixir, it can be applied to function signatures as we will see in this section.

엘릭서는 ??? 식별하기 위해 패턴 매칭을 사용합니다. 
Elixir uses pattern matching to identify the first set of parameters which match and invokes the corresponding body:

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
iex> handle_result.({:ok, some_result})
Handling result...

iex> handle_result.({:error})
An error has occurred!
```

## 이름이 있는 함수
## Named functions

우리는 차후에 호출할 수 있도록 모듈 내에서 `def` 키워드를 이용하여 함수에 이름을 부여할 수 있습니다. 지금은 이름이 있는 함수를 다루는 것에 집중하도록 하고, 다음 강의에서 모듈에 대해 더 배울 것입니다..
We can define functions with names so we can refer to them later, these named functions are defined with the `def` keyword within a module.  We'll learn more about Modules in the next lessons, for now we'll focus on the named functions alone.

모듈 내에서 정의된 함수는 다른 모듈에서 접근이 가능하며, 이는 엘릭서에서 프로젝트를 구축할때 특히 유용합니다. 
Functions defined within a module are available to other modules for use, this is a particularly useful building block in Elixir:

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

만약 함수의 몸체를 한 줄로 쓰고 싶은 경우, 우리는 `do:`를 이용하여 축약할 수 있습니다.
If our function body only spans one line, we can shorten it further with `do:`:

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

패턴매칭에 대한 지식, 이름있는 함수를 이용하여 재귀를 맛보도록 하죠.
Armed with our knowledge of pattern matching, let's explore recursion using named functions:

```elixir
defmodule Length do
  def of([]), do: 0
  def of([_|t]), do: 1 + of(t)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### 사적(private) 함수
### Private functions

다른 모듈에서 함수에 접근하는 것을 원하지 않는다면, 정의된 모듈 내에서만 호출될 수 있도록 사적(private) 함수를 이용할 수 있습니다. 엘릭서에서는 그것들을 `defd` 키워드를 이용하여 정의할 수 있습니다:
When we don't want other modules accessing a function we can use private functions, which can only be called within their Module.  We can define them in Elixir with `defp`:

```elixir
defmodule Greeter do
  def hello(name), do: phrase <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) undefined function: Greeter.phrase/0
    Greeter.phrase()
```

### 보호자(Guards)
### Guards

[제어 구조](../control-structures.md) 강의에서 guards에 대해 간략하게 다뤘으니, 지금은 이름이 있는 함수에 어떻게 적용할 수 있는지 알아보도록 하겠습니다. 엘릭서에서 함수가 매치되기만 하면, 존재하는 어떤 guards 든지 테스트될 것입니다.
We briefly covered guards in the [Control Structures](../control-structures.md) lesson, now we'll see how we can apply them to named functions.  Once Elixir has matched a function any existing guards will be tested.

다음의 예제예서, 우리는 
In the follow example we have two functions with the same signature, we rely on guards to determine which to use based on the argument's type:

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase <> name
  end

  defp phrase, do: "Hello, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"
```

### 기본(Default) ?????
### Default arguments


If we want a default value for an argument we use the `argument \\ value` syntax:

```elixir
defmodule Greeter do
  def hello(name, country \\ "en") do
    phrase(country) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello("Sean", "en")
"Hello, Sean"

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.hello("Sean", "es")
"Hola, Sean"
```

When we combine our guard example with default arguments, we run into an issue.  Let's see what that might look like:

```elixir
defmodule Greeter do
  def hello(names, country \\ "en") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(country)
  end

  def hello(name, country \\ "en") when is_binary(name) do
    phrase(country) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) def hello/2 has default values and multiple clauses, define a function head with the defaults
```

Elixir doesn't like default arguments in multiple matching functions, it can be  confusing.  To handle this we add a function head with our default arguments:

```elixir
defmodule Greeter do
  def hello(names, country \\ "en")
  def hello(names, country) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(country)
  end

  def hello(name, country) when is_binary(name) do
    phrase(country) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "es"
"Hola, Sean, Steve"
```
