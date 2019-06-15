---
version: 1.0.1
title: Querying
---

{% include toc.html %}

In this lesson, we'll be building off `Example` app and the movie-cataloguing domain we set up in the [previous lesson](./associations).

## Fetching Records with `Ecto.Repo`

Recall that a "repository" in Ecto maps to a datastore such as our Postgres database.
All communication to the database will be done using this repository.

We can perform simple queries directly against our `Example.Repo` with the help of a handful of functions.

### Fetching Records by ID

We can use the `Repo.get/3` function to fetch a record from the database given its ID. This function requires two arguments: a "queryable" data structure and the ID of a record to retrieve from the database. It returns a struct describing the record found, if any. It returns `nil` if no such record is found.

Let's take a look at an example. Below, we'll get the movie with and ID of 1:

```elixir
iex> alias Example.{Repo, Movie}
iex> Repo.get(Movie, 1)
%Example.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Notice that the first argument we give to `Repo.get/3` is our `Movie` module. `Movie` is "queryable" because the module uses the `Ecto.Schema` module and defines a schema for its data structure. This gives `Movie` access to the `Ecto.Queryable` protocol. This protocol converts a data structure into an `Ecto.Query`. Ecto queries are used to retrieve data from a repository. More on queries later.

### Fetching Records by Attribute

We can also fetch records that meet a given criteria with the `Repo.get_by/3` function. This function requires two arguments: the "queryable" data structure and the clause with which we want to query. `Repo.get_by/3` returns a single result from the repository. Let's look at an example:

```elixir
iex> alias Example.Repo
iex> alias Example.Movie
iex> Repo.get_by(Movie, title: "Ready Player One")
%Example.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

If we want to write more complex queries, or if we want to return _all_ records that meet a certain condition, we need to use the `Ecto.Query` module.

## Writing Queries with `Ecto.Query`

The `Ecto.Query` module provides us with the Query DSL which we can use to write queries to retrieve data from the application's repository.

### Creating Queries with `Ecto.Query.from/2`

We can create a query with the `Ecto.Query.from/2` function. This function takes in two arguments: an expression and a keyword list. Let's create a query to select all of the movies from our repository:

```elixir
import Ecto.Query
query = from(m in Movie, select: m)
#Ecto.Query<from m in Example.Movie, select: m>
```

In order to execute our query, we use the `Repo.all/2` function. This function takes in a required argument of an Ecto query and returns all of the records that meet the conditions of the query.

```elixir
iex> Repo.all(query)

14:58:03.187 [debug] QUERY OK source="movies" db=1.7ms decode=4.2ms
[
  %Example.Movie{
    __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
    actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

#### Using `from` with Keyword Queries

The example above gives the `from/2` an argument of a *keyword query*. When using `from` with a keyword query, the first argument can be one of two things:

* An `in` expression (ex: `m in Movie`)
* A module that implements the `Ecto.Queryable` protocol (ex: `Movie`)

The second argument is our `select` keyword query.

#### Using `from` with a Query Expression

When using `from` with a query expression, the first argument must be a value that implements the `Ecto.Queryable` protocol (ex: `Movie`). The second argument is an expression. Let's take a look at an example:

```elixir
iex> query = select(Movie, [m], m)
#Ecto.Query<from m in Example.Movie, select: m>
iex> Repo.all(query)

06:16:20.854 [debug] QUERY OK source="movies" db=0.9ms
[
  %Example.Movie{
    __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
    actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

You can use query expressions when you _don't_ need an `in` statement (`m in Movie`). You don't need an `in` statement when you don't need a reference to the data structure. Our query above doesn't require a reference to the data structure--we're not, for example, selecting movies where a given condition is met. So there's no need to use `in` expressions and keyword queries.

### Using `select` expressions

We use the `Ecto.Query.select/3` function to specify the select statement portion of our query. If we want to select only certain fields, we can specify those fields as a list of atoms or by referencing the struct's keys. Let's take a look at the first approach:

```elixir
iex> query = from(Movie, select: [:title])
#Ecto.Query<from m in Example.Movie, select: [:title]>
iex> Repo.all(query)

15:15:25.842 [debug] QUERY OK source="movies" db=1.3ms
[
  %Example.Movie{
    __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
    actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: nil,
    tagline: nil,
    title: "Ready Player One"
  }
]
```

Notice that we did _not_ use an `in` expression for the first argument given to our `from` function. That is because we did not need to create a reference to our data structure in order to use a keyword list with `select`.

This approach returns a struct with only the specified field, `title`, populated.

The second approach behaves a little differently. This time, we *do* need to use an `in` expression. This is because we need to create a reference to our data structure in order to specify the `title` key of the movie struct:

```elixir
iex(15)> query = from(m in Movie, select: m.title)
#Ecto.Query<from m in Example.Movie, select: m.title>
iex(16)> Repo.all(query)

15:06:12.752 [debug] QUERY OK source="movies" db=4.5ms queue=0.1ms
["Ready Player One"]
```

Notice that this approach to using `select` returns a list containing the selected values.

### Using `where` expressions

We can use `where` expressions to include "where" clauses in our queries. Multiple `where` expressions are combined into `WHERE AND` SQL statements.

```elixir
iex> query = from(m in Movie, where: m.title == "Ready Player One")
#Ecto.Query<from m in Example.Movie, where: m.title == "Ready Player One">
iex> Repo.all(query)

15:18:35.355 [debug] QUERY OK source="movies" db=4.1ms queue=0.1ms
[
  %Example.Movie{
    __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
    actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

We can use `where` expressions together with `select`:

```elixir
iex> query = from(m in Movie, where: m.title == "Ready Player One", select: m.tagline)
#Ecto.Query<from m in Example.Movie, where: m.title == "Ready Player One", select: m.tagline>
iex> Repo.all(query)

15:19:11.904 [debug] QUERY OK source="movies" db=4.1ms
["Something about video games"]
```

### Using `where` with Interpolated Values

In order to use interpolated values or Elixir expressions in our where clauses, we need to use the `^`, or pin, operator. This allows us to _pin_ a value to a variable and refer to that pinned value, instead of re-binding that variable.

```elixir
iex> title = "Ready Player One"
"Ready Player One"
iex> query = from(m in Movie, where: m.title == ^title, select: m.tagline)
#Ecto.Query<from m in Example.Movie, where: m.title == ^"Ready Player One",
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
#Ecto.Query<from m in Example.Movie, order_by: [desc: m.id], limit: 1>
```

Then we pass our query to the `Repo.one/2` function to get our result:

```elixir
iex> Movie |> first() |> Repo.one()

06:36:14.234 [debug] QUERY OK source="movies" db=3.7ms
%Example.Movie{
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
#Ecto.Association.NotLoaded<association :actors is not loaded>
```

We _can't_ access those associated characters unless we preload them. There are a few different way to preload records with Ecto.

#### Preloading With Two Queries

The following query will preload associated records in a _separate_ query.

```elixir
iex> import Ecto.Query
Ecto.Query
iex> Repo.all(from m in Movie, preload: [:actors])
[
  %Example.Movie{
    __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Example.Actor{
        __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Bob"
      },
      %Example.Actor{
        __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
        id: 2,
        movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Gary"
      }
    ],
    characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
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
[
  %Example.Movie{
    __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Example.Actor{
        __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Bob"
      },
      %Example.Actor{
        __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
        id: 2,
        movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Gary"
      }
    ],
    characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
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
  where: a.name == "John Wayne"
  preload: [actors: a]
```

More on join statements in a bit.

#### Preloading Fetched Records

We can also preload the associated schemas of records that have already been queried from the database.

```elixir
iex> movie = Repo.get(Movie, 1)
%Example.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: #Ecto.Association.NotLoaded<association :actors is not loaded>, # actors are NOT LOADED!!
  characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
iex> movie = Repo.preload(movie, :actors)
%Example.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Example.Actor{
      __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
      id: 1,
      movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Bob"
    },
    %Example.Actor{
      __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
      id: 2,
      movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Gary"
    }
  ], # actors are LOADED!!
  characters: [],
  distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Now we can ask a movie for its actors:

```elixir
iex> movie.actors
[
  %Example.Actor{
    __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
    id: 1,
    movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Bob"
  },
  %Example.Actor{
    __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
    id: 2,
    movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Gary"
  }
]
```

### Using Join Statements

We can execute queries that include join statements with the help of the `Ecto.Query.join/5` function.

```elixir
iex> query = from m in Movie,
              join: c in Character,
              on: m.id == c.movie_id,
              where: c.name == "Video Game Guy",
              select: {m.title, c.name}
iex> Repo.all(query)
15:28:23.756 [debug] QUERY OK source="movies" db=5.5ms
[{"Ready Player One", "Video Game Guy"}]
```

The `on` expression can also use a keyword list:

```elixir
from m in Movie,
  join: c in Character,
  on: [id: c.movie_id], # keyword list
  where: c.name == "Video Game Guy",
  select: {m.title, c.name}
```

In the example above, we are joining on an Ecto schema, `m in Movie`. We can also join on an Ecto query. Let's say our movies table has a column `stars`, where we store the "star rating" of the film, a number 1-5.

```elixir
movies = from m in Movie, where: [stars: 5]
from c in Character,
  join: ^movies,
  on: [id: c.movie_id], # keyword list
  where: c.name == "Video Game Guy",
  select: {m.title, c.name}
```

The Ecto Query DSL is a powerful tool that provides us with everything we need to make even complex database queries. With this introduction provides you with the basic building blocks to start querying.
