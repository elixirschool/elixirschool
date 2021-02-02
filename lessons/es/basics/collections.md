%{
  version: "1.3.1",
  title: "Colecciones",
  excerpt: """
  Listas, tuplas, listas de palabras clave y mapas.
  """
}
---

## Listas

Las listas son simples colecciones de valores, las cuales pueden incluir múltiples tipos de datos; las listas pueden incluir valores no únicos:

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir implementa las colecciones como listas enlazadas.
Esto significa que acceder al largo de la lista es una operación que se ejecutará en tiempo lineal (`O(n)`).
Por esta razón, normalmente es más rápido agregar un elemento al inicio que al final:

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
# Agregar elemento al inicio de la lista (rápido)
iex> ["π" | list]
["π", 3.14, :pie, "Apple"]
# Agregar elemento al final de la lista (lento)
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```


### Concatenación de listas

La concatenación de listas usa el operador `++/2`:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

Una aclaración acerca de la notación utilizada arriba (`++/2`):
En Elixir (y Erlang, sobre el cual Elixir está construido), el nombre de una función u operador tiene dos componentes: el nombre en sí (en este caso `++`) y su _aridad_.
La aridad es un concepto fundamental al hablar de código en Elixir y Erlang.
Es el número de argumentos que una función recibe (dos, en este caso).
El nombre y la aridad están unidos por una barra (`/`). Hablaremos más acerca de esta más adelante; conocer esto te ayudará a entender la notación por el momento.

### Sustracción de listas

La sustracción se realiza a través del operador `--/2`. Es seguro sustraer un valor que no exista:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

Tenga en cuenta los valores duplicados.
Para cada elemento de la lista derecha, la primera ocurrencia se retira de la lista izquierda.

```elixir
iex> [1,2,2,3,2,3] -- [1,2,3,2]
[2, 3]
```

**Nota:** La sustracción de listas utiliza [comparación estricta](../basics/#comparación) para coincidir los valores. Por Ejemplo:
```elixir
iex> [2] -- [2.0]
[2]
iex> [2.0] -- [2.0]
[]
```

### Cabeza / Cola

Cuando usamos listas es común trabajar con la cabeza y la cola.
La cabeza es el primer elemento de la lista, mientras que la cola es una lista que contiene a los elementos restantes.
Elixir ofrece dos funciones útiles, `hd` y `tl`, para trabajar con estas partes. `hd` es la abreviatura de "head" (cabeza en inglés), y `tl` es la abreviatura de "tail" (cola):

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

Además de las funciones anteriormente mencionadas, puedes hacer uso de la [coincidencia de patrones](../pattern-matching/) y del operador _cons_ `|` para partir una lista en cabeza y cola. Aprenderemos más acerca de este patrón en futuras lecciones:

```elixir
iex> [head | tail] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> head
3.14
iex> tail
[:pie, "Apple"]
```

## Tuplas

Las tuplas son similares a las listas, pero son almacenadas de manera contigua en la memoria.
Esto permite acceder a su longitud de forma rápida, pero hace su modificación costosa; debido a que la nueva tupla debe ser copiada de nuevo en la memoria.
Las tuplas son definidas mediante el uso de llaves:

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

Es común que utilicemos las tuplas como un mecanismo que retorna información adicional de funciones; la utilidad de esto será más evidente cuando aprendamos sobre [coincidencia de patrones](../pattern-matching/):

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Listas de palabras clave

Las listas de palabras clave y los mapas son las colecciones asociativas de Elixir.
En Elixir, una lista de palabras clave es una lista especial de tuplas de dos elementos, cuyos primeros elementos son átomos; éstas tienen el mismo rendimiento que las listas:

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

Las tres características de las listas de palabras clave que resaltan su importancia son:

+ Las claves son átomos.
+ Las claves están ordenadas.
+ Las claves pueden no ser únicas.

Es por esto que las listas de palabras clave son comúnmente usadas para pasar opciones a funciones.

## Mapas

En Elixir, los mapas son el tipo de datos utilizado por excelencia para almacenar pares de clave/valor.
A diferencia de las listas de palabras clave, los mapas permiten claves de cualquier tipo y no mantienen un orden.
Puedes definir un mapa con la sintaxis `%{}`:

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

A partir de Elixir 1.2, se pueden usar variables como claves:

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

Como podemos ver en la salida anterior, hay una sintaxis especial para los mapas que sólo contienen átomos como claves:

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```

Adicionalmente, hay una sintaxis especial para acceder a las claves que son átomos:

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> map.hello
"world"
```

Otra característica interesante de los mapas es que poseen su propia sintaxis para realizar operaciones de actualización (nota: esto crea un nuevo mapa):

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{map | foo: "baz"}
%{foo: "baz", hello: "world"}
```

**Nota**: ¡esta sintaxis solo puede usarse para actualizar una clave que ya existe en el mapa! Si la clave no existe, se lanzará un `KeyError` (Error de Clave, en inglés).

Para crear una nueva clave, en vez utiliza [`Map.put/3`](https://hexdocs.pm/elixir/Map.html#put/3):

```elixir
iex> map = %{hello: "world"}
%{hello: "world"}
iex> %{map | foo: "baz"}
** (KeyError) key :foo not found in: %{hello: "world"}
    (stdlib) :maps.update(:foo, "baz", %{hello: "world"})
    (stdlib) erl_eval.erl:259: anonymous fn/2 in :erl_eval.expr/5
    (stdlib) lists.erl:1263: :lists.foldl/3
iex> Map.put(map, :foo, "baz")
%{foo: "baz", hello: "world"}
```
