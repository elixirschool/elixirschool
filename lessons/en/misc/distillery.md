%{
  version: "2.0.4",
  title: "Distillery (Basics)",
  excerpt: """
  Distillery is a release manager written in pure Elixir.
  It allows you to generate releases that can be deployed elsewhere with little to no configuration.
  """
}
---

## What is a release?

A release is a package containing your compiled Erlang/Elixir code (i.e [BEAM](https://en.wikipedia.org/wiki/BEAM_(Erlang_virtual_machine)) [bytecode](https://en.wikipedia.org/wiki/Bytecode)).
It also provides any scripts necessary for launching your application.

> When you have written one or more applications, you might want to create a complete system with these applications and a subset of the Erlang/OTP applications. This is called a release. - [Erlang documentation](http://erlang.org/doc/design_principles/release_structure.html)

> Releases enable simplified deployment: they are self-contained, and provide everything needed to boot the release; they are easily administered via the provided shell script to open up a remote console, start/stop/restart the release, start in the background, send remote commands, and more. In addition, they are archivable artifacts, meaning you can restore an old release from its tarball at any point in the future (barring incompatibilities with the underlying OS or system libraries). The use of releases is also a prerequisite of performing hot upgrades and downgrades, one of the most powerful features of the Erlang VM. - [Distillery Documentation](https://hexdocs.pm/distillery/introduction/understanding_releases.html)

A release will contain the following:

* a /bin folder
  * This contains a script that is the starting point to running your entire application.
* a /lib folder
  * This contains the compiled bytecode of the application along with any dependencies.
* a /releases folder
  * This contains metadata about the release as well as hooks and custom commands.
* a /erts-VERSION
  * This contains the Erlang runtime which will allow a machine to run your application without having Erlang or Elixir installed.

### Getting started/installation

To add Distillery to your project, add it as a dependency to your `mix.exs` file.
*Note* - if you are working on an umbrella app this should be in the mix.exs in the root of your project

```elixir
defp deps do
  [{:distillery, "~> 2.0"}]
end
```

Then in your terminal call:

```shell
mix deps.get
mix compile
```

### Building your release

In your terminal, run

```shell
mix release.init
```

This command generates a `rel` directory with some configuration files in it.

To generate a release in your terminal run `mix release`

Once the release is built you should see some instructions in your terminal

```
==> Assembling release..
==> Building release book_app:0.1.0 using environment dev
==> You have set dev_mode to true, skipping archival phase
Release successfully built!
To start the release you have built, you can use one of the following tasks:

    # start a shell, like 'iex -S mix'
    > _build/dev/rel/book_app/bin/book_app console

    # start in the foreground, like 'mix run --no-halt'
    > _build/dev/rel/book_app/bin/book_app foreground

    # start in the background, must be stopped with the 'stop' command
    > _build/dev/rel/book_app/bin/book_app start

If you started a release elsewhere, and wish to connect to it:

    # connects a local shell to the running node
    > _build/dev/rel/book_app/bin/book_app remote_console

    # connects directly to the running node's console
    > _build/dev/rel/book_app/bin/book_app attach

For a complete listing of commands and their use:

    > _build/dev/rel/book_app/bin/book_app help
```

To run your application type the following in your terminal `_build/dev/rel/MYAPP/bin/MYAPP foreground`
In your case replace MYAPP with your project name.
Now we're running the release build of our application!

## Using Distillery with Phoenix

If you are using distillery with Phoenix there are a few extra steps you need to follow before this will work.

First, we need to edit our `config/prod.exs` file.

Change the following line from this:

```elixir
config :book_app, BookAppWeb.Endpoint,
  load_from_system_env: true,
  url: [host: "example.com", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"
```

to this:

```elixir
config :book_app, BookAppWeb.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [host: "localhost", port: {:system, "PORT"}],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  root: ".",
  version: Application.spec(:book_app, :vsn)
```

We've done a few things here:

* `server` - boots up the Cowboy application http endpoint on application start
* `root` - sets up the application root which is where static files are served
* `version` - busts the application cache when the application version is hot upgraded.
* `port` - changing the port to be set by an ENV variable allows us to pass in the port number when starting up the application.
When we start up the app, we can supply the port by running `PORT=4001 _build/prod/rel/book_app/bin/book_app foreground`

If you executed the above command, you might have noticed that your application crashed because it is unable to connect to the database since no database currently exists.
This can be rectified by running an Ecto `mix` command.
In your terminal, type the following:

```shell
MIX_ENV=prod mix ecto.create
```

This command will create your database for you.
Try re-running the application and it should start up successfully.
However, you will notice that your migrations to your database have not run.
Usually in development we run those migrations manually by calling `mix ecto.migrate`.
For the release, we will have to configure it so that it can run the migrations on its own.

## Running Migrations in Production

Distillery provides us with the ability to execute code at different points in a release's lifecycle.
These points are known as [boot-hooks](https://hexdocs.pm/distillery/1.5.2/boot-hooks.html).
The hooks provided by Distillery include

* pre_start
* post_start
* pre/post_configure
* pre/post_stop
* pre/post_upgrade

For our purposes, we're going to be using the `post_start` hook to run our apps migrations in production.
Let's first go and create a new release task called `migrate`.
A release task is a module function that we can call on from the terminal that contains code that is separate from the inner workings of our application.
It is useful for tasks that the application itself will typically not need to run.

```elixir
defmodule BookAppWeb.ReleaseTasks do
  def migrate do
    {:ok, _} = Application.ensure_all_started(:book_app)

    path = Application.app_dir(:book_app, "priv/repo/migrations")

    Ecto.Migrator.run(BookApp.Repo, path, :up, all: true)
  end
end
```

*Note* It is good practice to ensure that your applications have all started up properly before running these migrations.
The [Ecto.Migrator](https://hexdocs.pm/ecto/2.2.8/Ecto.Migrator.html) allows us to run our migrations with the connected database.

Next, create a new file - `rel/hooks/post_start/migrate.sh` and add the following code:

```bash
echo "Running migrations"

bin/book_app rpc "Elixir.BookApp.ReleaseTasks.migrate"

```

In order for this code to run properly, we are using Erlang's `rpc` module which allows us Remote Procedure Call service.
Basically, this allows us to call a function on a remote node and get the answer.
When running in production it is likely that our application will be running in several different nodes

Finally, in our `rel/config.exs` file we're going to add the hook to our prod configuration.

Let's replace

```elixir
environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"TkJuF,3nc4)OWPBpPxPDb6mz$>)>a>/v/,l2}W*sUFaz<)bG,v*3pPESE,`XOk{,"
  set vm_args: "rel/vm.args"
end
```

with

```elixir
environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"TkJuF,3nc4)OWPBpPxPDb6mz$>)>a>/v/,l2}W*sUFaz<)bG,v*3pPESE,`XOk{,"
  set vm_args: "rel/vm.args"
  set post_start_hooks: "rel/hooks/post_start"
end
```

*Note* - This hook only exists in the production release of this application.
If we used the default development release it would not run.

## Custom Commands

When working with a release, you may not have access to `mix` commands as `mix` may not be installed to the machine the release is deployed to.
We can solve this by creating custom commands.

> Custom commands are extensions to the boot script, and are used in the same way you use foreground or remote_console, in other words, they have the appearance of being part of the boot script. Like hooks, they have access to the boot scripts helper functions and environment - [Distillery Docs](https://hexdocs.pm/distillery/1.5.2/custom-commands.html)

Commands are similar to release tasks in that they are both method functions but are different from them in that they are executed through the terminal as opposed to being run by the release script.

Now that we can run our migrations, we may want to be able to seed our database with information through running a command.
First, add a new method to our release tasks.
In `BookAppWeb.ReleaseTasks`, add the following:

```elixir
def seed do
  seed_path = Application.app_dir(:book_app_web, "priv/repo/seeds.exs")
  Code.eval_file(seed_path)
end
```

Next, create a new file `rel/commands/seed.sh` and add the following code:

```bash
#!/bin/sh

release_ctl eval "BookAppWeb.ReleaseTasks.seed/0"
```

*Note* - `release_ctl()` is a shell script provided by Distillery that allows us to execute commands locally or in a clean node.
If you need to run this against a running node you can run `release_remote_ctl()`

See more about shell_scripts from Distillery [here](https://hexdocs.pm/distillery/extensibility/shell_scripts.html)

Finally, add the following to your `rel/config.exs` file

```elixir
release :book_app do
  ...
  set commands: [
    seed: "rel/commands/seed.sh"
  ]
end

```

Be sure, to recreate the release by running `MIX_ENV=prod mix release`.
Once this is complete, you can now run in your terminal `PORT=4001 _build/prod/rel/book_app/bin/book_app seed`.
