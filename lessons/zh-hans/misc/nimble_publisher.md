%{
  version: "1.0.2",
  title: "NimblePublisher",
  excerpt: """
  [NimblePublisher](https://github.com/dashbitco/nimble_publisher) 是一个基于文件系统的轻量级发布引擎，支持 Markdown 解析和语法高亮。
  """
}
---

## 为什么使用 NimblePublisher？

NimblePublisher 支持利用 Markdown 语法，从本地文件进行内容的发布。 典型的用法包括构建一个博客系统。

Dashbit 将他们博客的大部分代码在这个库中进行了封装，他们在 [Welcome to our blog: how it was made!](https://dashbit.co/blog/welcome-to-our-blog-how-it-was-made) 中进行了详细描述。这篇文章也解释了，他们为什么会选择从本地文件中解析内容，而不是使用数据库或更复杂的 CMS。

## 构建博客内容

让我们开始建立我们的博客。在这个示例里，我们会使用 Phoenix 构建应用程序，不过 Phoenix 并不是绝对必要的。因为 NimblePublisher 只关心本地文件的解析，你可以将它用在任何 Elixir 应用程序中。

首先，让我们从创建一个 Phoenix 应用开始。我们将它命名为 NimbleSchool，注意在创建时我们不需要生成 Ecto 文件：

```shell
mix phx.new nimble_school --no-ecto
```

现在，可以增加一些文章了。我们需要创建一些本地目录用于容纳文章，以年份为顺序对这些目录进行组织：

```
/priv/posts/YEAR/MONTH-DAY-ID.md
```

比如说，我们可以从这两篇文章开始：

```
/priv/posts/2020/10-28-hello-world.md
/priv/posts/2020/11-04-exciting-news.md
```

一篇典型的文章一般以元数据部分开头，其后为 Markdown 语法的正文，两者之间需要使用 `---` 分隔开，类似于这样：

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

只要遵守了以上元数据和内容规范，你也可以写出丰富多彩的博客文章。

在完成了相关文章文件的创建之后，我们就可以开始安装 NimblePublisher 来解析文章内容，并构建 `Blog` 管理器。

## 安装 NimblePublisher

首先，将 `nimble_publisher` 加入项目依赖。你也可以选择在项目依赖中加入可选的语法高亮工具，在这里我们引入了 Elixir 和 Erlang 的语法高亮支持。

在我们的 Phoenix 应用中，我们将以下依赖项加入 `mix.exs` 文件：

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

在运行 `mix deps.get` 获取到这些依赖项之后，我们就可以开始实际构建博客了！

## 构建 Blog 管理器

我们使用 `Post` 结构体来储存从本地文件获取的文章内容。对于文章元数据键值对中的每一个键，它都应包含相同的键，以及额外的 `:date` 代表从文件名获取的日期信息。创建 `lib/nimble_school/blog/post.ex` 文件并包含以下内容：

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

`Post` 模块定义了元数据和内容的结构体，还定义了一个 `build/3` 函数，其中包含相关逻辑，可以从本地文件解析出博客文章。

利用这个 `Post` 结构体，我们可以定义 `Blog` 管理器，它可以利用 NimblePublisher 将本地文件解析为博客文章。在 `lib/nimble_school/blog/blog.ex` 文件中增加以下内容：

```elixir
defmodule NimbleSchool.Blog do
  alias NimbleSchool.Blog.Post

  use NimblePublisher,
    build: Post,
    from: Application.app_dir(:nimble_school, "priv/posts/**/*.md"),
    as: :posts,
    highlighters: [:makeup_elixir, :makeup_erlang]

  # @posts 变量原本在 NimblePublisher 中定义
  # 我们对它进行修改，以实现将文章按日期降序排列
  @posts Enum.sort_by(@posts, & &1.date, {:desc, Date})

  # 我们也可以获取所有的文章标签
  @tags @posts |> Enum.flat_map(& &1.tags) |> Enum.uniq() |> Enum.sort()

  # 最后导出使用的变量
  def all_posts, do: @posts
  def all_tags, do: @tags
end
```

很明显，`Blog` 管理器依赖 NimblePublisher，在指定的本地目录构建 `Post` 结构体的文章集合，同时也支持了我们需要的语法高亮。

NimblePublisher 将会创建 `@posts` 变量，稍后它会被我们的管理器重写，以支持将文章按 `:date` 降序排列。

我们也定义了从 `@posts` 中抽取出的 `@tags` 变量。

最后，我们定义了两个方法 `all_posts/0` 和 `all_tags/0`，以返回解析好的这两个变量。

现在可以尝试解析文章了！我们可以使用 `iex -S mix` 进入一个命令行环境，并执行以下内容：

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

看起来很不错，我们的所有文章都被成功以 Markdown 解析，包括标签也被正确提取。

需要注意的是，文章的解析由 NimblePublisher 实现，它提供了 `@posts` 变量。实际上，你可以利用这个变量来构建你需要的函数。例如，如果我们需要定义函数来获取最近的文章，我们可以这样写：

```elixir
def recent_posts(num \\ 5), do: Enum.take(all_posts(), num)  
```

需要注意的是，在我们定义的函数中，我们避免了使用 `@posts` 变量，而是使用 `all_posts()` 函数作为替代。因为对于 `@posts` 的引用将会被编译器二次展开，从而引起一次对所有文章的高代价复制。

我们可以定义更多函数来完成我们的博客实现。我们可以通过 id 来获取某篇特定文章，或者根据标签来获取相应的文章集合。为了实现这些功能，我们在 `Blog` 管理器中定义以下内容：

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

## 提供内容服务

现在我们有了获取所有文章和标签的方法，为它们提供服务包括以通常的方式连接路由、控制器、视图和模板。在这里例子中，我们将尽可能简化，只包括列出所有文章和通过 id 获取文章的功能。按标签列出文章，以及使用最近的文章填充视图的功能，将留给读者作为练习。

### 路由

在 `lib/nimble_school_web/router.ex` 中定义以下路由：

```elixir
scope "/", NimbleSchoolWeb do
  pipe_through :browser

  get "/blog", BlogController, :index
  get "/blog/:id", BlogController, :show
end
```

### 控制器

在 `lib/nimble_school_web/controllers/blog_controller.ex` 中定义以下控制器，以提供内容服务：

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

### 视图

在视图中，你可以构建工具函数，用于辅助视图的渲染。但现在它只会被简单实现为：

```elixir
defmodule NimbleSchoolWeb.BlogView do
  use NimbleSchoolWeb, :view
end
```

### 模板

最后，我们需要创建对应的 HTML 文件以渲染内容。在 `lib/nimble_school_web/templates/blog/index.html.eex` 下定义以下内容，以渲染文章列表页面：

```html
<h1>Listing all posts</h1>

<%= for post <- @posts do %>
  <div id="<%= post.id %>" style="margin-bottom: 3rem;">
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
  </div>
<% end %>
```

在这之后，创建 `lib/nimble_school_web/templates/blog/show.html.eex` 以实现单篇文章页面的渲染：

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

### 欣赏你的博客

我们已经完成了所有的准备工作！

执行 `iex -S mix phx.server` 以启动网页服务器。现在可以访问 [http://localhost:4000/blog](http://localhost:4000/blog) 来看看你的新博客了！

## 拓展元数据

当进行文章结构体和元数据定义时，NimblePublisher 可以非常灵活地进行拓展。比如，让我们对文章增加一个 `:published` 键来标识文章是否已经发布，并且只展示这个键为 `true` 的文章。

我们只需要在 `Post` 结构体和每篇文章的元数据中增加 `:published` 键即可。在 `Blog` 模块中，我们可以进行如下修改：

```elixir
def all_posts, do: @posts

def published_posts, do: Enum.filter(all_posts(), &(&1.published == true))

def recent_posts(num \\ 5), do: Enum.take(published_posts(), num)
```

## 语法高亮

NimblePublisher 使用 Makeup 库实现语法高亮功能。你可以从 [这里](https://hexdocs.pm/makeup/Makeup.Styles.HTML.StyleMap.html) 找一个喜欢的样式，并生成对应的 CSS 类。

如果我们想采用 `:tango_style` 样式。从 `iex -S mix` 命令行环境中，执行：

```elixir
Makeup.stylesheet(:tango_style, "makeup") |> IO.puts()
```

然后将自动生成的  CSS 类放在你的样式表中。

## 拓展内容服务

NimblePublisher 也支持使用多个管理器，其中每个管理器都具有各自的结构体。

比如说，我们可以设计一个常见问题（ FAQs ）的集合，对于这个栏目，我们不需要日期和作者，因此使用一个简单的结构体，仅包含 `:id`、`:question` 和 `:answer` 是比较合适的。

我们需要把相应的内容文件放在另一个文件夹下，例如：

```
/priv/faqs/is-there-a-free-trial.md
/priv/faqs/when-did-it-start.md
```

接下来，我们将定义 `Faq` 结构体，并实现相应的 build 函数，在 `lib/nimble_school/faqs/faq.ex` 中定义以下内容：

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

`Faqs` 管理器将定义在 `lib/nimble_school/faqs/faqs.ex` 中：

```elixir
defmodule NimbleSchool.Faqs do
  alias NimbleSchool.Faqs.Faq

  use NimblePublisher,
    build: Faq,
    from: Application.app_dir(:nimble_school, "priv/faqs/*.md"),
    as: :faqs

  # @faqs 变量原本在 NimblePublisher 中定义
  # 我们对它进行修改，以实现将问题按名字降序排列
  @faqs Enum.sort_by(@faqs, & &1.question)

  # 最后导出使用的变量
  def all_faqs, do: @faqs
end
```

## 示例博客源码

你可以在 [https://github.com/jaimeiniesta/nimble_school](https://github.com/jaimeiniesta/nimble_school) 这里找到本教程使用的所有源码。