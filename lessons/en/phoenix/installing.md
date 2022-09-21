%{
  version: "1.0.0",
  title: "Installing Phoenix",
  excerpt: """
  With some simple steps you can install and create your first phoenix project
  """
}
---

## Getting Started

### Some considerations

Before creating a Phoenix project, we will need to install elixir. The latest version of phoenix framework needs [Elixir 12 or later](https://hexdocs.pm/phoenix/installation.html#erlang-22-or-later) and [Erlang 22 or later](https://hexdocs.pm/phoenix/installation.html#erlang-22-or-later).

We'll also need some database to run yotheur application, we recommend you to install PostgreSQL. You can check the [installation guides](https://wiki.postgresql.org/wiki/Detailed_installation_guides) to install it.

**linux users**: We might need to install the [inotify-tools](https://github.com/inotify-tools/inotify-tools/wiki) to run the phoenix application.

### Installing Phoenix

To start, we need to install the Hex package manager. The package manager is necessary to get the Phoenix Application because some dependencies are installed with it, and some extra dependencies might need along the way.

```bash
mix local.hex
```

After installing the Hex package manager, we can install the phx.new generator.

```
mix archive.install hex phx_new
```

We'll have all the necessary tools to create a Phoenix Project

obs: We'll need to answer Y to allow both of them to install.

## Creating the First Phoenix Project

To create a new project, just run the command `mix phx.new` from any directory in order to bootstrap our Phoenix application. On the example above, we are creating a new project with the name of `hello`

```bash
$ mix phx.new hello
* creating hello/config/config.exs
* creating hello/config/dev.exs
* creating hello/config/prod.exs
...
Fetch and install dependencies? [Yn]
```

After installation is done, we can access the project folder with `cd hello`

### Database Configuration

We need to setup our project to connect to our local database. Go to the `config/` folder and open the file `dev.exs`, and we'll see a file with something like that
Don't forget to change the username and password configs (if necessary). We may also need to change the test environment (`config/test.exs`)

```elixir
# Configure your database
config :hello, Hello.Repo,
  username: "postgres", # Change your database username
  password: "postgres", # Change your database password
  database: "hello_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
...
...
```

Now we can create the application database with:

```bash
mix ecto.create
```

### Running the application

Finally, we can run the application with:

```bash
mix phx.server
```

By default, phoenix applications runs at port 4000. If we go to <http://localhost:4000>, we should see this page

![](/images/hello_phoenix.png)
