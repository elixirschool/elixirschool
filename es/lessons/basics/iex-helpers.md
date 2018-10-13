---
version: 1.0.1
title: Ayudantes de IEx
---

{% include toc.html %}

## Visión general

Cuando empiezas a trabajar en Elixir, IEx es tu mejor amigo.
Es un REPL, pero tiene muchas características avanzadas que pueden hacer la vida más fácil cuando se explora un nuevo código o se desarrolla un trabajo propio a medida que se avanza.
Hay un montón de ayudantes incorporados que repasaremos en esta lección.

### Autocompletar

Cuando trabaje en el shell, a menudo podría encontrarse usando un nuevo módulo con el que no está familiarizado.
Para entender algo de lo que está disponible para usted, la funcionalidad de autocompletar es maravillosa.
Simplemente escriba el nombre del módulo seguido de ``.` y luego pulse `Tab`:

```elixir
iex> Map. # pulsa Tab
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
replace!/3           replace/3            split/2
take/2               to_list/1            update!/3
update/4             values/1
```

¡Y ahora sabemos las funciones que tenemos y su aridez!

### `.iex.exs`

Cada vez que IEx se inicia buscará un archivo de configuración `.iex.exs`. Si no está presente en el directorio actual, entonces el directorio raíz del usuario (`~/.iex.exs`) será usado como respaldo.

Las opciones de configuración y el código definido en este archivo estarán disponibles cuando se inicie el shell de IEx. Por ejemplo, si queremos algunas funciones de ayuda disponibles en IEx, podemos abrir `.iex.exs` y hacer algunos cambios.

Empecemos por añadir un módulo con algunas funciones de ayuda:

```elixir
defmodule IExHelpers do
  def whats_this?(term) when is_nil(term), do: "Type: Nil"
  def whats_this?(term) when is_binary(term), do: "Type: Binary"
  def whats_this?(term) when is_boolean(term), do: "Type: Boolean"
  def whats_this?(term) when is_atom(term), do: "Type: Atom"
  def whats_this?(_term), do: "Type: Unknown"
end
```

Ahora cuando ejecutemos IEx tendremos el módulo IExHelpers disponible desde el principio. Abre IEx y probemos nuestros nuevos ayudantes:

```elixir
$ iex
{{ site.erlang.OTP }} [{{ site.erlang.erts }}] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex> IExHelpers.whats_this?("a string")
"Type: Binary"
iex> IExHelpers.whats_this?(%{})
"Type: Unknown"
iex> IExHelpers.whats_this?(:test)
"Type: Atom"
```

Como podemos ver no necesitamos hacer nada especial para requerir o importar nuestros ayudantes, IEx se encarga de eso por nosotros.

### `h`

El `h` es una de las herramientas más útiles que nos da nuestra cáscara de elixir.
Gracias al fantástico soporte de documentación de primera clase del idioma, se puede acceder a los documentos de cualquier código mediante este asistente.
Verlo en acción es simple:

```elixir
iex> h Enum
                                      Enum

Proporciona un conjunto de algoritmos que enumeran sobre enumerables según el protocolo Enumerable.

┃ iex> Enum.map([1, 2, 3], fn(x) -> x * 2 end)
┃ [2, 4, 6]

Algunos tipos particulares, como los mapas, producen un formato específico de enumeración. Para
por ejemplo, el argumento es siempre una tupla {clave, valor} para mapas:

┃ iex> map = %{a: 1, b: 2}
┃ iex> Enum.map(map, fn {k, v} -> {k, v * 2} end)
┃ [a: 2, b: 4]

Tenga en cuenta que las funciones del módulo Enum están ansiosas: siempre inician la función
enumeración de lo enumerable dado. El módulo Stream permite una enumeración perezosa
de enumerables y proporciona flujos infinitos.

Dado que la mayoría de las funciones de Enum enumeran el conjunto enumerable y
devuelve una lista como resultado, los flujos infinitos necesitan ser usados con cuidado con tal
ya que pueden funcionar para siempre. Por ejemplo:

┃ Enum.each Stream.cycle([1, 2, 3]), &IO.puts(&1)
```

Y ahora podemos incluso combinar esto con las características de autocompletar de nuestro shell.
Imagínate que estábamos explorando Map por primera vez:

```elixir
iex> h Map
                                      Map

Conjunto de funciones para trabajar con mapas.

Los mapas son almacenes de valor clave donde las claves pueden ser de cualquier valor y se comparan utilizando
el operador del partido (====). Los mapas se pueden crear con el formulario especial %{} definido
en el módulo Kernel.SpecialForms.

iex> Map.
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
split/2              take/2               to_list/1
update!/3            update/4             values/1

iex> h Map.merge/2
                             def merge(map1, map2)

Fusiona dos mapas en uno.

Todas las teclas del mapa2 se añadirán al mapa1, anulando cualquier tecla existente.

Si tiene una estructura y desea fusionar un conjunto de claves en la estructura,
no utilice esta función, ya que fusionaría todas las teclas del lado derecho con la tecla
struct, incluso si la clave no forma parte de la struct. En su lugar, utilice
Kernel.struct/2.

Ejemplos

┃ iex> Map.merge(%{a: 1, b: 2}, %{a: 3, d: 4})
┃ %{a: 3, b: 2, d: 4}
```

Como podemos ver, no sólo pudimos encontrar qué funciones estaban disponibles como parte del módulo, sino que también pudimos acceder a documentos de funciones individuales, muchos de los cuales incluyen ejemplos de uso.

### `i`

Pongamos en práctica algunos de nuestros nuevos conocimientos mediante el empleo de `h` para aprender un poco más sobre el `i` helper:

```elixir
iex> h i

                                  def i(term)

Imprime información sobre el tipo de datos dado.

iex> i Map
Term
  Map
Data type
  Atom
Module bytecode
  /usr/local/Cellar/elixir/1.3.3/bin/../lib/elixir/ebin/Elixir.Map.beam
Source
  /private/tmp/elixir-20160918-33925-1ki46ng/elixir-1.3.3/lib/elixir/lib/map.ex
Version
  [9651177287794427227743899018880159024]
Compile time
  no value found
Compile options
  [:debug_info]
Description
  Use h(Map) to access its documentation.
  Call Map.module_info() to access metadata.
Raw representation
  :"Elixir.Map"
Reference modules
  Module, Atom
```

Ahora tenemos un montón de información sobre `Map` incluyendo dónde está almacenado su código fuente y los módulos a los que hace referencia. Esto es muy útil cuando se exploran datos personalizados, tipos de datos externos y nuevas funciones.

Los títulos individuales pueden ser densos, pero a un alto nivel podemos recopilar información relevante:

- Es un tipo de datos atómicos
- Donde el código fuente se encuentra
- La versión y las opciones de compilación
- Una descripción general
- Cómo acceder a ella
- A qué otros módulos hace referencia

Esto nos da mucho con que trabajar y es mejor que ir a ciegas.

### `r`

Si queremos recompilar un módulo en particular podemos usar el ayudante `r`. Digamos que hemos cambiado algún código y queremos ejecutar una nueva función que hemos añadido. Para ello necesitamos guardar nuestros cambios y recompilar con r:

```elixir
iex> r MyProject
warning: redefining module MyProject (current version loaded from _build/dev/lib/my_project/ebin/Elixir.MyProject.beam)
  lib/my_project.ex:1

{:reloaded, MyProject, [MyProject]}
```

### `t`

El `t` helper nos habla de los Tipos disponibles en un módulo dado:

```elixir
iex> t Map
@type key() :: any()
@type value() :: any()
```

Y ahora sabemos que `Map` define los tipos de claves y valores en su implementación.
Si vamos y miramos la fuente de `Map`:

```elixir
defmodule Map do
# ...
  @type key :: any
  @type value :: any
# ...
```

Este es un ejemplo simple, indicando que las claves y valores por implementación pueden ser de cualquier tipo, pero es útil saberlo.

Aprovechando todas estas sutilezas incorporadas podemos explorar fácilmente el código y aprender más sobre cómo funcionan las cosas. IEx es una herramienta muy poderosa y robusta que da poder a los desarrolladores. ¡Con estas herramientas en nuestra caja de herramientas, explorar y construir puede ser aún más divertido!