---
version: 0.9.0
title: Operador Pipe
---

El operador pipe `|>` pasa el resultado de una expresión como el primer parámetro de otra expresión.

{% include toc.html %}

## Introducción

La programación puede ser desordenada. De hecho, las llamadas de función que están contenidas dentro de otra función se vuelven muy difíciles de seguir. Por ejemplo, tome las siguientes funciones anidadas en consideración:


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

Si la función recibe más de 1 parámetro, asegúrese de usar paréntesis. Honestamente no importa mucho en elixir, pero es importante para otros programadores que pueden malinterpretar nuestro código. Si en el tercer ejemplo eliminamos los paréntesis de `String.ends_with?`, tendríamos la siguiente advertencia.

```shell
iex> "elixir" |> String.ends_with? "ixir"
warning: parentheses are required when piping into a function call. For example:

  foo 1 |> bar 2 |> baz 3

is ambiguous and should be written as

  foo(1) |> bar(2) |> baz(3)

true
```
