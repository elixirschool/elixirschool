%{
  version: "1.2.0",
  title: "Funciones",
  excerpt: """
  En Elixir y en muchos lenguajes funcionales, las funciones son ciudadanos de primera clase. Vamos a aprender acerca de los tipos de funciones en Elixir, qué los hace diferentes, y cómo usarlos.
  """
}
---

## Funciones anónimas

Tal como el nombre sugiere, una función anónima no tiene nombre. Como vimos en la lección `Enum`, son pasadas frecuentemente a otras funciones. Para definir una función anónima en Elixir necesitamos las palabras clave `fn` y `end`. Dentro de estos podemos definir, separados por `->`, cualquier número de parámetros y el cuerpo de la función.

Vamos a ver un ejemplo básico:

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### El atajo &

Usar funciones anónimas es una práctica común en Elixir, hay un atajo para hacer esto:

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

Como probablemente ya has adivinado, en la versión reducida nuestros parámetros están disponibles como: `&1`, `&2`, `&3`.

## Coincidencia de patrones

La coincidencia de patrones no está limitada solo a las variables en Elixir, puede ser aplicada a las firmas de la función como veremos en esta sección.

Elixir usa coincidencia de patrones para identificar el primer conjunto de parámetros que coincidan e invocar al cuerpo correspondiente:

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:ok, _} -> IO.puts "This would be never run as previous will be matched beforehand."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
1
iex> handle_result.({:ok, some_result})
Handling result...
:ok
iex> handle_result.({:error})
An error has occurred!
```

## Funciones con nombre

Podemos definir funciones con nombre para así poder referirnos a ellas luego. Estas funciones con nombre son definidas con la palabra clave `def` dentro de un módulo. Vamos a aprender más acerca de los módulos en las siguientes lecciones, por ahora nos enfocaremos solamente en las funciones con nombre.

Las funciones definidas dentro de un módulo están disponibles para ser usadas por otros módulos, esto es particularmente útil para construir bloques en Elixir:

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

Si el cuerpo de nuestra función solo se extiende a una línea, podemos acortarla con `do:`:

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

Armados con nuestro conocimiento de coincidencia de patrones, vamos a explorar la recursión usando funciones con nombre:

```elixir
defmodule Length do
  def of([]), do: 0
  def of([_ | tail]), do: 1 + of(tail)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### Nombre de funciones y aridad

Anteriormente mencionamos que las funciones son nombradas por la combinación de nombre y aridad (cantidad de argumentos).
Esto significa que puedes hacer cosas como:

```elixir
defmodule Greeter2 do
  def hello(), do: "Hello, anonymous person!"   # hello/0
  def hello(name), do: "Hello, " <> name        # hello/1
  def hello(name1, name2), do: "Hello, #{name1} and #{name2}"
                                                # hello/2
end

iex> Greeter2.hello()
"Hello, anonymous person!"
iex> Greeter2.hello("Fred")
"Hello, Fred"
iex> Greeter2.hello("Fred", "Jane")
"Hello, Fred and Jane"
```
Enumeramos los nombres de las funciones en los comentarios anteriores.
La primera implementación no recibe argumentos, su equivalente es `hello/0`; la segunda función recibe un argumento equivalente a `hello/1`, y así.
A diferencia de la sobrecarga en otros lenguajes, estas son consideradas funciones diferentes entre si.
(La coincidencia de patrones, descrita anteriormente, aplica solo cuando se definen varias funciones con el mismo nombre y el mismo numero de argumentos).

### Funciones y coincidencia de patrones

Detrás de escenas, las funciones se ajustan a el numero de argumentos con los que se llaman.

Digamos que necesitamos una función para aceptar un mapa, pero solo nos interesa utilizar una llave en particular.
Podemos coincidir el argumento con la llave de la siguiente forma:

```elixir
defmodule Greeter1 do
  def hello(%{name: person_name}) do
    IO.puts "Hello, " <> person_name
  end
end
```

Digamos que tenemos el siguiente mapa:

```elixir
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"
...> }
```

Estos son los resultados que obtenemos al llamar `Greeter1.hello/1` con el mapa `fred`:

```elixir
# call with entire map
...> Greeter1.hello(fred)
"Hello, Fred"
```
¿Qué sucede cuando llamamos la función con un mapa que no contiene la llave `:name`?

```elixir
# call without the key we need returns an error
...> Greeter1.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter1.hello/1

    The following arguments were given to Greeter1.hello/1:

        # 1
        %{age: "95", favorite_color: "Taupe"}

    iex:12: Greeter1.hello/1

```

La razón de este comportamiento es que Elixir busca la coincidencia de los argumentos con los que se llama la función con la aridad con la que se define la función.

Pensemos en como se ven los datos cuando llegan a `Greeter1.hello/1`:

```Elixir
# incoming map
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"
...> }
```
`Greeter1.hello/1` espera un argumento como el siguiente:
```elixir
%{name: person_name}
```
En `Greeter1.hello/1`, el mapa que pasamos (`fred`) se evalúa comparandolo con nuestro argumento (`%{name: person_name}`):

```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Encuentra que existe una llave que corresponde a `:name` en el mapa proporcionado.
¡Tenemos una coincidencia! y como resultado de esta coincidencia exitosa, el valor de la llave `:name` en el mapa de la derecha (Por ejemplo el mapa `fred`) esta vinculado a la variable de la izquierda (`person_name`).

Ahora, ¿qué sucede si quisiéramos asignar el nombre de Fred a `person_name` pero TAMBIÉN queremos acceder a todo el mapa? Digamos que queremos hacer `IO.inspect(fred)` despues de saludarlo.
En este punto, debido a que solo buscamos la llave `:name` en nuestro mapa, solo vinculamos el valor de esa llave a una variable, la función no tiene conocimiento del resto del mapa.

Para poder conservarlo, debemos asignar ese mapa completo a su propia variable para que podamos utilizarlo.

Empecemos una nueva función:
```elixir
defmodule Greeter2 do
  def hello(%{name: person_name} = person) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

Recuerde que Elixir buscara la coincidencia a medida de que se presente.
Por lo tanto, en este caso, cada lado buscara la coincidencia con el argumento entrante y se unirá a lo que corresponda.
Tomemos el lado derecho primero:

```elixir
person = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Ahora, `person` a sido evaluado y vinculado a todo el mapa de fred.
Pasemos a la siguiente coincidencia:
```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Ahora esto es lo mismo a nuestra función original `Greeter1` en la que la que solo buscábamos la coincidencia con el mapa y solo reteníamos el nombre de Fred.
Lo que hemos logrado son dos variable que podemos usar en lugar de una:
1. `person`, refiriéndose a `%{name: "Fred", age: "95", favorite_color: "Taupe"}`
2. `person_name`, refiriéndose a `"Fred"`

Así que ahora cuando llamamos `Greeter2.hello/1`, podemos usar toda la información de Fred:
```elixir
# call with entire person
...> Greeter2.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}
# call with only the name key
...> Greeter2.hello(%{name: "Fred"})
"Hello, Fred"
%{name: "Fred"}
# call without the name key
...> Greeter2.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter2.hello/1

    The following arguments were given to Greeter2.hello/1:

        # 1
        %{age: "95", favorite_color: "Taupe"}

    iex:15: Greeter2.hello/1
```

Así que hemos visto que las coincidencias en Elixir se ajustan a múltiples profundidades porque cada argumento se compara con los datos entrantes de forma independiente, dejandonos las variables para llamarlas dentro de nuestra función.

Si cambiamos el orden de `%{name: person_name}` y `person` en la lista, obtendremos los mismos resultados ya que cada uno coincide con fred por su cuenta.

Cambiamos la variable y el mapa:
```elixir
defmodule Greeter3 do
  def hello(person = %{name: person_name}) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

Y llamémoslo con los mismos datos que usamos en `Greeter2.hello/1`:
```elixir
# call with same old Fred
...> Greeter3.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}
```

Continuar escribiendo
Recordemos que aunque parezca que `%{name: person_name} = person` hace coincidir los patrones con `%{name: person_name}` contra la variable `person`, en realidad esta haciendo coincidir los patrones con los argumentos proporcionados.

**Resumen:** Las funciones buscan coincidencia con cada uno de los datos proporcionados de forma independiente.
Podemos usar esto para vincular valores a variables separadas dentro de la función.

### Funciones privadas

Cuando no queremos que otros módulos accedan a una función especifica, podemos hacer que la función sea privada.
Las funciones privadas solo pueden ser llamadas desde su propio modulo.
Las definimos en Elixir con `defp`:

```elixir
defmodule Greeter do
  def hello(name), do: phrase() <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### Guardias

Hemos cubierto brevemente las guardias en la lección [Estructuras de control](../control-structures), ahora veremos cómo aplicarlas a las funciones con nombre. Una vez Elixir ha coincidido una función algunas guardias serán evaluadas.

En el siguiente ejemplo tenemos dos funciones con la misma firma, confiamos en las guardias para determinar cuál usar basándonos en el tipo de los argumentos:

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase() <> name
  end

  defp phrase, do: "Hello, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"
```

### Argumentos por defecto

Si queremos un valor por defecto para un argumento usamos la sintaxis `argument \\ value`:

```elixir
defmodule Greeter do
  def hello(name, language_code \\ "en") do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello("Sean", "en")
"Hello, Sean"

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.hello("Sean", "es")
"Hola, Sean"
```

Cuando combinamos nuestro ejemplo de guardias con argumentos por defecto, nos encontramos con un problema, vamos a ver algo que podría ser similar:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code \\ "en") when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) iex:31: definitions with multiple clauses and default values require a header. Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b) do ... end

one should write:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end

def hello/2 has multiple clauses and defines defaults in one or more clauses
    iex:31: (module)
```

A Elixir no le gustan los parámetros por defecto en múltiples coincidencias de funciones, esto puede ser confuso. Para manejar esto podemos agregar una función al inicio con nuestros argumentos por defecto:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en")

  def hello(names, language_code) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code) when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "es"
"Hola, Sean, Steve"
```
