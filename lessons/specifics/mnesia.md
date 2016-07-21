---
layout: page
title: Mnesia
category: specifics
order: 5
lang: en
---

Mnesia is a heavy duty real-time distributed database management system.

{% include toc.html %}

## Overview

Mnesia is a Database Management System (DBMS) that ships with the Erlang Runtime System which we can use naturally with Elixir. The Mnesia *relational and object hybrid data model* is what makes it suitable for developing distributed applications of any scale.

## When to use

When to use a particular piece of technology is often a confusing pursuit. If you can answer 'yes' to any of the following questions, then this is a good indication to use Mnesia over ETS or DETS.

  - Do I need to roll back transactions?
  - Do I need an easy to use syntax for reading and writing data?
  - Should I store data across multiple nodes, rather than one?
  - Do I need a choice where to store information (RAM or disk)?

## Schema

As Mnesia is part of the the Erlang core, rather than Elixir, we have to access it with the colon syntax (See Lesson: [Erlang Interoperability](/lessons/advanced/erlang/)) as so:

```shell

iex> :mnesia.create_schema([node()])

# or if you prefer the Elixir feel...

iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
```

For this lesson, we will take the latter approach when working with the Mnesia API. `Mnesia.create_schema/1` initializes a new empty schema and passes in a Node List. In this case, we are passing in the node associated with our IEx session.

## Nodes

Once we run the `Mnesia.create_schema([node()])` command via IEx, you should see a folder called **Mnesia.nonode@nohost** or similar in your present working directory. You may be wondering what the **nonode@nohost** means as we haven't come across this before. Let's have a look.

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

When we pass in the `--help` option to IEx from the command line we are presented with all the possible options. We can see that there is a `--name` and `--sname` options for assigning information to nodes. A node is just a running Erlang Virtual Machine which handles it's own communications, garbage collection, processing scheduling, memory and more. The node is being named as **nonode@nohost** simply by default.

```shell
$ iex --name learner@elixirschool.com

Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex(learner@elixirschool.com)> Node.self
:"learner@elixirschool.com"
```

As we can now see, the node we are running is an atom called `:"learner@elixirschool.com"`. If we run `Mnesia.create_schema([node()])` again, we will see that it created another folder called **Mnesia.learner@elixirschool.com**. The purpose of this is quite simple. Nodes in Erlang are used to connect to other nodes to share (distribute) information and resources. This doesn't have to be restricted to the same machine and can communicate via LAN, the internet etc.

## Starting Mnesia

Now we have the background basics out of the way and set up the database, we are now in a position to start the Mnesia DBMS with the ```Mnesia.start/0``` command.

```shell
iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node])
:ok
iex> Mnesia.start()
:ok
```

It is worth keeping in mind when running a distributed system with two or more participating nodes, the function `Mnesia.start/1` must be executed on all participating nodes.

## Creating Tables

The function `Mnesia.create_table/2` is used to create tables within our database. Below we create a table called `Person` and then pass a keyword list defining the table schema.

```shell
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:atomic, :ok}
```

We define the columns using the atoms `:id`, `:name`, and `:job`. When we execute `Mnesia.create_table/2`, it will return either one of the following responses:

 - `{:atomic, :ok}` if the function executes successfully
 - `{:aborted, Reason}` if the function failed

## The Dirty Way

First of all we will look at the dirty way of reading and writing to an Mnesia table. This should generally be avoided as success is not guaranteed, but it should help us learn and become comfortable working with Mnesia. Let's add some entries to our **Person** table.

```shell
iex> Mnesia.dirty_write({Person, 1, "Seymour Skinner", "Principal"})
:ok

iex> Mnesia.dirty_write({Person, 2, "Homer Simpson", "Safety Inspector"})
:ok

iex> Mnesia.dirty_write({Person, 3, "Moe Szyslak", "Bartender"})
:ok
```

...and to retrieve the entries we can use `Mnesia.dirty_read/1`:

```shell
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

Traditionally we use **transactions** to encapsulate our reads and writes to our database. Transactions are an important part of designing fault-tolerant, highly distributed systems. An Mnesia *transaction is a mechanism by which a series of database operations can be executed as one functional block*. First we create an anonymous function, in this case `data_to_write` and then pass it onto `Mnesia.transaction`.

```shell
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
Based on this transaction message, we can safely assume that we have written the data to our `Person` table. Let's use a transaction to read from the database now to make sure. We will use `Mnesia.read/1` to read from the database, but again from within an anonymous function.

```shell
iex> data_to_read = fn ->
...>   Mnesia.read({Person, 6})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_read)
{:atomic, [{Person, 6, "Monty Burns", "Businessman"}]}
```
