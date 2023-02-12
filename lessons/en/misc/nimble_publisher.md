%{
  version: "1.0.2",
  title: "NimblePublisher",
  excerpt: """
  [NimblePublisher](https://github.com/dashbitco/nimble_publisher) is a minimal filesystem-based publishing engine with Markdown support and code highlighting.
  """
}
---

## Why use NimblePublisher?

NimblePublisher is a simple library designed for publishing content parsed from local files using Markdown syntax. A typical use case would be building a blog.

This library encapsulates most of the code that Dashbit uses for their own blog, as presented in their post [Welcome to our blog: how it was made!](https://dashbit.co/blog/welcome-to-our-blog-how-it-was-made) - and where they explain why they chose parsing the content from local files instead of using a database or a more complex CMS.

## Creating your content

Let's build our own blog. In our example, we're using a Phoenix application but Phoenix is not a requirement. As NimblePublisher only takes care of parsing the local files, you can use it in any Elixir application.

First, let's create a new Phoenix application for our example. We'll call it NimbleSchool, and we'll create it like this because we don't need Ecto where we're going:

```shell
mix phx.new nimble_school --no-ecto
```

Now, let's add some posts. We need to start creating a directory that will contain our posts. We'll keep them organized by year in this format:

```
/priv/posts/YEAR/MONTH-DAY-ID.md
```

For example, we start with these two posts:

```
/priv/posts/2020/10-28-hello-world.md
/priv/posts/2020/11-04-exciting-news.md
```

A typical blog post will be written in Markdown syntax, with a metadata section on top, and the content below separated by `---`, like this:

```
%{
  title: "Hello World!",
  author: "Jaime Iniesta",
  tags: ~w(hello),
  description: "Our first blog post is here"
}
---
Yes, this is **the post** you've been waiting for.
```

I'll let you be creative writing your own posts. Just ensure you follow the above format for the metadata and content.

With these posts in place, let's install NimblePublisher so we can parse the content and build up our `Blog` context.

## Installing NimblePublisher

First, add `nimble_publisher` as a dependency. You can optionally include syntax highlighters, in this case we'll add support for highlighting Elixir and Erlang code.

In our Phoenix app, we'll add this in `mix.exs`:

```elixir
  defp deps do
    [
      ...,
      {:nimble_publisher, "~> 0.1.1"},
      {:makeup_elixir, ">= 0.0.0"},
      {:makeup_erlang, ">= 0.0.0"}
    ]
  end
```

After you've run `mix deps.get` to fetch the dependencies, you're ready to continue building the blog.

## Building the Blog context

We'll define a `Post` struct that will hold the content parsed from the files. It will expect a key for each metadata key, and also a `:date` that will be parsed from the filename. Create a `lib/nimble_school/blog/post.ex` file with this content:

```elixir
defmodule NimbleSchool.Blog.Post do
  @enforce_keys [:id, :author, :title, :body, :description, :tags, :date]
  defstruct [:id, :author, :title, :body, :description, :tags, :date]

  def build(filename, attrs, body) do
    [year, month_day_id] = filename |> Path.rootname() |> Path.split() |> Enum.take(-2)
    [month, day, id] = String.split(month_day_id, "-", parts: 3)
    date = Date.from_iso8601!("#{year}-#{month}-#{day}")
    struct!(__MODULE__, [id: id, date: date, body: body] ++ Map.to_list(attrs))
  end
end
```

The `Post` module defines the struct for the metadata and content, and also defines a `build/3` function with the logic needed to parse a file with the post contents.

With this `Post` struct in place, we can define our `Blog` context that will use NimblePublisher to parse the local files into posts. Create `lib/nimble_school/blog/blog.ex` with this content:

```elixir
defmodule NimbleSchool.Blog do
  alias NimbleSchool.Blog.Post

  use NimblePublisher,
    build: Post,
    from: Application.app_dir(:nimble_school, "priv/posts/**/*.md"),
    as: :posts,
    highlighters: [:makeup_elixir, :makeup_erlang]

  # The @posts variable is first defined by NimblePublisher.
  # Let's further modify it by sorting all posts by descending date.
  @posts Enum.sort_by(@posts, & &1.date, {:desc, Date})

  # Let's also get all tags
  @tags @posts |> Enum.flat_map(& &1.tags) |> Enum.uniq() |> Enum.sort()

  # And finally export them
  def all_posts, do: @posts
  def all_tags, do: @tags
end
```

As you can see, the `Blog` context uses NimblePublisher to build the collection of `Post` from the indicated local directory, using the syntax highlighters that we want to use.

NimblePublisher will create the `@posts` variable, which we later process to sort the posts descending by `:date` as we normally want in a blog.

We also define `@tags` by taking them from the `@posts`.

Finally, we define `all_posts/0` and `all_tags/0` that will just return what was parsed respectively.

Let's try it! Enter a console with `iex -S mix` and run:

```elixir
iex(1)> NimbleSchool.Blog.all_posts()
[
  %NimbleSchool.Blog.Post{
    author: "Jaime Iniesta",
    body: "<p>\nAwesome, this is our second post in our great blog.</p>\n",
    date: ~D[2020-11-04],
    description: "Second blog post",
    id: "exciting-news",
    tags: ["exciting", "news"],
    title: "Exciting News!"
  },
  %NimbleSchool.Blog.Post{
    author: "Jaime Iniesta",
    body: "<p>\nYes, this is <strong>the post</strong> you’ve been waiting for.</p>\n",
    date: ~D[2020-10-28],
    description: "Our first blog post is here",
    id: "hello-world",
    tags: ["hello"],
    title: "Hello World!"
  }
]

iex(2)> NimbleSchool.Blog.all_tags() 
["exciting", "hello", "news"]
```

Isn't that great? We already have all our posts parsed, with Markdown interpretation, and ready to go. Also for tags!

Now, it's important to see that NimblePublisher is taking care of parsing the files and building the `@posts` variable with all of them, and you take it from there to define the functions you need. For example, if we need a function to get the recent posts, we can define it like this:

```elixir
def recent_posts(num \\ 5), do: Enum.take(all_posts(), num)  
```

As you can see, we've avoided using `@posts` inside our new function and have used `all_posts()` instead. Otherwise, the `@posts` variable would have been expanded by the compiler twice, making a complete copy of all posts.

Let's define some more functions to have our complete blog example. We'll need to get a post by its id and also to list all the posts for a given tag. Define the following inside the `Blog` context:

```elixir
defmodule NotFoundError, do: defexception [:message, plug_status: 404]

def get_post_by_id!(id) do
  Enum.find(all_posts(), &(&1.id == id)) ||
    raise NotFoundError, "post with id=#{id} not found"
end

def get_posts_by_tag!(tag) do
  case Enum.filter(all_posts(), &(tag in &1.tags)) do
    [] -> raise NotFoundError, "posts with tag=#{tag} not found"
    posts -> posts
  end
end
```

## Serving your content

Now that we have a way to get all our posts and tags, serving them just means wiring up routes, controllers, views and templates in the usual way. For this example we'll keep it simple and just list all posts and get a post by its id. It is left as an exercise to the reader to list posts by tag and extend the layout with the recent posts.

### Routes

Define the following routes in `lib/nimble_school_web/router.ex`:

```elixir
scope "/", NimbleSchoolWeb do
  pipe_through :browser

  get "/blog", BlogController, :index
  get "/blog/:id", BlogController, :show
end
```

### Controller

Define a controller to serve the posts in `lib/nimble_school_web/controllers/blog_controller.ex`:

```elixir
defmodule NimbleSchoolWeb.BlogController do
  use NimbleSchoolWeb, :controller

  alias NimbleSchool.Blog

  def index(conn, _params) do
    render(conn, "index.html", posts: Blog.all_posts())
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.html", post: Blog.get_post_by_id!(id))
  end
end
```

### View

Create the view module where you can place the helpers needed to render the view. By now it's just:

```elixir
defmodule NimbleSchoolWeb.BlogView do
  use NimbleSchoolWeb, :view
end
```

### Template

Finally, create the HTML files to render the content. Under `lib/nimble_school_web/templates/blog/index.html.eex` define this to render the list of posts:

```html
<h1>Listing all posts</h1>

<ul style="list-style: none;">
<%= for post <- @posts do %>
  <li id="<%= post.id %>" style="margin-bottom: 3rem;">
    <h2>
      <%= link post.title, to: Routes.blog_path(@conn, :show, post)%>
    </h2>

    <p>
      <time><%= post.date %></time> by <%= post.author %>
    </p>

    <p>
      Tagged as <%= Enum.join(post.tags, ", ") %>
    </p>

    <%= raw post.description %>
  </li>
<% end %>
</ul>
```

And create `lib/nimble_school_web/templates/blog/show.html.eex` to render a single post:

```html
<%= link "← All posts", to: Routes.blog_path(@conn, :index)%>

<h1><%= @post.title %></h1>

<p>
  <time><%= @post.date %></time> by <%= @post.author %>
</p>

<p>
  Tagged as <%= Enum.join(@post.tags, ", ") %>
</p>

<%= raw @post.body %>
```

### Browse your posts

You're ready to go!

Fire up the web server with `iex -S mix phx.server` and visit [http://localhost:4000/blog](http://localhost:4000/blog) to see your brand new blog in action!

## Extending metadata

NimblePublisher is very flexible when it comes to define our posts structure and metadata. For example, let's say we want to add a `:published` key to flag the posts, and only show the ones where this is `true`.

We just need to add the `:published` key to the `Post` struct, and also to the posts metadata. In the `Blog` module we can define:

```elixir
def all_posts, do: @posts

def published_posts, do: Enum.filter(all_posts(), &(&1.published == true))

def recent_posts(num \\ 5), do: Enum.take(published_posts(), num)
```

## Syntax highlighting

NimblePublisher uses the Makeup library for syntax highlighting. You will need to generate the CSS classes for the style you prefer from one defined [here](https://hexdocs.pm/makeup/Makeup.Styles.HTML.StyleMap.html).

For example, we're going to use the `:tango_style`. From a `iex -S mix` session, call:

```elixir
Makeup.stylesheet(:tango_style, "makeup") |> IO.puts()
```

And place the generated CSS classes in your stylesheets.

## Serving other content

NimblePublisher can also be used to build up other publishing contexts with a different structure.

For example, we could manage a collection of Frequently Asked Questions (FAQs), in this case we probably don't need dates, or authors, and a simpler structure with `:id`, `:question` and `:answer` would be just great.

We could place our content files on a different directory structure, for example:

```
/priv/faqs/is-there-a-free-trial.md
/priv/faqs/when-did-it-start.md
```

And we could define our `Faq` struct and build function in `lib/nimble_school/faqs/faq.ex` like this:

```elixir
defmodule NimbleSchool.Faqs.Faq do
  @enforce_keys [:id, :question, :answer]
  defstruct [:id, :question, :answer]

  def build(filename, attrs, body) do
    [id] = filename |> Path.rootname() |> Path.split() |> Enum.take(-1)
    struct!(__MODULE__, [id: id, answer: body] ++ Map.to_list(attrs))
  end
end
```

Our `Faqs` context in `lib/nimble_school/faqs/faqs.ex` would be something like:

```elixir
defmodule NimbleSchool.Faqs do
  alias NimbleSchool.Faqs.Faq

  use NimblePublisher,
    build: Faq,
    from: Application.app_dir(:nimble_school, "priv/faqs/*.md"),
    as: :faqs

  # The @faqs variable is first defined by NimblePublisher.
  # Let's further modify it by sorting all posts by ascending question
  @faqs Enum.sort_by(@faqs, & &1.question)

  # And finally export them
  def all_faqs, do: @faqs
end
```

## Source code for example blog

You can find the code for this example in [https://github.com/jaimeiniesta/nimble_school](https://github.com/jaimeiniesta/nimble_school)
