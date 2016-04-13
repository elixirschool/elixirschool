---
layout: page
title: Podstawy
category: basics
order: 1
lang: pl
---

Przygotowanie środowiska, podstawowe typy danych i operacje

## Spis treści

- [Przygotowanie środowiska](#przygotowanie-srodowiska)
	- [Instalacja](#install-elixir)
	- [Interactive Mode](#interactive-mode)
- [Basic Types](#basic-types)
	- [Integers](#integers)
	- [Floats](#floats)
	- [Booleans](#booleans)
	- [Atom](#atoms)
	- [String](#strings)
- [Basic Operations](#basic-operations)
	- [Arithmetic](#arithmetic)
	- [Boolean](#boolean)
	- [Comparison](#comparison)
	- [String interpolation](#string-interpolation)
	- [String concatenation](#string-concatenation)

## Przygotowanie środowiska

### Instalacja

Proces instalacji środowiska, w języku angielskim, dla poszczególnych systemów operacyjnych jest opisany ma stronie Elixir-lang.org w sekcji [Installing Elixir](http://elixir-lang.org/install.html).

### Interactive Mode

Elixir comes with `iex`, an interactive shell, which allows us to evaluate Elixir expressions as we go.

To get started, let's run `iex`:

	Erlang/OTP 17 [erts-6.4] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

	Interactive Elixir (1.0.4) - press Ctrl+C to exit (type h() ENTER for help)
	iex>

## Basic Types

### Integers

```elixir
iex> 255
255
iex> 0xFF
255
```

Support for binary, octal, and hexadecimal numbers comes built in:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### Floats

In Elixir, float numbers require a decimal after at least one digit; they have 64 bit double precision and support `e` for exponent numbers:

```elixir
iex> 3.41
3.41
iex> .41
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```


### Booleans

Elixir supports `true` and `false` as booleans; everything is truthy except for `false` and `nil`:

```elixir
iex> true
true
iex> false
false
```

### Atoms

An atom is a constant whose name is their value. If you're familiar with Ruby these are synonymous with Symbols:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

NOTE: Booleans `true` and `false` are also the atoms `:true` and `:false` respectively.

```elixir
iex> true |> is_atom
true
iex> :true |> is_boolean
true
iex> :true === true
true
```

### Strings

Strings in Elixir are UTF-8 encoded and are wrapped in double quotes:

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

Strings support line breaks and escape sequences:

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
