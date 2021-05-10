%{
  author: "Sophie DeBenedetto",
  author_link: "https://github.com/sophiedebenedetto",
  date: ~D[2019-05-21],
  tags: ["general"],
  title: "Tracking Users in a Chat App with LiveView, PubSub Presence",
  excerpt: """
  Use Phoenix Presence in your LiveView to track user state with just a few lines of code.
  """
}

---

After playing with LiveView and leveraging Phoenix PubSub to broadcast messages to all of a live view's clients, I wanted to try incorporating Phoenix Presence to track the state of these clients. So this past weekend I built a chat app using Phoenix LiveView, PubSub and Presence. The LiveView clocks in at 90 lines of code, and I was able to get the Presence-backed features up and running in no time! Keep reading to see how it works.

## The App

The chat app is fairly straightforward, and we won't get into the details of setting up LiveView in our Phoenix app here. You can check out the [source code](https://github.com/elixirschool/live-view-chat/tree/tutorial) along with this [earlier post](https://elixirschool.com/blog/phoenix-live-view/) on getting LiveView up and running for more info.

### Following Along

If you'd like to follow along with this tutorial, clone down the repo [here](https://github.com/elixirschool/live-view-chat/tree/tutorial) and follow the README instructions to get up and running. The starting state of the tutorial branch includes the chat domain model, routes, controller and the initial state of the LiveView, described below. You can also check out the completed code [here](https://github.com/elixirschool/live-view-chat).

### `ChatLiveView's` Initial State

We've mounted our live view at `/chats/:id` by telling the `show` action of the `ChatController` to render the `ChatLiveView`. We pass the given chat and the current user from the controller into our live view:

```elixir
# lib/phat_web/controllers/chat_controller.ex

defmodule PhatWeb.ChatController do
  use PhatWeb, :controller
  alias Phat.Chats
  alias Phoenix.LiveView
  alias PhatWeb.ChatLiveView

  def show(conn, %{"id" => chat_id}) do
    chat = Chats.get_chat(chat_id)

    LiveView.Controller.live_render(
      conn,
      ChatLiveView,
      session: %{chat: chat, current_user: conn.assigns.current_user}
    )
  end
end
```

The `ChatLiveView.mount/2` function sets up the initial state of the LiveView socket with the given chat, an empty message changeset with which to populate the form for a new message, and the current user:

```elixir
# lib/phat_web/live/chat_live_view.ex

defmodule PhatWeb.ChatLiveView do
  use Phoenix.LiveView
  alias Phat.Chats

  def render(assigns) do
    PhatWeb.ChatView.render("show.html", assigns)
  end

  def mount(%{chat: chat, current_user: current_user}, socket) do
    {:ok,
     assign(socket,
       chat: chat,
       message: Chats.change_message(),
       current_user: current_user
     )}
  end
end
```

After mounting and setting the socket state, the live view will render the `ChatView`'s `show.html` template:

```elixir
# lib/phat_web/templates/chat/show.html.leex

<h2><%= @chat.room_name %></h2>
<%=for message <- @chat.messages do %>
  <p>
    <%= message.user.first_name %>: <%= message.content %>
  </p>
<% end %>

<div class="form-group">
  <%= form_for @message, "#", [phx_submit: :message], fn _f -> %>
    <%= text_input :message, :content, placeholder: "write your message here..." %>
    <%= hidden_input :message, :user_id, value: @current_user.id  %>
    <%= hidden_input :message, :chat_id, value: @chat.id  %>
    <%= submit "submit" %>
  <% end %>
</div>
```

Our template is simple: it grabs the chat we assigned to our live view's socket, displays the chat room name and iterates over the messages to show us the content and sender. It also contains a form for a new message, built on the empty message changeset we assigned to our socket. At this point, our rendered template looks something like this:

![]({% asset live-view-1.png @path %})

### Pushing Messages to the LiveView Client

Now that our live view is up and running, let's take a look at what happens when a given user submits the form for a new message.

We've attached the `phx-submit` event to our form's submission, and instructed it to emit an event of type `"message"`.

```elixir
# lib/phat_web/templates/chat/show.html.leex

  <%= form_for @message, "#", [phx_submit: :message], fn _f -> %>
  ...
```

Now, we need to teach our live view how to handle this event by defining a matching `handle_event/3` function.

```elixir
# lib/phat_web/live/chat_live_view.ex

defmodule PhatWeb.ChatLiveView do
  ...
  def handle_event("message", %{"message" => message_params}, socket) do
    chat = Chats.create_message(message_params)
    {:noreply, assign(socket, chat: chat, message: Chats.change_message())}
  end
end
```

The live view responds to the `"message"` event by creating a new message and updating the socket's with the updated chat and a new empty message changeset for our form. *Note that although we specify the value of the `phx_submit` as an atom, `:message`, our live view process receives the message as a string, `"message".*`

The live view then re-renders the relevant portions of our page, in this case the chat and messages display and the form for a new message.

Thanks to this code, we have messages getting pushed down the socket to the client who submitted the message form. But what about all of the other clients in our live view––the other users in the chatroom?

## Broadcasting Messages with Phoenix PubSub

In order to broadcast the new message to all such users, we need to leverage Phoenix PubSub.

First, we need to ensure that each client starts subscribing to the chat room's PubSub topic when they mount the live view:

```elixir
# lib/phat_web/live/chat_live_view.ex

defp topic(chat_id), do: "chat:#{chat_id}"

def mount(%{chat: chat, current_user: current_user}, socket) do
  PhatWeb.Endpoint.subscribe(topic(chat.id))

  {:ok,
   assign(socket,
     chat: chat,
     message: Chats.change_message(),
     current_user: current_user
   )}
end
```
Then, we need to teach our live view to broadcast new messages to these subscribers when it handles the `"message"` event.

```elixir
# lib/phat_web/live/chat_live_view.ex

def handle_event("message", %{"message" => message_params}, socket) do
  chat = Chats.create_message(message_params)
  PhatWeb.Endpoint.broadcast_from(topic(chat.id), self(), "message", %{chat: chat})
  {:noreply, assign(socket, chat: chat, message: Chats.change_message())}
end
```

The `broadcast_from/4` function will broadcast a message of type `"message"`, with the payload of our newly updated chat, to all subscribing clients *excluding the client who is sending the message*.

Lastly, we need to teach our live view how to respond to this broadcast with a `handle_info/2` function:

```elixir
# lib/phat_web/live/chat_live_view.ex

def handle_info(%{event: "message", payload: state}, socket) do
  {:noreply, assign(socket, state)}
end
```

The live view handles the `"message"` message by updating the socket's state with `%{chat: chat}` payload, where the chat is our newly updated chat containing the new message from the user. And that is all it takes to ensure that all subscribing clients see any new messages submitted into the chat template's new message form!

## Tracking Users with Phoenix Presence

Now that our live view is smart enough to broadcast messages to all of the users in the given chat room, we're ready to build some features that track and interact with those users. Let's say we want to have our template render a list of users in the chat room, something like this:

![]({% asset live-view-presence-1.png @path %})

We could create our own data structure for tracking user presence in a live view, store it in the live view's socket, and hand-roll our own functions to update that data structure when a user joins, leaves or otherwise changes their state. However, the [Phoenix Presence behaviour](https://hexdocs.pm/phoenix/Phoenix.Presence.html) abstracts this work away from us. It provides presence tracking for processes and channels, leveraging Phoenix PubSub behind the scenes to broadcast updates. It also uses a CRDT (Conflict-free Replicated Data Type) model, which means it works on distributed applications.

Now that we understand a bit about what Presence is and why we want to use it, let's get it set up in our application.

### Setting Up Presence

In order to leverage Presence in our Phoenix app, we need to define our very our module:

```elixir
# lib/phat_web/presence.ex

defmodule PhatWeb.Presence do
  use Phoenix.Presence,
    otp_app: :phat,
    pubsub_server: Phat.PubSub
end
```

The `PhatWeb.Presence` module does three things:

* `uses` the Presence behaviour
* Specifies that it shares a PubSub server with the rest of the application
* Specifies that is shares our app's OTP app, which holds our application configuration

Now we can use the `PhatWeb.Presence` module throughout our app to track user presence in a given process.

### Tracking User Presence

Our Presence module will maintain lists of present users in a given chat room by storing these users under a given topic of `"chat:#{chat_id}"`.

So, when should we tell Presence to start tracking a given user? Well, at what point in time do we consider a user to be "present" in a chat room? When the user mounts the live view!

We'll hook into our `mount/2` function to add the new user to Presence's list of users in a given chat room:

```elixir
# lib/phat_web/live/chat_live_view.ex
©
def mount(%{chat: chat, current_user: current_user}, socket) do
  Presence.track(
    self(),
    topic(chat.id),
    current_user.id,
    %{
      first_name: current_user.first_name,
      email: current_user.email,
      user_id: current_user.id
    }
  )
  ...
end
```

Here, we use the [`Presence.track/4`](https://hexdocs.pm/phoenix/Phoenix.Presence.html#c:track/4) function to track our live view process as a presence. We add the PID of the LiveView process to Presence's data store, along with a payload describing the new user under a topic of `"chat:#{chat.id}"` and a key of the user's ID.

The Presence process's state for the given topic will look something like this:

```elixir
%{
  "1" => %{
    metas: [
      %{
        email: "sophie@email.com",
        first_name: "Sophie",
        phx_ref: "TNV4PzRfyhw=",
        user_id: 1
      }
  }
}
```

#### Broadcasting Presence To Existing Users

When we call `Presence.track`, Presence will broadcast a `"presence_diff"` event over its PubSub backend. We told our Presence module to use the same PubSub server as the rest of the application––the very same server that backs our `PhatWeb.Endpoint`.

Recall that our live view clients are subscribing to this PubSub server via the following call in the `mount/2` function: `PhatWeb.Endpoint.subscribe(topic(chat.id))`. So, these subscribing LiveView processes will receive the `"presence_diff"` event, which looks something like this:

```elixir
%{
  event: "presence_diff",
  payload: %{
    joins:
      %{
        "1" => %{
          metas: [
            %{
              email: "sophie@email.com",
              first_name: "Sophie",
              phx_ref: "TNV4PzRfyhw=",
              user_id: 1
            }
          }
        },
    leaves: %{},
  }
}
```

The event's payload will describe the users that are joining the channel when `Presence.track/4` is called. Although we will respond to the `"presence_diff"` event, we won't do anything with the event's payload for now. However, you could imagine using it to create custom user experiences such as welcoming the newly joined user or alerting existing users that a certain new member has joined the chat room.

In order to respond to the event we'll define a `handle_info/2` function in our live view that will match the `"presence_diff"` event:

```elixir
# lib/phat_web/live/chat_live_view.ex

def handle_info(%{event: "presence_diff"}, socket = %{assigns: %{chat: chat}}) do

end
```

This function has two responsibilities:

* Get the list of present users for the given chat room topic from the Presence data store
* Update the LiveView socket's state to reflect this list of users

```elixir
def handle_info(%{event: "presence_diff", payload: _payload}, socket = %{assigns: %{chat: chat}}) do
  users =   
    Presence.list(topic(chat.id))
    |> Enum.map(fn {_user_id, data} ->
      data[:metas]
      |> List.first()
    end)

  {:noreply, assign(socket, users: users)}
end
```

First, we use the `Presence.list/1` function to get the collection of present users under the given topic. This will return the following data structure:

```elixir
%{
  "1" => %{
    metas: [
      %{
        email: "sophie@email.com",
        first_name: "Sophie",
        phx_ref: "TNV4PzRfyhw="
        user_id: 1
      }
  },
  "2" => %{
    metas: [
      %{
        email: "beini@email.com",
        first_name: "Beini",
        phx_ref: "ZZ30QuoI/8s="
        user_id: 2
      }
  }
  ...
}
```

The Presence behavior handles the diffs of join and leave events for us. So, as long as we call `Presence.track/4`, the Presence process will update its own state, such that when we next call `Presence.list/1`, we are retrieving the updated list of users.

Once we fetch this list, we iterate over it to collect a list of the individual `:metas` payloads that describe each user. The resulting list will look like this:

```elixir
[
  %{
    email: "sophie@email.com",
    first_name: "Sophie",
    phx_ref: "TNV4PzRfyhw="
    user_id: 1
  },
  %{
    email: "beini@email.com",
    first_name: "Beini",
    phx_ref: "ZZ30QuoI/8s="
    user_id: 2
   }
  }
]
```

We enact this transformation so that we have a simple, easy-to-use data structure to interact with in the template when we want to list present user names.

Lastly, we update the LiveView socket's state by adding a key of `:users` pointing to a value of our user list:

```elixir
{:noreply, assign(socket, users: users)}
```

Now we can access the user list via the `@users` assignment in our template to list out the names of the users present in the chatroom:

```elixir
# lib/phat_web/templates/chat/show.html.leex

<h3>Members</h3>
<%= for user <- @users do %>
  <p>
    <%= user.first_name %>
  </p>
<% end %>
```

Let's recap. The code we've written so far supports the following flow:

When a user visits a chat room at `/chats/:id` and the LiveView is mounted...

* Add the user to the Presence data store's list of users for the given chat room topic
* Broadcast to subscribing clients, telling them to grab the latest list of present users from the Presnce data store
* Update the live view socket's state with this updated list
* Re-render the live view template to display this updated list of users

This allows users who are *already in a chat room* to see an updated list of users reflected anyone who joins the chatroom.

But what about the user who is joining? How can we ensure that when a new user visits the chat room, they see the list of users who are already present?

#### Fetching Presence for New Users

In order to display the existing chat room members to any new users who join, we need to fetch these users from Presence and assign them to the live view socket when the live view mounts.

Let's update our `mount/2` function to do exactly that:

```elixir
# lib/phat_web/live/chat_live_view.ex

def mount(%{chat: chat, current_user: current_user}, socket) do
  ...
  users =   
    Presence.list(topic(chat.id))
    |> Enum.map(fn {_user_id, data} ->
      data[:metas]
      |> List.first()
    end)

  {:ok,
   assign(socket,
     chat: chat,
     message: Chats.change_message(),
     current_user: current_user,
     users: users
   )}
end
```

Now our live view will be able to render the list of existing members for a new user loading the page.

#### Broadcasting User Leave Events

At this point, you might be wondering how we can update Presence state and broadcast changes when a user leaves the tracked process. This is actually functionality that we get for free thanks to the Presence behavior. Recall that we are tracking presence for a given LiveView process via the `Presence.track/4` function, where the first argument we give to `track/4` is the PID of the LiveView process.

When a user navigates away from the chat show page, their LiveView process terminates. This will cause `Presence.untrack/3` to get called, thereby un-tracking the terminated PID. This in turn tells Presence to broadcast the `"presence_diff"` event, this time with a payload that describes the departed user, i.e. the user we were tracking under the terminated PID. Presence knows how to handle diffs from both join *and* leave events––it will update the list of users it is storing under the chat room topic appropriately.

The running LiveView processes that receive this `"presence_diff"` event will need to fetch this updated list of present users for the given topic, update socket state and re-render the page accordingly. This means we can re-use our original `handle_info/2` function for the `"presence_diff"` event without making any changes:

```elixir
# lib/phat_web/live/chat_live_view.ex

def handle_info(%{event: "presence_diff", payload: _payload}, socket = %{assigns: %{chat: chat}}) do
  users =   
    Presence.list(topic(chat.id))
    |> Enum.map(fn {_user_id, data} ->
      data[:metas]
      |> List.first()
    end)

  {:noreply,
   assign(socket,
     users: users
   )}
end
```

So, we don't have to write any additional code to handle the "leave" event at all!

#### Using Presence to Track User State

So far, we've leveraged presence to keep track of users as they join or leave the LiveView. We can also use presence to track the state of a given user while they are present in the LiveView process. Let's see how this works by building a feature that indicates that a given user is typing into the new chat message form by appending a `"..."` to their name on the list of present users rendered in the template:

![]({% asset live-view-presence-2.png @path %})

First, we'll update the `:metas` payload we use to describe the starting state of a given user with the data point: `typing: false`:

```elixir
# lib/phat_web/live/chat_live_view.ex

def mount(%{chat: chat, current_user: current_user}, socket) do
  Presence.track(
    self(),
    topic(chat.id),
    current_user.id,
    %{
      first_name: current_user.first_name,
      email: current_user.email,
      user_id: current_user.id,
      typing: false
    }
  )
  ...
end
```

Then, we'll attach a new `phx-change` event to our form that will fire with a message type of `"typing"` when a user types into the form field:

```elixir
# lib/phat_web/templates/chat/show.html.leex

<%= form_for @message, "#", [phx_change: :typing, phx_submit: :message], fn _f -> %>
  ...
<% end %>
```

Next up, we will teach our live view to handle this event with a new `handle_event/2` function that matches the `"typing"` event type. To respond to this event, the live view should update the current user's `:metas` map under the given chat room's topic:

```elixir
# lib/phat_web/live/chat_live_view.ex

def handle_event("typing", _value, socket = %{assigns: %{chat: chat, current_user: user}}) do
  topic = topic(chat.id)
  key   = user.id
  payload = %{typing: true}
  metas =
      Presence.get_by_key(topic, key)[:metas]
      |> List.first()
      |> Map.merge(payload)

  Presence.update(self(), topic, key, metas)
  {:noreply, socket}
end
```

Here, we use the `Presence.get_by_key/2` function to fetch the `:metas` for the current user, stored under the `topic` of `"chat:#{chat.id}"`, under a key of the user's ID.

Then we create a copy of the `:metas` map for that user, setting the `:typing` key to `true`.

Lastly, we update the Presence process's metadata for the topic and user to point to this new map. Calling `Presence.update/4` will once again broadcast a `"presence_diff"` event for us. Our LiveView processes already know how to handle this event, so we don't need to write any additional code to ensure that running LiveView processes fetch the latest list of users with the new metadata and re-render the page.

The last thing we need to do is update our template to append `"..."` to name of any users on the list who have `typing` set to `true`:

```elixir
# lib/phat_web/templates/chat/show.html.leex

<h3>Members</h3>
<%= for user <- @users do %>
  <p>
    <%= user.first_name %><%= if user.typing, do: "..." end%>
  </p>
<% end %>
```

Now we're ready to teach our LiveView how to behave when a user *stops* typing, ensuring that the template will re-render without the `"..."` attached to the user's name.

We'll add a `phx-blur` event to the message content form field:

```elixir
# lib/phat_web/templates/chat/show.html.leex

  <%= text_input :message, :content, value: @message.changes[:content], phx_blur: "stop_typing", placeholder: "write your message here..." %>
```

This will send an event of type `"stop_typing"` to the LiveView process when the user blurs away from this form field.

We'll teach our LiveView to respond to this message with a `handle_info/2` that updates the Presence metadata with `typing: false` for the current user.

```elixir
# lib/phat_web/live/chat_live_view.ex

def handle_event(
      "stop_typing",
      value,
      socket = %{assigns: %{chat: chat, current_user: user, message: message}}
    ) do
  message = Chats.change_message(message, %{content: value})

  topic = topic(chat.id)
  key   = user.id
  payload = %{typing: false}
  metas =
      Presence.get_by_key(topic, key)[:metas]
      |> List.first()
      |> Map.merge(payload)

  Presence.update(self(), topic, key, metas)

  {:noreply, assign(socket, message: message)}
end
```

*Note: Here we can see some obvious repetition of code we wrote to handle the `"typing"` event. This code has been refactored to move Presence interactions into our `PhatWeb.Presence` module which you can check out [here](https://github.com/elixirschool/live-view-chat/blob/master/lib/phat_web/presence.ex) and [here](https://github.com/elixirschool/live-view-chat/blob/master/lib/phat_web/live/chat_live_view.ex). For the purposes of easy reading in this post, I let this code remain explicit.*

Here, we update the message changeset to reflect the content the user typed into the form field. Then, we fetch the user's metadata from Presence and update it to set `typing: false`. Lastly, we update the live view's socket to reflect the content the user typed into the message form field. This is a necessary step so that the template will display this content when it re-renders as a consequence of the `"presence_diff"` event.

Since we called `Presence.update/4`, the presence process will broadcast the `"presence_diff"` event and the LiveView processes will respond by fetching the updated list of users with the new metadata and re-rendering the template. This re-render will have the effect of removing the `"..."` from the given user's name since the call to `user.typing` in the template will now evaluate to `false`.

## Conclusion

Let's take a step back and recap what we've built:

* With "plain" LiveView, we gave our chat the ability to push real-time updates to the user who initiated the change. In other words, users who submit new messages via the chat form see those new messages appear in the chat log on the page.
* With the addition of PubSub, we were able to broadcast these new chat messages to *all* of the LiveView clients subscribed to a chat room topic, i.e. all of the members of a given chat room.
* By leveraging Presence, we were able to track and display the list of users "present" in a given chat room, along with the state of a given user (i.e. whether or not they are currently typing).

You can see the final (slightly refactored!) code [here](https://github.com/elixirschool/live-view-chat).

The flexibility of Phoenix PubSub made it easy to subscribe all of our running LiveView processes to the same topic on the pub sub server. In addition, the Presence module's ability to share a pub sub server with the rest of our application allowed each Presence process to broadcast presence events to LiveView processes. Overall, LiveView, PubSub and Presence played together really nicely, and enabled us to build a robust set of features with very little hand-rolled code.
