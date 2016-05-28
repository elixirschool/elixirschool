---
layout: page
title: Erlang Term Storage (ETS)
category: specifics
order: 4
lang: pl
---

Erlang Term Storage, zwany ETS, jest potężnym mechanizmem składowania danych zbudowanym z użyciem OTP i gotowym do użycia w Elixirze. W tej lekcji przyjrzymy się jak możemy użyć ETS w naszej aplikacji.  
 
{% include toc.html %}

## Informacje wstępne

ETS jest rozwiązaniem bazującym na pamięci operacyjnej, które pozwala na składowanie obiektów Elixirowych i Erlangowych. ETS został zaprojektowany, by obsługiwać nawet duże zbiory danych ze stałym czasem dostępu.

Tabele ETS są tworzone i obsługiwane przez procesy. Kiedy proces zarządzający tabelą kończy się, to tabela jest usuwana.  Domyślnie istnieje ograniczenie do 1400 tabel na węzeł.

## Tworzenie tabel

Do tworzenia tabel służy funkcja `new/2`, która jako parametry przyjmuje nazwę tabeli i zbiór opcji, a zwraca identyfikator tabeli, którego możemy używać w operacjach.

Przykładowo stwórzmy tabelę do składowania i wyszukiwania użytkowników po nicku:

```elixir
iex> table = :ets.new(:user_lookup, [:set, :protected])
8212
```

Podobnie jak w GenServers, ETS umożliwia odwołanie się do tabeli po nazwie, a ne tylko identyfikatorze. By to zrobić, musimy dodać opcję `:named_table`. I teraz możemy odwołać się d naszej tabeli bezpośrednio po nazwie:

```elixir
iex> :ets.new(:user_lookup, [:set, :protected, :named_table])
:user_lookup
```

### Typy tabel

W ETS wyróżniamy cztery typy tabel:

+ `set` — Jest to typ domyślny. Jedna wartość na klucz. Klucze są unikalne.
+ `ordered_set` — Podobny do `set`, ale klucze są posortowanie w rozumieniu Erlanga/Elixira. Warto pamiętać, że klucze są inaczej porównywane w ramach `ordered_set`.  Przy czym zasada nierówności kluczy jest spójna. Przykładowo 1 i 1.0 są traktowane jako równe.
+ `bag` — Wiele wartości w kluczu, ale wartości te muszą być unikalne.
+ `duplicate_bag` — Wiele wartości w kluczu. Wartości mogą się powtarzać.

### Kontrola dostępu

Zasady dostępy w ETS są zbliżone do tych dla modułów:

+ `public` — Odczyt i zapis dla wszystkich procesów.
+ `protected` — Odczyt dla wszystkich procesów. Zapis tylko dla procesu zarządzającego. Jest to wartość domyślna.
+ `private` — Odczyt i zapis tylko dla procesu zarządzającego.

## Wstawianie informacji

ETS nie posiada schematu. Jedyne ograniczenie polega na tym, że dane są składowane jako krotki, w których pierwsza wartość to klucz. By dodać rekord, należy użyć funkcji `insert/2`:

```elixir
iex> :ets.insert(:user_lookup, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
true
```

Gdy użyjemy `insert/2` z`set` lub `ordered_set` istniejaca wartość zostanie zastąpiona. By temu zapobiec, należy użyć funkcji `insert_new/2`, która zwróci `false`, jeżeli klucz istnieje:

```elixir
iex> :ets.insert_new(:user_lookup, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
false
iex> :ets.insert_new(:user_lookup, {"3100", "", ["Elixir", "Ruby", "JavaScript"]})
true
```

## Wyszukiwanie informacji

ETS posiada kilka wygodnych i elastycznych sposobów na wyszukiwanie danych. Przyjrzyjmy się jak pobierać dane po kluczu i z użyciem różnych form dopasowania wzorców.

Najbardziej wydajną, idealną wręcz, metodą wyszukiwania danych jest użycie klucza. Wyszukiwania bazujące na dopasowanie, choć są wygodne, powinny być używane rozsądnie, ponieważ rzutują na wydajność, szczególnie przy dużych zbiorach danych.

### Wyszukiwanie po kluczu

Mając klucz, możemy użyć funkcji `lookup/2`, by wyszukać wszystkie rekordy przypisane do tego klucza:

```elixir
iex> :ets.lookup(:user_lookup, "doomspork")
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

### Proste porównania

ETS został zaprojektowany dla Erlanga, więc pamiętaj iż porównywanie zmiennych może wyglądać _trochę niezdarnie_.

By wskazać, które zmienne będziemy porównywać, używamy atomów `:"$1"`, `:"$2"`, `:"$3"`, itd. Numer zmiennej odwołuje się do pozycji w wyniku, a nie pozycji w porównaniu. Jeżeli nie jesteśmy zainteresowaniu jakąś wartością, to używamy zmiennej `:"_"`.

Wartości też mogą zostać użyte w dopasowaniu, ale tylko zmienne zostaną zwrócone jako część wyniku. Złóżmy to wszystko razem i zobaczmy, jak działa:

```elixir
iex> :ets.match(:user_lookup, {:"$1", "Sean", :"_"})
[["doomspork"]]
```

Przyjrzyjmy się jeszcze jednemu przykładowi, by zrozumieć wpływ zmiennych na kolejność rezultatów:

```elixir
iex> :ets.match(:user_lookup, {:"$99", :"$1", :"$3"})
[["Sean", ["Elixir", "Ruby", "Java"], "doomspork"],
 ["", ["Elixir", "Ruby", "JavaScript"], "3100"]]
```

A co, jeżeli chcemy otrzymać oryginalny obiekt, a nie listę? Możemy użyć funkcji `match_object/2`, która zwróci cały obiekt bez patrzenia na zmienne:

```elixir
iex> :ets.match_object(:user_lookup, {:"$1", :"_", :"$3"})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]

iex> :ets.match_object(:user_lookup, {:"_", "Sean", :"_"})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```
### Zaawansowane wyszukiwanie

Wiemy już, jak wygląda proste wyszukiwanie, ale co jeżeli chcielibyśmy mieć coś w rodzaju SQL? Na całe szczęście mamy do dyspozycji elastyczniejsze rozwiązanie. Do przeszukiwania danych możemy użyć funkcji `select/2`, przyjmującej jako argument listę trójelementowych krotek. Krotki te reprezentują wzorzec, zero lub więcej strażników oraz format odpowiedzi.

Zmienne użyte w dopasowaniu oraz dwie nowe `:"$$"` i `:"$_"`, mogą być użyte do sformatowania wyniku. Te nowe zmienne są skróconym zapisem do formatowania wyniku; `:"$$"` zwraca wynik jako listę, a `:"$_"` zwróci oryginalny obiekt.

Zmieńmy nasz poprzedni przykład z `match/2` tak, by użyć `select/2`:

```elixir
iex> :ets.match_object(:user_lookup, {:"$1", :"_", :"$3"})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]

{% raw %}iex> :ets.select(:user_lookup, [{{:"$1", :"_", :"$3"}, [], [:"$_"]}]){% endraw %}
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"spork", 30, ["ruby", "elixir"]}]
```

Pomimo że `select/2` pozwala na precyzyjniejszą kontrolę rezultatów, to składnia tej funkcji jest nieprzyjazna szczególnie w złożonych przypadkach. Do ich obsługi ETS zawiera funkcję `fun2ms/1`, która zmienia funkcję w specyfikację zwaną `match_specs`.  Z pomocą`fun2ms/1` możemy tworzyć zapytania, używając lepiej nam znanej składni funkcyjnej. 

Połączmy zatem`fun2ms/2` i `select/2`, by odszukać wszystkie `usernames` z dwoma lub więcej językami:

```elixir
iex> fun = :ets.fun2ms(fn {username, _, langs} when length(langs) > 2 -> username end)
{% raw %}[{{:"$1", :"_", :"$2"}, [{:>, {:length, :"$2"}, 2}], [:"$1"]}]{% endraw %}

iex> :ets.select(:user_lookup, fun)
["doomspork", "3100"]
```

Chcesz dowiedzieć się więcej o specyfikacji dopasowań? Zapoznaj się z oficjalną, erlngową, dokumentacją w języku angielskim [match_spec](http://www.erlang.org/doc/apps/erts/match_spec.html).

## Usuwanie danych

### Usuwanie rekordów 

Deleting terms is as straightforward as `insert/2` and `lookup/2`.  With `delete/2` we only need our table and the key.  This deletes both the key and its values:

```elixir
iex> :ets.delete(:user_lookup, "doomspork")
true
```

### Usuwanie tabel

ETS tables are not garbage collected unless the parent is terminated.  Sometimes it may be necessary to delete an entire table without terminating the owner process.  For this we can use `delete/1`:

```elixir
iex> :ets.delete(:user_lookup)
true
```

## Przykładowe użycie ETS

Given what we've learned above, let's put everything together and build a simple cache for expensive operations.  We'll implement a `get/4` function to take a module, function, arguments, and options.  For now the only option we'll worry about is `:ttl`.

For this example we're assuming the ETS table has been created as part of another process, such as a supervisor:

```elixir
defmodule SimpleCache do
  @moduledoc """
  A simple ETS based cache for expensive function calls.
  """

  @doc """
  Retrieve a cached value or apply the given function caching and returning
  the result.
  """
  def get(mod, fun, args, opts \\ []) do
    case lookup(mod, fun, args) do
      nil ->
        ttl = Keyword.get(opts, :ttl, 3600)
        cache_apply(mod, fun, args, ttl)
      result -> result
    end
  end

  @doc """
  Lookup a cached result and check the freshness
  """
  defp lookup(mod, fun, args) do
    case :ets.lookup(:simple_cache, [mod, fun, args]) do
      [result|_] -> check_freshness(result)
      [] -> nil
    end
  end

  @doc """
  Compare the result expiration against the current system time.
  """
  defp check_freshness({mfa, result, expiration}) do
    cond do
      expiration > :os.system_time(:seconds) -> result
      :else -> nil
    end
  end

  @doc """
  Apply the function, calculate expiration, and cache the result.
  """
  defp cache_apply(mod, fun, args, ttl) do
    result = apply(mod, fun, args)
    expiration = :os.system_time(:seconds) + ttl
    :ets.insert(:simple_cache, {[mod, fun, args], result, expiration})
    result
  end
end
```

To demonstrate the cache we'll use a function that returns the system time and a TTL of 10 seconds.  As you'll see in the example below, we get the cached result until the value has expired:

```elixir
defmodule ExampleApp do
  def test do
    :os.system_time(:seconds)
  end
end

iex> :ets.new(:simple_cache, [:named_table])
:simple_cache
iex> ExampleApp.test
1451089115
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089119
iex> ExampleApp.test
1451089123
iex> ExampleApp.test
1451089127
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089119
```

After 10 seconds if we try again we should get a fresh result:

```elixir
iex> ExampleApp.test
1451089131
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089134
```

As you see we are able to implement a scalable and fast cache without any external dependencies and this is only one of many uses for ETS.

## ETS, a dysk twardy

We now know ETS is for in-memory term storage but what if we need disk-based storage? For that we have Disk Based Term Storage, or DETS for short.  The ETS and DETS APIs are interchangeable with the exception of how tables are created. DETS relies on `open_file/2` and doesn't require the `:named_table` option:

```elixir
iex> {:ok, table} = :dets.open_file(:disk_storage, [type: :set])
{:ok, :disk_storage}
iex> :dets.insert_new(table, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
true
iex> select_all = :ets.fun2ms(&(&1))
[{:"$1", [], [:"$1"]}]
iex> :dets.select(table, fun)
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

If you exit `iex` and look in your local directory, you'll see a new file `disk_storage`:

```shell
$ ls | grep -c disk_storage
1
```

One last thing to note is that DETS does not support `ordered_set` like ETS, only `set`, `bag`, and `duplicate_bag`.
