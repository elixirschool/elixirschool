---
author: Svilen Gospodinov
author_link: https://github.com/svileng
categories: general
tags: ['ecto', 'software design']
date:   2018-11-07
layout: post
title:  A brief guide to Ecto.Multi
excerpt: Learn how to compose and execute batches of queries using Ecto.Multi.
---

Ecto.Multi is a set of utilities aimed at composing and executing atomic operations, usually (but not always, as you’ll see soon) performed against the database. Furthermore, it handles rollbacks, provides results on either success or error, flattens-out nested code and saves multiple round trips to the database.

If you find yourself running and managing many database queries (and other operations), then keep reading and you may find some useful tools to add your Elixir/Ecto toolbox.

## Creating a Multi
Everything starts with a `%Multi{}` struct. You can create a new Multi calling the `Ecto.Multi.new()` function:


```elixir
iex> Ecto.Multi.new()
%Ecto.Multi{names: %MapSet<[]>, operations: []}
```

## Executing Multi operations
To run a Multi, you have to hand it over to `Repo.transaction/1`:

```elixir
iex> Ecto.Multi.new() |> Repo.transaction()
{:ok, %{}}
```
Clearly we just ran an empty Multi, which was obviously successful since nothing was performed (and nothing returned in the second element of the {:ok, return} tuple. To make Multis useful, you need to add operations to them.

Next, we're going to cover the most common operations you may end up doing.

## Working with individual changesets
When working with multiple `%Ecto.Changeset{}`s, usually you will call `Repo.insert/1` / `update/1` etc multiple times to run the operations. Switching to `Ecto.Multi` is as easy as replacing `Repo.update/1` with its equivalent `Ecto.Multi.update/3`, for example.

Assuming you already have a `team_changeset`, `user_changeset` and `foo_changeset` created beforehand, this would look like so:

```elixir
Ecto.Multi.new()
|> Ecto.Multi.insert(:team, team_changeset)
|> Ecto.Multi.update(:user, user_changeset)
|> Ecto.Multi.delete(:foo, foo_changeset)
|> Repo.transaction()
```
The atoms used — `:user` ,`:team` and `:foo` — are up to you. You can pass anything (also you can use a string, instead of an atom) as long as it’s a unique value for the current Multi.

## Result of a previous operation
Operations will be run in the order they’re added to the Multi. Often you need the result of a previous operation, which you can get by running a custom Multi operation, like so:

```elixir
Ecto.Multi.new()
|> Ecto.Multi.insert(:team, team_changeset)
|> Ecto.Multi.run(:user, fn repo, %{team: team} ->
  # Use the inserted team.
  repo.update(user_changeset)
end)
```
`Ecto.Multi.run/3` needs a name for its first parameter, just like Multi insert/delete/update etc functions, which I have called `:user`; the second is a function, which provides you with the current Ecto Repo, alongside the results of previous operations. The results are just a map, and you can use the unique key to pattern-match and get the result for a specific operation, in this case `:team`.

Notice that here we call `repo.update(user_changeset)` (which is the same function as `Ecto.Repo.update/1`); you need to return an `{:ok, val}` or a `{:error, val}` tuple from the function you pass to `Multi.run/3`. Using `Repo.update` will give us just what we need.

## Custom operations
Actually, `Multi.run/3` could be used for pretty much anything. As long as you return a success/error tuple, it will become part of the same atomic transaction:

```elixir
Ecto.Multi.new()
|> Ecto.Multi.insert_all(:users, MyApp.User, users)
|> Ecto.Multi.run(:pro_users, fn _repo, %{users: users} ->
  result = Enum.filter(users, & &1.role == "pro")
  {:ok, result}
end)
```
Here `:pro_users` will be available to use for subsequent operations and in the result returned by `Repo.transaction/1`. It’s a great way to ensure code is run together with the rest of the database operations. If the `:users` operation fails or something else before that, this potentially expensive filtering function will never be executed.

## Working with multiple Multis and dynamic data
The beauty of Ecto.Multi is that it’s just a data structure, which you can pass around. It is easy to dynamically generate data and combine different multis together, before executing everything as a single transaction:

```elixir
posts
|> Stream.filter(fn post ->
  # Filter old posts...
end)
|> Stream.map(fn post ->
  # Create changesets.
  Ecto.Changeset.change(post, %{category: "new"})
end)
|> Stream.map(fn post_cs ->
  # Create a Multi with a single update
  # operation, generating a unique key for the op.
  key = "post_#{post_cs.data.id}"
  Ecto.Multi.update(Ecto.Multi.new(), key, post_cs)
end)
|> Enum.reduce(Multi.new(), &Multi.append/2)
```

Thanks to `Multi.append/2` we now have a single Multi with all update operations in order. There’s also `merge` and `prepend` if you need them.

## Handling results
Once you call `Repo.transaction/1`, you can pattern-match the result tuple.

In the case of success, you will receive all `{:ok, result}` with result being a map; operations and their successful results will be in the result map, under the unique key you have chosen.

In the case of an error, all database operations will be rolled back, and you will be given `{:error, failed_operation, failed_value, changes_so_far}` which allows you to handle errors from specific operations individually and inspect them. Note that `changes_so_far` simply means “operations that went well until this one failed” and no data is actually left in the database.

```elixir
Ecto.Multi.new()
|> Ecto.Multi.insert(:team, team_changeset)
|> Ecto.Multi.update(:user, user_changeset)
|> Ecto.Multi.delete(:foo, foo_changeset)
|> Repo.transaction
|> case do
  {:ok, %{user: user, team: team, foo: foo}} ->
    # Yay, success!
  {:error, :foo, value, _} ->
    # It seems that :foo failed!
  {:error, op, res, others} ->
    # One of the others failed!
end
```

## Conclusion
This brief guide tried to cover the most common use cases and functions. Hope you found it useful,
and if you would like to learn more — head over to the [official Ecto.Multi documentation](https://hexdocs.pm/ecto/Ecto.Multi.html) where you can explore everything that's available to you.
