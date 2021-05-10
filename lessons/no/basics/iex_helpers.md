%{
  version: "1.0.1",
  title: "IEx Hjelpere",
  excerpt: """
  
  """
}
---

## Overview

Ettersom du starter og bruke Elixir, så vil IEx bli din bestevenn.
Det er et REPL, men den har veldig mange avanserte funskjonaliteter som kan gjøre livet ditt enklere når du utforsker ny kode eller mens du selv utvikler. Det er et mangfold av innebyggede hjelpere som vi skal utforske.

### Autofullføring

Når du jobber i terminalen, så møter du nok ofte nye moduler som du ikke er kjent med.
For å forstå hva som er tilgjengelig for deg, så er autofullføring funsjonaliteten fantastisk.
Skriv inn modul navnet etterfulgt av en `.` og press `Tab`:

```elixir
iex> Map. # press Tab
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

og nå kjenner vi til modulen sine funksjoner og deres aritet.

### .iex.exs

Hver gang IEx starter så vil den se etter en `.iex.exs` konfigurasjons fil. Hvis den ikke er tilgjengelig i nåværende direktiv, så vil den sjekke brukerens hjemmedirektiv (`~/.iex.exs`) og ta den i bruk.

La oss starte ved å legge til et bare hjelpe metoder:

```elixir
defmodule IExHelpers do
  def whats_this?(term) when is_nil(term), do: "Type: Nil"
  def whats_this?(term) when is_binary(term), do: "Type: Binary"
  def whats_this?(term) when is_boolean(term), do: "Type: Boolean"
  def whats_this?(term) when is_atom(term), do: "Type: Atom"
  def whats_this?(_term), do: "Type: Unknown"
end
```

Hvis vi starter IEx så vil vi ha IExHelpers modulen tilgjengelig for oss fra starten av. Åpne opp IEx og la oss prøve ut våre nye hjelpere:

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

Som vi kan se, så trenger vi ikke å gjøre noe spesielt for å få tak i våre hjelpere, IEx håndterer det for oss.

### h

`h` er en av de mest brukbare verktøyene som Elixir terminalen gir oss. På grunn av språkets fantastiske førsteklasse støtte for dokumentasjons, så vil dokumentasjonene for hvilken som helst kode bli nådd ved bruk av denne hjelperen.
For å se det i aksjon:

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

Vi kan til og med kombinere dette med autofullføring funksjonalitetet av terminalen vår. Tenk deg at vi utforsker Map for første gang:

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

Som vi kan se, så kunne vi se både funksjonene som var tilgjenglig i modulen, men også den individuelle dokumentasjonen for hver funksjon som inkluderer eksempeler.

### i

La oss ta i bruk det vi vet om `h` for å lære om `i` hjelperen:


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

Vi har en god del informasjon om `Map` inkludert hvor kildekoden er lagret og modulene den refererer. Dette er veldig brukbart når vi utforsker andres kode, moduler og funksjoner.

De første linjene kan være kompakte, men på et høyt nivå så kan vi ekstrahere veldig relevant informasjon:

- Det er en atom data type
- Hvor du kan finne kildekoden
- Versjonen og kompilasjons mulighetene
- En generelle deskripsjon
- Hvordan ta den i bruk
- Hvilke andre moduler den refererer til

Dette gir oss veldig mye å jobbe med.

### r

Hvis vi rekompilere en spesifikk modul så kan vi ta i bruk `r` hjelperen. La oss si at vi endret på noe kode og ønsker å ta i bruk den nye funksjonen som vi la til. For å gjøre det så må vi lagre våre endringer og rekompilere med r:

```elixir
iex> r MyProject
warning: redefining module MyProject (current version loaded from _build/dev/lib/my_project/ebin/Elixir.MyProject.beam)
  lib/my_project.ex:1

{:reloaded, MyProject, [MyProject]}
```

### t

hjelperen `t` forteller oss om typer tilgjenglig i en gitt modul:

```elixir
iex> t Map
@type key() :: any()
@type value() :: any()
```

Dette er et enkelt eksempel, som påpeker at nøkler og verdier i følge implementasjonen kan være av en hvilken som helst type, men det er nyttig å vite.

Ved å ta i bruk alle disse innebygde funksjonalitetene så kan vi enkelt utforske kode og lære mer om hvordan ting fungerer. IEx er et veldig robust verktøy som hjelper utviklerer. Med disse verktøyene i vår verktøykasse så kan utforsking og koding være enda mer morsomt!
