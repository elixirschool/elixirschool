%{
  version: "1.0.1",
  title: "Powłoka IEx",
  excerpt: """
  
  """
}
---

## Wstęp

Gdy zaczynasz przygodę z Elixirem, to IEx jest twoim najlepszym przyjacielem. 
Jest to REPL. Ma  jednak wiele dodatkowych cech, które ułatwiają pracę z istniejącym kodem, jak i tworzenie własnych rozwiązań.
W tej lekcji omówimy te pomocne elementy.

### Autouzupełnianie

Gdy pracujemy z powłoką, to może się zdarzyć, że chcemy użyć modułu, którego nie znamy. 
Funkcja autouzupełniania jest niezastąpiona, gdy chcemy rozeznać się w możliwościach takiego modułu. 
Wystarczy po nazwie modułu postawić kropkę i nacisnąć `Tab`:

```elixir
iex> Map. # naciśnij Tab
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
replace!/3           replace/3            split/2
take/2               to_list/1            update!/3
update/4             values/1
```

I już wiemy jakie funkcje są dostępne wraz z ich arnością!

### `.iex.exs`

Za każdym razem, gdy uruchamiamy IEx, poszukuje on pliku `.iex.exs` w bieżącym katalogu. Jeżeli plik nie istnieje, to sprawdzany jest katalog domowy użytkownika (`~/.iex.exs`).

Konfiguracja oraz funkcje zdefiniowane w tym pliku będą dostępne w powłoce IEx. Jeżeli zatem chcemy dodać kilka funkcji pomocniczych do IEx, to wystarczy otworzyć ten plik i wprowadzić zmiany.

Dodajmy zatem moduł z kilkoma funkcjami pomocniczymi:

```elixir
defmodule IExHelpers do
  def whats_this?(term) when is_nil(term), do: "Type: Nil"
  def whats_this?(term) when is_binary(term), do: "Type: Binary"
  def whats_this?(term) when is_boolean(term), do: "Type: Boolean"
  def whats_this?(term) when is_atom(term), do: "Type: Atom"
  def whats_this?(_term), do: "Type: Unknown"
end
```

Teraz gdy uruchomimy IEx, będziemy mieli dostępny moduł `IExHelpers` od samego początku. Uruchommy zatem IEx i zobaczmy, jak działają nasze funkcje:

```elixir
$ iex
{{ site.erlang.OTP }} [{{ site.erlang.erts }}] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex> IExHelpers.whats_this?("a string")
"Type: Binary"
iex> IExHelpers.whats_this?(%{})
"Type: Unknown"
iex> IExHelpers.whats_this?(:test)
"Type: Atom"
```

Jak widać, nie musimy wykonywać żadnych dodatkowych, operacji w rodzaju importowania, IEx zrobił to za nas. 

### `h`

`h` to jedna z najprzydatniejszych funkcji w powłoce.
Dzięki fantastycznemu wsparciu dla dokumentacji jako elementu języka, dzięki tej funkcji pomocniczej możemy dostać się do dokumentacji dowolnego kodu. Jest to banalnie proste:

```elixir
iex> h Enum
                                      Enum

Provides a set of algorithms that enumerate over enumerables according to the
Enumerable protocol.

┃ iex> Enum.map([1, 2, 3], fn(x) -> x * 2 end)
┃ [2, 4, 6]

Some particular types, like maps, yield a specific format on enumeration. For
example, the argument is always a {key, value} tuple for maps:

┃ iex> map = %{a: 1, b: 2}
┃ iex> Enum.map(map, fn {k, v} -> {k, v * 2} end)
┃ [a: 2, b: 4]

Note that the functions in the Enum module are eager: they always start the
enumeration of the given enumerable. The Stream module allows lazy enumeration
of enumerables and provides infinite streams.

Since the majority of the functions in Enum enumerate the whole enumerable and
return a list as result, infinite streams need to be carefully used with such
functions, as they can potentially run forever. For example:

┃ Enum.each Stream.cycle([1, 2, 3]), &IO.puts(&1)
```

I teraz połączmy, to z funkcją autouzupełniania. Na przykład pierwszy raz korzystając z modułu `Map`:

```elixir
iex> h Map
                                      Map

A set of functions for working with maps.

Maps are key-value stores where keys can be any value and are compared using
the match operator (===). Maps can be created with the %{} special form defined
in the Kernel.SpecialForms module.

iex> Map.
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
split/2              take/2               to_list/1
update!/3            update/4             values/1

iex> h Map.merge/2
                             def merge(map1, map2)

Merges two maps into one.

All keys in map2 will be added to map1, overriding any existing one.

If you have a struct and you would like to merge a set of keys into the struct,
do not use this function, as it would merge all keys on the right side into the
struct, even if the key is not part of the struct. Instead, use
Kernel.struct/2.

Examples

┃ iex> Map.merge(%{a: 1, b: 2}, %{a: 3, d: 4})
┃ %{a: 3, b: 2, d: 4}
```

Jak widać, możemy nie tylko dostać się do dokumentacji modułu, ale też do dowolnej funkcji w tym module. W dodatku dokumentacja zazwyczaj zawiera przykłady użycia.

### `i`

Wykorzystajmy naszą nowo zdobytą wiedzę, by z pomocą `h` zapoznać się z możliwościami funkcji `i`:

```elixir
iex> h i

                                  def i(term)

Prints information about the given data type.

iex> i Map
Term
  Map
Data type
  Atom
Module bytecode
  /usr/local/Cellar/elixir/1.3.3/bin/../lib/elixir/ebin/Elixir.Map.beam
Source
  /private/tmp/elixir-20160918-33925-1ki46ng/elixir-1.3.3/lib/elixir/lib/map.ex
Version
  [9651177287794427227743899018880159024]
Compile time
  no value found
Compile options
  [:debug_info]
Description
  Use h(Map) to access its documentation.
  Call Map.module_info() to access metadata.
Raw representation
  :"Elixir.Map"
Reference modules
  Module, Atom
```

Dowiedzieliśmy się kilku rzeczy o `Map` w tym, gdzie są pliki źródłowe i z jakich modułów korzysta. Jest to szczególnie użyteczne, gdy pracujemy z nieznanymi typami danych czy nowymi funkcjami. 

I choć poszczególne sekcje mogą zawierać dużo informacji, to na pewnym wysokim poziomie możemy zebrać wiele istotnych informacji:

- Jest on typu atomowego,
- Gdzie jest kod źródłowy,
- Wersja oraz opcje kompilacji,
- Ogólny opis,
- Jak się do niego dostać,
- Do jakich modułów się odwołuje.

To pozwala nam na zaoszczędzenie mnóstwa pracy i nie poruszamy się jak błędna owieczka.

### `r`

By zrekompilować dowolny moduł używamy funkcji `r`. Załóżmy, że zmieniliśmy jakiś kod i chcemy uruchomić nowo dodaną funkcję. Wszystko, co musimy zrobić, to zapisać nasze zmiany i zrekompilować je z użyciem `r`:  

```elixir
iex> r MyProject
warning: redefining module MyProject (current version loaded from _build/dev/lib/my_project/ebin/Elixir.MyProject.beam)
  lib/my_project.ex:1

{:reloaded, MyProject, [MyProject]}
```

### `t`

`t` mówi nam jakie typy mamy dostępne w danym module:

```elixir
iex> t Map
@type key() :: any()
@type value() :: any()
```

I teraz już wiemy, że `Map` definiuje typy `key` i `value`. Gdy zajrzymy do kodu źródłowego modułu `Map`, zobaczymy:

```elixir
defmodule Map do
# ...
  @type key :: any
  @type value :: any
# ...
```

Jest to bardzo prosty przykład, który pokazuje, że klucze i wartości mogą być dowolnego typu. 

Wykorzystując wszystkie te wbudowane elementy, możemy bardzo łatwo badać kod, bo dowiedzieć się jak działa. IEx to wydajne i niezawodne narzędzie dla programistów. Mając je w naszym arsenale nauka i tworzenie kodu może być jeszcze fajniejszą zabawą.
