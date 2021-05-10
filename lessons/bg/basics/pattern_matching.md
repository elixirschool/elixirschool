---
version: 0.9.0
title: Съпоставка с образец
---

Съпоставката с образец (pattern matching) е мощна част от Elixir, тя ни позволчва да съпоставяме прости стойности, структури от даннии дори функции.  В този урок ще започнем да разбираме как съпоставянето с образец се използва.

{% include toc.html %}

## Оператор за съпоставка

Готови ли сте за ниска топка?  При Elixir, операторът `=` е всъщност нашият оператор за съпоставяне.  Чрез оператора за съпоставка можем да присвояваме и след това съпоставяме стойности, нека видим:

```elixir
iex> x = 1
1
```

А сега нека пробваме някои прости съпоставки с образец:

```elixir
iex> 1 = x
1
iex> 2 = x
** (MatchError) no match of right hand side value: 1
```

Нека опитаме същото с някои от познатите ни колекции:

```elixir
# Списъци
iex> list = [1, 2, 3]
[1, 2, 3]
iex> [1, 2, 3] = list
[1, 2, 3]
iex> [] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

iex> [1 | tail] = list
[1, 2, 3]
iex> tail
[2, 3]
iex> [2|_] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

# Tuples
iex> {:ok, value} = {:ok, "Successful!"}
{:ok, "Successful!"}
iex> value
"Successful!"
iex> {:ok, value} = {:error}
** (MatchError) no match of right hand side value: {:error}
```

## Оператор за забождане

Тъкмо научихме, че оператора за съпоставяне изпълнява присвояването когато лявата страна на съпоставката съдържа променлива.  В някой случаи това поведение, повторно присвояване на променлива, е нежелателно.  За такива случаи имаме оператора за 'забождане': `^`.

Когато забодем променлива, ние съпоставяме върху съществуващата стойност, а не присвояваме нова такава към променливата.  Нека видим как действа това:

```elixir
iex> x = 1
1
iex> ^x = 2
** (MatchError) no match of right hand side value: 2
iex> {x, ^x} = {2, 1}
{2, 1}
iex> x
2
```

Elixir 1.2 добави поддръжка за забождане в ключове на асоциативни листи и клаузи на функции:

```elixir
iex> key = "hello"
"hello"
iex> %{^key => value} = %{"hello" => "world"}
%{"hello" => "world"}
iex> value
"world"
iex> %{^key => value} = %{:hello => "world"}
** (MatchError) no match of right hand side value: %{hello: "world"}
```

Пример за забождане в клауза на функция:

```elixir
iex> greeting = "Hello"
"Hello"
iex> greet = fn
...>   (^greeting, name) -> "Hi #{name}"
...>   (greeting, name) -> "#{greeting}, #{name}"
...> end
#Function<12.54118792/2 in :erl_eval.expr/5>
iex> greet.("Hello", "Sean")
"Hi Sean"
iex> greet.("Mornin'", "Sean")
"Mornin', Sean"
```
