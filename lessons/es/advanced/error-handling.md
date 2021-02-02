%{
  version: "1.0.1",
  title: "Manejo de errores",
  excerpt: """
  Aunque es más común devolver una tupla `{:error, reason}`, Elixir soporta excepciones, y en esta lección revisaremos como manejar errores y los diferentes mecanismos a nuestra disposición.

En general la convención en Elixir es crear una función (`example/1`) que devuelve `{:ok, result}` y `{:error, reason}` y una función distinta (`example!/1`) que devuelve el resultado `result` sin envolver o levanta un error.

Esta lección se enfocará en interactuar con la última forma.
  """
}
---

## Manejo de errores

Antes de que podamos manejar errores necesitamos crearlos, y la manera más simple de hacer esto es con `raise/1`:

```elixir
iex> raise "Oh no!"
** (RuntimeError) Oh no!
```

Si queremos especificar el tipo y mensaje, necesitamos usar `raise/2`:

```elixir
iex> raise ArgumentError, message: "the argument value is invalid"
** (ArgumentError) the argument value is invalid
```

Cuando sabemos que un error puede ocurrir, podemos manejarlo usando `try/rescue` y coincidencia de patrones:

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> end
An error occurred: Oh no!
:ok
```

Es posible coincidir múltiples errores en un solo `rescue`:

```elixir
try do
  opts
  |> Keyword.fetch!(:source_file)
  |> File.read!()
rescue
  e in KeyError -> IO.puts("missing :source_file option")
  e in File.Error -> IO.puts("unable to read source file")
end
```

## After

A veces es necesario realizar alguna acción después de nuestro `try/rescue` independientemente de si hubo o no error. Para esto tenemos `try/after`. Si estás familiarizado con Ruby, esto es similar a `begin/rescue/ensure` o en Java a `try/catch/finally`:

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> after
...>   IO.puts "The end!"
...> end
An error occurred: Oh no!
The end!
:ok
```

Esto es más comúnmente usado con archivos o conexiones que deberían ser cerradas:

```elixir
{:ok, file} = File.open("example.json")

try do
  # Do hazardous work
after
  File.close(file)
end
```

## Nuevos errores

Pese a que elixir incluye un número de errores predefinidos como `RuntimeError`, mantenemos la habilidad de crear los nuestros si necesitamos algo específico.
Crear un nuevo error es fácil con la macro `defexception/1`, que convenientemente acepta la opción `:message` para definir un mensaje de error por defecto:

```elixir
defmodule ExampleError do
  defexception message: "an example error has occurred"
end
```

Llevemos nuestro nuevo error a dar una vuelta:

```elixir
iex> try do
...>   raise ExampleError
...> rescue
...>   e in ExampleError -> e
...> end
%ExampleError{message: "an example error has occurred"}
```

## Throws

Otro mecanismo para trabajar con errores en Elixir es `throw` y `catch`.
En la práctica, estos ocurren muy inusualmente en código de Elixir más nuevo, pero es importante conocerlos y entenderlos.

La función `throw/1` nos da la habilidad de salir de la ejecución con un valor específico que podemos capturar con `catch` y luego utilizar:

```elixir
iex> try do
...>   for x <- 0..10 do
...>     if x == 5, do: throw(x)
...>     IO.puts(x)
...>   end
...> catch
...>   x -> "Caught: #{x}"
...> end
0
1
2
3
4
"Caught: 5"
```

Como se mencionó, `throw/catch` son muy poco comunes y típicamente existen como recurso provisional cuando las bibliotecas fallan en proveer APIs adecuadas.

## Salir

El último mecanismo de error que Elixir nos provee es `exit`.
Las señales de salida ocurren cuando un proceso muere y son una parte importante de la tolerancia a fallos en Elixir.

Para salir de manera explícita podemos usar `exit/1`:

```elixir
iex> spawn_link fn -> exit("oh no") end
** (EXIT from #PID<0.101.0>) evaluator process exited with reason: "oh no"
```

Pese a que es posible manejar una salida con `try/catch`, hacerlo es _extremadamente_ raro. En casi todos los casos es ventajoso permitir al supervisor manejar la salida del proceso:

```elixir
iex> try do
...>   exit "oh no!"
...> catch
...>   :exit, _ -> "exit blocked"
...> end
"exit blocked"
```
