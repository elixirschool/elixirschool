%{
  version: "1.2.1",
  title: "Podstawy",
  excerpt: """
  Przygotowanie środowiska, podstawowe typy danych i operacje.
  """
}
---

## Przygotowanie środowiska

### Instalacja

Proces instalacji środowiska dla poszczególnych systemów operacyjnych jest opisany, w języku angielskim, na stronie Elixir-lang.org w sekcji [Installing Elixir](http://elixir-lang.org/install.html).

Po zakończeniu procesu instalacji możemy w łatwy sposób sprawdzić, którą wersję zainstalowaliśmy:

     % elixir -v
     Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

     Elixir {{ site.elixir.version }}

### Tryb interaktywny

W Elixirze dostępna jest interaktywna powłoka `iex`, która pozwala nam na uruchamianie kodu w konsoli.   

By ją uruchomić wpisz w wierszu poleceń `iex`:

	Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

	Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
	iex>

Spróbujmy wykonać kilka prostych operacji:

```elixir
iex> 2+3
5
iex> 2+3 == 5
true
iex> String.length("The quick brown fox jumps over the lazy dog")
43
```

Nie martw się, jeśli nie rozumiesz jeszcze wszystkich wyrażeń. Mamy nadzieję, że zrozumiesz ideę.

## Podstawowe typy danych

### Liczby całkowite

ang. _Integer_

```elixir
iex> 255
255
```

Elixir pozwala też na używanie liczb w notacji binarnej, ósemkowej i szesnastkowej:  

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### Liczby zmiennoprzecinkowe

W Elixirze liczby zmiennoprzecinkowe (ang. _float_) oznaczamy pojedynczą kropką; mają one 64 bitową precyzję oraz możemy użyć notacji z `e` do wyrażenia potęg:

```elixir
iex> 3.14
3.14
iex> .14
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```


### Wartości logiczne

Wartości logiczne (ang. _Boolean_) są reprezentowane przez `true` dla prawdy i `false` dla fałszu; każda wartość, innego typu, będzie interpretowana jako prawda poza `false` i `nil`:  

```elixir
iex> true
true
iex> false
false
```

### Atomy

Atomy są to stałe, których nazwa jest jednocześnie ich wartością. Jeżeli masz doświadczenie z językiem Ruby to atomy są tym samym co Symbole:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

Wartości `true` i `false` są też atomami odpowiednio`:true` i `:false`.

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

Nazwy modułów w Elixirze są atomami. Dla przykładu `MyApp.MyModule` jest poprawnym atomem nawet wtedy, gdy moduł o takiej nazwie nie istnieje.

```elixir
iex> is_atom(MyApp.MyModule)
true
```

Atomy służą też jako odwołania do bibliotek Erlanga, również tych wbudowanych.

```elixir
iex> :crypto.strong_rand_bytes 3
<<23, 104, 108>>
```

### Ciągi znaków

Ciągi znaków (ang. _String_) w Elixirze są reprezentowane w kodowaniu UTF-8 i otoczone znakiem cudzysłowu:

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

W ciągu znaków można używać zarówno znaków ucieczki jak i tworzyć ciągi w wielu liniach:

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

Elixir zawiera również bardziej złożone typy danych.
Więcej na ten temat dowiemy się, kiedy poznamy [kolekcje](../collections/) i [funkcje](../functions/).

## Podstawowe operacje

### Arytmetyczne

Elixir oczywiście wspiera podstawowe operatory `+`, `-`, `*` i`/`.  Ważne jest, że operacja `/` zawsze zwróci liczbę zmiennoprzecinkową:

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

Jeżeli jednak potrzebujesz dzielenia liczb całkowitych, albo reszty z dzielenia, Elixir udostępnia dwie funkcje do obsługi tych działań:

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Logiczne

Elixir posiada operatory logiczne `||`, `&&` i `!`. Wspierają one wszystkie typy:

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

Istnieją też trzy operatory, których pierwszym argumentem _musi_ być wartość logiczna (`true` lub `false`):

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

Uwaga: Operatory `and` oraz `or` w języku Elixir są odwzorowywane na `andalso` i `orelse` w Erlangu.

### Porównania

Elixir posiada pełen zestaw operatorów porównania: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<` i `>`.

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

Operator `===` porównuje wartość i typ, na przykład:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Ważną cechą Elixira jest to, że można porównać zmienne dowolnego typu, co jest szczególnie użyteczne przy sortowaniu. Nie musimy pamiętać kolejności przy sortowaniu, ale warto jest by mieć to na uwadze:

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

Pozwala to na stworzenie nietypowych, ale poprawnych konstrukcji porównań, które nie są dostępne w innych językach:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### Interpolacja ciągów znaków

Jeżeli używałeś Rubiego to interpolacja ciągów znaków w Elixirze wygląda tak samo:

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### Łączenie ciągów znaków

By połączyć dwa ciągi znaków wystarczy użyć operatora `<>`:

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
