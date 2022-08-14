%{
  version: "1.1.1",
  title: "Erlang Term Storage (ETS)",
  excerpt: """
  Erlang Term Storage — ETS — jest potężnym mechanizmem składowania danych wbudowanym w OTP i dostępnym do użycia w Elixirze.
  W tej lekcji zobaczymy, jak połączyć się z ETS i jak możemy go użyć w naszych aplikacjach.
  """
}
---

## Informacje wstępne

ETS jest rozwiązaniem bazującym na pamięci operacyjnej, które pozwala na składowanie obiektów elixirowych i erlangowych.
ETS został zaprojektowany tak, by obsługiwać nawet duże zbiory danych ze stałym czasem dostępu.

Tabele ETS są tworzone i obsługiwane przez oddzielne procesy.
Kiedy proces zarządzający tabelą kończy się, tabela z nim powiązana jest usuwana.
Możesz mieć tak wiele tabel ETS, jak tylko zechcesz — jedynym limitem jest pamięć serwera. Możliwe jest ustalenie maksymalnej liczby tabel za pomocą zmiennej środowiskowej `ERL_MAX_ETS_TABLES`.

## Tworzenie tabel

Do tworzenia tabel służy funkcja `new/2`, która jako parametry przyjmuje nazwę tabeli i zbiór opcji, a zwraca identyfikator tabeli, którego możemy używać w dalszych operacjach.

Dla przykładu stwórzmy tabelę do składowania i wyszukiwania użytkowników po nicku:

```elixir
iex> table = :ets.new(:user_lookup, [:set, :protected])
8212
```

Podobnie jak w GenServerach, ETS umożliwia odwołanie się do tabeli po nazwie, a nie tylko po identyfikatorze.
By to zrobić, musimy dodać opcję `:named_table`.
Dzięki niej możemy odwołać się do naszej tabeli bezpośrednio po jej nazwie:

```elixir
iex> :ets.new(:user_lookup, [:set, :protected, :named_table])
:user_lookup
```

### Typy tabel

W ETS wyróżniamy cztery typy tabel:

+ `set` — typ domyślny.
Jedna wartość na klucz.
Klucze są unikalne.
+ `ordered_set` — podobny do `set`, ale klucze są posortowanie w rozumieniu Erlanga/Elixira.
Warto pamiętać, że klucze są inaczej porównywane w ramach `ordered_set`.
Konieczne jest zachowanie zasady rozróżnialności kluczy — nie mogą być one równe.
Przykładowo 1 i 1.0 są traktowane jako równe.
+ `bag` — wiele wartości w kluczu, ale wartości te muszą być unikalne.
+ `duplicate_bag` — wiele wartości w kluczu, duplikaty są dopuszczalne.

### Kontrola dostępu

Zasady dostępy w ETS są zbliżone do tych dla modułów:

+ `public` — odczyt i zapis dla wszystkich procesów.
+ `protected` — odczyt dla wszystkich procesów.
Zapis tylko dla procesu zarządzającego.
Jest to wartość domyślna.
+ `private` — odczyt i zapis tylko dla procesu zarządzającego.

## Wyścigi

Jeśli więcej niż jeden proces może zapisywać dane do tabeli — czy to przez publiczny dostęp (`public`), czy przez wiadomości do procesu zarządzającego — możliwe jest wystąpienie zjawiska wyścigów (hazardu).
Przykładowo, dwa procesy mogą jednocześnie odczytać wartość licznika równą `0`, następnie ją zwiększyć i zapisać `1`; końcowy rezultat będzie zatem odzwierciedlał tylko pojedynczą inkrementację tego licznika.

Specjalnie dla liczników dostępna jest funkcja [:ets.update_counter/3](http://erlang.org/doc/man/ets.html#update_counter-3), która zapewnia „atomowe” (niepodzielne) procesy aktualizacji i odczytywania wartości.
Dla innych przypadków może być konieczne, aby proces zarządzający tabelą wykonywał własne atomowe operacje jako odpowiedź na przychodzące wiadomości, takie jak „dodaj tę wartość do listy pod kluczem `:results`”.

## Wstawianie informacji

ETS nie posiada schematu.
Jedyne ograniczenie polega na tym, że dane są składowane jako krotki, w których pierwsza wartość to klucz.
By dodać rekord, możemy użyć funkcji `insert/2`:

```elixir
iex> :ets.insert(:user_lookup, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
true
```

Gdy użyjemy `insert/2` z `set` lub `ordered_set`, już istniejace dane mogą zostać nadpisane.
By temu zapobiec, należy użyć funkcji `insert_new/2`, która zwróci `false`, jeżeli dany klucz istnieje:

```elixir
iex> :ets.insert_new(:user_lookup, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
false
iex> :ets.insert_new(:user_lookup, {"3100", "", ["Elixir", "Ruby", "JavaScript"]})
true
```

## Wyszukiwanie informacji

ETS posiada kilka wygodnych i elastycznych sposobów na wyszukiwanie danych.
Przyjrzyjmy się, jak pobierać dane po kluczu i z użyciem różnych form dopasowania wzorców.

Najbardziej wydajną, idealną wręcz metodą wyszukiwania danych jest użycie klucza.
Wyszukiwania bazujące na dopasowaniu wzorców, choć bywają użyteczne, iterują po całej tabeli, więc powinniśmy ich używać oszczędnie, zwłaszcza przy dużych zbiorach danych.

### Wyszukiwanie po kluczu

Mając klucz, możemy użyć funkcji `lookup/2`, by wyszukać wszystkie rekordy przypisane do tego klucza:

```elixir
iex> :ets.lookup(:user_lookup, "doomspork")
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

### Proste porównania

ETS został zaprojektowany dla Erlanga, więc pamiętaj iż porównywanie zmiennych może wyglądać _odrobinę_ niezgrabnie.

By wskazać, które zmienne będziemy porównywać, używamy atomów `:"$1"`, `:"$2"`, `:"$3"` itd.
Numer zmiennej odwołuje się do pozycji w wyniku, a nie pozycji w porównaniu.
Jeżeli nie jesteśmy zainteresowani jakąś wartością, używamy zmiennej `:_`.

Wartości także mogą zostać użyte w dopasowaniu, ale jedynie zmienne zostaną zwrócone jako część wyniku.
Złóżmy to wszystko razem i zobaczmy, jak to działa:

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

Wiemy już, jak wygląda proste wyszukiwanie, ale co zrobić, jeżeli chcielibyśmy mieć coś w rodzaju SQL? Na szczęście mamy do dyspozycji bardziej solidne rozwiązanie.
Aby przeszukać nasze dane przy użyciu funkcji `select/2`, musimy skonstruować listę trójelementowych krotek.
Krotki te reprezentują wzorzec, zero lub więcej strażników oraz format odpowiedzi.

Zmienne użyte w dopasowaniu — oraz dwie nowe, `:"$$"` i `:"$_"` — mogą być użyte do skonstruowania zwracanej wartości.
Te nowe zmienne są skróconym zapisem do formatowania wyniku; `:"$$"` zwraca wynik jako listę, a `:"$_"` zwróci oryginalny obiekt.

Zmieńmy nasz poprzedni przykład z `match/2` tak, by użyć `select/2`:

```elixir
iex> :ets.match_object(:user_lookup, {:"$1", :_, :"$3"})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]

iex> :ets.select(:user_lookup, [{{:"$1", :_, :"$3"}, [], [:"$_"]}])
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]
```

Choć `select/2` pozwala na bardziej precyzyjną kontrolę rezultatów, to składnia tej funkcji jest nieprzyjazna w szczególnie złożonych przypadkach.
Do ich obsługi ETS zawiera funkcję `fun2ms/1`, która zmienia funkcję w specyfikację zwaną `match_specs`.
Z pomocą`fun2ms/1` możemy tworzyć zapytania, używając lepiej nam znanej składni funkcyjnej.

Połączmy zatem `fun2ms/1` i `select/2`, by odszukać wszystkie `usernames` z dwoma lub więcej językami:

```elixir
iex> fun = :ets.fun2ms(fn {username, _, langs} when length(langs) > 2 -> username end)
{% raw %}[{{:"$1", :_, :"$2"}, [{:>, {:length, :"$2"}, 2}], [:"$1"]}]{% endraw %}

iex> :ets.select(:user_lookup, fun)
["doomspork", "3100"]
```

Chcesz dowiedzieć się więcej o specyfikacji dopasowań? Zapoznaj się z oficjalną, erlangową dokumentacją w języku angielskim na temat [match_spec](http://www.erlang.org/doc/apps/erts/match_spec.html).

## Usuwanie danych

### Usuwanie rekordów

Usuwanie rekordów jest tak proste, jak użycie `insert/2` i `lookup/2`.
Wywołując `delete/2` przekazujemy nazwę tabeli i klucz.
W wyniku usunięte zostaną zarówno dane, jak i klucz:

```elixir
iex> :ets.delete(:user_lookup, "doomspork")
true
```

### Usuwanie tabel

Tabele ETS nie są usuwane, chyba że proces je obsługujący zakończy się.
Czasami jednak konieczne może być usunięcie tabeli bez zatrzymywania zarządzającego nią procesu.
Możemy do tego użyć funkcji `delete/1`:

```elixir
iex> :ets.delete(:user_lookup)
true
```

## Przykładowe użycie ETS

Wykorzystajmy zdobytą wiedzę w praktyce i stwórzmy aplikację — prosty _cache_ — pamięć podręczną — dla kosztownych obliczeniowo operacji.
Zaimplementujemy funkcję `get/4`, która jako argumenty będzie przyjmować moduł, funkcję, argumenty tej funkcji oraz opcje.
Na początek obchodzi nas tylko opcja `:ttl`.

W przykładzie zakładamy, że tabela ETS została utworzona przez inny proces, na przykład nadzorcę:

```elixir
defmodule SimpleCache do
  @moduledoc """
  Prosty, oparty na ETS cache dla kosztownych obliczeniowo funkcji.
  """

  @doc """
  Zwróć zapisaną wartość albo zastosuj daną funkcję, zapisując
  i zwracając wynik.
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
  Wyszukaj zapisany wynik i sprawdź jego aktualność.
  """
  defp lookup(mod, fun, args) do
    case :ets.lookup(:simple_cache, [mod, fun, args]) do
      [result | _] -> check_freshness(result)
      [] -> nil
    end
  end

  @doc """
  Porównaj czas wygaśnięcia wyniku z aktualnym czasem systemowym.
  """
  defp check_freshness({mfa, result, expiration}) do
    cond do
      expiration > :os.system_time(:seconds) -> result
      :else -> nil
    end
  end

  @doc """
  Zastosuj funkcję, oblicz czas wygaśnięcia i zapisz wynik.
  """
  defp cache_apply(mod, fun, args, ttl) do
    result = apply(mod, fun, args)
    expiration = :os.system_time(:seconds) + ttl
    :ets.insert(:simple_cache, {[mod, fun, args], result, expiration})
    result
  end
end
```

Zademonstrujmy działanie naszego _cache'a_ z użyciem funkcji zwracającej czas systemowy z 10-sekundową „pamięcią” (TTL).
Jak zobaczysz w poniższym przykładzie, otrzymujemy wynik z pamięci podręcznej, do momentu aż wartość się nie zdezaktualizuje:

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

## ETS a dysk twardy

Jak już wiemy, ETS do działania wykorzystuje pamięć RAM — ale co jeżeli chcielibyśmy mieć rozwiązanie wykorzystujące dysk twardy? Do tego służy _Disk Based Term Storage_, w skrócie DETS.
Interfejsy ETS i DETS mają spójne API z wyjątkiem sposobu tworzenia tabel.
DETS wykorzystuje `open_file/2` i nie wymaga opcji `:named_table`:

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

Trzeba jeszcze zaznaczyć, że w przeciwieństwie do ETS, DETS nie wspiera `ordered_set`, a jedynie `set`, `bag` i `duplicate_bag`.
