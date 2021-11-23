%{
author: "Yuri Oliveira",
author_link: "https://github.com/yuriploc",
tags: ["ecto"],
date: ~D[2021-11-22],
title: "TIL: Cleaner queries with Ecto `map`",
excerpt: """
Today I learned how to write cleaner `Ecto` select queries with the help of `Ecto.Query.map`.
"""
}

---

# TIL: Cleaner queries with Ecto `map`

When working with large tables a common practice is to avoid using `SELECT *` to make better use of database indices and resources.

So, instead of writing:

```elixir
query = from p in Post
Repo.all(query)
```

To avoid getting back more data than we need, we can explicitly tell Ecto (and the DB) which columns we want it to return us:

```elixir
query = from p in Post, select: %{id: p.id, title: p.title, category_id: p.category_id}
Repo.all(query)
```

But why do we have to be so explicit and duplicate keys and values? Isn't there a better way?

It turns out Ecto.Query already solved this for us with the `map/2` function. So this:

```elixir
query = from p in Post, select: %{id: p.id, title: p.title, category_id: p.category_id}
Repo.all(query)
```

Becomes:

```elixir
query = from p in Post, select: map(p, [:id, :title, :category_id])
Repo.all(query)
```

Or, in Pipeland:

```elixir
Post
|> select([p], %{id: p.id, title: p.title, category_id: p.category_id})
|> Repo.all()
```

```elixir
Post
|> select([p], map(p, [:id, :title, :category_id]))
|> Repo.all()
```

And we can even have dynamic fields when using it in a function, like:

```elixir
def filter_posts_by_id(posts_ids, fields \\ [:id, :title, :category_id]) do
  Post
    |> where([p], p.id in ^posts_ids)
    |> select([p], map(p, ^fields))
    |> Repo.all()
end
```

Thanks to the `Ecto.Query.map/2` function and the use of pipes, we end up with clean, composable and highly readable code.

Enjoy Ecto!

_Thank you to the Groxio Mentoring folks for the support._
