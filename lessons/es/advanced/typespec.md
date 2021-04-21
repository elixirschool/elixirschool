---
version: 1.0.3
title: Tipos y especificaciones
---

En esta lección vamos a aprender acerca de la sintaxis de `@spec` y `@type`.
`@spec` es mas una sintaxis complementaria para escribir documentación la cual podría ser analizada por herramientas.
`@type` nos ayuda a escribir código más legible y fácil de entender.

{% include toc.html %}

## Introducción

No es poco común que quieras describir la interfaz de tu función.
Podrías usar [@doc annotation](../../basics/documentation), pero es solo información para otros desarrolladores la cual no es revisada en tiempo de compilación.
Para este propósito Elixir tiene la anotación `@spec`para describir la especificación de una función que será revisada por el compilador.

Sin embargo en algunos casos la especificación va a ser grande y complicada.

Si quisieras reducir la complejidad vas a tener que introducir una definición de tipo personalizada.
Elixir tiene la anotación `@type` para eso.
Por otro lado, Elixir es aún un lenguaje dinámico.

Eso significa que toda la información de tipo será ignorado por el compilador pero podría ser usada por otras herramientas.

## Especificación

Si tienes experiencia con Java podrías pensar acerca de la especificación como una interfaz.
La especificación define cuales deberían ser los tipos de los parámetros y el valor de retorno de una función.

Para definir los tipos de entrada y salida usamos la directiva `@spec` y la ponemos antes de la definición de la función y tomando como parámetros el nombre de la función, una lista de tipos de parámetros y luego de `::` el tipo del valor de retorno.

Revisemos un ejemplo:

```elixir
@spec sum_product(integer) :: integer
def sum_product(a) do
  [1, 2, 3]
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
end
```

Todo parece estar bien cuando llamamos a la función pero la función `Enum.sum` retorna un `number` en lugar de un `integer` como se espera según `@spec`.
Esto podría ser una fuente de errores. Existen herramientas como Dialyzer para realizar un análisis estático del código lo cual nos ayuda a encontrar este tipo de error.
Vamos a hablar acerca de ellas en otra lección.

## Tipos personalizados

Escribir especificaciones es agradable pero algunas veces nuestras funciones trabajan con estructuras mas complejas que simples números o colecciones.
En ese caso la definición de `@spec` podría ser difícil de entender y/o cambiar para otros desarrolladores.
Algunas veces las funciones necesitan tomar un número grande de parámetros o retornar data compleja.
Una lista larga de parámetros es uno de muchos potenciales errores en nuestro código.
En lenguajes orientados a objetos como Ruby o Java podríamos fácilmente definir clases que nos ayuden a resolver este problema.
Elixir no tiene clases pero debido a que es fácil de extender podemos definir nuestros propios tipos.

Por defecto Elixir contiene algunos tipos básico como `integer` o `pid`.
Puedes encontrar la lista completa de todos los tipos disponibles en la [documentación](https://hexdocs.pm/elixir/typespecs.html#types-and-their-syntax).

### Definiendo un tipo personalizado

Vamos a modificar nuestra función `sum_times` y vamos a introducir algunos parámetros extra.

```elixir
@spec sum_times(integer, %Examples{first: integer, last: integer}) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

Hemos introducido una estructura en el módulo `Examples` que contiene dos campos `first` y `last`.
Esta es una versión simple de la estructura del módulo `Range`.
Para más información acerca de `structs` podemos revisar la sección de [módulos](../../basics/modules/#structs).
Vamos a imaginar que necesitamos una especificación con la estructura `Examples` en algunos lugares.
Podría ser tedioso escribir especificaciones grandes y complejas y podría ser una fuente de errores.
Una solución para este problema es `@type`.

Elixir tiene tres directivas para tipos:

  - `@type` – simple, tipo público.
La estructura interna del tipo es pública.
  - `@typep` – el tipo es privado y solo puede ser usado en el módulo donde es definido.
  - `@opaque` – el tipo es público pero la estructura interna es privada.

Vamos a definir nuestro tipo:

```elixir
defmodule Examples do
  defstruct first: nil, last: nil

  @type t(first, last) :: %Examples{first: first, last: last}

  @type t :: %Examples{first: integer, last: integer}
end
```

Ya hemos definimos el tipo `t(first, last)` el cual es una representación de la estructura `%Examples{first: first, last: last}`.
En este punto vemos que los tipos podrían tomar parámetros pero definimos el tipo `t` también y esta vez es una representación de la estructura `%Examples{first: integer, last: integer}`.

¿Cuál es la diferencia? El primero representa la estructura `Examples` el cual tiene dos llaves que podrían ser de cualquier tipo.
El segundo representa la estructura en el cual las llaves son `integers`.
Esto significa código que se parece a esto:

```elixir
@spec sum_times(integer, Examples.t()) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

Es igual a esto:

```elixir
@spec sum_times(integer, Examples.t(integer, integer)) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

### Documentación de tipos

El último elemento del que necesitamos hablar es como documentar nuestros tipos.
Como sabemos de la lección de [documentación](../../basics/documentation) tenemos las anotaciones `@doc` y `@moduledoc` para documentar funciones y módulos.
Para documentar nuestros tipos podemos usar `@typedoc`:

```elixir
defmodule Examples do
  @typedoc """
      Type that represents Examples struct with :first as integer and :last as integer.
  """
  @type t :: %Examples{first: integer, last: integer}
end
```

La directiva `@typedoc` es similar a `@doc` y `@moduledoc`.
