---
layout: page
title: Básico
category: basics
order: 1
lang: es
---

Preparar el entorno, tipos básicos y operaciones.

## Tabla de contenidos

- [Preparar el entorno](#preparar-el-entorno)
	- [Instalar Elixir](#instalar-elixir)
	- [Modo interactivo](#modo-interactivo)
- [Tipos Básicos](#tipos-basicos)
	- [Enteros](#enteros)
	- [Coma flotante](#coma-flotante)
	- [Booleanos](#booleanos)
	- [Atomos](#atomos)
	- [Cadenas](#cadenas)
- [Operaciones Básicas](#operaciones-basicas)
	- [Aritmética](#aritmetica)
	- [Booleanas](#booleanas)
	- [Comparación](#comparacion)
	- [Interpolación de cadenas](#interpolacion-de-cadenas)
	- [Concatenación de cadenas](#concatenacion-de-cadenas)

## Preparar el entorno

### Instalar Elixir

Las instrucciones para cada sistema operativo pueden ser encontradas en [Elixir-lang.org](http://elixir-lang.org) en la guía [Instalando Elixir](http://elixir-lang.org/install.html).

### Modo Interactivo

Elixir viene con `iex`, una consola interactiva, que nos permite evaluar expresiones Elixir.

Para empezar, Ejecutamos `iex`:

	Erlang/OTP 17 [erts-6.4] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

	Interactive Elixir (1.0.4) - press Ctrl+C to exit (type h() ENTER for help)
	iex>

## Tipos Básicos

### Enteros

```elixir
iex> 255
iex> 0xFF
```

El soporte para números binarios, octales y hexadecimales también viene incluido:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
255
```

### Coma flotante

En Elixir, los números con coma flotante requieren un decimal después de al menos un dígito; estos tienen una precisión de 64 bits y soportan `e` para números exponenciales.

```elixir
iex> 3.41
iex> .41
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
```


### Booleanos

Elixir soporta `true` y `false` como booleanos; todo valor es verdadero a excepción de `false` y `nil`:

```elixir
iex> true
iex> false
```

### Átomos

Un Átomo es una constante cuyo nombre es su valor, si estás familiarizado con Ruby estos son equivalentes a los Símbolos:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

NOTA: Booleanos `true` y `false` son también los átomos `:true` y `:false` respectivamente.

```elixir
iex> true |> is_atom
true
iex> :true |> is_boolean
true
iex> :true === true
true
```

### Cadenas

Las cadenas en Elixir están codificadas en utf-8 y están representadas con comillas dobles:

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

Las cadenas soportan saltos de línea y secuencias de escape:

```elixir
iex(9)> "foo
...(9)> bar"
"foo\nbar"
iex(10)> "foo\nbar"
"foo\nbar"
```

## Operaciones Básicas

### Aritmética

Elixir soporta los operadores básicos `+`, `-`, `*`, y `/` como era de esperarse. Es importante resaltar que `/` siempre retornará un número con coma flotante:

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

Si tu necesitas una división entera o el resto de una división, Elixir viene con dos funciones útiles para para lograr esto:

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Booleanas

Elixir provee los operadores booleanos: `||`, `&&`, y `!`, estos soportan cualquier tipo:

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

Hay tres operadores adicionales cuyo primer argumento _tiene_ que ser un booleano (`true` y `false`):

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

### Comparación

### Interpolación de cadenas

Si haz usado Ruby, la interpolación de cadenas en Elixir te parecerá muy familiar:

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### Concatenación de cadenas

La concatenación de cadenas usa el operador `<>`:

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
