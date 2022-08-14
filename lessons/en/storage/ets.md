%{
  version: "1.1.1",
  title: "Erlang Term Storage (ETS)",
  excerpt: """
  Erlang Term Storage, commonly referred to as ETS, is a powerful storage engine built into OTP and available to use in Elixir.
  In this lesson we'll look at how to interface with ETS and how it can be employed in our applications.
  """
}
---

## Overview

ETS is a robust in-memory store for Elixir and Erlang objects that comes included.
ETS is capable of storing large amounts of data and offers constant time data access.

Tables in ETS are created and owned by individual processes.
When an owner process terminates, its tables are destroyed.
You can have as many ETS table as you want, the only limit is the server memory. A limit can be specified using the `ERL_MAX_ETS_TABLES` environment variable.

## Creating Tables

Tables are created with `new/2`, which accepts a table name, and a set of options, and returns a table identifier that we can use in subsequent operations.

For our example we'll create a table to store and look up users by their nickname:

```elixir
iex> table = :ets.new(:user_lookup, [:set, :protected])
8212
```

Much like GenServers, there is a way to access ETS tables by name rather than identifier.
To do this we need to include the `:named_table` option.
Then we can access our table directly by name:

```elixir
iex> :ets.new(:user_lookup, [:set, :protected, :named_table])
:user_lookup
```

### Table Types

There are four types of tables available in ETS:

+ `set` — This is the default table type.
One value per key.
Keys are unique.
+ `ordered_set` — Similar to `set` but ordered by Erlang/Elixir term.
It is important to note that key comparison is different within `ordered_set`.
Keys need not match so long as they compare equally.
1 and 1.0 are considered equal.
+ `bag` — Many objects per key but only one instance of each object per key.
+ `duplicate_bag` — Many objects per key, with duplicates allowed.

### Access Controls

Access control in ETS is similar to access control within modules:

+ `public` — Read/Write available to all processes.
+ `protected` — Read available to all processes.
Only writable by owner process.
This is the default.
+ `private` — Read/Write limited to owner process.

## Race Conditions

If more than one process can write to a table - whether via `:public` access or by messages to the owning process - race conditions are possible.
For example, two processes each read a counter value of `0`, increment it, and write `1`; the end result reflects only a single increment.

For counters specifically, [:ets.update_counter/3](http://erlang.org/doc/man/ets.html#update_counter-3) provides for atomic update-and-read.
For other cases, it may be necessary for the owner process to perform custom atomic operations in response to messages, such as "add this value to the list at key `:results`".

## Inserting data

ETS has no schema.
The only limitation is that data must be stored as a tuple whose first element is the key.
To add new data we can use `insert/2`:

```elixir
iex> :ets.insert(:user_lookup, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
true
```

When we use `insert/2` with a `set` or `ordered_set` existing data will be replaced.
To avoid this there is `insert_new/2` which returns `false` for existing keys:

```elixir
iex> :ets.insert_new(:user_lookup, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
false
iex> :ets.insert_new(:user_lookup, {"3100", "", ["Elixir", "Ruby", "JavaScript"]})
true
```

## Data Retrieval

ETS offers us a few convenient and flexible ways to retrieve our stored data.
We'll look at how to retrieve data by key and through different forms of pattern matching.

The most efficient, and ideal, retrieval method is key lookup.
While useful, matching iterates through the table and should be used sparingly especially for very large data sets.

### Key Lookup

Given a key, we can use `lookup/2` to retrieve all records with that key:

```elixir
iex> :ets.lookup(:user_lookup, "doomspork")
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

### Simple Matches

ETS was built for Erlang, so be warned that match variables may feel a _little_ clunky.

To specify a variable in our match we use the atoms `:"$1"`, `:"$2"`, `:"$3"`, and so on.
The variable number reflects the result position and not the match position.
For values we're not interested in, we use the `:_` variable.

Values can also be used in matching, but only variables will be returned as part of our result.
Let's put it all together and see how it works:

```elixir
iex> :ets.match(:user_lookup, {:"$1", "Sean", :_})
[["doomspork"]]
```

Let's look at another example to see how variables influence the resulting list order:

```elixir
iex> :ets.match(:user_lookup, {:"$99", :"$1", :"$3"})
[["Sean", ["Elixir", "Ruby", "Java"], "doomspork"],
 ["", ["Elixir", "Ruby", "JavaScript"], "3100"]]
```

What if we want our original object, not a list?  We can use `match_object/2`, which regardless of variables returns our entire object:

```elixir
iex> :ets.match_object(:user_lookup, {:"$1", :_, :"$3"})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]

iex> :ets.match_object(:user_lookup, {:_, "Sean", :_})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

### Advanced Lookup

We learned about simple match cases but what if we want something more akin to an SQL query?  Thankfully there is a more robust syntax available to us.
To lookup our data with `select/2` we need to construct a list of tuples with arity 3.
These tuples represent our pattern, zero or more guards, and a return value format.

Our match variables and two new variables, `:"$$"` and `:"$_"`, can be used to construct the return value.
These new variables are shortcuts for the result format; `:"$$"` gets results as lists and `:"$_"` gets the original data objects.

Let's take one of our previous `match/2` examples and turn it into a `select/2`:

```elixir
iex> :ets.match_object(:user_lookup, {:"$1", :_, :"$3"})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]

iex> :ets.select(:user_lookup, [{{:"$1", :_, :"$3"}, [], [:"$_"]}])
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]
```

Although `select/2` allows for finer control over what and how we retrieve records, the syntax is quite unfriendly and will only become more so.
To handle this the ETS module includes `fun2ms/1`, which turns the functions into match_specs.
With `fun2ms/1` we can create queries using a familiar function syntax.

Let's use `fun2ms/1` and `select/2` to find all usernames with more than 2 languages:

```elixir
iex> fun = :ets.fun2ms(fn {username, _, langs} when length(langs) > 2 -> username end)
{% raw %}[{{:"$1", :_, :"$2"}, [{:>, {:length, :"$2"}, 2}], [:"$1"]}]{% endraw %}

iex> :ets.select(:user_lookup, fun)
["doomspork", "3100"]
```

Want to learn more about the match specification?  Check out the official Erlang documentation for [match_spec](http://www.erlang.org/doc/apps/erts/match_spec.html).

## Deleting Data

### Removing Records

Deleting terms is as straightforward as `insert/2` and `lookup/2`.
With `delete/2` we only need our table and the key.
This deletes both the key and its values:

```elixir
iex> :ets.delete(:user_lookup, "doomspork")
true
```

### Removing Tables

ETS tables are not garbage collected unless the parent is terminated.
Sometimes it may be necessary to delete an entire table without terminating the owner process.
For this we can use `delete/1`:

```elixir
iex> :ets.delete(:user_lookup)
true
```

## Example ETS Usage

Given what we've learned above, let's put everything together and build a simple cache for expensive operations.
We'll implement a `get/4` function to take a module, function, arguments, and options.
For now the only option we'll worry about is `:ttl`.

For this example we're assuming the ETS table has been created as part of another process, such as a supervisor:

```elixir
defmodule SimpleCache do
  @moduledoc """
  A simple ETS based cache for expensive function calls.
  """

  @doc """
  Retrieve a cached value or apply the given function caching and returning
  the result.
  """
  def get(mod, fun, args, opts \\ []) do
    case lookup(mod, fun, args) do
      nil ->
        ttl = Keyword.get(opts, :ttl, 3600)
        cache_apply(mod, fun, args, ttl)

      result ->
        result
    end
  end

  @doc """
  Lookup a cached result and check the freshness
  """
  defp lookup(mod, fun, args) do
    case :ets.lookup(:simple_cache, [mod, fun, args]) do
      [result | _] -> check_freshness(result)
      [] -> nil
    end
  end

  @doc """
  Compare the result expiration against the current system time.
  """
  defp check_freshness({mfa, result, expiration}) do
    cond do
      expiration > :os.system_time(:seconds) -> result
      :else -> nil
    end
  end

  @doc """
  Apply the function, calculate expiration, and cache the result.
  """
  defp cache_apply(mod, fun, args, ttl) do
    result = apply(mod, fun, args)
    expiration = :os.system_time(:seconds) + ttl
    :ets.insert(:simple_cache, {[mod, fun, args], result, expiration})
    result
  end
end
```

To demonstrate the cache we'll use a function that returns the system time and a TTL of 10 seconds.
As you'll see in the example below, we get the cached result until the value has expired:

```elixir
defmodule ExampleApp do
  def test do
    :os.system_time(:seconds)
  end
end

iex> :ets.new(:simple_cache, [:named_table])
:simple_cache
iex> ExampleApp.test
1451089115
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089119
iex> ExampleApp.test
1451089123
iex> ExampleApp.test
1451089127
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089119
```

After 10 seconds if we try again we should get a fresh result:

```elixir
iex> ExampleApp.test
1451089131
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089134
```

As you see we are able to implement a scalable and fast cache without any external dependencies and this is only one of many uses for ETS.

## Disk-based ETS

We now know ETS is for in-memory term storage but what if we need disk-based storage? For that we have Disk Based Term Storage, or DETS for short.
The ETS and DETS APIs are interchangeable with the exception of how tables are created.
DETS relies on `open_file/2` and doesn't require the `:named_table` option:

```elixir
iex> {:ok, table} = :dets.open_file(:disk_storage, [type: :set])
{:ok, :disk_storage}
iex> :dets.insert_new(table, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
true
iex> select_all = :ets.fun2ms(&(&1))
[{:"$1", [], [:"$1"]}]
iex> :dets.select(table, select_all)
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

If you exit `iex` and look in your local directory, you'll see a new file `disk_storage`:

```shell
$ ls | grep -c disk_storage
1
```

One last thing to note is that DETS does not support `ordered_set` like ETS, only `set`, `bag`, and `duplicate_bag`.
