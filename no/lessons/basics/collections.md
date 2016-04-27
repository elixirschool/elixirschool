---
layout: page
title: Kolleksjoner
category: basics
order: 2
lang: no
---

Lister, tupler, nøkkelord, og funksjonelle combinators.

## Innholdsfortegnelse

- [Lister (lists)](#lister-lists)
	- [Listesammenføyning (list concatenation)](#listesammenføyning-list-concatenation)
	- [Listesubtrahering (list subtraction](#listesubtrahering-list-subtraction)
	- [Head / Tail](#head--tail)
- [Tupler (tuples)](#tupler-tuples)
- [Nøkkelordslister (keyword lists)](#nøkkelordslister-keyword-lists)
- [Kart (maps)](#kart-maps)

## Lister (lists)

Lister er enkle kolleksjoner av verdier, og kan inneholde forskjellige typer.
Listene kan inneholde ikke-unike verdier:

```elixir
iex> [3.41, :pie, "Apple"]
[3.41, :pie, "Apple"]
```

Elixir implementerer listene som lenkede lister. Dette betyr at for å få lengden av en liste, må man bruke en `O(n)` operasjon for å aksessere den.
På grunnlag av dette er det ofte raskere å foranstille enn å tilføye til listen.

```elixir
iex> list = [3.41, :pie, "Apple"]
[3.41, :pie, "Apple"]
iex> ["π"] ++ list
["π", 3.41, :pie, "Apple"]
iex> list ++ ["Cherry"]
[3.41, :pie, "Apple", "Cherry"]
```


### Listesammenføyning (list concatenation)

For å sammenføye to lister bruker vi `++/2` operatoren:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

### Listesubrahering (list subtraction)

For å trekke fra i en liste bruker vi `--/2` operatoren. Det er trygt å trekke fra en verdi som ikke eksisterer:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

**Note:** It uses [strict comparison](../basics/#comparison) to match the values.
**Merk:**  Den bruker [nøyaktig sammenligning](../basics/#sammenligningsoperatorer) for å matche verdiene.

### Head / Tail

When using lists it is common to work with the list's head and tail.  The head is the first element of the list and the tail the remaining elements.  Elixir provides two helpful methods, `hd` and `tl`, for working with these parts:
Når man jobber med lister er det vanlig å referere til listens head og tail (hode og hale). Head er det første elementet av listen, mens tail er de resterende elementene.
Elixir leveres med to hjelpsomme metoder, `hd` og `tl` når man jobber med dette:
```elixir
iex> hd [3.41, :pie, "Apple"]
3.41
iex> tl [3.41, :pie, "Apple"]
[:pie, "Apple"]
```

In addition to the aforementioned functions, you may use the pipe operator `|`; we'll see this pattern in later lessons:
I tillegg til de tidligere nevnte funksjonene, kan man også bruke pipe operatoren `|` - Vi kommer tilbake til denne i en senere leksjon:

```elixir
iex> [h|t] = [3.41, :pie, "Apple"]
[3.41, :pie, "Apple"]
iex> h
3.41
iex> t
[:pie, "Apple"]
```

## Tupler (tuples)

Tuples are similar to lists but are stored contiguously in memory.  This makes accessing their length fast but modification expensive; the new tuple must be copied entirely to memory.  Tuples are defined with curly braces:
Tupler ligner på lister, men er lagret i minne på datamaskinen. Dette gjør at vi raskt kan få tilgang til de, men det gjør også endringer kostbare, da tuppelen i sin helhet må kopieres til minnet. Tupler defineres ved å skrive de mellom klammeparantes:

```elixir
iex> {3.41, :pie, "Apple"}
{3.41, :pie, "Apple"}
```

It is common for tuples to be used as a mechanism to return additional information from functions; the usefulness of this will be more apparent when we get into pattern matching:
Det er vanlig å bruke tupler for å returnere ekstra informasjon fra funksjoner. Bruksnytten av dette vil bli tydeligere når vi starter med mønstergjenkjenning:

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Nøkkelordlister (keyword lists)

Keywords and maps are the associative collections of Elixir.  In Elixir, a keyword list is a special list of tuples whose first element is an atom; they share performance with lists:
Nøkkelord (keywords) og kart (maps) er assosiative kolleksjoner i Elixir. Ei nøkkelordsliste er en liste som består av tupler, hvor det første elementet er et atam.
Nøkkelordslister har samme ytelse som en vanlig liste:

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

The three characteristics of keyword lists highlight their importance:
Disse tre karakteristikkene av ei nøkkelordsliste fremhever dems betydning:

+ Nøklene er atomer.
+ Nøklene er organisert.
+ Nøklene er ikke unike.

+ Keys are atoms.
+ Keys are ordered.
+ Keys are not unique.

For these reasons keyword lists are most commonly used to pass options to functions.
Av disse grunnene er det vanligst å bruke søkeordslister for å gi forskjellige alternativer til funksjoner.

## Kart (maps)

In Elixir maps are the "go-to" key-value store, unlike keyword lists they allow keys of any type and they do not follow ordering.  You can define a map with the `%{}` syntax:
Trenger man å bruke nøkkel-verdi

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

As of Elixir 1.2 variables are allowed as map keys:

```elixir
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
```

If a duplicate is added to a map, it will replace the former value:

```elixir
iex> %{:foo => "bar", :foo => "hello world"}
%{foo: "hello world"}
```

As we can see from the output above, there is a special syntax for maps containing only atom keys:

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}

iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```

