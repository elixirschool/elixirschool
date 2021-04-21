---
version: 1.1.2
title: Základy
---

Inštalácia, základné dátové typy a operácie.

{% include toc.html %}

## Príprava

### Inštalácia Elixiru

Návod na inštaláciu pre každý OS sú k dispozícii na Elixir-lang.org v sekcii [Installing Elixir](http://elixir-lang.org/install.html).

Po tom ako sa Elixir nainštaloval, môžeme jednoducho overiť verziu.

	$ elixir -v
	Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

	Elixir {{ site.elixir.version }}

### Interaktívny mód

Elixir obsahuje nástroj `iex`, interaktívny shell (príkazový riadok), ktorý dovoľuje skúšať a vyhodnocovať rôzne výrazy.

Začnime teda jeho spustením príkazom `iex`:

	Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

	Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
	iex>

## Základné dátové typy

### Celé čísla

```elixir
iex> 255
255
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

### Desatinné čísla

V Elixire vyžadujú desatinné čísla aspoň jednu číslicu pred desatinnou bodkou, sú 64 bitové a podporujú zápis exponentu pomocou znaku `e`:

```elixir
iex> 3.14
3.14
iex> .14
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```


### Booleany

Elixir podporuje `true` a `false` ako boolean hodnoty; všetky hodnoty, okrem `false` a `nil` sú pravdivé (t.j. vyhodnotia sa ako `true`):

```elixir
iex> true
true
iex> false
false
```

### Atómy

Atóm je konštanta, ktorej meno je zároveň jej hodnotou. Ak poznáte Ruby, tak atóm je ekvivalentom Symbolov:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

Boolean hodnoty `true` a `false` sú zároveň atómami `:true` a `:false`.

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

Názvy modulov v Elixire sú tiež atómy. `MyApp.MyModule` je valídny atóm, dokonca aj keď taký modul ešte nebol deklarovaný.

```elixir
iex> is_atom(MyApp.MyModule)
true
```

Atómy sa tiež používajú na označenie modulov z knižníc Erlangu, vrátane vstavaných.

```elixir
iex> :crypto.strong_rand_bytes 3
<<23, 104, 108>>
```

### Reťazce

V Elixire sú reťazce enkódované v UTF-8 a ohraničené dvojitými úvodzovkami (double quotes):

```elixir
iex> "Hello"
"Hello"
iex> "guľôčka"
"guľôčka"
```

Reťazce podporujú zalomenie riadkov a escapované sekvencie:

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

Elixir tiež obsahuje zložitejšie dátové typy. O tých sa viac naučíme pri [kolekciách]() a [funkciách]().

## Základné operácie

### Aritmetika

Elixir podporuje základné operátory `+`, `-`, `*`, a `/` tak, ako by ste očakávali. Dôležitý detail: `/` vždy vráti desatinné číslo:

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

Ak potrebujete celočíselné delenie, alebo zvyšok po ňom (modulo), poskytuje na to Elixir tieto dve funkcie:

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Logické

Elixir poskytuje `||`, `&&`, a `!` ako logické operátory. Tie podporujú akékoľvek typy:

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

### Porovnávanie

Elixir poskytuje všetky obvyklé porovnávacie operátory, na ktoré sme zvyknutí: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<` a `>`.

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

Pre striktné porovnávanie celých a desatinných čísiel použite `===`:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Dôležitou vlastnosťou Elixiru je, že umožňuje porovnať hodnoty akýchkoľvek dvoch typov, čo je obzvlášť užitočné pri zoraďovaní. Nie je nutné učiť sa spamäti poradie typov pri zoraďovaní, ale je dobré o ňom vedieť:

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
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

Spájanie reťazcov používa operátor `<>`:

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
