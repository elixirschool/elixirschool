---
version: 0.9.1
title: Mix
---

Zanim zajmiemy się bardziej zaawansowanymi aspektami Elixira musimy poznać mix. Jeżeli znasz Ruby to mix jest odpowiednikiem Bundlera, RubyGems i Rake. Jest to kluczowy element każdego projektu tworzonego w Elixirze i w tej lekcji przyjrzymy się najważniejszym jego funkcjom. By uzyskać pełną listę oferowanych funkcji, wpisz `mix help`.

Dotychczas pracowaliśmy z interpreterem `iex`, który ma dość ograniczone możliwości. Chcąc napisać coś bardziej rozbudowanego, musimy nasz projekt podzielić na wiele plików, by móc zarządzać kodem. Mix pozwala nam na efektywne zarządzanie projektem.   

{% include toc.html %}

## Nowy projekt

Kiedy będziesz gotowy, by stworzyć swój pierwszy projekt w Elixirze zrób to poleceniem `mix new`. Generator stworzy strukturę katalogów oraz niezbędne pliki projektu. Jest to bardzo proste, a zatem zaczynajmy:

```bash
$ mix new example
```

W konsoli pojawi się informacja, że mix stworzył niezbędne pliki oraz katalogi:

```bash
* creating README.md
* creating .gitignore
* creating mix.exs
* creating config
* creating config/config.exs
* creating lib
* creating lib/example.ex
* creating test
* creating test/test_helper.exs
* creating test/example_test.exs
```

W tej lekcji skupimy się na pliku `mix.exs`. Skonfigurujemy naszą aplikację, zależności, środowisko oraz wersję. Otwórz plik w swoim ulubionym edytorze. Powinieneś zobaczyć coś w rodzaju (komentarze usunięte dla zwięzłości):

```elixir
defmodule Example.Mixfile do
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

Pierwsza sekcja, której się przyjrzymy to `project`.  W niej definiujemy nazwę naszej aplikacji (`app`), określamy jej wersję (`version`), wersję Elixira (`elixir`) oraz listę zależności (`deps`).

Sekcja `application` jest używana w czasie tworzenia pliku aplikacji. Przyjrzymy się jej w następnej kolejności.

## Tryb interaktywny

Może zajść potrzeba użycia `iex` w kontekście naszej aplikacji.  Na całe szczęście z mixem jest to proste. Wystarczy uruchomić nową sesję `iex` z parametrami:

```bash
$ iex -S mix
```

Tak uruchomiony `iex` załaduje na starcie aplikację wraz z zależnościami.

## Kompilacja

Mix jest cwany i będzie kompilował tylko zmieniony kod, ale czasami zachodzi potrzeba skompilowania całego projektu. W tej części przyjrzymy się jak kompilować projekt i co robi kompilator.

Do skompilowania projektu wystarczy polecenie `mix compile` wywołane w katalogu głównym projektu:

```bash
$ mix compile
```

Nasz projekt nie zawiera zbyt wielu elementów, a zatem komunikat nie będzie zbyt ekscytujący, ale jednak liczymy na sukces:

```bash
Compiled lib/example.ex
Generated example app
```

W trakcie kompilacji mix tworzy katalog `_build`, w którym umieści wyniki. Jak zajrzymy do katalogu `_build`, zobaczymy naszą skompilowaną aplikację: `example.app`.

## Zarządzanie zależnościami

Jak na razie nasz projekt nie ma żadnych zależności, ale nic nie stoi nam na przeszkodzie, by je dodać.

Dodanie nowej zależności odbywa się w sekcji `deps` w pliku `mix.exs`. Lista zależności zawiera krotki o dwóch obowiązkowych elementach i jednym opcjonalnym: atomie reprezentującym nazwę pakietu, ciągu znaków określającym wersję oraz opcjonalnych przełącznikach.

Rzućmy okiem na przykład na projekt [phoenix_slim](https://github.com/doomspork/phoenix_slim):

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

Jak zapewne się domyślasz zależność `cowboy` jest potrzebna tylko w fazie rozwoju i testów aplikacji.

Jak już skonfigurujemy nasze zależności, trzeba je jeszcze pobrać. Jest to zachowanie analogiczne do `bundle install`:

```bash
$ mix deps.get
```

I to wszystko! Zdefiniowaliśmy i pobraliśmy nasze zależności. Teraz możemy ich użyć jak zajdzie potrzeba.

## Środowiska

Mix, tak jak Bundler, wspiera rozróżnianie środowisk. Domyślnie mamy zdefiniowane trzy z nich:

+ `:dev` — Środowisko domyślne.
+ `:test` — Używane przez `mix test`. Omówimy je w kolejnych lekcjach.
+ `:prod` — Używane, gdy uruchamiamy aplikację na produkcji.

Aktualne środowisko dostępne jest w `Mix.env`.  I jak można się spodziewać, istnieje możliwość skonfigurowania go za pomocą zmiennej systemowej `MIX_ENV`:

```bash
$ MIX_ENV=prod mix compile
```
