%{
  author: "Sean Callan",
  author_link: "https://github.com/doomspork",
  date: ~D[2018-07-25],
  tags: ["ecto", "software design"],
  title: "Ecto query composition",
  excerpt: """
  Follow along as we look at how to dynamically compose Ecto queries using pattern matching and reduction.
  """
}

---

Ecto is fantastic tool that provides us with a great degree of flexibility.
In this blog post we'll look at how we can dynamically build our Ecto queries and sanitize our input data at the same time.

Let's plan to approach our composition in 3 steps:

- Create the base query we'll build upon
- Compose our query from input criteria
- Execute our final query

For our example we'll be working with everyone's favorite example project: a blog!
Before we begin, take a peek at the schema we'll be building our code to interface with:

![image](https://user-images.githubusercontent.com/73386/41698787-7a4efb0e-74dd-11e8-970b-7fb8fe3fef14.png)

## Query base

To keep things clean we'll create a new module to contain the functionality for accessing the underlying schema data.
Let's move ahead with creating our module and addressing the first step above: the base query.

```elixir
defmodule Posts do
  import Ecto.Query

  defp base_query do
    from p in Post
  end
end
```

Simple enough.
When `base_query/0` is called we'll create the initial query that will serve as the base for our criteria.
At this point our query is analogous to `SELECT * FROM posts`.

## Applying our criteria

Next we'll need to build upon `base_query/0` by applying our criteria, this is where the magic of our query composition shines!

There's a good chance the resulting query we want won't just be simple `==` comparisons.
Let's consider how we might look up a blog post by title.
It's unlikely we'll want to search by exact title, so instead of `p.title == "Repo"` we want `p.title ILIKE "%Repo%"`.

With that in mind it's easy to understand why the following is not only a bad idea, because it doesn't filter the criteria, but the resulting queries are basic `==` comparisons:

```elixir
defp build_query(query, criteria) do
  expr = Enum.into(criteria, [])
  where(query, [], expr)
end
```

So how might we approach this problem instead?

Before we discuss the new approach let's decide on some business rules for Post look up, see them applied in our approach, and then walk through it.
For our example we will assume the following are always true:

- Searches for `title` are expected to be `ILIKE "%title%"`
- Including `tags` requires _at least_ one.
- Simple comparison is available for `draft` and `id`
- All other values are discarded

Now that we know the rules around looking up a Post let's see them applied with query composition:

```elixir
defp build_query(query, criteria) do
  Enum.reduce(criteria, query, &compose_query/2)
end

defp compose_query({"title", title}, query) do
  where(query, [p], ilike(p.title, ^"%#{title}%"))
end

defp compose_query({"tags", tags}, query) do
  query
  |> join(:left, [p], t in assoc(p, :tags))
  |> where([_p, t], t.name in ^tags)
end

defp compose_query({key, value}, query) when key in ~w(draft id) do
  where(query, [p], ^{String.to_atom(key), value})
end

defp compose_query(_unsupported_param, query) do
  query
end
```

## Bringing it all together

With `base_query/0` and `build_query/2` in place, let's define our public `all/1` function.
There's nothing special to running our query so we can setup our new function as a pipeline ending in `Repo.all/1`:

```elixir
def all(criteria) do
  base_query()
  |> build_query(criteria)
  |> Repo.all()
end
```

The result is public function, our module's API, that is concise and to a degree self documenting: "Get the base query, build the query with the criteria, and get all records".

When we bring it all together and begin to leverage the flexibility we've provided, we begin to see the true power provided to us through Ecto:

```elixir
defmodule Posts do
  import Ecto.Query

  def all(criteria) do
    base_query()
    |> build_query(criteria)
    |> Repo.all()
  end

  def drafts, do: all(%{"draft" => true})

  def get(id) do
    %{"id" => id}
    |> all()
    |> handle_get()
  end

  defp base_query do
    from p in Post
  end

  defp build_query(query, criteria) do
    Enum.reduce(criteria, query, &compose_query/2)
  end

  defp compose_query({"title", title}, query) do
    where(query, [p], ilike(p.title, ^"%#{title}%"))
  end

  defp compose_query({"tags", tags}, query) do
    query
    |> join(:left, [p], t in assoc(p, :tags))
    |> where([_p, t], t.name in ^tags)
  end

  defp compose_query({key, value}, query) when key in ~w(draft id) do
    field = String.to_atom(key)
    where(query, [p], ^{field, value})
  end

  defp compose_query(_unsupported_param, query) do
    query
  end

  defp handle_get([]), do: {:error, "not found"}
  defp handle_get([post]), do: {:ok, post}
end
```

Here we have a module that encapsulates the logic around our data retrieval, separating our presentation and data layers, while providing a clean interface into our data.

If we're using Phoenix, than our controller might look something like this:

```elixir
defmodule Web.PostController do
  use Web, :controller

  def index(conn, params) do
    params
    |> Posts.all()
    |> render_result(conn)
  end

  def show(conn, %{"id" => id}) do
    id
    |> Posts.get()
    |> render_result(conn)
  end

  defp render_result({:ok, post}, conn) do
    render(conn, "show.json", post: post)
  end

  defp render_result({:error, reason}, conn) do
    render(conn, ErrorView, "error.json", reason: reason)
  end

  defp render_result(posts, conn) when is_list(posts) do
    render(conn, "index.json", posts: posts)
  end
end
```

The controller is concise and does little more than present the data — as it should.

What do you think of this approach?  How are you composing your Ecto queries?  We'd love to hear your thoughts and suggestions!
