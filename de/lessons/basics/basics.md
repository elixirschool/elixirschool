---
version: 0.9.0
title: Grundlagen
---

Zum Anfang: Grundlegende Datentypen und Operationen.

{% include toc.html %}

## Grundlagen

### Elixir installieren

Installationsanleitungen für jedes Betriebssystem können auf elixir-lang.org unter [Installing Elixir](http://elixir-lang.org/install.html) gefunden werden.

Nachdem Elixir installiert ist, kann die installierte Version einfach überprüft werden.

    % elixir -v
    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Elixir {{ site.elixir.version }}

### Benutzen des interaktiven Modus

Elixir kommt mit `iex`, einer interaktiven Shell, welche uns erlaubt Ausdrücke in Elixir auszuwerten.

Zum Loslegen starten wir `iex`:

    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
    iex>

Lass uns fortfahren und ein paar einfache Audrücke ausprobieren:

```elixir
iex> 2+3
5
iex> 2+3 == 5
true
iex> String.length("Franz jagt im komplett verwahrlosten Taxi quer durch Bayern")
59
```

Falls du momentan noch nicht jeden Ausdruck versteht, mach dir darüber keine Gedanken. Wir denken du wirst dir bald ein Bild davon machen können.

## Einfache Datentypen

### Integer

```elixir
iex> 255
255
```

Unterstützung für Binär-, Oktal- und Hexadezimalzahlen wird mitgeliefert:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### Gleitkommazahlen

In Elixir verlangen Gleitkommazahlen mindestens einen Punkt nach einer Zahl; sie haben 64 Bit double precision und überstützen `e` für Exponenten:

```elixir
iex> 3.14
3.14
iex> .14
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```


### Booleans

Elixir unterstützt `true` und `false` als Booleans; alles außer `false` und `nil` wird als wahr betrachtet:

```elixir
iex> true
true
iex> false
false
```

### Atoms

Ein Atom ist eine Konstante, bei der der Name auch den Wert darstellt. Falls du mit Ruby vertraut bist kennst du Atoms als Symbole:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

Booleans `true` und `false` sind gleichwertig zu den Atoms `:true` und `:false`.

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

Modulnamen in Elixir sind auch Atoms. `MyApp.MyModule` ist ein gültiges Atom, auch wenn dieses Modul noch nicht deklariert wurde.

```elixir
iex> is_atom(MyApp.MyModule)
true
```

Atoms werden auch dazu genutzt, um Module aus Erlangbibiliotheken zu referenzieren. Dies gilt auch für in Erlang bereits vorhandenen Bibiliotheken.

```elixir
iex> :crypto.strong_rand_bytes 3
<<23, 104, 108>>
```

### Strings

Strings in Elixir sind UTF-8 codiert und in doppelten Anführungszeichen zu schreiben:

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

Strings unterstützen Zeilenumbrüche und Escapesequenzen:

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

Elixir unterstützt auch komplexere Datentypen. Wir werden mehr darüber erfahren wenn wir Collections und Funktionen lernen.

## Einfache Operationen

### Arithmetik

Elixir unterstützt die grundlegenden Operatoren `+`, `-`, `*`, und `/`. Wichtig dabei ist zu beachten, dass `/` immer Float zurück gibt:

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

Falls du Integerdivision oder den Rest der Division brauchst hat Elixir zwei hilfreiche Funktionen dafür:

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Boolean

Elixir bringt `||`, `&&` und `!` an Booleschen Operatoren mit. Diese unterstützen jeden Typ:

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

Es gibt drei weitere Operatoren, deren erstes Argument ein Boolean sein _muss_:

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

### Vergleiche

Elixir kommt mit diversen vergleichenden Operatoren: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<` und `>`.

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

Für strikte Vergleiche von Integern und Floats benutze `===`:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Ein wichtiges Feature von Elixir ist, dass jegliche zwei Typen miteinander verglichen werden können. Das ist beispielsweise dann praktisch, wenn man die Typen sortieren möchte. Wir müssen uns nicht an die Sortierreihenfolge erinnern, aber es ist wichtig zu wissen, dass es sie gibt:

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

Das führt mitunter zu interessanten, aber gültigen, Vergleichen, welche es so in anderen Sprachen nicht gibt:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### String Interpolation

Falls du Ruby kennst wird dir String Interpolation in Elixir bekannt vorkommen:

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### String-Verkettung

String-Verkettung benutzt den `<>` Operator:

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
