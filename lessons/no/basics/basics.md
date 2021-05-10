%{
  version: "0.9.0",
  title: "Grunnleggende Elixir",
  excerpt: """
  Installasjon, grunnleggende typer og operatorer.
  """
}
---

## Installering

### Installere Elixir

Se guiden hos Elixir-lang.org - [Installere Elixir](http://elixir-lang.org/install.html) på hvordan du installerer Elixir på en rekke forskjellige operativsystemer.

### Interaktiv Modus

Elixir leveres med `iex`, et interaktivt skall som lar oss evaluere Elixirkoder fortløpende.

For å starte IEx skriver vi `iex` i terminalvinduet:

	Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

	Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
	iex>

## Grunnleggende Typer

### Heltall (integers)

```elixir
iex> 255
255
```

Elixir støtter binære, oktale og heksdesimale heltall:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### Flyttall (floats)

flyttall krever et desimal med minimum et siffer. De har 64 bit dobbel nøyaktighet, og støtter `e` for å lage eksponenter:

```elixir
iex> 3.14 
3.14
iex> .14
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```


### Boolske Verdier (booleans)

Elixir støtter `true` og `false` som boolske verdier. Alt er 'sant', bortsett fra `false` (usant) og `nil` (null):

```elixir
iex> true
true
iex> false
false
```

### Atomer (Atoms)

Et atom er en konstant, hvor navnet er dens verdi. Om du er kjent med Ruby, kjenner du disse igjen som Symboler:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

MERK: De boolske verdiene `true` og `false` er også atomer: `:true` og `:false`.

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

Navnet på moduler i Elixir er også atomer. `MinApp.MinModule` er en gyldig atom,
selv om ingen slik module har blitt lagd.

```elixir
iex> is_atom(MinApp.MinModule)
true
```

Atomer er også brukt for å referere til moduler fra Erlang biblioteket, men også til de innebygde modulene.

```elixir
iex> :crypto.strong_rand_bytes 3
<<23, 104, 108>>
```

### Strenger (strings)

Strenger i Elixir er UTF-8 innkodet, og skrives mellom doble anførselstegn:

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

Strenger støtter linjeskift og avbruddssekvenser:

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

## Grunnleggende Operatorer

### Aritmetikk

Elixir støtter de grunnleggende matematiske operatorene `+`, `-`, `*` og `/`. Det er verdt å merke seg at `/` alltid vil returnere et flyttall (float):

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

Elixir har to innebygde funksjoner for å returnere et heltall(integer), eller finne rest i en divisjon:

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Boolske Operatorer (boolean)

Elixir lar deg bruke de boolske operatorene `||`, `&&` og `!`.
Disse operatorene støtter alle typer:

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

Det er i tillegg tre andre operatorer, hvor første argumentet _må_ være en boolsk verdi (`true` eller `false`):

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

### Sammenligningoperatorer

Elixir lar deg bruke en rekke forskjellige operatorer for sammenligning av verdier: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<` og `>`.

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

For en nøyaktig (strict) sammenligning av heltall og flyttall benytter vi oss av `===`:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

En viktig egenskap i Elixir, er at alle typer kan bli sammenlignet med hverandre.
Dette er spesielt nyttig ved sortering. Vi trenger ikke memorisere sorteringsrekkefølgen, men det er greit å være kjent med den:

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

Dette kan føre til noen interessante, men gyldige sammenligninger du kanskje ikke finner i andre programmeringsspråk:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### Strenginterpolering (String interpolation)

Hvis du noen gang har programmert i Ruby, vil strenginterpolering i Elixir
se kjent ut:

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### Strengsammensetning (String concatenation)

Strengsammensetning benytter `<>` operatoren:

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```

iex> "Hello " <> name
"Hello Sean"
```


Dette kan føre til noen interessante, men gyldige sammenligninger du kanskje ikke finner i andre programmeringsspråk:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### Strenginterpolering (String interpolation)

Hvis du noen gang har programmert i Ruby, vil strenginterpolering i Elixir
se kjent ut:

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### Strengsammensetning (String concatenation)

Strengsammensetning benytter `<>` operatoren:

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
