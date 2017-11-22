---
version: 1.0.1
title: Guardian (Basics)
redirect_from:
  - /lessons/libraries/guardian/
---

[Guardian](https://github.com/ueberauth/guardian) is a widely used authentication library based on tokens. By default it uses [JWT](https://jwt.io/) (JSON Web Tokens).

{% include toc.html %}

## Tokens

A token can provide a rich token for authentication. Where many authentication systems provide access to only a subject identifier for the resource, tokens provide this along with other information like:

* Who issued the token
* Who is the token for
* Which system should use the token
* What time was it issued
* What time does the token expire

In addition to these fields Guardian provides some other fields to facilitate additional functionality:

* What type is the token
* What permissions does the bearer have

These are just the basic fields in a Token. You're free to add any additional information that your application requires. Just remember to keep it short, as token has to fit in the HTTP header.

This richness means that you can pass tokens around in your system as a fully contained unit of credentials.

### Where to use them

Tokens can be used to authenticate any part of your application.

* Single page applications
* Controllers (via browser session)
* Controllers (via authorization headers - API)
* Phoenix Channels
* Service to Service requests
* Inter-process
* 3rd Party access (OAuth)
* Remember me functionality
* Other interfaces - raw TCP, UDP, CLI, etc

Tokens can be used everywhere in your application where you need to provide verifiable authentication.

### Do I have to use a database?

You do not need to track tokens via a database. You can simply rely on the issued and expiry timestamps for controlling access. Often you'll end up using a database to look up your user resource but the token itself does not require it.

For example, if you were going to use JWT to authenticate communication on a UDP socket you likely wouldn't use a database. Encode all the information you need directly into the token when you issue it. Once you verify it (check that it's signed correctly) you're good to go.

You _can_ however use a database to track JWT. If you do, you gain the ability to verify that the token is still valid - that is - it has not been revoked. Or you could use the records in the DB to force a log out of all tokens a for user. This is made simple in Guardian by using [GuardianDb](https://github.com/hassox/guardian_db). GuardianDb uses Guardians callbacks to hook into the lifecycle to perform validation checks, save and delete from the DB. We'll cover that later.

## Setup

There are many options for setting up Guardian. We'll cover them at some point but let's start with a very simple setup.

### Minimal Setup

To get started there are a handful of things that you'll need.

#### Configuration

`mix.exs`

```elixir
def application do
  [
    mod: {MyApp, []},
    applications: [:guardian, ...]
  ]
end

def deps do
  [
    {guardian: "~> 1.x"},
    ...
  ]
end
```

`config/config.ex`

```elixir
config :guardian, MyApp.Guardian,
  issuer: "MyAppId",
  secret_key: Mix.env, # in each environment config file you should overwrite this if it's external
```

This is the minimum set of information you need to provide Guardian with to operate. You shouldn't encode your secret key directly into your top-level config. Instead, each environment should have its own key. It's common to use the Mix environment for secrets in dev and test. Staging and production, however, must use strong secrets. (e.g. generated with `mix guardian.gen.secret`)

`lib/my_app/guardian.ex`

```elixir
defmodule MyApp.Guardian do
  use Guardian, otp_app: :my_app

  alias MyApp.Repo
  alias MyApp.User

  def subject_for_token(user = %User{}, _claims), do: { :ok, "User:#{user.id}" }
  def subject_for_token(_, _), do: { :error, "Unknown resource type" }

  def resource_from_claims(%{"sub" => "User:" <> id}), do: { :ok, Repo.get(User, id) }
  def resource_from_claims(_claims), do: { :error, "Unknown resource type" }
end
```

Your implementation module is responsible for finding the resource identified in the `sub` (subject) field. This could be a lookup from a db, an API, or even a simple string. Serializing your resource into the `sub` field and provides many callbacks to interact with a token throughout it's lifecycle which we'll get to later.

That's it for the minimum configuration. There's plenty more you can do if you need to but to get started that's enough.

#### Application Usage

Now that we have the configuration in place to use Guardian, we need to integrate it into the application. Since this is the minimum setup, let's first consider HTTP requests.

## HTTP requests

Guardian provides a number of Plugs to facilitate integration into HTTP requests. You can learn about Plug in a [separate lesson](../../specifics/plug/). Guardian doesn't require Phoenix, but using Phoenix in the following examples will be easiest to demonstrate.

The easiest way to integrate into HTTP is via the router. Since Guardian's HTTP integrations are all based on plugs, you can use these anywhere a plug could be used.

The general flow of Guardian plug is:

1. Find a token in the request (somewhere) and verify it: `Verify*` plugs
2. Optionally load the resource identified in the token: `LoadResource` plug
3. Ensure that there is a valid token for the request and refuse access if not. `EnsureAuthenticated` plug

To meet all the needs of application developers, Guardian implements these phases separately. To find the token use the `Verify*` plugs.

Guardian packages all of these up into a `Pipeline` to help you keep the logic together and test them independently.
Let's create some pipelines.

```elixir
defmodule MyApp.Guardian.StandardPipeline do
  use Guardian.Plug.Pipeline, otp_app: :my_app,
                              module: MyApp.Guardian,
                              error_handler: MyApp.Guardian.ErrorHandler

  plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource, ensure: true
end
```

This pipeline will

* look for a token first in the session, if found it will verify it before moving on
* If one is not found in the session it will look in the header and verify it if found. (In the Authorization header with value of "Bearer JWT")
* `EnsureAuthenticated` will make sure that a token was found _somewhere_
* `LoadResource` will use the information in the token to fetch the resource. The `allow_blank: true` option will not cause a failure if a resource was not loaded.

At the end of this pipeline, you'll have a `token`, `claims` and `resource` loaded onto your connection.

We can add another pipeline that will try to authenticate but will not cause the pipeline to halt.

```elixir
defmodule MyApp.Guardian.MaybePipeline do
  use Guardian.Plug.Pipeline, otp_app: :my_app,
                              module: MyApp.Guardian,
                              error_handler: MyApp.Guardian.ErrorHandler

  plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  plug Guardian.Plug.LoadResource, ensure: false
end
```

Wiring it into Phoenix at this point is simple.

```elixir
pipeline :maybe_browser_auth do
  plug MyApp.Guardian.MaybePipeline
end

pipeline :ensure_authed_access do
  plug MyApp.Guardian.StandardAuthentication
end
```

These pipelines can be used to compose different authentication requirements. The first pipeline tries to find a token first in the session and then falls back to a header. If it finds one, it will load the resource for you.

The second pipeline requires that there is a valid, verified token present and that it is of type "access". To use these, add them to your scope.

```elixir
scope "/", MyApp do
  pipe_through([:browser, :maybe_browser_auth])

  get("/login", LoginController, :new)
  post("/login", LoginController, :create)
  delete("/login", LoginController, :delete)
end

scope "/", MyApp do
  pipe_through [:browser, :ensure_authed_access]

  resource("/protected/things", ProtectedController)
end
```

The login routes above will have the authenticated user if there is one. The second scope ensures that there is a valid token passed for all actions.
You don't _have_ to put them in pipelines, you could put them in your controllers for super flexible customization but we're doing a minimal setup.

If you want to put them in your controllers there is one thing that you'll need to do to tell Guardian what your Implementation module is.

```elixir
plug Guardian.Plug.Pipeline, module: MyApp.Guardian, error_handler: MyApp.Guardian.ErrorHandler
```

You can put this at the top of your endpoint. All of the Guardian plugs will then know which implementation of a token you want to use and work as expected. This gives a lot of flexibility but is also more complicated.

We're missing one piece so far. The error handler we added on the pipeline plug. This is a very simple module that responds to

* `auth_error(conn, {type, reason}, options)`

Any time there is an error in one of Guardians plugs, this will be called to handle it. You can even specify your error handler as a Phoenix controller to handle specific cases for given endpoints!

```elixir
defmodule MyApp.MyController do
  use MyApp.Web, :controller
  use Guardian.Plug.Pipeline, error_handler: __MODULE__

  # ...

  def auth_error(conn, {type, reason}, _opts), do: handle_error(conn, type, reason)
end
```

#### In the controller

Inside the controller you access the current user by using guardians plug functions.

```elixir
defmodule MyApp.MyController do
  use MyApp.Web, :controller

  def some_action(conn, params) do
    with {:ok, user} <- MyApp.Guardian.Plug.current_resource(conn) do
      # do stuff
    end
  end
end
```

#### Login/Logout

Logging in and out of a browser session is very simple. In your login controller:

```elixir
def create(conn, params) do
  case find_the_user_and_verify_them_from_params(params) do # this function is not provided by Guardian
    {:ok, user} ->
      # Use access tokens. Other tokens can be used, like :refresh etc
      conn
      |> Guardian.Plug.sign_in(user) # Use access tokens. Other tokens can be used, like :refresh etc
      |> respond_somehow()

    {:error, reason} ->
      nil
      # handle not verifying the user's credentials
  end
end

def delete(conn, params) do
  conn
  |> Guardian.Plug.sign_out()
  |> respond_somehow()
end
```

The `sign_in` function is ok to use with or without sessions. If there is a session it will store the token in the session but if not it will just create the token and set it on the connection so you can then provide it to your client.
