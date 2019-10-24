---
version: 2.4.0
title: Basics
---

Ecto es un proyecto oficial de Elixir que provee un envoltorio a la base de datos y un lenguaje de consultas integrado. Con Ecto podemos crear migraciones, definir modelos, insertar, actualizar y consultar registros de nuestra base de datos.

{% include toc.html %}

### Adaptadores

Ecto soporta distintas bases de datos a través de adaptadores. Algunos ejemplos de estos son:

* PostgreSQL
* MySQL
* SQLite

Para esta lección configuraremos Ecto usando el adaptador para PostgreSQL.

### Inicio

A través de esta lección cubriremos tres partes de Ecto:

* Repositorio - proveé la interfaz hacía nuestra base de datos, incluyendo la conexión
* Migraciones - un mecanismo para crear, modificar y eliminar tablas e índices
* Esquemas - estructuras especialidas que representan entradas en la base de datos

Para empezar crearemos una aplicación con su árbol de supervisión.

```shell
$ mix new amigos --sup
$ cd amigos
```

Agrega los paquetes de ecto y postgrex a tu archivo `mix.exs`

```elixir
  defp deps do
    [
      {:ecto_sql, "~> 3.2"},
      {:postgrex, "~> 0.15"}
    ]
  end
```

Y descarga las dependencias ejecutando

```shell
$ mix deps.get
```

#### Creando un repositorio

Un repositorio en Ecto se relaciona con un set de datos, como nuestra base de datos PostgreSQL.
Toda comunicación con la base de datos se hará usando este repositorio.

Configura un repositorio ejecutando:

```shell
$ mix ecto.gen.repo -r Amigos.Repo
```

Esto generará la configuración requerida en `config/config.exs` para conectarse a la base de datos, incluyendo el adaptador que usará.
Este es el archivo de configuración de nuestra aplicación `Amigos`

```elixir
config :amigos, Amigos.Repo,
  database: "amigos_repo",
  usernombre: "postgres",
  password: "",
  hostnombre: "localhost"
```

Esto configura como Ecto se conectará a la base de datos.

También crea un módulo `Amigos.Repo` en `lib/amigos/repo.ex`

```elixir
defmodule Amigos.Repo do
  use Ecto.Repo, 
    otp_app: :amigos,
    adapter: Ecto.Adapters.Postgres
end
```

Usaremos el módulo `Amigos.Repo` para consultar la base de datos. También le decimos a este módulo que encuentre la configuración de su base de datos en la aplicación de Elixir `:amigos` y que elegimos el adaptador `Ecto.Adapters.Postgres`.

Después, configuraremos el módulo `Amigos.Repo` como supervisor dentro del árbol de supervisor de nuestra aplicación en `lib/amigos/application.ex`.
Esto iniciará el proceso de Ecto cuando nuestra aplicación inicie.

```elixir
  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      Amigos.Repo,
    ]

  ...
```

Después de eso tendremos que agregar la siguiente línea a `config/config.exs`:

```elixir
config :amigos, ecto_repos: [Amigos.Repo]
```

Esto permitirá que nuestra aplicación pueda ejecutar comandos mix de ecto desde la terminal

Hemos terminado con la configuración de nuestro repositorio!
Ahora podemos crear la base de datos dentro de postgres con este comando:

```shell
$ mix ecto.create
```

Ecto usará la información en `config/config.exs` para determinar como conectarse con Postgres y que nombre darle a la base de datos.

Si recibes algún error verifica que la configuración es la correcta y que tu instancia de postgres está corriendo.

## Migraciones

Para crear y modificar tablas dentro de una base de datos postgres, Ecto nos proveé con migraciones.
Cada migración describe un grupo de acciones a ejecutar en nuestra base de datos, como que tablas crear o actualizar.

Como nuestra base de datos no contiene aún ninguna tabla tendremos que crear una migración que agregue algunas.
La convención en Ecto es pluralizar las tablas, así que para nuestra aplicación necesitaremos una tabla `personas`, así que empezemos por ahí.

La mejor forma de crear migraciones es con el comando mix `ecto.gen.migration <nombre>`, así que para nuestro caso ejecutaremos:

```shell
$ mix ecto.gen.migration create_personas
```

Esto generará un nuevo archivo en el directorio `priv/repo/migrations` que contendrá un timestamp en su nombre.
Si navegamos a nuestro directorio y abrimos la migración veremos algo como esto:

```elixir
defmodule Amigos.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do

  end
end
```

Empezemos modificando la función `change/0` para crear una nueva tabla `personas` con `nombre` y `edad`:

```elixir
defmodule Amigos.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do
    create table(:personas) do
      add :nombre, :string, null: false
      add :edad, :integer, default: 0
    end
  end
end
```

Puedes ver que hemos definido el tipo de dato de las columnas.
Adicionalmente hemos incluido `null: false` y `default: 0` como opciones.

Movámonos a la terminal y ejecutemos nuestra migración:

```shell
$ mix ecto.migrate
```

## Esquemas

Ahora que creamos nuestra tabla inicial, tenemos que decirle a Ecto más sobre ella y parte de esto lo hacemos a través de esquemas.
Un esquema es un módulo que define la relación con los campos de la base de datos.

Mientras Ecto favorece pluralizar los nombres de las tablas de la base de datos, el esquema es usualmente singular, así que crearemos un esquema `Persona` para acompañar nuestra tabla.

Creemos nuestro nuevo esquema en `lib/amigos/person.ex`:

```elixir
defmodule Amigos.Persona do
  use Ecto.Schema

  schema "personas" do
    field :nombre, :string
    field :edad, :integer, default: 0
  end
end
```

Aquí podemos ver que el módulo `Amigos.Persona` le dice a Ecto que el esquema se relaciona con la tabla `personas` y que tenemos dos columnas: `nombre` que es una cadena de texto y `edad`, que es un entero con un valor por default de `0`.

Echemos un vistazo a nuestro esquema abriendo `iex -S mix` y creando una nueva persona:

```shell
iex> %Amigos.Persona{}
%Amigos.Persona{edad: 0, nombre: nil}
```

Como lo esperabamos, obtuvimos un nuevo `Persona` con el valor por defecto aplicado a `edad`.
Ahora crearemos una persona "real":

```shell
iex> person = %Amigos.Persona{nombre: "Tomás", edad: 11}
%Amigos.Persona{edad: 11, nombre: "Tomás"}
```

Como los esquemas son estructuras, podemos interactuar con nuestra data como estamos acostumbrados:

```elixir
iex> person.nombre
"Tomás"
iex> Map.get(person, :nombre)
"Tomás"
iex> %{nombre: nombre} = person
%Amigos.Persona{edad: 11, nombre: "Tomás"}
iex> nombre
"Tomás"
```

Igualmente podemos actualizar nuestros esquemas justo como lo haríamos con cualquier otro mapa o estructura en Elixir:

```elixir
iex> %{person | edad: 18}
%Amigos.Persona{edad: 18, nombre: "Tomás"}
iex> Map.put(person, :nombre, "Juan")
%Amigos.Persona{edad: 11, nombre: "Juan"}
```

En nuestra siguiente lección sobre Changesets, veremos como validar los cambios en nuestra data y finalmente como persistir estos en nuestra base de datos.
