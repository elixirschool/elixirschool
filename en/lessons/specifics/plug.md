---
version: 1.1.2
title: Plug
redirect_from:
  - /lessons/specifics/plug/
---

If you're familiar with Ruby you can think of Plug as Rack with a splash of Sinatra.
It provides a specification for web application components and adapters for web servers.
While not part of Elixir core, Plug is an official Elixir project.

We'll start by creating a minimal Plug-based web application.
After that, we'll learn about Plug's router and how to add a Plug to an existing web application.

{% include toc.html %}

## Prerequisites

This tutorial assumes you have Elixir 1.4 or higher, and `mix` installed already.

If you don't have a project started, create one like this:

```shell
$ mix new example
$ cd example
```

## Dependencies

Adding dependencies is a breeze with mix.
To install Plug we need to make two small changes to the `mix.exs` file.
The first thing to do is add both Plug and a web server (we'll be using Cowboy) to our file as dependencies:

```elixir
defp deps do
  [
    {:cowboy, "~> 1.1.2"},
    {:plug, "~> 1.3.4"}
  ]
end
```

At the command line, run the following mix task to pull in these new dependencies:

```shell
$ mix deps.get
```

## The Specification

In order to begin creating Plugs, we need to know, and adhere to, the Plug spec.
Thankfully for us, there are only two functions necessary: `init/1` and `call/2`.

Here's a simple Plug that returns "Hello World!":

```elixir
defmodule Example.HelloWorldPlug do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Hello World!\n")
  end
end
```

Save the file to `lib/example/hello_world_plug.ex`.

The `init/1` function is used to initialize our Plug's options. It is called by a supervision tree, which is explained in the next section. For now, it'll be an empty List that is ignored.

The value returned from `init/1` will eventually be passed to `call/2` as its second argument.

The `call/2` function is called for every new request that comes in from the web server, Cowboy.
It receives a `%Plug.Conn{}` connection struct as its first argument and is expected to return a `%Plug.Conn{}` connection struct.

## Configuring the Project's Application Module

Since we're starting a Plug application from scratch, we need to define the application module.
Update `lib/example.ex` to start and supervise Cowboy:

```elixir
defmodule Example do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Example.HelloWorldPlug, [], port: 8080)
    ]

    Logger.info("Started application")

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

This supervises Cowboy, and in turn, supervises our `HelloWorldPlug`.

In the `Plug.Adapters.Cowboy.child_spec/4` call, the third argument will be passed to `Example.HelloWorldPlug.init/1`.

We're not finished yet. Open `mix.exs` again, and find the `applications` function.
We need to add configuration for our own application, which should also cause it to start up automatically.

Let's update it to do that:

```elixir
def application do
  [
    extra_applications: [:logger],
    mod: {Example, []}
  ]
end
```

We're ready to try out this minimalistic, plug-based web server.
On the command line, run:

```shell
$ mix run --no-halt
```

Once everything is finished compiling, and `[info]  Started app` appears, open a web
browser to `127.0.0.1:8080`. It should display:

```
Hello World!
```

## Plug.Router

For most applications, like a web site or REST API, you'll want a router to route request for different paths and HTTP verbs to different handlers.
`Plug` provides a router to do that. As we are about to see, we don't need a framework like Sinatra in Elixir since we get that for free with Plug.

To start let's create a file at `lib/example/router.ex` and copy the following into it:

```elixir
defmodule Example.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Welcome"))
  match(_, do: send_resp(conn, 404, "Oops!"))
end
```

This is a bare minimum Router but the code should be pretty self-explanatory.
We've included some macros through `use Plug.Router` and then set up two of the built-in Plugs: `:match` and `:dispatch`.
There are two defined routes, one for handling GET requests to the root and the second for matching all other requests so we can return a 404 message.

Back in `lib/example.ex`, we need to add `Example.Router` into the web server supervisor tree.
Swap out the `Example.HelloWorldPlug` plug with the new router:

```elixir
def start(_type, _args) do
  children = [
    Plug.Adapters.Cowboy.child_spec(:http, Example.Router, [], port: 8080)
  ]

  Logger.info("Started application")
  Supervisor.start_link(children, strategy: :one_for_one)
end
```

Start the server again, stopping the previous one if it's running (press `Ctrl+C` twice).

Now in a web browser, go to `127.0.0.1:8080`.
It should output `Welcome`.
Then, go to `127.0.0.1:8080/waldo`, or any other path.
It should output `Oops!` with a 404 response.

## Adding Another Plug

It is common to create Plugs to intercept all requests or a subset of requests, to handle common request handling logic.

For this example we'll create a Plug to verify whether or not the request has some set of required parameters.
By implementing our validation in a Plug we can be assured that only valid requests will make it through to our application.
We will expect our Plug to be initialized with two options: `:paths` and `:fields`.
These will represent the paths we apply our logic to and which fields to require.

_Note_: Plugs are applied to all requests which is why we will handle filtering requests and applying our logic to only a subset of them.
To ignore a request we simply pass the connection through.

We'll start by looking at our finished Plug and then discuss how it works.
We'll create it at `lib/plug/verify_request.ex`:

```elixir
defmodule Example.Plug.VerifyRequest do
  defmodule IncompleteRequestError do
    @moduledoc """
    Error raised when a required field is missing.
    """

    defexception message: "", plug_status: 400
  end

  def init(options), do: options

  def call(%Plug.Conn{request_path: path} = conn, opts) do
    if path in opts[:paths], do: verify_request!(conn.body_params, opts[:fields])
    conn
  end

  defp verify_request!(body_params, fields) do
    verified =
      body_params
      |> Map.keys()
      |> contains_fields?(fields)

    unless verified, do: raise(IncompleteRequestError)
  end

  defp contains_fields?(keys, fields), do: Enum.all?(fields, &(&1 in keys))
end
```

The first thing to note is we have defined a new exception `IncompleteRequestError` and that one of its options is `:plug_status`.
When available this option is used by Plug to set the HTTP status code in the event of an exception.

The second portion of our Plug is the `call/2` function.
This is where we decide whether or not to apply our verification logic.
Only when the request's path is contained in our `:paths` option will we call `verify_request!/2`.

The last portion of our plug is the private function `verify_request!/2` which verifies whether the required `:fields` are all present.
In the event that some are missing, we raise `IncompleteRequestError`.

We've set up our Plug to verify that all requests to `/upload` include both `"content"` and `"mimetype"`.
Only then will the route code be executed.

Next, we need to tell the router about the new Plug.
Edit `lib/example/router.ex` and make the following changes:

```elixir
defmodule Example.Router do
  use Plug.Router

  alias Example.Plug.VerifyRequest

  plug(Plug.Parsers, parsers: [:urlencoded, :multipart])

  plug(
    VerifyRequest,
    fields: ["content", "mimetype"],
    paths: ["/upload"]
  )

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Welcome\n"))
  post("/upload", do: send_resp(conn, 201, "Uploaded\n"))
  match(_, do: send_resp(conn, 404, "Oops!\n"))
end
```

## Making The HTTP Port Configurable

Back when we defined the `Example` module and application, the HTTP port was hard-coded in the module.
It's considered good practice to make the port configurable by putting it in a configuration file.

Let's start by updating the `application` portion of `mix.exs` to tell Elixir about our application and set an application env variable.
With those changes in place our code should look something like this:

```elixir
def application do
  [
    extra_applications: [:logger],
    mod: {Example, []},
    env: [cowboy_port: 8080]
  ]
end
```

Our application is configured with the `mod: {Example, []}` line.
Notice that we're also starting up the `cowboy`, `logger` and `plug` applications.

Next we need to update `lib/example.ex` read the port configuration value, and pass it to Cowboy:

```elixir
defmodule Example do
  use Application

  def start(_type, _args) do
    port = Application.get_env(:example, :cowboy_port, 8080)

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Example.Router, [], port: port)
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

The third argument of `Application.get_env` is the default value, for when the configuration directive is undefined.

> (Optional) add `:cowboy_port` in `config/config.exs`

```elixir
use Mix.Config

config :example, cowboy_port: 8080
```

Now to run our application we can use:

```shell
$ mix run --no-halt
```

## Testing a Plug

Testing Plugs is pretty straightforward thanks to `Plug.Test`.
It includes a number of convenience functions to make testing easy.

Write the following test to `test/example/router_test.exs`:

```elixir
defmodule Example.RouterTest do
  use ExUnit.Case
  use Plug.Test

  alias Example.Router

  @content "<html><body>Hi!</body></html>"
  @mimetype "text/html"

  @opts Router.init([])

  test "returns welcome" do
    conn =
      conn(:get, "/", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "returns uploaded" do
    conn =
      conn(:post, "/upload", "content=#{@content}&mimetype=#{@mimetype}")
      |> put_req_header("content-type", "application/x-www-form-urlencoded")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 201
  end

  test "returns 404" do
    conn =
      conn(:get, "/missing", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end
```

Run it with this:

```shell
$ mix test test/example/router_test.exs
```

## Available Plugs

There are a number of Plugs available out-of-the-box.
The complete list can be found in the Plug docs [here](https://github.com/elixir-lang/plug#available-plugs).
