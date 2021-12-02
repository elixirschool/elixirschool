%{
version: "1.1.0",
title: "Getting Started",
excerpt: """
Getting started with Phoenix in a few easy steps.
"""
}

---

## Getting Started

Before we can get started with Phoenix we need to install Elixir which we recommend doin with the [asdf version manager](https://elixirschool.com/blog/asdf-version-management). We'll also be using Postgres which can be installed following their official [documentation](https://www.postgresql.org/download/).

## Installing Phoenix

Installing Phoenix is made easy using `mix archive.install`, we just need to run:

```
$ mix archive.install hex phx_new
```

This installs everything necessary for us to create Phoenix new projects.

**Note**: When using Linux it may be necessary to to install [inotify-tools](https://github.com/inotify-tools/inotify-tools/wiki) working with Phoenix applications.

## Creating a new project

Since we've installed the Phoenix archive we have access to a convenient mix task for generating new projects: `mix phx.new`.
This generator comes with a number of options to customize our application but for this project we'll stick with the defaults. To learn more about the options available please refer to the official [Mix.Tasks.Phx.New docs](https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html).

```bash
$ mix phx.new phx_example
* creating phx_example/config/config.exs
* creating phx_example/config/dev.exs
* creating phx_example/config/prod.exs
* creating phx_example/config/runtime.exs
* creating phx_example/config/test.exs
* creating phx_example/lib/phx_example/application.ex
* creating phx_example/lib/phx_example.ex
* creating phx_example/lib/phx_example_web/views/error_helpers.ex
...
* creating phx_example/assets/css/phoenix.css
* creating phx_example/assets/css/app.css
* creating phx_example/assets/js/app.js
* creating phx_example/priv/static/robots.txt
* creating phx_example/priv/static/images/phoenix.png
* creating phx_example/priv/static/favicon.ico

Fetch and install dependencies? [Yn] y
* running mix deps.get
* running mix deps.compile

We are almost there! The following steps are missing:

    $ cd phx_example

Then configure your database in config/dev.exs and run:

    $ mix ecto.create

Start your Phoenix app with:

    $ mix phx.server

You can also run your app inside IEx (Interactive Elixir) as:

    $ iex -S mix phx.server
```

## Database Configuration

If we follow the standard Postgres installation the Phoenix defaults should work. However, it may be necessary to change our database configuration to connect with our local instance. We can find the configuration at the top of `config/dev.exs`:

```elixir
import Config

# Configure your database
config :phx_example, PhxExample.Repo,
  username: "postgres",
  password: "postgres",
  database: "phx_example_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

...
```

Once our configuration is correct we can move on with creating our database. This can be accomplished by running `mix ecto.create`:

```bash
$ mix ecto.create
```

## Running the application

Finally, we can run our new Phoenix application with:

```bash
mix phx.server
```

By default, phoenix applications runs at port 4000. If we go to http://localhost:4000 we should see our new Phoenix application!

That's it! We've installed Phoenix and created a new Phoenix application! In the next lesson we'll explore how to create new API endpoints, database tables, and Ecto Schemas using Phoenix generators.
