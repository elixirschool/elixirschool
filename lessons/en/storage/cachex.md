%{
  version: "1.0.0",
  title: "Cachex",
  excerpt: """
  Cachex is a powerful caching library for Elixir with support for transactions, fallbacks, expirations, and distributed operations.
  In this lesson, we'll learn how to use Cachex to improve application performance through intelligent caching strategies.
  """
}
---

## Overview

Cachex is a feature-rich caching library for Elixir that provides a robust solution for storing and retrieving data efficiently. Unlike simple in-memory stores, Cachex offers advanced features like automatic expiration, distributed caching across nodes, transactional operations, and extensible hooks for custom behavior.

Cachex provides automatic expiration with configurable TTL policies, distributed caching across multiple nodes, and transactional operations for atomic cache updates. It supports fallback functions for lazy loading of missing data, batch operations for improved performance, statistics and monitoring through hooks, and custom commands for specialized operations.

## Installation and Setup

To add Cachex to our project let's add it to our `mix.exs` dependencies:

```elixir
def deps do
  [{:cachex, "~> 4.1"}]
end
```

Then we need to install our dependencies:

```shell
mix deps.get
```

## Basic Usage

### Starting a Cache

For quick testing in IEx, you can start a cache manually:

```elixir
iex> Cachex.start_link(:my_cache)
{:ok, #PID<0.123.0>}
```

For production applications, it's bes to add Cachex to our supervision tree in `application.ex`:

```elixir
children = [
  {Cachex, [:my_cache]},     # with default options
  {Cachex, [:my_cache, []]}  # with custom options
]
```

### Core Operations

Cachex provides intuitive functions for basic cache operations:

```elixir
iex> {:ok, _pid} = Cachex.start_link(:my_cache)

# Store a value
iex> {:ok, true} = Cachex.put(:my_cache, "user:123", %{name: "Alice", age: 30})

# Check if a key exists
iex> {:ok, true} = Cachex.exists?(:my_cache, "user:123")

# Retrieve a value
iex> {:ok, %{name: "Alice", age: 30}} = Cachex.get(:my_cache, "user:123")

# Delete a key
iex> {:ok, true} = Cachex.del(:my_cache, "user:123")

# Verify deletion
iex> {:ok, false} = Cachex.exists?(:my_cache, "user:123")
iex> {:ok, nil} = Cachex.get(:my_cache, "user:123")
```

### Unsafe Operations

Cachex provides "unsafe" versions of functions (suffixed with `!`) that unpack tuples and raise on errors:

```elixir
# Safe version returns tuples
iex> {:ok, nil} = Cachex.get(:my_cache, "missing_key")

# Unsafe version returns values directly
iex> nil = Cachex.get!(:my_cache, "missing_key")

# Errors raise exceptions with unsafe versions
iex> Cachex.get!(:nonexistent_cache, "key")
** (Cachex.Error) Specified cache not running
```

While convenient for testing and chaining operations, use unsafe functions cautiously in production where explicit error handling is preferred.

## Advanced Operations

### Batch Operations

For better performance when dealing with multiple keys, use batch operations:

```elixir
iex> {:ok, _pid} = Cachex.start_link(:my_cache)

# Insert multiple key-value pairs at once
iex> {:ok, true} = Cachex.put_many(:my_cache, [
...>   {"user:1", %{name: "Alice"}},
...>   {"user:2", %{name: "Bob"}},
...>   {"user:3", %{name: "Charlie"}}
...> ])
```

### Atomic Operations

Cachex supports atomic updates for safe concurrent modifications:

```elixir
# Atomic increment
iex> Cachex.put(:my_cache, "counter", 0)
iex> {:ok, 1} = Cachex.incr(:my_cache, "counter")
iex> {:ok, 2} = Cachex.incr(:my_cache, "counter")

# Atomic decrement
iex> {:ok, 1} = Cachex.decr(:my_cache, "counter")

# Atomic get and update
iex> {:commit, 10} = Cachex.get_and_update(:my_cache, "counter", fn value ->
...>   value * 10
...> end)
```

### Optimized Batch Execution

Use `Cachex.execute/3` to perform multiple operations efficiently:

```elixir
# Standard approach (multiple validations)
r1 = Cachex.get!(:my_cache, "key1")
r2 = Cachex.get!(:my_cache, "key2") 
r3 = Cachex.get!(:my_cache, "key3")

# Optimized batch approach (single validation)
{r1, r2, r3} = Cachex.execute!(:my_cache, fn cache ->
  r1 = Cachex.get!(cache, "key1")
  r2 = Cachex.get!(cache, "key2")
  r3 = Cachex.get!(cache, "key3")
  {r1, r2, r3}
end)
```

## Expiration and TTL

### Default Expiration

Set a default expiration for all cache entries:

```elixir
import Cachex.Spec

Cachex.start_link(:my_cache, [
  expiration: expiration(default: :timer.minutes(5))
])
```

### Per-Key Expiration

Set expiration when storing values:

```elixir
# Expire after 60 seconds
iex> Cachex.put(:my_cache, "session:abc", user_data, expire: :timer.seconds(60))

# Or set expiration after storing
iex> Cachex.put(:my_cache, "key", "value")
iex> Cachex.expire(:my_cache, "key", :timer.seconds(30))
```

### Testing Expiration

```elixir
iex> Cachex.put(:my_cache, "short_lived", "data", expire: 100)
{:ok, true}

# Wait for expiration
iex> :timer.sleep(150)
:ok

iex> Cachex.get(:my_cache, "short_lived")
{:ok, nil}
```

## Lazy Loading with Fetch

The `fetch/4` function provides elegant lazy loading when keys are missing:

```elixir
# Simple fetch with function reference
{:commit, 6} = Cachex.fetch(:my_cache, "tarzan", &String.length/1)

# Fetch with custom logic and expiration
{:commit, data} = Cachex.fetch(:my_cache, "api:users", fn ->
  users = fetch_users_from_api()
  {:commit, users, expire: :timer.minutes(10)}
end)
```

The `fetch/4` function is particularly powerful for preventing cache stampedes in concurrent environments. Unlike manual cache-miss handling, `fetch/4` ensures that concurrent requests for the same missing key will queue behind a single computation:

```elixir
# Multiple concurrent requests for the same missing key
for _ <- 1..10 do
  spawn(fn ->
    Cachex.fetch(:cache, "expensive_key", fn ->
      # This expensive operation runs only once
      expensive_database_call()
    end)
  end)
end
```

## Transactions

Transactions provide atomic operations across multiple keys:

```elixir
result = Cachex.transaction!(:my_cache, ["user:1", "user:2"], fn cache ->
  user1 = Cachex.get!(cache, "user:1")
  user2 = Cachex.get!(cache, "user:2")
  
  # Perform some operation
  updated_user1 = update_user(user1)
  
  # Update the cache atomically
  Cachex.put!(cache, "user:1", updated_user1)
  
  updated_user1
end)
```

**Important**: You must specify all keys that will be accessed in the transaction. This ensures proper locking and prevents deadlocks.

## Statistics and Monitoring

Enable statistics collection with hooks:

```elixir
import Cachex.Spec

Cachex.start_link(:my_cache, [
  hooks: [
    hook(module: Cachex.Stats)
  ]
])

# Generate some activity
Cachex.put!(:my_cache, "key1", "value1")
Cachex.put!(:my_cache, "key2", "value2")
Cachex.get!(:my_cache, "key1")  # hit
Cachex.get!(:my_cache, "key3")  # miss

# View statistics
stats = Cachex.stats!(:my_cache)
IO.inspect(stats)

# Output:
# %{
#   meta: %{creation_date: 1726777631670},
#   hits: 1,
#   misses: 1,
#   hit_rate: 50.0,
#   miss_rate: 50.0,
#   calls: %{get: 2, put: 2},
#   operations: 4,
#   writes: 2
# }
```

## Cache Limiting and Pruning

### Automatic Limiting with Hooks

Prevent memory issues by limiting cache size:

```elixir
import Cachex.Spec

# LRU-style eviction with scheduled pruning
Cachex.start_link(:my_cache, [
  hooks: [
    hook(module: Cachex.Limit.Accessed),  # Track access times
    hook(module: Cachex.Limit.Scheduled, args: {
      500,  # Maximum 500 entries
      [],   # Options for Cachex.prune/3
      []    # Options for Cachex.Limit.Scheduled
    })
  ]
])
```

### Manual Pruning

You can also manually control cache size:

```elixir
# Insert test data
for i <- 1..100, do: Cachex.put!(:my_cache, i, i)

{:ok, 100} = Cachex.size(:my_cache)

# Prune to 50 entries with 10% reclaim buffer
{:ok, true} = Cachex.prune(:my_cache, 50, reclaim: 0.1)

{:ok, 45} = Cachex.size(:my_cache)  # 50 - (50 * 0.1) = 45
```

## Persistence

### Saving and Restoring Cache Data

Cachex can persist cache data to disk:

```elixir
# Save cache to file
{:ok, true} = Cachex.save(:my_cache, "/tmp/my_cache.dat")

# Restore from file (merges with existing data)
{:ok, _count} = Cachex.restore(:my_cache, "/tmp/my_cache.dat")

# Clear before restore for exact match
Cachex.clear(:my_cache)
{:ok, _count} = Cachex.restore(:my_cache, "/tmp/my_cache.dat")
```

Note that expired entries in the saved file will not be restored.

## Distributed Caching

Cachex supports distributed caching across multiple nodes using routers:

```elixir
import Cachex.Spec

# Ring-based distributed cache
Cachex.start_link(:distributed_cache, [
  router: router(module: Cachex.Router.Ring, options: [
    monitor: true  # Automatically handle node changes
  ])
])
```

Some things to keep in mind when we're workign in distributed mode:
- Keys are automatically routed to appropriate nodes
- Multi-key operations require keys to be on the same node
- Some operations like `stream/3` are not available in distributed mode

## Custom Hooks

Create custom hooks to extend Cachex functionality:

```elixir
defmodule MyApp.CacheLogger do
  use Cachex.Hook

  def init(_), do: {:ok, nil}

  def handle_notify({action, _args}, result, state) do
    Logger.info("Cache #{action}: #{inspect(result)}")
    {:ok, state}
  end
end

# Attach the hook
import Cachex.Spec

Cachex.start_link(:my_cache, [
  hooks: [
    hook(module: MyApp.CacheLogger)
  ]
])
```

## Real-World Example

Here's a practical example of using Cachex in a web application:

```elixir
defmodule MyApp.UserCache do
  @cache_name :user_cache

  def start_link do
    import Cachex.Spec
    
    Cachex.start_link(@cache_name, [
      expiration: expiration(default: :timer.hours(1)),
      hooks: [
        hook(module: Cachex.Stats),
        hook(module: Cachex.Limit.Scheduled, args: {1000, [], []})
      ]
    ])
  end

  def get_user(user_id) do
    Cachex.fetch(@cache_name, "user:#{user_id}", fn ->
      case MyApp.Users.get_user(user_id) do
        {:ok, user} -> {:commit, user}
        {:error, :not_found} -> {:ignore, nil}
      end
    end)
  end

  def update_user(user_id, attrs) do
    with {:ok, user} <- MyApp.Users.update_user(user_id, attrs) do
      Cachex.put(@cache_name, "user:#{user_id}", user)
      {:ok, user}
    end
  end

  def invalidate_user(user_id) do
    Cachex.del(@cache_name, "user:#{user_id}")
  end

  def stats do
    Cachex.stats(@cache_name)
  end
end
```

Add it to our supervision tree:

```elixir
children = [
  MyApp.UserCache,
  # ... other children
]
```

## Best Practices

When working with Cachex in production, we should use supervision trees for cache management rather than manual starts, as this ensures proper process lifecycle management. Error handling becomes crucial in production code, so we prefer explicit error handling over unsafe functions that raise exceptions.

Setting appropriate TTLs helps us balance performance gains with data freshness requirements. Monitoring cache statistics allows us to optimize hit rates and identify potential issues before they impact performance. When working with multiple keys, batch operations provide significant performance improvements over individual calls.

For multi-node deployments, distributed caching can provide better scalability and fault tolerance. We should implement proper fallback strategies using `fetch/4` when integrating with databases or external services. Finally, transactions become essential for operations requiring consistency across multiple keys, ensuring data integrity in concurrent environments.

## Conclusion

Cachex provides a comprehensive caching solution for Elixir applications, offering everything from simple key-value storage to advanced distributed caching with transactions and monitoring. Its rich feature set and extensible architecture make it suitable for applications of any scale, from simple web apps to large distributed systems.

The library's emphasis on performance, reliability, and developer experience makes it an excellent choice for improving application performance through intelligent caching strategies. Whether you need basic memoization or complex distributed cache coordination, Cachex provides the tools to build robust caching solutions.