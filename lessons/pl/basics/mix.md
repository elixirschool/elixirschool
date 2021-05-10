%{
  version: "1.1.2",
  title: "Mix",
  excerpt: """
  Zanim zajmiemy się bardziej zaawansowanymi aspektami Elixira musimy poznać Mix.
Jeżeli znasz język Ruby, to można powiedzieć, że Mix stanowi połączenie Bundlera, RubyGems i Rake.
Jest to kluczowy element każdego projektu tworzonego w Elixirze i w tej lekcji przyjrzymy się najważniejszym jego funkcjom.
By uzyskać pełną listę oferowanych funkcji, wpisz `mix help`.

Dotychczas pracowaliśmy z interpreterem `iex`, który ma dość ograniczone możliwości.
Chcąc napisać coś bardziej rozbudowanego, musimy nasz kod podzielić na wiele plików, by móc nim efektywnie zarządzać; Mix pozwala nam to robić z projektami.
  """
}
---

## Nowy projekt

Kiedy jesteśmy gotowi, by stworzyć nasz pierwszy projekt w Elixirze, możemy to zrobić za pomocą polecenia `mix new`.
Generator stworzy strukturę katalogów oraz niezbędne pliki projektu.
Jest to bardzo proste – zatem zaczynajmy:

```bash
$ mix new example
```

W konsoli pojawi się informacja, że Mix stworzył niezbędne pliki oraz katalogi:

```bash
* creating README.md
* creating .gitignore
* creating .formatter.exs
* creating mix.exs
* creating lib
* creating lib/example.ex
* creating test
* creating test/test_helper.exs
* creating test/example_test.exs
```

W tej lekcji skupimy się na pliku `mix.exs`.
Skonfigurujemy naszą aplikację, zależności, środowisko oraz wersję.
Otwórz plik w swoim ulubionym edytorze – powinieneś zobaczyć coś takiego (komentarze usunęliśmy dla zwięzłości):

```elixir
defmodule Example.Mix do
  use Mix.Project

  def project do
    [
      app: :example,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end
end
```

Pierwsza sekcja, której się przyjrzymy, to `project`.
W niej definiujemy nazwę naszej aplikacji (`app`), określamy jej wersję (`version`), wersję Elixira (`elixir`) oraz listę zależności (`deps`).

Sekcja `application` jest używana w czasie tworzenia pliku aplikacji, który omówimy dalej.

## Tryb interaktywny

Może zajść potrzeba użycia `iex` w kontekście naszej aplikacji.
Dzięki Mixowi jest to na szczęście proste.
Wystarczy uruchomić nową sesję `iex` z parametrami:

```bash
$ cd example
$ iex -S mix
```

Tak uruchomiony `iex` załaduje na starcie aplikację wraz z zależnościami.

## Kompilacja

Mix jest cwany i będzie kompilował tylko zmieniony kod, ale czasami zachodzi potrzeba skompilowania całego projektu.
W tej części przyjrzymy się jak kompilować projekt i co robi kompilator.

Do skompilowania projektu wystarczy polecenie `mix compile` wywołane w katalogu głównym projektu:
**Uwaga: polecenia Mixa specyficzne dla projektu są dostępne jedynie w głównym katalogu tego projektu – w innych lokalizacjach można użyć jedynie poleceń globalnych.**

```bash
$ mix compile
```

Nasz projekt nie zawiera zbyt wielu elementów, a zatem komunikat nie jest zbyt ekscytujący, ale kompilacja powinna zakończyć się powodzeniem:

```bash
Compiled lib/example.ex
Generated example app
```

W trakcie kompilacji Mix tworzy katalog `_build`, w którym umieści wyniki.
Jeśli zajrzymy do katalogu `_build`, zobaczymy naszą skompilowaną aplikację: `example.app`.

## Zarządzanie zależnościami

Jak na razie nasz projekt nie ma żadnych zależności, ale nic nie stoi na przeszkodzie, by je dodać.

Aby dodać nową zależność, powinniśmy ją najpierw umieścić w sekcji `deps` pliku `mix.exs`.
Lista zależności zawiera krotki o dwóch obowiązkowych elementach i jednym opcjonalnym: atomie reprezentującym nazwę pakietu, ciągu znaków określającym wersję oraz opcjonalnych przełącznikach.

Spójrzmy dla przykładu na projekt [phoenix_slim](https://github.com/doomspork/phoenix_slim):

```elixir
def deps do
  [
    {:phoenix, "~> 1.1 or ~> 1.2"},
    {:phoenix_html, "~> 2.3"},
    {:cowboy, "~> 1.0", only: [:dev, :test]},
    {:slime, "~> 0.14"}
  ]
end
```

Jak zapewne się domyślasz, zależność `cowboy` jest potrzebna tylko przy implementowaniu i testowaniu aplikacji.

Kiedy nasze zależności są już skonfigurowane, pozostaje nam jeszcze jeden krok: pobranie ich.
Jest to zachowanie analogiczne do `bundle install`:

```bash
$ mix deps.get
```

I to wszystko! Zdefiniowaliśmy i pobraliśmy nasze zależności.
Teraz możemy ich użyć jak zajdzie potrzeba.

## Środowiska

Mix, tak jak Bundler, wspiera rozróżnianie środowisk.
Domyślnie mamy zdefiniowane trzy z nich:

+ `:dev` — środowisko domyślne.
+ `:test` — używane przez `mix test`; omówimy je w kolejnych lekcjach.
+ `:prod` — używane, gdy uruchamiamy aplikację na produkcji.

Aktualne środowisko dostępne jest w `Mix.env`.
Jak można się spodziewać, istnieje możliwość skonfigurowania go za pomocą zmiennej środowiskowej `MIX_ENV`:

```bash
$ MIX_ENV=prod mix compile
```
