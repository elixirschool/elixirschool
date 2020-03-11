---
version: 1.0.2
title: Tareas de Mix personalizadas
---

Creando tareas de Mix personalizadas para tus proyectos Elixir.

{% include toc.html %}

## Introducción

Es común querer extender la funcionalidad de tus aplicaciones Elixir agregando tareas Mix personalizadas. Antes de aprender acerca de como crear tareas Mix específicas para nuestros proyectos vamos a ver una que ya existe.

```shell
$ mix phx.new my_phoenix_app

* creating my_phoenix_app/config/config.exs
* creating my_phoenix_app/config/dev.exs
* creating my_phoenix_app/config/prod.exs
* creating my_phoenix_app/config/prod.secret.exs
* creating my_phoenix_app/config/test.exs
* creating my_phoenix_app/lib/my_phoenix_app.ex
* creating my_phoenix_app/lib/my_phoenix_app/endpoint.ex
* creating my_phoenix_app/test/views/error_view_test.exs
...
```

Como podemos ver desde la terminal superior. El _framework_ Phoenix tiene una tarea Mix personalizada para generar un nuevo proyecto. ¿Y si pudiéramos crear algo similar para nuestro proyecto? Pues bien, la gran noticia es que podemos crearlo y Elixir lo hace realmente sencillo.

## Preparación

Vamos a preparar una aplicación Mix muy básica.

```shell
$ mix new hello

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/hello.ex
* creating test
* creating test/test_helper.exs
* creating test/hello_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

cd hello
mix test

Run "mix help" for more commands.
```

Ahora en nuestro archivo **lib/hello.ex** que Mix generó para nosotros vamos a crear una simple función que dará como salida "Hello, World!".

```elixir
defmodule Hello do
  @doc """
  Outputs `Hello, World!` every time.
  """
  def say do
    IO.puts("Hello, World!")
  end
end
```

## Tarea Mix personalizada

Vamos a crear nuestra tarea Mix personalizada. Crea un nuevo directorio y un archivo **hello/lib/mix/tasks/hello.ex**. Dentro de este archivo vamos a insertar lo siguiente:

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Simply runs the Hello.say/0 function"
  def run(_) do
    # calling our Hello.say() function from earlier
    Hello.say()
  end
end
```

Nota como empezamos la declaración del módulo con `Mix.Tasks` y el nombre que queremos llamar desde la línea de comandos. En la segunda línea introducimos `use Mix.Task` el cual trae el comportamiento de `MixTask` al espacio de nombres. Ahora declaramos una función `run` que ignora cualquier argumento por ahora. Dentro de esta función llamamos a nuestro módulo `Hello` y a la función `say`.

## Tareas Mix en acción

Vamos a revisar nuestra tarea Mix. Mientras estemos en el directorio debería funcionar. Desde la línea de comandos ejecuta `mix hello` y deberíamos ver lo siguiente:

```shell
$ mix hello
Hello, World!
```

Mix es bastante amigable por defecto. Sabe que cualquiera puede hacer un error de ortografía entonces usa una técnica llamada "fuzzy sting matching" para hacer recomendaciones:

```shell
$ mix hell
** (Mix) The task "hell" could not be found. Did you mean "hello"?
```

¿También notaste que introducimos un nuevo atributo `@shortdoc`? Este viene a ser útil cuando empaquetamos nuestra aplicación y cuando un usuario ejecuta `mix help` desde la terminal.

```shell
$ mix help

mix app.start         # Starts all registered apps
...
mix hello             # Simply calls the Hello.say/0 function.
...
```
