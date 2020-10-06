---
version: 0.9.1
title: Almacenamiento de términos de Erlang (ETS)
---

Almacenamiento de términos de Erlang, comúnmente conocido como ETS, es un potente motor de almacenamiento incorporado en OTP y disponible para utilizar en Elixir. En esta lección vamos a ver cómo interactuar con ETS y cómo se pueden emplear en nuestras aplicaciones.

{% include toc.html %}

## Descripción General

ETS es un robusto almacén en memoria para objetos Elixir y Erlang que viene incluido. ETS es capaz de almacenar grandes cantidades de datos y ofrece un tiempo constante para el acceso a datos.

Las tablas en ETS son creadas y son propiedad de los procesos individuales. Cuando un proceso propietario termina, sus tablas son destruidas. Por defecto ETS esta limitado a 1400 tablas por nodo.

## Creando Tablas

Las tablas son creadas con `new/2`, aceptando un nombre de tabla y un conjunto de opciones, este devuelve un identificador de tabla que se puede utilizar en las operaciones subsiguientes.

Para nuestro ejemplo vamos a crear una tabla para almacenar y buscar usuarios por su apodo:

```elixir
iex> table = :ets.new(:user_lookup, [:set, :protected])
8212
```

Al igual que con GenServers, hay una manera de acceder a las tablas de ETS por su nombre en lugar de su identificador. Para hacer esto necesitamos incluir `:named_table` y podemos acceder a nuestra tabla directamente por su nombre:

```elixir
iex> :ets.new(:user_lookup, [:set, :protected, :named_table])
:user_lookup
```

### Tipos de Tablas

Existen cuatro tipos de tablas disponibles en ETS:

+ `set` — Este es el tipo de tabla por defecto.  Un valor por clave.  Las claves son únicas.
+ `ordered_set` — Similar a `set` pero ordenadas por los términos Erlang/Elixir.  Es importante tener en cuenta que la comparación de clave es diferente dentro de `ordered_set`.  Las llaves no deben coincidir siempre y cuando se comparen igualmente, tanto 1 y 1.0 se consideran iguales.
+ `bag` — Muchos objetos por claves pero solo una instancia de cada objeto por clave.
+ `duplicate_bag` — Muchos objetos por clave, duplicados permitidos.

### Controles de Acceso

El control de acceso en ETS es similar al control de acceso con módulos:

+ `public` — Lectura/Escritura disponible para todos los procesos.
+ `protected` — Lectura  disponible para todos los procesos.  Escritura disponible solo para el proceso propietario. Este es el valor predeterminado.
+ `private` — Lectura/Escritura limitada al proceso propietario.

## Insertando Datos

ETS no tiene esquemas, la única limitación es que los datos deben ser almacenados como una tupla cuyo primer elemento es la clave. Para agregar nuevos datos podemos usar `insert/2`:

```elixir
iex> :ets.insert(:user_lookup, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
true
```

Cuando usamos `insert/2` con un `set` o `ordered_set` los datos existentes serán reemplazados. Para prevenir esto existe `insert_new/2` que devuelve `false` para claves existentes:

```elixir
iex> :ets.insert_new(:user_lookup, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
false
iex> :ets.insert_new(:user_lookup, {"3100", "", ["Elixir", "Ruby", "JavaScript"]})
true
```

## Recuperación de Datos

ETS nos ofrece algunas maneras convenientes y flexibles para recuperar los datos almacenados. Vamos a ver cómo recuperar los datos por clave y por medio de diferentes formas de coincidencia de patrones.


El más eficiente, e ideal, método de recuperación es la búsqueda de claves. Si bien es útil, el método de concordancia itera a través de la tabla y debe utilizarse con moderación, especialmente en caso de grandes conjuntos de datos.

### Búsqueda de claves

Dada una clave, podemos utilizar `lookup/2` para recuperar todos los registros con esa clave:

```elixir
iex> :ets.lookup(:user_lookup, "doomspork")
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

### Concordancia Simple

ETS fue construido para Erlang, así que tenga cuidado, las variables de comparación pueden sentirse un  _poco_ anticuadas.

Para especificar una variable en nuestro juego usamos los átomos `:"$1"`, `:"$2"`, `:"$3"`, y así sucesivamente; el número de variable refleja la posición de los resultados y no la posición del juego. Para valores que no estamos interesados usamos la `:_` variable.

Los valores también se pueden utilizar en emparejamiento, pero sólo las variables se devolverán como parte de nuestro resultado. Vamos a poner todos los elementos y ver cómo funciona:

```elixir
iex> :ets.match(:user_lookup, {:"$1", "Sean", :_})
[["doomspork"]]
```

Veamos otro ejemplo para ver cómo las variables influyen en el orden de la lista resultante:

```elixir
iex> :ets.match(:user_lookup, {:"$99", :"$1", :"$3"})
[["Sean", ["Elixir", "Ruby", "Java"], "doomspork"],
 ["", ["Elixir", "Ruby", "JavaScript"], "3100"]]
```

¿Qué pasa si queremos que nuestro objeto original no sea una lista? Podemos usar `match_object/2`, que independientemente de las variables devuelve todo nuestro objeto:

```elixir
iex> :ets.match_object(:user_lookup, {:"$1", :_, :"$3"})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]

iex> :ets.match_object(:user_lookup, {:_, "Sean", :_})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

### Búsqueda Avanzada

Hemos aprendido acerca de los casos de los juegos sencillos pero ¿que si queremos algo más parecido a una consulta SQL? Afortunadamente hay una sintaxis más robusta disponible para nosotros. Para buscar nuestros datos con `select/2` necesitamos construir una lista de tuplas con tres aridad. Estas tuplas representan nuestro patrón, cero o más guardias, y un formato de valor de retorno.

Nuestras variables de emparejamiento y dos nuevas variables, `:"$$"` y `:"$_"` pueden ser usados para construir el valor de retorno. Estas nuevas variables son accesos directos para el formato del resultado; `:"$$"` Obtiene resultados como listas y `:"$_"` los objetos de datos originales.

Vamos a tomar uno de nuestros anteriores ejemplos `match/2` y convertirlo en un `select/2`:

```elixir
iex> :ets.match_object(:user_lookup, {:"$1", :_, :"$3"})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]

{% raw %}iex> :ets.select(:user_lookup, [{{:"$1", :_, :"$3"}, [], [:"$_"]}]){% endraw %}
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"spork", 30, ["ruby", "elixir"]}]
```

Aunque `select/2` permite un mayor control sobre qué y cómo recuperar los registros, la sintaxis es bastante desagradable y sólo lo será aún más. Para manejar esto el módulo ETS incluye `fun2ms/1`, para convertir las funciones en match_specs. Con `fun2ms/1` podemos crear consultas utilizando una función de sintaxis familiar.

Vamos a usar `fun2ms/1` y `select/2` para encontrar todos los nombres de usuario con 2 o más lenguajes:

```elixir
iex> fun = :ets.fun2ms(fn {username, _, langs} when length(langs) > 2 -> username end)
{% raw %}[{{:"$1", :_, :"$2"}, [{:>, {:length, :"$2"}, 2}], [:"$1"]}]{% endraw %}

iex> :ets.select(:user_lookup, fun)
["doomspork", "3100"]
```

¿Quieres saber más acerca de especificación partido? Echa un vistazo a la documentación oficial de Erlang [match_spec](http://www.erlang.org/doc/apps/erts/match_spec.html).

## Eliminando Datos

### Removiendo Registros

Eliminar términos es tan sencillo como `insert/2` y `lookup/2`. Con `delete/2` sólo necesitamos nuestra tabla y la clave. Esto elimina la clave y sus valores:

```elixir
iex> :ets.delete(:user_lookup, "doomspork")
true
```

### Removiendo Tablas

Las tablas ETS no son basura recolectada al menos el padre sea terminado. A veces puede ser necesario eliminar una tabla completa sin necesidad de terminar el proceso propietario. Para ello podemos utilizar `delete/1`:

```elixir
iex> :ets.delete(:user_lookup)
true
```

## Ejemplos de uso de ETS

Debido a lo que hemos aprendido previamente vamos a poner todo junto y construir una cache sencilla para operaciones costosas. Vamos a implementar una funcion `get/4` para tomar un módulo, función, argumentos y opciones. Por ahora la única opción de la que nos preocuparemos es `:ttl`.

Para este ejemplo asumiremos que las tablas ETS han sido creadas como parte de otro proceso, como un supervisor:

```elixir
defmodule SimpleCache do
  @moduledoc """
  A simple ETS based cache for expensive function calls.
  """

  @doc """
  Retrieve a cached value or apply the given function caching and returning
  the result.
  """
  def get(mod, fun, args, opts \\ []) do
    case lookup(mod, fun, args) do
      nil ->
        ttl = Keyword.get(opts, :ttl, 3600)
        cache_apply(mod, fun, args, ttl)

      result ->
        result
    end
  end

  @doc """
  Lookup a cached result and check the freshness
  """
  defp lookup(mod, fun, args) do
    case :ets.lookup(:simple_cache, [mod, fun, args]) do
      [result | _] -> check_freshness(result)
      [] -> nil
    end
  end

  @doc """
  Compare the result expiration against the current system time.
  """
  defp check_freshness({mfa, result, expiration}) do
    cond do
      expiration > :os.system_time(:seconds) -> result
      :else -> nil
    end
  end

  @doc """
  Apply the function, calculate expiration, and cache the result.
  """
  defp cache_apply(mod, fun, args, ttl) do
    result = apply(mod, fun, args)
    expiration = :os.system_time(:seconds) + ttl
    :ets.insert(:simple_cache, {[mod, fun, args], result, expiration})
    result
  end
end
```

Para demostrar la caché vamos a utilizar una función que devuelve la hora del sistema y un TTL de 10 segundos. Como se verá en el siguiente ejemplo, obtenemos el resultado almacenado en caché hasta que el valor haya expirado:

```elixir
defmodule ExampleApp do
  def test do
    :os.system_time(:seconds)
  end
end

iex> :ets.new(:simple_cache, [:named_table])
:simple_cache
iex> ExampleApp.test
1451089115
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089119
iex> ExampleApp.test
1451089123
iex> ExampleApp.test
1451089127
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089119
```

Después de 10 segundos si intentamos de nuevo, deberíamos obtener resultados actualizados:

```elixir
iex> ExampleApp.test
1451089131
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089134
```

Como se puede ver, ahora somos capaces de implementar una caché escalable y rápida sin ningún tipo de dependencias externas, y este es sólo uno de los muchos usos para ETS.

## ETS basado en disco

Ahora sabemos que ETS es para almacenamiento de términos en memoria, ¿pero que si necesitamos almacenamiento basado en disco? Para eso tenemos Almacenamiento de Términos Basado en Disco o DETS para abreviar. Las APIs de ETS y DETS son intercambiables con la excepción de cómo se crean las tablas. DETS depende de `open_file/2` y no requiere la opcion `:named_table`:

```elixir
iex> {:ok, table} = :dets.open_file(:disk_storage, [type: :set])
{:ok, :disk_storage}
iex> :dets.insert_new(table, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
true
iex> select_all = :ets.fun2ms(&(&1))
[{:"$1", [], [:"$1"]}]
iex> :dets.select(table, select_all)
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

Si sale de `iex` y buscas en su directorio local, verás un nuevo archivo `disk_storage`:

```shell
$ ls | grep -c disk_storage
1
```

Una última cosa a tener en cuenta es que DETS no soporta `ordered_set` como ETS, solamente `set`, `bag`, y `duplicate_bag`.
