---
version: 0.9.1
title: Wyjątki i błędy
---

Elixir wspiera obsługę wyjątków. Ta lekcja jest poświęcona mechanizmom do obsługi błędów, wśród których najpopularniejszym jest zwracanie krotki `{:error, reason}`. 

Ogólnie przyjętą w Elixirze zasadą jest tworzenie funkcji (`example/1`) zwracającej `{:ok, result}` albo `{:error, reason}` oraz oddzielnej funkcji (`example!/1`), która zwróci bezpośrednio `result` albo zakończy się wyjątkiem.

W tej lekcji skupimy się na pracy z takim podejściem.

{% include toc.html %}

## Obsługa błędów

Zanim obsłużymy błąd musimy go wywołać. Najprościej jest zrobić to z pomocą `raise/1`:

```elixir
iex> raise "Oh no!"
** (RuntimeError) Oh no!
```

Jeżeli chcemy by miał on konkretny typ i opis, to wywołamy `raise/2`:

```elixir
iex> raise ArgumentError, message: "the argument value is invalid"
** (ArgumentError) the argument value is invalid
```

Jeżeli wiemy, że może pojawić się błąd, to możemy go obsłużyć wykorzystując `try/rescue` i dopasowanie wzorców:

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> end
An error occurred: Oh no!
:ok
```

Możemy obsłużyć wiele wyjątków w pojedynczym bloku `rescue`:

```elixir
try do
  opts
  |> Keyword.fetch!(:source_file)
  |> File.read!()
rescue
  e in KeyError -> IO.puts("missing :source_file option")
  e in File.Error -> IO.puts("unable to read source file")
end
```

## Blok `after`

Czasami musimy podjąć pewne dodatkowe działania po wykonaniu kodu w bloku `try/rescue`, niezależnie czy błąd się pojawił, czy też nie.  Służy do tego konstrukcja `try/after`.  Odpowiada ona konstrukcji `begin/rescue/ensure` w Ruby lub `try/catch/finally` w Javie:

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> after
...>   IO.puts "The end!"
...> end
An error occurred: Oh no!
The end!
:ok
```

Najczęstszym przypadkiem użycia jest zamykanie połączeń i plików:

```elixir
{:ok, file} = File.open("example.json")

try do
  # Do hazardous work
after
  File.close(file)
end
```

## Własne błędy

Elixir zawiera wiele wbudowanych typów błędów jak na przykład `RuntimeError`, ale czasami zachodzi potrzeba stworzenia nowego typu, specyficznego dla naszego projektu.  Stworzenie nowego błędu polega na wykorzystaniu makra  `defexception/1`, które przyjmuje opcję `:message` zawierającą komunikat:

```elixir
defmodule ExampleError do
  defexception message: "an example error has occurred"
end
```

Sprawdźmy jak sprawuje się nasz błąd:

```elixir
iex> try do
...>   raise ExampleError
...> rescue
...>   e in ExampleError -> e
...> end
%ExampleError{message: "an example error has occurred"}
```

## Zwracanie błędów

Innym mechanizmem związanym z błędami w Elixirze jest użycie `throw` i `catch`.  Nie występuje on za często, szczególnie w nowszym kodzie, ale ważne jest, by wiedzieć, że istnieje i jak działa.

Funkcja `throw/1` pozwala na przerwanie wykonania kodu i przekazanie do `catch` pewnej wartości:

```elixir
iex> try do
...>   for x <- 0..10 do
...>     if x == 5, do: throw(x)
...>     IO.puts(x)
...>   end
...> catch
...>   x -> "Caught: #{x}"
...> end
0
1
2
3
4
"Caught: 5"
```

Jak już wspomnieliśmy, `throw/catch` jest rzadko używanym mechanizmem, który zazwyczaj pojawia się jako tymczasowe rozwiązanie tam, gdzie biblioteki nie zapewniają odpowiedniego API .

## Kończenie procesu

W końcu Elixir posiada mechanizm kończenia procesów za pomocą `exit`. Sygnał wyjścia jest wysyłany za każdym razem, kiedy kończy się proces i jest bardzo ważnym elementem związanym z odpornością na błędy.

Możemy też jawnie wywołać `exit/1`:

```elixir
iex> spawn_link fn -> exit("oh no") end
** (EXIT from #PID<0.101.0>) evaluator process exited with reason: "oh no"
```

Możliwe jest użycie `try/catch` do obsłużenia sygnału `exit`, ale takie zachowanie jest _bardzo_ rzadkie. Zazwyczaj obsługą takiego zdarzenia powinien zająć się nadzorca procesów:

```elixir
iex> try do
...>   exit "oh no!"
...> catch
...>   :exit, _ -> "exit blocked"
...> end
"exit blocked"
```
