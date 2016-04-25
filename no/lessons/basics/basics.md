---
layout: page
title: Grunnleggende Elixir
category: basics
order: 1
lang: no
---

Installasjon, grunnleggende typer og operasjoner.


## Innholdsfortegnelse

- [Installering](#installering)
	- [Installere Elixir ](#installere-elixir)
	- [Interaktiv Modus](#interaktiv-modus)
- [Grunnleggende Typer](#grunnleggende-typer)
	- [Integers](#integers)
	- [Floats](#floats)
	- [Booleans](#booleans)
	- [Atom](#atoms)
	- [String](#strings)
- [Grunnleggende Operasjoner](#grunnleggende-operasjoner)
	- [Aritmetikk](#artmetikk)
	- [Boolean](#boolean)
	- [Sammenligning](#sammenligning)
	- [String interpolasjon](#string-interpolasjon)
	- [String sammensetning](#string-sammensetning)

## Installering

### Installere Elixir

Se guiden hos Elixir-lang.org - [Installere Elixir](http://elixir-lang.org/install.html) på hvordan du installerer Elixir på en rekke forskjellige operativsystemer.

### Interaktiv Modus

Elixir leveres med `iex`, et interaktivt skall som lar oss evaluere Elixirkoder fortløpende.

To get started, let's run `iex`:
For å start IEx skriver vi `iex` i terminalvinduet:

	Erlang/OTP 17 [erts-6.4] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

	Interactive Elixir (1.0.4) - press Ctrl+C to exit (type h() ENTER for help)
	iex>

## Grunnleggende Typer

### Integers

```elixir
iex> 255
255
iex> 0xFF
255
```

Elixir støtter binære, oktale og heksdesimale tall:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### Floats

Float tall krever et desimal med minimum et siffer. De har 64 bit dobbel nøyaktighet, og støtter `e` for å lage eksponente tall:

```elixir
iex> 3.41
3.41
iex> .41
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```


### Booleans

Elixir støtter `true` og `false` som boolske verdier. Alt er 'sant', bortsett fra `false` (usant) og `nil` (null):

```elixir
iex> true
true
iex> false
false
```

### Atoms

Et atom er en konstant, hvor navnet er dens verdi. Om du er kjent med Ruby, kjenner du disse igjen som Symboler:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

MERK: De boolske verdiene `true` og `false` er også atomer: `:true` og `:false`.

```elixir
iex> true |> is_atom
true
iex> :true |> is_boolean
true
iex> :true === true
true
```

### Strings

Strings i Elixir er UTF-8 innkodet, og skrives mellom doble anførselstegn:

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

Strings støtter linjeskift og avbruddssekvenser:

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

## Basic Operations

### Arithmetic

Elixir supports the basic operators `+`, `-`, `*`, and `/` as you would expect.  It's important to notice that `/` will always return a float:

```elixir
iex> 2 + 2
4
iex> 2 - 1
1
iex> 2 * 5
10
iex> 10 / 5
2.0
```

If you need integer division or the division remainder, Elixir comes with two helpful functions to achieve this:

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Boolean

Elixir provides the `||`, `&&`, and `!` boolean operators. These support any types:

```elixir
iex> -20 || true
-20
iex> false || 42
42

iex> 42 && true
true
iex> 42 && nil
nil

iex> !42
false
iex> !false
true
```

There are three additional operators whose first argument _must_ be a boolean (`true` and `false`):

```elixir
iex> true and 42
42
iex> false or true
true
iex> not false
true
iex> 42 and true
** (ArgumentError) argument error: 42
iex> not 42
** (ArgumentError) argument error
```

### Comparison

Elixir comes with all the comparisons operators we're used to: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<` and `>`.

```elixir
iex> 1 > 2
false
iex> 1 != 2
true
iex> 2 == 2
true
iex> 2 <= 3
true
```

For strict comparison of integers and floats use `===`:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

An important feature of Elixir is that any two types can be compared, this is particularly useful in sorting.  We don't need to memorize the sort order but it is important to be aware of it:

```elixir
number < atom < reference < functions < port < pid < tuple < maps < list < bitstring
```

This can lead to some interesting, and valid, comparisons you might not find in other languages:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### String interpolation

If you've used Ruby, string interpolation in Elixir will look familiar:

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### String concatenation

String concatenation uses the `<>` operator:

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```

