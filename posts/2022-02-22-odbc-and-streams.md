%{
author: "Bobby Grayson",
author_link: "https://github.com/notactuallytreyanastasio",
tags: [],
date: ~D[2022-02-22],
title: "`:odbc` and Efficient Querying With Streams",
excerpt: """
Learn how to use Erlang's built in `:odbc` interface to query using streams effectively
"""
}

---

# `:odbc` and and Efficient Querying With Streams

Erlang offers an interface to [ODBC](https://docs.microsoft.com/en-us/sql/odbc/microsoft-open-database-connectivity-odbc?view=sql-server-ver15) at a native level.

This can be used to communicate with a variety of different databases.

One that is particularly useful is [Snowflake](https://en.wikipedia.org/wiki/Snowflake_Inc.#cite_note-raises-5).

This is a great general purpose data warehouse.

Since it is a warehouse, one can imagine that queries can get quite large.

If you are building an interface to this, in order to remain low-memory, you might want to build a wrapper around `:odbc` that can talk to it in a lazy way to pull data and move it around to other sources for things like analysis, or for intake into another system for a service.

This post will give a simple dive into getting a basic connection and streaming some data, and can serve as a jumping off point if you ever need to write a client API for something like this.

## Getting Things Running

Since `:odbc` is included in Erlang, we don't need to include any dependencies.
We can create a new supervised project and get started immediately

```shell
mix new my_etl_odbc_app --sup
cd my_etl_odbc_app
mix compile
```

Now, let's make a config for our connection.

```shell
mkdir config
touch config/config.exs
```

And we open that up:

```elixir
import Config

config :my_etl_odbc_app,
  connection: [
    server: "some.server.path",
    uid: "your_user",
    pwd: "your_password",
    role: "your_role",
    warehouse: "your_warehouse_name"
  ]
```

Now, we can just throw our code into `lib/my_etl_odbc_app.ex`.

We will start with a simple example: streaming some data to a file.
This is a trivial example, but it is not inconceivable that we may want to run a Warehouse analysis query and then persist it to S3 or some other data store.

```elixir
defmodule MyEtlOdbcApp do
  @query """
  -- obviously, fill in your own query here
  SELECT id, name, owner_id, description FROM thing_stuffs;
  """

  def run(query) do
    temp_file_stream = File.stream!("/var/tmp/#{DateTime.utc_now()}", [:utf8])
    {:ok, pid} = connect(connection_args)
    {odbc_conn_pid, count} = query_warehouse(pid, @query)

    row_stream =
      Stream.flat_map(1..count, fn _n ->
        odbc_pid
        |> :odbc.next()
        |> process_results([])
      end)

    row_stream
    |> Stream.map(fn row ->
      row_io = Jason.encode_to_iodata!(row)
      [row_io, ?\n]
    end)
    |> Stream.into(temp_file_stream)
    |> Stream.run()
  end

  defp query_warehouse(pid, query) do
    cl_query = to_char_list(query)
    {:ok, count} = :odbc.select_count(pid, cl_query)
    {pid, count}
  end

  defp connect(connection_args) do
    driver = Application.get_env(:my_etl_odbc_app, :connection)
    connection_args = [{:driver, driver} | connection_args]

    conn_str =
      connection_args
      |> Enum.reduce("", fn {key, value}, acc -> acc <> "#{key}=#{value};" end)
      |> to_charlist()

    {:ok, pid} = :odbc.connect(conn_str, [])
  end

  defp process_results(data, opts) when is_list(data) do
    Enum.map(data, &process_results(&1, opts))
  end

  defp process_results({:selected, headers, rows}, opts) do
    bin_headers =
      headers
      |> Enum.map(fn header -> header |> to_string() end)
      |> Enum.with_index()

    Enum.map(rows, fn row ->
      Enum.reduce(bin_headers, %{}, fn {col, index}, map ->
        data = elem(row, index)
        Map.put(map, col, data)
      end)
    end)
  end
  defp process_results({:updated, _} = results, _opts), do: results
end
```

## Breaking The Code Down

There are a lot of moving parts here that are quite specific to `:odbc` and the fact it relies on charlists over binaries like most higher level Elixir APIs.

Let's look at this piece by piece.

```elixir
  def run(query) do
    temp_file_stream = File.stream!("/var/tmp/#{DateTime.utc_now()}", [:utf8])
    {:ok, pid} = connect(connection_args)
    # ...
```

Here, we start things off by creating a temporary file stream, and getting a connection to work with.

Here is the `connect/1` code:

```elixir
  defp connect(connection_args) do
    driver = Application.get_env(:my_etl_odbc_app, :connection)
    connection_args = [{:driver, driver} | connection_args]

    conn_str =
      connection_args
      |> Enum.reduce("", fn {key, value}, acc -> acc <> "#{key}=#{value};" end)
      |> to_charlist()

    {:ok, pid} = :odbc.connect(conn_str, [])
  end
```

Here, we establish the connection by making the drivers preferred format for a connection string using our earlier configuration, and get a connection pid we can begin to work with.

Back to the `run` function:

```elixir
    row_stream =
      Stream.flat_map(1..count, fn _n ->
        odbc_pid
        |> :odbc.next()
        |> process_results([])
      end)
```

`:odbc.next/1` is the simplest way to iterate through results.

You can also call `:odbc.select/2` and handle jumping in pages.
However, if you want to keep memory use minimal, this implementation works quite efficiently.
In our production system, it spiked memory usage by about 400mb for querying and processing 1.8M rows of data with 25 columns.
Doing this in memory took up about 25gb.
Paging actually used more memory than `next/1`!
So we stuck to this way.

`process_results/2` is now the meat of what we work with to manipulate the data into something more useful.

Let's take a look at that:

```elixir
  defp process_results(data, opts) when is_list(data) do
    Enum.map(data, &process_results(&1, opts))
  end

  defp process_results({:selected, headers, rows}, opts) do
    bin_headers =
      headers
      |> Enum.map(fn header -> header |> to_string() end)
      |> Enum.with_index()

    Enum.map(rows, fn row ->
      Enum.reduce(bin_headers, %{}, fn {col, index}, map ->
        data = elem(row, index)
        Map.put(map, col, data)
      end)
    end)
  end
  defp process_results({:updated, _} = results, _opts), do: results
```

Here, we are iterating through in the format `next/1` returns, which is a tuple of `:selected`, your headers, and that row's data.
We reduce through to return it as a map after making the headers binaries instead of charlists.

Once this is complete, we are returning a nice map of all the data.

In this case, let's write it in a JSON-LD format.

The final clause catches the end of the query and allows it to finish.

We can add `jason` to `mix.exs`.

```elixir
  defp deps do
    [
      {:jason, "~> 1.3.0"},
    ]
  end
```

Now, we can move on to the rest of our run function.

```elixir
    row_stream
    |> Stream.map(fn row ->
      row_io = Jason.encode_to_iodata!(row)
      [row_io, ?\n]
    end)
    |> Stream.into(temp_file_stream)
    |> Stream.run()
```

Now, we make our row stream and our query stream work together to write to the file!

Once it completes, you can find it at the path we hard-coded.

## Conclusion

In a real system, since `:odbc` makes one process per connection, you will want to use a tool like [Poolboy](https://hex.pm/packages/poolboy).
Check out the [post on Poolboy](https://elixirschool.com/en/lessons/misc/poolboy) to see how you could integrate it into this querying interface as to not overload whatever database you may be talking to.

If you are interesting in implementing this with paging, I recommend looking into `Stream.resource/3`.
`Stream.resource/3` will allow you to use a 0 accumulator to build up your offset to interpolate in your querying interfaces.

I hope this post helps anyone who has to dive into the `:odbc` module to work with data efficiently.
