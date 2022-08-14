%{
  version: "2.2.0",
  title: "Plug",
  excerpt: """
  If you're familiar with Ruby you can think of Plug as Rack with a splash of Sinatra.
  It provides a specification for web application components and adapters for web servers.
  While not part of Elixir core, Plug is an official Elixir project.

  In this lesson we'll build a simple HTTP server from scratch using the `PlugCowboy` Elixir library.
  Cowboy is a simple HTTP server for Erlang and Plug will provide us with a connection adapter for that web server.

After we set up our minimal web application, we'll learn about Plug's router and how to use multiple plugs in a single web app
  """
}
---

## Prerequisites

This tutorial assumes you have Elixir 1.5 or higher, and `mix` installed already.

We'll start by creating a new OTP project, with a supervision tree.

```shell
mix new example --sup
cd example
```

We need our Elixir app to include a supervision tree because we will use a Supervisor to start up and run our Cowboy2 server.

## Dependencies

Adding dependencies is a breeze with mix.
To use Plug as an adapter interface for the Cowboy2 webserver, we need to install the `PlugCowboy` package:

Add the following to your `mix.exs` file:

```elixir
def deps do
  [
    {:plug_cowboy, "~> 2.0"},
  ]
end
```

At the command line, run the following mix task to pull in these new dependencies:

```shell
mix deps.get
```

## The Plug Specification

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

The `init/1` function is used to initialize our Plug's options.
It is called by a supervision tree, which is explained in the next section.
For now, it'll be an empty List that is ignored.

The value returned from `init/1` will eventually be passed to `call/2` as its second argument.

The `call/2` function is called for every new request that comes in from the web server, Cowboy.
It receives a `%Plug.Conn{}` connection struct as its first argument and is expected to return a `%Plug.Conn{}` connection struct.

## Configuring the Project's Application Module

We need to tell our application to start up and supervise the Cowboy web server when the app starts up.

We'll do so with the [`Plug.Cowboy.child_spec/1`](https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html#child_spec/1) function.

This function expects three options:

* `:scheme` - HTTP or HTTPS as an atom (`:http`, `:https`)
* `:plug` - The plug module to be used as the interface for the web server.
You can specify a module name, like `MyPlug`, or a tuple of the module name and options `{MyPlug, plug_opts}`, where `plug_opts` gets passed to your plug modules `init/1` function.
* `:options` - The server options.
Should include the port number on which you want your server listening for requests.

Our `lib/example/application.ex` file should implement the child spec in its `start/2` function:

```elixir
defmodule Example.Application do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Example.HelloWorldPlug, options: [port: 8080]}
    ]
    opts = [strategy: :one_for_one, name: Example.Supervisor]

    Logger.info("Starting application...")

    Supervisor.start_link(children, opts)
  end
end
```

_Note_: We do not have to call `child_spec` here, this function will be called by the supervisor starting this process.
We simply pass a tuple with the module that we want the child spec built for and then the three options needed.

This starts up a Cowboy2 server under our app's supervision tree.
It starts Cowboy running under the HTTP scheme (you can also specify HTTPS), on the given port, `8080`, specifying the plug, `Example.HelloWorldPlug`, as the interface for any incoming web requests.

Now we're ready to run our app and send it some web requests! Notice that, because we generated an OTP app with the `--sup` flag, our `Example` application will start up automatically thanks to the `application` function.

In `mix.exs` you should see the following:

```elixir
def application do
  [
    extra_applications: [:logger],
    mod: {Example.Application, []}
  ]
end
```

We're ready to try out this minimalistic, plug-based web server.
On the command line, run:

```shell
mix run --no-halt
```

Once everything is finished compiling, and `[info]  Starting application...` appears, open a web
browser to <http://127.0.0.1:8080>.
It should display:

```
Hello World!
```

## Plug.Router

For most applications, like a web site or REST API, you'll want a router to route requests for different paths and HTTP verbs to different handlers.
`Plug` provides a router to do that.
As we are about to see, we don't need a framework like Sinatra in Elixir since we get that for free with Plug.

To start let's create a file at `lib/example/router.ex` and copy the following into it:

```elixir
defmodule Example.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Welcome")
  end

  match _ do
    send_resp(conn, 404, "Oops!")
  end
end
```

This is a bare minimum Router but the code should be pretty self-explanatory.
We've included some macros through `use Plug.Router` and then set up two of the built-in Plugs: `:match` and `:dispatch`.
There are two defined routes, one for handling GET requests to the root and the second for matching all other requests so we can return a 404 message.

Back in `lib/example/application.ex`, we need to add `Example.Router` into the web server supervisor tree.
Swap out the `Example.HelloWorldPlug` plug with the new router:

```elixir
def start(_type, _args) do
  children = [
    {Plug.Cowboy, scheme: :http, plug: Example.Router, options: [port: 8080]}
  ]
  opts = [strategy: :one_for_one, name: Example.Supervisor]

  Logger.info("Starting application...")

  Supervisor.start_link(children, opts)
end
```

Start the server again, stopping the previous one if it's running (press `Ctrl+C` twice).

Now in a web browser, go to <http://127.0.0.1:8080>.
It should output `Welcome`.
Then, go to <http://127.0.0.1:8080/waldo>, or any other path.
It should output `Oops!` with a 404 response.

## Adding Another Plug

It is common to use more than one plug in a given web application, each of which is dedicated to its own responsibility.
For example, we might have a plug that handles routing, a plug that validates incoming web requests, a plug that authenticates incoming requests, etc.
In this section, we'll define a plug to verify incoming requests parameters and we'll teach our application to use _both_ of our plugs--the router and the validation plug.

We want to create a Plug that verifies whether or not the request has some set of required parameters.
By implementing our validation in a Plug we can be assured that only valid requests will make it through to our application.
We will expect our Plug to be initialized with two options: `:paths` and `:fields`.
These will represent the paths we apply our logic to and which fields to require.

_Note_: Plugs are applied to all requests which is why we will handle filtering requests and applying our logic to only a subset of them.
To ignore a request we simply pass the connection through.

We'll start by looking at our finished Plug and then discuss how it works.
We'll create it at `lib/example/plug/verify_request.ex`:

```elixir
defmodule Example.Plug.VerifyRequest do
  defmodule IncompleteRequestError do
    @moduledoc """
    Error raised when a required field is missing.
    """

    defexception message: ""
  end

  def init(options), do: options

  def call(%Plug.Conn{request_path: path} = conn, opts) do
    if path in opts[:paths], do: verify_request!(conn.params, opts[:fields])
    conn
  end

  defp verify_request!(params, fields) do
    verified =
      params
      |> Map.keys()
      |> contains_fields?(fields)

    unless verified, do: raise(IncompleteRequestError)
  end

  defp contains_fields?(keys, fields), do: Enum.all?(fields, &(&1 in keys))
end
```

The first thing to note is we have defined a new exception `IncompleteRequestError` which we'll raise in the event of an invalid request.

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

  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug VerifyRequest, fields: ["content", "mimetype"], paths: ["/upload"]
  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Welcome")
  end

  get "/upload" do
    send_resp(conn, 201, "Uploaded")
  end

  match _ do
    send_resp(conn, 404, "Oops!")
  end
end
```

With this code, we are telling our application to send incoming requests through the `VerifyRequest` plug _before_ running through the code in the router.
Via the function call:

```elixir
plug VerifyRequest, fields: ["content", "mimetype"], paths: ["/upload"]
```

We automatically invoke `VerifyRequest.init(fields: ["content", "mimetype"], paths: ["/upload"])`.
This in turn passes the given options to the `VerifyRequest.call(conn, opts)` function.

Let's take a look at this plug in action! Go ahead and crash your local server (remember, that's done by pressing `ctrl + c` twice).
Then restart the server (`mix run --no-halt`).
Now go to <http://127.0.0.1:8080/upload> in your browser and you'll see that the page simply isn't working. You'll just see a default error page provided by your browser.

Now let's add our required params by going to <http://127.0.0.1:8080/upload?content=thing1&mimetype=thing2>. Now we should see our 'Uploaded' message.

It's not great that when we raise an error, we don't get _any_ page. We'll look at how to handle errors with plugs later.

## Making The HTTP Port Configurable

Back when we defined the `Example` module and application, the HTTP port was hard-coded in the module.
It's considered good practice to make the port configurable by putting it in a configuration file.

We'll set an application environment variable in `config/config.exs`

```elixir
use Mix.Config

config :example, cowboy_port: 8080
```

Next we need to update `lib/example/application.ex` read the port configuration value, and pass it to Cowboy.
We'll define a private function to wrap up that responsibility

```elixir
defmodule Example.Application do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Example.Router, options: [port: cowboy_port()]}
    ]
    opts = [strategy: :one_for_one, name: Example.Supervisor]

    Logger.info("Starting application...")

    Supervisor.start_link(children, opts)
  end

  defp cowboy_port, do: Application.get_env(:example, :cowboy_port, 8080)
end
```

The third argument of `Application.get_env` is the default value, for when the configuration directive is undefined.

Now to run our application we can use:

```shell
mix run --no-halt
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
      :get
      |> conn("/", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "returns uploaded" do
    conn =
      :get
      |> conn("/upload?content=#{@content}&mimetype=#{@mimetype}")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 201
  end

  test "returns 404" do
    conn =
      :get
      |> conn("/missing", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end
```

Run it with this:

```shell
mix test test/example/router_test.exs
```

## Plug.ErrorHandler

We noticed earlier that when we went to <http://127.0.0.1:8080/upload> without the expected parameters, we didn't get a friendly error page or a sensible HTTP status - just our browser's default error page with a `500 Internal Server Error`.

Let's fix that now by adding in [`Plug.ErrorHandler`](https://hexdocs.pm/plug/Plug.ErrorHandler.html).

First, open up `lib/example/router.ex` and then write the following to that file.

```elixir
defmodule Example.Router do
  use Plug.Router
  use Plug.ErrorHandler

  alias Example.Plug.VerifyRequest

  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug VerifyRequest, fields: ["content", "mimetype"], paths: ["/upload"]
  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Welcome")
  end

  get "/upload" do
    send_resp(conn, 201, "Uploaded")
  end

  match _ do
    send_resp(conn, 404, "Oops!")
  end

  defp handle_errors(conn, %{kind: kind, reason: reason, stack: stack}) do
    IO.inspect(kind, label: :kind)
    IO.inspect(reason, label: :reason)
    IO.inspect(stack, label: :stack)
    send_resp(conn, conn.status, "Something went wrong")
  end
end
```

You'll notice that at the top, we are now adding `use Plug.ErrorHandler`.

This plug catches any error, and then looks for a function `handle_errors/2` to call in order to handle it.

`handle_errors/2` just needs to accept the `conn` as the first argument and then a map with three items (`:kind`, `:reason`, and `:stack`) as the second.

You can see we've defined a very simple `handle_errors/2` function to see what's going on. Let's stop and restart our app again to see how this works!

Now, when you navigate to <http://127.0.0.1:8080/upload>, you'll see a friendly error message.

If you look in your terminal, you'll see something like the following:

```shell
kind: :error
reason: %Example.Plug.VerifyRequest.IncompleteRequestError{message: ""}
stack: [
  {Example.Plug.VerifyRequest, :verify_request!, 2,
   [file: 'lib/example/plug/verify_request.ex', line: 23]},
  {Example.Plug.VerifyRequest, :call, 2,
   [file: 'lib/example/plug/verify_request.ex', line: 13]},
  {Example.Router, :plug_builder_call, 2,
   [file: 'lib/example/router.ex', line: 1]},
  {Example.Router, :call, 2, [file: 'lib/plug/error_handler.ex', line: 64]},
  {Plug.Cowboy.Handler, :init, 2,
   [file: 'lib/plug/cowboy/handler.ex', line: 12]},
  {:cowboy_handler, :execute, 2,
   [
     file: '/path/to/project/example/deps/cowboy/src/cowboy_handler.erl',
     line: 41
   ]},
  {:cowboy_stream_h, :execute, 3,
   [
     file: '/path/to/project/example/deps/cowboy/src/cowboy_stream_h.erl',
     line: 293
   ]},
  {:cowboy_stream_h, :request_process, 3,
   [
     file: '/path/to/project/example/deps/cowboy/src/cowboy_stream_h.erl',
     line: 271
   ]}
]
```

At the moment, we're still sending a `500 Internal Server Error` back. We can customise the status code by adding a `:plug_status` field to our exception. Open up `lib/example/plug/verify_request.ex` and add the following:

```elixir
defmodule IncompleteRequestError do
  defexception message: "", plug_status: 400
end
```

Restart your server and refresh, and now you'll get back a `400 Bad Request`.

This plug makes it really easy to catch the useful information needed for developers to fix issues, while being able to also give our end user a nice page so it doesn't look like our app totally blew up!

## Available Plugs

There are a number of Plugs available out-of-the-box.
The complete list can be found in the Plug docs [here](https://github.com/elixir-lang/plug#available-plugs).
