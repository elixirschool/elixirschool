%{
  version: "2.0.0",
  title: "Mnesia",
  excerpt: """
  Mnesia is a distributed real-time database management system that ships with the Erlang Runtime System. In this lesson, we'll explore how to use Mnesia to build fault-tolerant, distributed applications with Elixir.
  """
}
---

## Overview

Mnesia is a Database Management System (DBMS) that comes built into the Erlang Runtime System, making it immediately available in Elixir applications. What makes Mnesia special is its distributed, real-time capabilities and its hybrid data model that combines relational and object-oriented features.

Unlike traditional databases that require separate installation and configuration, Mnesia runs inside our Elixir application's virtual machine. This unique architecture provides distributed storage across multiple nodes, real-time performance with flexible in-memory and disk storage options, and fault tolerance through automatic replication and recovery. Mnesia also supports full ACID transactions with rollback capabilities and enables hot code swapping without downtime, making it particularly well-suited for high-availability systems.

## When to Use Mnesia

Mnesia shines in specific scenarios. Consider using Mnesia when we can answer "yes" to any of these questions:

Do we need a database that's embedded within our application? Are we building a distributed system that needs to share data across multiple nodes? Do we need real-time performance with sub-millisecond response times? Does our application require high availability with automatic failover? Do we need to store and query Elixir data structures directly?

Mnesia might not be the best choice for applications requiring SQL compatibility, systems that need to share data with non-Erlang/Elixir applications, applications with massive datasets that don't fit in memory, or projects that require extensive reporting and analytics.

## Getting Started

Since Mnesia is part of the Erlang Runtime System, we access it using the colon syntax for Erlang interoperability. Let's start by aliasing it for convenience:

```elixir
iex> alias :mnesia, as: Mnesia
```

Throughout this lesson, we'll use this approach to make our code more readable.

### Creating a Schema

Before we can use Mnesia, we need to create a schema. The schema defines the database structure and tells Mnesia where to store data:

```elixir
iex> Mnesia.create_schema([node()])
:ok
```

This command creates a new schema on the current node. After running this, you'll notice a new directory in your current working directory named something like `Mnesia.nonode@nohost` - this is where Mnesia stores its data files.

### Understanding Nodes

The `node()` function returns the current node name. In a standalone IEx session, this might be something like `:nonode@nohost`. In distributed systems, you'll work with named nodes:

```shell
$ iex --name myapp@localhost
```

```elixir
iex(myapp@localhost)> node()
:myapp@localhost
```

Node names are important in Mnesia because they determine how data is distributed across your cluster.

## Starting Mnesia

Once we have a schema, we can start the Mnesia database:

```elixir
iex> Mnesia.start()
:ok
```

Mnesia starts asynchronously, so if you need to ensure tables are ready before proceeding, use `wait_for_tables/2`:

```elixir
iex> Mnesia.wait_for_tables([:my_table], 5000)
:ok
```

## Working with Tables

Tables in Mnesia are containers for records. Let's create a simple table to store user information:

```elixir
iex> Mnesia.create_table(:users, [
...>   attributes: [:id, :name, :email, :created_at]
...> ])
{:atomic, :ok}
```

The `attributes` list defines the structure of records in this table. The first attribute (`:id` in this case) automatically becomes the primary key.

### Table Configuration Options

Mnesia tables can be configured with various options:

```elixir
iex> Mnesia.create_table(:sessions, [
...>   attributes: [:session_id, :user_id, :data, :expires_at],
...>   type: :set,                    # Default: each key appears once
...>   storage_type: :disc_copies,    # Store on disk and in memory
...>   index: [:user_id]              # Create secondary index
...> ])
{:atomic, :ok}
```

**Table types:**
`:set` means each key appears once (default), `:ordered_set` provides ordered keys useful for range queries, `:bag` allows multiple values per key but no duplicates, and `:duplicate_bag` permits multiple values per key including duplicates.

**Storage types:**
`:ram_copies` stores data in memory only for fastest access but data is lost on restart, `:disc_copies` stores data in both memory and disk providing a good balance of performance and durability, and `:disc_only_copies` stores data on disk only using minimal memory but with slower access.

## Basic Operations

### Writing Data

Let's add some users to our table. Mnesia stores data as tuples where the first element is the table name:

```elixir
iex> user1 = {:users, 1, "Alice", "alice@example.com", ~N[2024-01-01 10:00:00]}
iex> user2 = {:users, 2, "Bob", "bob@example.com", ~N[2024-01-01 11:00:00]}

iex> Mnesia.transaction(fn ->
...>   Mnesia.write(user1)
...>   Mnesia.write(user2)
...> end)
{:atomic, :ok}
```

All Mnesia operations that modify data should be wrapped in transactions to ensure consistency.

### Reading Data

Reading data is straightforward:

```elixir
iex> Mnesia.transaction(fn ->
...>   Mnesia.read(:users, 1)
...> end)
{:atomic, [{:users, 1, "Alice", "alice@example.com", ~N[2024-01-01 10:00:00]}]}
```

If no record is found, you'll get an empty list:

```elixir
iex> Mnesia.transaction(fn ->
...>   Mnesia.read(:users, 999)
...> end)
{:atomic, []}
```

### Updating Data

To update a record, simply write a new version with the same key:

```elixir
iex> updated_user = {:users, 1, "Alice Smith", "alice.smith@example.com", ~N[2024-01-01 10:00:00]}
iex> Mnesia.transaction(fn ->
...>   Mnesia.write(updated_user)
...> end)
{:atomic, :ok}
```

### Deleting Data

Delete records by specifying the table and key:

```elixir
iex> Mnesia.transaction(fn ->
...>   Mnesia.delete({:users, 2})
...> end)
{:atomic, :ok}
```

## Dirty Operations

For performance-critical operations where you don't need transaction guarantees, Mnesia provides "dirty" operations:

```elixir
iex> user3 = {:users, 3, "Charlie", "charlie@example.com", ~N[2024-01-01 12:00:00]}
iex> Mnesia.dirty_write(user3)
:ok

iex> Mnesia.dirty_read(:users, 3)
[{:users, 3, "Charlie", "charlie@example.com", ~N[2024-01-01 12:00:00]}]

iex> Mnesia.dirty_delete({:users, 3})
:ok
```

**Warning:** Dirty operations bypass transaction safety. Use them only when we understand the implications and need maximum performance.

## Querying Data

Mnesia provides several ways to query data beyond simple key lookups.

### Using Indices

Remember the index we created on `:user_id` for the sessions table? Let's use it:

```elixir
iex> Mnesia.create_table(:sessions, [
...>   attributes: [:session_id, :user_id, :data, :expires_at],
...>   index: [:user_id]
...> ])
{:atomic, :ok}

iex> sessions = [
...>   {:sessions, "sess_1", 1, %{theme: "dark"}, ~N[2024-01-02 10:00:00]},
...>   {:sessions, "sess_2", 1, %{theme: "light"}, ~N[2024-01-02 11:00:00]},
...>   {:sessions, "sess_3", 2, %{theme: "auto"}, ~N[2024-01-02 12:00:00]}
...> ]

iex> Mnesia.transaction(fn ->
...>   Enum.each(sessions, &Mnesia.write/1)
...> end)
{:atomic, :ok}

iex> Mnesia.transaction(fn ->
...>   Mnesia.index_read(:sessions, 1, :user_id)
...> end)
{:atomic, [
  {:sessions, "sess_1", 1, %{theme: "dark"}, ~N[2024-01-02 10:00:00]},
  {:sessions, "sess_2", 1, %{theme: "light"}, ~N[2024-01-02 11:00:00]}
]}
```

### Pattern Matching

Mnesia supports pattern matching with the special atom `:_` as a wildcard:

```elixir
iex> Mnesia.transaction(fn ->
...>   Mnesia.match_object({:users, :_, :_, "alice@example.com", :_})
...> end)
{:atomic, [{:users, 1, "Alice", "alice@example.com", ~N[2024-01-01 10:00:00]}]}
```

### Advanced Queries with select/2

For complex queries, use `select/2` with match specifications:

```elixir
iex> Mnesia.transaction(fn ->
...>   # Find all users whose names start with "A"
...>   Mnesia.select(:users, [
...>     {
...>       {:users, :"$1", :"$2", :"$3", :"$4"},  # Match pattern
...>       [{'=:=', {:hd, :"$2"}, ?A}],            # Guard (name starts with 'A')
...>       [:"$$"]                                  # Return entire match
...>     }
...>   ])
...> end)
{:atomic, [[1, "Alice", "alice@example.com", ~N[2024-01-01 10:00:00]]]}
```

## Error Handling and Recovery

Mnesia operations return specific patterns that make error handling straightforward:

```elixir
iex> case Mnesia.transaction(fn -> Mnesia.read(:users, 1) end) do
...>   {:atomic, []} -> 
...>     IO.puts("User not found")
...>   {:atomic, [user]} -> 
...>     IO.puts("Found user: #{inspect(user)}")
...>   {:aborted, reason} -> 
...>     IO.puts("Transaction failed: #{inspect(reason)}")
...> end
Found user: {:users, 1, "Alice", "alice@example.com", ~N[2024-01-01 10:00:00]}
```

### Handling Table Creation Errors

```elixir
iex> case Mnesia.create_table(:users, [attributes: [:id, :name]]) do
...>   {:atomic, :ok} -> 
...>     IO.puts("Table created successfully")
...>   {:aborted, {:already_exists, :users}} -> 
...>     IO.puts("Table already exists")
...>   {:aborted, reason} -> 
...>     IO.puts("Failed to create table: #{inspect(reason)}")
...> end
Table already exists
```

## Building a Real Application

Let's build a simple blog system to demonstrate Mnesia in action:

```elixir
defmodule Blog.Database do
  alias :mnesia, as: Mnesia

  def setup do
    # Create schema if it doesn't exist
    case Mnesia.create_schema([node()]) do
      :ok -> :ok
      {:error, {_, {:already_exists, _}}} -> :ok
    end

    # Start Mnesia
    :ok = Mnesia.start()

    # Create tables
    create_tables()
  end

  defp create_tables do
    # Posts table
    Mnesia.create_table(:posts, [
      attributes: [:id, :title, :content, :author_id, :published_at, :tags],
      index: [:author_id]
    ])

    # Authors table
    Mnesia.create_table(:authors, [
      attributes: [:id, :name, :email, :bio]
    ])

    # Comments table
    Mnesia.create_table(:comments, [
      attributes: [:id, :post_id, :author_name, :content, :created_at],
      index: [:post_id],
      type: :bag  # Multiple comments per post
    ])
  end

  def create_author(name, email, bio \\ "") do
    id = :erlang.unique_integer([:positive])
    author = {:authors, id, name, email, bio}
    
    case Mnesia.transaction(fn -> Mnesia.write(author) end) do
      {:atomic, :ok} -> {:ok, id}
      {:aborted, reason} -> {:error, reason}
    end
  end

  def create_post(title, content, author_id, tags \\ []) do
    id = :erlang.unique_integer([:positive])
    post = {:posts, id, title, content, author_id, DateTime.utc_now(), tags}
    
    case Mnesia.transaction(fn -> Mnesia.write(post) end) do
      {:atomic, :ok} -> {:ok, id}
      {:aborted, reason} -> {:error, reason}
    end
  end

  def get_posts_by_author(author_id) do
    case Mnesia.transaction(fn ->
      Mnesia.index_read(:posts, author_id, :author_id)
    end) do
      {:atomic, posts} -> {:ok, posts}
      {:aborted, reason} -> {:error, reason}
    end
  end

  def add_comment(post_id, author_name, content) do
    id = :erlang.unique_integer([:positive])
    comment = {:comments, id, post_id, author_name, content, DateTime.utc_now()}
    
    case Mnesia.transaction(fn -> Mnesia.write(comment) end) do
      {:atomic, :ok} -> {:ok, id}
      {:aborted, reason} -> {:error, reason}
    end
  end

  def get_comments_for_post(post_id) do
    case Mnesia.transaction(fn ->
      Mnesia.index_read(:comments, post_id, :post_id)
    end) do
      {:atomic, comments} -> {:ok, comments}
      {:aborted, reason} -> {:error, reason}
    end
  end
end
```

Let's test our blog system:

```elixir
iex> Blog.Database.setup()
:ok

iex> {:ok, author_id} = Blog.Database.create_author("Jane Doe", "jane@example.com", "Tech writer")
{:ok, 123456}

iex> {:ok, post_id} = Blog.Database.create_post(
...>   "Getting Started with Mnesia", 
...>   "Mnesia is a powerful database...", 
...>   author_id, 
...>   ["elixir", "database"]
...> )
{:ok, 234567}

iex> Blog.Database.add_comment(post_id, "Bob Reader", "Great post!")
{:ok, 345678}

iex> {:ok, comments} = Blog.Database.get_comments_for_post(post_id)
{:ok, [{:comments, 345678, 234567, "Bob Reader", "Great post!", ~U[2024-01-01 15:30:00.123456Z]}]}
```

## Distribution and Replication

One of Mnesia's greatest strengths is its built-in support for distribution. Here's how to set up a distributed Mnesia cluster:

### Setting Up Multiple Nodes

Start two named nodes in separate terminals:

```shell
# Terminal 1
$ iex --name node1@localhost --cookie mycookie

# Terminal 2  
$ iex --name node2@localhost --cookie mycookie
```

### Creating a Distributed Schema

On the first node:

```elixir
# node1@localhost
iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node(), :node2@localhost])
:ok
```

This creates a schema that will be shared across both nodes.

### Starting Mnesia on All Nodes

Start Mnesia on both nodes:

```elixir
# On both nodes
iex> Mnesia.start()
:ok
```

### Creating Replicated Tables

```elixir
# On node1@localhost
iex> Mnesia.create_table(:distributed_users, [
...>   attributes: [:id, :name, :email],
...>   disc_copies: [node(), :node2@localhost]  # Replicate to both nodes
...> ])
{:atomic, :ok}
```

Now data written to this table will be automatically replicated to both nodes!

### Testing Replication

Write data on one node:

```elixir
# On node1@localhost
iex> Mnesia.transaction(fn ->
...>   Mnesia.write({:distributed_users, 1, "Alice", "alice@example.com"})
...> end)
{:atomic, :ok}
```

Read it from the other node:

```elixir
# On node2@localhost
iex> Mnesia.transaction(fn ->
...>   Mnesia.read(:distributed_users, 1)
...> end)
{:atomic, [{:distributed_users, 1, "Alice", "alice@example.com"}]}
```

## Data Migration and Schema Evolution

As our application evolves, we'll need to modify our database schema. Mnesia provides tools for this:

### Adding New Tables

```elixir
iex> Mnesia.create_table(:user_preferences, [
...>   attributes: [:user_id, :theme, :language, :notifications]
...> ])
{:atomic, :ok}
```

### Adding Columns to Existing Tables

```elixir
iex> Mnesia.transform_table(:users, 
...>   fn({:users, id, name, email, created_at}) ->
...>     {:users, id, name, email, created_at, true}  # Add 'active' field
...>   end, 
...>   [:id, :name, :email, :created_at, :active]
...> )
{:atomic, :ok}
```

### Creating Indices on Existing Tables

```elixir
iex> Mnesia.add_table_index(:users, :email)
{:atomic, :ok}
```

## Best Practices

### Use Transactions for Consistency

Always use transactions for operations that must be atomic:

```elixir
# Good: Transfer money between accounts atomically
def transfer_money(from_id, to_id, amount) do
  Mnesia.transaction(fn ->
    [from_account] = Mnesia.read(:accounts, from_id)
    [to_account] = Mnesia.read(:accounts, to_id)
    
    if from_account.balance >= amount do
      Mnesia.write({:accounts, from_id, from_account.balance - amount})
      Mnesia.write({:accounts, to_id, to_account.balance + amount})
      :ok
    else
      Mnesia.abort(:insufficient_funds)
    end
  end)
end
```

### Design Tables for Our Query Patterns

Create indices for fields we'll query frequently. If we often search users by email, we should structure our tables accordingly:

```elixir
# If we often search users by email
Mnesia.create_table(:users, [
  attributes: [:id, :name, :email, :created_at],
  index: [:email]
])
```

### Choose Appropriate Storage Types

Select storage types based on our application's needs. Use `:ram_copies` for cache-like data that doesn't need to survive restarts, `:disc_copies` for important data that needs to survive restarts while maintaining good performance, and `:disc_only_copies` for large datasets that don't fit in memory.

### Handle Network Partitions

In distributed systems, we should be prepared for network partitions:

```elixir
def robust_write(table, record) do
  case Mnesia.transaction(fn -> Mnesia.write(record) end) do
    {:atomic, :ok} -> :ok
    {:aborted, reason} -> 
      Logger.error("Write failed: #{inspect(reason)}")
      {:error, reason}
  end
end
```

### Monitor Table Sizes

Keep an eye on table sizes, especially for `:ram_copies` tables:

```elixir
iex> Mnesia.table_info(:users, :size)
2

iex> Mnesia.table_info(:users, :memory)
1024  # in words
```

## Performance Considerations

### Choosing the Right Table Type

`:set` works best for key-value lookups, `:ordered_set` excels when we need sorted data or range queries, `:bag` handles one-to-many relationships effectively, and `:duplicate_bag` serves cases where duplicates are meaningful.

### Optimizing Queries

Use indices for frequently queried fields:

```elixir
# Slow: Full table scan
Mnesia.match_object({:users, :_, :_, "alice@example.com", :_})

# Fast: Index lookup (if email is indexed)
Mnesia.index_read(:users, "alice@example.com", :email)
```

### Batch Operations

Group multiple writes in a single transaction:

```elixir
# Good: Single transaction for multiple writes
Mnesia.transaction(fn ->
  Enum.each(users, &Mnesia.write/1)
end)

# Less efficient: Multiple transactions
Enum.each(users, fn user ->
  Mnesia.transaction(fn -> Mnesia.write(user) end)
end)
```

## Debugging and Troubleshooting

### Inspecting Table Information

```elixir
# Get all table information
iex> Mnesia.table_info(:users, :all)

# Get specific information
iex> Mnesia.table_info(:users, :attributes)
[:id, :name, :email, :created_at, :active]

iex> Mnesia.table_info(:users, :storage_type)
:disc_copies

iex> Mnesia.table_info(:users, :size)
1
```

### Viewing All Records

```elixir
iex> Mnesia.transaction(fn ->
...>   Mnesia.foldr(fn(record, acc) -> [record | acc] end, [], :users)
...> end)
{:atomic, [{:users, 1, "Alice Smith", "alice.smith@example.com", ~N[2024-01-01 10:00:00], true}]}
```

### Checking System Status

```elixir
iex> Mnesia.system_info(:running_db_nodes)
[:nonode@nohost]

iex> Mnesia.system_info(:tables)
[:schema, :users, :sessions, :posts, :authors, :comments, :user_preferences, :distributed_users]
```

## Common Pitfalls and Solutions

### Schema Already Exists Error

```elixir
# Problem: Running create_schema multiple times
iex> Mnesia.create_schema([node()])
{:error, {:nonode@nohost, {:already_exists, :nonode@nohost}}}

# Solution: Check if schema exists first
case Mnesia.create_schema([node()]) do
  :ok -> :ok
  {:error, {_, {:already_exists, _}}} -> :ok
  error -> error
end
```

### Table Already Exists Error

```elixir
# Solution: Use conditional creation
def ensure_table_exists(name, options) do
  case Mnesia.create_table(name, options) do
    {:atomic, :ok} -> :ok
    {:aborted, {:already_exists, ^name}} -> :ok
    error -> error
  end
end
```

### Transaction Aborts

```elixir
# Handle transaction aborts gracefully
case Mnesia.transaction(fn -> 
  # Our operations here
end) do
  {:atomic, result} -> {:ok, result}
  {:aborted, :no_transaction} -> {:error, :database_not_available}
  {:aborted, reason} -> {:error, reason}
end
```

## Conclusion

Mnesia is a powerful, distributed database that's perfect for Elixir applications requiring real-time performance and fault tolerance. Its tight integration with the BEAM virtual machine makes it unique among database solutions.

Start simple with basic tables and operations, then add complexity as needed. Think distributed by designing our schema with distribution in mind from the beginning. Use transactions to wrap critical operations and ensure consistency. Monitor performance by keeping an eye on table sizes and query patterns, and plan for growth by designing our schema evolution strategy early.

Mnesia excels in scenarios requiring embedded databases, real-time performance, and distributed architectures. While it may not be suitable for every use case, it can be the perfect solution for applications that fit its strengths.

For more advanced topics like hot code swapping, custom backends, and performance tuning, explore the [official Mnesia documentation](http://erlang.org/doc/man/mnesia.html).
