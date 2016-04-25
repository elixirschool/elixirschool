---
layout: page
title: Funkcje
category: basics
order: 7
lang: pl
---

W Elixirze tak, jak w wielu innych językach funkcyjnych, funkcje należą do bytów podstawowych (ang. _first class 
citizen_). W tej lekcji poznamy rodzaje funkcji, różnice pomiędzy nimi oraz zastosowania.

## Spis treści

- [Funkcje anonimowe](#Funkcje-anonimowe)
  - [Znak & jako skrót](#Znak--jako-skrót)
- [Dopasowanie wzorców](#Dopasowanie-wzorców)
- [Funkcje nazwane](#Funkcje-nazwane)
  - [Funkcje prywatne](#Funkcje-prywatne)
  - [Strażnicy](#Strażnicy)
  - [Argumenty domyślne](#Argumenty-domyślne)

## Funkcje anonimowe

Jak sama nazwa wskazuje, funkcje anonimowe nie mają nazw.  W lekcji `Enum` zobaczyliśmy, że funkcje często są 
przekazywane do innych funkcji jako parametry. Jeżeli chcemy zdefiniować funkcję anonimową w Elixirze musimy użyć słów 
kluczowych `fn` i `end`. Funkcja taka może posiadać wiele parametrów, które są oddzielone od jej ciała za pomocą 
znaku `->`.  

Przyjrzyjmy się prostemu przykładowi:

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### Znak & jako skrót

Funkcje anonimowe są tak często wykorzystywane, że istnieje skrócony sposób ich zapisu:

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

Jak można się domyślić, w skróconej formie zapisu argumenty funkcji są dostępne jako `&1`,`&2`, `&3`, itd.

## Dopasowanie wzorców

Dopasowanie wzorców w Elixirze nie jest ograniczone tylko do zmiennych. Może zostać wykorzystane do dopasowania 
funkcji na podstawie listy ich parametrów.

Elixir używa dopasowania wzorców, by odnaleźć pierwszy pasujący zestaw parametrów i wykonać połączony z nim kod:

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

## Funkcje nazwane

Możemy zdefiniować funkcję i nadać jej nazwę, by móc się do niej później odwołać. Robimy to w ramach 
modułu wykorzystując słowo kluczowe `def`. O modułach będziemy jeszcze mówić w kolejnych lekcjach. Teraz skupimy się 
na samych funkcjach. 

Funkcje zdefiniowane w module są też domyślnie dostępne w innych modułach. Jest to szczególnie użyteczna cecha języka.

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

Możemy też zapisać funkcję w jednej linijce, wykorzystując wyrażenie `do:`:

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

Wykorzystując naszą wiedzę o dopasowaniu wzorców, stwórzmy funkcję rekurencyjną:

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

### Funkcje prywatne

Jeżeli nie chcemy, by inne moduły mogły wywołać naszą funkcję, możemy zdefiniować ją jako prywatną. Będzie można ją 
użyć tylko w module, w którym została stworzona.  W Elixirze służy do tego słowo kluczowe `defp`:

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

### Strażnicy

Pokrótce omówiliśmy strażników w lekcji o [strukturach kontrolnych](../control-structures.md), a teraz przyjrzymy 
się bliżej, jak można wykorzystać ich w funkcjach. Elixir odszukując funkcję do wywołania, sprawdza warunki dla 
wszystkich strażników.

W poniższym przykładzie mamy dwie funkcje o takiej samej sygnaturze, ale wywołanie właściwej jest możliwe dzięki 
strażnikom testującym typ argumentu:

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

### Argumenty domyślne

Jeżeli chcemy, by argument miał wartość domyślną, to należy użyć konstrukcji `argument \\ wartość`:

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

Należy uważać, łącząc mechanizmy strażników i domyślnych argumentów, ponieważ może to spowodować błędy kompilacji. 
Zobaczmy co stanie się, gdy połączymy nasze przykłady:

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

Domyślne argumenty nie są preferowane przez Elixira w mechanizmach dopasowania wzorców, ponieważ mogą być mylące. By 
temu zaradzić, możemy dodać dodatkową funkcję:

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
