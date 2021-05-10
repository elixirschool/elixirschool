%{
  author: "Sophie DeBenedetto",
  author_link: "https://github.com/sophiedebenedetto",
  date: ~D[2019-09-20],
  tags: ["docker", "mix release", "config", "umbrella apps", "general"],
  title: "Releasing an Umbrella App with Docker, Mix Release and Config",
  excerpt: """
  The release of Elixir 1.9 gave us `mix release` and the ability to support basic releases, runtime configuration and more, natively in Elixir. Learn how we were able to build a production release of an Elixir umbrella app with Docker, `mix release` and the new `Config` module.
  """
}

---

The prelease of Elixir 1.9 earlier this year introduced some [powerful new tools](http://blog.plataformatec.com.br/2019/04/whats-new-in-elixir-apr-19/). `mix release` allows us to build a release without Distillery; configuration for our umbrella child apps has been moved to the parent application; the addition of the `Config` module deprecates `Mix.Config` and makes it easy to configure our releases, and configuration has been further simplified with the addition of functions like `System.fetch_env!`.

Let's take advantage of _all_ of these new features in order to build a release of an Elixir umbrella app with the help of Docker.

## Background: Our Build + Deploy Process

First, a little background on the build and deployment process for the app in question. At The Flatiron School, we maintain an app, Registrar, to handle our student admissions and billing. The Registrar app is an Elixir umbrella app that is built and deployed using a CI/CD pipeline managed by CircleCi and AWS Fargate. Registrar is built by circle and the resulting image is pushed to ECR (Elastic Container Repository). Fargate pulls down the image and runs the containerized release in ECS.

If that setup is confusing or unfamiliar to you--no problem! The only thing you need to understand for the purposes of this blog post is that our applicaton's environment variables are _not_ available when we build our release but they _are_ available at runtime.

## Initializing the Release

Before we get started, we'll run `mix release.init` from the root of our umbrella app. This will generate the following files:

* `rel/env.sh`
* `rel/env.bat`
* `rel/vm.args`

More on these files later.


## Configuring the Umbrella App with the `Config` Module

The first thing we need to do is make sure our Elixir umbrella app's children are properly configured with the new `Config` module.

Where our umbrella app's formerly help the configuration for each child in the `config/` subdirectory of that child app, we are now configuring each child application in the parent app directly. So, the config directory top-level app, `registrar_umbrella`, is where all the action happens.

We'll start by taking a look at the `registrar_umbrella/config/config.exs` file.

Where we have an umbrella app, `registrar_umbrella`, with two children, `registrar` and `registrar_web`, our `config.exs` file might look something like this:

```elixir
# registrar_umbrella/config/config.exs

import Config

config :registrar,
  stripe_api_base_url: System.get_env("STRIPE_BASE_URL"),
  stripe_api_key: System.get_env("STRIPE_SECRET_KEY"),
  accounts: Registrar.Accounts,
  billing: Registrar.Billing

config :registrar_web,
  learn_base_url: System.get_env("LEARN_OAUTH_BASE_URL"),
  learn_client_id: System.get_env("LEARN_OAUTH_CLIENT_ID"),
  learn_client_secret: System.get_env("LEARN_OAUTH_CLIENT_SECRET"),
  learn_client: RegistrarWeb.OAuth.LearnClient

# Configures the endpoint
config :registrar_web, RegistrarWeb.Endpoint,
  server: true,
  url: [host: "localhost"],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  render_errors: [view: RegistrarWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: RegistrarWeb.PubSub, adapter: Phoenix.PubSub.PG2]

...

import_config "#{Mix.env}.exs"
```

Let's break this down.

### The `Config` Module

Note that we've included `import Config` at the top of the file. Elixir 1.9 soft-deprecates the usage of `use Mix.Config` and here's why. Releases will have their own configuration, including a runtime configuration determined by the `config/releases.exs` file (more on that later). Mix, however, is a build tool. As such, it is not available in your release. So, we don't want to rely on it and can instead use the (new!) native Elixir `Config` module for all of our configuration needs.

### Environment-specific Configuration

We can continue to set environment-specific config in the `config/dev.exs`, `config/test.exs` and `config/prod.exs`. The `import_config "#{Mix.env}.exs"` line will import the appropriate configuration file at compile-time.

### Using `System.get_env/1`

In our `config.exs` file, we're using `System.get_env/1`. This will return the value of the given environment variable, _if it is present on the system at compile time_. Otherwise it will return `nil`. Using `System.get_env/1` will work for us just fine in the development and test environments, but it _won't_ fly in our production environment. This is because, for our particular app's build and deployment pipeline, we are building the release in an environment whose system does _not_ contain the environment variables our app needs, like `"STRIPE_SECRET_KEY"` for example. Our production release's _runtime_ environment will have those variables, however.

Now that we've seen how to configure the child app's of our umbrella with the help of the `Config` module and `System.get_env/1`, let's take a look at our release configuration.

## Configuring The Release

### Defining The Release in `config/mix.exs`

We'll start by configuring our release in the top-level `mix.exs` file under the `:releases` key inside the `project/0` function:

```elixir
# registrar_umbrella/mix.exs
defmodule Registrar.Umbrella.Mixfile do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      version: "0.1.0",
      elixir: "~> 1.9",
      releases: [
        registrar_umbrella: [
          applications: [
            registrar: :permanent,
            registrar_web: :permanent
          ]
        ]
      ]
    ]
  end
  ...
end
```

We can define multiple releases by adding subsequent keys under `:releases`––for example if we want to create a release that runs _just_ the `registrar` application. For now, we're defining just one release, `registrar_umbrella`. For an umbrella app's release configuration, we _must_ specify which child apps to start when the release starts. We do this by listing the child apps we want to start under the `:applications` key.

There are a number of additional release configuration options that you can check out [here](https://hexdocs.pm/mix/Mix.Tasks.Release.html#module-customization), but we'll keep our configuration pretty barebones for now.

### Runtime Configuration with `config/releases.exs`

Since our build and deployment pipeline requires that our app's environment variables be present at _runtime_, rather than build time, we need our release to have runtime configuration. To enable runtime configuration for our release, we create a file, `config/releases.exs`.

```elixir
# registrar_umbrella/config/releases.exs

import Config

config :registrar,
  stripe_api_base_url: System.fetch_env!("STRIPE_BASE_URL"),
  stripe_api_key: System.fetch_env!("STRIPE_SECRET_KEY")

config :registrar_web,
  learn_base_url: System.fetch_env!("LEARN_OAUTH_BASE_URL"),
  learn_client_id: System.fetch_env!("LEARN_OAUTH_CLIENT_ID"),
  learn_client_secret: System.fetch_env!("LEARN_OAUTH_CLIENT_SECRET")

# Configures the endpoint
config :registrar_web, RegistrarWeb.Endpoint,
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE")
```

Here we're configuring all of our runtime application environment variables with the help of `System.fetch_env!/1`. This function will raise an error if the given environment variable is not present in the system at runtime. We want this kind of validation in place so that our app fails to start up if its missing necessary environment variables--no silent failures downstream.

Its important to understand that we are still leveraging a `config/prod.exs` file (not included here) to do things like configure our `ReigstrarWeb.Endpoint` for production. This file is specifically for our runtime release configuration.

One last thing to point out before we move on.

Let's say we have the following application environment variable getting set in our release at runtime:

```elixir
# registrar_umbrella/config/config.exs

import Config

config :registrar,
  stripe_api_base_url: System.fetch_env!("STRIPE_BASE_URL")
```

And we have a module, `Registrar.StripeApiClient` that uses a module attribute to look up and store the value of that application environment variable:

```elixir
# registrar_umbrella/apps/registrar/lib/stripe_api_client.ex

defmodule Registrar.StripeApiClient do
  @stripe_api_base_url Application.get_env(:registrar, :stripe_api_base_url)

  def get(url) do
    HTTPoison.get(@stripe_api_base_url <> url)
  end
end
```

While developers often use user-defined module attributes as constants, its important to remember that _the value is read at compilation time and not at runtime._ Since the value of `Application.get_env(:registrar, :stripe_api_base_url)` (which comes from a system environment variable) is only present at _runtime_, using a module attribute here won't work!

Instead, we'll use a function to dynamically look up the value at runtime:

```elixir
# registrar_umbrella/apps/registrar/lib/stripe_api_client.ex

defmodule Registrar.StripeApiClient do
  defp stripe_api_base_url, do: Application.get_env(:registrar, :stripe_api_base_url)

  def get(url) do
    HTTPoison.get(stripe_api_base_url() <> url)
  end
end
```

Now that we have our runtime configuration set up, we're ready to build our release!

## Building the Release with Docker + `mix release`

We're using Docker to build our release, since our app will run in a container within our ECS cluster.

Our Dockerfile is pretty straightforward:

```
FROM bitwalker/alpine-elixir-phoenix:1.9.0 as releaser

WORKDIR /app

# Install Hex + Rebar
RUN mix do local.hex --force, local.rebar --force

COPY config/ /app/config/
COPY mix.exs /app/
COPY mix.* /app/

COPY apps/registrar/mix.exs /app/apps/registrar/
COPY apps/registrar_web/mix.exs /app/apps/registrar_web/

ENV MIX_ENV=prod
RUN mix do deps.get --only $MIX_ENV, deps.compile

COPY . /app/


WORKDIR /app/apps/registrar_web
RUN MIX_ENV=prod mix compile
RUN npm install --prefix ./assets
RUN npm run deploy --prefix ./assets
RUN mix phx.digest

WORKDIR /app
RUN MIX_ENV=prod mix release

########################################################################

FROM bitwalker/alpine-elixir-phoenix:1.9.0

EXPOSE 4000
ENV PORT=4000 \
    MIX_ENV=prod \
    SHELL=/bin/bash

WORKDIR /app
COPY --from=releaser app/_build/prod/rel/registrar_umbrella .
COPY --from=releaser app/bin/ ./bin

CMD ["./bin/start"]
```

Let's take a closer look at the parts we really care about.

First, we se the `MIX_ENV` to `prod` and get and compile our production dependencies:

```
ENV MIX_ENV=prod
RUN mix do deps.get --only $MIX_ENV, deps.compile
```

Later, we build our production assets for the `registrar_web` child app:

```
WORKDIR /app/apps/registrar_web
RUN MIX_ENV=prod mix compile
RUN npm install --prefix ./assets
RUN npm run deploy --prefix ./assets
RUN mix phx.digest
```

Then we use `mix release` to build our release according to the configuration in the `:releases` key of the `project/0` function in our `mix.exs` file.

```
WORKDIR /app
RUN MIX_ENV=prod mix release
```

This builds our release and places it in `_build/prod/rel/registrar_umbrella`.

Finally, we copy the release into our container and specify that the start script is in `./bin/start`.

Let's talk about that start script now.

## The Start Script

Starting our release is simple. Our `./bin/start` script looks like this:

```bash
#!/usr/bin/env bash

set -e

echo "Starting app..."
bin/registrar_umbrella start
```

At this point, you _might_ be remembering that Distillery provides a "boot hook" feature that allows you to run certain commands/execute some code when the app starts up. You _might_ be wondering how we can accomplish the same goal using `mix release`. How can we, for example, ensure that our migrations run whenever the release starts up? Keep reading to find out!

## Pre-Start Scripts with `rel/env.sh`

The `rel/env.sh` file that was generated by `mix release.init` will run when the release starts. This is where we'll call on our migration script.

Assume we have a module, `Registrar.ReleaseTasks` with a function, `migrate/0` that starts up the application and executes the Ecto migrations:

```elixir
defmodule Registrar.ReleaseTasks do
  @moduledoc false

  @start_apps [
    :crypto,
    :ssl,
    :postgrex,
    :ecto,
    :ecto_sql
  ]

  @repos Application.get_env(:registrar, :ecto_repos, [])

  def migrate do
    start_services()
    run_migrations()
    stop_services()
  end

  defp start_services do
    IO.puts("Starting dependencies..")
    # Start apps necessary for executing migrations
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    # Start the Repo(s) for app
    IO.puts("Starting repos..")

    # Switch pool_size to 2 for ecto > 3.0
    Enum.each(@repos, & &1.start_link(pool_size: 2))
  end

  defp stop_services do
    IO.puts("Success!")
    :init.stop()
  end

  defp run_migrations do
    Enum.each(@repos, &run_migrations_for/1)
  end
end
```

We can execute this function in our release using `eval`. A call `bin/MY_RELEASE eval` will start up your release and execute whatever function you give as an argument to `eval`. To execute our migration function in our release:

```
bin/registrar_umbrella eval "Registrar.ReleaseTasks.migrate()"
```

Recall that we're starting our release in `./bin/start` with that `start` command:

```
bin/registrar_umbrella start
```

This will execute the `rel/env.sh` file in turn. This file should contain a script that does the following:

* If the command given to the release was `start`, run the migrations using `eval`.

Something like this should do the trick:

```
if [ "$RELEASE_COMMAND" = "start" ]; then
 echo "Beginning migration script..."
 bin/registrar_umbrella eval "Registrar.ReleaseTasks.migrate()"
fi
```

And that's it!

## Conclusion

With Elixir 1.9, we can build a release without the addition of any external dependencies––Elixir now natively provides us everything we need. We can configure multiple releases for our umbrella app, defining which child apps to start for a given release. We can configure runtime vs. build time environment variables _and_ we can even define customized start up scripts to do things like run our migrations. All in all, `mix release` provides us with a comprehensive and powerful set of tools.
