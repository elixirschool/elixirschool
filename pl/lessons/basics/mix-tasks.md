---
version: 1.2.0
title: Własne funkcje Mixa
---

Tworzenie własnych funkcji Mixa dla projektów w Elixirze.

{% include toc.html %}

## Wprowadzenie

Nie jest niczym niezwykłym chęć rozszerzenia funkcjonalności aplikacji napisanych w Elixirze poprzez dodanie własnych funkcji Mixa.
Zanim zobaczymy jak to zrobić, przyjrzyjmy się jednej z już istniejących:

```shell
$ mix phx.new my_phoenix_app

* creating my_phoenix_app/config/config.exs
* creating my_phoenix_app/config/dev.exs
* creating my_phoenix_app/config/prod.exs
* creating my_phoenix_app/config/prod.secret.exs
* creating my_phoenix_app/config/test.exs
* creating my_phoenix_app/lib/my_phoenix_app.ex
* creating my_phoenix_app/lib/my_phoenix_app/endpoint.ex
* creating my_phoenix_app/test/views/error_view_test.exs
...
```

Jak możemy zobaczyć wyżej, framework [Phoenix](http://www.phoenixframework.org/) posiada własną funkcję do generowania nowego projektu.
A co, jeśli chciałbyś mieć coś podobnego w swoim projekcie? Nie ma problemu — Elixir daje nam taką możliwość i czyni cały proces bardzo prostym do wykonania.

## Konfiguracja

Utwórzmy prostą aplikację Mixa.

```shell
$ mix new hello

* creating README.md
* creating .formatter.exs
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/hello.ex
* creating test
* creating test/test_helper.exs
* creating test/hello_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

cd hello
mix test

Run "mix help" for more commands.
```

A teraz, w pliku **lib/hello.ex**, który został dla nas wygenerowany, napiszmy funkcję, która wypisze na ekranie "Hello, World!".

```elixir
defmodule Hello do
  @doc """
  Wypisuje `Hello, World!`.
  """
  def say do
    IO.puts("Hello, World!")
  end
end
```

## Własne funkcje Mixa

Stwórzmy własną funkcję Mixa.
Najpierw utwórz nowy katalog i plik **hello/lib/mix/tasks/hello.ex**.
W tym pliku zamieść poniższy kod:

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Wywołuje funkcję Hello.say/0."
  def run(_) do
    # Wywołanie funkcji Hello.say(), którą wcześniej napisaliśmy
    Hello.say()
  end
end
```

Zwróć uwagę na instrukcję `defmodule` — nazwę, której chcemy używać w wierszu poleceń, poprzedamy prefiksem `Mix.Tasks`.
W drugiej linii wprowadzamy `use Mix.Task`, co pozwala nam skorzystać z zachowania `Mix.Task` w przestrzeni nazw.
Następnie definiujemy funkcję `run`, w której ignorujemy przekazywany argument.
W ciele tej funkcji wołamy funkcję `say` z naszego modułu `Hello`.

## Ładowanie aplikacji

Mix nie uruchamia automatycznie naszej aplikacji ani żadnych jej zależności, co jest w porządku w większości przypadków użycia funkcji Mixa. Co jednak, jeśli potrzebujemy użyć Ecto i pracować z bazą danych? W tym przypadku powinniśmy się upewnić, że aplikacja stojąca za Ecto.Repo została uruchomiona. Są dwa sposoby, by to osiągnąć: możemy bezpośrednio uruchomić tę aplikację lub uruchomić nasz program, który z kolei uruchomi pozostałe.

Spójrzmy, jak możemy zmienić napisaną przez nas funkcję Mixa tak, by uruchomiła naszą aplikację i jej zależności:

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Wywołuje funkcję Hello.say/0."
  def run(_) do
    # To polecenie uruchomi naszą aplikację
    Mix.Task.run("app.start")

    Hello.say()
  end
end
```

## Funkcje Mixa w akcji

Wypróbujmy naszą nową funkcję Mixa.
Dopóki jesteśmy katalogu głównym naszego projektu, wszystko powinno działać.
Z wiersza poleceń wywołajmy komendę `mix hello`, powinniśmy zobaczyć:

```shell
$ mix hello
Hello, World!
```

Mix jest bardzo przyjazny w użyciu.
Wie, że każdy może popełnić literówkę, więc używa techniki zwanej dopasowaniem rozmytym (ang. _fuzzy string matching_), by w takim przypadku podpowiedzieć nam właściwą komendę:

```shell
$ mix hell
** (Mix) The task "hell" could not be found. Did you mean "hello"?
```

Zwróciłeś uwagę, że wykorzystaliśmy nowy atrybut modułu, `@shortdoc`? Jest on bardzo pomocny przy dystrybuowaniu aplikacji, szczególnie gdy użytkownik skorzysta z komendy `mix help` w konsoli.

```shell
$ mix help

mix app.start         # Starts all registered apps
...
mix hello             # Simply calls the Hello.say/0 function.
...
```

Uwaga: Nasz kod musi być skompilowany, zanim nowe funkcje pojawią się w informacji zwracanej przez `mix help`.
Możemy to zrobić zarówno używając wprost polecenia `mix compile`, jak i wywołując naszą funkcję, tak jak zrobiliśmy to z `mix hello`, co uruchomi dla nas proces kompilacji.
