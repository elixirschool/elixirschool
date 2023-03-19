%{
  version: "1.2.2",
  title: "Associations",
  excerpt: """
  In this section we'll learn how to use Ecto to define and work with associations between our schemas.
  """
}
---

## Set Up

We'll start off with the same `Friends` app from the previous lesson. You can refer to the setup [here](/en/lessons/ecto/basics) for a quick refresher.

## Types of Associations

There are three types of associations we can define between our schemas. We'll look at what they are and how to implement each type of relationship.

### Belongs To/Has Many

We're adding some new entities to our Friends app's domain model so that we can catalogue our favorite films. We'll start with two schemas: `Movie` and `Character`. We'll implement a "has many/belongs to" relationship between these two schemas: A movie has many characters and a character belongs to a movie.

#### The Has Many Migration

Let's generate a migration for `Movie`:

```console
mix ecto.gen.migration create_movies
```

Open up the newly generated migration file and define your `change` function to create the `movies` table with a few attributes:

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

#### The Has Many Schema

We'll add a schema that specifies the "has many" relationship between a movies and its characters.

```elixir
# lib/friends/movie.ex
defmodule Friends.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Friends.Character
  end
end
```

The `has_many/3` macro doesn't add anything to the database itself. What it does is use the foreign key on the associated schema, `characters`, to make a movie's associated characters available. This is what will allow us to call `movie.characters`.

#### The Belongs To Migration

Now we're ready to build our `Character` migration and schema. A character belongs to a movie, so we'll define a migration and schema that specifies this relationship.

First, generate the migration:

```console
mix ecto.gen.migration create_characters
```

To declare that a character belongs to a movie, we need the `characters` table to have a `movie_id` column. We want this column to function as a foreign key. We can accomplish this with the following line in our `create table/1` function:

```elixir
add :movie_id, references(:movies)
```

So our migration should look like this:

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

#### The Belongs To Schema

Our schema likewise needs to define the "belongs to" relationship between a character and its movie.

```elixir
# lib/friends/character.ex

defmodule Friends.Character do
  use Ecto.Schema

  schema "characters" do
    field :name, :string
    belongs_to :movie, Friends.Movie
  end
end
```

Let's take a closer look at what the `belongs_to/3` macro does for us. In addition to adding the foreign key `movie_id` to our schema, it also gives us the ability to access associated `movies` schema _through_ `characters`. It uses the foreign key to make a character's associated movie available when we query for them. This is what will allow us to call `character.movie`.

Now we're ready to run our migrations:

```console
mix ecto.migrate
```

### Belongs To/Has One

Let's say that a movie has one distributor, for example Netflix is the distributor of their original film "Bright".

We'll define the `Distributor` migration and schema with the "belongs to" relationship. First, let's generate the migration:

```console
mix ecto.gen.migration create_distributors
```

We should add a foreign key of `movie_id` to the `distributors` table migration we just generated as well as a unique index to enforce that a movie has only one distributor:

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

And the `Distributor` schema should use the `belongs_to/3` macro to allow us to call `distributor.movie` and look up a distributor's associated movie using this foreign key.

```elixir
# lib/friends/distributor.ex

defmodule Friends.Distributor do
  use Ecto.Schema

  schema "distributors" do
    field :name, :string
    belongs_to :movie, Friends.Movie
  end
end
```

Next up, we'll add the "has one" relationship to the `Movie` schema:

```elixir
# lib/friends/movie.ex

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

The `has_one/3` macro functions just like the `has_many/3` macro. It uses the associated schema's foreign key to look up and expose the movie's distributor. This will allow us to call `movie.distributor`.

We're ready to run our migrations:

```console
mix ecto.migrate
```

### Many To Many

Let's say that a movie has many actors and that an actor can belong to more than one movie. We'll build a join table that references _both_ movies _and_ actors to implement this relationship.

First, let's generate the `Actors` migration:

```console
mix ecto.gen.migration create_actors
```

Define the migration:

```elixir
# priv/migrations/*_create_actors.ex

defmodule Friends.Repo.Migrations.CreateActors do
  use Ecto.Migration

  def change do
    create table(:actors) do
      add :name, :string
    end
  end
end
```

Let's generate our join table migration:

```console
mix ecto.gen.migration create_movies_actors
```

We'll define our migration such that the table has two foreign keys. We'll also add a unique index to enforce unique pairings of actors and movies:

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

Next up, let's add the `many_to_many` macro to our `Movie` schema:

```elixir
# lib/friends/movie.ex

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

Finally, we'll define our `Actor` schema with the same `many_to_many` macro.

```elixir
# lib/friends/actor.ex

defmodule Friends.Actor do
  use Ecto.Schema

  schema "actors" do
    field :name, :string
    many_to_many :movies, Friends.Movie, join_through: "movies_actors"
  end
end
```

We're ready to run our migrations:

```console
mix ecto.migrate
```

## Saving Associated Data

The manner in which we save records along with their associated data depends on the nature of the relationship between the records. Let's start with the "Belongs to/has many" relationship.

### Belongs To

#### Saving With Ecto.build_assoc/3

With a "belongs to" relationship, we can leverage Ecto's `build_assoc/3` function.

[`build_assoc/3`](https://hexdocs.pm/ecto/Ecto.html#build_assoc/3) takes in three arguments:

* The struct of the record we want to save.
* The name of the association.
* Any attributes we want to assign to the associated record we are saving.

Let's save a movie and an associated character. First, we'll create a movie record:

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

Now we'll build our associated character and insert it into the database:

```elixir
iex> character = Ecto.build_assoc(movie, :characters, %{name: "Wade Watts"})
%Friends.Character{
  __meta__: %Ecto.Schema.Metadata<:built, "characters">,
  id: nil,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Wade Watts"
}
iex> Repo.insert!(character)
%Friends.Character{
  __meta__: %Ecto.Schema.Metadata<:loaded, "characters">,
  id: 1,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Wade Watts"
}
```

Notice that since the `Movie` schema's `has_many/3` macro specifies that a movie has many `:characters`, the name of the association that we pass as a second argument to `build_assoc/3` is exactly that: `:characters`. We can see that we've created a character that has its `movie_id` properly set to the ID of the associated movie.

In order to use `build_assoc/3` to save a movie's associated distributor, we take the same approach of passing the _name_ of the movie's relationship to distributor as the second argument to `build_assoc/3`:

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

### Many to Many

#### Saving With Ecto.Changeset.put_assoc/4

The `build_assoc/3` approach won't work for our many-to-many relationship. That is because neither the movie nor actor tables contain a foreign key. Instead, we need to leverage Ecto Changesets and the `put_assoc/4` function.

Assuming we already have the movie record we created above, let's create an actor record:

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

Now we're ready to associate our movie to our actor via the join table.

First, note that in order to work with changesets, we need to make sure that our `movie` structure has preloaded associated data. We'll talk more about preloading data in a bit. For now, it's enough to understand that we can preload our associations like this:

```elixir
iex> movie = Repo.preload(movie, [:distributor, :characters, :actors])
%Friends.Movie{
 __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [],
  characters: [
    %Friends.Character{
      __meta__: #Ecto.Schema.Metadata<:loaded, "characters">,
      id: 1,
      movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
      movie_id: 1,
      name: "Wade Watts"
    }
  ],
  distributor: %Friends.Distributor{
    __meta__: #Ecto.Schema.Metadata<:loaded, "distributors">,
    id: 1,
    movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
    movie_id: 1,
    name: "Netflix"
  },
  id: 1,
  tagline: "Something about video game",
  title: "Ready Player One"
}
```

Next up, we'll create a changeset for our movie record:

```elixir
iex> movie_changeset = Ecto.Changeset.change(movie)
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Movie<>,
 valid?: true>
```

Now we'll pass our changeset as the first argument to [`Ecto.Changeset.put_assoc/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#put_assoc/4):

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

This gives us a _new_ changeset that represents the following change: add the actors in this list of actors to the given movie record.

Lastly, we'll update the given movie and actor records using our latest changeset:

```elixir
iex> Repo.update!(movie_actors_changeset)
%Friends.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Friends.Actor{
      __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
      id: 1,
      movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Tyler Sheridan"
    }
  ],
  characters: [
    %Friends.Character{
      __meta__: #Ecto.Schema.Metadata<:loaded, "characters">,
      id: 1,
      movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
      movie_id: 1,
      name: "Wade Watts"
    }
  ],
  distributor: %Friends.Distributor{
    __meta__: #Ecto.Schema.Metadata<:loaded, "distributors">,
    id: 1,
    movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
    movie_id: 1,
    name: "Netflix"
  },
  id: 1,
  tagline: "Something about video game",
  title: "Ready Player One"
}
```

We can see that this gives us a movie record with the new actor properly associated and already preloaded for us under `movie.actors`.

We can use this same approach to create a brand new actor that is associated with the given movie. Instead of passing a _saved_ actor struct into `put_assoc/4`, we simply pass in a map of attributes describing a new actor that we want to create:

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

We can see that a new actor was created with an ID of "2" and the attributes we assigned it.

In the next section, we'll learn how to query for our associated records.
