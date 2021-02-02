%{
  version: "2.4.0",
  title: "Basics",
  excerpt: """
  Ecto es un proyecto oficial de Elixir que provee un envoltorio a la base de datos y un lenguaje de consultas integrado. Con Ecto podemos crear migraciones, definir modelos, insertar, actualizar y consultar registros de nuestra base de datos.
  """
}
---

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
* Esquemas - estructuras especializadas que representan entradas en la base de datos

Para empezar, crearemos una aplicación con su árbol de supervisión.

```shell
$ mix new friends --sup
$ cd friends
```

Agrega los paquetes de Ecto y Postgrex a tu archivo `mix.exs`

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
$ mix ecto.gen.repo -r Friends.Repo
```

Esto generará la configuración requerida en `config/config.exs` para conectarse a la base de datos, incluyendo el adaptador que usará.
Este es el archivo de configuración de nuestra aplicación `Friends`

```elixir
config :friends, Friends.Repo,
  database: "friends_repo",
  username: "postgres",
  password: "",
  hostname: "localhost"
```

Esto configura como Ecto se conectará a la base de datos.

También crea un módulo `Friends.Repo` en `lib/friends/repo.ex`

```elixir
defmodule Friends.Repo do
  use Ecto.Repo,
    otp_app: :friends,
    adapter: Ecto.Adapters.Postgres
end
```

Usaremos el módulo `Friends.Repo` para consultar la base de datos. También le decimos a este módulo que encuentre la configuración de su base de datos en la aplicación de Elixir `:friends` y que elegimos el adaptador `Ecto.Adapters.Postgres`.

Después, configuraremos el módulo `Friends.Repo` como supervisor dentro del árbol de supervisor de nuestra aplicación en `lib/friends/application.ex`.
Esto iniciará el proceso de Ecto cuando nuestra aplicación inicie.

```elixir
  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      Friends.Repo,
    ]

  ...
```

Después de eso tendremos que agregar la siguiente línea a `config/config.exs`:

```elixir
config :friends, ecto_repos: [Friends.Repo]
```

Esto permitirá que nuestra aplicación pueda ejecutar comandos mix de Ecto desde la terminal

¡Hemos terminado con la configuración de nuestro repositorio!
Ahora podemos crear la base de datos dentro de Postgres con este comando:

```shell
$ mix ecto.create
```

Ecto usará la información en `config/config.exs` para determinar como conectarse con Postgres y que nombre darle a la base de datos.

Si recibes algún error verifica que la configuración es la correcta y que tu instancia de Postgres está corriendo.

### Migraciones

Para crear y modificar tablas dentro de una base de datos Postgres, Ecto nos proveé con migraciones.
Cada migración describe un grupo de acciones a ejecutar en nuestra base de datos, como que tablas crear o actualizar.

Como nuestra base de datos no contiene aún ninguna tabla tendremos que crear una migración que agregue algunas.
La convención en Ecto es pluralizar las tablas, así que para nuestra aplicación necesitaremos una tabla `people`, así que empecemos por ahí.

La mejor forma de crear migraciones es con el comando mix `ecto.gen.migration <name>`, así que para nuestro caso ejecutaremos:

```shell
$ mix ecto.gen.migration create_people
```

Esto generará un nuevo archivo en el directorio `priv/repo/migrations` que contendrá un timestamp en su nombre.
Si navegamos a nuestro directorio y abrimos la migración veremos algo como esto:

```elixir
defmodule Friends.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do

  end
end
```

Empecemos modificando la función `change/0` para crear una nueva tabla `people` con `name` y `age`:

```elixir
defmodule Friends.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do
    create table(:people) do
      add :nombre, :string, null: false
      add :age, :integer, default: 0
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

### Esquemas

Ahora que creamos nuestra tabla inicial, tenemos que decirle a Ecto más sobre ella y parte de esto lo hacemos a través de esquemas.
Un esquema es un módulo que define la relación con los campos de la base de datos.

Mientras Ecto favorece pluralizar los nombres de las tablas de la base de datos, el esquema es usualmente singular, así que crearemos un esquema `Person` para acompañar nuestra tabla.

Creemos nuestro nuevo esquema en `lib/friends/person.ex`:

```elixir
defmodule Friends.Person do
  use Ecto.Schema

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

Aquí podemos ver que el módulo `Friends.Person` le dice a Ecto que el esquema se relaciona con la tabla `people` y que tenemos dos columnas: `name` que es una cadena de texto y `age`, que es un entero con un valor por default de `0`.

Echemos un vistazo a nuestro esquema abriendo `iex -S mix` y creando una nueva persona:

```shell
iex> %Friends.Person{}
%Friends.Person{age: 0, name: nil}
```

Como lo esperábamos, obtuvimos un nuevo `Person` con el valor por defecto aplicado a `age`.
Ahora crearemos una persona "real":

```shell
iex> person = %Friends.Person{name: "Tom", age: 11}
%Friends.Person{age: 11, name: "Tom"}
```

Como los esquemas son estructuras, podemos interactuar con nuestra data como estamos acostumbrados:

```elixir
iex> person.name
"Tom"
iex> Map.get(person, :name)
"Tom"
iex> %{name: name} = person
%Friends.Person{age: 11, name: "Tom"}
iex> name
"Tom"
```

Igualmente podemos actualizar nuestros esquemas justo como lo haríamos con cualquier otro mapa o estructura en Elixir:

```elixir
iex> %{person | age: 18}
%Friends.Person{age: 18, name: "Tom"}
iex> Map.put(person, :name, "Jerry")
%Friends.Person{age: 11, name: "Jerry"}
```

En nuestra siguiente lección sobre Changesets, veremos como validar los cambios en nuestra data y finalmente como persistir estos en nuestra base de datos.
