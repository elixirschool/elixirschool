%{
  version: "1.0.1",
  title: "NimblePublisher",
  excerpt: """
  [NimblePublisher](https://github.com/dashbitco/nimble_publisher) es un motor de publicación minimalista basado en ficheros con soporte para Markdown y coloreado de sintaxis.
  """
}
---

## ¿Por qué usar NimblePublisher?

NimblePublisher es una librería sencilla diseñada para publicar contenido parseado de ficheros locales que usan sintaxis Markdown. Un ejemplo de uso típico sería la publicación de un blog.

Esta librería encapsula la mayoría del código que Dashbit usa para su propio blog, como se explicó en su post [Welcome to our blog: how it was made!](https://dashbit.co/blog/welcome-to-our-blog-how-it-was-made) - y donde explican por qué prefirieron parsear el contenido de archivos locales en lugar de usar una base de datos o un CMS más complejo.

## Crea tu contenido

Vamos a crear nuestro propio blog. En nuestro ejemplo, estamos usando una aplicación Phoenix pero Phoenix no es un requisito. Ya que NimblePublisher sólo se encarga de parsear el contenido de los ficheros locales, puedes usarlo en cualquier aplicación Elixir.

En primer lugar, vamos a crear una aplicación Phoenix para nuestro ejemplo. La llamaremos NimbleSchool, y la crearemos de esta manera porque no necesitamos Ecto allá donde vamos:

```
mix phx.new nimble_school --no-ecto
```

Ahora, vamos a añadir algunos posts. Necesitamos comenzar creando un directorio que contendrá nuestros posts. Los tendremos organizados por año en este formato:

```
/priv/posts/AÑO/MES-DIA-ID.md
```

Por ejemplo, comenzamos con estos dos posts:

```
/priv/posts/2020/10-28-hello-world.md
/priv/posts/2020/11-04-exciting-news.md
```

Un post típico estará escrito usando la sintaxis Markdown, con una sección de metadatos en la parte superior, y el contenido debajo separado por `---`, de esta manera:

```
%{
  title: "Hello World!",
  author: "Jaime Iniesta",
  tags: ~w(hello),
  description: "Our first blog post is here"
}
---
Si, este es **el post** que estabas esperando.
```

Te dejaré que seas creativo escribiendo tus propios posts. Simplemente asegúrate de seguir el formato de arriba para los metadatos y el contenido.

Con estos posts en su sitio, vamos a instalar NimblePublisher para así poder parsear el contenido y construir nuestro contexto `Blog`.

## Cómo instalar NimblePublisher

En primer lugar, añade `nimble_publisher` como dependencia. Opcionalmente puedes incluir coloreadores de sintaxis, en este caso añadiremos soporte para colorear código Elixir y Erlang.

En nuestra aplicación Phoenix, añadiremos esto en `mix.exs`:

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

Después de ejecutar `mix deps.get` para instalar las dependencias, estarás listo para continuar construyendo el blog.

## Cómo construir el contexto Blog

Vamos a definir un struct `Post` para contener el contenido parseado de los ficheros. Va a esperar una clave para cada clave de los metadatos, y también una clave `:date` para la fecha, que será parseada del nombre de fichero. Crea un fichero `lib/nimble_school/blog/post.ex` con este contenido:

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

El módulo `Post` define el struct para los metadatos y contenido, y también define una función `build/3` para la lógica necesaria para parsear un fichero con los contenidos del post.

Con esta struct `Post` definida, podemos definir nuestro contexto `Blog` que usará NimblePublisher para convertir los ficheros locales en posts. Crea `lib/nimble_school/blog/blog.ex` con este contenido:

```elixir
defmodule NimbleSchool.Blog do
  alias NimbleSchool.Blog.Post

  use NimblePublisher,
    build: Post,
    from: Application.app_dir(:nimble_school, "priv/posts/**/*.md"),
    as: :posts,
    highlighters: [:makeup_elixir, :makeup_erlang]

  # La variable @posts es definida primero por NimblePublisher.
  # Vamos a modificarla más para ordenar todos los posts por fecha descendiente.
  @posts Enum.sort_by(@posts, & &1.date, {:desc, Date})

  # También definimos las tags
  @tags @posts |> Enum.flat_map(& &1.tags) |> Enum.uniq() |> Enum.sort()

  # Y finalmente lo exportamos todo
  def all_posts, do: @posts
  def all_tags, do: @tags
end
```

Como puedes ver, el contexto `Blog` usa NimblePublisher para construir la colección de `Post` a partir del directorio local indicado, empleando los coloreadores de sintaxis que queramos usar.

NimblePublisher creará la variable `@posts`, que más adelante procesamos para ordenar los posts de manera descendente por `:date` como normalmente queremos en un blog.

También definiremos `@tags` sacándolas de los `@posts`.

Por último, definimos `all_posts/0` y `all_tags/0` que simplemente devolverán lo que acabamos de parsear.

¡Vamos a probarlo! Entra en una consola con `iex -S mix` y ejecuta:
 
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

¿No es genial? Ya tenemos todos nuestros posts parseados, con la sintaxis de Markdown interpretada, y listos para ser usados. ¡Y también tenemos tags!

Ahora, es importante destacar que NimblePublisher se está ocupando de parsear los ficheros y construir la variable `@posts` con todos ellos, y tú continúas a partir de ahí para definir las funciones que necesites. Por ejemplo, si necesitas una función para traer los posts recientes, la puedes definir así:

```elixir
def recent_posts(num \\ 5), do: Enum.take(all_posts(), num)  
```

Como puedes observar, hemos evitado usar `@posts` dentro de nuestra nueva función y hemos usado `all_posts()` en su lugar. Si no, la variable `@posts` habría sido expandida por el compilador dos veces, haciendo una copia completa de todos los posts.

Vamos a definir algunas funciones más para tener nuestro ejemplo de blog completo. Necesitaremos obtener un post por su id y también listar todos los posts para un tag determinado. Define lo siguiente dentro del contexto `Blog`:

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

## Cómo servir tu contenido

Ahora que tenemos una manera de obtener todos nuestros posts y tags, servirlos simplemente significa conectar las rutas, controladores, vistas y plantillas de la manera acostumbrada. Para este ejemplo no nos complicaremos y simplemente listaremos todos los posts y traeremos cada post por su id. Se deja como un ejercicio al lector listar los posts por tag y ampliar el layout con los posts recientes.

### Rutas

Define las siguientes rutas en `lib/nimble_school_web/router.ex`:

```elixir
scope "/", NimbleSchoolWeb do
  pipe_through :browser

  get "/blog", BlogController, :index
  get "/blog/:id", BlogController, :show
end
```

### Controlador

Define un controlador para servir los posts en `lib/nimble_school_web/controllers/blog_controller.ex`:

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

### Vista

Crea el módulo de vista donde puedes colocar los helpers que necesites para pintar la vista. De momento es simplemente:

```elixir
defmodule NimbleSchoolWeb.BlogView do
  use NimbleSchoolWeb, :view
end
```

### Plantilla

Finalmente, crea los ficheros HTML para pintar el contenido. Dentro de `lib/nimble_school_web/templates/blog/index.html.eex` define esto para pintar el contenido de la lista de posts:

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

Y crea `lib/nimble_school_web/templates/blog/show.html.eex` para pintar un post individual:

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

### ¡Probemos el blog!

¡Ya está todo preparado!

Lanza el servidor web con `iex -S mix phx.server` y visita [http://localhost:4000/blog](http://localhost:4000/blog) para ver tu nuevo blog.

## Cómo ampliar los metadatos

NimblePublisher es muy flexible a la hora de definir la estructura de nuestros posts y metadatos. Por ejemplo, supongamos que queremos añadir una clave `:published` para marcar los posts, y mostrar sólo aquellos donde sea `true`.

Sólo necesitamos añadir la clave `:published` al struct `Post`, y también a los metadatos de los posts. En el módulo `Blog` podemos definir:

```elixir
def all_posts, do: @posts

def published_posts, do: Enum.filter(all_posts(), &(&1.published == true))

def recent_posts(num \\ 5), do: Enum.take(published_posts(), num)
```

## Coloreado de sintaxis

NimblePublisher usa la librería Makeup para el coloreado de sintaxis. Tendrás que generar las clases CSS para el estilo que prefieras de uno de los definidos [aquí](https://hexdocs.pm/makeup/Makeup.Styles.HTML.StyleMap.html).

Por ejemplo, vamos a usar el `:tango_style`. En una sesión de `iex -S mix` ejecuta:

```elixir
Makeup.stylesheet(:tango_style, "makeup") |> IO.puts()
```

Y coloca las clases CSS generadas en tus hojas de estilo.

## Cómo servir otro contenido

NimblePublisher también puede ser empleado para construir otros contextos de publicación con una estructura diferente.

Por ejemplo, podríamos mantener una colección de Preguntas Frecuentes (FAQs), en este caso probablemente no necesitemos fechas ni autores, y una estructura con `:id`, `:question` and `:answer` sería suficiente:

Podríamos colocar nuestros ficheros de contenidos en una estructura de directorio diferente, por ejemplo:

```
/priv/faqs/is-there-a-free-trial.md
/priv/faqs/when-did-it-start.md
```

Y podríamos definir nuestra struct `Faq` y la función para construirla en `lib/nimble_school/faqs/faq.ex` de esta manera: 

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

Nuestro contexto `Faqs` en `lib/nimble_school/faqs/faqs.ex` sería algo así como:

```elixir
defmodule NimbleSchool.Faqs do
  alias NimbleSchool.Faqs.Faq

  use NimblePublisher,
    build: Faq,
    from: Application.app_dir(:nimble_school, "priv/faqs/*.md"),
    as: :faqs

  # La variable @faqs es definida primero por NimblePublisher.
  # Vamos a modificarla más para ordenar todas las FAQs por fecha descendiente.
  @faqs Enum.sort_by(@faqs, & &1.question)

  # Y finalmente lo exportamos
  def all_faqs, do: @faqs
end
```

## Código fuente para el blog de ejemplo

Puedes encontrar el código para este ejemplo en [https://github.com/jaimeiniesta/nimble_school](https://github.com/jaimeiniesta/nimble_school)
