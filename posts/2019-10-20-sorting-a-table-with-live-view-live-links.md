%{
  author: "Sophie DeBenedetto",
  author_link: "https://github.com/sophiedebenedetto",
  date: ~D[2019-10-20],
  tags: ["live view", "general"],
  title: "Building a Table Sort UI with Live View's `live_link`",
  excerpt: """
  We'll use LiveView's `live_link/2` together with the `handle_params/3` callback to allow users to sort a table in real-time.
  """
}

---

LiveView makes it easy to solve for some of the most common UI challenges with little to no front-end code. It allows us to save JavaScript for the hard stuff––for complex and sophisticated UI changes. In building out a recent admin-facing view that included a table of student cohorts at the Flatiron School, I found myself reaching for LiveView. In just a few lines of backend code, my sortable table was up and running. Keep reading to see how you can leverage LiveView's `live_link/2` and `handle_params/3` to build out such a feature.

## The Feature

Our view presents a table of student cohorts that looks like this:

![live view table]({% asset live-view-table.png @path %})

Users need to be able to sort this table by cohort name, campus, start date or status. We'd also like to ensure that the "sort by" attribute is included in the URL's query params, so that users can share links to sorted views.

Here's a look at the behavior we're going for. Note how the URL changes when we click on a given column heading to sort the table.

<iframe width="560" height="315" src="https://www.youtube.com/embed/-4VRaX1uEhk" allow="accelerometer; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Using `live_link/2`

LiveView's [`live_link/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#module-live-navigation) function allows page navigation using the browser's [pushState API](https://developer.mozilla.org/en-US/docs/Web/API/History_API). This will ensure that that URL will change to include whatever parameters we include in a given `live_link/2` call.

One important thing to note before we proceed, however. In order to use the live navigation features, our live view needs to be mounted directly in the router, _not_ rendered from a controller action.

Our router mounts the live view like this:

```elixir
# lib/course_conductor_web/router.ex

scope "/", CourseConductorWeb do
  pipe_through([:browser, :auth])
  live "/cohorts", CohortsLive
end
```

And we're ready to get started!

We'll start by turning the `"Name"` table header into a live link.

```html
# lib/course_conductor_web/templates/cohorts/index.html.leex
<table>
  <th><%= live_link "Name", to: Routes.live_path(@socket, CourseConductorWeb.CohortsLive, %{sort_by: "name"}) %></th>
  ...
</table>
```

The `live_link/2` function generates a live link for HTML5 pushState based navigation *without* page reloads.

With the help of the the `Routes.live_path` helper, we're generating the following live link: `"/cohorts?sort_by=name"`. Since this route belongs to the `CohortsLive` live view that we've already mounted, _and_ since that live view is defined in our router (as opposed to rendered from a controller action), this means we will invoke our existing live view's `handle_params/3` function _without mounting a new LiveView_. Pretty cool!

Let's take a look at how we can implement a `handle_params/3` function now.

## Implementing `handle_params/3`

The `handle_params/3` callback is invoked under two circumstances.
* After `mount/2` is called (i.e. when the live view first renders)
* When a live navigation event, like a live link click, occurs. This second circumstance only triggers this callback when, as described above, the live view we are linking to is the same live view we are currently on _and_ the LiveView is defined in the router.  

`handle_params/3` receives three arguments:
* The query parameters
* The requested url
* The socket

We can use `handle_params/3` to update socket state and therefore trigger a server re-render of the template.

Given that `handle_params/3` will be invoked by our live view whenever our `"Name"` live link is clicked, we need to implement this function in our live view to match and act on the `sort_by` params our live link will send.

Assuming we have the following live view that mounts and renders a list of cohorts:

```elixir
# lib/course_conductor_web/live/cohorts_live.ex

defmodule CourseConductorWeb.CohortsLive do
  use Phoenix.LiveView

  def render(assigns) do
    Phoenix.View.render(CourseConductorWeb.CohortView, "index.html", assigns)
  end

  def mount(_, socket) do
    cohorts = Cohort.all_cohorts()
    {:ok, assign(socket, cohorts: cohorts)}
  end
end
```

We'll implement our `handle_params/3` function like this:

```elixir
#  lib/course_conductor_web/live/cohorts_live.ex

def handle_params(%{"sort_by" => sort_by}, _uri, socket) do
  case sort_by do
    sort_by
    when sort_by in ~w(name) ->
      {:noreply, assign(socket, cohorts: sort_cohorts(socket.assigns.cohorts, sort_by))}

    _ ->
      {:noreply, socket}
  end
end


def handle_params(_params, _uri, socket) do
  {:noreply, socket}
end

def sort_cohorts(cohort, "name") do
  Enum.sort_by(cohorts, fn cohort -> cohort.name end)
end
```

Note that we've included a "catch-all" version of the `handle_params/3` function that will be invoked if someone navigates to `/cohorts` and includes query params that do not match the `"sort_by"` param that we care about. If our live view receives such a request, it will not update state.

Now, when a user clicks the `"Name"` live link, two things will happen:

* The browser's pushState API will be leveraged to change the URL to `/cohorts?sort_by=name`
* Our already-mounted live view's `handle_params/3` function will be invoked with the params `%{"sort_by" => "name"}`

Our `handle_params/3` function will then sort the cohorts stored `socket.assigns` by cohort name and update the socket state with the sorted list. The template will therefore re-render with the sorted list.

Since `handle_params/3` is _also_ called after `mount/2`, we have therefore allowed a user to navigate directly to `/cohorts?sort_by=name` via their browser and see the live view render with a table of cohorts already sorted by name. And just like that we've enabled users to share links to sorted table views with zero additional lines of code!

## More Sorting!

Now that our "sort by name" feature is up and running, let's add the remaining live links to allow users to sort by the other attributes we listed earlier: campus, start date and status.

First, we'll make each of these table headers into a live link:

```html
<table>
  <th><%= live_link "Name", to: Routes.live_path(@socket, CourseConductorWeb.CohortsLive, %{sort_by: "name"}) %></th>
  <th><%= live_link "Campus", to: Routes.live_path(@socket, CourseConductorWeb.CohortsLive, %{sort_by: "campus"}) %></th>
  <th><%= live_link "Start Date", to: Routes.live_path(@socket, CourseConductorWeb.CohortsLive, %{sort_by: "start_date"}) %></th>
  <th><%= live_link "Status", to: Routes.live_path(@socket, CourseConductorWeb.CohortsLive, %{sort_by: "status"}) %></th>
</table>
```

And we'll build out our `handle_params/3` function to operate on params describing a sort by any of these attributes:

```elixir
def handle_params(%{"sort_by" => sort_by}, _uri, socket) do
  case sort_by do
    sort_by
    when sort_by in ~w(name course_offering campus start_date end_date lms_cohort_status) ->
      {:noreply, assign(socket, cohorts: sort_cohorts(socket.assigns.cohorts, sort_by))}

    _ ->
      {:noreply, socket}
  end
end
```

Here, we've added a check to see if the `sort_by` attribute is included in our list of sortable attributes.

```elixir
when sort_by in ~w(name course_offering campus start_date end_date lms_cohort_status)
```

If so, we will proceed to sort cohorts. If not, i.e. if a user pointed their browser to `/cohorts?sort_by=not_a_thing_we_support`, then we will ignore the `sort_by` value and refrain from updating socket state.

Next up, we'll add the necessary version for the `sort_cohorts/2` function that will pattern match against our new "sort by" options:

```elixir
def sort_cohorts(cohorts, "campus") do
  Enum.sort_by(cohorts, fn cohort -> cohort.campus.name end)
end

def sort_cohorts(cohorts, "start_date") do
  Enum.sort_by(
    cohorts,
    fn cohort -> {cohort.start_date.year, cohort.start_date.month, cohort.start_date.day} end,
    &>=/2
  )
end

def sort_cohorts(cohorts, "status") do
  Enum.sort_by(cohorts, fn cohort ->
    cohort.status
  end)
end
```

And that's it!

## Conclusion

Once again LiveView has made it easy to build seamless real-time UIs. So, while LiveView doesn't mean you'll never have to write JavaScript again, it _does_ mean that we don't need to leverage JavaScript for common, everyday challenges like sorting data in a UI. Instead of writing complex vanilla JS, or reaching for a powerful front-end framework, we were able to create a sophisticated real-time UI with mostly back-end code, and back it all with the power of fault-tolerant Elixir processes.
