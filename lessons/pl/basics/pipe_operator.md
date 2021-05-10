---
version: 1.0.1
title: Operator potoku
---

Operator potoku `|>` przekazuje wynik jednego wyrażenia jako pierwszy parametr następnego wyrażenia.

{% include toc.html %}

## Wprowadzenie

Programowanie może być chaotyczne.
Tak chaotyczne, że kolejne, zagnieżdżone wywołania funkcji mogą stać się bardzo trudne do śledzenia i zrozumienia.
Weźmy pod uwagę poniższy przykład, przedstawiający zagnieżdżone funkcje:

```elixir
foo(bar(baz(new_function(other_function()))))
```

Najpierw przekazujemy wartość funkcji `other_function/0` do `new_function/1`, następnie `new_function/1` do `baz/1`, z `baz/1` do `bar/1` i ostatecznie wynik funkcji `bar/1` do `foo/1`.
Elixir przyjmuje pragmatyczne podejście do tego składniowego chaosu, dostarczając operator potoku.
Operator ten, `|>`,_przyjmuje wynik jednego wyrażenia i przekazuje go dalej_.
Przyjrzyjmy się wcześniejszemu fragmentowi kodu, przepisanemu z wykorzystaniem operatora potoku:

```elixir
other_function() |> new_function() |> baz() |> bar() |> foo()
```

Operator potoku przejmuje wynik działania funkcji po lewej stronie i przekazuje go do funkcji po prawej stronie.

## Przykłady

W poniższym zestawie przykładów wykorzystamy Elixirowy moduł String.

- Tokenizacja ciągu znaków

```elixir
iex> "Elixir rocks" |> String.split()
["Elixir", "rocks"]
```

- Zamiana na wielkie litery we wszystkich tokenach

```elixir
iex> "Elixir rocks" |> String.upcase() |> String.split()
["ELIXIR", "ROCKS"]
```

- Sprawdzenie zakończenia ciągu znaków

```elixir
iex> "elixir" |> String.ends_with?("ixir")
true
```

## Najlepsze praktyki 

Jeśli liczba argumentów funkcji jest większa niż 1, pamiętaj o korzystaniu z nawiasów.
Nawiasy w Elixirze nie są obowiązkowe, ale ich stosowanie poprawia czytelność kodu, co docenić mogą inni programiści.
Jeżeli z kodu w trzecim przykładzie usuniemy nawiasy z funkcji `Enum.ends_with/2`, zobaczymy poniższe ostrzeżenie:

```elixir
iex> "elixir" |> String.ends_with? "ixir"
warning: parentheses are required when piping into a function call. For example:

  foo 1 |> bar 2 |> baz 3

is ambiguous and should be written as

  foo(1) |> bar(2) |> baz(3)

true
```

