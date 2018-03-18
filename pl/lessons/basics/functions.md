---
version: 0.9.1
title: Funkcje
---

W Elixirze, tak jak w wielu innych językach funkcyjnych, funkcje należą do bytów podstawowych (ang. _first class citizen_). W tej lekcji poznamy rodzaje funkcji, różnice pomiędzy nimi oraz zastosowania.

{% include toc.html %}

## Funkcje anonimowe

Jak sama nazwa wskazuje, funkcje anonimowe nie mają nazw.  W lekcji `Enum` zobaczyliśmy, że funkcje często są przekazywane do innych funkcji jako parametry. Jeżeli chcemy zdefiniować funkcję anonimową w Elixirze musimy użyć słów kluczowych `fn` i `end`. Funkcja taka może posiadać wiele parametrów, które są oddzielone od jej ciała za pomocą znaku `->`.  

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

Dopasowanie wzorców w Elixirze nie jest ograniczone tylko do zmiennych. Może zostać wykorzystane do dopasowania funkcji na podstawie listy ich parametrów.

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

Możemy zdefiniować funkcję i nadać jej nazwę, by móc się do niej później odwołać. Robimy to w ramach modułu wykorzystując słowo kluczowe `def`. O modułach będziemy jeszcze mówić w kolejnych lekcjach. Teraz skupimy się na samych funkcjach. 

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
  def of([_ | tail]), do: 1 + of(tail)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### Nazywanie i arność funkcji

Jak już wspominaliśmy wcześniej pełna nazwa funkcji jest kombinacją jej nazwy i arności (liczby argumentów). Można to rozumieć w nastepujacy sposób:

```elixir
defmodule Greeter2 do
  def hello(), do: "Hello, anonymous person!"   # hello/0
  def hello(name), do: "Hello, " <> name        # hello/1
  def hello(name1, name2), do: "Hello, #{name1} and #{name2}"
                                                # hello/2
end

iex> Greeter2.hello()
"Hello, anonymous person!"
iex> Greeter2.hello("Fred")
"Hello, Fred"
iex> Greeter2.hello("Fred", "Jane")
"Hello, Fred and Jane"
```

Wypisaliśmy pełne nazwy funkcji w komentarzach powyżej. Pierwsza z nie przyjmuje żadnego argumentu, zatem jest nazwana `hello/0`, druga przyjmuje jeden argument zatem nazwa to `hello/1` i tak dalej. Nie należy mylić tego z przeciążaniem funkcji w innych językach. Każda z tych funkcji jest _niezależna_ od innych. Dopasowanie wzorców, o którym przed chwilą mówiliśmy, zostanie zastosowane jedynie wtedy, gdy mamy wiele definicji funkcji o takich samych nazwach i liczbie argumentów.    

### Funkcje prywatne

Jeżeli nie chcemy, by inne moduły mogły wywołać naszą funkcję, możemy zdefiniować ją jako prywatną. Będzie można ją użyć tylko w module, w którym została stworzona.  W Elixirze służy do tego słowo kluczowe `defp`:

```elixir
defmodule Greeter do
  def hello(name), do: phrase <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### Strażnicy

Pokrótce omówiliśmy strażników w lekcji o [strukturach kontrolnych](../control-structures), a teraz przyjrzymy się bliżej, jak można wykorzystać ich w funkcjach. Elixir odszukując funkcję do wywołania, sprawdza warunki dla wszystkich strażników.

W poniższym przykładzie mamy dwie funkcje o takiej samej sygnaturze, ale wywołanie właściwej jest możliwe dzięki strażnikom testującym typ argumentu:

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase() <> name
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
  def hello(name, language_code \\ "en") do
    phrase(language_code) <> name
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

Należy uważać, łącząc mechanizmy strażników i domyślnych argumentów, ponieważ może to spowodować błędy kompilacji. Zobaczmy co stanie się, gdy połączymy nasze przykłady:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code \\ "en") when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) iex:31: definitions with multiple clauses and default values require a header. Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b) do ... end

one should write:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end

def hello/2 has multiple clauses and defines defaults in one or more clauses
    iex:31: (module)
```

Domyślne argumenty nie są preferowane przez Elixira w mechanizmach dopasowania wzorców, ponieważ mogą być mylące. By temu zaradzić, możemy dodać dodatkową funkcję:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en")

  def hello(names, language_code) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code) when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "es"
"Hola, Sean, Steve"
```
