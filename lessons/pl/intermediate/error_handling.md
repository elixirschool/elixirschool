%{
  version: "1.1.0",
  title: "Obsługa błędów",
  excerpt: """
  Choć bardziej popularnym rozwiązaniem jest zwracanie krotki `{:error, reason}`, Elixir wspiera też wyjątki — i w tej lekcji przyjrzymy się sposobom obsługi błędów i różnym dostępnym mechanizmom do tego służącym.

  Ogólnie przyjętą w Elixirze zasadą jest tworzenie funkcji (`example/1`) zwracającej `{:ok, result}` albo `{:error, reason}` oraz oddzielnej funkcji (`example!/1`), która zwraca bezpośrednio `result` albo wyrzuca wyjątek.

  W tej lekcji skupimy się na tej ostatniej opcji.
  """
}
---

## Ogólne konwencje

W tej chwili społeczność Elixira doszła do kilku konwencji dotyczących zwracania błędów:

* dla błędów będących częścią normalnego działania funkcji (np. gdy użytkownik wpisał zły typ daty), funkcja zwraca `{:ok, result}` (dla poprawnego działania) albo `{:error, reason}` gdy wystąpi taki błąd;
* w przypadku błędów niebędących częścią standardowych operacji (np. kiedy nie jesteśmy w stanie przetworzyć danych konfiguracyjnych), program powinien wyrzucić wyjątek.

Zazwyczaj radzimy sobie ze standardowymi błędami za pomocą [dopasowania wzorców](/pl/lessons/basics/pattern_matching), ale w tej lekcji skupimy się na drugim przypadku — wyjątkach.

W publicznych API często można znaleźć drugą wersję funkcji z wykrzyknikiem w nazwie (example!/1), która zwraca nieopakowany w żadne dodatkowe struktury wynik albo wyrzuca wyjątek.

## Obsługa błędów

Zanim obsłużymy błąd, musimy go wywołać — a najprostsztym sposobem, by to uczynić, jest użycie `raise/1`:

```elixir
iex> raise "Oh no!"
** (RuntimeError) Oh no!
```

Jeżeli chcemy określić konkretny typ i komunikat błędu, powinniśmy użyć `raise/2`:

```elixir
iex> raise ArgumentError, message: "the argument value is invalid"
** (ArgumentError) the argument value is invalid
```

Jeśli wiemy, że może pojawić się błąd, to możemy go obsłużyć wykorzystując `try/rescue` i dopasowanie wzorców:

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

## Blok after

Czasami musimy podjąć pewne dodatkowe działania po wykonaniu kodu w bloku `try/rescue`, niezależnie od tego, czy błąd się pojawił, czy też nie.
Służy do tego konstrukcja `try/after`.
Odpowiada ona `begin/rescue/ensure` w Rubym czy `try/catch/finally` w Javie:

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

Najczęstszym przypadkiem użycia `after` jest zamykanie połączeń i plików:

```elixir
{:ok, file} = File.open("example.json")

try do
  # Wykonuj niebezpieczną pracę
after
  File.close(file)
end
```

## Własne błędy

Elixir zawiera wiele wbudowanych typów błędów, takich jak na przykład `RuntimeError`, niemniej czasami zachodzi potrzeba stworzenia nowego typu, specyficznego dla naszego projektu.
Stworzenie nowego błędu polega na wykorzystaniu makra `defexception/1`, które przyjmuje opcję `:message`, umożliwiającą nam ustawienie domyślnego komunikatu błędu:

```elixir
defmodule ExampleError do
  defexception message: "an example error has occurred"
end
```

Teraz sprawdźmy, jak sprawuje się nasz błąd:

```elixir
iex> try do
...>   raise ExampleError
...> rescue
...>   e in ExampleError -> e
...> end
%ExampleError{message: "an example error has occurred"}
```

## Zwracanie błędów

Innym mechanizmem związanym z błędami w Elixirze jest użycie `throw` i `catch`.
Nie występuje on za często, szczególnie w nowszym elixirowym kodzie, ale ważne jest, by o nim wiedzieć i rozumieć jego działanie.

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

Ostatnim mechanizmem związanym z obsługą błędów dostarczanym nam przez Elixira jest `exit`.
Sygnały wyjścia (`exit`) wysyłane są za każdym razem, kiedy kończy się proces i są bardzo ważną częścią odporności Elixira na błędy.

Możemy też jawnie wywołać `exit/1`:

```elixir
iex> spawn_link fn -> exit("oh no") end
** (EXIT from #PID<0.101.0>) evaluator process exited with reason: "oh no"
```

Możliwe jest użycie `try/catch` do obsłużenia sygnału `exit`, ale takie rozwiązanie jest _wyjątkowo_ rzadkie.
W niemal wszystkich przypadkach najlepiej będzie, jeśli pozwolimy, by obsługą takiego zdarzenia zajął się nadzorca procesów (ang. _supervisor_):

```elixir
iex> try do
...>   exit "oh no!"
...> catch
...>   :exit, _ -> "exit blocked"
...> end
"exit blocked"
```
