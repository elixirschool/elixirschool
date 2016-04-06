---
layout: page
title: Basis
category: basics
order: 1
lang: nl
---

Opstarten, basistypen en -operaties.


## Inhoud

- [Opstarten](#opstarten)
	- [Elixir Installeren](#elixir-installeren)
	- [Interactieve Modus](#interactieve-modus)
- [Basistypen](#basistypen)
	- [Integers](#integers)
	- [Floats](#floats)
	- [Booleans](#booleans)
	- [Atoms](#atoms)
	- [Strings](#strings)
- [Basisoperaties](#basisoperaties)
	- [Rekenkundig](#rekenkundig)
	- [Booleaans](#booleaans)
	- [Vergelijking](#vergelijking)
	- [String interpolatie](#string-interpolatie)
	- [String samenvoeging](#string-samenvoeging)

## Opstarten

### Elixir Installeren

Installatie instructies voor elk besturingssysteem zijn te vinden op Elixir-lang.org in de [Installing Elixir](http://elixir-lang.org/install.html) gids.

### Interactieve Modus

Elixir wordt geleverd met `iex`, een interactieve shell die ons in staat stelt om Elixir expressies uit te voeren.

Om te beginnen starten we `iex`:

	Erlang/OTP 17 [erts-6.4] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

	Interactive Elixir (1.0.4) - press Ctrl+C to exit (type h() ENTER for help)
	iex>

## Basistypen

### Integers

```elixir
iex> 255
255
iex> 0xFF
255
```

Ondersteuning voor binaire, octale en hexadecimale getallen is ingebouwd:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### Floats

In Elixir vereisen drijvende komma getallen een decimale punt achter minimaal één cijfer. Ze hebben 64 bit dubbele precisie en ondersteuning `e` voor wetenschappelijke notatie:

```elixir
iex> 3.41
3.41
iex> .41
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```

### Booleans

Elixir ondersteunt `true` and `false` als booleans; alles is waar (truthy) behalve `false` en `nil`:

```elixir
iex> true
true
iex> false
false
```

### Atoms

Een atom is een constante wiens naam tevens diens waarde is. Ze zijn gelijk aan symbolen in Ruby, voor wie daar bekend mee is:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

OPMERKING: Booleans `true` en `false` zijn tevens de atoms `:true:` en `:false`, respectievelijk.

```elixir
iex> true |> is_atom
true
iex> :true |> is_boolean
true
iex> :true === true
true
```

### Strings

Strings in Elixir zijn UTF-8 gecodeerd en worden in dubbele quotes geplaatst:

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

Strings ondersteunen regeleinden en Escape-karakterreeksen:

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

## Basisoperaties

### Rekenkundig

Elixir ondersteunt de basis operators `+`, `-`, `*` en `/`/ zoals je zou verwachten. Het is belangrijk om te weten dat `/` altijd een float teruggeeft:

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

Indien je integerdelingen of de rest nodig hebt dan heeft Elixir daar twee handige functies voor:

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Booleaans

Elixir levert de `||`, `&&` en `!` booleaanse operators. Deze ondersteunen alle typen:

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

Er zijn drie aanvullende operators wiens eerste argument een boolean _moet_ zijn (`true` en `false`):

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

### Vergelijking

Elixir wordt geleverd met alle vergelijkingsoperators die we gewend zijn: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<` en `>`.

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

Voor strikte vergelijking van integers of floats gebruik je `===`:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Een belangrijk kenmerk van Elixir is dat twee willekeurige typen altijd kunnen worden vergeleken. Dit is vooral nuttig tijdens het sorteren. Het is nu niet belangrijk om de sorteervolgorde te onthouden maar het is wel belangrijk om er bewust van te zijn:

```elixir
number < atom < reference < functions < port < pid < tuple < maps < list < bitstring
```

Dit kan tot interessante en geldige vergelijkingen leiden die je wellicht niet in andere talen vindt:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### String interpolatie

Als je Ruby gebruikt dan ziet string interpolatie in Elixir er bekend uit:

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### String samenvoeging

Strings kunnen worden samengevoegd met de `<>` operator:

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
