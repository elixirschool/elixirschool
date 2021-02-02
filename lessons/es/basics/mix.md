%{
  version: "1.0.2",
  title: "Mix",
  excerpt: """
  Antes de que podamos sumergirnos en las profundas aguas de Elixir primero necesitamos aprender acerca de mix. Si estás familiarizado con Ruby, mix es Bundler, RubyGems y Rake combinados. Es una parte crucial de cualquier proyecto Elixir y en esta lección vamos a explorar solo algunas de sus grandiosas características. Para ver todo lo que mix ofrece ejecutamos `mix help`.

Hasta ahora hemos estado trabajando exclusivamente dentro de `iex` con sus limitaciones. Para construir algo sustancial necesitamos dividir nuestro código en varios archivos para administrarlos efectivamente, mix nos permite hacer eso con nuestros proyectos.
  """
}
---

## Nuevo proyecto

Cuando estamos listos para crear un nuevo proyecto Elixir, mix lo hace fácil con el comando `mix new`. Esto generará la estructura y los archivos necesarios de nuestro proyecto. Esto es bastante sencillo, ahora vamos a empezar:

```bash
$ mix new example
```

De la salida podemos ver que mix ha creado nuestro directorio y un número de archivos:

```bash
* creating README.md
* creating .gitignore
* creating .formatter.exs
* creating mix.exs
* creating lib
* creating lib/example.ex
* creating test
* creating test/test_helper.exs
* creating test/example_test.exs
```

En esta sección vamos a enfocar nuestra atención en `mix.exs`. Aquí configuramos nuestra aplicación, dependencias, entornos, y versión. Abre el archivo en tu editor favorito, deberías ver algo como esto (comentarios eliminados por brevedad):

```elixir
defmodule Example.Mix do
  use Mix.Project

  def project do
    [
      app: :example,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end
end
```

La primera sección que vamos a ver es `project`. Aquí vamos a definir el nombre de nuestra aplicación(`app`), especificar la versión del proyecto(`version`), la versión de Elixir(`elixir`), y finalmente nuestras dependencias(`deps`).

La sección `application` es usada durante la generación de nuestro archivo de aplicación el cual cubriremos a continuación.

## Interactivo

Puede ser necesario usar `iex` dentro del contexto de nuestra aplicación. Por suerte para nosotros, mix hace esto fácil. Podemos empezar una nueva sesión `iex`:

```bash
$ cd example
$ iex -S mix
```

Al empezar `iex` de esta forma, mix cargará nuestra aplicación y dependencias en la ejecución actual.


## Compilación

Mix es inteligente y compilará tus cambios cuando sea necesario, pero todavia puede ser necesario compilar tu proyecto explícitamente. En esta sección vamos a cubrir cómo compilar nuestro proyecto y como se hace la compilación.

Para compilar un proyecto mix solo necesitamos ejecutar `mix compile` en nuestro directorio base:

```bash
$ mix compile
```

No hay mucho en nuestro proyecto, por eso la salida no es tan emocionante así que esto debería completarse satisfactoriamente:

```bash
Compiled lib/example.ex
Generated example app
```

Cuando compilamos un proyecto mix crea un directorio `_build` para nuestros artefactos. Si miramos dentro de `_build` vamos a ver nuestra aplicación compilada `example.app`.


## Administrar dependencias

Nuestro proyecto no tiene ninguna dependencia pero lo hará en breve. Vamos a seguir adelante para definir las dependencias y obtenerlas.

Para añadir una nueva dependencia primero necesitamos agregarla a nuestro archivo `mix.exs` en la sección `deps`. Nuestra lista de dependencias está compuesta de tuplas con dos valores requeridos y uno opcional: El nombre del paquete como un átomo, la versión como una cadena, y opciones (opcionales).

Para este ejemplo vamos a ver un proyecto con dependencias, como [phoenix_slim](https://github.com/doomspork/phoenix_slim):

```elixir
def deps do
  [
    {:phoenix, "~> 1.1 or ~> 1.2"},
    {:phoenix_html, "~> 2.3"},
    {:cowboy, "~> 1.0", only: [:dev, :test]},
    {:slime, "~> 0.14"}
  ]
end
```

Como probablemente has visto en las dependencias arriba, la dependencia `cowboy` es la única necesaria durante las fases de desarrollo y pruebas.

Una vez que hemos definido nuestras dependencias hay un paso final: obtenerlas. Esto es análogo a `bundle install` (en Ruby):

```bash
$ mix deps.get
```

¡Eso es! Hemos definido y obtenido nuestras dependencias. Ahora estamos preparados para agregar dependencias cuando sea necesario.

## Entornos

Mix, como Bundler, soporta diferentes entornos. Mix trabaja con tres entornos:

+ `:dev` — El entorno por defecto.
+ `:test` — Usado por `mix test`. Cubierto en la siguiente lección.
+ `:prod` — Usado cuando enviamos nuestra aplicación a producción.

El actual entorno puede ser accedido usando `Mix.env`. Como esperamos, el entorno puede ser cambiado mediante la variable de entorno `MIX_ENV`:

```bash
$ MIX_ENV=prod mix compile
```
