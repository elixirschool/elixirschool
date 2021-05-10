%{
  version: "1.2.1",
  title: "Asociaciones",
  excerpt: """
  En esta sección vamos a aprender como usar Ecto para definir y trabajar con asociaciones entre nuestros esquemas.
  """
}
---

## Configuración

Vamos a comenzar con la aplicación `Ejemplo` de la lección anterior. Puedes ir a la configuración [aquí](../basics) para recordarlo rápidamente.

## Tipos de asociaciones

Hay tres tipos de asociaciones que podemos definir entre nuestros esquemas. Vamos a ver lo que son y como implementar cada tipo de relación.

### Belongs To/Has Many (Pertenece a/Tiene muchos)

Vamos a agregar algunas entidades nuevas al dominio de nuestra app de ejemplo para que podamos catalogar nuestras películas favoritas. Vamos a empezar con dos esquemas: `Movie` (Película) y `Character` (Personaje). Vamos a implementar una relación "has many/belongs to" entre nuestros dos esquemas: Una película tiene muchos personajes, y un personaje pertenece a una película.

#### La Migración Has Many

Vamos a crear una migración para `Movie`:

```console
mix ecto.gen.migration create_movies
```

Abre el nuevo archivo generado de migración y define tu función `change` para crear la tabla `movies` con algunos atributos nuevos:

```elixir
# priv/repo/migrations/*_create_movies.exs
defmodule Friends.Repo.Migrations.CreateMovies do
  use Ecto.Migration

  def change do
    create table(:movies) do
      add :title, :string
      add :tagline, :string
    end
  end
end
```

#### El esquema Has Many

Vamos a agregar un esquema que especifica la relación "has many" entre una película y sus personajes.

```elixir
# lib/example/movie.ex
defmodule Friends.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Friends.Character
  end
end
```

El macro `has_many/3` no agrega nada a la base de datos en sí. Lo que hace es usar la llave foranea en el esquema asociado, `characters`, para hacer que esten disponibles los personajes asociados a una película. Esto es lo que nos permite llamar `movie.characters`.

#### La migración Belongs To

Ahora estamos listos para construir nuestra migración y esquema de `Character`. Un personaje pertenece a una película, así que vamos a definir una migración y un esquema que especifique esta relación.

Primero, creamos la migración:

```console
mix ecto.gen.migration create_characters
```

Para declarar que un personaje pertenece a una película, nececitamos que la tabla `characters` tenga una columna `movie_id`.
Queremos que esta columna funcione como una llave foranea. Podemos lograr esto con la siguiente linea en nuestra función `create table/1`:

```elixir
add :movie_id, references(:movies)
```
Entonces nuestra migración debe verse así:

```elixir
# priv/migrations/*_create_characters.exs
defmodule Friends.Repo.Migrations.CreateCharacters do
  use Ecto.Migration

  def change do
    create table(:characters) do
      add :name, :string
      add :movie_id, references(:movies)
    end
  end
end
```

#### El Esquema Belongs To

Nuestro esquema igualmente necesita definir la relación "belongs to" entre un personaje y su película.

```elixir
# lib/example/character.ex

defmodule Friends.Character do
  use Ecto.Schema

  schema "characters" do
    field :name, :string
    belongs_to :movie, Friends.Movie
  end
end
```

Vamos a echar un vistazo más de cerca a lo que el macro `belongs_to/3` hace por nosotros. Además de agregar la llave foranea `movie_id` a nuestro esquema, también nos da la habilidad de acceder al esquema asociado `movies` _a tráves_ de `characters`. Éste usa la llave foranea para hacer disponible una película asociada a un personaje cuando los consultamos. Esto es lo que nos permite llamar `character.movie`

Ahora estamos listos para ejecutar nuestras migraciones:

```console
mix ecto.migrate
```

### Belongs To/Has One (Pertenece a/Tiene uno)

Digamos que una película tiene un distribuidor, por ejemplo, Netflix es el distribuidor de su película original "Bright"

Vamos a definir la migración del `Distributor` (Distribuidor) y su esquema con la relación `belongs_to`. Primero, vamos a generar la migración:

```console
mix ecto.gen.migration create_distributors
```

Debemos agregar una llave foranea de `movie_id` a la migración de la tabla `distributors` que acabamos de crear así como un índice único para asegurarnos de que una película tiene únicamente un distribuidor:

```elixir
# priv/repo/migrations/*_create_distributors.exs

defmodule Friends.Repo.Migrations.CreateDistributors do
  use Ecto.Migration

  def change do
    create table(:distributors) do
      add :name, :string
      add :movie_id, references(:movies)
    end
    
    create unique_index(:distributors, [:movie_id])
  end
end
```

Y el esquema `Distributor` debería usar el macro `belongs_to/3` que nos permite llamar `distributor.movie` y buscar la película asociada al distribuidor usando esta llave foranea.

```elixir
# lib/example/distributor.ex

defmodule Friends.Distributor do
  use Ecto.Schema

  schema "distributors" do
    field :name, :string
    belongs_to :movie, Friends.Movie
  end
end
```

Después, vamos a agregar la relación `has_one` a el esquema `Movie`:

```elixir
# lib/example/movie.ex

defmodule Friends.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Friends.Character
    has_one :distributor, Friends.Distributor # I'm new!
  end
end
```

El macro `has_one/3` funciona justo como el macro `has_many/3`. Usa la llave foranea del esquema asociado para buscar y exponer el distribuidor de la película. Esto nos permite llamar `movie.distributor`

Ya estamos listos para ejecutar nuestras migraciones:

```console
mix ecto.migrate
```

### Muchos a Muchos

Digamos que una película tiene muchos actores, y que un actor puede pertenecer a más de una película. Vamos a construir una talba de asociación que referencía _ambas_ películas _y_ actores para implementar esta relación.

Primero, vamos a generar la migración `Actors` (Actores):

```console
mix ecto.gen.migration create_actors
```

Define la migración:

```elixir
# priv/migrations/*_create_actors.ex

defmodule Friends.Repo.Migrations.Actors do
  use Ecto.Migration

  def change do
    create table(:actors) do
      add :name, :string
    end
  end
end
```

Vamos a generar nuestra migración de la tabla de asociación:

```console
mix ecto.gen.migration create_movies_actors
```

Vamos a definir nuestra migración de forma que la tabla tiene dos llaves foraneas. También vamos a añadir un índice único para asegurarnos de que existan pares únicos de actores y películas:

```elixir
# priv/migrations/*_create_movies_actors.ex

defmodule Friends.Repo.Migrations.CreateMoviesActors do
  use Ecto.Migration

  def change do
    create table(:movies_actors) do
      add :movie_id, references(:movies)
      add :actor_id, references(:actors)
    end

    create unique_index(:movies_actors, [:movie_id, :actor_id])
  end
end
```

Después, vamos a agregar el macro `many_to_many` a nuestro esquema `Movie`:

```elixir
# lib/example/movie.ex

defmodule Friends.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Friends.Character
    has_one :distributor, Friends.Distributor
    many_to_many :actors, Friends.Actor, join_through: "movies_actors" # I'm new!
  end
end
```

Finalmente, definiremos nuestro esquema `Actor` con el mismo macro `many_to_may`.

```elixir
# lib/example/actor.ex

defmodule Friends.Actor do
  use Ecto.Schema

  schema "actors" do
    field :name, :string
    many_to_many :movies, Friends.Movie, join_through: "movies_actors"
  end
end
```

Estamos listos para ejecutar nuestras migraciones:

```console
mix ecto.migrate
```

## Guardando Datos Asociados

La manera en la que guardamos registros junto con sus datos asociados, depende de la naturaleza de la relación entre los registros. Vamos a comenzar con la relación "Belongs to/has many".

### Belongs To

#### Guardando con `Ecto.build_assoc/3`

Con una relación "belongs to", podemos aprovechar la función de Ecto `build_assoc/3`.

[`build_assoc/3`](https://hexdocs.pm/ecto/Ecto.html#build_assoc/3) toma tres argumentos:

* La estructura del registro que queremos guardar.
* El nombre de la asociación.
* Cualquier atributo que queremos asignar a el registro asociado que estamos guardando.

Vamos a guardar una película y un personaje asociado. Primero, vamos a crear un registro de una película:

```elixir
iex> alias Friends.{Movie, Character, Repo}
iex> movie = %Movie{title: "Ready Player One", tagline: "Something about video games"}

%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:built, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: nil,
  tagline: "Something about video games",
  title: "Ready Player One"
}

iex> movie = Repo.insert!(movie)
```

Ahora construiremos nuestro personaje asociado y lo insertaremos en la base de datos:

```elixir
character = Ecto.build_assoc(movie, :characters, %{name: "Wade Watts"})
%Friends.Character{
  __meta__: %Ecto.Schema.Metadata<:built, "characters">,
  id: nil,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Wade Watts"
}
Repo.insert!(character)
%Friends.Character{
  __meta__: %Ecto.Schema.Metadata<:loaded, "characters">,
  id: 1,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Wade Watts"
}
```

Nota que como el macro `has_many/3` del esquema `Movie` especifica que una película tiene muchos `:characters`, el nombre de la asociación que pasamos como segundo argumento a `build_assoc/3` es exactamente ese: `:characters`. Podemos ver que hemos creado un personaje que tiene su `movie_id` propiamente establecido como ID de la película asociada.

Para poder usar `build_assoc/3` para guardar un distribuidor asociado a una película, tomamos el mismo enfoque de pasar el _nombre_ de la relación de la película al distribuidor como el segundo argumento de `build_assoc/3`:

```elixir
iex> distributor = Ecto.build_assoc(movie, :distributor, %{name: "Netflix"})
%Friends.Distributor{
  __meta__: %Ecto.Schema.Metadata<:built, "distributors">,
  id: nil,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Netflix"
}
iex> Repo.insert!(distributor)
%Friends.Distributor{
  __meta__: %Ecto.Schema.Metadata<:loaded, "distributors">,
  id: 1,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Netflix"
}
```

### Muchos a Muchos

#### Guardando con `Ecto.Changeset.put_assoc/4`

La estrategia `build_assoc/3` no funcionará para nuestra relación muchos-a-muchos. Esto es porque ni el actor ni la película contienen una llave foranea. En su lugar, necesitamos aprovechar los Changesets de Ecto y la función `put_assoc/4`

Asumiendo que ya tenemos el registro de la película que creamos arriba, vamos a crear un registro de actror:

```elixir
iex> alias Friends.Actor
iex> actor = %Actor{name: "Tyler Sheridan"}
%Friends.Actor{
  __meta__: %Ecto.Schema.Metadata<:built, "actors">,
  id: nil,
  movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
  name: "Tyler Sheridan"
}
iex> actor = Repo.insert!(actor)
%Friends.Actor{
  __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
  id: 1,
  movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
  name: "Tyler Sheridan"
}
```

Ahora estamos listos para asociar nuestra película a nuestro actor a travez de la tabal de asociación.

Primero, ten en cuenta que para trabajar con changesets, necesitamos asegurarnos de que nuestra estructura `movie` tiene precargados datos asociados. Vamos a hablar más acerca de precargar los datos en un momento. Por ahora, es suficiente con entender que podemos precargar nuestra asociación así:

```elixir
iex> movie = Repo.preload(movie, [:distributor, :characters, :actors])
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [],
  characters: [],
  distributor: nil,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Después, vamos a crear un changeset para nuestro registro película:

```elixir
iex> movie_changeset = Ecto.Changeset.change(movie)
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Movie<>,
 valid?: true>
```

Ahora vamos a pasar nuestro changeset como el primer argumento a [`Ecto.Changeset.put_assoc/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#put_assoc/4):

```elixir
iex> movie_actors_changeset = movie_changeset |> Ecto.Changeset.put_assoc(:actors, [actor])
%Ecto.Changeset<
  action: nil,
  changes: %{
    actors: [
      %Ecto.Changeset<action: :update, changes: %{}, errors: [],
       data: %Friends.Actor<>, valid?: true>
    ]
  },
  errors: [],
  data: %Friends.Movie<>,
  valid?: true
>
```

Esto nos da un _nuevo_ changeset que representa el siguiente cambio: agregar los actores en la lista de actores a el registro de película proporcionado.

Por último, actualizaremos los registros de película y actor proporcionados usando nuestro último changeset:

```elixir
iex> Repo.update!(movie_actors_changeset)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Friends.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
      id: 1,
      movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Bob"
    }
  ],
  characters: [],
  distributor: nil,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Ahora podemos ver que esto nos devuelve un registro de película con el nuevo actor propiamente asociado y ya precargado para nosotros en `movie.actors`.

Podemos usar la misma estrategia para crear un nuevo actor que está asociado con la película proporcionada. En lugar de pasar una estructura de actor _guardada_ a `put_assoc/4`, nosotros simplemente pasamos una estructura de actor describiendo un nuevo actor que queremos crear:

```elixir
iex> changeset = movie_changeset |> Ecto.Changeset.put_assoc(:actors, [%{name: "Gary"}])
%Ecto.Changeset<
  action: nil,
  changes: %{
    actors: [
      %Ecto.Changeset<
        action: :insert,
        changes: %{name: "Gary"},
        errors: [],
        data: %Friends.Actor<>,
        valid?: true
      >
    ]
  },
  errors: [],
  data: %Friends.Movie<>,
  valid?: true
>
iex>  Repo.update!(changeset)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Friends.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
      id: 2,
      movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Gary"
    }
  ],
  characters: [],
  distributor: nil,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Podemos ver que un nuevo actor fue creado, con un ID "2" y los atributos que le asignamos.

En la siguiente sección, aprenderemos como consultar nuestros registros asociados.
