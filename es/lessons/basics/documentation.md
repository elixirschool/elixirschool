---
version: 1.0.3
title: Documentación
---

Documentando código Elixir.

{% include toc.html %}

## Anotación

Cuánto documentamos y qué hace que la documentación de calidad siga siendo un tema polémico dentro del mundo de la programación.
Sin embargo, todos podemos estar de acuerdo que la documentación es importante para nosotros y para aquellos que trabajan con nuestro código.

Elixir trata la documentación como *ciudadanos de primera clase*, ofreciendo varias funciones para acceder y generar documentación para tus proyectos.
El núcleo de Elixir nos provee con diferentes atributos para documentar el código. Vamos a ver 3 formas:

  - `#` - Para documentación en linea.
  - `@moduledoc` - Para documentación a nivel de módulo.
  - `@doc` - Para documentación a nivel de función.

### Documentación en linea

Probablemente la forma más simple de comentar tu código es con comentarios en linea. Similar a Ruby o Python, el comentario en linea de Elixir está denotado con `#`, frecuentemente conocido como *almohadilla* o de alguna otra forma de acuerdo de donde seas.

Toma este script de Elixir (greeting.exs):

```elixir
# Outputs 'Hello, chum.' to the console.
IO.puts "Hello, " <> "chum."
```

Elixir, cuando ejecuta este script ignorará todo desde `#` hasta el final de la linea, tratándolo como datos sin uso.
Esto puede no agregar valor a la operación o rendimiento del _script_, sin embargo cuando no es obvio que está pasando, un programador debería saberlo leyendo tu comentario.
¡Se consciente de no abusar del comentario en línea! Ensuciar un código puede volverse una pesadilla para algunos.
Es mejor usarlo con moderación.

### Documentando Módulos

El anotador `@moduledoc` permite agregar documentación al nivel de módulo.
Esto típicamente se sitúa bajo la declaración `defmodule` al inicio del archivo.
El ejemplo a continuación muestra un comentario de una línea dentro del decorador `@moduledoc`.

```elixir
defmodule Greeter do
  @moduledoc """
  Provides a function `hello/1` to greet a human
  """

  def hello(name) do
    "Hello, " <> name
  end
end
```

Nosotros (u otros) podemos acceder a esta documentación usando la función de ayuda `h` dentro de IEx.

```elixir
iex> c("greeter.ex", ".")
[Greeter]

iex> h Greeter

                Greeter

Provides a function hello/1 to greet a human
```

### Documentando Funciones

Al igual que Elixir nos da la habilidad para documentar a nivel de módulo, también habilita similares anotaciones para documentar funciones.
El anotador `@doc` permite agregar documentación a nivel de función.
El anotador `@doc` se sitúa justo sobre la función que está comentando.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

Si entramos en IEx otra vez y usamos el comando de ayuda (`h`) con la función precedida por el nombre del módulo, veremos lo siguiente:

```elixir
iex> c("greeter.ex")
[Greeter]

iex> h Greeter.hello

                def hello(name)

Prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"

iex>
```

¿Notas como puedes usar marcado dentro de la documentación y la terminal lo renderizará? Además de ser realmente genial y una adición novedosa al vasto ecosistema de Elixir, se vuelve mucho más interesante cuando vemos que ExDoc genera documentación en HTML sobre la marcha.

**Nota:** la anotación `@spec` es usada para analisis estático del código. Para aprender mas acerca de eso, revisa la lección [Especificaciones y tipos](../../advanced/typespec).

## ExDoc

ExDoc es un proyecto oficial de Elixir que puede ser encontrado en [GitHub](https://github.com/elixir-lang/ex_doc).
Produce **HTML (HyperText Markup Language) y documentación en línea** para proyectos Elixir.
Primero vamos a crear un proyecto Mix para nuestra aplicación:

```bash
$ mix new greet_everyone

* creating README.md
* creating .gitignore
* creating .formatter.exs
* creating mix.exs
* creating lib
* creating lib/greet_everyone.ex
* creating test
* creating test/test_helper.exs
* creating test/greet_everyone_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd greet_everyone
    mix test

Run "mix help" for more commands.

$ cd greet_everyone

```

Ahora copia y pega el código de la lección del anotador `@doc` en un archivo llamado `lib/greeter.ex` y asegúrate de que todo aun está funcionando desde la línea de comandos.
Ahora que estamos trabajando dentro de un proyecto Mix necesitamos empezar IEx de una forma un poco diferente usando el comando `iex -S mix`:

```bash
iex> h Greeter.hello

                def hello(name)

Prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"
```

### Instalando

Asumiendo que todo esta bien vamos a ver la salida siguiente, ahora estamos listos para configurar ExDoc.
En el archivo `mix.exs`, agrega las dos dependencias requeridas: `:earmark` y `:ex_doc`.

```elixir
  def deps do
    [{:earmark, "~> 1.2", only: :dev},
    {:ex_doc, "~> 0.19", only: :dev}]
  end
```

Especificamos el par llave-valor `only: :dev` porque no queremos descargar y compilar estas dependencias en un entorno de producción.
Pero ¿Por qué Earmark? Earmark es un *parser* Markdown para el lenguaje de programación Elixir el cual ExDoc utiliza para convertir nuestra documentación dentro de `@moduledoc` y `@doc` en hermoso HTML.

Vale la pena señalar en este punto que no estas forzado a usar Earmark.
Puedes cambiar la herramienta de marcado a otros como Pandoc, Hoedown, o Cmark; sin embargo vas a necesitar hacer un poco mas de configuración la cual puedes leer [aquí](https://github.com/elixir-lang/ex_doc#changing-the-markdown-tool).
Para este tutorial, seguiremos con Earmark.

### Generando documentación

Desde la linea de comandos ejecuta los siguientes comandos:

```bash
$ mix deps.get # gets ExDoc + Earmark.
$ mix docs # makes the documentation.

Docs successfully generated.
View them at "doc/index.html".
```

Si todo fue de acuerdo al plan, deberías ver un mensaje similar al mensaje de salida del anterior ejemplo.
Ahora vamos a ver dentro de nuestro proyecto Mix y deberíamos ver que hay otro directorio llamado **docs/**.
Dentro está nuestra documentación generada.
Si visitamos la página indice(index.html) en nuestro navegador deberíamos ver los siguiente:

![ExDoc Screenshot 1]({% asset documentation_1.png @path %})

Podemos ver que Earmark ha renderizado nuestro Markdown y ExDoc y ahora lo muestra en un formato útil.

![ExDoc Screenshot 2]({% asset documentation_2.png @path %})

Ahora podemos publicar esto en GitHub, a nuestro propio sitio web, o mas comunmente a [HexDocs](https://hexdocs.pm/).

## Mejores Prácticas

La documentación agregada debería ser agregada dentro de las directrices de mejores prácticas del lenguaje.
Ya que Elixir es un lenguaje bastante joven muchos estándares aun esta siendo descubiertos conforme el ecosistema crece.
La comunidad, sin embargo, intentó establecer las mejores prácticas.
Para leer acerca de estas mejores prácticas puedes revisar [The Elixir Style Guide](https://github.com/niftyn8/elixir_style_guide).

  - Siempre documenta un módulo.

```elixir
defmodule Greeter do
  @moduledoc """
  This is good documentation.
  """

end
```

  - Si no vas a documentar un módulo, **no** lo dejes en blanco, Considera anotar el módulo como `false`, al igual que:

```elixir
defmodule Greeter do
  @moduledoc false

end
```

 - Cuando te refieras a funciones dentro de la documentación de un módulo, usa *backticks* al igual que:

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 - Separar cualquier código una linea bajo `@moduledoc` como:

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  alias Goodbye.bye_bye
  # and so on...

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 - Usa Markdown dentro de la documentación.
 Esto hará facil la lectura ya sea desde IEx o ExDoc.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

 - Prueba incluir algunos ejemplos en tu documentación.
 Esto te permitirá agregar pruebas automáticas desde los ejemplos encontrados en un módulo, función, o macro con [ExUnit.DocTest][].
 Para hacer eso, necesitas invocar al macro `doctest/1` desde tu caso de prueba y escribir tus ejemplos conforme a algunas directrices, las cuales estan detalladas en la [documentación oficial][ExUnit.DocTest].

[ExUnit.DocTest]: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html
