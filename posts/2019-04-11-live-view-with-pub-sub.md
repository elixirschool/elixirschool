%{
  author: "Sophie DeBenedetto",
  author_link: "https://github.com/sophiedebenedetto",
  date: ~D[2019-04-11],
  tags: ["phoenix", "general"],
  title: "Building Real-Time Features with Phoenix Live View and PubSub",
  excerpt: """
  Integrate Phoenix PubSub with LiveView to build real-time features capable of broadcasting updates across a set of clients.
  """
}

---

In an [earlier post](https://elixirschool.com/blog/phoenix-live-view/), we used the brand new (still pre-release at time of writing) Phoenix LiveView library to build a real-time feature with very little backend code and even less JavaScript. LiveView allowed us to easily connect our client to the server via a socket and push updates down to our client. In an app that allows users to "deploy" a repo to GitHub, we achieved the following real-time functionality:

<div class="responsive-embed">
  <iframe width="560" height="315" src="https://www.youtube.com/embed/8M-Hjj7IBu8" allowfullscreen></iframe>
</div>
<br />

But what happens when we have a set of clients that _all_ need to see the _same_ real-time updates? Phoenix Channels might seem like the right fit, but wouldn't it be nice if we could get our existing LiveView to simply broadcast updates to a set of subscribing clients? We can use Phoenix's PubSub module to do exactly that!

In this post, we'll learn how to use PubSub to make real-time updates available to all of our LiveView clients, not just the person who clicked the "Deploy to GitHub" button. Our finished product will look like this:

<div class="responsive-embed">
  <iframe width="560" height="315" src="https://www.youtube.com/embed/QLwfYNgVuu0" allowfullscreen></iframe>
</div>
<br />

Let's get started!

## What is PubSub and Why Do We Need It?

PubSub ("publish/subscribe") describes a pattern in which we publish messages to a "topic", such that those messages can be consumed by any number of subscribers. In the context of our web app, a set of clients connected to our server become the subscribers of a given topic. One particular client (the one who clicks the "Deploy to GitHub" button) will publish, or broadcast, messages to that topic, to be picked up and operated on by the other subscribing clients.

[Phoenix's PubSub library](https://hexdocs.pm/phoenix/1.1.0/Phoenix.PubSub.html) will allow us to set up our own publish/subscribe flow. It's important to note that Phoenix's PubSub library takes advantage of Distributed Elixir––clients across distributed nodes of our app can subscribe to a shared topic and broadcast to that shared topic because PubSub can directly exchange notifications between servers when configured to use the `Phoenix.PubSub.PG2` adapter (more on that later).

First, we'll subscribe our LiveView processes to a shared topic. Then we'll use each live view's socket to push changes out to each subscriber when they receive a broadcast from that topic. In this way, we'll combine the real-time capability provided by LiveView, with the ability to pass messages across a distributed set of clients provided by PubSub.

## Configuring Phoenix PubSub

We'll configure our app's endpoint with the `Phoenix.PubSub.PG2` adapter. This way, we'll be able to subscribe clients across distributed nodes of our application, should we deploy it that way. The following configuration in our `config/config.exs` will ensure that the pubsub backend starts up and and exposes its functions via the endpoint module.

```elixir
config :my_app, MyAppWeb.Endpoint,
  pubsub: [name: MyApp.PubSub, adapter: Phoenix.PubSub.PG2]
  ...
```

Next up, we'll teach our clients to subscribe to a shared topic in our LiveView.

## Subscribing to a Topic

When should a client subscribe to a topic? We already have a LiveView that is responsible for rendering our view, receiving a click event and pushing out changes to the front-end. This LiveView should also subscribe to a shared topic and broadcast to that topic so that real-time updates can be shared across all instances of the LiveView.

Each LiveView process should subscribe to the topic when the LiveView mounts. We can do that with the `Phoenix.PubSub.subscribe/3` function:


```elixir
defmodule MyAppWeb.GithubDeployView do
  use Phoenix.LiveView

  @topic "deployments"

  def render(assigns) do
    MyAppWeb.PageView.render("index.html", assigns)
  end

  def mount(_session, socket) do
    MyAppWeb.Endpoint.subscribe(@topic)
    {:ok, assign(socket, text: "Ready!", status: "ready")}
  end
  ...
end
```

Now that our LiveView instances are subscribed to the topic, we're ready to start broadcasting.

## Broadcasting to the Subscribers

### A LiveView Refresher

When do we want to broadcast to our subscribing clients? Before we answer this question, let's take a look at our (slightly refactored) LiveView code. Recall that we are working on an app that allows a user to "deploy" a repo with some contents to GitHub. A user clicks a button which kicks off the several step deployment process (creating an org, creating a repo, pushing some contents).

So, when a user clicks the "Deploy to GitHub" button on our LiveView's template:

```elixir
<div class="">
  <div class="bar">
    <button phx-click="deploy">Deploy to GitHub</button>
    <div class="github-deploy">
      Status: <span class=<%= @status %>><%= @text %></span>
    </div>
  </div>
</div>
```

It will call `MyAppWeb.GithubDeployView.handle_event` with a first argument of our `phx-click`' event, `"deploy"`.

Our live view will then call on some code that enacts each step in the deployment process by looking up the next step in the `@deployment_steps` module attribute and passing the next message to the live view.

So when the `"deploy"` event gets fired by the user's button click, our `handle_event/3` function will respond by:

* Looking up the next step, `"create-org"`
* Looking up the text that we'd like to display, `"Creating org"`
* Sending the `"create-org"` message to itself
* Updating the socket's state to point the `step` key to `"create-org"` and the `text` key to `"Creating org"`. This will cause the live view's template to re-render with the new text.

Sending the `"create-org"` message to itself will cause the live view's `handle_info/2` function to be invoked. The live view will in turn look up the next step, pass that next message to itself and update the socket once again. All the way until we reach the `"done"` message.

```elixir
defmodule MyAppWeb.GithubDeployView do
  use Phoenix.LiveView
  @deployment_steps %{
    "deploy" => %{next_step: "create-org", text: "Creating org"},
    "create-org" => %{next_step: "create-repo", text: "Creating repo"},
    "create-repo" => %{next_step: "push-contents", text: "Pushing contents"},
    "push-contents" => %{next_step: "done", text: "Done!"}
  }
  @topic "deployments"

  def render(assigns) do
    MyAppWeb.PageView.render("index.html", assigns)
  end

  def mount(_session, socket) do
    {:ok, assign(socket, text: "Ready!", status: "ready")}
  end

  def handle_event(step, _value, socket) do
    text = @deployment_steps[step][:text]
    next_step = @deployment_steps[step][:next_step]
    state = %{text: text, status: step}
    send(self(), next_step)
    {:noreply, assign(socket, state)}
  end

  def handle_info("done", socket) do
    IO.puts "Done!"
    {:noreply, assign(socket, text: "Done!", status: "done")}
  end

  def handle_info(step, socket) do
    IO.puts "HANDLE INFO FOR #{step}..."
    MyApp.GitHubClient.do(step) # our app doing some work, details omitted.
    text = @deployment_steps[step][:text]
    next_step = @deployment_steps[step][:next_step]
    state = %{text: text, status: step}
    send(self(), next_step)
    {:noreply, assign(socket, state)}
  end
end
```

This works great when we're only concerned about pushing updates down the socket of _one_ LiveView process. But what about all of the other users who have loaded our Github Deploy page and are operating on their own LiveView processes? What if we want all such users to see the updates caused by one person's button click? Here's where our PubSub code comes to the rescue.

## Enacting the Broadcasts

Every time an instance of `GithubDeployView` mounts, we subscribe it to the _same_ topic:

```elixir
@topic "deployments"

def mount(_session, socket) do
  MyAppWeb.Endpoint.subscribe(@topic)
  {:ok, assign(socket, text: "Ready!", status: "ready")}
end
```

So, if a given LiveView process *broadcasts* to that topic, all of our subscribers will receive that message. We want our live view to broadcast whenever it will update the state of its socket. This way, we can tell all subscribing LiveView processes to update their own socket's state, which will then cause that LiveView's template to re-render. The flow will work like this:

![](/images/live_view_pub_sub.png)

Let's add a broadcast when our LiveView first receives the `"deploy"` event and when it receives each subsequent deployment step event:


```elixir
defmodule MyAppWeb.GithubDeployView do
  use Phoenix.LiveView
  @deployment_steps %{
    "deploy" => %{next_step: "create-org", text: "Creating org"},
    "create-org" => %{next_step: "create-repo", text: "Creating repo"},
    "create-repo" => %{next_step: "push-contents", text: "Pushing contents"},
    "push-contents" => %{next_step: "done", text: "Done!"}
  }
  @topic "deployments"

  def render(assigns) do
    MyAppWeb.PageView.render("index.html", assigns)
  end

  def mount(_session, socket) do
    {:ok, assign(socket, text: "Ready!", status: "ready")}
  end

  def handle_event(step, _value, socket) do
    text = @deployment_steps[step][:text]
    next_step = @deployment_steps[step][:next_step]
    state = %{text: text, status: step}
    MyAppWeb.Endpoint.broadcast_from(self(), @topic, step, state)
    send(self(), next_step)
    {:noreply, assign(socket, state)}
  end

  def handle_info("done", socket) do
    IO.puts "Done!"
    {:noreply, assign(socket, text: "Done!", status: "done")}
  end

  def handle_info(step, socket) do
    IO.puts "Processing #{step}..."
    MyApp.GitHubClient.do(step) # our app doing some work, details omitted.
    text = @deployment_steps[step][:text]
    next_step = @deployment_steps[step][:next_step]
    state = %{text: text, status: step}
    MyAppWeb.Endpoint.broadcast_from(self(), @topic, step, state)
    send(self(), next_step)
    {:noreply, assign(socket, state)}
  end
end
```

By using the `Phoenix.PubSub.broadcast_from/4` function, we broadcast a message describing the new socket state to all subscribers of a topic, *excluding the process from which we call broadcast*. We don't need the live view that received the click event to broadcast to itself, since it is already sending itself the next message via `send(self(), next_step)` and already updating its own socket's state via `assign(socket, state)`.

Now that we are successfully broadcasting the message, we need to teach our LiveView how to handle the receipt of the message. We can do this be defining another `handle_info/2` function that will pattern match against the broadcast struct:

```elixir
def handle_info(%{topic: @topic, payload: state}, socket) do
  IO.puts "HANDLE BROADCAST FOR #{state[:status]}"
  {:noreply, assign(socket, state)}
end
```

This `handle_info/2` function will get invoked when our LiveView subscribers receive a broadcast. Each subscriber will then update its own socket via `assign(socket, state)`, causing each subscriber's template to re-render.

If we start up our app, open two browser windows, and click "Deploy to GitHub", we should see both browsers update:

And we can see via our `puts` statements that, only one of our two clients is receiving the broadcasts while the other (the one that initiated the click event), is sending messages directly to itself:

```bash
[info] GET /
[debug] Processing with MyAppWeb.PageController.index/2
  Parameters: %{}
  Pipelines: [:browser]
[info] Sent 200 in 33ms
[info] CONNECT Phoenix.LiveView.Socket
  Transport: :websocket
  Connect Info: %{}
  Parameters: %{"vsn" => "2.0.0"}
[info] Replied Phoenix.LiveView.Socket :ok
[info] Replied phoenix:live_reload :ok
[info] Replied phoenix:live_reload :ok
HANDLE BROADCAST FOR deploy
HANDLE INFO FOR create-org
HANDLE BROADCAST FOR create-org
HANDLE INFO FOR create-repo
HANDLE BROADCAST FOR create-repo
HANDLE INFO FOR push-contents
HANDLE BROADCAST FOR push-contents
Done!
```

## Conclusion

Another approach to building this broadcast functionality would be to use an Elixir [Registry](https://hexdocs.pm/elixir/master/Registry.html). It wouldn't give us the ability to broadcast across distributed nodes as easily as PubSub, but I'd be curious to see it implemented to solve this problem.

The Phoenix PubSub library, however, allowed us to build a real-time feature that broadcasts shared updates to a set of users with just an additional five lines of code. Our Phoenix app was already configured to use Phoenix PubSub, and already had the pubsub backend up and running thanks to some out-of-the-box configuration. Integrating it with our existing LiveView code proved to be pretty straightforward, and we had even more advanced real-time functionality up and running in no time.
