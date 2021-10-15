%{
  version: "1.4.1",
  title: "Organizacja kodu",
  excerpt: """
  Doświadczenie podpowiada, że bardzo ciężko jest trzymać cały nasz kod w jednym pliku.
  W tej lekcji przyjrzymy się, jak grupować nasze funkcje w moduły oraz jak za pomocą wyspecjalizowanych map, zwanych strukturami, można efektywnie zorganizować nasz kod.
  """
}
---

## Moduły

Moduły to najlepsza metoda na zorganizowanie naszego kodu w ramach przestrzeni nazw.
Dodatkowo poza grupowaniem funkcji moduły pozwalają na definiowanie funkcji nazwanych oraz prywatnych, które poznaliśmy w [poprzedniej lekcji](/pl/lessons/basics/functions).

Przyjrzyjmy się prostemu przykładowi:

```elixir
defmodule Example do
  def greeting(name) do
    "Hello #{name}."
  end
end

iex> Example.greeting "Sean"
"Hello Sean."
```

W Elixirze możliwe jest zagnieżdżanie się modułów, co pozwala na lepszą organizację w naszej przestrzeni nazw:

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

Atrybuty modułów są najczęściej wykorzystywane do reprezentowania stałych.
Przyjrzyjmy się przykładowi:

```elixir
defmodule Example do
  @greeting "Hello"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

Ważne jest, aby pamiętać, że Elixir zawiera zastrzeżone atrybuty.
Trzy najpopularniejsze to:

- `moduledoc` — Reprezentuje dokumentację modułu.
- `doc` — Reprezentuje dokumentację funkcji i makr.
- `behaviour` — Używany przez OTP lub zachowania zdefiniowanego przez użytkownika.

## Struktury

Struktury to wyspecjalizowane mapy, które zawierają zbiór kluczy i domyślnych wartości.
Struktura musi być zdefiniowana w module, od którego bierze swoją nazwę.
Nierzadko struktura jest jedynym elementem zdefiniowanym w module.

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

I najważniejsze.
Struktury można dopasowywać tak jak zwykłe mapy:

```elixir
iex> %{name: "Sean"} = sean
%Example.User<name: "Sean", roles: [...], ...>
```

Od wersji Elixir 1.8 struktury zawierają niestandardową introspekcję.
Aby zrozumieć, co to oznacza i jak mamy z niego korzystać, przyjrzyjmy się naszemu uchwyceniu `sean`:

```elixir
iex> inspect(sean)
"%Example.User<name: \"Sean\", roles: [...], ...>"
```

Wszystkie nasze pola są obecne, co jest w porządku w tym przykładzie, ale co by było, gdybyśmy mieli pole chronione, którego nie chcieliśmy uwzględnić?
Nowa funkcja `@derive` pozwala nam właśnie to osiągnąć!
Zaktualizujmy nasz przykład, aby `role` nie były już uwzględniane w naszych danych wyjściowych:

```elixir
defmodule Example.User do
  @derive {Inspect, only: [:name]}
  defstruct name: nil, roles: []
end
```

_Uwaga_: moglibyśmy również użyć `@derive {Inspect, except: [:roles]}`, są one równoważne.

Po zaktualizowaniu naszego modułu przyjrzyjmy się, co dzieje się w `iex`:

```elixir
iex> sean = %Example.User{name: "Sean"}
%Example.User<name: "Sean", ...>
iex> inspect(sean)
"%Example.User<name: \"Sean\", ...>"
```

Pole `role` zostało pominięte w danych wyjściowych!

## Komponenty

Skoro już wiemy jak tworzyć moduły oraz struktury, przyjrzyjmy się jak wykorzystywać je w kodzie z pomocą komponentów.
Elixir zapewnia nam wiele różnych sposobów interakcji z innymi modułami.
Przyjrzyjmy się, z czego możemy skorzystać.

### alias

Pozwala na tworzenie aliasów nazw modułów, co jest bardzo często wykorzystywane w kodzie Elixira:

```elixir
defmodule Sayings.Greetings do
  def basic(name), do: "Hi, #{name}"
end

defmodule Example do
  alias Sayings.Greetings

  def greeting(name), do: Greetings.basic(name)
end

# Bez wykorzystania alias

defmodule Example do
  def greeting(name), do: Sayings.Greetings.basic(name)
end
```

Jeśli istnieje konflikt między dwoma aliasami lub po prostu chcemy zmienić alias na zupełnie inną nazwę, możemy użyć opcji `:as`:

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

### import

Jeżeli zamiast aliasu chcemy dołączyć (zaimportować) funkcje i makra z modułu do naszego kodu, to możemy użyć `import`:

```elixir
iex> last([1, 2, 3])
** (CompileError) iex:9: undefined function last/1
iex> import List
nil
iex> last([1, 2, 3])
3
```

#### Filtrowanie

Domyślnie importowane są wszystkie funkcje i makra, ale możemy odfiltrować tylko część z nich za pomocą opcji `:only` i `:except`.

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

Poza podaniem pary nazwa/liczba argumentów możemy też użyć dwóch specjalnych atomów `:functions` i `:macros`, dzięki którym zaimportujemy odpowiednio tylko funkcje lub tylko makra:

```elixir
import List, only: :functions
import List, only: :macros
```

### require

Możemy użyć `require`, aby poinformować Elixir, że zamierzamy używać makr z innego modułu.
Niewielka różnica w stosunku do `import` polega na tym, że pozwala na używanie makr, ale nie funkcji z określonego modułu:

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

Jeżeli spróbujemy wywołać makro, które jeszcze nie zostało załadowane, to otrzymamy błąd.

### use

Za pomocą makra `use` możemy umożliwić innemu modułowi modyfikację naszej aktualnej definicji modułu.
Kiedy wywołujemy `use` w naszym kodzie, w rzeczywistości wywołujemy wywołanie zwrotne `__using__/1` zdefiniowane przez dostarczony moduł.
Wynik makra `__using__/1` staje się częścią definicji naszego modułu.
Aby lepiej zrozumieć, jak to działa, spójrzmy na prosty przykład:

```elixir
defmodule Hello do
  defmacro __using__(_opts) do
    quote do
      def hello(name), do: "Hi, #{name}"
    end
  end
end
```

Stworzyliśmy moduł `Hello`, który definiuje wywołanie zwrotne `__using__/1`, wewnątrz którego definiujemy funkcję `hello/1`.
Stwórzmy nowy moduł, abyśmy mogli wypróbować nasz nowy kod:

```elixir
defmodule Example do
  use Hello
end
```

Jeśli wypróbujemy nasz kod w IEx, zobaczymy, że `hello/1` jest dostępne w module `Example`:

```elixir
iex> Example.hello("Sean")
"Hi, Sean"
```

Widzimy, że dzięki `use` zostało wykonane wywołanie zwrotne `__using__/1` na `Hello`, co z kolei dodało wynikowy kod do naszego modułu.
Teraz gdy zademonstrowaliśmy podstawowy przykład, zaktualizujmy nasz kod, aby zobaczyć, jak `__using__/1` obsługuje opcje.
Zrobimy to, dodając opcję `greeting`:

```elixir
defmodule Hello do
  defmacro __using__(opts) do
    greeting = Keyword.get(opts, :greeting, "Hi")

    quote do
      def hello(name), do: unquote(greeting) <> ", " <> name
    end
  end
end
```

Zaktualizujmy nasz moduł `Example` o nowo utworzoną opcję `greeting`:

```elixir
defmodule Example do
  use Hello, greeting: "Hola"
end
```

Jeśli wykonasz kod w IEx, zobaczysz, że powitanie zostało zmienione:

```elixir
iex> Example.hello("Sean")
"Hola, Sean"
```

Są to proste przykłady pokazujące, jak działa `use`, ale jest to niesamowicie potężne narzędzie w Elixir.
W miarę jak będziesz uczyć się o Elixirze, wypatruj `use`, jednym z przykładów, który na pewno zobaczysz, jest `use ExUnit.Case, async: true`.

**Uwaga**: `quote`, `alias`, `use`, `require` to makra związane z [metaprogramowaniem](/pl/lessons/advanced/metaprogramming).
