---
version: 1.1.0
title: Comprensiones
---

La comprensión de listas es azúcar sintáctica para iterar a través de enumerables en Elixir. En esta lección veremos como podemos usar comprensiones para iteración y generación.

{% include toc.html %}

## Lo esencial

Las comprensiones algunas veces pueden ser usadas para producir declaraciones mas concisas para iterar sobre `Enum` y `Stream`. Vamos a empezar viendo una comprensión simple y descomponiéndola.

```elixir
iex> list = [1, 2, 3, 4, 5]
iex> for x <- list, do: x * x
[1, 4, 9, 16, 25]
```

La primera cosa que notamos es el uso de `for` y un generador. ¿Qué es un generador? Generadores son las expresiones `x <- [1, 2, 3, 4]` encontradas en las comprensión de listas. Son responsables de generar el siguiente valor.

Por suerte para nosotros, las comprensiones no están limitadas a las listas; de hecho ellas pueden trabajar con cualquier enumerable.

```elixir
# Keyword Lists
iex> for {_key, val} <- [one: 1, two: 2, three: 3], do: val
[1, 2, 3]

# Maps
iex> for {k, v} <- %{"a" => "A", "b" => "B"}, do: {k, v}
[{"a", "A"}, {"b", "B"}]

# Binaries
iex> for <<c <- "hello">>, do: <<c>>
["h", "e", "l", "l", "o"]
```

Como muchas otras cosas en Elixir, los generadores dependen de la coincidencia de patrones para comparar su conjunto de entrada con el lado izquierdo de la variable. En el caso de que la coincidencia no sea encontrada el valor es ignorado:

```elixir
iex> for {:ok, val} <- [ok: "Hello", error: "Unknown", ok: "World"], do: val
["Hello", "World"]
```

Es posible usar múltiples generadores como iteraciones anidadas:

```elixir
iex> list = [1, 2, 3, 4]
iex> for n <- list, times <- 1..n do
...>   String.duplicate("*", times)
...> end
["*", "*", "**", "*", "**", "***", "*", "**", "***", "****"]
```

Para ilustrar mejor la iteración que esta ocurriendo vamos a usar `IO.puts` para mostrar los dos valores generados:

```elixir
iex> for n <- list, times <- 1..n, do: IO.puts "#{n} - #{times}"
1 - 1
2 - 1
2 - 2
3 - 1
3 - 2
3 - 3
4 - 1
4 - 2
4 - 3
4 - 4
```

Las comprensiones de listas son azúcar sintáctica y solo deberían ser usadas cuando es apropiado.

## Filtros

Puedes pensar en los filtros como un tipo de guardas para las comprensiones. Cuando un valor filtrado retorna `false` o `nil` este es excluido desde el final de la lista. Vamos a iterar un rango y solo preocuparnos por los números pares. Vamos a usar la función `is_even/1` del módulo `Integer` para verificar si el valor es par o no.

```elixir
import Integer
iex> for x <- 1..10, is_even(x), do: x
[2, 4, 6, 8, 10]
```

Como con los generadores podemos usar múltiples filtros. Vamos a expandir nuestro rango y filtrar solo los valores que son pares y divisibles por 3.

```elixir
import Integer
iex> for x <- 1..100,
...>   is_even(x),
...>   rem(x, 3) == 0, do: x
[6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 78, 84, 90, 96]
```

## Usando `:into`

¿Qué pasa si queremos producir algo que no es una lista?. Con la opción `:into` podemos hacer justo eso. Como una regla de oro, `:into` acepta cualquier estructura que implementa el protocolo `Collectable`.

Usando `:into` vamos a crear un mapa desde una lista de palabras clave:

```elixir
iex> for {k, v} <- [one: 1, two: 2, three: 3], into: %{}, do: {k, v}
%{one: 1, three: 3, two: 2}
```

Dado que los binarios son coleccionables podemos usar comprensión de listas e `:into` para crear cadenas:

```elixir
iex> for c <- [72, 101, 108, 108, 111], into: "", do: <<c>>
"Hello"
```

¡Eso es todo! La comprensión de listas son una forma sencilla de iterar a través de colecciones de manera concisa.
