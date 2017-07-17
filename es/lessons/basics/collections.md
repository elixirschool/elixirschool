---
version: 0.9.0
title: Colecciones
---

Listas, tuplas, listas de palabras clave, mapas, diccionarios y combinadores funcionales

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

### Sustracción de listas

El soporte para sustracción es provisto por el operador `--/2`; es seguro sustraer un valor que no existe:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

Tenga en cuenta los valores duplicados. Para cada elemento de la derecha, la primera ocurrencia de la misma se retira de la izquierda.

```elixir
iex> [1,2,2,3,2,3] -- [1,2,3,2]
[2, 3]
```

### Cabeza/Cola

Cuando usas listas es común trabajar con la cabeza y la cola de la lista. La cabeza es el primer elemento de la lista y la cola son los elementos restantes. Elixir provee dos funciones útiles, `hd` y `tl`, para trabajar con estas partes:

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

Además de la funciones citadas, puedes usar el operador tubería `|`; veremos este patrón en futuras lecciones:

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

Es común para las tuplas ser usadas como un mecanismo que retorna información adicional de funciones; la utilidad de esto será mas aparente cuando entremos en la coincidencia de patrones:

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Listas de palabras clave

Las listas de palabras clave y los mapas son colecciones asociativas de Elixir; ambas implementan el módulo `Dict`. En Elixir, una lista de palabras clave es una lista especial de tuplas cuyo primer elemento es un átomo; ellos comparten el rendimiento de las listas:

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

## Diccionarios

En Elixir, ambos, listas de palabras claves y mapas implementan el módulo `Dict`; tales se conocen colectivamente como diccionarios. Si necesitas construir tu propio almacenamiento clave-valor, implementar el módulo `Dict` es un buen lugar para empezar.

El [módulo `Dict`](https://hexdocs.pm/elixir/#!Dict.html) provee un número de funciones útiles para interactuar y manipular esos diccionarios:

```elixir
# keyword lists
iex> Dict.put([foo: "bar"], :hello, "world")
[hello: "world", foo: "bar"]

# maps
iex> Dict.put(%{:foo => "bar"}, "hello", "world")
%{:foo => "bar", "hello" => "world"}

iex> Dict.has_key?(%{:foo => "bar"}, :foo)
true
```
