---
layout: page
title: Поточен оператор
category: basics
order: 6
lang: bg
---

Поточният оператор `|>` предава резултата на израз като първи параметър към следващ израз.

{% include toc.html %}

## Въведение

Програмирането може да бъде объркващо. Толкова объркващо, че обръщения към функции могат да бъдат толкова дълбоко вложение, че обръщенията към функции стават много трудни за проследяване. Вземете например следните вградени функции под внимание:

```elixir
foo(bar(baz(new_function(other_function()))))
```

Тук подаваме стойността `other_function/1` към `new_function/1`, а `new_function/1` към `baz/1`, `baz/1` към `bar/1`, и накрая резултата от `bar/1` към `foo/1`. Elixir използва прагматичен подход към този синтактичен хаос като ни предоставя поточния оператор. Поточният оператор, който изглежда като `|>` *взема резултата от един израз и го предава нататък*. Нека разгледаме още веднъж горния фрагмент код, пренаписан с поточния оператор.

```elixir
other_function() |> new_function() |> baz() |> bar() |> foo()
```

Потокът приема резултата от ляво и го подава на дясната страна.

## Примери

За този набор от примери ще използваме модула String на Elixir.

- Разбиване на символи (неопределено)

```shell
iex> "Elixir rocks" |> String.split
["Elixir", "rocks"]
```

- Изпиши всички символи с главни букви

```shell
iex> "Elixir rocks" |> String.split |> Enum.map( &String.upcase/1 )
["ELIXIR", "ROCKS"]
```

- Провери за край на низа

```shell
iex> "elixir" |> String.ends_with?("ixir")
true
```

## Добри практики

Ако арността на функция е повече от 1, то тогава използвайте скоби. Това не е от особено значение за Elixir, но е важно за други програмисти, които може погрешно да разчетат кода ви. Ако използваме вторият ни пример и премахнем скобите от `Enum.map/2`, ни посреща следното предупреждение.

```shell
iex> "Elixir rocks" |> String.split |> Enum.map &String.upcase/1
iex: warning: you are piping into a function call without parentheses, which may be ambiguous. Please wrap the function you are piping into in parenthesis. For example:

foo 1 |> bar 2 |> baz 3

Should be written as:

foo(1) |> bar(2) |> baz(3)

["ELIXIR", "ROCKS"]
```

