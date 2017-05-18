---
version: 1.0.1
layout: page
title: Colecciones
category: basics
order: 2
lang: es
---

Listas, tuplas, listas de palabras clave y mapas.

{% include toc.html %}

## Listas

Las listas son simples colecciones de valores. Estas pueden incluir múltiples tipos; las listas pueden incluir valores no únicos:

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir implementa las listas como listas enlazadas. Esto significa que acceder a la longitud de la lista es una operación `O(n)`. Por esta razón, normalmente es más rápido agregar un elemento al inicio que al final:

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> ["π"] ++ list
["π", 3.14, :pie, "Apple"]
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```


### Concatenación de listas

La concatenación de listas usa el operador `++/2`:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

Una anotación acerca del formato (`++/2`) utilizado en Elixir (y Erlang, sobre el que está construido Elixir), el nombre de una función u operador tiene dos componentes: El nombre que le das (en este caso `++`) y su _aridad_. Aridad es una parte básica al hablar de código de Elixir (y Erlang). Es el número de argumentos que una función dada tomará (dos en este caso). Aridad y el nombre de la función combinadas con una diagonal. Hablaremos más acerca de esto posteriorente, este conocimiento te ayudará a entender la notación por ahora.

### Sustracción de listas

El soporte para sustracción es provisto por el operador `--/2`; es seguro sustraer un valor que no existe:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

Ten en cuenta los valores duplicados. Para cada elemento de la derecha, la primera ocurrencia de la misma se retira de la izquierda.

```elixir
iex> [1,2,2,3,2,3] -- [1,2,3,2]
[2, 3]
```

**Nota:** Esto utiliza [comparación estricta](../basics/#comparison) para coincidir los valores.

### Cabeza/Cola

Cuando usas listas es común trabajar con la cabeza y la cola de la lista. La cabeza es el primer elemento de la lista y la cola son los elementos restantes. Elixir provee dos funciones útiles, `hd` y `tl`, para trabajar con estas partes:

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

Además de la funciones citadas, puedes usar [coincidencia de patrones](../pattern-matching/) y el operador tubería `|` para dividir una lista en cabeza y cola; veremos este patrón en futuras lecciones:

```elixir
iex> [head | tail] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> head
3.14
iex> tail
[:pie, "Apple"]
```

## Tuplas

Las tuplas son similares a las listas pero son guardadas de manera contigua en memoria. Esto permite acceder a su longitud de forma rápida pero hace su modificación costosa; la nueva tupla debe ser copiada entera en memoria. Las tuplas son definidas con llaves.

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

Es común para las tuplas ser usadas como un mecanismo que retorna información adicional de funciones; la utilidad de esto será mas aparente cuando entremos en [coincidencia de patrones](../pattern-matching/):

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Listas de palabras clave

Las listas de palabras clave y los mapas son colecciones asociativas de Elixir. En Elixir, una lista de palabras clave es una lista especial de tuplas de dos elementos cuyo primer elemento es un átomo; estas comparten el rendimiento de las listas:

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

Las tres características resaltantes de las listas de palabras clave son:

+ Las claves son átomos.
+ Las claves están ordenadas.
+ Las claves no son únicas.

Por estas razones las listas de palabras clave son comúnmente usadas para pasar opciones a funciones.

## Mapas

A diferencia de las listas de palabras clave estos permiten claves de cualquier tipo y no siguen un orden. Puedes definir un mapa con la sintaxis `%{}`:

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

A partir de Elixir 1.2 es posible utilizar variables como claves en mapas.

```elixir
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
```

Si un elemento duplicado es agregado al mapa, este reemplazará el valor anterior:

```elixir
iex> %{:foo => "bar", :foo => "hello world"}
%{foo: "hello world"}
```

Como podemos ver de la salida anterior, hay una sintaxis especial para los mapas que solo contienen átomos como claves:

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}

iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```

<<<<<<< c78e7bb55a316cc967792b89c188156bd50d6b27
## Diccionarios

En Elixir, ambos, listas de palabras claves y mapas implementan el módulo `Dict`; tales se conocen colectivamente como diccionarios. Si necesitas construir tu propio almacenamiento clave-valor, implementar el módulo `Dict` es un buen lugar para empezar.

El [módulo `Dict`](https://hexdocs.pm/elixir/#!Dict.html) provee un número de funciones útiles para interactuar y manipular esos diccionarios:
=======
Otra característica interesante de los mapas es que poseen su propia sintaxis para actualizar y acceder los átomos como clave.
>>>>>>> Update es collections translation to v1.0.0

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{map | foo: "baz"}
%{foo: "baz", hello: "world"}
iex> map.hello
"world"
```
