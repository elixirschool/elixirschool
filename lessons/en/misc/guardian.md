%{
  version: "1.0.4",
  title: "Guardian (Basics)",
  excerpt: """
  [Guardian](https://github.com/ueberauth/guardian) is a widely used authentication library based on [JWT](https://jwt.io/) (JSON Web Tokens).
  """
}
---

## JWTs

A JWT can provide a rich token for authentication.
Where many authentication systems provide access to only a subject identifier for the resource, JWTs provide this along with other information like:

* Who issued the token
* Who is the token for
* Which system should use the token
* What time was it issued
* What time does the token expire

In addition to these fields Guardian provides some other fields to facilitate additional functionality:

* What type is the token
* What permissions does the bearer have

These are just the basic fields in a JWT.
You're free to add any additional information that your application requires.
Just remember to keep it short, as JWT has to fit in the HTTP header.

This richness means that you can pass JWTs around in your system as a fully contained unit of credentials.

### Where to use them

JWT tokens can be used to authenticate any part of your application.

* Single page applications
* Controllers (via browser session)
* Controllers (via authorization headers - API)
* Phoenix Channels
* Service to Service requests
* Inter-process
* 3rd Party access (OAuth)
* Remember me functionality
* Other interfaces - raw TCP, UDP, CLI, etc

JWT tokens can be used everywhere in your application where you need to provide verifiable authentication.

### Do I have to use a database?

You do not need to track JWT via a database.
You can simply rely on the issued and expiry timestamps for controlling access.
Often you'll end up using a database to look up your user resource but the JWT itself does not require it.

For example, if you were going to use JWT to authenticate communication on a UDP socket you likely wouldn't use a database.
Encode all the information you need directly into the token when you issue it.
Once you verify it (check that it's signed correctly) you're good to go.

You _can_ however use a database to track JWT.
If you do, you gain the ability to verify that the token is still valid - that is - it has not been revoked.
Or you could use the records in the DB to force a log out of all tokens a for user.
This is made simple in Guardian by using [GuardianDb](https://github.com/hassox/guardian_db).
GuardianDb uses Guardians 'Hooks' to perform validation checks, save and delete from the DB.
We'll cover that later.

## Setup

There are many options for setting up Guardian. We'll cover them at some point but let's start with a simple setup.

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
    {:guardian, "~> x.x"},
    ...
  ]
end
```

`config/config.exs`

```elixir
# in each environment config file you should overwrite this if it's external
config :guardian, Guardian,
  issuer: "MyAppId",
  secret_key: Mix.env(),
  serializer: MyApp.GuardianSerializer
```

This is the minimum set of information you need to provide Guardian with to operate.
You shouldn't encode your secret key directly into your top-level config.
Instead, each environment should have its own key.
It's common to use the Mix environment for secrets in dev and test.
Staging and production, however, must use strong secrets.
(e.g.
generated with `mix phoenix.gen.secret`)

`lib/my_app/guardian_serializer.ex`

```elixir
defmodule MyApp.GuardianSerializer do
  @behaviour Guardian.Serializer

  alias MyApp.Repo
  alias MyApp.User

  def for_token(user = %User{}), do: {:ok, "User:#{user.id}"}
  def for_token(_), do: {:error, "Unknown resource type"}

  def from_token("User:" <> id), do: {:ok, Repo.get(User, id)}
  def from_token(_), do: {:error, "Unknown resource type"}
end
```

Your serializer is responsible for finding the resource identified in the `sub` (subject) field.
This could be a lookup from a db, an API, or even a simple string.
It's also responsible for serializing a resource into the `sub` field.

That's it for the minimum configuration.
There's plenty more you can do if you need to but to get started that's enough.

#### Application Usage

Now that we have the configuration in place to use Guardian, we need to integrate it into the application.
Since this is the minimum setup, let's first consider HTTP requests.

## HTTP requests

Guardian provides a number of Plugs to facilitate integration into HTTP requests.
You can learn about Plug in a [separate lesson](/en/lessons/misc/plug).
Guardian doesn't require Phoenix, but using Phoenix in the following examples will be easiest to demonstrate.

The easiest way to integrate into HTTP is via the router.
Since Guardian's HTTP integrations are all based on plugs, you can use these anywhere a plug could be used.

The general flow of Guardian plug is:

1. Find a token in the request (somewhere) and verify it: `Verify*` plugs
2. Optionally load the resource identified in the token: `LoadResource` plug
3. Ensure that there is a valid token for the request and refuse access if not: `EnsureAuthenticated` plug

To meet all the needs of application developers, Guardian implements these phases separately.
To find the token use the `Verify*` plugs.

Let's create some pipelines.

```elixir
pipeline :maybe_browser_auth do
  plug(Guardian.Plug.VerifySession)
  plug(Guardian.Plug.VerifyHeader, realm: "Bearer")
  plug(Guardian.Plug.LoadResource)
end

pipeline :ensure_authed_access do
  plug(Guardian.Plug.EnsureAuthenticated, %{"typ" => "access", handler: MyApp.HttpErrorHandler})
end
```

These pipelines can be used to compose different authentication requirements.
The first pipeline tries to find a token first in the session and then falls back to a header.
If it finds one, it will load the resource for you.

The second pipeline requires that there is a valid, verified token present and that it is of type "access".
To use these, add them to your scope.

```elixir
scope "/", MyApp do
  pipe_through([:browser, :maybe_browser_auth])

  get("/login", LoginController, :new)
  post("/login", LoginController, :create)
  delete("/login", LoginController, :delete)
end

scope "/", MyApp do
  pipe_through([:browser, :maybe_browser_auth, :ensure_authed_access])

  resource("/protected/things", ProtectedController)
end
```

The login routes above will have the authenticated user if there is one.
The second scope ensures that there is a valid token passed for all actions.
You don't _have_ to put them in pipelines, you could put them in your controllers for super flexible customization but we're doing a minimal setup.

We're missing one piece so far.
The error handler we added on the `EnsureAuthenticated` plug.
This is a very simple module that responds to

* `unauthenticated/2`
* `unauthorized/2`

Both these functions receive a Plug.Conn struct and a params map and should handle their respective errors.
You can even use a Phoenix controller!

#### In the controller

Inside the controller, there are a couple of options for how to access the currently logged in user.
Let's start with the simplest.

```elixir
defmodule MyApp.MyController do
  use MyApp.Web, :controller
  use Guardian.Phoenix.Controller

  def some_action(conn, params, user, claims) do
    # do stuff
  end
end
```

By using the `Guardian.Phoenix.Controller` module, your actions will receive two additional arguments that you can pattern match on.
Remember, if you didn't use `EnsureAuthenticated` you may have a nil user and claims.

The other - more flexible/verbose version - is to use plug helpers.

```elixir
defmodule MyApp.MyController do
  use MyApp.Web, :controller

  def some_action(conn, params) do
    if Guardian.Plug.authenticated?(conn) do
      user = Guardian.Plug.current_resource(conn)
    else
      # No user
    end
  end
end
```

#### Login/Logout

Logging in and out of a browser session is very simple.
In your login controller:

```elixir
def create(conn, params) do
  case find_the_user_and_verify_them_from_params(params) do
    {:ok, user} ->
      # Use access tokens.
      # Other tokens can be used, like :refresh etc
      conn
      |> Guardian.Plug.sign_in(user, :access)
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

When using API login, it's slightly different because there's no session and you need to provide the raw token back to the client.
For API login you'll likely use the `Authorization` header to provide the token to your application.
This method is useful when you do not intend on using a session.

```elixir
def create(conn, params) do
  case find_the_user_and_verify_them_from_params(params) do
    {:ok, user} ->
      {:ok, jwt, _claims} = Guardian.encode_and_sign(user, :access)
      conn |> respond_somehow(%{token: jwt})

    {:error, reason} ->
      # handle not verifying the user's credentials
  end
end

def delete(conn, params) do
  jwt = Guardian.Plug.current_token(conn)
  Guardian.revoke!(jwt)
  respond_somehow(conn)
end
```

The browser session login calls `encode_and_sign` under the hood so you can use them the same way.
