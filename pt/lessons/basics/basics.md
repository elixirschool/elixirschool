---
layout: page
title: Básico
category: basics
order: 1
lang: pt
---

Instalação, tipos básicos e operações básicas.

## Sumário

- [Instalação](#instalacao)
	- [Instalar Elixir](#instalar-elixir)
	- [Modo interativo](#modo-interativo)
- [Tipos Básicos](#tipos)
	- [Inteiros](#enteros)
	- [Ponto Flutuantes](#ponto-flutuantes)
	- [Booleanos](#booleanos)
	- [Atomos](#atomos)
	- [Strings](#strings)
- [Operações Básicas](#operaciones-basicas)
	- [Aritmética](#aritmetica)
	- [Booleanas](#booleanas)
	- [Comparação](#comparacao)
	- [Interpolação de string](#interpolacao-de-string)
	- [Concatenação de string](#concatenacao-de-string)

## Instalação

### Instalar Elixir

As instruções para cada sistema operacional podem ser encontradas em [Elixir-lang.org](http://elixir-lang.org) na aba [Install](http://elixir-lang.org/install.html).

### Modo Interactivo

Elixir vem com `iex`, um console interativo, que nos permite avaliar expressões Elixir.

Para iniciar, executamos `iex`:

	Erlang/OTP 17 [erts-6.4] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

	Interactive Elixir (1.0.4) - press Ctrl+C to exit (type h() ENTER for help)
	iex>

## Tipos Básicos

### Inteiros

```elixir
iex> 255
iex> 0xFF
```

O suporte para números binários, octais e hexadecimais também estão inclusos:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
255
```

### Ponto Flutuantes

Em Elixir, os ponto flutuantes requerem um decimal depois de pelo menos um dígito; estes possuem uma precisão de 64 bits e suportam `e` para números exponenciais.

```elixir
iex> 3.41
iex> .41
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
```


### Booleanos

Elixir suporta `true` e `false` como booleanos; todo valor é verdadeiro com excessão de `false` e `nil`:

```elixir
iex> true
iex> false
```

### Atomos

Um Átomo é uma constante cujo o nome é seu valor, se está familiarizado com Ruby, estes são equivalentes aos Símbolos:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

NOTA: Booleanos `true` e `false` são também átomos `:true` e `:false` respectivamente.

```elixir
iex> true |> is_atom
true
iex> :true |> is_boolean
true
iex> :true === true
true
```

### Strings

As strings em Elixir estão codificadas em utf-8 e estão representadas com aspas duplas:

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

As strings suportam quebras de linha e sequências de espaço:

```elixir
iex(9)> "foo
...(9)> bar"
"foo\nbar"
iex(10)> "foo\nbar"
"foo\nbar"
```

## Operações Básicas

### Aritmética

Elixir suporta os operadores básicos `+`, `-`, `*`, e `/` como era de esperar. É importante ressaltar que `/` sempre retornará um número ponto flutuante:

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

Se você necessita de uma divisão inteira ou o resto da divisão, Elixir vem com duas funcionalidades úteis para isto:

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Booleanos

Elixir prover os operadores booleanos: `||`, `&&`, e `!`, estes suportam qualquer tipo:

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

Há três operadores adicionais cujo o primeiro argumento _tem_ que ser um booleano (`true` e `false`):

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

### Comparação

Elixir vem com todos os operadores de comparação que estamos acostumados a usar: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<` e `>`.

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

Para comparação de inteiros e pontos flutuantes usa-se `===`:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Uma importante caracteristica do Elixir é que


Uma característica importante de elixir é que os dois tipos podem ser comparados, isto é particularmente útil para a ordenação. Não precisamos memorizar a ordem de classificação, mas é importante estar ciente de que:

```elixir
number < atom < reference < functions < port < pid < tuple < maps < list < bitstring
```

Isso pode levar a algumas comparações interessantes e válidas, você pode não encontrar em outras linguagens:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### Interpolação de Strings

Se você já usou Ruby, a interpolação de strings em Elixir parecerá muito familiar:

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### Concatenação de Strings

A concatenação de strings usa o operador `<>`:

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
