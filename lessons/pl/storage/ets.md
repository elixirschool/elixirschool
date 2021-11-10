%{
  version: "0.9.1",
  title: "Erlang Term Storage (ETS)",
  excerpt: """
  Erlang Term Storage, zwany ETS, jest potężnym mechanizmem składowania danych zbudowanym z użyciem OTP i gotowym do użycia w Elixirze. W tej lekcji przyjrzymy się jak możemy użyć ETS w naszej aplikacji.
  """
}
---

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

Podobnie jak w GenServers, ETS umożliwia odwołanie się do tabeli po nazwie, a nie tylko po identyfikatorze. By to zrobić, musimy dodać opcję `:named_table`. I teraz możemy odwołać się d naszej tabeli bezpośrednio po nazwie:

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

By wskazać, które zmienne będziemy porównywać, używamy atomów `:"$1"`, `:"$2"`, `:"$3"`, itd. Numer zmiennej odwołuje się do pozycji w wyniku, a nie pozycji w porównaniu. Jeżeli nie jesteśmy zainteresowaniu jakąś wartością, to używamy zmiennej `:_`.

Wartości też mogą zostać użyte w dopasowaniu, ale tylko zmienne zostaną zwrócone jako część wyniku. Złóżmy to wszystko razem i zobaczmy, jak działa:

```elixir
iex> :ets.match(:user_lookup, {:"$1", "Sean", :_})
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
iex> :ets.match_object(:user_lookup, {:"$1", :_, :"$3"})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]

iex> :ets.match_object(:user_lookup, {:_, "Sean", :_})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```
### Zaawansowane wyszukiwanie

Wiemy już, jak wygląda proste wyszukiwanie, ale co jeżeli chcielibyśmy mieć coś w rodzaju SQL? Na całe szczęście mamy do dyspozycji elastyczniejsze rozwiązanie. Do przeszukiwania danych możemy użyć funkcji `select/2`, przyjmującej jako argument listę trójelementowych krotek. Krotki te reprezentują wzorzec, zero lub więcej strażników oraz format odpowiedzi.

Zmienne użyte w dopasowaniu oraz dwie nowe `:"$$"` i `:"$_"`, mogą być użyte do sformatowania wyniku. Te nowe zmienne są skróconym zapisem do formatowania wyniku; `:"$$"` zwraca wynik jako listę, a `:"$_"` zwróci oryginalny obiekt.

Zmieńmy nasz poprzedni przykład z `match/2` tak, by użyć `select/2`:

```elixir
iex> :ets.match_object(:user_lookup, {:"$1", :_, :"$3"})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]

{% raw %}iex> :ets.select(:user_lookup, [{{:"$1", :_, :"$3"}, [], [:"$_"]}]){% endraw %}
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"spork", 30, ["ruby", "elixir"]}]
```

Pomimo że `select/2` pozwala na precyzyjniejszą kontrolę rezultatów, to składnia tej funkcji jest nieprzyjazna szczególnie w złożonych przypadkach. Do ich obsługi ETS zawiera funkcję `fun2ms/1`, która zmienia funkcję w specyfikację zwaną `match_specs`.  Z pomocą`fun2ms/1` możemy tworzyć zapytania, używając lepiej nam znanej składni funkcyjnej. 

Połączmy zatem `fun2ms/1` i `select/2`, by odszukać wszystkie `usernames` z dwoma lub więcej językami:

```elixir
iex> fun = :ets.fun2ms(fn {username, _, langs} when length(langs) > 2 -> username end)
{% raw %}[{{:"$1", :_, :"$2"}, [{:>, {:length, :"$2"}, 2}], [:"$1"]}]{% endraw %}

iex> :ets.select(:user_lookup, fun)
["doomspork", "3100"]
```

Chcesz dowiedzieć się więcej o specyfikacji dopasowań? Zapoznaj się z oficjalną, erlngową, dokumentacją w języku angielskim [match_spec](http://www.erlang.org/doc/apps/erts/match_spec.html).

## Usuwanie danych

### Usuwanie rekordów 

Usuwanie rekordów jest zbliżone do wstawiania za pomocą `insert/2` i wyszukiwania za pomocą `lookup/2`. Wywołując `delete/2` przekazujemy nazwę tabeli i klucz. W wyniku usunięte zostaną zarówno dane, jak i klucz:

```elixir
iex> :ets.delete(:user_lookup, "doomspork")
true
```

### Usuwanie tabel

Tabele ETS nie są usuwane, chyba że proces je obsługujący zakończy się. Czasami jednak musimy usunąć tabelę, ale nie zatrzymując procesu. Służy do tego funkcja `delete/1`:

```elixir
iex> :ets.delete(:user_lookup)
true
```

## Przykładowe użycie ETS

Wykorzystajmy naszą wiedzę w praktyce. Stwórzmy aplikację – prosty _cache_ dla drogich obliczeniowo operacji. Zaimplementujemy funkcję `get/4`, która jako argumenty przyjmuje moduł, funkcję, argumenty tej funkcji oraz opcje. Na początek obchodzi nas tylko opcja `:ttl`.  

W przykładzie zakładamy, że tabela ETS została utworzona przez inny proces, na przykład nadzorcę:

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

      result ->
        result
    end
  end

  @doc """
  Lookup a cached result and check the freshness
  """
  defp lookup(mod, fun, args) do
    case :ets.lookup(:simple_cache, [mod, fun, args]) do
      [result | _] -> check_freshness(result)
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

Zademonstrujmy działanie naszego _cacha_ z użyciem funkcji zwracającej czas systemowy z 10-sekundową "pamięcią" (TTL). Jak widać na poniższym przykładzie, otrzymujemy wynik z pamięci podręcznej, do momentu aż wartość się nie zdezaktualizuje:

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

Gdy spróbujemy po 10 sekundach, otrzymamy nowy wynik:

```elixir
iex> ExampleApp.test
1451089131
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089134
```

Jak widać, udało nam się zaimplementować skalowalną i szybką pamięć podręczną bez żadnych zewnętrznych zależności, a to tylko jedno z zastosowań ETS.

## ETS, a dysk twardy

Jak wiemy ETS do działania wykorzystuje pamięć RAM, a co jeżeli chcielibyśmy mieć rozwiązanie wykorzystujące dysk twardy? Do tego służy _Disk Based Term Storage_, w skrócie DETS. Interfejsy ETS i DETS mają spójne API z dokładnością do sposobu tworzenia tabel. DETS wykorzystuje `open_file/2` i nie wymaga opcji `:named_table`:

```elixir
iex> {:ok, table} = :dets.open_file(:disk_storage, [type: :set])
{:ok, :disk_storage}
iex> :dets.insert_new(table, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
true
iex> select_all = :ets.fun2ms(&(&1))
[{:"$1", [], [:"$1"]}]
iex> :dets.select(table, select_all)
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

Jak wyjdziesz z `iex` i zajrzysz do lokalnego katalogu, to odkryjesz nowy plik `disk_storage`:

```shell
$ ls | grep -c disk_storage
1
```

Trzeba jeszcze zaznaczyć, że DETS nie wspiera `ordered_set` w przeciwieństwie do ETS, tylko `set`, `bag` i `duplicate_bag` są obsługiwane.
