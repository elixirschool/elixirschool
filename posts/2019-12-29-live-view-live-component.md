%{
  author: "Sophie DeBenedetto",
  author_link: "https://github.com/sophiedebenedetto",
  date: ~D[2019-12-29],
  tags: ["LiveView", "software design"],
  title: "LiveView Design Patterns - LiveComponent and the Single Responsibility Principle",
  excerpt: """
  It's easy to end up with an overly complex LiveView that houses lots of business rules and responsibilities. We can use `Phoenix.LiveComponent` to build a LiveView feature that is clean, maintainable and adherent to the Single Responsibility Principle.
  """
}

---

## LiveView Can Get Messy

As LiveView becomes a more established technology, we naturally find ourselves using it to back more and more complex features. If we're not careful, this can lead to "fat controller syndrome"––live views that are jam packed with complex business logic and disparate responsibilities, just like the classic "fat Rails controller".

How can we write live views that are easy to reason about and maintain while adhering to common design principles like SRP?

One way to achieve this goal is to leverage the `Phoenix.LiveComponent` behaviour.

## Introducing `Phoenix.LiveComponent`

Components are modules that use the `Phoenix.LiveComponent` behaviour. This behaviour provides

> ...a mechanism to compartmentalize state, markup, and events in LiveView. ––[docs](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html)

Components are run inside a parent live view process via a call to `Phoenix.LiveView.live_component/3`. Since they share a process with their parent live view, communication between the two is simple (more on that later).

Components can be stateless or stateful. While stateless components don't do much more than render a particular `leex` template, stateful components implement a `handle_event/3` function that allow us to update the component's own state. This makes components a great way to peel off responsibilities from an overly complex live view.

Let's take a look at how we can use components to refactor some complicated LiveView code in an existing application.

## The App

Let's say we have an application that uses a message broker like RabbitMQ to publish and consume messages between systems. Our app persists these messages in the DB and exposes a UI for users to list and search such persisted messages.


![live view messages index]({% asset live-view-messages-index.png @path %})

We're using LiveView to enact the search functionality, pagination and maintain which messages are currently being displayed in state. Our live view module responds to search form events and maintains the state of the search form, handles the search form submission *and* renders the template with various search and pagination params.

### The Code

A simplified version of our live view looks something like this:

```elixir
defmodule RailwayUiWeb.MessageLive.Index do
  def render(assigns) do
   Phoenix.View.render(RailwayUiWeb.MessageView, "index.html", assigns)
  end

  def mount(_session, socket) do
   socket =
     socket
     |> assign(:page, 1)
     |> assign(:search, %Search{query: nil, value: nil})
     |> assign(:messages, load_messages())

   {:ok, socket}
  end

  def handle_params(
       %{"page" => page_num, "search" => %{"query" => query, "value" => value}},
       _uri,
       %{assigns: %{search: search}} = socket
     ) do
   socket =
     socket
     |> assign(:page, page_num)
     |> assign(:search, Search.update(query, value))
     |> assign(:messages, messages_search(query, value, page_num))

   {:noreply, socket}
  end

  def handle_params(
       %{"page" => page_num},
       _uri,
       %{assigns: %{state: state}} = socket
     ) do
   socket =
     socket
     |> assign(:page, page_num)
     |> assign(:messages, messages_page(page_num))

   {:noreply, socket}
  end

  def handle_params(
       %{"search" => %{"query" => query, "value" => value}},
       _,
       %{assigns: %{search: search}} = socket
     ) do
   socket =
     socket
     |> assign(:search, %Search{query: query, value: value})
     |> assign(:messages, messages_search(query, value))

   {:noreply, socket}
  end

  def handle_params(_params, _, socket) do
   {:noreply, socket}
  end

  def handle_info("search", params, socket) do
   {:noreply,
    live_redirect(socket,
      to: Routes.live_path(socket, __MODULE__, params)
    )}
  end

  def handle_event(
       "search_form_change",
       %{"_target" => ["search", "value"], "search" => %{"value" => value}},
       %{assigns: %{search: search}} = socket
     ) do
   {:noreply, assign(socket, :search, %Search{query: search.query, value: value})}
  end

  def handle_event(
       "search_form_change",
       %{"_target" => ["search", "query"], "search" => %{"query" => query}},
       %{assigns: %{search: search}} = socket
     ) do
   {:noreply, assign(socket, :search, %Search{query: query, value: search.value})}
  end

  def handle_event(
       "search_form_change",
       %{"_target" => ["search", "query"], "search" => %{"value" => _value}},
       socket
     ) do
   {:noreply, socket}
  end
end
```

Maintaining a representation of the search form's selected query and inputed value in state allows us to ensure that the correct search query radio button is selected and allows us to update the placeholder text of the search form input field:

<iframe width="560" height="315" src="https://www.youtube.com/embed/6Ta2Au-PcQI" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>


Maintaining the search form state also ensures that users can navigate directly to the `/consumed_messages` route with a set of query params and see not just the correctly populated messages but also the correctly configured search form:


![live component search form query params]({% asset live-component-search-form-query-params.png @path %})

### The Problem

Its clear that we need to maintain the state of our search form but the LiveView code above is too lengthy to maintain and reason about. It manages search form state, implements a set of `handle_params/3` callbacks to enact search queries and pagination and maintains a set of messages in state. This is a lot of work and it violates the Single Responsibility Principle. Our live view, plainly put, does too many jobs.

Let's refactor the search form state maintenance into its very own stateful component!

## The Solution: The Search Form Component

Our search form component will get its initial search form state from the parent live view. This will ensure that a user can navigate directly to a route like `/consumed_messages?search[query]=uuid&search[value]=0af71c6a-aeec-431f-83d0-ae779358b055` and see the search form correctly configured from the params.

However, our search component will go on to maintain the search form state independently of the parent, only forwarding messages up to the live view when the form is submitted.

This way, we can move the search form change event handling and its subsequent impact on search form state out of the live view. This will leave us with a cleaner live view with fewer responsibilities.

### Defining the Component
#### Setting Initial State From LiveView

We'll begin by defining our component, `RailwayUiWeb.MessageLive.SearchComponent`, and rendering it with an initial search from state from the parent live view.

```elixir
defmodule RailwayUiWeb.MessageLive.SearchComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    Phoenix.View.render(RailwayUiWeb.MessageView, "search_component.html", assigns)
  end
end
```

At this point, our component is simple. It uses the `Phoenix.LiveComponent` behaviour and implements a `render/1` function. This function renders our `search_component.html.leex` template (which we'll take a look at in a moment), passing through the `assigns` established when the parent live view calls `live_component/3`.

Let's take a look at that call now. In the parent live view's template, we invoke:

```html
<%= live_component @socket, RailwayUiWeb.MessageLive.SearchComponent, search: @search, id: :search %>
```

There are two important things to call out here. First, its important to note that we are passing in the `:id` attribute and setting it to a value of the `:search` atom. Components are made stateful by the setting of the `:id` attribute. Without this, we would not be able to implement the `handle_event/2` callbacks

Second, we are populating the component's `assigns` with the `@search` value. The component's `assigns` at this point looks like this:

```elixir
%{search: search}
```

And the search struct from the parent live view's `socket.assigns` will be available in the component's own template as `@search`.

This allows us to leverage the `handle_params/3` callback in the parent live view to establish the search state and then pass that search state into the component. Let's take a closer look at how this works:

1. User visit `/consumed_messages?search[query]=uuid&search[value]=0af71c6a-aeec-431f-83d0-ae779358b055`
2. The `MessageLive.Index` live view's `handle_params/3` function is called:

```elixir
def handle_params(
      %{"search" => %{"query" => query, "value" => value}},
      _,
      %{assigns: %{search: search}} = socket
    ) do
  socket =
    socket
    |> assign(:search, %Search{query: query, value: value})
    |> assign(:messages, messages_search(query, value))

  {:noreply, socket}
end
```

3. The `MessageLive.Index` live view's template renders with the `@search` assignment
4. The `MessageLive.Index`'s template calls `live_component/3`, passing through the `@search` assignment
5. The `MessageLive.SearchComponent`'s template renders with the  `@search` assignment, correctly rendering the search form to reflect any selected search query type and input.

Let's take a look at the component's template now in order to understand how it uses the information in the search form's state to render appropriately.

#### Building The Search Form Template

The search component's template uses the query and value attributes of the `@search` assignment to ensure that the correct radio button is selected and that the search form input is correctly populated with a value if one is present.

```html
<!-- styling removed for brevity -->
<form>
  <div>
    <div>
      <input name="search[query]" value="uuid" type="radio" <%= if @search.query == "uuid", do: "checked" %>>
      <label class="form-check-label">message UUID</label>
    </div>
    <div>
      <input name="search[query]" value="correlation_id" type="radio" <%= if @search.query == "correlation_id", do: "checked" %>>
      <label class="form-check-label">correlation ID</label>
    </div>
    <div>
      <input name="search[query]" value="message_type" type="radio" <%= if @search.query == "message_type", do: "checked" %>>
      <label class="form-check-label">message type</label>
    </div>
  </div>
  <div>
    <input name="search[value]" value="<%= @search.value %>" type="text" placeholder="<%= "search by #{@search.query}"  %>">
  </div>
  <button type="submit" class="btn btn-primary">Submit</button>
</form>
```

A few things to note here:

* `if` conditions, like the one below, are responsible for ensuring the correct radio button is selected:

```elixir
if @search.query == "message_type", do: "checked"
```

* The `value` of the search form's input field is populated by the `@search` assignment's `value` attribute:

Now that we've seen how our component is rendered with its initial search form state, let's take a look at how our component will handle search form events.

#### Handling Form Change Events

We need to update the component's `socket.assigns` to reflect changes to search form state under two conditions:

* The user selects a given search query ("message UUID", "correlation ID", "message type")
* The user types a value into the search form input field

We'll add a `phx-change` event to our form to capture these interactions and define the corresponding `handle_event/3` callbacks in our component.

```html
<form phx-change="search_form_change">
  ...
</form>
```

We'll add the following `handle_event/3` callbacks:

```elixir
defmodule RailwayUiWeb.MessageLive.SearchComponent do
  ...

  # update search state when user inputs a search value
  def handle_event(
      "search_form_change",
      %{"_target" => ["search", "value"], "search" => %{"value" => value}},
      %{assigns: %{search: search}} = socket
    ) do
    {:noreply, assign(socket, :search, %Search{query: search.query, value: value})}
  end

  # update search state when user selects a query type radio button
  def handle_event(
        "search_form_change",
        %{"_target" => ["search", "query"], "search" => %{"query" => query}},
        %{assigns: %{search: search}} = socket
      ) do
    {:noreply, assign(socket, :search, %Search{query: query, value: search.value})}
  end
end
```

These callbacks ensure two things for us:

* The correct radio button is marked as "selected" when a user chooses a new search query type option.
* The search form input's `placeholder` attribute is correctly updated to reflect the selected query type:

```html
<input name="search[value]" value="<%= @search.value %>" type="text" placeholder="<%= "search by #{@search.query}"  %>">
```

#### Handling Form Submission

Now that our form component's state properly updates in response to the user's interactions, let's talk about what needs to happen when a user submits the form.

The feature we're designing requires us to populate the URI's query params in the browser's URL bar when the user submits the search form. This allows users to share a link with the results of a particular search.

In order to achieve this, we can reach for the `live_redirect/2` function. This will take advantage of the browser's `pushState` API to change the page navigation without actually sending a web request. Instead, our live view's `handle_params/3` callback function will be invoked, allowing us to respond by searching for the appropriate messages and updating the live view socket's state with those messages.

But wait! The `live_redirect/2` function is sadly not available from within component since the `Phoenix.LiveComponent` behaviour does not implement a `handle_params/3` function. Luckily for us, however, the parent live view and the component share a process. That means that calling `self()` from within the component returns a PID that *is the same PID as that parent live view process*. So, from within our component we can `send` a message to `self()` and handle that message in the parent live view.

We'll take advantage of this functionality to have our component handle search from submission events by sending a message to the parent live view instructing that live view to enact a live redirect.

We'll start by adding a `phx-submit` event binding to our search form in the component's template:

```html
<form phx-submit="search" phx-change="search_form_change">
  ...
</form>
```

Then we'll implement a `handle_event/3` function for this `"search"` event in the component:

```elixir
defmodule RailwayUiWeb.MessageLive.SearchComponent do
  ...

  def handle_event("search", params, socket) do
    send self(), {:search, params}
    {:noreply, socket}
  end
end
```

The important part of our function is this line:

```elixir
send self(), {:search, params}
```

Here, we are sending a message `{:search, params}` that the parent live view can respond to.

Lastly, we will implement a `handle_info/2` callback in the parent live view that will be responsible for enacting the live redirect with the params from the search form:

```elixir
defmodule RailwayUiWeb.MessageLive.Index do
  ...

  def handle_info({:search, params}, socket) do
    {:noreply,
     live_redirect(socket,
       to: Routes.live_path(socket, __MODULE__, params)
     )}
  end
end
```

This will in turn cause the live view's `handle_params/3` callback to be invoked, resulting in the correct updates to the live view's state:

```elixir
defmodule RailwayUiWeb.MessageLive.Index do
  ...

  def handle_params(
       %{"search" => %{"query" => query, "value" => value}},
       _,
       %{assigns: %{search: search}} = socket
     ) do
   socket =
     socket
     |> assign(:search, %Search{query: query, value: value})
     |> assign(:messages, messages_search(query, value))

   {:noreply, socket}
  end
end
```

## Conclusion

As a result of this refactoring, we have a cleaner live view module that is more adherent to the Single Responsibility Principle. Our live view can focus on setting up the correct state given a set of params. Meanwhile, the logic required to maintain the state of the search form and render search form attributes appropriately can be housed in a dedicated component.

We did run into an obstacle when we found ourselves unable to use `live_redirect/2` from within our component. However, since the component and the live view share a process, we found it easy to enact communication between the two.

Still, this approach doesn't allow us to build a live view that is entirely agnostic of the state of the search form. In order to allow users to navigate directly to the route with query params, our parent live view does set up the initial state of the search form and pass it down into the component. Regardless of this drawback, reaching for components here has allowed us to write and maintain a slimmer live view.

For a look at some of the other state, markup and event handling isolation options that LiveView offers, check out the docs [here](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#module-compartmentalizing-markup-and-events-with-render-live_render-and-live_component).
