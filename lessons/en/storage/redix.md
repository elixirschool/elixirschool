%{
  version: "1.0.0",
  title: "Redix",
  excerpt: """
  Redix is a fast, pipelined, and resilient Redis driver for Elixir. In this lesson, we'll explore how to integrate Redis into our Elixir applications using Redix, covering everything from basic operations to advanced patterns like connection pooling and pub/sub messaging.
  """
}
---

## What is Redix?

[Redix](https://github.com/whatyouhide/redix) is the go-to Redis client for Elixir applications, supporting both Redis and Valkey (the Redis fork). It's designed to be fast, resilient, and easy to use while leveraging Redis's pipelining capabilities for optimal performance. Unlike some Redis clients that try to abstract Redis commands, Redix embraces Redis's native command structure, making it both powerful and straightforward.

Redix supports pipelining for sending multiple commands in a single round-trip, automatic reconnection with configurable backoff strategies, pub/sub for real-time messaging, and Redis Sentinel integration for high availability. It also includes telemetry events out of the box, making monitoring straightforward.

## Installation

To get started with Redix, add it to our `mix.exs`:

```elixir
defp deps do
  [
    {:redix, "~> 1.1"}
  ]
end
```

Then fetch the dependencies:

```shell
mix deps.get
```

## Basic Usage

### Connecting to Redis

Let's start by establishing a connection to Redis using `Redix.start_link/1`:

```elixir
# Connect to Redis on localhost:6379 (default)
{:ok, conn} = Redix.start_link()

# Connect to a specific host and port
{:ok, conn} = Redix.start_link(host: "example.com", port: 5000)

# Connect using a Redis URI
{:ok, conn} = Redix.start_link("redis://localhost:6379/3")
```
### Using Named Connections

For real-world applications, we generally want to start Redix connections under our application's supervision tree with registered names. Let's pull the Redis URL from our config rather than hardcoding it:

```elixir
# config/config.exs
config :my_app, redis_url: "redis://localhost:6379"
```

```elixir
def start(_type, _args) do
  redis_url = Application.get_env(:my_app, :redis_url, "redis://localhost:6379")

  children = [
    {Redix, name: :redix, url: redis_url}
    # ...other children
  ]

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

Now we can use the connection anywhere in our application:

```elixir
iex> Redix.command(:redix, ["SET", "app_state", "running"])
{:ok, "OK"}

iex> Redix.command!(:redix, ["GET", "app_state"])
"running"
```

### Executing Commands

Redix uses Redis's native command structure represented as lists of strings. This means there's no abstraction layer to learn — if we know a Redis command, we can use it directly. A complete list of commands can be found in the official Redis documentation.

```elixir
iex> Redix.command(conn, ["SET", "mykey", "Hello, Redis!"])
{:ok, "OK"}

iex> Redix.command(conn, ["GET", "mykey"])
{:ok, "Hello, Redis!"}

iex> Redix.command(conn, ["INCR", "counter"])
{:ok, 1}

iex> Redix.command(conn, ["INCR", "counter"])
{:ok, 2}
```

For cases where we want to work with the result directly or let errors bubble up, Redix provides bang (`!`) variants:

```elixir
iex> Redix.command!(conn, ["PING"])
"PONG"

iex> Redix.command!(conn, ["GET", "mykey"])
"Hello, Redis!"

iex> Redix.command!(conn, ["INVALID", "COMMAND"])
** (Redix.Error) ERR unknown command 'INVALID'
```

### Pipelining Commands

One of Redix's powerful features is command pipelining which allows us to send multiple commands at once. This dramatically improves performance when we need to execute several commands:

```elixir
iex> commands = [
...>   ["SET", "key1", "value1"],
...>   ["SET", "key2", "value2"],
...>   ["GET", "key1"],
...>   ["GET", "key2"]
...> ]

iex> Redix.pipeline(conn, commands)
{:ok, ["OK", "OK", "value1", "value2"]}

iex> Redix.pipeline!(conn, [["INCR", "foo"], ["INCR", "foo"], ["INCRBY", "foo", "2"]])
[1, 2, 4]
```

As we see from our examples, pipeline commands return results in the same order as the commands were sent, making it easy to correlate commands with their responses.

## Working with Data Types

Redis supports various data types and Redix makes it easy to work with all of them.

### Strings

```elixir
# Set and get strings
iex> Redix.command!(conn, ["SET", "username", "alice"])
"OK"
iex> Redix.command!(conn, ["GET", "username"])
"alice"
```

### Atomic operations

```elixir
iex> Redix.command!(conn, ["INCR", "page_views"])
1
iex> Redix.command!(conn, ["INCRBY", "page_views", "5"])
6
```

### Lists

```elixir
# Push elements to a list
iex> Redix.command!(conn, ["LPUSH", "tasks", "task1"])
iex> Redix.command!(conn, ["LPUSH", "tasks", "task2"])
iex> Redix.command!(conn, ["RPUSH", "tasks", "task3"])

# Get list contents
iex> Redix.command!(conn, ["LRANGE", "tasks", "0", "-1"])
["task3", "task2", "task1"]

# Pop elements
iex> Redix.command!(conn, ["LPOP", "tasks"])
"task3"
```

### Sets

```elixir
# Add members to a set
iex> Redix.command!(conn, ["SADD", "languages", "elixir"])
iex> Redix.command!(conn, ["SADD", "languages", "erlang", "go", "rust"])

# Get all members
iex> Redix.command!(conn, ["SMEMBERS", "languages"])
["elixir", "erlang", "go", "rust"]

# Check membership
iex> Redix.command!(conn, ["SISMEMBER", "languages", "elixir"])
1
```

### Hashes

```elixir
# Set hash fields
iex> Redix.command!(conn, ["HSET", "user:1", "name", "Alice", "age", "30"])

# Get specific fields
iex> Redix.command!(conn, ["HGET", "user:1", "name"])
"Alice"

# Get all fields and values
iex> Redix.command!(conn, ["HGETALL", "user:1"])
["name", "Alice", "age", "30"]
```

## Telemetry Integration

Redix emits telemetry events that we can use for monitoring. Let's look at an example Telemetry setup for our application:
   
```elixir
defmodule MyApp.RedixTelemetry do
  require Logger

  def setup do
    events = [
      [:redix, :connection],
      [:redix, :disconnection],
      [:redix, :failed_connection],
      [:redix, :pipeline_stop],
      [:redix, :command_stop]
    ]

    :telemetry.attach_many(
      "redix-telemetry",
      events,
      &handle_event/4,
      %{}
    )
  end

  def handle_event([:redix, :connection], _measurements, metadata, _config) do
    Logger.info("Connected to Redis at #{metadata.address}")
  end

  def handle_event([:redix, :disconnection], _measurements, metadata, _config) do
    Logger.warn("Disconnected from Redis at #{metadata.address}: #{Exception.message(metadata.reason)}")
  end

  def handle_event([:redix, :failed_connection], _measurements, metadata, _config) do
    Logger.error("Failed to connect to Redis at #{metadata.address}: #{Exception.message(metadata.reason)}")
  end

  def handle_event([:redix, :command_stop], measurements, metadata, _config) do
    if measurements.duration > 1_000_000 do  # Log slow commands (>1ms)
      Logger.warn("Slow Redis command: #{inspect(metadata.command)} took #{measurements.duration}μs")
    end
  end

  def handle_event([:redix, :pipeline_stop], measurements, metadata, _config) do
    command_count = length(metadata.commands)
    Logger.debug("Pipeline with #{command_count} commands took #{measurements.duration}μs")
  end
end
```

We have to remember to start telemetry in our application:

```elixir
def start(_type, _args) do
  MyApp.RedixTelemetry.setup()
  
  children = [
    {Redix, name: :redix},
    # ...other children
  ]

  Supervisor.start_link(children, strategy: :one_for_one)
end
```

## Real-World Examples

### Caching with TTL

Setting TTLs (Time To Live) on cached data prevents our Redis instance from running out of memory and keeps data fresh by expiring stale entries. Let's look at an example:

```elixir
defmodule MyApp.Cache do
  @redix_name :cache_redix

  def get(key) do
    case Redix.command(@redix_name, ["GET", key]) do
      {:ok, nil} -> {:error, :not_found}
      {:ok, value} -> {:ok, Jason.decode!(value)}
      error -> error
    end
  end

  def set(key, value, ttl \\ 3600) do
    json_value = Jason.encode!(value)
    Redix.command(@redix_name, ["SETEX", key, ttl, json_value])
  end

  def delete(key) do
    Redix.command(@redix_name, ["DEL", key])
  end

  def exists?(key) do
    case Redix.command(@redix_name, ["EXISTS", key]) do
      {:ok, 1} -> true
      _ -> false
    end
  end
end
```

### Rate Limiting

Rate limiting prevents abuse by restricting how many requests a user or IP can make within a time window. We can use Redis's atomic `INCR` and `EXPIRE` commands in a pipeline to track request counts without race conditions.

```elixir
defmodule MyApp.RateLimit do
  @redix_name :rate_limit_redix

  def check_rate_limit(identifier, limit, window_seconds) do
    key = "rate_limit:#{identifier}"

    # Use a Lua script to atomically increment and set expiry only on first request
    script = """
    local current = redis.call("INCR", KEYS[1])
    if current == 1 then
      redis.call("EXPIRE", KEYS[1], ARGV[1])
    end
    return current
    """

    case Redix.command(@redix_name, ["EVAL", script, "1", key, window_seconds]) do
      {:ok, count} when count <= limit ->
        {:ok, %{allowed: true, count: count, limit: limit}}

      {:ok, count} ->
        {:ok, %{allowed: false, count: count, limit: limit}}

      error ->
        error
    end
  end
end

defmodule MyApp.RateLimitPlug do
  import Plug.Conn

  @behaviour Plug

  def init(opts), do: opts

  def call(conn, opts) do
    identifier = get_identifier(conn, opts)
    limit = Keyword.fetch!(opts, :limit)
    window = Keyword.fetch!(opts, :window)

    case MyApp.RateLimit.check_rate_limit(identifier, limit, window) do
      {:ok, %{allowed: true}} ->
        conn

      {:ok, %{allowed: false, count: count, limit: limit}} ->
        conn
        |> send_resp(429, "Rate limit exceeded: #{count}/#{limit}")
        |> halt()

      {:error, reason} ->
        # In case Redix/Redis is down, allow request
        conn
    end
  end

  # Extract identifier (by default, IP)
  defp get_identifier(conn, opts) do
    case Keyword.get(opts, :identifier) do
      :ip ->
        to_string(:inet_parse.ntoa(conn.remote_ip))
      {:header, name} ->
        get_req_header(conn, name) |> List.first() || "anonymous"
      val when is_function(val, 1) ->
        val.(conn)
      nil ->
        # Default fallback: IP
        to_string(:inet_parse.ntoa(conn.remote_ip))
    end
  end
end
```

## Transactions

When we need atomicity across multiple commands, Redis provides `MULTI`/`EXEC` transactions. With Redix, we send these as a pipeline — there's no special transaction function:

```elixir
iex> Redix.pipeline!(:redix, [
...>   ["MULTI"],
...>   ["SET", "account:1:balance", "100"],
...>   ["SET", "account:2:balance", "200"],
...>   ["EXEC"]
...> ])
["OK", "QUEUED", "QUEUED", ["OK", "OK"]]
```

All commands between `MULTI` and `EXEC` are queued and executed atomically — either they all succeed or none do. The real result comes back in the `EXEC` response (the last element), while the intermediate responses are just `"QUEUED"`.

If we need to abort a transaction, we can use `DISCARD` instead of `EXEC`:

```elixir
iex> Redix.pipeline!(:redix, [
...>   ["MULTI"],
...>   ["SET", "key", "value"],
...>   ["DISCARD"]
...> ])
["OK", "QUEUED", "OK"]
```

## Best Practices

There are a few things to keep in mind when using Redix:

+ Always set appropriate TTLs on cached data to prevent memory bloat and ensure data freshness.
+ When executing multiple commands use pipelining for performance.
+ If we need atomicity across multiple commands, use Redis' transactions `MULTI`/`EXEC` for data consistency.

## Conclusion

Redix gives us a fast, resilient way to integrate Redis into our Elixir applications. Its direct use of Redis's native command structure means there's nothing extra to learn — if we know Redis, we know Redix.

For caching with more built-in features like expiration policies and cache limiting, check out the [Cachex](/en/storage/cachex) lesson. If we need persistent storage without an external dependency, the [ETS](/en/storage/ets) and [Mnesia](/en/storage/mnesia) lessons cover what's built into the runtime.