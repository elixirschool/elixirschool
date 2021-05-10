%{
  version: "1.0.2",
  title: "NimblePublisher",
  excerpt: """
  [NimblePublisher](https://github.com/dashbitco/nimble_publisher) é um mecanismo de publicação simples baseado em um sistema de arquivos com suporte a Markdown e realce de código.
  """
}
---

## Por que usar NimblePublisher?

NimblePublisher é uma biblioteca simples projetada para a publicação de conteúdo parseado de arquivos locais utilizando a sintaxe Markdown. Um caso de uso típico seria a construção de um blog.

Essa biblioteca encapsula a maior parte do código que a Dashbit usa para seu próprio blog, como apresentado em sua postagem [Boas vindas ao nosso blog: como ele foi feito!](https://dashbit.co/blog/welcome-to-our-blog-how-it-was-made) - e onde explicam por que escolheram parsear o conteúdo de arquivos locais ao invés de utilizar um banco de dados ou um CMS mais complexo.

## Criando seu conteúdo

Vamos construir nosso próprio blog. Em nosso exemplo, estamos utilizando uma aplicação Phoenix mas o Phoenix não é um requisito obrigatório. Como a NimblePublisher se encarrega apenas de parsear os arquivos locais, você pode utilizá-la em qualquer aplicação Elixir.

Primeiro, vamos criar uma nova aplicação Phoenix para nosso exemplo. Vamos chamá-la de NimbleSchool, e vamos a criar desta forma pois não iremos precisar do Ecto em nosso caso:

```shell
mix phx.new nimble_school --no-ecto
```

Agora, vamos adicionar algumas postagens. Precisamos começar criando um diretório que irá conter nossas postagens. Vamos mantê-los organizados por ano neste formato:

```
/priv/posts/YEAR/MONTH-DAY-ID.md
```

Por exemplo, começamos com essas duas postagens:

```
/priv/posts/2020/10-28-hello-world.md
/priv/posts/2020/11-04-exciting-news.md
```

Uma postagem típica de blog será escrita na sintaxe Markdown, com uma seção de metadados no topo e o conteúdo abaixo separado por `---`, assim:

```
%{
  title: "Hello World!",
  author: "Jaime Iniesta",
  tags: ~w(hello),
  description: "Nossa primeira postagem do blog está aqui"
}
---
Sim, essa é **a postagem** que você estava esperando.
```

Vou deixar você ser uma pessoa criativa escrevendo suas próprias postagens. Apenas se certifique de seguir o formato acima para os metadados e conteúdo.

Com essas postagens no lugar, vamos instalar a NimblePublisher para que possamos parsear o conteúdo e contruir o contexto do nosso `Blog`.

## Instalando a NimblePublisher

Primeiro, adicione `nimble_publisher` como uma dependência. Opcionalmente você pode incluir algum realçador de sintaxe, neste caso adicionaremos suporte para realçar o código Elixir e Erlang.

Em nossa aplicação Phoenix, vamos adicionar isso em `mix.exs`:

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

Depois de executar `mix deps.get` para buscar as dependências, você está pronta para continuar construindo o blog.

## Construindo o contexto do Blog

Vamos definir uma estrutura `Post` que manterá o conteúdo parseado dos arquivos. Ela irá esperar uma chave para cada chave de metadados e também um `:date` que será parseado a partir do nome do arquivo. Crie um arquivo `lib/nimble_school/blog/post.ex` com este conteúdo:

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

O módulo `Post` define a estrutura para os metadados e conteúdo, define também uma função `build/3` com a lógica necessária para parsear o arquivo com o conteúdo da postagem.

Com a estrutura `Post` no lugar, podemos definir nosso contexto `Blog` que irá utilizar a NimblePublisher para parsear os arquivos locais em postagens. Crie `lib/nimble_school/blog/blog.ex` com este conteúdo:

```elixir
defmodule NimbleSchool.Blog do
  alias NimbleSchool.Blog.Post

  use NimblePublisher,
    build: Post,
    from: Application.app_dir(:nimble_school, "priv/posts/**/*.md"),
    as: :posts,
    highlighters: [:makeup_elixir, :makeup_erlang]

  # A variável @posts é primeiro definida por NimblePublisher.
  # Vamos modificá-la ainda mais ordenando todas as postagens por data decrescente.
  @posts Enum.sort_by(@posts, & &1.date, {:desc, Date})

  # Vamos também recuperar todas as tags.
  @tags @posts |> Enum.flat_map(& &1.tags) |> Enum.uniq() |> Enum.sort()

  # E finalmente exportá-las.
  def all_posts, do: @posts
  def all_tags, do: @tags
end
```

Como você pode perceber, o contexto `Blog` utiliza a NimblePublisher para construir a coleção de `Post` a partir do diretório local indicado, utilizando o realce de sintaxe que desejamos usar.

A NimblePublisher irá criar a variável `@posts`, que mais tarde processamos para ordenar as postagens em ordem decrescente por `:date` como normalmente queremos em um blog.

Também definimos `@tags` a partir dos `@posts`.

Finalmente, definimos `all_posts/0` e `all_tags/0` que retornarão apenas o que foi parseado respectivamente.

Vamos tentar! Entre no console com `iex -S mix` e execute:

```elixir
iex(1)> NimbleSchool.Blog.all_posts()
[
  %NimbleSchool.Blog.Post{
    author: "Jaime Iniesta",
    body: "<p>\nIncrível, essa é nossa segunda postagem em nosso ótimo blog.</p>\n",
    date: ~D[2020-11-04],
    description: "Segunda postagem do blog",
    id: "exciting-news",
    tags: ["exciting", "news"],
    title: "Exciting News!"
  },
  %NimbleSchool.Blog.Post{
    author: "Jaime Iniesta",
    body: "<p>\nSim, essa é <strong>a postagem</strong> que você estava esperando.</p>\n",
    date: ~D[2020-10-28],
    description: "Nossa primeira postagem do blog está aqui",
    id: "hello-world",
    tags: ["hello"],
    title: "Hello World!"
  }
]

iex(2)> NimbleSchool.Blog.all_tags()
["exciting", "hello", "news"]
```

Não é ótimo? Já temos todas as nossas postagens parseadas, com interpretação de Markdown e estamos prontas para seguir. Com as tags também!

Agora, é importante perceber que a NimblePublisher está cuidando de parsear os arquivos e construir a variável `@posts` com todos eles, e você parte daí para definir as funções de que precisa. Por exemplo, se precisarmos de uma função para obter as postagens recentes, podemos definir desta forma:

```elixir
def recent_posts(num \\ 5), do: Enum.take(all_posts(), num)
```

Como pode perceber, evitamos utilizar `@posts` dentro de nossa nova função usando `all_posts()` no lugar. Caso contrário, a variável `@posts` teria sido expandida pelo compilador duas vezes, fazendo uma cópia completa de todos as postagens.

Vamos definir mais algumas funções para ter nosso blog de exemplo completo. Vamos precisar obter uma postagem por seu id e também listar todos as postagens de uma determinada tag. Defina o seguinte dentro do contexto `Blog`:

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

## Disponibilizando seu conteúdo

Agora que já temos uma maneira de obter todas as nossas postagens e tags, disponibilizar significa apenas conectar as rotas, controllers, views e templates da forma usual. Para esse exemplo iremos manter a simplicidade e apenas listar todas as postagens e obter uma postagem por seu id. É deixado a você como um exercício listar postagens por tags e estender o layout com as postagens recentes.

### Rotas

Defina as seguintes rotas em `lib/nimble_school_web/router.ex`:

```elixir
scope "/", NimbleSchoolWeb do
  pipe_through :browser

  get "/blog", BlogController, :index
  get "/blog/:id", BlogController, :show
end
```

### Controller

Defina um controller para servir as postagens em `lib/nimble_school_web/controllers/blog_controller.ex`:

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

Crie o módulo view onde você pode colocar os auxiliares necessários para renderizar a view. Por agora é só:

```elixir
defmodule NimbleSchoolWeb.BlogView do
  use NimbleSchoolWeb, :view
end
```

### Template

Finalmente, crie os arquivos HTML para rederizar o conteúdo. Dentro de `lib/nimble_school_web/templates/blog/index.html.eex` defina o seguinte para renderizar a lista de postagens:

```html
<h1>Listing all posts</h1>

<%= for post <- @posts do %>
<div id="<%= post.id %>" style="margin-bottom: 3rem;">
  <h2><%= link post.title, to: Routes.blog_path(@conn, :show, post)%></h2>

  <p><time><%= post.date %></time> by <%= post.author %></p>

  <p>Tagged as <%= Enum.join(post.tags, ", ") %></p>

  <%= raw post.description %>
</div>
<% end %>
```

E crie `lib/nimble_school_web/templates/blog/show.html.eex` para renderizar uma única postagem:

```html
<%= link "← All posts", to: Routes.blog_path(@conn, :index)%>

<h1><%= @post.title %></h1>

<p><time><%= @post.date %></time> by <%= @post.author %></p>

<p>Tagged as <%= Enum.join(@post.tags, ", ") %></p>

<%= raw @post.body %>
```

### Navegue por suas postagens!

Tudo pronto para seguir!

Abra o servidor web com `iex -S mix phx.server` e visite [http://localhost:4000/blog](http://localhost:4000/blog) para conferir seu novo blog em ação!

## Extendendo metadados

A NimblePublisher é muito flexível quando se trata de definir nossa estrutura de postagens e metadados. Por exemplo, digamos que queremos adicionar uma chave `:published` para sinalizar as postagens e mostrar apenas aquelas onde isso é verdade, ou `true`.

Precisamos apenas adicionar a chave `:published` à estrutura do `Post`, e também aos metadados das postagens. No módulo `Blog` podemos definir:

```elixir
def all_posts, do: @posts

def published_posts, do: Enum.filter(all_posts(), &(&1.published == true))

def recent_posts(num \\ 5), do: Enum.take(published_posts(), num)
```

## Realçe de Sintaxe

A NimblePublisher usa a biblioteca Makeup para realçar a sintaxe. Você irá precisar gerar as classes CSS para o estilo que preferir a partir de um definido [aqui](https://hexdocs.pm/makeup/Makeup.Styles.HTML.StyleMap.html).

Por exemplo, iremos usar o `:tango_style`. A partir de uma sessão `iex -S mix`, execute:

```elixir
Makeup.stylesheet(:tango_style, "makeup") |> IO.puts()
```

E coloque as classes CSS geradas em sua folha de estilo.

## Disponibilizando outros conteúdos

A NimblePublisher também pode ser usada para construir outros contextos de publicação com uma estrutura diferente.

Por exemplo, poderíamos gerenciar uma coleção de Perguntas Frequentes (FAQs), neste caso nós provavelmente não precisamos de datas, ou autores, e uma estrutura mais simples com `:id`, `:question` e `:answer` seria ótimo.

Poderíamos colocar nossos arquivos de conteúdo em uma estrutura de diretório diferente, por exemplo:

```
/priv/faqs/is-there-a-free-trial.md
/priv/faqs/when-did-it-start.md
```

E poderíamos definir nossa estrutura de `Faq` e a função de construção em `lib/nimble_school/faqs/faq.ex` assim:

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

Nosso contexto `Faqs` em `lib/nimble_school/faqs/faqs.ex` seria algo como:

```elixir
defmodule NimbleSchool.Faqs do
  alias NimbleSchool.Faqs.Faq

  use NimblePublisher,
    build: Faq,
    from: Application.app_dir(:nimble_school, "priv/faqs/*.md"),
    as: :faqs

  # A variável @faqs é primeiro definida pela NimblePublisher.
  # Vamos modificá-la ainda mais ordenando todas as postagens por perguntas de forma crescente.
  @faqs Enum.sort_by(@faqs, & &1.question)

  # E finalmente exportá-las
  def all_faqs, do: @faqs
end
```

## Código fonte para esse blog de exemplo

Você pode encontrar o código para esse exemplo em [https://github.com/jaimeiniesta/nimble_school](https://github.com/jaimeiniesta/nimble_school)
