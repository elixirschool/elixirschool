%{
  author: "Sean Callan",
  author_link: "",
  date: ~D[2019-01-25],
  tags: ["plug", "software design"],
  title: "Building web apps with Plug.Router",
  excerpt: """
  When it comes to building a web application with Elixir many people will immediately reach for Phoenix.
  However, did you know `Plug.Router` is just as viable an option?
  Sometimes, it can be even faster.
  """
}

---

## The project

For this project we'll build a simple single page portfolio site.
We can expect our site to load and display our portfolio from a file, database, or somewhere else dynamically. As well as allowing users to submit contact information via a web form.

__Please note__: To keep the application and tutorial concise, we will forego database backing and stub this out in favor of concentrating on the web portions.

Want to skip the reading and just look at a code?
Head over to [elixirschool/router_example](https://github.com/elixirschool/router_example).

## Getting started

To get started we need to do a couple of things:

1. Generate a new project with `mix new --sup`
1. Add the `plug_cowboy` dependency to `mix.exs`
1. Put our router into the supervision tree of our application

Without further delay, let's get this show on the road and generate our new project:

```shell
$ mix new router_example --sup

* creating README.md
* creating .formatter.exs
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/router_example.ex
* creating lib/router_example/application.ex
* creating test
* creating test/test_helper.exs
* creating test/router_example_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd router_example
    mix test

Run "mix help" for more commands.
```

Let's head into our new directory and open `mix.exs` in the editor of your choice.
Here we'll make small a small change by adding the `plug_cowboy` dependency:

```elixir
defp deps do
  [
    {:plug_cowboy, "~> 2.0"}
  ]
end
```

With that change in place we can fetch our dependencies with `mix deps.get` and proceed.
Though we have not yet created our router, let's get the supervisor setup out of the way.
We'll need to open `lib/router_example/application.ex` next so we can update our supervisor's children.
The `plug_cowboy` package makes this step easy with the included `Plug.Cowboy.child_spec/3` function.
Let's update our application's `start/2` function:

```elixir
def start(_type, _args) do
  children = [
    Plug.Cowboy.child_spec(scheme: :http, plug: RouterExample.Router, options: [port: 4001])
  ]

  opts = [strategy: :one_for_one, name: RouterExample.Supervisor]
  Supervisor.start_link(children, opts)
end
```

Our setup is complete!
Before we can run our application we'll need to create our `RouterExample.Router` module which we'll do next.

## Stubs

As was mentioned in the introduction for the sake of keeping the tutorial short and focused, we'll be stubbing the functions that would otherwise retrieve data from our datastore and persist it there.
We won't waste too much time on this file we just need two functions: one to give us a collection of results (stubbing a database lookup) and a second to take our parameters and write them to the terminal (instead of persisting them to a store).

Let's create a new file `lib/router_example/stubs.ex` and copy the following code into it:

```elixir
defmodule RouterExample.Stubs do
  def portfolio_entries do
    for x <- 1..10, do: %{name: "Project #{x}", image: "https://picsum.photos/400/300/?random?t=#{x}"}
  end

  def submit_contact(params) do
    IO.inspect(params, label: "Submitted contact")
  end
end
```

_Note_: If you're unfamiliar with the `:label` option in `IO.inspect/2`, check out our other blog post [TIL IO.inspect labels](https://elixirschool.com/blog/til-io-inspect-labels/).

## The Router

One small line of code, `use Plug.Router`, unlocks great potential by bringing the power of `Plug.Router` into our application.
Need a refresher on `use/1`?
Head on over to Elixir School's [section on `use`](https://elixirschool.com/en/lessons/basics/modules/#use).

So what _is_ `Plug.Router` afterall?

Stated simply `Plug.Router` is a collection of macros that make it easy to match request paths and their type.
If you're familiar with with Ruby's [Sinatra](http://sinatrarb.com/), Python's [Flask](http://flask.pocoo.org/), Java's [Jersey](https://jersey.github.io/), or any of the other "micro frameworks" then this will look familiar.

Create a new file for our router and open it: `lib/router_example/router.ex`.
Let's copy the basic router code below into our new file and then look at the individual pieces:

```elixir
defmodule RouterExample.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/ping" do
    send_resp(conn, 200, "pong")
  end
end
```

The first thing we notice after the `use` is a series of plugs: `match` and `dispatch`.
These are included for us and match the incoming request to a function and invoke it respectively.

The next thing we see is our first route!
It's a simple health check but it's significant none-the-less, it shows us the format all of our routes will follow: HTTP verb, path, and block of code.
As one migth imagine there is more than `get/1`, we also have `post/1`, `patch/1`, `put/1`, `delete/1`, `option/1`, and `match/1`.

In the next few sections we'll explore some of these other macros but first let's look at how we can handle rendering EEx templates and JSON.

For more on `Plug.Router` check out the dedicated section in our [Plug lesson](https://elixirschool.com/en/lessons/specifics/plug/#plugrouter).

### Rendering templates

Elixir includes EEx, Embedded Elixir, which lets us parse strings and files and evaluate the embedded Elixir.
For our purposes we'll focus on `EEx.eval_file/2` and use it as the basis for our own `render/3` function.

For our `render/3` function we'll pass in our connection struct, a template without the ".eex" extension, and any variable bindings we may want to provide to the embedded Elixir.
We want a function invocation that will look something like this:

```elixir
render(conn, "index.html", portfolio: [])
```

Now that we know what we want it's time to build it!

The `EEx.eval_file/2` function takes our template's filepath along with variable bindings and returns the computed string, our response body.
With EEx doing all the heavy lifting our `render/3` function needs to do little more than build the complete filepath and send along the response with `send_resp/3`:

```elixir
@template_dir "lib/router_example/templates"

...

defp render(%{status: status} = conn, template, assigns \\ []) do
  body =
    @template_dir
    |> Path.join(template)
    |> String.replace_suffix(".html", ".html.eex")
    |> EEx.eval_file(assigns)

  send_resp(conn, (status || 200), body)
end
```

We've set it up for EEx to look for our templates in the directory `lib/router_example/templates` so let's create that directory.
Next we'll create two templates `index.html.eex` and `contact.html.eex`.

You can find the code for `index.html.eex` [here](https://raw.githubusercontent.com/elixirschool/router_example/master/lib/router_example/templates/index.html.eex) and `contact.html.eex` [here](https://raw.githubusercontent.com/elixirschool/router_example/master/lib/router_example/templates/contact.html.eex), we won't focus on HTML or CSS today.

### Sending and receiving JSON

Building JSON endpoints in Plug.Router is much less work than the template rendering we just covered.

The first thing we need is a library to parse and encode JSON, for our purpose we'll use `jason`:

```elixir
{:jason, "~> 1.1"}
```

Now would be a good time to run `mix deps.get` before we forget.
Once we've done that we can move on to updating our router to handle incoming JSON via the `Plug.Parsers` plug.
Let's open `lib/router_example/router.ex` and update our plugs to include `Plug.Parsers` with `Jason` as our decoder:

```elixir
plug Plug.Parsers, parsers: [:json],
                   pass: ["text/*"],
                   json_decoder: Jason
plug :match
plug :dispatch
```

That's _really_ all we need to do for JSON.

If we want to keep things simple, we can leverage `Jason.encode/1` or `Jason.encode!/1` along with `send_resp/3` and be done:

```elixir
{:ok, json} = Jason.encode(result)
send_resp(conn, 200, json)
```

Or if we want a little more polish we could make a `render_json/2`:

```elixir
defp render_json(%{status: status} = conn, data) do
  body = Jason.encode!(data)
  send_resp(conn, (status || 200), body)
end
```

For the remainder of the post we'll use the `render_json/2` approach.

_Note_: If you intend to use something like the [JSON:API specification](https://jsonapi.org), you may want an additional dependency like [jsonapi](https://github.com/jeregrine/jsonapi) to help.

### Defining routes

We now have our router code in place, code to render templates, and code to render JSON, all that's left is for us to define our routes!

We previously created two EEx templates, `index.html.eex` and `contact.html.eex`, so we'll create routes to handle those requests first.
From our healthcheck endpoint we know the format we expect but we can use our new `render/3` functions as well as our stubbed data.

If you looked a `index.html.eex` then you know our EEx expects a `portfolio` capture populated with a list of maps containing `:name` and `:image`, the format we conveniently defined in our stubbed module!
Let's bring all the pieces together inside `lib/router_example/router.ex`:

```elixir
get "/" do
  render(conn, "index.html", portfolio: Stubs.portfolio_entries())
end

get "/contact" do
  render(conn, "contact.html")
end
```

We're getting there but we're not _quite_ done.
We have to handle our contact form's AJAX requests.

In the interest of staying focused we won't get sidetrack with validation today, instead we'll make use of our `Stubs.submit_contact/1` function.
Let's create a new route with the `post/1` macro that uses the aforementioned function and sends a pleasant JSON message back using our `render_json/2` function:

```elixir
post "/contact" do
  Stubs.submit_contact(conn.params)
  render_json(conn, %{message: "Thank you! We will get back to you shortly."})
end
```

That's it, we're done, right?!
Well — we probably want to handle requests to routes we haven't defined yet.
Let's do that next and then we can call it done.

### Missing routes

Handling missing routes is a straight forward thanks to Elixir's powerful pattern matching.
With the `match/3` macro and `_` we can match on all requests.
By placing this at the bottom of our router we ensure if a request has not previously been matched it will be caught and handled.

For now we'll implement a simple message, similar to how we implemented our "/ping" endpoint with `send_resp/3`:

```elixir
defmodule RouterExample.Router do
  use Plug.Router

  ...

  match _ do
    send_resp(conn, 404, "Oh no! What you seek cannot be found.")
  end
end
```

Tada!
Our app is complete, time to wrap things up.

### Wrapping things up

We've come a long way in very small lines of code, let's look the entirety of our app:

```elixir
defmodule RouterExample.Router do
  use Plug.Router

  alias RouterExample.Stubs

  @template_dir "lib/router_example/templates"

  plug Plug.Parsers, parsers: [:urlencoded, :json],
                   pass: ["text/*"],
                   json_decoder: Jason
  plug :match
  plug :dispatch

  get "/ping" do
    send_resp(conn, 200, "pong")
  end

  get "/" do
    render(conn, "index.html", portfolio: Stubs.portfolio_entries())
  end

  get "/contact" do
    render(conn, "contact.html")
  end

  post "/contact" do
    Stubs.submit_contact(conn.params)
    render_json(conn, %{message: "Thank you! We will get back to you shortly."})
  end

  match _ do
    send_resp(conn, 404, "Oh no! What you seek cannot be found.")
  end

  defp render(%{status: status} = conn, template, assigns \\ []) do
    body =
      @template_dir
      |> Path.join(template)
      |> String.replace_suffix(".html", ".html.eex")
      |> EEx.eval_file(assigns)

    send_resp(conn, (status || 200), body)
  end

  defp render_json(%{status: status} = conn, data) do
    body = Jason.encode!(data)
    send_resp(conn, (status || 200), body)
  end
end
```

We're rendering EEx templates, receiving and sending JSON, and all the _entire_ app (`RouterExample.Router` + `RouterExample.Stubs`) is 58 lines of code!

All that's really left for us to do is run it and enjoy our new website.
To run our new app we'll use `mix run --no-halt`, the app can be found at [localhost:4001](localhost:4001).

There is no arguing this is a very basic implementation but it get's us started.
With these simple pieces we have what we need build to something significant.

We hope you've enjoyed!
In future posts we'll explore improvements like grouping routes together into module, supporting Webpack, other refactors.

The code for our application can be found at [elixirschool/router_example](https://github.com/elixirschool/router_example).
