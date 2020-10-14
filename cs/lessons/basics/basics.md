---
version: 1.2.1
title: Základy
---

Základy jazyka Elixir, jeho základní datové typy a operace.
Jazyk Elixír je ze základu plně UTF-8 kompatibilní, pro účely tohoto tutoriálu je veškerý kód nepřeložen a je ponechán v originále.

{% include toc.html %}

## Začínáme!

### Instalace Elixíru

Instrukce pro instalalci na libovolném OS jsou popsány v návodu zde [Installing Elixir](http://elixir-lang.org/install.html).

Poté co je Elixír nainstalovám, můžete si jednoduše ověřit jeho verzi.

    % elixir -v
    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Elixir {{ site.elixir.version }}

### Interaktivní mód

Elixír nabízí IEx, interaktivní shell (REPL), který umožňuje vykonávat výrazy Elixíru za běhu.

Na spuštění napište `iex`:

    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
    iex>

Zkuste teď napsat několik jednoduchých příkazů:

```elixir
iex> 2+3
5
iex> 2+3 == 5
true
iex> String.length("The quick brown fox jumps over the lazy dog")
43
```

Žádne starosti jestli tomuhle neorzumíš, ale doufám, že chápeš koncept ;-)

## Základní datové typy

### Integers

```elixir
iex> 255
255
```

Podpora pro binární, oktálové a hexadecimální čísla je samozřejmostí:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### Floats

V Elixíru jsou čísla s desetinou čárkou s 64-bit double přesností a podporují `e` pro hodnotu exponentu:

```elixir
iex> 3.14
3.14
iex> .14
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```

### Booleans

Elixír podporuje `true` a `false` jako boolean honoty; všechno je pravdivé kromě `false` a `nil`:

```elixir
iex> true
true
iex> false
false
```

### Atoms

Atom je konstanta jejíž hodnota je stejná jako její jméno.
Zapisuje se s  pomocí `:` před samotným atomem.

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

Boolean hodnoty `true` a `false` jsou také atomy `:true` a `:false`.

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

Jména modulů v Elixíru jsou rovněž atomy. `MyApp.MyModule` je taky platný atom, ikdyž žádný takový modul ještě nebyl deklarován.

```elixir
iex> is_atom(MyApp.MyModule)
true
```

Atomy se taky používají jako reference modulů z Erlang knihoven, i z těch které Erlang nativně obsahuje od základu.

```elixir
iex> :crypto.strong_rand_bytes 3
<<23, 104, 108>>
```

### Strings

Řetězce v Elixíru jsou kódovány v UTF-8 a jsou uzavřeny ve dvojitých uvozovkách:

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

Řetězce podporují také line breaks a escape sekvence:

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

Elixír taky obsahuje více komplexní datové typy.
My se o těhle budeme učit když budeme probírat [kolekce](../collections/) a [funkce](../functions/).

## Základní operace

### Aritmetika

Elixír podporuje základní operátory `+`, `-`, `*`, a `/` tak jak byste čekali.
Je důležité si pamatovat, že `/` vždy vrátí float:

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

Pokud potřebujete celočíselné dělení nebo dělení se zbythem (viz. modulo),
Elixír má pro tohle dvě pomocné funkce `div` a `rem`:

```elixir
iex> 10 / 5
2.0
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Boolean

Elixír nabízí `||`, `&&`, a `!` booleanovské operátory.
Ty podporují jakékoliv typy:

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

Jsou zde i tři další operátory které však _musí_ mít jako první argument boolean hodnotu (`true` nebo `false`)

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


### Porovnání

Elixír má všechny operátory na které jsme již zvyklý: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<`, and `>`.

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

Pro striktní porovnání integerů a floatů, použijte `===`:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Důležitou vlastností Elixíru je, že umožňuje porovnat jakékoliv dva datové typy. Tohle je užitečné převážně v řazení. Nemusíme si pamatovat pořadí v jakém se řadí, ale je důležié na to brát ohledy:

```elixir
číslo < atom < reference < funkce < port < pid < tuple < map < list < bitstring
```

Tohle může vést k několika zajímavým, ale validním porovnáním, které nemusíte najít v jinačích jazycích:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### Řetězcová interpolace

Pokud jste používali Ruby, řetězcová interpolace v Elixíru vám bude vypadat povědomě:

```elixir
iex> name = "Babiš"
iex> "Hello zmrd #{name}"
"Hello zmrd Babiš"
```

### Zřetězení řetězců

K zřetězení řetězců se používá `<>` operátor:

```elixir
iex> name = "Kunda"
iex> "Hello " <> name
"Hello Kunda"
```
