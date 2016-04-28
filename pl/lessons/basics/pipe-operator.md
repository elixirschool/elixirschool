---
layout: page
title: Operator Potoku
category: basics
order: 6 
lang: pl
---

Operator potoku `|>` przekazuje wynik jednego wyrażenia jako pierwszy parametr następnego wyrażenia.

## Spis treści

- [Wprowadzenie](#wprowadzenie)
- [Przykłady](#przyklady)
- [Najlepsze praktyki](#najlepsze-praktyki)

## Wprowadzenie

Programowanie może być chaotyczne. Tak chaotyczne, że kolejne, zagnieżdżone wywołania funkcji mogą stać się bardzo trudne do śledzenia i zrozumienia. Weźmy pod uwagę poniższy przykład, przedstawiający zagnieżdżone funkcje:

```elixir
foo(bar(baz(new_function(other_function()))))
```

Najpierw przekazujemy wartość funkcji `other_function/1` do `new_function/1`, następnie `new_function/1` do `baz/1`, z `baz/1` do `bar/1`, i ostatecznie wynik funkcji `bar/1` do `foo/1`. Elixir przyjmuje pragmatyczne podejście do tego składniowego chaosu, dostarczając operator potoku. Operator ten, `|>`, *przyjmuje wynik jednego wyrażenia i przekazuje go dalej*. Przyjrzyjmy się wcześniejszemu fragmentowi kodu, przepisanemu z wykorzystaniem operatora potoku:

```elixir
other_function() |> new_function() |> baz() |> bar() |> foo()
```

Operator potoku przejmuje wynik działania funkcji po lewej stronie i przekazuje go do funkcji po prawej stronie.

## Przykłady

W poniższym zestawie przykładów wykorzystamy Elixirowy moduł String.

- Tokenizacja ciągu znaków

```shell
iex> "Elixir rocks" |> String.split
["Elixir", "rocks"]
```

- Zamiana na wielkie litery we wszystkich tokenach

```shell
iex> "Elixir rocks" |> String.split |> Enum.map( &String.upcase/1 )
["ELIXIR", "ROCKS"]
```

- Sprawdzenie zakończenia ciągu znaków

```shell
iex> "elixir" |> String.ends_with?("ixir")
true
```

## Najlepsze praktyki 

Jesli liczba argumentów funkcji jest większa niż 1, pamietaj o korzystaniu z nawiasów. Nawiasy w Elixierze nie są obowiązkowe, ale ich stosowanie poprawia czytelność kodu, co docenić mogą inni programiści. Jeśli z kodu, w przykładzie drugim, usuniemy nawiasy z funkcji `Enum.map/2`, zobaczymy poniższe ostrzeżenie.

```shell
iex> "Elixir rocks" |> String.split |> Enum.map &String.upcase/1
iex: warning: you are piping into a function call without parentheses, which may be ambiguous. Please wrap the function you are piping into in parenthesis. For example:

foo 1 |> bar 2 |> baz 3

Should be written as:

foo(1) |> bar(2) |> baz(3)

["ELIXIR", "ROCKS"]
```

