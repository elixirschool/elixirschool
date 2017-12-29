---
version: 0.9.1
title: Ecto
---

Ecto es un proyecto oficial de Elixir, provee un envoltorio a la base de datos y un lenguaje de consultas integrado. Con Ecto podemos crear migraciones, definir modelos, insertar, actualizar y consultar registros de nuestra base de datos.

{% include toc.html %}

## Inicio

Para iniciar necesitamos incluir a Ecto y un adaptador a una base de datos en el fichero `mix.exs` de nuestro proyecto. Puede encontrar una lista de los adaptadores a bases de datos soportados en la sección [Usage](https://github.com/elixir-lang/ecto/blob/master/README.md#usage) del README de Ecto. Para nuestro ejemplo emplearemos PostgreSQL:

```elixir
defp deps do
  [{:ecto, "~> 1.0"}, {:postgrex, ">= 0.0.0"}]
end
```

Ahora podemos agregar Ecto y nuestro adaptador, `postgrex` en nuestro caso, a la lista de aplicaciones:

```elixir
def application do
  [applications: [:ecto, :postgrex]]
end
```

### Repositorio

Finalmente necesitamos crear el repositorio de nuestro proyecto, el envoltorio a la base de datos. Esto puede realizarse al ejecutar la siguiente tarea Mix: `mix ecto.gen.repo`, describiremos las tareas Mix en subsiguientes secciones. El repositorio creado puede encontrarse en `lib/<nombre_proyecto>/repo.ex`

```elixir
defmodule ExampleApp.Repo do
  use Ecto.Repo, otp_app: :example_app
end
```

### Supervisor

Una vez creado nuestro Repo necesitamos configurar nuestro árbol de supervisión, el cual usualmente se encuentra en `lib/<nombre_proyecto>.ex`.

Es importante notar que configuramos Repo como un supervisor por medio de `supervisor/3` y _no_ por medio de `worker/3`. Si usted genera su aplicación con la opción `--sup` lo que viene a continuación seguramente ya existe:

```elixir
defmodule ExampleApp.App do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(ExampleApp.Repo, [])
    ]

    opts = [strategy: :one_for_one, name: ExampleApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

<!-- TODO: Remove this as a comment, once advanced/otp-supervisors  is translated to Spanish
Para mayor información acerca de supervisores revisa la lección [Supervisores OTP](../../advanced/otp-supervisors).
-->

### Configuración

Para configurar Ecto necesitamos agregar una sección a nuestro `config/config.exs`. Acá especificaremos el repositorio, adaptador, base de datos e información de acceso:

```elixir
config :example_app, ExampleApp.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "example_app",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
```

## Tareas Mix

Ecto incluye cierto número de tareas Mix útiles para trabajar con nuestra base de datos:

```shell
mix ecto.create         # Crea el almacenamiento de nuestro repositorio
mix ecto.drop           # Elimina el almacenamiento para nuestro repositorio
mix ecto.gen.migration  # Genera una nueva migración para nuestro repositorio
mix ecto.gen.repo       # Genera un nuevo repositorio
mix ecto.migrate        # Ejecuta migraciones sobre nuestro repositorio
mix ecto.rollback       # Revierte las migraciones aplicadas a nuestro repositorio
```

## Migraciones

La mejor manera de crear migraciones es a través de `mix ecto.gen.migration <nombre>`. Si usted está familiarizado con ActiveRecord esto le parecerá familiar.

Comencemos por ver el detalle de la migración para la tabla de usuarios:

```elixir
defmodule ExampleApp.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:username, :string, unique: true)
      add(:encrypted_password, :string, null: false)
      add(:email, :string)
      add(:confirmed, :boolean, default: false)

      timestamps
    end

    create(unique_index(:users, [:username], name: :unique_usernames))
  end
end
```

Por omisión Ecto crea un `id` auto incremental como llave primaria. Acá estamos usando el _callback_ por omisión `change/0` pero Ecto también soporta `up/0` y `down/0` por si usted requiere un control más granular.

Como usted seguramente ya habrá descubierto al agregar `timestamps` a su migración Ecto creará y manejará los campos `inserted_at` y `updated_at` por usted.

Para aplicar nuestra nueva migración ejecute el comando `mix ecto.migrate`

Para mayor detalle acerca de las migraciones vea la sección [Ecto.Migration](http://hexdocs.pm/ecto/Ecto.Migration.html#content) de la documentación oficial.

## Modelos

Ahora que tenemos nuestra migración podemos movernos a nuestro modelo. Los modelos definen nuestro esquema, funciones auxiliares y nuestro _set de cambios_, cubriremos más acerca del _set de cambios_ en secciones subsiguientes.

Por ahora veamos como luce el modelo para nuestra migración:

```elixir
defmodule ExampleApp.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:username, :string)
    field(:encrypted_password, :string)
    field(:email, :string)
    field(:confirmed, :boolean, default: false)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)

    timestamps
  end

  @required_fields ~w(username encrypted_password email)
  @optional_fields ~w()

  def changeset(user, params \\ :empty) do
    user
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:username)
  end
end
```

El esquema que hemos definido en nuestro modelo es muy similar a lo que especificamos en nuestra migración. Además de los campos de nuestra base de datos también hemos incluido 2 campos virtuales. Los campos virtuales no son almacenados en la base de datos pero pueden ser útiles para cuestiones como validaciones. Veremos en acción los campos virtuales en la sección que hace referencia a los [set de cambios](#set_de_cambios)

## Consultas

Antes de realizar consultas a nuestro repositorio necesitamos importar el API Query, por ahora solo necesitamos importar `from/2`:

```elixir
import Ecto.Query, only: [from: 2]
```

Para mayor detalle puede consultar la documentación oficial de [Ecto.Query](http://hexdocs.pm/ecto/Ecto.Query.html).

### Básico

Ecto provee un excelente lenguaje específico de dominio (DSL, por sus siglas en inglés) para expresar consultas de manera clara. Para buscar los nombres de usuario con sus cuentas confirmadas podemos usar algo como:

```elixir
alias ExampleApp.{Repo, User}

query =
  from(
    u in User,
    where: u.confirmed == true,
    select: u.username
  )

Repo.all(query)
```

Además de `all/2`, Repo provee cierto número de _callbacks_ que incluyen `one/2`, `get/3`, `insert/2` y `delete/2`. La lista completa de _callbacks_ puede ser encontrada en [Ecto.Repo#callbacks](http://hexdocs.pm/ecto/Ecto.Repo.html#callbacks).

### Count

```elixir
query =
  from(
    u in User,
    where: u.confirmed == true,
    select: count(u.id)
  )
```

### Group By

Para agrupar el número de nombres de usuarios en base a su estado de confirmación de cuenta podemos incluir la opción `group_by`:

```elixir
query =
  from(
    u in User,
    group_by: u.confirmed,
    select: [u.confirmed, count(u.id)]
  )

Repo.all(query)
```

### Order By

Ordenando los usuarios en base a su fecha de inserción:

```elixir
query =
  from(
    u in User,
    order_by: u.inserted_at,
    select: [u.username, u.inserted_at]
  )

Repo.all(query)
```

Para ordenar de manera decreciente usamos `DESC`:

```elixir
query =
  from(
    u in User,
    order_by: [desc: u.inserted_at],
    select: [u.username, u.inserted_at]
  )
```

### Joins

Asumiendo que tenemos un perfil asociado a nuestro usuario, busquemos todos los perfiles de cuentas confirmadas:

```elixir
query =
  from(
    p in Profile,
    join: u in assoc(p, :user),
    where: u.confirmed == true
  )
```

### Fragmentos

En algunas ocasiones el API que ofrece `Ecto.Query` no es suficiente, por ejemplo, cuando necesitamos funciones específicas de la base de datos. La función `fragment/1` existe para cubrir estos casos:

```elixir
query =
  from(
    u in User,
    where: fragment("downcase(?)", u.username) == ^username,
    select: u
  )
```

Ejemplos adicionales sobre el uso del API Ecto.Query pueden encontrarse en [phoenix-examples/ecto_query_library](https://github.com/phoenix-examples/ecto_query_library).

## Set de cambios

En la sección previa aprendimos como obtener datos, pero no realizar inserciones o actualizaciones de los mismos, para ello necesitamos los _set de cambios_.

Los _set de cambios_ se encargan de filtrar, validar y respetar las restricciones cuando el modelo cambia.

Para este ejemplo nos enfocaremos en el _set de cambios_ para la creación de la cuenta de usuario. Para comenzar necesitamos actualizar nuestro modelo:

```elixir
defmodule ExampleApp.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Comeonin.Bcrypt, only: [hashpwsalt: 1]

  schema "users" do
    field(:username, :string)
    field(:encrypted_password, :string)
    field(:email, :string)
    field(:confirmed, :boolean, default: false)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)

    timestamps
  end

  @required_fields ~w(username email password password_confirmation)
  @optional_fields ~w()

  def changeset(user, params \\ :empty) do
    user
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:password, min: 8)
    |> validate_password_confirmation()
    |> unique_constraint(:username, name: :email)
    |> put_change(:encrypted_password, hashpwsalt(params[:password]))
  end

  defp validate_password_confirmation(changeset) do
    case get_change(changeset, :password_confirmation) do
      nil ->
        password_incorrect_error(changeset)

      confirmation ->
        password = get_field(changeset, :password)
        if confirmation == password, do: changeset, else: password_mismatch_error(changeset)
    end
  end

  defp password_mismatch_error(changeset) do
    add_error(changeset, :password_confirmation, "Passwords does not match")
  end

  defp password_incorrect_error(changeset) do
    add_error(changeset, :password, "is not valid")
  end
end
```

Hemos mejorado nuestra funcion `changeset/2` y hemos incluido tres funciones auxiliares: `validate_password_confirmation/1`, `password_mismatch_error/1` y `password_incorrect_error/1`.

Como su nombre sugiere `changeset/2` crea un nuevo _set de cambios_ por nosotros. Dentro de el se usa `cast/4` para convertir nuestros parámetros a un _set de cambios_ a partir de un conjunto de campos requeridos y opcionales. Seguidamente validamos la longitud de la contraseña, confirmamos la contraseña con una función privada y se verifica que el nombre de usuario proporcionado sea único. Finalmente actualizamos el campo de la base de datos que contiene la contraseña, para actualizar el valor en el _set de cambios_ usamos `put_change/3`.

El uso de `User.changeset/2` es relativamente sencillo:

```elixir
alias ExampleApp.{User, Repo}

pw = "passwords should be hard"

changeset =
  User.changeset(%User{}, %{
    username: "doomspork",
    email: "sean@seancallan.com",
    password: pw,
    password_confirmation: pw
  })

case Repo.insert(changeset) do
  {:ok, model}        -> # Inserted with success
  {:error, changeset} -> # Something went wrong
end
```

Esto es todo! Ahora usted está listo para almacenar sus datos.
