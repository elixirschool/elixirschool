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

Redix is feature rich with pipelining support for efficiently sending multiple commands in a single round-trip, along with automatic reconnection capabilities that use configurable backoff strategies to handle network interruptions gracefully. The library includes comprehensive pub/sub support for real-time messaging patterns and Redis Sentinel integration for high availability deployments. Additionally, telemetry integration makes monitoring and observability straightforward.

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

Let's start by establishing a connection to Redis. The simplest way is to use `Redix.start_link/1`. There

```elixir
# Connect to Redis on localhost:6379 (default)
{:ok, conn} = Redix.start_link()

# Connect to a specific host and port
{:ok, conn} = Redix.start_link(host: "example.com", port: 5000)

# Connect using a Redis URI
{:ok, conn} = Redix.start_link("redis://localhost:6379/3")

# Connect with a registered name for easy access
{:ok, conn} = Redix.start_link("redis://localhost:6379", name: :redix)
```

### Executing Commands

Redix uses Redis's native command structure, refer to the official Redis documentation for a complete list of commands. Commands are represented as lists of strings:

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

One of Redix's powerful features is command pipelining, which allows us to send multiple commands at once. This dramatically improves performance when we need to execute several commands:

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

Pipeline commands return results in the same order as the commands were sent, making it easy to correlate commands with their responses.

## Working with Data Types

Redis supports various data types, and Redix makes it easy to work with all of them.

### Strings

```elixir
# Set and get strings
Redix.command!(conn, ["SET", "username", "alice"])
Redix.command!(conn, ["GET", "username"])
#=> "alice"

# Atomic operations
Redix.command!(conn, ["INCR", "page_views"])
#=> 1
Redix.command!(conn, ["INCRBY", "page_views", "5"])
#=> 6
```

### Lists

```elixir
# Push elements to a list
Redix.command!(conn, ["LPUSH", "tasks", "task1"])
Redix.command!(conn, ["LPUSH", "tasks", "task2"])
Redix.command!(conn, ["RPUSH", "tasks", "task3"])

# Get list contents
Redix.command!(conn, ["LRANGE", "tasks", "0", "-1"])
#=> ["task2", "task1", "task3"]

# Pop elements
Redix.command!(conn, ["LPOP", "tasks"])
#=> "task2"
```

### Sets

```elixir
# Add members to a set
Redix.command!(conn, ["SADD", "languages", "elixir"])
Redix.command!(conn, ["SADD", "languages", "erlang", "go", "rust"])

# Get all members
Redix.command!(conn, ["SMEMBERS", "languages"])
#=> ["erlang", "elixir", "go", "rust"]

# Check membership
Redix.command!(conn, ["SISMEMBER", "languages", "elixir"])
#=> 1
```

### Hashes

```elixir
# Set hash fields
Redix.command!(conn, ["HSET", "user:1", "name", "Alice", "age", "30"])

# Get specific fields
Redix.command!(conn, ["HGET", "user:1", "name"])
#=> "Alice"

# Get all fields and values
Redix.command!(conn, ["HGETALL", "user:1"])
#=> ["name", "Alice", "age", "30"]
```

## Integration with Applications

### Using Named Connections

For real-world applications, we generally want to start Redix connections under our application's supervision tree with registered names:

```elixir
# In our application.ex
def start(_type, _args) do
  children = [
    {Redix, name: :redix, host: "localhost", port: 6379}
    # ...other children
  ]

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

Now we can use the connection anywhere in our application:

```elixir
Redix.command(:redix, ["SET", "app_state", "running"])
#=> {:ok, "OK"}

Redix.command!(:redix, ["GET", "app_state"])
#=> "running"
```

### Building a Connection Pool

For high-traffic applications, we might want to use multiple Redis connections. Here's a simple connection pool implementation:

```elixir
defmodule MyApp.RedisPool do
  @pool_size 5

  def child_spec(_args) do
    children =
      for index <- 0..(@pool_size - 1) do
        Supervisor.child_spec(
          {Redix, name: :"redix_#{index}", host: "localhost", port: 6379},
          id: {Redix, index}
        )
      end

    %{
      id: RedixSupervisor,
      type: :supervisor,
      start: {Supervisor, :start_link, [children, [strategy: :one_for_one]]}
    }
  end

  def command(command) do
    :"redix_#{random_index()}"
    |> Redix.command(command)
  end

  def pipeline(commands) do
    :"redix_#{random_index()}"
    |> Redix.pipeline(commands)
  end

  defp random_index do
    Enum.random(0..(@pool_size - 1))
  end
end
```

Now we can use the pool:

```elixir
MyApp.RedisPool.command(["SET", "key", "value"])
#=> {:ok, "OK"}

MyApp.RedisPool.pipeline([["INCR", "counter"], ["GET", "counter"]])
#=> {:ok, [1, "1"]}
```

## Pub/Sub Messaging

Redis pub/sub is perfect for real-time messaging, and Redix makes it easy to implement.

### Setting Up a Publisher

```elixir
defmodule MyApp.Publisher do
  def start_link do
    Redix.start_link(name: __MODULE__)
  end

  def publish(channel, message) do
    Redix.command(__MODULE__, ["PUBLISH", channel, message])
  end
end
```

### Setting Up a Subscriber

```elixir
defmodule MyApp.Subscriber do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    {:ok, pubsub} = Redix.PubSub.start_link()
    
    {:ok, ref} = Redix.PubSub.subscribe(pubsub, "notifications", self())
    
    state = %{pubsub: pubsub, ref: ref}
    {:ok, state}
  end

  def handle_info({:redix_pubsub, pubsub, ref, :subscribed, %{channel: channel}}, state) do
    IO.puts("Successfully subscribed to #{channel}")
    {:noreply, state}
  end

  def handle_info({:redix_pubsub, pubsub, ref, :message, %{channel: channel, payload: message}}, state) do
    IO.puts("Received message on #{channel}: #{message}")
    # Process the message here
    {:noreply, state}
  end
end
```

### Using Pub/Sub in Practice

```elixir
{:ok, _} = MyApp.Subscriber.start_link([])

{:ok, _} = MyApp.Publisher.start_link()

MyApp.Publisher.publish("notifications", "Hello, subscribers!")
#=> {:ok, 1}  # Number of subscribers that received the message
```

## Observability and Monitoring

### Telemetry Integration

Redix emits telemetry events that we can use for monitoring:

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

Start telemetry in our application:

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

Setting TTLs (Time To Live) on cached data not only prevents our Redis instance from running out of memory but also aids in ensuring cache freshness by expiring old or stale data, ensuring that our application doesn't serve outdated information indefinitely. TTL balances performance benefits with data freshness and resource management. Let's look at an example of TTL in Redix:

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
      {:ok, 0} -> false
    end
  end
end
```

### Rate Limiting

```elixir
defmodule MyApp.RateLimit do
  @redix_name :rate_limit_redix

  def check_rate_limit(identifier, limit, window_seconds) do
    key = "rate_limit:#{identifier}"
    
    pipeline = [
      ["INCR", key],
      ["EXPIRE", key, window_seconds]
    ]
    
    case Redix.pipeline(@redix_name, pipeline) do
      {:ok, [count, _expire_result]} when count <= limit ->
        {:ok, %{allowed: true, count: count, limit: limit}}
      
      {:ok, [count, _expire_result]} ->
        {:ok, %{allowed: false, count: count, limit: limit}}
      
      error ->
        error
    end
  end
end

case MyApp.RateLimit.check_rate_limit("user:123", 100, 3600) do
  {:ok, %{allowed: true, count: count}} ->
    IO.puts("Request allowed. Count: #{count}")
    
  {:ok, %{allowed: false, count: count, limit: limit}} ->
    IO.puts("Rate limit exceeded. #{count}/#{limit}")
    
  {:error, reason} ->
    IO.puts("Rate limit check failed: #{reason}")
end
```

## Testing with Redix

### Setup for Testing

In our `config/test.exs`:

```elixir
config :my_app, :redis_url, "redis://localhost:6379/15"  # Use a test database
```

In `test/test_helper.exs`:

```elixir
ExUnit.start()

# Clean up Redis before each test
ExUnit.after_suite(fn _results ->
  {:ok, conn} = Redix.start_link(Application.get_env(:my_app, :redis_url))
  Redix.command!(conn, ["FLUSHDB"])
  Redix.stop(conn)
end)
```

### Test Setup Pattern

```elixir
defmodule MyApp.CacheTest do
  use ExUnit.Case
  
  setup do
    {:ok, conn} = Redix.start_link(Application.get_env(:my_app, :redis_url))
    Redix.command!(conn, ["FLUSHDB"])  # Clean database before each test
    
    on_exit(fn -> Redix.stop(conn) end)
    
    %{redis: conn}
  end

  test "cache operations work correctly", %{redis: conn} do
    # Our test using the conn
    assert {:ok, "OK"} = Redix.command(conn, ["SET", "test_key", "test_value"])
    assert {:ok, "test_value"} = Redix.command(conn, ["GET", "test_key"])
  end
end
```

## Best Practices

For high-traffic applications implementing connection pooling is essential to distribute load across multiple connections and prevent bottlenecks. Similarly, graceful disconnection handling through appropriate backoff strategies ensures our application remains resilient when Redis becomes temporarily unavailable.

Performance optimization comes through strategic use of pipelining when executing multiple commands, which significantly reduces round-trip time compared to individual command execution. Monitoring this performance through telemetry allows us to track command execution times and overall connection health, helping identify issues before they impact users.

Data management practices are equally important: use consistent key naming patterns to avoid conflicts and simplify debugging, and always set appropriate TTLs on cached data to prevent memory bloat and ensure data freshness. For operations requiring atomicity across multiple commands, Redis transactions using MULTI/EXEC provide the necessary guarantees to maintain data consistency.

## Conclusion

Redix provides a robust, high-performance way to integrate Redis into our Elixir applications. Its emphasis on Redis's native command structure, combined with excellent resilience features and OTP integration, makes it an excellent choice for everything from simple caching to complex real-time systems.

Whether we're building a web application that needs session storage, implementing a real-time chat system with pub/sub, or creating a high-performance caching layer, Redix gives we the tools to leverage Redis effectively in the Elixir ecosystem.

The key to success with Redix is understanding both Redis fundamentals and how to properly integrate asynchronous, resilient connections into our OTP supervision tree. With proper configuration and monitoring, Redix can provide years of reliable service in production applications.