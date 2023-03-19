%{
  version: "1.0.2",
  title: "NimblePublisher",
  excerpt: """
  [NimblePublisher](https://github.com/dashbitco/nimble_publisher)は、Markdownをサポートし、コードハイライトを備えた、最小のファイルシステムベースの出版エンジンです。
  """
}
---

## なぜNimblePublisherを利用するのか

NimblePublisherは、Markdown構文のローカルファイルからパースしたコンテンツを公開するために設計されたシンプルなライブラリです。典型的な使用例としては、ブログの構築が挙げられます。

このライブラリは、Dashbit社が自社のブログに使用しているコードのほとんどをカプセル化しています。Dashbit社のポスト[Welcome to our blog: how it was made!](https://dashbit.co/blog/welcome-to-our-blog-how-it-was-made)で紹介されており、データベースや複雑なCMSを使用する代わりに、ローカルファイルからコンテンツをパースすることを選択した理由が説明されています。

## コンテンツを作成する

自身のブログを作ってみましょう。この例ではPhoenixアプリケーションを使用していますが、Phoenixは必須ではありません。NimblePublisherはローカルファイルのパースのみ行うので、どんなElixirアプリケーションでも使用できます。

まず、新しいPhoenixアプリケーションを作ってみましょう。名前をNimbleSchoolとし、Ectoを必要としないため、次のように作成します。

```shell
mix phx.new nimble_school --no-ecto
```

それでは、投稿を追加してみましょう。まず、投稿を格納するディレクトリを作成する必要があります。このような形式で年ごとに管理します。

```
/priv/posts/YEAR/MONTH-DAY-ID.md
```

たとえば、これら2つの投稿から始めてみます。

```
/priv/posts/2020/10-28-hello-world.md
/priv/posts/2020/11-04-exciting-news.md
```

典型的なブログ投稿はMarkdownの構文で書かれており、トップにはメタデータのセクションがあり、その下にはコンテンツが `---` で区切られています。

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

あとは創造的に自分の投稿を書くことができます。ただ、メタデータとコンテンツのフォーマットを守ってください。

これらの投稿ができたら、NimblePublisherをインストールして、コンテンツをパースし、 `Blog` コンテキストを構築しましょう。

## NimblePublisherをインストールする

まず、 `nimble_publisher` を依存関係として追加します。任意でシンタックスハイライターを含めることができます。ここでは、ElixirとErlangのコードハイライトをサポートするライブラリを追加します。

Phoenixアプリでは、 `mix.exs` にこれを追加します。

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

`mix deps.get` を実行して依存関係を取得したら、ブログの構築を続ける準備が整いました。

## Blogコンテキストを構築する

ここでは、ファイルからパースされたコンテンツを格納する `Post` 構造体を定義します。この構造体には、各メタデータのキーと、ファイル名からパースされる `:date` が必要です。次のように `lib/nimble_school/blog/post.ex` ファイルを作成します。

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

`Post` モジュールは、メタデータとコンテンツの構造体を定義し、投稿のコンテンツを含むファイルをパースするのに必要なロジックを持つ `build/3` 関数も定義します。

この `Post` 構造体をもとに、NimblePublisherを使ってローカルファイルをパースして投稿にする `Blog` コンテキストを定義できます。次のように `lib/nimble_school/blog/blog.ex` を作成します。

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

ご覧のとおり、 `Blog` コンテキストでは、NimblePublisherを使って、指定したローカルディレクトリから、使いたいシンタックスハイライターを使って、 `Post` のコレクションを構築しています。

NimblePublisherは `@posts` という変数を作成し、あとでこれを処理して、 `:date` 降順に記事をソートします。これはブログで通常必要とされます。

また、 `@tags` も `@posts` から取得して定義します。

最後に、 `all_posts/0` と `all_tags/0` を定義して、それぞれパースされたものを返すようにしています。

では早速やってみましょう。コンソールで `iex -S mix` と入力して実行してみてください。

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

素晴らしいと思いませんか？すでにすべての投稿がMarkdownの解釈をもとにパースされ、準備が整っています。タグも同様です!

ここで重要なのは、NimblePublisherがファイルをパースして、それらすべてを含む `@posts` 変数を構築していることで、あなたはそこから必要な関数を定義します。たとえば、最近の投稿を取得する関数が必要な場合は、次のように定義します。

```elixir
def recent_posts(num \\ 5), do: Enum.take(all_posts(), num)
```

ご覧のように、新しい関数の中では `@posts` を使わず、代わりに `all_posts()` を使っています。そうしないと、 `@posts` 変数がコンパイラによって2回展開され、すべての投稿の完全なコピーが作成されてしまうからです。

完全なブログの例を作るために、さらにいくつかの関数を定義してみましょう。idでポストを取得したり、指定したタグのポストをすべてリストアップする必要があります。以下の関数を `Blog` コンテキストの中で定義します。

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

## コンテンツを提供する

すべての投稿とタグを取得する方法ができたので、あとはルート、コントローラー、ビュー、テンプレートを通常の方法で繋ぐだけです。この例では、シンプルにすべての投稿をリストアップし、IDで投稿を取得することにします。タグで投稿を一覧表示したり、最近の投稿でレイアウトを拡張したりすることは、読者の課題とします。

### ルート

`lib/nimble_school_web/router.ex` に次のようにルートを定義します。

```elixir
scope "/", NimbleSchoolWeb do
  pipe_through :browser

  get "/blog", BlogController, :index
  get "/blog/:id", BlogController, :show
end
```

### コントローラー

投稿を提供するために、 `lib/nimble_school_web/controllers/blog_controller.ex` にコントローラーを定義します。

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

### ビュー

ビューモジュールを作成して、ビューのレンダリングに必要なヘルパーを配置します。今回は次のようにします。

```elixir
defmodule NimbleSchoolWeb.BlogView do
  use NimbleSchoolWeb, :view
end
```

### テンプレート

最後に、コンテンツをレンダリングするためのHTMLファイルを作成します。投稿の一覧をレンダリングするために、 `lib/nimble_school_web/templates/blog/index.html.eex` を次のように定義します。

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

そして、単一の投稿をレンダリングするために、 `lib/nimble_school_web/templates/blog/show.html.eex` を作成します。

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

### 投稿を閲覧する

これで準備は整いました！

`iex -S mix phx.server` でウェブサーバーを起動し、[http://localhost:4000/blog](http://localhost:4000/blog)にアクセスして、新しいブログが実際に動いているのを見てみましょう！

## メタデータを拡張する

NimblePublisherは、投稿の構造やメタデータの定義に関して非常に柔軟です。たとえば、 `:published` キーを追加して投稿にフラグを立て、それが `true` であるものだけを表示したいとします。

そのためには、 `:published` キーを `Post` 構造体に追加し、投稿のメタデータにも追加する必要があります。 `Blog` モジュールでは、次のように定義します。

```elixir
def all_posts, do: @posts

def published_posts, do: Enum.filter(all_posts(), &(&1.published == true))

def recent_posts(num \\ 5), do: Enum.take(published_posts(), num)
```

## シンタックスハイライト

NimblePublisherでは、シンタックスハイライトにMakeupライブラリを使用しています。[こちら](https://hexdocs.pm/makeup/Makeup.Styles.HTML.StyleMap.html)で定義されているものから、好みのスタイルのCSSクラスを生成する必要があります。

たとえば、ここでは `:tango_style` というスタイルを使います。 `iex -S mix` のセッションから、次のように呼び出します。

```elixir
Makeup.stylesheet(:tango_style, "makeup") |> IO.puts()
```

そして、生成されたCSSクラスをスタイルシートに配置してください。

## 他のコンテンツを提供する

NimblePublisherは、異なる構造を持つ他のコンテキストの出版にも使用できます。

たとえば、よくある質問（FAQ）を集めて管理したいとします。この場合、日付や著者は必要なく、 `:id` 、 `:question` 、 `:answer` のシンプルな構造が適しています。

また、コンテンツファイルを別のディレクトリ構造に配置することもできます。たとえば、次の通りです。

```
/priv/faqs/is-there-a-free-trial.md
/priv/faqs/when-did-it-start.md
```

そして、 `lib/nimble_school/faqs/faq.ex` で `Faq` 構造体とbuild関数を次のように定義します。

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

`lib/nimble_school/faqs/faqs.ex` の `Faqs` コンテキストは次のようになります。

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

## サンプルのソースコード

このサンプルのコードは[https://github.com/jaimeiniesta/nimble_school](https://github.com/jaimeiniesta/nimble_school)に掲載されています。
