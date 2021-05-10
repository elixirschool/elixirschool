---
version: 1.0.1
title: Operador Pipe
---

El operador pipe `|>` pasa el resultado de una expresión como el primer parámetro de otra expresión.

{% include toc.html %}

## Introducción

La programación puede ser desordenada.
De hecho tan desordenada que las llamadas de función pueden estar tan contenidas que sean difícil de entender.

Por ejemplo, toma en consideración las siguientes funciones anidadas:

```elixir
foo(bar(baz(nueva_function(otra_function()))))
```

Aquí, pasamos el valor de `otra_function/1` a `nueva_function/1`, y de `nueva_function/1` a `baz/1`, `baz/1` a `bar/1`, y finalmente el resultado de `bar/1` a `foo/1`.
Elixir adopta un enfoque pragmático a este caos sintáctico al darnos el operador pipe.
El operador pipe que luce así `|>` *toma el resultado de una expresión, y se lo pasa a la siguiente*.
Vamos a echar otro vistazo al código anterior reescrito con el operador pipe.

```elixir
otra_function() |> nueva_function() |> baz() |> bar() |> foo()
```

El operador lleva el resultado de la izquierda, y lo pasa a la derecha.

## Ejemplos

Para este grupo de ejemplos, usaremos el módulo String de elixir.

- Separar Cadenas (Tokenize String)

```elixir
iex> "Elixir language" |> String.split()
["Elixir", "language"]
```

- Mayúsculas a todos los caracteres (Uppercase all the tokens)

```elixir
iex> "Elixir language" |> String.upcase() |> String.split()
["ELIXIR", "LANGUAGE"]
```

- Comparar terminación de una cadena (Check ending)

```elixir
iex> "elixir" |> String.ends_with?("ixir")
true
```

## Buenas Prácticas

Si la aridad de una función es mayor a 1, asegurate de usar paréntesis.
Esto no importa mucho en Elixir, pero es importante para otros programadores que pueden malinterpretar tu código.
Sin embargo, este si importa para el operador pipe.
Por ejemplo, si en el tercer ejemplo eliminamos los paréntesis de `String.ends_with?`, tendríamos la siguiente advertencia.

```elixir
iex> "elixir" |> String.ends_with? "ixir"
warning: parentheses are required when piping into a function call. For example:

  foo 1 |> bar 2 |> baz 3

is ambiguous and should be written as

  foo(1) |> bar(2) |> baz(3)

true
```
