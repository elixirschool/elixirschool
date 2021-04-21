%{
  version: "1.0.2",
  title: "NimblePublisher",
  excerpt: """
  Η [NimblePublisher](https://github.com/dashbitco/nimble_publisher) είναι μια μινιμαλιστική μηχανή δημοσιεύσεων βασισμένη σε αρχεία με υποστήριξη για κώδικα Markdown και επισήμανση κώδικα.
  """
}
---

## Γιατί να χρησιμοποιήσουμε την NimblePublisher;

Η NimblePublisher είναι μια απλή βιβλιοθήκη σχεδιασμένη για δημοσιεύσεις περιεχομένου επεξεργάζοντας τοπικά αρχεία που χρησιμοποιούν συντακτικό Markdown.
Μια τυπική περίπτωση θα ήταν η δημιουργία ενός blog.

Αυτή η βιβλιοθήκη ενσωματώνει τον περισσότερο από τον κώδικα που η Dashbit χρησιμοποιεί για το ίδιο της το blog, όπως παρουσιάζεται στο άρθρο τους [Welcome to our blog: how it was made!](https://dashbit.co/blog/welcome-to-our-blog-how-it-was-made) - όπου και εξηγούν γιατί επέλεξαν να επεξεργάζονται το περιεχόμενο από τοπικά αρχεία αντί να χρησιμοποιήσουν μια βάση δεδομένων ή ένα πιο περίπλοκο CMS.

## Δημιουργώντας το περιεχόμενό σας

Ας χτίσουμε το δικό μας blog.
Στο παράδειγμά μας, χρησιμοποιούμε μια εφαρμογή Phoenix αλλά αυτό δεν είναι απαραίτητο.
Καθώς η NimblePublisher φροντίζει την επεξεργασία των τοπικών αρχείων, μπορείτε να την χρησιμοποιήσετε σε οποιαδήποτε εφαρμογή Elixir.

Αρχικά, ας δημιουργήσουμε μια νέα εφαρμογή Phoenix για το παράδειγμά μας.
Θα την ονομάσουμε NimbleSchool, και θα τη δημιουργήσουμε με την παρακάτω εντολή, καθώς δεν χρειαζόμαστε το Ecto:

```shell
mix phx.new nimble_school --no-ecto
```

Τώρα, ας προσθέσουμε μερικά άρθρα.
Θα χρειαστεί να δημιουργήσουμε ένα φάκελο στον οποίο θα περιλαμβάνονται τα άρθρα μας.
Θα τα κρατήσουμε οργανωμένα ανά χρόνο σε αυτή τη μορφή:

```
/priv/posts/YEAR/MONTH-DAY-ID.md
```

Για παράδειγμα, ας ξεκινήσουμε με αυτά τα δύο άρθρα:

```
/priv/posts/2020/10-28-hello-world.md
/priv/posts/2020/11-04-exciting-news.md
```

Ένα τυπικό άρθρο blog θα γραφτεί σε συντακτικό Markdown, με ένα τομέα μεταδεδομένων στην κορυφή, και το περιεχόμενο παρακάτω χωρισμένο με `---` ως εξής:

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

Θα σας αφήσω να είστε δημιουργικοί με τα δικά σας άρθρα.
Απλά βεβαιωθείτε ότι θα ακολουθήσετε το παραπάνω φορμάτ για τα μεταδεδομένα και το περιεχόμενο.

Με αυτά τα άρθρα στη θέση τους, ας εγκαταστήσουμε την NimblePublisher ώστε να επεξεργαστούμε το περιεχόμενο και να χτίσουμε το `Blog` context μας.

## Εγκαθιστώντας την NimblePublisher

Αρχικά, προσθέστε την `nimble_publisher` σαν εξάρτηση.
Μπορείτε προαιρετικά να συμπεριλάβετε επισημαντές κώδικα, σε αυτή την περίπτωση θα προσθέσουμε υποστήριξη για επισήμανση κώδικα Elixir και Erlang.

Στην εφαρμογή μας Phoenix, θα προσθέσουμε αυτό στο `mix.exs`:

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

Αφού τρέξετε την `mix deps.get` για να φέρετε τις εξαρτήσεις, είστε έτοιμοι να συνεχίσετε με τη δημιουργία του blog.

## Χτίζοντας το Blog context

Θα ορίσουμε μια δομή `Post` η οποία θα κρατάει το περιεχόμενο που επεξεργάζεται από τα αρχεία.
Θα περιμένει ένα κλειδί για κάθε κλειδί μεταδεδομένων, και επίσης ένα `:date` το οποίο θα επεξεργαστεί από το όνομα αρχείου.
Δημιουργήστε ένα αρχείο `lib/nimble_school/blog/post.ex` με το παρακάτω περιεχόμενο:

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

Η ενότητα `Post` ορίζει τη δομή για τα μεταδεδομένα και το περιεχόμενο, και επίσης ορίζει μια συνάρτηση `build/3` με τη λογική που χρειάζεται για να επεξεργαστεί ένα αρχείο με τα περιεχόμενα του άρθρου.

Με τη δομή `Post` στη θέση της, μπορούμε να ορίσουμε το `Blog` context μας το οποίο θα χρησιμοποιήσει την NimblePublisher για να επεξεργαστεί τα τοπικά αρχεία σε άρθρα.
Δημιουργήστε το αρχείο `lib/nimble_school/blog/blog.ex` με αυτό το περιεχόμενο:

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

Όπως μπορείτε να δείτε, το `Blog` context χρησιμοποιεί την NimblePublisher για να χτίσει τη συλλογή των `Post` από το δεδομένο τοπικό φάκελο, χρησιμοποιώντας τους επισημαντές κώδικα που θέλουμε.

Η NimblePublisher θα δημιουργήσει τη μεταβλητή `@posts`, την οποία αργότερα θα επεξεργαστούμε για να ταξινομήσουμε τα άρθρα με φθίνουσα σειρά κατά την `:date` όπως κανονικά θέλουμε σε ένα blog.

Θα ορίσουμε επίσης `@tags` διαβάζοντάς τα από τα `@posts`.

Τελικά, θα ορίσουμε τις `all_posts/0` και `all_tags/0` οι οποίες θα επιστρέφουν ότι επεξεργάστηκε αντίστοιχα.

Ας τις δοκιμάσουμε!
Ανοίξτε μια κονσόλα με την `iex -S mix` και τρέξτε:
 
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

Δεν είναι φοβερό;
Ήδη έχουμε όλα τα άρθρα μας επεξεργασμένα, αλλαγμένα βάσει του συντακτικού Markdown και έτοιμα.
Το ίδιο έχει συμβεί με τις ετικέτες!

Τώρα, είναι σημαντικό να δείτε ότι η NimblePublisher έχει φροντίσει την επεξεργασία αρχείων και το χτίσιμο της μεταβλητής `@posts` με όλα αυτά, και εσείς λαμβάνετε δράση από εκεί και πέρα στο να ορίσετε τις συναρτήσεις που θέλετε.
Για παράδειγμα, αν θέλουμε μια συνάρτηση για να παίρνουμε τα πρόσφατα άρθρα, μπορούμε να την ορίσουμε ώς εξής:

```elixir
def recent_posts(num \\ 5), do: Enum.take(all_posts(), num)  
```

Όπως μπορείτε να δείτε, αποφύγαμε να χρησιμοποιήσουμε την `@posts` μέσα στη νέα μας συνάρτηση και αντ' αυτού χρησιμοποιήσαμε την συνάρτηση `all_posts()`.
Διαφορετικά, η μεταβλητή `@posts` θα είχε ανοιχθεί από τον μεταγλωττιστή δύο φορές, κάνοντας αντίστοιχα δύο αντίγραφα όλων των άρθρων μας.

Ας ορίσουμε μερικές ακόμα συναρτήσεις για να έχουμε ένα πλήρες παράδειγμα blog.
Θα χρειαστεί να βρούμε ένα άρθρο από το id του και επίσης να πάρουμε μια λίστα άρθρων για μια δεδομένη ετικέτα.
Ορίστε τα παρακάτω μέσα στο `Blog` context:

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

## Παρουσιάζοντας το περιεχόμενο σας

Τώρα που έχουμε ένα τρόπο να πάρουμε όλα τα άρθρα και τις ετικέτες μας, η παρουσίασή τους απλά σημαίνει η σύνδεση διαδρομών, χειριστών, προβολών και προτύπων με το γνωστό τρόπο.
Για αυτό το παράδειγμα θα μείνουμε στα απλά και απλά θα προβάλουμε μια λίστα όλων των άρθρων και θα δούμε ένα άρθρο από το id του.
Μένει σαν άσκηση στον αναγνώστη να πάρει μια λίστα άρθρων από την ετικέτα και να επεκτείνετε τη δομή με τα πρόσφατα άρθρα.

### Διαδρομές

Ορίστε τις παρακάτω διαδρομές στο `lib/nimble_school_web/router.ex`:

```elixir
scope "/", NimbleSchoolWeb do
  pipe_through :browser

  get "/blog", BlogController, :index
  get "/blog/:id", BlogController, :show
end
```

### Χειριστής

Ορίστε έναν χειριστή για να προβάλετε τα άρθρα στο `lib/nimble_school_web/controllers/blog_controller.ex`:

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

### Προβολή

Δημιουργήστε την ενότητα προβολής όπου μπορείτε να τοποθετήσετε τις βοηθητικές συναρτήσεις για την προβολή.
Ως τώρα είναι απλά:

```elixir
defmodule NimbleSchoolWeb.BlogView do
  use NimbleSchoolWeb, :view
end
```

### Πρότυπο

Τελικά, δημιουργήστε τα HTML αρχεία για να προβάλετε το περιεχόμενο.
Στο `lib/nimble_school_web/templates/blog/index.html.eex` γράψτε το παρακάτω για να δείξετε μια λίστα άρθρων:

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

Και δημιουργήστε το `lib/nimble_school_web/templates/blog/show.html.eex` για να προβάλλετε ένα μοναδικό άρθρο:

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

### Περιηγηθείτε στα άρθρα σας!

Είστε έτοιμοι!

Ανοίξτε τον εξυπηρετητή web σας με την `iex -S mix phx.server` και επισκευθείτε την τοποθεσία [http://localhost:4000/blog](http://localhost:4000/blog) για να δείτε το νέο σας blog σε δράση!

## Επεκτείνοντας τα μεταδεδομένα

Η NimblePublisher είναι πολύ ευέλικτη σε ότι έχει να κάνει με τον ορισμό της δομής άρθρων και μεταδεδομένων.
Για παράδειγμα, ας πούμε ότι θέλουμε να προσθέσουμε ένα κλειδί `:published` για να μαρκάρουμε τα άρθρα μας και να προβάλλουμε μόνο όσα το έχουν στην τιμή `true`.

Απλά πρέπει να προσθέσουμε το κλειδί `:published` στη δομή μας `Post` και επίσης στα μεταδεδομένα των άρθρων.
Στην ενότητα `Blog` μπορούμε να ορίσουμε:

```elixir
def all_posts, do: @posts

def published_posts, do: Enum.filter(all_posts(), &(&1.published == true))

def recent_posts(num \\ 5), do: Enum.take(published_posts(), num)
```

## Επισήμανση Συντακτικού

Η NimblePublisher χρησιμοποιεί τη βιβλιοθήκη Makeup για επισήμανση συντακτικού.
Θα χρειαστεί να παράξετε τις κλάσεις CSS για το στυλ που επιθυμείτε από αυτά που ορίζονται [εδώ](https://hexdocs.pm/makeup/Makeup.Styles.HTML.StyleMap.html).

Για παράδειγμα, θα χρησιμοποιήσουμε το `:tango_style`.
Από μια συνεδρία `iex -S mix`, καλέστε την:

```elixir
Makeup.stylesheet(:tango_style, "makeup") |> IO.puts()
```

Και τοποθετήστε τις παραγόμενες κλάσεις CSS στα στυλ σας.

## Προβάλλοντας άλλο περιεχόμενο

Η NimblePublisher μπορεί να χρησιμοποιηθεί για να χτίσει άλλου είδους περιεχόμενο με παρόμοια δομή.

Για παράδειγμα, θα μπορούσαμε να χειριστούμε μια συλλογή από Συχνές Ερωτήσεις (FAQs), σε αυτή την περίπτωση πιθανότατα δεν θα χρειαστούμε ημερομηνίες ή συγγραφείς αλλά μια πιο απλή δομή με τα πεδία `:id`, `:question`, και `:answer` θα ήταν εξαιρετική.

Θα μπορούσαμε να τοποθετήσουμε τα αρχεία περιεχομένου μας σε μια διαφορετική δομή φακέλων, για παράδειγμα:

```
/priv/faqs/is-there-a-free-trial.md
/priv/faqs/when-did-it-start.md
```

Και να ορίσουμε τη δομή μας `Faq` με τη συνάρτησή μας build στο `lib/nimble_school/faqs/faq.ex` ως εξής:

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

Το `Faqs` context μας στο `lib/nimble_school/faqs/faqs.ex` θα είναι κάτι σαν αυτό:

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

## Πηγαίος κώδικας για το παράδειγμα blog

Μπορείτε να βρείτε τον κώδικα για αυτό το παράδειγμα στο [https://github.com/jaimeiniesta/nimble_school](https://github.com/jaimeiniesta/nimble_school)
