---
author: Sophie DeBenedetto
author_link: https://github.com/sophiedebenedetto
categories: til
tags: ['phoenix']
date: 2019-03-19
layout: post
title:  Walk-Through of Phoenix LiveView
excerpt: >
  Learn how to use Phoenix LiveView for real-time features without complicated JS frameworks.
---
It's here! Phoenix LiveView leverages server-rendered HTML and Phoenix's native WebSocket tooling so you can build fancy real-time features without all that complicated JavaScript. If you're sick to death of writing JS (I had a bad day with Redux, don't ask), then this is the library for you!

Phoenix LiveView is brand brand new so I thought I'd provide a short write-up of a super simple demo I built for anyone looking to get up and running. Keep in mind that the library is still a release candidate and as such, is subject to change.

## What is LiveView?

Chris McCord said it best in his [announcement](https://dockyard.com/blog/2018/12/12/phoenix-liveview-interactive-real-time-apps-no-need-to-write-javascript) back in December:

> Phoenix LiveView is an exciting new library which enables rich, real-time user experiences with server-rendered HTML. LiveView powered applications are stateful on the server with bidirectional communication via WebSockets, offering a vastly simplified programming model compared to JavaScript alternatives.

## Kill Your JavaScript

If you've waded through an overly complex SPA that Reduxes all the things (for example), you've felt the maintenance and iteration costs that often accompany all that fancy JavaScript.

Phoenix LiveView feels like a perfect fit for the 90% of the time that you do want some live updates but don't actually need the wrecking ball of many modern JS frameworks.

Let's get LiveView up and running to support a feature that pushes out live updates as our server enacts a step-by-step process of creating a GitHub repo.

Here's the functionality we're building:

<div class="responsive-embed">
  <iframe width="560" height="315" src="https://www.youtube.com/embed/8M-Hjj7IBu8" allowfullscreen></iframe>
</div>
<br />

## Getting Started

The following steps are detailed in Phoenix LiveView [Readme](https://github.com/phoenixframework/phoenix_live_view).

* Install the dependency in your `mix.exs` file:

```elixir
def deps do
  [
    {:phoenix_live_view, "~> 0.2.0"}
  ]
end
```

* Update your app's endpoint configuration with a signing salt for your live view connection to use:

```elixir
# Configures the endpoint
config :my_app, MyApp.Endpoint,
  ...
  live_view: [
    signing_salt: "YOUR_SECRET"
  ]
```
*Note: You can generate a secret by running `mix phx.gen.secret` from the command line.*

* Update your configuration to enable writing LiveView templates with the  `.leex` extension.

```elixir
config :phoenix,
  template_engines: [leex: Phoenix.LiveView.Engine]
```

* Add the live view flash plug to your browser pipeline, after `:fetch_flash`

```elixir
pipeline :browser do
  ...
  plug :fetch_flash
  plug Phoenix.LiveView.Flash
end
```

* Import the following in your `lib/app_web.ex` file:

```elixir
def view do
  quote do
    ...
    import Phoenix.LiveView, only: [live_render: 2, live_render: 3]
  end
end

def router do
  quote do
    ...
    import Phoenix.LiveView.Router
  end
end
```

* Expose a socket for LiveView to use in your endpoint module:

```elixir

defmodule MyAppWeb.Endpoint do
  use Phoenix.Endpoint

  socket "/live", Phoenix.LiveView.Socket

  # ...
end
```

* Add LiveView to your NPM dependencies:

```elixir
# assets/package.json
{
  "dependencies": {
    ...
    "phoenix_live_view": "file:../deps/phoenix_live_view"
  }
}
```
You'll need to run `npm install` after this step.

* Use the LiveView JavaScript library to connect to the LiveView socket in `app.js`

```javascript
import LiveSocket from "phoenix_live_view"

let liveSocket = new LiveSocket("/live")
liveSocket.connect()
```

* Your live views should be saved in the `lib/my_app_web/live/` directory. For live page reload support, add the following pattern to your `config/dev.exs`:

```elixir
config :demo, MyApp.Endpoint,
  live_reload: [
    patterns: [
      ...,
      ~r{lib/my_app_web/live/.*(ex)$}
    ]
  ]
```

Now we're ready to build and render a live view!

### Rendering a Live View from the Controller

You can [serve live views directly from your router](https://github.com/phoenixframework/phoenix_live_view/blob/master/lib/phoenix_live_view.ex#L86). However, in this example we'll teach our controller to render a live view. Let's take a look at our controller:

```elixir
defmodule MyApp.PageController do
  use MyApp, :controller
  alias Phoenix.LiveView

  def index(conn, _) do
    LiveView.Controller.live_render(conn, MyAppWeb.GithubDeployView, session: %{})
  end
end
```

We're calling on the `live_render/3` function which takes in an argument of the `conn`, the live view we want to render, and any session info we want to send down into the live view.

Now we're ready to define our very own live view.

### Defining the Live View

Our first live view will live in `my_app_web/live/github_deploy_view.ex`. This view is responsible for handling an interaction whereby a user "deploys" some content to GitHub. This process involves creating a GitHub organization, creating the repo and pushing up some contents to that repo. We won't care about the implementation details of this process for the purpose of this example.

Our live view will use `Phoenix.LiveView` and must implement two functions: `render/1` and `mount/2`.

```elixir
defmodule MyAppWeb.GithubDeployView do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <div class="">
      <div>
        <%= @deploy_step %>
      </div>
    </div>
    """
  end

  def mount(_session, socket) do
    {:ok, assign(socket, deploy_step: "Ready!")}
  end
end
```

Now that we have the basic pieces in place, let's break down the live view process.

### How It Works

The live view connection process looks something like this:

![]({% asset live_view.png @path %})

When our app receives an HTTP request for the index route, it will respond by rendering the static HTML defined in our live view's `render/1` function. It will do so by first invoking our view's `mount/2` function, only then rendering the HTML populated with whatever default values `mount/2` assigned to the socket.

The rendered HTML will include the signed session info. The session is signed using the signing salt we provided to our live view configuration in `config.exs`. That signed session will be sent back to the server when the client opens the live view socket connection. If you inspect the page rendering your live view in the browser, you'll see that signed session:

```html
<div
  id="phx-20gvOvqvFMA="
  data-phx-view="MyApp.GithubDeployView"
  data-phx-session="SFMyNTY.g3QAAAACZAAEZGF0YW0AAACQZzNRQUFBQUVaQUFDYVdS">
  ...
</div>
```

Once that static HTML is rendered, the client will send the live socket connect request thanks to this snippet:

```javascript
import LiveSocket from "phoenix_live_view"

let liveSocket = new LiveSocket("/live")
liveSocket.connect()
```

This initiates a stateful connection that will cause the view to be re-rendered anytime the socket updates. Since the page first renders as static HTML, we can rest assured that our page will always render for our user, even if JavaScript is disabled in the browser.

Now that we understand how the live view is first rendered and how the live view socket connection is established, let's render some live updates.

### Rendering Live Updates

LiveView is listening to updates to our socket and will re-render _only the portions of the page that need updating_. Taking a closer look at our `render/1` function, we see that it renders the values of the keys assigned to our socket.

Where `mount/2` assigned the values `:deploy_step`, our `render/1` function renders them like this:

```elixir
def render(assigns) do
  ~L"""
  <div class="">
    <div>
      <%= @deploy_step %>
    </div>
  </div>
  """
end
```

*Note: The [`~L`](https://github.com/phoenixframework/phoenix_live_view/blob/master/lib/phoenix_live_view.ex#L159) sigil represents Live EEx. This is the built-in LiveView template. Unlike `.eex` templates, LEEx templates are capable of tracking and rendering only necessary changes. So, if the value of `@deploy_step` changes, our template will re-render only that portion of the page.*

Let's give our user a way to kick off the "deploy to GitHub" process and see the page update as each deploy step is enacted.

LiveView supports DOM element bindings to give us the ability to respond to client-side events. We'll create a "deploy to GitHub" button and we'll listen for the click of that button with the phx-click event binding.

```elixir
def render(assigns) do
  ~L"""
  <div class="">
    <div>
      <div>
        <button phx-click="github_deploy">Deploy to GitHub</button>
      </div>
      Status: <%= @deploy_step %>
    </div>
  </div>
  """
end
```

The `phx-click` binding will send our click event to the server to be handled by `GithubDeployView`. Events are handled in our live views by the `handle_event/3` function. This function will take in an argument of the event name, a value and the socket.

There are a [number of ways to populate the `value` argument](https://github.com/phoenixframework/phoenix_live_view/blob/master/lib/phoenix_live_view.ex#L228), but we won't use that data point in this example.

Let's build out our `handle_event/3` function for the `"github_deploy"` event:

```elixir
def handle_event("github_deploy", _value, socket) do
  # do the deploy process
  {:noreply, assign(socket, deploy_step: "Starting deploy...")}
end
```

Our function is responsible for two things. First, it will kick off the deploy process (coming soon). Then, it will update the value of the `:deploy_step` key in our socket. This will cause our template to re-render the portion of the page with `<%= @deploy_step %>`, so the user will see `Status: Ready!` change to `Status: Starting deploy...`.

Next up, we need the "deploying to GitHub" process to be capable of updating the socket's `:deploy_step` at each turn. We'll have our view's `handle_event/3` function send a message to itself to enact each successive step in the process.

```elixir
def handle_event("github_deploy", _value, socket) do
  :ok = MyApp.start_deploy()
  send(self(), :create_org)
  {:noreply, assign(socket, deploy_step: "Starting deploy...")}
end

def handle_info(:create_org, socket) do
  {:ok, org} = MyApp.create_org()
  send(self(), {:create_repo, org})
  {:noreply, assign(socket, deploy_step: "Creating GitHub org...")}
end

def handle_info({:create_repo, org}, socket) do
  {:ok, repo} = MyApp.create_repo(org)
  send(self(), {:push_contents, repo})
  {:noreply, assign(socket, deploy_step: "Creating GitHub repo...")}
end

def handle_info({:push_contents, repo}, socket) do
  :ok = MyApp.push_contents(repo)
  send(self(), :done)
  {:noreply, assign(socket, deploy_step: "Pushing to repo...")}
end

def handle_info(:done, socket) do
  {:noreply, assign(socket, deploy_step: "Done!")}
end
```

*This code is dummied-up––we're not worried about the implementation details of deploying our GitHub repo, but we can imagine how we might add error handling and other responsibilities into this code flow.*

Our `handle_event/3` function kicks off the deploy process by sending the `:create_org` message to the view itself. Our view responds to this message by calling on code that enacts that step and by updating the socket. This will cause our template to re-render once again, so the user will see `Status: Starting deploy...` change to `Status: Creating GitHub org...`. In this way, the view enacts each step in the GitHub deploy process, updating the socket and causing the template to re-render each time.

Now that we have our live updates working, let's refactor the HTML code out of our `render/1` function and into its own template file.

### Rendering a Template File

We'll define our template in `lib/my_app_web/templates/page/github_deploy.html.leex`:

```html
<div>
  <div class>
    <button phx-click="github_deploy">Deploy to GitHub</button>
    <div class="github-deploy">
      Status: <%= @deploy_step %>
    </div>
  </div>
</div>
```

Next, we'll have our live view's `render/1` function simply tell our `PageView` to render this template:


```elixir
defmodule MyApp.GithubDeployView do
  use Phoenix.LiveView

  def render(assigns) do
    MyApp.PageView.render("github_deploy.html", assigns)
  end
  ...
end
```

Now our code is a bit more organized.

## Conclusion

From even this limited example, we can see what a powerful offering this is. We were able to implement this real-time feature with only server-side code, and not that many lines of server-side code at that! I really enjoyed playing around with Phoenix LiveView and I'm excited to see what other devs build with it. Happy coding!
