---
version: 1.0.3
title: Querying
---

{% include toc.html %}

En esta lección construiremos una la aplicación `Friends` y el catálogo de películas que configuramos en nuestra [lección anterior](./associations)

## Obteniendo registros con `Ecto.Repo`

Recuerda que un "repositorio" en Ecto se relaciona a un set de datos como nuestra base de datos Postgres.
Toda comunicación con la base se hará utilizando este repositorio.

Podemos ejecutar consultas simples directamente contra nuestro `Friends.Repo` con la ayuda de algunas funciones.

### Obteniendo registros por ID

Podemos usar la función `Repo.get/3` para obtener un registro de la base de datos dado su ID. Esta función requiere dos argumentos: una estructura "queryable" y el ID del registro a obtener de la base de datos. Regresa una estructura que describe el registro encontrado, si lo hay. Si no se encontrara el registro, esta regresa `nil`.

Veamos un ejemplo. Obtendremos una película con el ID 1:

```elixir
iex> alias Friends.{Repo, Movie}
iex> Repo.get(Movie, 1)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

 Como podrás observar, el primer argumento que le damos a `Repo.get/3` es nuestro módulo `Movie`. `Movie` es "queryable" porque usa el módulo `Ecto.Schema` para definir un esquema para su estructura de datos. Esto permite que `Movie` acceda al protocolo `Ecto.Queryable`. El protocolo convierte la estructura de datos en un `Ecto.Query`. Las consultas de Ecto se usan para obtener información de un repositorio. Hablaremos más sobre consultas luego.

### Obteniendo registros por atributo

También podemos obtener registros que cumplan con ciertos criterios con la función `Repo.get_by/3`. Esta función requiere dos argumentos: la estructura de datos "queryable" y la cláusula con la que vamos a consultar. `Repo.get_by/3` regresa un solo registro del repositorio. Veamos un ejemplo:

```elixir
iex> alias Friends.Repo
iex> alias Friends.Movie
iex> Repo.get_by(Movie, title: "Ready Player One")
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Si queremos escribir consultas más complejas o si queremos regresar _todos_ los registros que cumplan con cierta condición tenemos que usar el módulo `Ecto.Query`.

## Escribiendo consultas con `Ecto.Query`

El módulo `Ecto.Query` nos proveé con un DSL que podemos usar para escribir consultas para obtener información del repositorio de nuestra aplicación.

### Creando consultas con `Ecto.Query.from/2`

Podemos crear una consulta con la función `Ecto.Query.from/2`. Esta función toma dos argumentos: una expresión y una keyword list. Hagamos un consulta que obtenga todas las películas de nuestro repositorio:

```elixir
import Ecto.Query
query = from(m in Movie, select: m)
#Ecto.Query<from m in Friends.Movie, select: m>
```

Para poder ejecutar esta consulta usaremos la función `Repo.all/2`. Essta función toma como argumento requerido una consulta de Ecto y retorna todos los registros que cumplen con las condiciones de la consulta.

```elixir
iex> Repo.all(query)

14:58:03.187 [debug] QUERY OK source="movies" db=1.7ms decode=4.2ms
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

#### Usando `from` en Keyword Queries

El ejemplo anterior le da a `from/2` un argumento de un "keyword query". Cuando usamos `from` con un keyword query, el primer argumento puede ser una de dos cosas:

* Una expresión `in` (ex. `m in Movie`)
* Un módulo que implementa el protocolo `Ecto.Queryable` (ex: `Movie`)

El segundo argumento en nuestro keyword query `select`.

#### Usando `from` con una Query Expression

Cuando se usa `from` con una query expression, el primer argumento debe ser un valor que implemente el protocolo `Ecto.Queryable` (ex: `Movie`). El segundo argumento es una expresión. Veamos un ejemplo:

```elixir
iex> query = select(Movie, [m], m)
%Ecto.Query<from m in Friends.Movie, select: m>
iex> Repo.all(query)

06:16:20.854 [debug] QUERY OK source="movies" db=0.9ms
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

Puedes usar query expressions cuando _no_ necesitas usar `in` (`m in Movie`). No necesitas usar `in` cuando no necesitas una referencia a la estructura de datos. La consulta de arriba no requiere una referencia a la estructura de datos. No estamos, por ejemplo, seleccionando películas donde se cumpla cierta condición, por lo que no es necesario usar expresiones y consultas con `in`.

### Usando expresiones `select`

Usamos la función `Ecto.Query.select/3` para especificar donde se declara que seleccionaremos en nuestra consulta. Si queremos seleccionar sólo ciertos campos, podemos especificar esos campos como una lista de átomos o haciendo referencia a las llaves de una estructura. Revisemos el primer enfoque:

```elixir
iex> query = select(Movie, [:title])
%Ecto.Query<from m in Friends.Movie, select: [:title]>
iex> Repo.all(query)

15:15:25.842 [debug] QUERY OK source="movies" db=1.3ms
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: nil,
    tagline: nil,
    title: "Ready Player One"
  }
]
```

Démonos cuenta que _no_ usamos la expresión `in` en el primer argumento que le damos a nuestra función `from`. Eso es porque no necesitamos crear una referencia a nuestra estructura de datos en orden para usar un keyword list con `select`.

Este enfoque regresa una estructura sólo con el campo `title` lleno.

El segundo enfoque se comporta un poco diferente. Ahora, *necesitamos* usar una expresión `in`. Eso es porque necesitamos crear una referencia a la estructura de datos en orden para poder especificar la llave `title` de nuestra estructura de película.

```elixir
iex(15)> query = from(m in Movie, select: m.title)
%Ecto.Query<from m in Friends.Movie, select: m.title>
iex(16)> Repo.all(query)

15:06:12.752 [debug] QUERY OK source="movies" db=4.5ms queue=0.1ms
["Ready Player One"]
```

En esta forma de usar `select` regresamos una lista conteniendo los valores seleccionados.

### Usando expresiones `where`

Podemos usar expresiones `where` para incluir cláusulas "where" en nuestras consultas. Múltiples expresiones `where` se combinan en sentencias SQL `WHERE AND`.

```elixir
iex> query = from(m in Movie, where: m.title == "Ready Player One")
%Ecto.Query<from m in Friends.Movie, where: m.title == "Ready Player One">
iex> Repo.all(query)

15:18:35.355 [debug] QUERY OK source="movies" db=4.1ms queue=0.1ms
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

Podemos usar expresiones `where` en conjunto con `select`:

```elixir
iex> query = from(m in Movie, where: m.title == "Ready Player One", select: m.tagline)
%Ecto.Query<from m in Friends.Movie, where: m.title == "Ready Player One", select: m.tagline>
iex> Repo.all(query)

15:19:11.904 [debug] QUERY OK source="movies" db=4.1ms
["Something about video games"]
```

### Usando `where` con valores interpolados

En orden para usar valores interpolados o expresiones de Elixir en nuestras cláusulas where necesitamos usar el operador `^`. Esto nos permite _fijar_ el valor a una variable y hacer referencia a este valor en vez de reasignar la variable.

```elixir
iex> title = "Ready Player One"
"Ready Player One"
iex> query = from(m in Movie, where: m.title == ^title, select: m.tagline)
%Ecto.Query<from m in Friends.Movie, where: m.title == ^"Ready Player One",
 select: m.tagline>
iex> Repo.all(query)

15:21:46.809 [debug] QUERY OK source="movies" db=3.8ms
["Something about video games"]
```

### Obteniendo el primero y el último registro

Podemos obtener el primer o último registro de nuestro repositorio utilizando las funciones `Ecto.Query.first/2` y `Ecto.Query.last/2`.

Primero escribiremos una expresión usando la función `first/2`:

```elixir
iex> first(Movie)
%Ecto.Query<from m in Friends.Movie, order_by: [desc: m.id], limit: 1>
```

Después, pasamos nuestra consulta a la función `Repo.one/2` para obtener nuestro resultado:

```elixir
iex> Movie |> first() |> Repo.one()

06:36:14.234 [debug] QUERY OK source="movies" db=3.7ms
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

La función `Ecto.Query.last/2` se usa de la misma manera:

```elixir
iex> Movie |> last() |> Repo.one()
```

## Haciendo consultas de información relacionada

### Precargando

Para poder acceder a los registros asociados que los macros `belongs_to`, `has_many` y `has_one` nos exponen, debemos _precargar_ los esquemas asociados.

Veamos que ocurre cuando intentamos consultar los actores asociados a una película:

```elixir
iex> movie = Repo.get(Movie, 1)
iex> movie.actors
%Ecto.Association.NotLoaded<association :actors is not loaded>
```

No podemos acceder a estos personajes asociados a menos de que los precarguemos. Existen diferentes maneras de precargar registros con Ecto.

#### Precargando con dos consultas

La siguiente consulta precargará los registros asociados en una consulta _por separado_.

```elixir
iex> Repo.all(from m in Movie, preload: [:actors])

13:17:28.354 [debug] QUERY OK source="movies" db=2.3ms queue=0.1ms
13:17:28.357 [debug] QUERY OK source="actors" db=2.4ms
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Bob"
      },
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 2,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Gary"
      }
    ],
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

Podemos observar que el código anterior ejecutó _dos_ consultas a la base de datos. Uno para todas las películas y otro para todos los actores con los IDs dados de las películas.

#### Precargando con una sola consulta

Podemos reducir nuestras consultas a la base de datos con lo siguiente:

```elixir
iex> query = from(m in Movie, join: a in assoc(m, :actors), preload: [actors: a])
iex> Repo.all(query)

13:18:52.053 [debug] QUERY OK source="movies" db=3.7ms
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Bob"
      },
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 2,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Gary"
      }
    ],
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

Esto nos permite ejecutar sólo una llamada a la base de datos. También tiene el beneficio de permitirnos seleccionar y filtrar tanto películas como actores en una misma consulta. Por ejemplo, este enfoque nos permite consultar todas las películas cuyos actores asociados cumplan con ciertas condiciones, usando la sentencia `join`. Algo como:

```elixir
Repo.all from m in Movie,
  join: a in assoc(m, :actors),
  where: a.name == "John Wayne",
  preload: [actors: a]
```

Más sobre sentencias join después.

#### Precargando registros obtenidos

También podemos precargar esquemas asociados a registros que ya hayamos consultado con anterioridad.

```elixir
iex> movie = Repo.get(Movie, 1)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>, # actors are NOT LOADED!!
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
iex> movie = Repo.preload(movie, :actors)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Friends.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
      id: 1,
      movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Bob"
    },
    %Friends.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
      id: 2,
      movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Gary"
    }
  ], # actors are LOADED!!
  characters: [],
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Ahora podemos preguntar por los actores de una película.

```elixir
iex> movie.actors
[
  %Friends.Actor{
    __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
    id: 1,
    movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Bob"
  },
  %Friends.Actor{
    __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
    id: 2,
    movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Gary"
  }
]
```

### Usando sentencias Join

Podemos ejecutar consultas que incluyen sentencias join con ayuda de la función `Ecto.Query.join/5`.

```elixir
iex> query = from m in Movie,
              join: c in Character,
              on: m.id == c.movie_id,
              where: c.name == "Wade Watts",
              select: {m.title, c.name}
iex> Repo.all(query)
15:28:23.756 [debug] QUERY OK source="movies" db=5.5ms
[{"Ready Player One", "Wade Watts"}]
```

La expresión `on` puede usarse también con una keyword list:

```elixir
from m in Movie,
  join: c in Character,
  on: [id: c.movie_id], # keyword list
  where: c.name == "Wade Watts",
  select: {m.title, c.name}
```

En el ejemplo anterior estamos haciendo join en un esquema de Ecto, `m in Movie`. También podemos hacer join sobre una consulta de Ecto. Digamos que nuestra tabla de películas tiene una columna `stars` donde guardamos el rating en estrellas de nuestro filme, con un valor entre 1 y 5.

```elixir
movies = from m in Movie, where: [stars: 5]
from c in Character,
  join: ^movies,
  on: [id: c.movie_id], # keyword list
  where: c.name == "Wade Watts",
  select: {m.title, c.name}
```

El DSL para consultas de Ecto es una poderosa herramienta que nos proveé con todo lo que necesitamos para crear hasta consultas muy complejas de la base de datos. Lo que esta introducción nos da son las bases para empezar a hacer consultas.
