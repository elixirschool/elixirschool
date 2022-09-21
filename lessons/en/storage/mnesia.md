%{
  version: "1.2.0",
  title: "Mnesia",
  excerpt: """
  Mnesia is a heavy duty real-time distributed database management system.
  """
}
---

## Overview

Mnesia is a Database Management System (DBMS) that ships with the Erlang Runtime System which we can use naturally with Elixir.
The Mnesia *relational and object hybrid data model* is what makes it suitable for developing distributed applications of any scale.

## When to use

When to use a particular piece of technology is often a confusing pursuit.
If you can answer 'yes' to any of the following questions, then this is a good indication to use Mnesia over ETS or DETS.

- Do I need to roll back transactions?
- Do I need an easy to use syntax for reading and writing data?
- Should I store data across multiple nodes, rather than one?
- Do I need a choice where to store information (RAM or disk)?

## Schema

As Mnesia is part of the Erlang core, rather than Elixir, we have to access it with the colon syntax (See Lesson: [Erlang Interoperability](/en/lessons/intermediate/erlang)):

```elixir

iex> :mnesia.create_schema([node()])

# or if you prefer the Elixir feel...

iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
```

For this lesson, we will take the latter approach when working with the Mnesia API.
`Mnesia.create_schema/1` initializes a new empty schema and passes in a Node List.
In this case, we are passing in the node associated with our IEx session.

## Nodes

Once we run the `Mnesia.create_schema([node()])` command via IEx, you should see a folder called **Mnesia.nonode@nohost** or similar in your present working directory.
You may be wondering what the **nonode@nohost** means as we haven't come across this before.
Let's have a look.

```shell
$ iex --help
Usage: iex [options] [.exs file] [data]

  -v                Prints version
  -e "command"      Evaluates the given command (*)
  -r "file"         Requires the given files/patterns (*)
  -S "script"       Finds and executes the given script
  -pr "file"        Requires the given files/patterns in parallel (*)
  -pa "path"        Prepends the given path to Erlang code path (*)
  -pz "path"        Appends the given path to Erlang code path (*)
  --app "app"       Start the given app and its dependencies (*)
  --erl "switches"  Switches to be passed down to Erlang (*)
  --name "name"     Makes and assigns a name to the distributed node
  --sname "name"    Makes and assigns a short name to the distributed node
  --cookie "cookie" Sets a cookie for this distributed node
  --hidden          Makes a hidden node
  --werl            Uses Erlang's Windows shell GUI (Windows only)
  --detached        Starts the Erlang VM detached from console
  --remsh "name"    Connects to a node using a remote shell
  --dot-iex "path"  Overrides default .iex.exs file and uses path instead;
                    path can be empty, then no file will be loaded

** Options marked with (*) can be given more than once
** Options given after the .exs file or -- are passed down to the executed code
** Options can be passed to the VM using ELIXIR_ERL_OPTIONS or --erl
```

When we pass in the `--help` option to IEx from the command line we are presented with all the possible options.
We can see that there is a `--name` and `--sname` options for assigning information to nodes.
A node is just a running Erlang Virtual Machine which handles it's own communications, garbage collection, processing scheduling, memory and more.
The node is being named as **nonode@nohost** simply by default.

```shell
$ iex --name learner@elixirschool.com

Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex(learner@elixirschool.com)> Node.self
:"learner@elixirschool.com"
```

As we can now see, the node we are running is an atom called `:"learner@elixirschool.com"`.
If we run `Mnesia.create_schema([node()])` again, we will see that it created another folder called **Mnesia.learner@elixirschool.com**.
The purpose of this is quite simple.
Nodes in Erlang are used to connect to other nodes to share (distribute) information and resources.
This doesn't have to be restricted to the same machine and can communicate via LAN, the internet etc.

## Starting Mnesia

Now we have the background basics out of the way and set up the database, we are now in a position to start the Mnesia DBMS with the `Mnesia.start/0` command.

```elixir
iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
:ok
iex> Mnesia.start()
:ok
```

The function `Mnesia.start/0` is asynchronous.
It starts the initialization of the existing tables and returns the `:ok` atom.
In case we need to perform some actions on an existing table right after starting Mnesia, we need to call the `Mnesia.wait_for_tables/2` function.
It will suspend the caller until the tables are initialized.
See the example in the section [Data initialization and migration](#data-initialization-and-migration).

It is worth keeping in mind when running a distributed system with two or more participating nodes, the function `Mnesia.start/1` must be executed on all participating nodes.

## Creating Tables

The function `Mnesia.create_table/2` is used to create tables within our database.
Below we create a table called `Person` and then pass a keyword list defining the table schema.

```elixir
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:atomic, :ok}
```

We define the columns using the atoms `:id`, `:name`, and `:job`.
The first atom (in this case `:id`) is the primary key.
At least one additional attribute is required.

When we execute `Mnesia.create_table/2`, it will return either one of the following responses:

- `{:atomic, :ok}` if the function executes successfully
- `{:aborted, Reason}` if the function failed

In particular, if the table already exists, the reason will be of the form `{:already_exists, table}` so if we try to create this table a second time, we will get:

```elixir
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:aborted, {:already_exists, Person}}
```

## The Dirty Way

First of all we will look at the dirty way of reading and writing to a Mnesia table.
This should generally be avoided as success is not guaranteed, but it should help us learn and become comfortable working with Mnesia.
Let's add some entries to our **Person** table.

```elixir
iex> Mnesia.dirty_write({Person, 1, "Seymour Skinner", "Principal"})
:ok

iex> Mnesia.dirty_write({Person, 2, "Homer Simpson", "Safety Inspector"})
:ok

iex> Mnesia.dirty_write({Person, 3, "Moe Szyslak", "Bartender"})
:ok
```

...and to retrieve the entries we can use `Mnesia.dirty_read/1`:

```elixir
iex> Mnesia.dirty_read({Person, 1})
[{Person, 1, "Seymour Skinner", "Principal"}]

iex> Mnesia.dirty_read({Person, 2})
[{Person, 2, "Homer Simpson", "Safety Inspector"}]

iex> Mnesia.dirty_read({Person, 3})
[{Person, 3, "Moe Szyslak", "Bartender"}]

iex> Mnesia.dirty_read({Person, 4})
[]
```

If we try to query a record that doesn't exist Mnesia will respond with an empty list.

## Transactions

Traditionally we use **transactions** to encapsulate our reads and writes to our database.
Transactions are an important part of designing fault-tolerant, highly distributed systems.
An Mnesia *transaction is a mechanism by which a series of database operations can be executed as one functional block*.
First we create an anonymous function, in this case `data_to_write` and then pass it onto `Mnesia.transaction`.

```elixir
iex> data_to_write = fn ->
...>   Mnesia.write({Person, 4, "Marge Simpson", "home maker"})
...>   Mnesia.write({Person, 5, "Hans Moleman", "unknown"})
...>   Mnesia.write({Person, 6, "Monty Burns", "Businessman"})
...>   Mnesia.write({Person, 7, "Waylon Smithers", "Executive assistant"})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_write)
{:atomic, :ok}
```

Based on this transaction message, we can safely assume that we have written the data to our `Person` table.
Let's use a transaction to read from the database now to make sure.
We will use `Mnesia.read/1` to read from the database, but again from within an anonymous function.

```elixir
iex> data_to_read = fn ->
...>   Mnesia.read({Person, 6})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_read)
{:atomic, [{Person, 6, "Monty Burns", "Businessman"}]}
```

Note that if you want to update data, you just need to call `Mnesia.write/1` with the same key as an existing record.
Therefore, to update the record for Hans, you can do:

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.write({Person, 5, "Hans Moleman", "Ex-Mayor"})
...>   end
...> )
```

## Using indices

Mnesia support indices on non-key columns and data can then be queried against those indices.
So we can add an index against the `:job` column of the `Person` table:

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:atomic, :ok}
```

The result is similar to the one returned by `Mnesia.create_table/2`:

- `{:atomic, :ok}` if the function executes successfully
- `{:aborted, Reason}` if the function failed

In particular, if the index already exists, the reason will be of the form `{:already_exists, table, attribute_index}` so if we try to add this index a second time, we will get:

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:aborted, {:already_exists, Person, 4}}
```

Once the index is successfully created, we can read against it and retrieve a list of all principals:

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.index_read(Person, "Principal", :job)
...>   end
...> )
{:atomic, [{Person, 1, "Seymour Skinner", "Principal"}]}
```

## Match and select

Mnesia supports complex queries to retrieve data from a table in the form of matching and ad-hoc select functions.

The `Mnesia.match_object/1` function returns all records that match the given pattern.
If any of the columns in the table have indices, it can make use of them to make the query more efficient.
Use the special atom `:_` to identify columns that don't participate in the match.

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.match_object({Person, :_, "Marge Simpson", :_})
...>   end
...> )
{:atomic, [{Person, 4, "Marge Simpson", "home maker"}]}
```

The `Mnesia.select/2` function allows you to specify a custom query using any operator or function in the Elixir language (or Erlang for that matter).
Let's look at an example to select all records that have a key that is greater than 3:

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.select(Person, [{{Person, :"$1", :"$2", :"$3"}, [{:>, :"$1", 3}], [:"$$"]}])
...>   end
...> )
{:atomic, [[7, "Waylon Smithers", "Executive assistant"], [4, "Marge Simpson", "home maker"], [6, "Monty Burns", "Businessman"], [5, "Hans Moleman", "unknown"]]}
```

Let's unpack this.
The first attribute is the table, `Person`, the second attribute is a triple of the form `{match, [guard], [result]}`:

- `match` is the same as what you'd pass to the `Mnesia.match_object/1` function; however, note the special atoms `:"$n"` that specify positional parameters that are used by the remainder of the query
- the `guard` list is a list of tuples that specifies what guard functions to apply, in this case the `:>` (greater than) built in function with the first positional parameter `:"$1"` and the constant `3` as attributes
- the `result` list is the list of fields that are returned by the query, in the form of positional parameters of the special atom `:"$$"` to reference all fields so you could use `[:"$1", :"$2"]` to return the first two fields or `[:"$$"]` to return all fields

For more details, see [the Erlang Mnesia documentation for select/2](http://erlang.org/doc/man/mnesia.html#select-2).

## Data initialization and migration

With every software solution, there will come a time when you need to upgrade the software and migrate the data stored in your database.
For example, we may want to add an `:age` column to our `Person` table in v2 of our app.
We can't create the `Person` table once it's been created but we can transform it.
For this we need to know when to transform, which we can do when creating the table.
To do this, we can use the `Mnesia.table_info/2` function to retrieve the current structure of the table and the `Mnesia.transform_table/3` function to transform it to the new structure.

The code below does this by implementing the following logic:

- Create the table with the v2 attributes: `[:id, :name, :job, :age]`
- Handle the creation result:
  - `{:atomic, :ok}`: initialize the table by creating indices on `:job` and `:age`
  - `{:aborted, {:already_exists, Person}}`: check what the attributes are in the current table and act accordingly:
    - if it's the v1 list (`[:id, :name, :job]`), transform the table giving everybody an age of 21 and add a new index on `:age`
    - if it's the v2 list, do nothing, we're good
    - if it's something else, bail out

If we are performing any actions on the existing tables right after starting Mnesia with `Mnesia.start/0`, those tables may not be initialized and accessible.
In that case, we should use the [`Mnesia.wait_for_tables/2`](http://erlang.org/doc/man/mnesia.html#wait_for_tables-2) function.
It will suspend the current process until the tables are initialized or until the timeout is reached.

The `Mnesia.transform_table/3` function takes as attributes the name of the table, a function that transforms a record from the old to the new format and the list of new attributes.

```elixir
case Mnesia.create_table(Person, [attributes: [:id, :name, :job, :age]]) do
  {:atomic, :ok} ->
    Mnesia.add_table_index(Person, :job)
    Mnesia.add_table_index(Person, :age)
  {:aborted, {:already_exists, Person}} ->
    case Mnesia.table_info(Person, :attributes) do
      [:id, :name, :job] ->
        Mnesia.wait_for_tables([Person], 5000)
        Mnesia.transform_table(
          Person,
          fn ({Person, id, name, job}) ->
            {Person, id, name, job, 21}
          end,
          [:id, :name, :job, :age]
          )
        Mnesia.add_table_index(Person, :age)
      [:id, :name, :job, :age] ->
        :ok
      other ->
        {:error, other}
    end
end
```
