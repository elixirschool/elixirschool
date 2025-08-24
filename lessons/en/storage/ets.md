%{
  version: "2.0.0",
  title: "Erlang Term Storage (ETS)",
  excerpt: """
  Erlang Term Storage, commonly referred to as ETS, is a powerful in-memory storage engine built into the Erlang VM and available to use in Elixir.
  In this lesson we'll explore how to interface with ETS and how it can be employed in our applications for high-performance data storage and retrieval.
  """
}
---

## Overview

ETS is a robust in-memory storage system for Elixir and Erlang terms that comes included with the runtime capable of storing large amounts of data and offers constant time data access for most operations. It's particularly useful for caching, lookups, and scenarios where we need fast access to structured data.

Tables in ETS are created and owned by individual processes.
When an owner process terminates, its tables are automatically destroyed.
By default, we can create as many ETS tables as memory allows, though we can set limits using the `ERL_MAX_ETS_TABLES` environment variable.

ETS provides several key benefits that make it invaluable for high-performance applications. It offers fast access with constant time lookups for most operations, enabling efficient data retrieval even with large datasets. The system supports concurrent access, allowing multiple processes to read from tables simultaneously while maintaining data consistency. ETS provides flexible storage options with different table types to suit various use cases, from simple key-value stores to more complex data structures. Additionally, it's memory efficient, storing data directly in the VM without serialization overhead, which reduces both memory usage and access times.

## Creating Tables

Tables are created with `:ets.new/2`, which accepts a table name and a set of options, returning a table identifier for subsequent operations.

For our example, we'll create a table to store and look up users by their nickname:

```elixir
iex> table = :ets.new(:user_lookup, [:set, :protected])
#Reference<0.1234567890.1234567890.123456>
```

Much like GenServers, there's a way to access ETS tables by name rather than identifier.
To do this we need to include the `:named_table` option:

```elixir
iex> :ets.new(:user_lookup, [:set, :protected, :named_table])
:user_lookup
```

Now we can access our table directly by name instead of keeping track of the reference.

### Table Types

ETS provides four different table types to suit various use cases. The default `set` type stores one value per key with unique keys, making it ideal for simple key-value storage. An `ordered_set` works similarly to `set` but maintains order by Erlang/Elixir term ordering, where key comparison uses Erlang's term ordering and `1` and `1.0` are considered equal. The `bag` type allows multiple objects per key but only permits one instance of each unique object per key. Finally, `duplicate_bag` supports multiple objects per key with duplicates allowed, useful for scenarios like storing multiple events for the same timestamp.

Let's see the differences in action:

```elixir
iex> set_table = :ets.new(:set_example, [:set, :named_table])
iex> :ets.insert(:set_example, {:key, "value1"})
iex> :ets.insert(:set_example, {:key, "value2"})  # Overwrites previous
iex> :ets.lookup(:set_example, :key)
[{:key, "value2"}]

iex> bag_table = :ets.new(:bag_example, [:bag, :named_table])
iex> :ets.insert(:bag_example, {:key, "value1"})
iex> :ets.insert(:bag_example, {:key, "value2"})  # Adds to existing
iex> :ets.lookup(:bag_example, :key)
[{:key, "value1"}, {:key, "value2"}]
```

### Access Controls

Access control in ETS determines which processes can read from and write to our tables. The `public` mode makes read and write operations available to all processes, which is useful for shared data structures but requires careful coordination to avoid race conditions. The `protected` mode, which is the default, allows read access to all processes while restricting write access to only the owner process, providing a good balance of accessibility and safety. The `private` mode limits both read and write access to the owner process only, offering maximum isolation at the cost of reduced accessibility.

```elixir
iex> public_table = :ets.new(:public_example, [:set, :public, :named_table])
iex> protected_table = :ets.new(:protected_example, [:set, :protected, :named_table])
iex> private_table = :ets.new(:private_example, [:set, :private, :named_table])
```

## Concurrency and Race Conditions

When multiple processes can write to a table (via `:public` access or by sending messages to the owning process), race conditions are possible.
For example, two processes each reading a counter value of `0`, incrementing it, and writing `1` back would result in a lost increment.

For counters specifically, `:ets.update_counter/3` provides atomic update-and-read operations:

```elixir
iex> :ets.new(:counters, [:set, :public, :named_table])
iex> :ets.insert(:counters, {:page_views, 0})
iex> :ets.update_counter(:counters, :page_views, 1)
1
iex> :ets.update_counter(:counters, :page_views, 5)
6
```

For other atomic operations, we might need the owner process to handle updates through message passing to ensure consistency.

## Performance Features

### Write Concurrency

ETS tables can be optimized for concurrent writes using the `write_concurrency` option:

```elixir
iex> :ets.new(:concurrent_table, [:set, :public, {:write_concurrency, true}])
```

Starting with OTP 25, we can use `{:write_concurrency, :auto}` to let the runtime automatically optimize based on usage patterns:

```elixir
iex> :ets.new(:adaptive_table, [:set, :public, {:write_concurrency, :auto}])
```

### Read Concurrency

For tables with many concurrent readers, enable read concurrency:

```elixir
iex> :ets.new(:read_heavy_table, [:set, :public, {:read_concurrency, true}])
```

## Inserting Data

ETS has no predefined schema - the only requirement is that data must be stored as tuples where the first element is the key.
To add new data we use `:ets.insert/2`:

```elixir
iex> :ets.insert(:user_lookup, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
true
```

When using `:ets.insert/2` with a `set` or `ordered_set`, existing data with the same key will be replaced.
To avoid overwriting, use `:ets.insert_new/2` which returns `false` for existing keys:

```elixir
iex> :ets.insert_new(:user_lookup, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
false
iex> :ets.insert_new(:user_lookup, {"3100", "", ["Elixir", "Ruby", "JavaScript"]})
true
```

We can also insert multiple objects at once:

```elixir
iex> users = [
...>   {"alice", "Alice", ["Python", "Go"]},
...>   {"bob", "Bob", ["JavaScript", "TypeScript"]},
...>   {"charlie", "Charlie", ["Rust", "C++"]}
...> ]
iex> :ets.insert(:user_lookup, users)
true
```

## Data Retrieval

ETS offers several convenient and flexible ways to retrieve stored data.
We'll explore key-based lookups and various pattern matching approaches.

### Key Lookup

The most efficient retrieval method is key lookup using `:ets.lookup/2`:

```elixir
iex> :ets.lookup(:user_lookup, "doomspork")
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

For tables that might have multiple objects per key (bag types), this returns all matching objects:

```elixir
iex> bag_table = :ets.new(:skills, [:bag, :named_table])
iex> :ets.insert(:skills, [{"doomspork", "Elixir"}, {"doomspork", "Ruby"}])
iex> :ets.lookup(:skills, "doomspork")
[{"doomspork", "Elixir"}, {"doomspork", "Ruby"}]
```

### Simple Pattern Matching

ETS supports pattern matching using special variables. Variables are specified with atoms like `:"$1"`, `:"$2"`, `:"$3"`, and so on.
The variable number reflects the result position, not the match position.
For values we don't care about, use the `:_` variable.

Let's see how it works:

```elixir
iex> :ets.match(:user_lookup, {:"$1", "Sean", :_})
[["doomspork"]]
```

Here's how variables influence the result order:

```elixir
iex> :ets.match(:user_lookup, {:"$99", :"$1", :"$3"})
[["Sean", ["Elixir", "Ruby", "Java"], "doomspork"],
 ["", ["Elixir", "Ruby", "JavaScript"], "3100"]]
```

If we want the original object regardless of variables, use `:ets.match_object/2`:

```elixir
iex> :ets.match_object(:user_lookup, {:"$1", :_, :"$3"})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]

iex> :ets.match_object(:user_lookup, {:_, "Sean", :_})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

### Advanced Querying with Select

For more complex queries, use `:ets.select/2`. This function takes a list of match specifications - tuples with three elements: pattern, guards, and result format.

The special variables `:"$$"` and `:"$_"` are shortcuts for result formatting. The `:"$$"` variable returns results as lists while `:"$_"` returns the original data objects.

Let's convert a `:ets.match_object/2` example to `:ets.select/2`:

```elixir
iex> :ets.select(:user_lookup, [{{:"$1", :_, :"$3"}, [], [:"$_"]}])
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]
```

ETS includes `:ets.fun2ms/1` to convert functions into match specifications for more readable queries:

```elixir
iex> fun = :ets.fun2ms(fn {username, _, langs} when length(langs) > 2 -> username end)
[{{:"$1", :_, :"$2"}, [{:>, {:length, :"$2"}, 2}], [:"$1"]}]

iex> :ets.select(:user_lookup, fun)
["doomspork", "3100"]
```

### Table Traversal

ETS provides functions to iterate through tables:

```elixir
iex> :ets.first(:user_lookup)
"3100"
iex> :ets.next(:user_lookup, "3100")
"doomspork"
```

**New in OTP 27**: The `first_lookup/1` and `next_lookup/2` functions combine traversal with lookup:

```elixir
iex> {key, object} = :ets.first_lookup(:user_lookup)
{"3100", {"3100", "", ["Elixir", "Ruby", "JavaScript"]}}
iex> {next_key, next_object} = :ets.next_lookup(:user_lookup, key)
{"doomspork", {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}}
```

## Updating Data

### Updating Elements

**New in OTP 27**: `:ets.update_element/4` allows providing a default object when the key doesn't exist:

```elixir
iex> table = :ets.new(:example, [])
iex> :ets.update_element(table, :key, {2, :new_value}, {:key, :new_value})
true
iex> :ets.lookup(table, :key)
[{:key, :new_value}]
```

### Taking Data

The `:ets.take/2` function works like `:ets.delete/2` but also returns the deleted objects:

```elixir
iex> :ets.take(:user_lookup, "doomspork")
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
iex> :ets.lookup(:user_lookup, "doomspork")
[]
```

## Deleting Data

### Removing Records

Deleting individual records is straightforward with `:ets.delete/2`:

```elixir
iex> :ets.delete(:user_lookup, "3100")
true
```

### Removing Tables

ETS tables are not garbage collected unless the parent process terminates.
To delete an entire table explicitly, use `:ets.delete/1`:

```elixir
iex> :ets.delete(:user_lookup)
true
```

## Practical Example: Building a Simple Cache

Let's implement a simple cache for expensive operations using what we've learned:

```elixir
defmodule SimpleCache do
  @moduledoc """
  A simple ETS-based cache for expensive function calls.
  """

  @table_name :simple_cache

  def start_link do
    :ets.new(@table_name, [:set, :public, :named_table, {:read_concurrency, true}])
    {:ok, self()}
  end

  @doc """
  Retrieve a cached value or apply the given function, caching and returning
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
  Lookup a cached result and check if it's still fresh
  """
  defp lookup(mod, fun, args) do
    case :ets.lookup(@table_name, {mod, fun, args}) do
      [{_key, result, expiration}] -> check_freshness(result, expiration)
      [] -> nil
    end
  end

  @doc """
  Compare the result expiration against the current system time.
  """
  defp check_freshness(result, expiration) do
    if expiration > :os.system_time(:seconds) do
      result
    else
      nil
    end
  end

  @doc """
  Apply the function, calculate expiration, and cache the result.
  """
  defp cache_apply(mod, fun, args, ttl) do
    result = apply(mod, fun, args)
    expiration = :os.system_time(:seconds) + ttl
    :ets.insert(@table_name, {{mod, fun, args}, result, expiration})
    result
  end

  @doc """
  Clear expired entries from the cache
  """
  def cleanup do
    current_time = :os.system_time(:seconds)
    expired_pattern = {{:_, :_, :_}, :_, :"$1"}
    guard = [{:<, :"$1", current_time}]
    expired_keys = :ets.select(@table_name, [{expired_pattern, guard, [:"$_"]}])

    Enum.each(expired_keys, fn {key, _, _} ->
      :ets.delete(@table_name, key)
    end)

    length(expired_keys)
  end
end
```

Let's test our cache:

```elixir
iex> SimpleCache.start_link()
{:ok, #PID<0.123.0>}

iex> defmodule ExampleApp do
...>   def expensive_operation do
...>     :timer.sleep(1000)  # Simulate expensive work
...>     :os.system_time(:seconds)
...>   end
...> end

iex> SimpleCache.get(ExampleApp, :expensive_operation, [], ttl: 10)
1640995200  # Takes ~1 second

iex> SimpleCache.get(ExampleApp, :expensive_operation, [], ttl: 10)
1640995200  # Returns immediately from cache

# After 10 seconds...
iex> SimpleCache.get(ExampleApp, :expensive_operation, [], ttl: 10)
1640995211  # Takes ~1 second again as cache expired
```

## Information and Monitoring

ETS provides several functions to inspect table properties:

```elixir
iex> :ets.info(:simple_cache)
[
  {:id, :simple_cache},
  {:decentralized_counters, false},
  {:read_concurrency, true},
  {:write_concurrency, false},
  {:compressed, false},
  {:memory, 305},
  {:owner, #PID<0.123.0>},
  {:heir, :none},
  {:name, :simple_cache},
  {:size, 1},
  {:node, :nonode@nohost},
  {:named_table, true},
  {:type, :set},
  {:keypos, 1},
  {:protection, :protected}
]

iex> :ets.info(:simple_cache, :size)
1
iex> :ets.info(:simple_cache, :memory)
305
```

## Disk-based Storage with DETS

For persistent storage, Erlang provides DETS (Disk-based Term Storage).
The DETS API is nearly identical to ETS, with the main difference being table creation:

```elixir
iex> {:ok, table} = :dets.open_file(:disk_storage, [type: :set])
{:ok, :disk_storage}
iex> :dets.insert(table, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
:ok
iex> :dets.lookup(table, "doomspork")
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
iex> :dets.close(table)
:ok
```

**Note**: DETS doesn't support `ordered_set` - only `set`, `bag`, and `duplicate_bag`.

After closing IEx, we'll find a `disk_storage` file in our directory containing the persisted data.

## Best Practices and Tips

When working with ETS, several considerations can help us build more effective and performant applications. Choosing the right table type is crucial - we should use `set` for unique keys, `bag` when we need multiple values per key, and `ordered_set` when we need sorted data. Considering concurrency options early in our design helps optimize performance; enabling `read_concurrency` benefits read-heavy workloads while `write_concurrency` helps with write-heavy scenarios.

Memory management becomes important for long-running applications, so monitoring table sizes with `:ets.info/2` and implementing cleanup strategies prevents memory issues over time. Our key design should distribute evenly for better performance in concurrent scenarios, and we should remember that tables are tied to the owner process - considering using a dedicated GenServer for important tables helps ensure data persistence. Finally, using atomic operations like `:ets.update_counter/3` and similar functions helps us avoid race conditions when multiple processes interact with our tables.

## Conclusion

ETS is a powerful in-memory storage solution that provides fast, concurrent access to structured data.
Its flexibility in table types, access controls, and performance optimizations makes it suitable for a wide range of use cases from simple caches to complex data structures.

Combined with DETS for persistence, ETS forms a complete storage solution that can handle everything from temporary caches to application state management.
Understanding ETS is essential for building high-performance Elixir applications that need efficient data access patterns.