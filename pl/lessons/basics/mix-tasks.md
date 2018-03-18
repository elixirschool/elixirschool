---
version: 0.9.1
title: Własne funkcje Mix'a 
---

Tworzenie własnych funkcji Mix'a dla projektów w Elixirze.

{% include toc.html %}

## Wprowadzenie

Nie jest niczym niezwykłym chęć rozszerzenia funkcjonalności aplikacji napisanych w Elixirze. Można to osiągnąć dodając własne funkcje do Mix'a. Zanim zobaczymy jak to zrobić, przyjrzyjmy się jednej z już istniejących:

```shell
$ mix phoenix.new my_phoenix_app

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

Jak możemy zobaczyć wyżej, framework [Phoenix](http://www.phoenixframework.org/) posiada własną funkcję do generowania nowego projektu. A co, jeśli chciałbyś mieć coś podobnego w swoim projekcie? Świetnie się składa, gdyż Elixir daje nam taką możliwość i czyni cały proces bardzo prostym do wykonania.     

## Konfiguracja

Utwórzmy prostą aplikację Mix'a. 

```shell
$ mix new hello

* creating README.md
* creating .gitignore
* creating mix.exs
* creating config
* creating config/config.exs
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

A teraz, w pliku **lib/hello.ex**, który został dla nas wygenerowany, napiszmy funkcję, która wypisze na ekranie "Hello, World!"

```elixir
defmodule Hello do
  @doc """
  Output's `Hello, World!` everytime.
  """
  def say do
    IO.puts("Hello, World!")
  end
end
```

## Własne funkcje Mix'a 

Stwórzmy własną funkcję Mix'a. Najpierw utwórz nowy katalog i plik **hello/lib/mix/tasks/hello.ex**. W tym pliku zamieść poniższy kod:

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Simply runs the Hello.say/0 command."
  def run(_) do
    # calling our Hello.say() function from earlier
    Hello.say()
  end
end
```

Zauważ jak rozpoczynamy tworzenie modułu z użyciem `Mix.Tasks` i nazwą, którą chcemy zawołać z linii komend. W drugiej linii wprowadzamy `use Mix.Task`, co pozwala nam skorzystać z zachowania `Mix.Task` w przestrzeni nazw. Następnie definiujemy funkcję `run`, w której ignorujemy przekazywany argument. W ciele tej funkcji wołamy funkcję `say` z naszego modułu `Hello`. 


## Funkcje Mix'a w akcji

Wypróbujmy naszą nową funkcję Mix'a. Dopóki jesteśmy katalogu głównym naszego projektu wszystko powinno działać. Z linii komend wywołaj `mix hello`. Powinieneś zobaczyć: 

```shell
$ mix hello
Hello, World!
```

Mix jest bardzo przyjazny w użyciu i podpowiada nam właściwe komendy w przypadku zrobienia literówki:

```shell
$ mix hell
** (Mix) The task "hell" could not be found. Did you mean "hello"?
```

Zwróciłeś uwagę, że wykorzystaliśmy nowy atrybut modułu, `@shortdoc`? Jest on bardzo pomocny przy dystrybuowaniu aplikacji, szczególnie, gdy użytkownik skorzysta z komendy `mix help` w konsoli.

```shell
$ mix help

mix app.start         # Starts all registered apps
...
mix hello             # Simply calls the Hello.say/0 function.
...
```
