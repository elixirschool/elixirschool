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
	- [Instalacja](#instalacja)
	- [Tryb interaktywny](#tryb-interaktywny)
- [Podstawowe typy danych](#podstawowe-typy-danych)
	- [Liczby całkowite](#liczby-całkowite)
	- [Liczby zmiennoprzecinkowe](#liczby-zmiennoprzecinkowe)
	- [Wartości logiczne](#wartości-logiczne)
	- [Atomy](#atomy)
	- [Ciągi znaków](#ciągi-znakþw)
- [Podstawowe operacje](#podstawowe-operacje)
	- [Arytmetyczne](#arytmetyczne)
	- [Logiczne](#logiczne)
	- [Porównania](#porownania)
	- [Interpolacja ciągów znaków](#interpolacja-ciągów-znaków)
	- [Łączenie ciągów znaków](#laczenie-ciągów-znaków)

## Przygotowanie środowiska

### Instalacja

Proces instalacji środowiska dla poszczególnych systemów operacyjnych jest opisany, w języku angielskim, na stronie Elixir-lang.org w sekcji [Installing Elixir](http://elixir-lang.org/install.html).

### Tryb interaktywny

W Elixirze dostępna jest interaktywna powłoka `iex`, która pozwala nam na uruchamianie kodu w konsoli.   

By ją uruchomić wpisz w wierszu poleceń `iex`:

	Erlang/OTP 17 [erts-6.4] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

	Interactive Elixir (1.0.4) - press Ctrl+C to exit (type h() ENTER for help)
	iex>

## Podstawowe typy danych

### Liczby całkowite

ang. _Integer_

```elixir
iex> 255
255
iex> 0xFF
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

W Elixirze liczby zmiennoprzecinkowe (ang. _float_) oznaczamy pojedynczą kropką; mają one 64 bitową prezycję oraz możemy użyć notacji z `e` do wyrażenia potęg:

```elixir
iex> 3.41
3.41
iex> .41
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

Atomy są to stałe posiadające nazwę. Jeżeli masz doświadczenie z językiem Ruby to atomy są tym samym co Symbole:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

UWAGA: Wartości `true` i `false` są też atomami odpowiednio`:true` i `:false`.

```elixir
iex> true |> is_atom
true
iex> :true |> is_boolean
true
iex> :true === true
true
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

Istnieją też trzy operatory, które _muszą_ być użyte tylko z wartościami logicznymi (`true` i `false`):

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

Ważną cechą Elixira jest to, że można porównać zmienne dowolngo typu, jest to szczególnie użyteczne przy sortowaniu. Nie musimy pamiętać kolejności przy sortowaniu, ale warto jest by mieć to na uwadze:

```elixir
number < atom < reference < functions < port < pid < tuple < maps < list < bitstring
```

Pozwala to na stworzenie nietypowych, ale poprawnych konstrukcji porównań, które nie są dostępne w innych jezykach:

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
