---
layout: page
title: Оператор конвейера
category: basics
order: 6
lang: ru
---

Оператор конвейера `|>` передает результат выполнения выражения первым параметром в другое выражение.

## Содержание

- [Вступление](#section-1)
- [Примеры](#section-2)
- [Советы](#section-3)

## Вступление

Разработка может быть хаотичным процессом. Настолько хаотичным, что вызовы функций становятся очень запутанными, и их сложно читать. Например, такое выражение:

```elixir
foo(bar(baz(new_function(other_function()))))
```

Тут передан результат вызова `other_function/1` в `new_function/1`, `new_function/1` в `baz/1`, `baz/1` в `bar/1` и, наконец, результат вызова `bar/1` становится аргументом `foo/1`. Elixir подходит к решению этой проблемы прагматично - добавлением оператора конвейера. Оператор, выглядящий как `|>` *получает результат одного выражения, и передает его дальше*. Давайте еще раз посмотрим на тот же пример, переписанный с использованием этого оператора.

```elixir
other_function() |> new_function() |> baz() |> bar() |> foo()
```

Оператор конвейера получает результат выражения слева и передает его в правую часть.

## Примеры

Для этих примеров мы будем пользоваться функциями из модуля String.

- Разбиение строки на слова

```shell
iex> "Elixir rocks" |> String.split
["Elixir", "rocks"]
```

- Перевод всех слов строки в верхний регистр

```shell
iex> "Elixir rocks" |> String.split |> Enum.map( &String.upcase/1 )
["ELIXIR", "ROCKS"]
```

- Проверка кончается ли строка на "ixir"

```shell
iex> "elixir" |> String.ends_with?("ixir")
true
```

## Советы

Если строка получает больше одного параметра - используйте скобки. Это абсолютно не имеет значения для языка, но важно для других разработчиков, которые могут неправильно понять код. Если взять второй пример и убрать оттуда скобки из вызова `Enum.map/2` -  будет предупреждение:

```shell
iex> "Elixir rocks" |> String.split |> Enum.map &String.upcase/1
iex: warning: you are piping into a function call without parentheses, which may be ambiguous. Please wrap the function you are piping into in parenthesis. For example:

foo 1 |> bar 2 |> baz 3

Should be written as:

foo(1) |> bar(2) |> baz(3)

["ELIXIR", "ROCKS"]
```
