%{
  version: "1.0.1",
  title: "Benchee",
  excerpt: """
  Nie możemy po prostu przypuszczać, które funkcje są szybkie a które są powolne - aby to ustalić potrzebujemy rzeczywistych pomiarów. Tu z pomocą przychodzi analiza porównacza. W tej lekcji nauczymy się jak łatwo jest zmierzyć szybkość naszego kodu.
  """
}
---

# O Benchee

Chociaż istnieje [funkcja w Erlangu](http://erlang.org/doc/man/timer.html#tc-1), która może być użyta do bardzo podstawowego pomiaru czasu wykonania funkcji, nie jest tak latwa w użytkowaniu jak niektóre z dostępnych narzędzi. Nie daje Ci wielu pomiarów, ktore są niezbedne do prawidłowego przeprowadzenia statystyk, dlatego skorzystamy z [Benchee](https://github.com/PragTob/benchee). Benchee dostarcza nam wielu statystyk z łatwymi do porównania scenariuszami, wspaniałą cechą, która pozwala nam przetestować różne dane wejściowe na funkcjach które testujemy i kilka różnych formaterów, które możemy wykorzystać do wyświetlania naszych wyników.

# Użytkowanie

Aby dodać Benchee do projektu, umieść go jako zależność w pliku `mix.exs`:

```elixir
defp deps do
  [{:benchee, "~> 0.9", only: :dev}]
end
```

Następnie wykonujemy:

```shell
$ mix deps.get
...
$ mix compile
```

Pierwsze polecenie pobiera i instaluje Benchee. Możesz zostać poproszony o zainstalowanie Hex wraz z nim. Drugie kompiluje aplikację Benchee. Teraz jesteśmy gotowi napisać nasz pierwszy test wydajości!

**Ważna uwaga przed rozpoczęciem:** Podczas testów wydajności bardzo ważne jest, aby nie używać `iex`, ponieważ zachowuje się inaczej i często jest dużo wolniejsze niż to, jak twój kod jest używany w produkcji. Stwórzmy plik który nazwiemy "benchmark.exs", a w tym pliku dodamy następujący kod:

```elixir
list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(%{
  "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
})
```

Aby uruchomić nasz test wydajności, wykonujemy:

```shell
$ mix run benchmark.exs
```

Następnie w konsoli powinniśmy zobaczyć:

```shell
Operating System: macOS
CPU Information: Intel(R) Core(TM) i5-4260U CPU @ 1.40GHz
Number of Available Cores: 4
Available memory: 8.589934592 GB
Elixir 1.5.1
Erlang 20.0
Benchmark suite executing with the following configuration:
warmup: 2.00 s
time: 5.00 s
parallel: 1
inputs: none specified
Estimated total run time: 14.00 s


Benchmarking flat_map...
Benchmarking map.flatten...

Name                  ips        average  deviation         median
flat_map           1.03 K        0.97 ms    ±33.00%        0.85 ms
map.flatten        0.56 K        1.80 ms    ±31.26%        1.60 ms

Comparison:
flat_map           1.03 K
map.flatten        0.56 K - 1.85x slower
```

Oczywiście informacje o twoim systemie oraz rezultaty mogą być inne w zależności od specyfikacji Twojej maszyny, ale generalne informacje powinny być takie same.

Na pierwszy rzut oka sekcja `Comparison` pokazuje nam, że nasza wersja `map.flatten` jest wolniejsza o 1.85x od `flat_map` - jest to bardzo pomocna informacja! Spójrzmy jednak na inne statystyki, które otrzymaliśmy:

* **ips** - oznacza "iteracje na sekundę", która mówi, jak często dana funkcja może być wykonana w ciągu jednej sekundy. Dla tej metryki im wyższy numer tym lepiej.
* **average** - jest to średni czas wykonania danej funkcji. Dla tego wskaźnika im mniejsza liczba tym lepiej.
* **deviation** - jest to odchylenie standardowe, które informuje, ile wyników dla każdej iteracji zmienia się w wynikach. Tutaj podaje się je jako procent średniej.
* **mediana** - gdy wszystkie zmierzone czasy są sortowane, jest to wartość środkowa (lub średnia dwóch wartości środkowych, gdy liczba próbek jest równa). Ze względu na niezgodności środowiskowe będzie to bardziej stabilne niż `average` i nieco bardziej prawdopodobne, że odzwierciedlają one normalną wydajność Twojego kodu w produkcji. Dla tego wskaźnika mniejsza liczba jest lepsza.

Istnieją również inne dostępne statystyki, ale te cztery są często najbardziej użyteczne i powszechnie używane do analizy porównawczej, dlatego są wyświetlane w domyślnym formaterze. Więcej informacji na temat innych dostępnych metryk można znaleźć w dokumentacji [hexdocs](https://hexdocs.pm/benchee/Benchee.Statistics.html#statistics/1).

# Konfiguracja

Jedną z najlepszych części Benchee są wszystkie dostępne opcje konfiguracji. Zaczniemy od podstaw, ponieważ nie wymagają przykładów kodu, a następnie pokażemy, jak wykorzystać jedną z najlepszych funkcji Benchee - wejść.

## Podstawy

Benchee ma wiele opcji konfiguracyjnych. W najbardziej popularnym interfejsie `Benchee.run/2`, są one przekazywane jako drugi argument w formie listy słów kluczowych:

```elixir
Benchee.run(
  %{"example function" => fn -> "hi!" end},
  warmup: 4,
  time: 10,
  inputs: nil,
  parallel: 1,
  formatters: [&Benchee.Formatters.Console.output/1],
  print: [
    benchmarking: true,
    configuration: true,
    fast_warning: true
  ],
  console: [
    comparison: true,
    unit_scaling: :best
  ]
)
```

Dostępne są następujące opcje (także udokumentowane w [hexdocs](https://hexdocs.pm/benchee/Benchee.Configuration.html#init/1)).

* **warmup** - czas w sekundach, dla którego powinien być uruchomiony scenariusz porównawczy bez czasów pomiarowych, zanim zaczną się rzeczywiste pomiary. To symuluje "ciepłe" działanie systemu. Domyślne ustawienie to 2 sekundy.
* **time** - czas w sekundach, jak długo powinien być uruchamiany i mierzony każdy indywidualny scenariusz porównawczy. Domyślnie 5 sekund.
* **inputs** - mapa z łańcuchami reprezentującymi nazwę wejściową jako klucze i rzeczywiste dane wejściowe jako wartości. Domyślnie `nil`. W dalszej części omówimy to szczegółowo.
* **parallel** - liczba procesów używanych do testu wydajności danej funkcjonalności. Więc jeśli ustawisz 'parallel: 4', wtedy zostaną stworzone cztery procesy, które wykonują tę samą funkcję dla danego `time`. Kiedy skończą się, na następnej funkcji zostaną uruchomione cztery nowe procesy. Daje to więcej danych w tym samym czasie, ale także powoduje obciążenie systemu zakłócające wyniki testów. Może to być przydatne do symulacji systemu pod obciążeniem, które jest czasem pomocne, ale powinno być stosowane z pewną ostrożnością, ponieważ może to wpływać na wyniki w nieprzewidywalny sposoby. Domyślnie 1 (co oznacza brak równoległej realizacji).
* **formatters** - lista funkcji formatyzacji, które chcesz uruchomić, aby uzyskać wyniki testów porównawczych pakietu przy użyciu polecenia `Benchee.run/2`. Funkcje muszą zaakceptować jeden argument (czyli pakiet porównawczy z wszystkimi danymi), a następnie użyć go do produkcji danych wyjściowych. Domyślny formater to: `Benchee.Formatters.Console.output/1`. Omówimy to w dalszej części.
* **print** - mapa lub lista słów kluczowych z następującymi opcjami jako atomy dla kluczy i wartości `true` lub `false`. Pozwala to kontrolować, czy dane wyjściowe identyfikowane przez atom zostaną wydrukowane podczas standardowego procesu analizy porównawczej. Wszystkie opcje są domyślnie włączone (true). Dostępne opcje to:
  * **benchmarking** - drukowanie, gdy Benchee zacznie testować nowe zadanie.
  * **configuration** - przed rozpoczęciem analizy porównawczej drukowane jest podsumowanie konfiguracji opcji analizy porównawczej, w tym szacowany całkowity czas pracy.
  * **fast_warning** - wyświetlane są ostrzeżenia, jeśli funkcje są wykonywane zbyt szybko, co może prowadzić do niedokładnych pomiarów.
* **console** - mapa lub lista słów kluczowych z następującymi opcjami jako atomy dla kluczy i wartości zmiennych. Dostępne wartości są wymienione w każdej z opcji:
  * **comparison** - jeśli porównane porównanie różnych prac benchmarkingu (x razy wolniej niż) ma być pokazane. Domyślnie to `true`, ale można też ustawić na `false`.
  * **unit_scaling** - strategia wyboru jednostki czasowej i liczników. Podczas skalowania wartości Benchee znajduje jednostkę "najlepiej pasującą" (największą jednostką, dla której wynik wynosi co najmniej 1). Na przykład "1_200_000" skaluje się do 1,2 M, podczas gdy `800_000` skaluje do 800 K. Strategia skalowania jednostek decyduje o tym, jak Benchee wybiera najlepszą jednostkę dopasowania dla całej listy wartości, gdy poszczególne wartości na liście mogą mieć inne najlepsze dopasowane jednostki. Są cztery strategie, wszystkie podane jako atomy, domyślnie `:best`:
    * **best** - najczęściej stosowana jednostka najlepiej dopasowana. Remis spowoduje wybranie większej jednostki.
    * **largest** - zostanie użyta największa jednostka dopasowania
    * **smallest** - najmniejsza jednostka najlepiej dopasowana będzie używana
    * **none** - nie ma skalowania jednostkowego. Czas wykonania wyświetlany jest w mikrosekundach, a liczniki ips będą wyświetlane bez jednostek.

## Wejścia

Bardzo ważne jest, aby testować wydajność funkcji na danych wielkością odpowiadających danym które będą używane w produkcji. Często funkcja może zachowywać się inaczej na małych zestawach danych w porównaniu do dużych zbiorów danych! Tu z pomocą przychodzi `inputs`. Pozwala to na testowanie tej samej funkcji, ale różnymi rodzajami danych wejściowych. Następnie wyniku testów można porównać.

Przyjrzyjmy się więc naszemu pierwotnemu przykładowi:

```elixir
list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(%{
  "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
})
```

W tym przykładzie używamy tylko jednej listy liczb całkowitych od 1 do 10,000. Zaktualizujmy to aby użyć kilku różnych wejść, dzięki czemu możemy zobaczyć, co się dzieje z mniejszymi i większymi listami. Otworzymy ten plik i zmienimy go w następujący sposób:

```elixir
map_fun = fn i -> [i, i * i] end

inputs = %{
  "small list" => Enum.to_list(1..100),
  "medium list" => Enum.to_list(1..10_000),
  "large list" => Enum.to_list(1..1_000_000)
}

Benchee.run(
  %{
    "flat_map" => fn list -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn list -> list |> Enum.map(map_fun) |> List.flatten() end
  },
  inputs: inputs
)
```

Zauważysz dwie różnice. Najpierw mamy mapę `input` zawierającą informacje o naszych danych wejściowych. Przekazujemy tę mapę jako opcję konfiguracji do `Benchee.run/2`.

Ponieważ nasze funkcje wymagają argumentu, musimy zaktualizować nasze funkcje tak, aby przyjmowały argument:

```elixir
fn -> Enum.flat_map(list, map_fun) end
```

teraz mamy:

```elixir
fn(list) -> Enum.flat_map(list, map_fun) end
```

Uruchommy to ponownie:

```shell
$ mix run benchmark.exs
```

Teraz powinieneś zobaczyć następujące dane w konsoli:

```shell
Operating System: macOS
CPU Information: Intel(R) Core(TM) i5-4260U CPU @ 1.40GHz
Number of Available Cores: 4
Available memory: 8.589934592 GB
Elixir 1.5.1
Erlang 20.0
Benchmark suite executing with the following configuration:
warmup: 2.00 s
time: 5.00 s
parallel: 1
inputs: large list, medium list, small list
Estimated total run time: 2.10 min

Benchmarking with input large list:
Benchmarking flat_map...
Benchmarking map.flatten...

Benchmarking with input medium list:
Benchmarking flat_map...
Benchmarking map.flatten...

Benchmarking with input small list:
Benchmarking flat_map...
Benchmarking map.flatten...


##### With input large list #####
Name                  ips        average  deviation         median
flat_map             6.29      158.93 ms    ±19.87%      160.19 ms
map.flatten          4.80      208.20 ms    ±23.89%      200.11 ms

Comparison:
flat_map             6.29
map.flatten          4.80 - 1.31x slower

##### With input medium list #####
Name                  ips        average  deviation         median
flat_map           1.34 K        0.75 ms    ±28.14%        0.65 ms
map.flatten        0.87 K        1.15 ms    ±57.91%        1.04 ms

Comparison:
flat_map           1.34 K
map.flatten        0.87 K - 1.55x slower

##### With input small list #####
Name                  ips        average  deviation         median
flat_map         122.71 K        8.15 μs   ±378.78%        7.00 μs
map.flatten       86.39 K       11.58 μs   ±680.56%       10.00 μs

Comparison:
flat_map         122.71 K
map.flatten       86.39 K - 1.42x slower
```

Teraz możemy zobaczyć informacje o naszych benchmarkach pogrupowane według danych wejściowych. Ten prosty przykład nie dostarcza imponujących spostrzeżeń, ale może Cię zaskoczyę jak bardzo pomiary wydajności zależą od wielkości danych wejsciowych!

# Formatery

Wyjście konsoli, które widzieliśmy, jest bardzo pomocne podczas pomiaru czasy wykonywania Twoich funkcji, ale to nie jedyna opcja! W tej sekcji zapoznamy się z trzema innymi formaterami, a także dowiesz się co musisz zrobić, aby napisać własny formater, jeśli chcesz.

## Inne formatery

Benchee ma wbudowany formater konsolowy, co widzieliśmy już wcześniej, ale istnieją trzy inne oficjalne formaty - `benchee_csv`, `benchee_json` i `benchee_html`. Każdy z nich zapisuje wyniki do plików danego formatu, dzięki czemu możesz pracować z Twoimi wynikami w dowolnym formacie.

Każdy z tych formatów znajduje się w osobnej paczce, więc aby nich korzystać trzeba dodać je jako zależności do pliku `mix.exs`:

```elixir
defp deps do
  [
    {:benchee_csv, "~> 0.6", only: :dev},
    {:benchee_json, "~> 0.3", only: :dev},
    {:benchee_html, "~> 0.3", only: :dev}
  ]
end
```

Chociaż `benchee_json` i `benchee_csv` są bardzo proste, `benchee_html` jest bogaty w interesujące funkcjonalności! Może pomóc Ci w prosty sposób tworzyć ładne wykresy z wynikami, a nawet je eksportować jako obrazy PNG. Wszystkie trzy formaty są dobrze udokumentowane na odpowiednich stronach GitHub.

## Niestandardowe formatery

Jeśli cztery oferowane formatery nie są dla Ciebie wystarczające, możesz napisać własny. Pisanie formatera jest całkiem proste. Musisz napisać funkcję, która akceptuje strukturę `% Benchee.Suite {}`, a następnie możesz pobrać dowolne informacje. Informacje na temat tego, co dokładnie znajduje się w tej strukturze można znaleźć na stronie [GitHub](https://github.com/PragTob/benchee/blob/master/lib/benchee/suite.ex) lub [HexDocs](https://hexdocs.pm/benchee/Benchee.Suite.html). Baza kodu jest bardzo dobrze udokumentowana i czytelna.

W kolejnym przykładzie pokażemy jak niestandardowy format może wyglądać. Powiedzmy, że chcemy tylko bardzo minimalnego formatera, który drukuje średni czas wykonywania każdego scenariusza - może on wyglądać tak:

```elixir
defmodule Custom.Formatter do
  def output(suite) do
    suite
    |> format
    |> IO.write()

    suite
  end

  defp format(suite) do
    Enum.map_join(suite.scenarios, "\n", fn scenario ->
      "Average for #{scenario.job_name}: #{scenario.run_time_statistics.average}"
    end)
  end
end
```

Następnie możemy uruchomić nasze testy wydajności w naspępujący sposób:

```elixir
list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(
  %{
    "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
  },
  formatters: [&Custom.Formatter.output/1]
)
```

Dzięki naszemu nowemu formaterowi ukaże się nam następujący widok:

```shell
Operating System: macOS
CPU Information: Intel(R) Core(TM) i5-4260U CPU @ 1.40GHz
Number of Available Cores: 4
Available memory: 8.589934592 GB
Elixir 1.5.1
Erlang 20.0
Benchmark suite executing with the following configuration:
warmup: 2.00 s
time: 5.00 s
parallel: 1
inputs: none specified
Estimated total run time: 14.00 s


Benchmarking flat_map...
Benchmarking map.flatten...
Average for flat_map: 851.8840109326956
Average for map.flatten: 1659.3854339873628
```