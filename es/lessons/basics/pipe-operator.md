---
layout: page
title: Operador Pipe
category: basics
order: 6
lang: es
---

El operador pipe `|>` pasa el resultado de una expresión como el primer parámetro de otra expresión.

## Tabla de Contenidos

- [Introducción](#introduction)
- [Ejemplos](#examples)
- [Buenas Prácticas](#best-practices)

## Introducción

La programación puede ser desordenada. De hecho, los llamados de función que están contenidos dentro de otra función se vuelven muy difíciles de seguir. Por ejemplo, tome las siguientes funciones anidadas en consideración:


```elixir
foo(bar(baz(nueva_function(otra_function()))))
```

Aquí, pasamos el valor de `otra_function/1` a `nueva_function/1`, y de `nueva_function/1` a `baz/1`, `baz/1` a `bar/1`, y finalmente el resultado de `bar/1` a `foo/1`. Elixir adopta un enfoque pragmático a este caos sintáctico al darnos el operador pipe. El operador pipe que luce así `|>` *toma el resultado de una expresión, y se lo pasa a la siguiente*. Vamos a echar otro vistazo al código anterior reescrito con el operador pipe.

```elixir
otra_function() |> nueva_function() |> baz() |> bar() |> foo()
```

El operador lleva el resultado de la izquierda, y lo pasa a la derecha.

## Ejemplos

Para este grupo de ejemplos, usaremos el módulo String de elixir.

- Separar Cadenas (Tokenize String)

```shell
iex> "Elixir language" |> String.split
["Elixir", "language"]
```

- Mayúsculas a todos los caracteres (Uppercase all the tokens)

```shell
iex> "Elixir language" |> String.split |> Enum.map( &String.upcase/1 )
["ELIXIR", "LANGUAGE"]
```

- Comparar terminación de una cadena (Check ending)

```shell
iex> "elixir" |> String.ends_with?("ixir")
true
```

## Buenas Prácticas

Si la función recibe más de 1 parámetro, asegúrese de usar paréntesis. Honestamente no importa mucho en elixir, pero es importante para otros programadores que pueden malinterpretar nuestro código. Si en el segundo ejemplo removemos los paréntesis de `Enum.map/2`, tendríamos la siguiente advertencia.

```shell
iex> "Elixir language" |> String.split |> Enum.map &String.upcase/1
iex: warning: you are piping into a function call without parentheses, which may be ambiguous. Please wrap the function you are piping into in parenthesis. For example:

foo 1 |> bar 2 |> baz 3

Should be written as:

foo(1) |> bar(2) |> baz(3)

["ELIXIR", "LANGUAGE"]
```
