---
layout: page
title: Mnesia
category: specifics
order: 5
lang: pl
---

Mnesia to rozwiązanie „wagi ciężkiej” do zarządzania w czasie rzeczywistym rozproszonymi bazami danych.

{% include toc.html %}

## Wstęp

Mnesia to system zarządzania bazą danych (ang. _Database Management System_ – DBMS) dostarczany razem ze środowiskiem Erlanga, który możemy oczywiście wykorzystać w Elixirze. Mnesia ma *relacyjno-obiektowy, hybrydowy model danych* co czyni ją odpowiednim narzędziem do tworzenia rozproszonych aplikacji w dowolnej skali.

## Kiedy używać

Kiedy powinniśmy użyć konkretnej technologi? To często bardzo kłopotliwe pytanie. Jeżeli odpowiedź na jedno z poniższych pytań brzmi „tak”, to znak, że warto zastanowić się nad użyciem Mnesii zamiast ETS lub DETS.

  - Czy potrzebujesz mieć możliwość wycofania transakcji?
  - Czy potrzebujesz prostej w użyciu składni do odczytu i zapisu danych?
  - Czy potrzebujesz przechowywać dane w wielu miejscach (węzłach) zamiast w jednym?
  - Czy chcesz mieć możliwość określenia gdzie, dysk lub RAM, dane będą przechowywane?

## Schemat

Ponieważ Mnesia jest częścią Erlanga, a nie Elixira, to odwołujemy się do niej z użyciem dwukropka (patrz: [Współpraca z Erlangiem](https://elixirschool.com/pl/lessons/advanced/erlang/)):

```shell

iex> :mnesia.create_schema([node()])

# jeżeli jednak preferujesz Elixira...

iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])

```

W tej lekcji skupimy się na pracy z API Mnesii. `Mnesia.create_schema/1` tworzy nowy, pusty schemat i umieszcza go w liście węzłów. W naszym przypadku węzłem jest aktualna sesja IEx.

## Węzły

Gdy uruchamiamy `Mnesia.create_schema([node()])` poprzez IEx, powinniśmy zobaczyć folder **Mnesia.nonode@nohost**, lub podobny, w aktualnym katalogu. Możesz się zastanawiać, co oznacza katalog **nonode@nohost**, bo dotychczas się z nim nie spotkaliśmy. Zobaczmy zatem.

```shell
$ iex --help
Usage: iex [options] [.exs file] [data]

  -v                Prints version
  -e "command"      Evaluates the given command (*)
  -r "file"         Requires the given files/patterns (*)
  -S "script"       Finds and executes the given script
  -pr "file"        Requires the given files/patterns in parallel (*)
  -pa "path"        Prepends the given path to Erlang code path (*)
  -pz "path"        Appends the given path to Erlang code path (*)
  --app "app"       Start the given app and its dependencies (*)
  --erl "switches"  Switches to be passed down to Erlang (*)
  --name "name"     Makes and assigns a name to the distributed node
  --sname "name"    Makes and assigns a short name to the distributed node
  --cookie "cookie" Sets a cookie for this distributed node
  --hidden          Makes a hidden node
  --werl            Uses Erlang's Windows shell GUI (Windows only)
  --detached        Starts the Erlang VM detached from console
  --remsh "name"    Connects to a node using a remote shell
  --dot-iex "path"  Overrides default .iex.exs file and uses path instead;
                    path can be empty, then no file will be loaded

** Options marked with (*) can be given more than once
** Options given after the .exs file or -- are passed down to the executed code
** Options can be passed to the VM using ELIXIR_ERL_OPTIONS or --erl
```

Kiedy wywołamy `--help` w IEx otrzymamy listę wszystkich możliwych opcji. Na liście są `--name` i `--sname` służące do konfigurowania informacji o węzłach. Węzeł to nic innego jak instancja maszyny wirtualnej Erlanga, która we własnym zakresie zarządza komunikacją, GC, zadaniami, pamięcią itd. Nazwa węzła **nonode@nohost** jest domyślną.

```shell
$ iex --name learner@elixirschool.com

Erlang/OTP 18 [erts-7.2.1] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex(learner@elixirschool.com)> Node.self
:"learner@elixirschool.com"
```

Jak widzimy, uruchomiony przez nas węzeł nazywa się`:"learner@elixirschool.com"`. Jeżeli po raz kolejny wywołamy `Mnesia.create_schema([node()])`, to zobaczymy nowy folder o nazwie **Mnesia.learner@elixirschool.com**. Dzieje się to z prostej przyczyny. Węzły w Erlangu są używane do komunikacji pomiędzy maszynami wirtualnymi i współdzielenia (rozpraszania) informacji i zasobów. komunikacja ta nie jest ograniczona do jednej maszyny fizycznej (systemu operacyjnego), ale można komunikować się przez LAN lub internet.

## Uruchamianie Mnesii

Mamy już podstawową wiedzę i jesteśmy na dobrej drodze do uruchomienia bazy danych, uruchommy zatem Mnesia DBMS za pomocą polecenia `Mnesia.start/0`.

```shell
iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node])
:ok
iex> Mnesia.start()
:ok
```

Musimy pamiętać, że jak pracujemy z systemem rozproszonym na dwóch lub więcej węzłach, to funkcja `Mnesia.start/1` musi byc wywołana na każdym z nich.

## Tworzenie tabel

Do tworzenia tabel w naszej bazie służy funkcja `Mnesia.create_table/2`. Poniżej tworzymy tabelę `Person` i przekazujemy listę asocjacyjną opisującą jej schemat.

```shell
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:atomic, :ok}
```

Kolumny definiujemy za pomocą atomów `:id`, `:name` i `:job`. Kiedy wywołamy `Mnesia.create_table/2`, otrzymamy jedną z poniższych odpowiedzi:

 - `{atomic, ok}` – jeżeli wszystko się udało,
 - `{aborted, Reason}` – jeżeli funkcja napotkała błąd.

## „Niekoszerne” podejście 

Na początek rzućmy okiem na „nie koszerne” podejście do odczytu i zapisu danych do tabel. Zasadniczo powinno być ono unikane, ponieważ nie gwarantuje sukcesu operacji, ale pomoże nam w nauce i zapewni komfort w pracy z Mnesią. Dodajmy trochę danych do tabeli **Person**.

```shell
iex> Mnesia.dirty_write({Person, 1, "Seymour Skinner", "Principal"})
:ok

iex> Mnesia.dirty_write({Person, 2, "Homer Simpson", "Safety Inspector"})
:ok

iex> Mnesia.dirty_write({Person, 3, "Moe Szyslak", "Bartender"})
:ok
```

...i odczytajmy je z użyciem `Mnesia.dirty_read/1`:

```shell
iex> Mnesia.dirty_read({Person, 1})
[{Person, 1, "Seymour Skinner", "Principal"}]

iex> Mnesia.dirty_read({Person, 2})
[{Person, 2, "Homer Simpson", "Safety Inspector"}]

iex> Mnesia.dirty_read({Person, 3})
[{Person, 3, "Moe Szyslak", "Bartender"}]

iex> Mnesia.dirty_read({Person, 4})
[]
```

Jeżeli spróbujemy pobrać nieistniejący rekord, Mnesia zwróci pustą listę.

## Transakcje

Tradycyjnie używamy **transakcji** do odizolowania odczytów i zapisów do bazy. Transakcje są bardzo istotnym elementem przy projektowaniu odpornych na błędy i silnie rozproszonych systemów. Dla Mnesii *transakcja jest mechanizmem pozwalającym na uruchomienie wielu operacji na danych w ramach jednego bloku funkcyjnego*. Najpierw stwórzmy anonimową funkcję, w tym przypadku `data_to_write` i przekażmy ją do `Mnesia.transaction`.

```shell
iex> data_to_write = fn ->
...>   Mnesia.write({Person, 4, "Marge Simpson", "home maker"})
...>   Mnesia.write({Person, 5, "Hans Moleman", "unknown"})
...>   Mnesia.write({Person, 6, "Monty Burns", "Businessman"})
...>   Mnesia.write({Person, 7, "Waylon Smithers", "Executive assistant"})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_write)
{:atomic, :ok}
```
Bazując na informacji zwrotnej, możemy z satysfakcją stwierdzić, że zapisaliśmy dane do tabeli `Person`. Teraz użyjmy transakcji do odczytu danych. W tym celu użyjemy `Mnesia.read/1`, ale tak jak poprzednio w anonimowej funkcji.

```shell
iex> data_to_read = fn ->
...>   Mnesia.read({Person, 6})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_read)
{:atomic, [{Person, 6, "Monty Burns", "Businessman"}]}
```
