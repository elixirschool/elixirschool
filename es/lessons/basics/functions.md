---
version: 0.9.1
title: Funciones
---

En Elixir y en muchos lenguajes funcionales, las funciones son ciudadanos de primera clase. Vamos a aprender acerca de los tipos de funciones en Elixir, qué los hace diferentes, y cómo usarlos.

{% include toc.html %}

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
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
iex> handle_result.({:ok, some_result})
Handling result...

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

### Funciones privadas

Cuando no queremos que otros módulos accedan a una función podemos usar funciones privadas, que solo pueden ser llamadas dentro de su módulo. Podemos definirlas en Elixir con `defp`:

```elixir
defmodule Greeter do
  def hello(name), do: phrase <> name
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
