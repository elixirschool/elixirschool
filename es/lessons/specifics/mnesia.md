---
version: 1.2.0
title: Mnesia
---

Mnesia es un sistema distribuido de base de datos en tiempo real.

{% include toc.html %}

## Introducción

Mnesia es sistema de administración de base de datos que viene incluido en Erlang el cual podemos usar naturalmente con Elixir.
El *modelo de datos híbrido relacional-objeto* es lo que lo hace adecuado para desarrollar aplicaciones distribuidas de cualquier escala.

## Cuando usarlo

Cuando usar una pieza particular de tecnología es frecuentemente una pregunta difícil de contestar.
Si puedes responder 'si' a cualquiera de las siguientes preguntas entonces es un buen indicador para usar Mnesia en lugar de ETS o DETS.

  - ¿Necesito hacer rollback de transacciones?
  - ¿Necesito una sintaxis fácil usar para leer y escribir data?
  - ¿Debería guardar data en múltiples nodos en lugar de uno solo?
  - ¿Necesito elegir donde guardar información (RAM o disco)?

## Esquema

Como Mnesia es parte del core de Erlang y no de Elixir podemos acceder a este con la sintaxis `:` (Revisa la lección: [Interoperabilidad con Erlang](../../advanced/erlang/)):

```elixir

iex> :mnesia.create_schema([node()])

# or if you prefer the Elixir feel...

iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
```

Para esta lección tomaremos al último enfoque cuando trabajemos con el API de Mnesia.
`Mnesia.create_schema/1` inicializa un nuevo esquema vacío y recibe una lista de nodos.
En este caso le estamos pasando le nodo asociado con nuestra sesión de IEx.

## Nodos

Una vez que ejecutamos el comando `Mnesia.create_schema([node()])` en IEx deberías ver una carpeta llamada **Mnesia.nonode@nohost** o algo similar en tu directorio de trabajo actual.
Te puedes estar preguntando que significa **nonode@nohost** dado que no lo hemos abordado antes.
Vamos a echar un vistazo.

```shell
$ iex --help
Usage: iex [options] [.exs file] [data]

  -v                Prints version
  -e "command"      Evaluates the given command (*)
  -r "file"         Requires the given files/patterns (*)
  -S "script"       Finds and executes the given script
  -pr "file"        Requires the given files/patterns in parallel (*)
  -pa "path"        Prepends the given path to Erlang code path (*)
  -pz "path"        Appends the given path to Erlang code path (*)
  --app "app"       Start the given app and its dependencies (*)
  --erl "switches"  Switches to be passed down to Erlang (*)
  --name "name"     Makes and assigns a name to the distributed node
  --sname "name"    Makes and assigns a short name to the distributed node
  --cookie "cookie" Sets a cookie for this distributed node
  --hidden          Makes a hidden node
  --werl            Uses Erlang's Windows shell GUI (Windows only)
  --detached        Starts the Erlang VM detached from console
  --remsh "name"    Connects to a node using a remote shell
  --dot-iex "path"  Overrides default .iex.exs file and uses path instead;
                    path can be empty, then no file will be loaded

** Options marked with (*) can be given more than once
** Options given after the .exs file or -- are passed down to the executed code
** Options can be passed to the VM using ELIXIR_ERL_OPTIONS or --erl
```

Cuando le pasamos la opción `--help` a IEx en la linea de comandos veremos todas las posibles opciones.
Podemos ver que hay opciones `--name` y `--sname` para asignar información a los nodos.
Un nodo es solo una máquina virtual de Erlang corriendo la cual maneja sus propias comunicaciones, colección de basura, planificación de procesos, memoria y más.
El nodo está siendo llamado simplemente **nonode@nohost** por defecto.

```shell
$ iex --name learner@elixirschool.com

Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex(learner@elixirschool.com)> Node.self
:"learner@elixirschool.com"
```

Como podemos ver el nodo que estamos corriendo es un átomo llamado `:"learner@elixirschool.com"`.
Si ejecutamos `Mnesia.create_schema([node()])` otra vez, veremos que es creado otro directorio llamado **Mnesia.learner@elixirschool.com**.
El propósito de esto es bastante simple.
Los nodos en Erlang están acostumbrados a conectarse a otros nodos para compartir(distribuir) información y recursos.
Esto no tiene que estar limitado a la misma máquina y pueden comunicarse mediante LAN, internet, etc.

## Empezando con Mnesia

Ahora que hemos cubierto lo básico de la forma como configurar la base de datos estamos en una posición para empezar la base de datos con el comando`Mnesia.start/0`.

```elixir
iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
:ok
iex> Mnesia.start()
:ok
```
La función `Mnesia.start/0` es asíncrona. Empieza la inicialización de las tablas existentes y retorna al átomo `:ok`. En caso necesitemos realizar alguna acción sobre una tabla existente justo luego de iniciar Mnesia necesitamos llamar a la función `Mnesia.wait_for_tables/2`. Esto suspenderá la llamada hasta que las tablas hayan sido inicializadas. Revisa el ejemplo en la sección [Inicialización de datos y migración](#inicialización de datos y migración).

Hay que tener en cuenta que cuando corremos un sistema distribuido con dos o más nodos la función `Mnesia.start/1` debe ser ejecutada en todos los nodos.

## Creando tablas

La función `Mnesia.create_table/2` es usada para crear tablas dentro de nuestra base de datos.
Abajo creamos una tabla llamada `Person` y luego pasamos una lista de llaves definiendo el esquema de la tabla.

```elixir
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:atomic, :ok}
```

Definimos las columnas usando los átomos `:id`, `:name`, y `:job`.
El primer átomo (en este caso `:id`) es la llave primaria.
Al menos un atributo adicional es requerido.

Cuando ejecutamos `Mnesia.create_table/2` esto retornará una de las siguientes respuestas:

 - `{:atomic, :ok}` si la función se ejecuta satisfactoriamente
 - `{:aborted, Reason}` si la función falla

En particular si la tabla ya existe, la razón será de la forma `{:already_exists, table}` por lo que si intentamos crear esta tabla por segunda vez obtendremos:

```elixir
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:aborted, {:already_exists, Person}}
```

## La forma sucia

Antes que todo revisaremos la forma "sucia" de leer y escribir en una tabla de Mnesia.
Esto generalmente debería ser evitado ya que el éxito de la acción no está garantizado pero nos ayudará a aprender y sentirnos cómodos trabajando con Mnesia.
Agreguemos algunas entradas a nuestra tabla **Person**.

```elixir
iex> Mnesia.dirty_write({Person, 1, "Seymour Skinner", "Principal"})
:ok

iex> Mnesia.dirty_write({Person, 2, "Homer Simpson", "Safety Inspector"})
:ok

iex> Mnesia.dirty_write({Person, 3, "Moe Szyslak", "Bartender"})
:ok
```

...y para recuperar las entradas podemos usar `Mnesia.dirty_read/1`:

```elixir
iex> Mnesia.dirty_read({Person, 1})
[{Person, 1, "Seymour Skinner", "Principal"}]

iex> Mnesia.dirty_read({Person, 2})
[{Person, 2, "Homer Simpson", "Safety Inspector"}]

iex> Mnesia.dirty_read({Person, 3})
[{Person, 3, "Moe Szyslak", "Bartender"}]

iex> Mnesia.dirty_read({Person, 4})
[]
```

Si intentamos consultar un registro que no existe Mnesia responderá con una lista vacía.

## Transacciones

Tradicionalmente usamos **transacciones** para encapsular las lecturas y escrituras a nuestra base de datos.
Las transacciones son una parte importante de diseñar sistemas altamente distribuidos y tolerantes a fallos.
Una transacción en Mnesia es un mecanismo mediante el cual una seria de operaciones de base de datos pueden ser ejecutadas como un bloque funcional.
Primero vamos a crear una función anónima, en este caso `data_to_write` y luego la pasamos a `Mnesia.transaction`.

```elixir
iex> data_to_write = fn ->
...>   Mnesia.write({Person, 4, "Marge Simpson", "home maker"})
...>   Mnesia.write({Person, 5, "Hans Moleman", "unknown"})
...>   Mnesia.write({Person, 6, "Monty Burns", "Businessman"})
...>   Mnesia.write({Person, 7, "Waylon Smithers", "Executive assistant"})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_write)
{:atomic, :ok}
```
Basado en este mensaje de la transacción podemos con seguridad asumir que hemos escrito la data en nuestra tabla `Person`.
Vamos a usar una transacción para leer de la base de datos para asegurarnos.
Usaremos `Mnesia.read/1` para leer de la base de datos pero otra vez desde una función anónima.

```elixir
iex> data_to_read = fn ->
...>   Mnesia.read({Person, 6})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_read)
{:atomic, [{Person, 6, "Monty Burns", "Businessman"}]}
```

Nota que si quieres actualizar la data solo necesitas llamar a `Mnesia.write/1` con la misma llave de un registro existente.
Por lo tanto para actualizar el registro Hans puedes hacer:

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.write({Person, 5, "Hans Moleman", "Ex-Mayor"})
...>   end
...> )
```

## Usando índices

Mnesia soporta índices en columnas que no sean llaves y la data puede ser consultada usando esos índices.
Entonces podemos agregar un índice a la columna `:job` de la tabla `Person`:

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:atomic, :ok}
```

El resultado es similar al regresado por `Mnesia.create_table/2`:

 - `{:atomic, :ok}` si la función se ejecutó satisfactoriamente
 - `{:aborted, Reason}` si la función falló

Particularmente si el índice ya existe la razón será de la forma `{:already_exists, table, attribute_index}` por lo que podemos tratar de agregar este índice una segunda vez y obtendremos:

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:aborted, {:already_exists, Person, 4}}
```

Una vez que el índice ha sido creado satisfactoriamente podemos hacer una lectura usándolo y retornar una lista de todos los directores:

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.index_read(Person, "Principal", :job)
...>   end
...> )
{:atomic, [{Person, 1, "Seymour Skinner", "Principal"}]}
```

## Match y selección

Mnesia soporta consultas complejas para obtener data de una tabla en la forma *matching* y funciones de selección.

La función `Mnesia.match_object/1` retorna todos los registros que hacen *match* con el patrón dado.
Si alguna de las columnas en la tabla tiene índices puede hacer uso de ellos para hacer la consulta mas eficiente.
Usa el átomo especial `:_` para identificar columnas que no participan en el *match*.

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.match_object({Person, :_, "Marge Simpson", :_})
...>   end
...> )
{:atomic, [{Person, 4, "Marge Simpson", "home maker"}]}
```

La función `Mnesia.select/2` permite especificar una consulta personalizada usando cualquier operador o función en el lenguaje Elixir o Erlang.
Veamos por ejemplo una selección de todos los registros que tienen una llave que es mayor que 3:

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     {% raw %}Mnesia.select(Person, [{{Person, :"$1", :"$2", :"$3"}, [{:>, :"$1", 3}], [:"$$"]}]){% endraw %}
...>   end
...> )
{:atomic, [[7, "Waylon Smithers", "Executive assistant"], [4, "Marge Simpson", "home maker"], [6, "Monty Burns", "Businessman"], [5, "Hans Moleman", "unknown"]]}
```

Vamos detallar esto.
El primer atributo es la tabla `Person`, el segundo atributo es una tupla de tres elementos de la forma `{match, [guard], [result]}`:

- `match` es igual al que pasaste a la función `Mnesia.match_object/1` sin embargo nota los átomos especiales `:"$n"` que especifican la posición de los parámetros que son usados por el resto de la consulta.
- la lista `guard` es una lista de tuplas que especifica que función de guarda aplicar, en este caso la función `:>` (mayor que) con el primer parámetro `:"$1"` y la constante `3` como atributos.
- la lista `result` es la lista de campos que son retornados por la consulta, en la forma de parámetros posicionales del átomo especial `:$$` para hacer referencia a todos los campos que podría usar de modo que podrás usar`[:"$1", :"$2"]` para retornar los primeros dos campos o `[:"$$"]` para retornar todos los campos.

Para mas detalles ver [documentación de select/2](http://erlang.org/doc/man/mnesia.html#select-2).

## Inicialización de datos y migración

Con cada solución de software habrá un tiempo cuando necesitas actualizar el software y migrar la data guardada en tu base de datos.
Por ejemplo puede que queramos agregar una columna `:age` a la tabla `Person` en la versión 2 de nuestra aplicación.
No podemos crear la tabla `Person` una vez que ha sido creada pero podemos transformarla.
Para esto necesitamos saber cuando transformar lo cual lo podemos hacer cuando creamos la tabla.
Para hacer esto podemos usar la función `Mnesia.table_info/2` para obtener la estructura actual de la tabla y la función `Mnesia.transform_table/3` para transformarla a la nueva estructura.

El código siguiente hace esto implementando la siguiente lógica.

* Crea la tabla con los atributos de la versión 2: `[:id, :name, :job, :age]`
* Maneja el resultado del a creación:
    * `{:atomic, :ok}`: inicializa la tabla creando índices en `:job` y `:age`
    * `{:aborted, {:already_exists, Person}}`: revisa que atributos son usados en la tabla actual y actúa según sea el caso
        * Si es la lista de la v1 (`[:id, :name, :job]`), transforma la tabla dando a cada uno una edad de 21 y agregando un nuevo índice en `:age`
        * Si es la lista de la v2 no se hace nada, todo está bien
        * Si es algo diferente retorna el error

Si estamos realizando alguna acción en las tablas existentes justo luego de iniciar Mnesia con `Mnesia.start/0` esas tablas puede que no estén inicializadas y no sean accesibles. En ese caso deberíamos usar la función [`Mnesia.wait_for_tables/2`](http://erlang.org/doc/man/mnesia.html#wait_for_tables-2). Esto suspenderá el proceso actual hasta que las tablas sean inicializadas o hasta que tiempo límite sea alcanzado.

La función `Mnesia.transform_table/3` toma como atributos el nombre de la tabla, una función que transforma un registro del viejo al nuevo formato y la lista de nuevos atributos.

```elixir
case Mnesia.create_table(Person, [attributes: [:id, :name, :job, :age]]) do
  {:atomic, :ok} ->
    Mnesia.add_table_index(Person, :job)
    Mnesia.add_table_index(Person, :age)
  {:aborted, {:already_exists, Person}} ->
    case Mnesia.table_info(Person, :attributes) do
      [:id, :name, :job] ->
        Mnesia.wait_for_tables([Person], 5000)
        Mnesia.transform_table(
          Person,
          fn ({Person, id, name, job}) ->
            {Person, id, name, job, 21}
          end,
          [:id, :name, :job, :age]
          )
        Mnesia.add_table_index(Person, :age)
      [:id, :name, :job, :age] ->
        :ok
      other ->
        {:error, other}
    end
end
```
