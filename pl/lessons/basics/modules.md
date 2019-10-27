---
version: 0.9.1
title: Organizacja kodu
---

Doświadczenie podpowiada, że bardzo ciężko jest trzymać cały nasz kod w jednym pliku. W tej lekcji przyjrzymy się, jak grupować nasze funkcje w moduły oraz jak za pomocą wyspecjalizowanych map, zwanych strukturami, można efektywnie zorganizować nasz kod.

{% include toc.html %}

## Moduły

Moduły to najlepsza metoda na zorganizowanie naszego kodu w ramach przestrzeni nazw. Dodatkowo poza grupowaniem funkcji moduły pozwalają na definiowanie funkcji nazwanych oraz prywatnych, które poznaliśmy w poprzedniej lekcji.

Przyjrzyjmy się prostemu przykładowi:

``` elixir
defmodule Example do
  def greeting(name) do
    "Hello #{name}."
  end
end

iex> Example.greeting "Sean"
"Hello Sean."
```

W Elixirze możliwe jest zagnieżdżanie się modułów, pozwala to na lepszą organizację w naszej przestrzeni nazw:

```elixir
defmodule Example.Greetings do
  def morning(name) do
    "Good morning #{name}."
  end

  def evening(name) do
    "Good night #{name}."
  end
end

iex> Example.Greetings.morning "Sean"
"Good morning Sean."
```

### Atrybuty modułów

Atrybuty modułów są najczęściej wykorzystywane do reprezentowania stałych.  Przyjrzyjmy się przykładowym atrybutom:

```elixir
defmodule Example do
  @greeting "Hello"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

W Elixirze istnieją zarezerwowane nazwy dla atrybutów.  Trzy najpopularniejsze to:

+ `moduledoc` — Reprezentuje dokumentację modułu.
+ `doc` — Reprezentuje dokumentację funkcji i makr.
+ `behaviour` — Używany przez OTP i zachowania zdefiniowane przez użytkownika.

## Struktury

Struktury to wyspecjalizowane mapy, które zawierają zbiór kluczy i domyślnych wartości. Muszą być zdefiniowane w module i mają taką samą jak on nazwę. Nierzadko struktura jest jedynym elementem zdefiniowanym w module.

By zdefiniować strukturę, używamy słowa kluczowego `defstruct` wraz z listą asocjacyjną zawierającą nazwy pól i wartości domyślne:

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

Stwórzmy zatem kilka struktur:

```elixir
iex> %Example.User{}
%Example.User<name: "Sean", roles: [], ...>

iex> %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [], ...>

iex> %Example.User{name: "Steve", roles: [:manager]}
%Example.User<name: "Steve", roles: [:manager]>
```

Struktury można aktualizować tak jak zwykłe mapy:

```elixir
iex> steve = %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [...], ...>
iex> sean = %{steve | name: "Sean"}
%Example.User<name: "Sean", roles: [...], ...>
```

I najważniejsze. Struktury można dopasowywać tak jak zwykłe mapy:

```elixir
iex> %{name: "Sean"} = sean
%Example.User<name: "Sean", roles: [...], ...>
```

## Komponenty

Skoro już wiemy jak tworzyć moduły oraz struktury przyjrzyjmy się jak wykorzystywać je w kodzie z pomocą komponentów. Elixir pozwala na współpracę pomiędzy modułami na kilka sposobów. Przyjrzyjmy się, z czego możemy skorzystać.

### `alias`

Pozwala na tworzenie aliasów nazw modułów, co jest bardzo często wykorzystywane w kodzie Elixira:

```elixir
defmodule Sayings.Greetings do
  def basic(name), do: "Hi, #{name}"
end

defmodule Example do
  alias Sayings.Greetings

  def greeting(name), do: Greetings.basic(name)
end

# Without alias

defmodule Example do
  def greeting(name), do: Sayings.Greetings.basic(name)
end
```

Jeżeli pojawi się konflikt w nazwach aliasów, to za pomocą `:as` możemy lokalnie zmienić nazwę jednego z nich:

```elixir
defmodule Example do
  alias Sayings.Greetings, as: Hi

  def print_message(name), do: Hi.basic(name)
end
```

Można też utworzyć alias do wielu modułów naraz:

```elixir
defmodule Example do
  alias Sayings.{Greetings, Farewells}
end
```

### `import`

Jeżeli zamiast aliasu chcemy dołączyć, zaimportować, funkcje i makra z modułu do naszego kodu to możemy użyć `import/`:

```elixir
iex> last([1, 2, 3])
** (CompileError) iex:9: undefined function last/1
iex> import List
nil
iex> last([1, 2, 3])
3
```

#### Filtrowanie

Domyślnie importowane są wszystkie funkcje i makra, ale możemy odfiltrować tylko część z nich za pomocą opcji `:only` i
`:except`.

By zaimportować wskazane funkcje i makra, musimy podać nazwę/ilość argumentów jako parametry `:only` i `:except`.
Zaimportujmy tylko funkcję `last/1`:

```elixir
iex> import List, only: [last: 1]
iex> first([1, 2, 3])
** (CompileError) iex:13: undefined function first/1
iex> last([1, 2, 3])
3
```

Jeżeli zaimportujemy wszystkie funkcje poza `last/1` i uruchomimy kod z poprzedniego przykładu:

```elixir
iex> import List, except: [last: 1]
nil
iex> first([1, 2, 3])
1
iex> last([1, 2, 3])
** (CompileError) iex:3: undefined function last/1
```

Poza podaniem pary nazwa/liczba argumentów możemy też użyć dwóch atomów `:functions` i `:macros`, dzięki którym zaimportujemy odpowiednio tylko funkcje lub tylko makra:

```elixir
import List, only: :functions
import List, only: :macros
```

### `require`

Choć nie jest to zbyt często stosowana funkcja to `require/2` jest też bardzo ważna. Pozwala ona na wymuszenie kompilacji i załadowania wskazanego modułu. Jest to szczególnie przydatne, jeżeli chcemy korzystać z makr:

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

Jeżeli spróbujemy wywołać makro, które jeszcze nie zostało załadowane, to otrzymamy błąd.

### `use`

Pozwala na użycie modułu w aktualnym kontekście. Jest to szczególnie użyteczne, gdy moduł potrzebny jest do konfiguracji. Wywołując `use` odwołujemy się do zaczepu `__using__` wewnątrz modułu, pozwalając modułowi na zmiany w aktualnym kontekście:

```elixir
defmodule MyModule do
  defmacro __using__(opts) do
    quote do
      import MyModule.Foo
      import MyModule.Bar
      import MyModule.Baz

      alias MyModule.Repo
    end
  end
end
```
