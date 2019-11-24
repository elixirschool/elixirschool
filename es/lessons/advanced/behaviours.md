---
version: 1.0.1
title: Comportamientos
---

Aprendimos acerca de Typespecs en la lección anterior, ahora vamos a aprender como requerir que un módulo implemente esas especificaciones.
En Elixir, esta funcionalidad es referida como comportamientos.

{% include toc.html %}

## Usos

A veces quieres que los módulos compartan una API pública, la solución para esto en Elixir son los comportamientos.
Los comportamientos tienen dos roles importantes:

+ Definir un conjunto de funciones que deben ser implementadas
+ Revisar que ese conjunto de funciones haya efectivamente sido implementado.

Elixir incluye un número de comportamientos tales como `GenServer` pero en esta lección vamos a enfocarnos en crear uno propio.

## Definiendo un comportamiento

Para mejor entendimiento de los comportamientos vamos a implementar uno para un módulo *worker*.
Se espera que estos *workers* implementen dos funciones: `init/1` y `perform/2`.

Para lograr esto vamos a usar la directiva `@callback` la cual tiene una sintaxis similar a `@spec`.
Esto define una función __requerida__, para macros podemos usar `@macrocallback`.
Vamos a especificar las funciones `init/1` y `perform/2` para nuestros *workers*.

```elixir
defmodule Example.Worker do
  @callback init(state :: term) :: {:ok, new_state :: term} | {:error, reason :: term}
  @callback perform(args :: term, state :: term) ::
              {:ok, result :: term, new_state :: term}
              | {:error, reason :: term, new_state :: term}
end
```

Aquí hemos definido `init/1` que acepta cualquier valor y retorna una tupla que puede ser `{:ok, state}` o `{:error, reason}`, esta inicialización es bastante estándar.
Nuestra función `perform/2` recibirá algunos argumentos para el *worker* junto con el estado que inicializamos, esperaremos que `perform/2` retorne `{:ok, result, state}` o `{:error, reason, state}` bastante similar a los GenServers.

## Usando los comportamientos

Ahora que hemos definido nuestro comportamiento podemos usarlo para crear una variedad de módulos que comparten la misma API pública.
Agregar un comportamiento a nuestro módulo es fácil con el atributo `@behaviour`.

Usando nuestro nuevo comportamiento vamos a crear un módulo cuya tarea sea descargar un archivo remoto y guardarlo localmente:

```elixir
defmodule Example.Downloader do
  @behaviour Example.Worker

  def init(opts), do: {:ok, opts}

  def perform(url, opts) do
    url
    |> HTTPoison.get!()
    |> Map.fetch(:body)
    |> write_file(opts[:path])
    |> respond(opts)
  end

  defp write_file(:error, _), do: {:error, :missing_body}

  defp write_file({:ok, contents}, path) do
    path
    |> Path.expand()
    |> File.write(contents)
  end

  defp respond(:ok, opts), do: {:ok, opts[:path], opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

¿O qué tal un *worker* que comprime un arreglo de archivos? Eso es posible también:

```elixir
defmodule Example.Compressor do
  @behaviour Example.Worker

  def init(opts), do: {:ok, opts}

  def perform(payload, opts) do
    payload
    |> compress
    |> respond(opts)
  end

  defp compress({name, files}), do: :zip.create(name, files)

  defp respond({:ok, path}, opts), do: {:ok, path, opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

Mientras el trabajo es realizado diferente la API pública no lo es, y cualquier código que aproveche estos módulos puede interactuar con ellos sabiendo como van a responder.
Esto nos da la habilidad de crear cualquier número de *workers*, todos realizando tareas diferentes pero conforme a la la misma API pública.

Si por casualidad agregamos un comportamiento pero no implementamos todas las funciones requeridas tendremos una advertencia en tiempo de compilación.
Para ver esto en acción vamos a modificar el código de `Example.Compressor`y vamos a eliminar la función `init/1`:

```elixir
defmodule Example.Compressor do
  @behaviour Example.Worker

  def perform(payload, opts) do
    payload
    |> compress
    |> respond(opts)
  end

  defp compress({name, files}), do: :zip.create(name, files)

  defp respond({:ok, path}, opts), do: {:ok, path, opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

Ahora cuando compilemos nuestro código deberíamos ver una advertencia:

```shell
lib/example/compressor.ex:1: warning: undefined behaviour function init/1 (for behaviour Example.Worker)
Compiled lib/example/compressor.ex
```

Eso es todo. Ahora estamos listos para construir y compartir comportamientos con otros.
