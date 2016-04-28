---
layout: page
title: Základy
category: basics
order: 1
lang: sk
---

Setup, základné typy a operácie.

## Obsah

- [Setup](#setup)
	- [Inštalácia Elixiru](#intalcia-elixiru)
	- [Interaktívny mód](#interaktvny-md)
- [Základné dátové typy](#zkladn-dtov-typy)
	- [Celé číslo](#cel-slo)
	- [Desatinné číslo](#desatinn-slo)
	- [Boolean](#boolean)
	- [Atom](#atom)
	- [Reťazec](#reazec)
- [Základné operácie](#zkladn-opercie)
	- [Aritmetické](#aritmetick)
	- [Logické](#logick)
	- [Porovnania](#porovnania)
	- [Interpolácia reťazcov](#interpolcia-reazcov)
	- [Spájanie reťazcov](#spjanie-reazcov)

## Setup

### Inštalácia Elixiru

Návod na inštaláciu pre každý OS sú k dispozícii na Elixir-lang.org v sekcii [Installing Elixir](http://elixir-lang.org/install.html).

### Interaktívny mód

Elixir obsahuje nástroj `iex`, interaktívny shell (príkazový riadok), ktorý dovoľuje skúšať a vyhodnocovať rôzne výrazy a konštrutky v Elixire..

Začnime teda jeho spustením príkazu `iex`:

	Erlang/OTP 17 [erts-6.4] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

	Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
	iex>

## Základné dátové typy

### Celé číslo

```elixir
iex> 255
iex> 0xFF
```

Zabudovaná podpora pre binárne, oktalové (osmičkové) a hexadecimálne čisla:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### Desatinné číslo

V Elixire vyžadujú desatinné čísla aspoň jednu číslicu pred desatinnou bodkou, sú 64 bitové a podporujú zápis exponenta pomocou znaku `e`:

```elixir
iex> 3.41
iex> .41
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
```


### Boolean

Elixir ma boolean hodnoty `true` a `false`; všetky hodnoty, okrem `false` a `nil` sú pravdivé (t.j. vyhodnotia sa ako `true`):

```elixir
iex> true
iex> false
```

### Atom

Atom je konštanta, ktorej meno je zároveň jej hodnotou. Ak poznáte Ruby, tak Atom je ekvivalentom Symbolov:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

POZNÁMKA: Boolean hodnoty `true` a `false` sú zároveň Atómami `:true` a `:false`.

```elixir
iex> true |> is_atom
true
iex> :true |> is_boolean
true
iex> :true === true
true
```

### Reťazec

V Elixire sú reťazce enkódované v UTF-8 a ohraničené dvojitými úvodzovkami (double quotes):

```elixir
iex> "Hello"
"Hello"
iex> "guľôčka"
"guľôčka"
```

Reťazce tiež podporujú zlomy riadkov a escapované sekvencie:

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

## Základné operácie

### Aritmetické

Elixir podporuje základné operátory `+`, `-`, `*`, a `/` tak, ako by ste očakávali. Dôležitý detail: `/` vždy vráti Float (desatinné číslo):

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

Pre celočíselné delenie (a zvyšok po ňom) poskytuje Elixir tieto dve funkcie:

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Logické

V Elixire existujú tri základné logické operátory `||`, `&&`, a `!` - dokážu pracovať s ľubovoľnými typmi (keďže všetko okrem `false` a `nil` je pravdivé):

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

Ďalšie tri logické operátory _vyžadujú_, aby prvým operandom bola hodnota typu Boolean (`true` alebo `false`):

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

### Porovnania

Elixir poskytuje všetky obvyklé porovnávacie operátory: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<` a `>`.

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

Pre striktné porovnávanie celých a desatinných čisel použite `===`:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Dôležitou vlastnosťou Elixiru je, že umožńuje porovnať hodnoty akýchkoľvek dvoch typov, čo sa obzvlášť hodí pri zoraďovaní (sortingu). Nie je nutné učiť sa spamäti poradie typov pri sortingu, ale je dobré o ňom vedieť:

```elixir
number < atom < reference < functions < port < pid < tuple < maps < list < bitstring
```

Toto môže viesť k niektorým zaujímavým a valídnym porovnaniam, aké v iných jazykoch nenájdete:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### Interpolácia reťazcov

Ak ste niekedy používali Ruby, interpolácia reťazcov v Elixire vám nebude cudzia:

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### Spájanie reťazcov

Na spájanie reťazcov v Elixire slúži operátor `<>`:

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
