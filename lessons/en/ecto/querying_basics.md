%{
  version: "1.2.1",
  title: "Querying",
  excerpt: """
  """
}
---

In this lesson, we'll continue building off the `Friends` app and the movie-cataloguing domain we set up in the [previous lesson](/en/lessons/ecto/associations).

## Fetching Records with Ecto.Repo

Recall that a "repository" in Ecto maps to a datastore such as our Postgres database.
All communication to the database will be done using this repository.

We can perform simple queries directly against our `Friends.Repo` with the help of a handful of functions.

### Fetching Records by ID

We can use the `Repo.get/3` function to fetch a record from the database given its ID. This function requires two arguments: a "queryable" data structure and the ID of a record to retrieve from the database. It returns a struct describing the record found, if any. It returns `nil` if no such record is found.

Let's take a look at an example. Below, we'll get the movie with an ID of 1:

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

Notice that the first argument we give to `Repo.get/3` is our `Movie` module. `Movie` is "queryable" because the module uses the `Ecto.Schema` module and defines a schema for its data structure. This gives `Movie` access to the `Ecto.Queryable` protocol. This protocol converts a data structure into an `Ecto.Query`. Ecto queries are used to retrieve data from a repository. More on queries later.

### Fetching Records by Attribute

We can also fetch records that meet a given criteria with the `Repo.get_by/3` function. This function requires two arguments: the "queryable" data structure and the clause with which we want to query. `Repo.get_by/3` returns a single result from the repository. Let's look at an example:

```elixir
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

If we want to write more complex queries, or if we want to return _all_ records that meet a certain condition, we need to use the `Ecto.Query` module.

## Writing Queries with Ecto.Query

The `Ecto.Query` module provides us with the Query DSL which we can use to write queries to retrieve data from the application's repository.

### Keyword-based queries with Ecto.Query.from/2

We can create a query with the `Ecto.Query.from/2` macro. This function takes in two arguments: an expression and an optional keyword list. Let's create the most simple query to select all of the movies from our repository:

```elixir
iex> import Ecto.Query
iex> query = from(Movie)
#Ecto.Query<from m0 in Friends.Movie>
```

In order to execute our query, we use the `Repo.all/2` function. This function takes in a required argument of an Ecto query and returns all of the records that meet the conditions of the query.

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

#### Bindingless queries with from

The example above lacks the most fun parts of SQL statements. We often want to only query for specific fields or filter records by some condition. Let's fetch `title` and `tagline` of all movies that have `"Ready Player One"` title:

```elixir
iex> query = from(Movie, where: [title: "Ready Player One"], select: [:title, :tagline])
#Ecto.Query<from m0 in Friends.Movie, where: m0.title == "Ready Player One",
 select: [:title, :tagline]>

iex> Repo.all(query)
SELECT m0."title", m0."tagline" FROM "movies" AS m0 WHERE (m0."title" = 'Ready Player One') []
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    id: nil,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

Please note that the returned struct only has `tagline` and `title` fields set – this is the result of our `select:` part.

Queries like this are called _bindingless_, because they are simple enough to not require bindings.

#### Bindings in queries

So far we used a module that implements the `Ecto.Queryable` protocol (ex: `Movie`) as the first argument for `from` macro. However, we can also use `in` expression, like this:

```elixir
iex> query = from(m in Movie)
#Ecto.Query<from m0 in Friends.Movie>
```

In such case, we call `m` a _binding_. Bindings are extremely useful, because they allow us to reference modules in other parts of the query. Let's select titles of all movies that have `id` less than `2`:

```elixir
iex> query = from(m in Movie, where: m.id < 2, select: m.title)
#Ecto.Query<from m0 in Friends.Movie, where: m0.id < 2, select: m0.title>

iex> Repo.all(query)
SELECT m0."title" FROM "movies" AS m0 WHERE (m0."id" < 2) []
["Ready Player One"]
```

The very important thing here is how output of the query changed. Using an _expression_ with a binding in `select:` part allows you to specify exactly the way selected fields will be returned. We can ask for a tuple, for example:

```elixir
iex> query = from(m in Movie, where: m.id < 2, select: {m.title})

iex> Repo.all(query)
[{"Ready Player One"}]
```

It is a good idea to always start with a simple bindingless query and introduce a binding whenever you need to reference your data structure. More on bindings in queries can be found in [Ecto documentation](https://hexdocs.pm/ecto/Ecto.Query.html#module-query-expressions)

### Macro-based queries

In the examples above we used keywords `select:` and `where:` inside of `from` macro to build a query – these are so called _keyword-based queries_. There is, however, another way to compose queries – macro-based queries. Ecto provides macros for every keyword, like `select/3` or `where/3`. Each macro accepts a _queryable_ value, _an explicit list of bindings_ and the same expression you'd provide to its keyword analogue:

```elixir
iex> query = select(Movie, [m], m.title)
#Ecto.Query<from m0 in Friends.Movie, select: m0.title>

iex> Repo.all(query)
SELECT m0."title" FROM "movies" AS m0 []
["Ready Player One"]
```

The good thing about macros is that they work very well with pipes:

```elixir
iex> Movie \
...>  |> where([m], m.id < 2) \
...>  |> select([m], {m.title}) \
...>  |> Repo.all
[{"Ready Player One"}]
```

Note that to continue writing after the line break, use the character `\`.

### Using where with Interpolated Values

In order to use interpolated values or Elixir expressions in our where clauses, we need to use the `^`, or pin, operator. This allows us to _pin_ a value to a variable and refer to that pinned value, instead of re-binding that variable.

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

### Getting the First and Last Records

We can fetch the first or last records from a repository using the `Ecto.Query.first/2` and `Ecto.Query.last/2` functions.

First, we'll write a query expression using the `first/2` function:

```elixir
iex> first(Movie)
#Ecto.Query<from m0 in Friends.Movie, order_by: [asc: m0.id], limit: 1>
```

Then we pass our query to the `Repo.one/2` function to get our result:

```elixir
iex> Movie |> first() |> Repo.one()

SELECT m0."id", m0."title", m0."tagline" FROM "movies" AS m0 ORDER BY m0."id" LIMIT 1 []
%Friends.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

The `Ecto.Query.last/2` function is used in the same way:

```elixir
iex> Movie |> last() |> Repo.one()
```

## Querying For Associated data

### Preloading

In order to be able to access the associated records that the `belongs_to`, `has_many` and `has_one` macros expose to us, we need to _preload_ the associated schemas.

Let's take a look to see what happens when we try to ask a movie for its associated actors:

```elixir
iex> movie = Repo.get(Movie, 1)
iex> movie.actors
%Ecto.Association.NotLoaded<association :actors is not loaded>
```

We _can't_ access those associated characters unless we preload them. There are a few different ways to preload records with Ecto.

#### Preloading With Two Queries

The following query will preload associated records in a _separate_ query.

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
        name: "Tyler Sheridan"
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

We can see that the above line of code ran _two_ database queries. One for all of the movies, and another for all of the actors with the given movie IDs.

#### Preloading With One Query

We can cut down on our database queries with the following:

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
        name: "Tyler Sheridan"
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

This allows us to execute just one database call. It also has the added benefit of allowing us to select and filter both movies and associated actors in the same query. For example, this approach allows us to query for all movies where the associated actors meet certain conditions using a `join` statement. Something like:

```elixir
Repo.all from m in Movie,
  join: a in assoc(m, :actors),
  where: a.name == "John Wayne",
  preload: [actors: a]
```

More on join statements in a bit.

#### Preloading Fetched Records

We can also preload the associated schemas of records that have already been queried from the database.

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
      name: "Tyler Sheridan"
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

Now we can ask a movie for its actors:

```elixir
iex> movie.actors
[
  %Friends.Actor{
    __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
    id: 1,
    movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Tyler Sheridan"
  },
  %Friends.Actor{
    __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
    id: 2,
    movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Gary"
  }
]
```

### Using Join Statements

We can execute queries that include join statements with the help of the `Ecto.Query.join/5` function.

```elixir
iex> alias Friends.Character
iex> query = from m in Movie,
              join: c in Character,
              on: m.id == c.movie_id,
              where: c.name == "Wade Watts",
              select: {m.title, c.name}
iex> Repo.all(query)
15:28:23.756 [debug] QUERY OK source="movies" db=5.5ms
[{"Ready Player One", "Wade Watts"}]
```

The `on` expression can also use a keyword list:

```elixir
from m in Movie,
  join: c in Character,
  on: [id: c.movie_id], # keyword list
  where: c.name == "Wade Watts",
  select: {m.title, c.name}
```

In the example above, we are joining on an Ecto schema, `m in Movie`. We can also join on an Ecto query. Let's say our movies table has a column `stars`, where we store the "star rating" of the film, a number 1-5.

```elixir
movies = from m in Movie, where: [stars: 5]
from c in Character,
  join: ^movies,
  on: [id: c.movie_id], # keyword list
  where: c.name == "Wade Watts",
  select: {m.title, c.name}
```

The Ecto Query DSL is a powerful tool that provides us with everything we need to make even complex database queries. With this introduction provides you with the basic building blocks to start querying.
