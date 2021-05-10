%{
  author: "Sean Callan",
  author_link: "https://github.com/doomspork",
  date: ~D[2018-07-17],
  tags: ["configuration", "software design", "general"],
  title: "Configuration Demystified",
  excerpt: """
  We attempt to clear up some confusion around configuration by looking at the different types, the roles they play, and a different approach we could take.
  """
}

---

There's been a lot of discussion about configuration in the community lately.
We thought this would be an opportune time to discuss configuration and how best to handle it within an Elixir application.
It is surprising to see how a small change to our applications configuration can eliminate much of the headaches others are experiencing.

### Configuration types

Before we go any further, let's look at the two configuration types and the roles they play.

__Runtime Configuration__

If you've ever used a system environment variable to configure some part of your application, then you're familiar with runtime configuration.
As the name suggests, this is the configuration for an application at the time it is run.
These are the values we can expect to change as we deploy our build artifacts to different systems.

__Build-time Configuration__

Our build-time configuration, sometimes known as Application configuration, is something different and the difference, while subtle, can be a pitfall in certain situations.
The difference shines when we consider that our code, and its configuration, is compiled into a build artifact we can distribute.

We can say with certainty that no matter where our application is run there are certain things we want to remain constant; we intend to use the same `Logger` configuration regardless of where we deploy.
If we're relying on dependency injection for testing, then we know for certain we don't want to use those dependencies in the final deliverable.
They configure the function of our code.

### How it's been done

The frustration for many people has to do with the usage of `Application.get_env/2` and `System.get_env/1`.
We'll jump right in by looking at a configuration that's common to many Elixir projects:

```elixir
use Mix.Config

config :example_app, Data.Repo,
  adapter: Ecto.Adapters.MySQL,
  username: System.get_env("EXAMPLE_APP_USERNAME"),
  password: System.get_env("EXAMPLE_APP_PASSWORD"),
  hostname: System.get_env("EXAMPLE_APP_HOSTNAME"),
  database: System.get_env("EXAMPLE_APP_DATABASE"),
  pool_size: 10
```

Simple and harmless enough, right?
Wrong!

Our application's configuration, defined in `config.exs` and friends, is compiled when we generate build artifacts, like those produced by Distillery.
That means those `System.get_env/1` functions need to be resolved at compile time.
See the problem?
Our application's compiled code is coupled to the configuration of the system where it was compiled.

What if we want to generate the build artifact locally and run it elsewhere?
What if there's an emergency and the value of `EXAMPLE_APP_HOSTNAME` has been updated?
With this configuration our application needs to be recompiled for changes to take effect.

Let's illustrate the concept using colors to differentiate changes:

![elixir-config-recompile](https://user-images.githubusercontent.com/73386/41503026-d8a66ef4-7185-11e8-95fa-37598f6a56ff.png)

Here we see that our runtime values are different, which required us to recompile our code.
This results in a new build artifact and updated configuration for Runtime B.
We've managed to couple the runtime configuration and code together.
To see changes in our environment reflected in our code recompilation is unavoidable.
For those using releases this combination of configuration types often times requires additional libraries to fill the gaps.

At its root, the problem is the conflation of two separate concepts: build-time and runtime configuration.

### A new approach

Now let's look at another approach to configuration that enables changes to the runtime, without requiring our code to be recompiled:

```elixir
defmodule ExampleApp.Repo do
  use Ecto.Repo, otp_app: :data

  def init(_, opts) do
    {:ok, build_opts(opts)}
  end

  defp build_opts(opts) do
    system_opts = [
      database: System.get_env("EXAMPLE_APP_DATABASE"),
      hostname: System.get_env("EXAMPLE_APP_HOSTNAME"),
      password: System.get_env("EXAMPLE_APP_PASSWORD"),
      username: System.get_env("EXAMPLE_APP_USERNAME")
    ]

    Keyword.merge(opts, system_opts)
  end
end
```

Here `Repo.init/2`, called on start, is used to update our configuration with values from the current system environment without the need to recompile anything.

Now we could generate our build artifacts locally and run them elsewhere.
How would the aforementioned scenario with `EXAMPLE_APP_HOSTNAME` changes play out?
An application restart would pull the latest value, no compilation necessary.

Let's update our illustration from before to reflect this new approach:

![elixir-config](https://user-images.githubusercontent.com/73386/41503027-d8b8ecc8-7185-11e8-8284-73d417fea6dc.png)

Our runtime environments have changed but our application's configuration and build artifacts have not, nor should they need to.

We've managed to decouple our code from our runtime configuration with the added bonus of a configuration that is explicit and lives alongside the code.

### Bringing it together

In our last example we see the benefit to separating our configuration into two distinct parts.
An easy way to avoid the confusion and pitfalls of configuration is to remember this simple rule: `System.get_env/1` should never be used to populate our application's configuration, the values defined in `config.exs`.

Worried about what that means for local development and testing?
There's no need to fret!
We can marry these two configuration types to keep things simple and easy for local development.

Let's update our `Repo.init/2` function to reject any values that resolve to `nil` at run time, failing back to the application configuration that's been provided via `opts` (the values set in `config.exs`, `dev.exs`, and `test.exs`).

```elixir
defmodule ExampleApp.Repo do
  def init(_, opts) do
    {:ok, build_opts(opts)}
  end

  defp build_opts(opts) do
    system_opts = [
      database: System.get_env("EXAMPLE_APP_DATABASE"),
      hostname: System.get_env("EXAMPLE_APP_HOSTNAME"),
      password: System.get_env("EXAMPLE_APP_PASSWORD"),
      username: System.get_env("EXAMPLE_APP_USERNAME")
    ]

    system_opts
    |> remove_empty_opts()
    |> merge_opts(opts)
  end

  defp merge_opts(system_opts, opts) do
    Keyword.merge(opts, system_opts)
  end

  defp remove_empty_opts(system_opts) do
    Enum.reject(system_opts, fn {_k, value} -> is_nil(value) end)
  end
end
```

When our application starts it will attempt to retrieve those system variables, removing the `nil` values, and finally merging the options defined by our application configuration with the runtime configuration, giving precedence to the runtime options.

Now we can use the `dev.exs` and `test.exs` files we're so accustomed to while also ensuring our final build artifact will be correctly set up, thus making configuration of deployments a breeze.

What do you think of this approach?
We'd love to hear your thoughts!

In our next configuration post we'll look at how to design our libraries in a way to remove the need for `Application.get_env/2` while at the same time allowing multiple, independently configured, instances to live within the same application.
