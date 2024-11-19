%{
  version: "1.1.0",
  title: "NimblePublisher",
  excerpt: """
  [NimblePublisher](https://github.com/dashbitco/nimble_publisher) — это минималистичный движок для публикации текстов на основе файловой системы с поддержкой Markdown и подсветкой кода.
  """
}
---

## Зачем использовать NimblePublisher?

NimblePublisher — простая библиотека, разработанная для публикации контента, который парсится из локальных файлов с использованием синтаксиса Markdown. Типичным вариантом использования является создание блога.

Эта библиотека инкапсулирует большую часть кода, который Dashbit использует для своего собственного блога, как представлено в их посте [Добро пожаловать в наш блог: как это было сделано!](https://dashbit.co/blog/welcome-to-our-blog-how-it-was-made), где они объясняют, почему они решили парсить контент из локальных файлов вместо использования базы данных или более сложной CMS.

## Создание вашего контента

Давайте создадим свой блог. В нашем примере мы используем приложение на Phoenix'е, но Phoenix не является обязательным. Поскольку NimblePublisher занимается только парсингом локальных файлов, вы можете использовать его в любом приложении Elixir.

Сначала давайте создадим новое приложение Phoenix для нашего примера. Назовем проект NimbleSchool и создадим его с флагом --no-ecto, потому что нам не нужен Ecto в данном приложении:

```shell
mix phx.new nimble_school --no-ecto
```

Теперь давайте добавим несколько постов. Нам нужно создать директорию, в которой будут наши посты. Мы будем хранить их по годам в следующем формате:

```
/priv/posts/YEAR/MONTH-DAY-ID.md
```

Например, начнем с этих двух постов:

```
/priv/posts/2020/10-28-hello-world.md
/priv/posts/2020/11-04-exciting-news.md
```

Типичная запись в блоге будет написана с использованием синтаксиса Markdown, с разделом метаданных вверху и содержимым ниже, разделенным символами `---`, например:

```
%{
  title: "Привет, Мир!",
  author: "Джейми Иньеста",
  tags: ~w(hello),
  description: "Наш первый блог пост"
}
---
Да, это **тот пост**, которого вы ждали.
```

Я позволю вам проявить творческий подход к написанию собственных постов. Просто убедитесь, что вы следуете указанному выше формату метаданных и контента.

Разместив эти записи, давайте установим NimblePublisher, чтобы мы могли проанализировать контент и создать наш контекст `Блог`.

## Установка NimblePublisher

Сначала добавьте `nimble_publisher` как зависимость. Вы можете по желанию включить подсветку синтаксиса, в нашем случае мы добавим поддержку подсветки кода Elixir и Erlang.

В нашем Phoenix приложении необходимо добавить следующий код в `mix.exs`:

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

После того, как вы запустили `mix deps.get` для установки зависимостей, вы готовы продолжить создание блога.

## Создание контекста блога

Мы определим структуру `Post`, в которой будет содержимое парсинга файлов. Она будет ожидать ключ для каждого ключа метаданных, а также дата `:date` из имени файла. Создайте файл `lib/nimble_school/blog/post.ex` со следующим содержимым:

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

Модуль `Post` определяет структуру для метаданных и контента, а также функцию `build/3` с логикой, необходимой для парсинга файла с содержимым поста.

С помощью структуры `Post` мы можем определить наш контекст `Blog`, который будет использовать NimblePublisher для парсинга локальных файлов в посты. Создайте `lib/nimble_school/blog/blog.ex` со следующим содержимым:

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

Как видите, контекст `Blog` использует NimblePublisher для создания коллекции `Post` из указанного локального каталога, используя подсветку синтаксиса, которую мы хотим использовать.

NimblePublisher создаст переменную `@posts`, которую мы позже обработаем для сортировки постов по убыванию `:date`, как мы обычно делаем в блоге.

Мы также определяем переменную `@tags`, беря её значение из `@posts`.

Наконец, мы определяем функции `all_posts/0` и `all_tags/0`, которые будут возвращать только то, что было распаршено соответственно.

Давайте попробуем! Войдите в консоль с помощью команды `iex -S mix` и запустите:

```elixir
iex(1)> NimbleSchool.Blog.all_posts()
[
  %NimbleSchool.Blog.Post{
    author: "Джейми Иньеста",
    body: "<p>\nОтлично, это наш второй пост в нашем замечательном блоге.</p>\n",
    date: ~D[2020-11-04],
    description: "Второй блог пост",
    id: "exciting-news",
    tags: ["exciting", "news"],
    title: "Захватывающие новости!"
  },
  %NimbleSchool.Blog.Post{
    author: "Джейми Иньеста",
    body: "<p>\nДа, это <strong>тот пост</strong>, которого вы ждали.</p>\n",
    date: ~D[2020-10-28],
    description: "Наш первый блог пост",
    id: "hello-world",
    tags: ["hello"],
    title: "Привет, Мир!"
  }
]

iex(2)> NimbleSchool.Blog.all_tags()
["exciting", "hello", "news"]
```

Разве это не здорово? Все наши посты распаршены с интерпретацией Markdown и готовы к работе. И теги тоже!

Важно отметить, что NimblePublisher занимается разбором файлов и созданием переменной `@posts` со всеми из них, а вы берете данные из этой переменной, чтобы создать нужные вам функции. Например, если нам нужна функция для получения последних постов, мы можем определить ее следующим образом:

```elixir
def recent_posts(num \\ 5), do: Enum.take(all_posts(), num)
```

Как вы можете видеть, мы избежали использования `@posts` внутри нашей новой функции и вместо этого вызвали функцию `all_posts()`. В противном случае компилятор вычислил бы переменную `@posts` дважды, создав полную копию всех постов.

Давайте определим еще несколько функций, чтобы получить наш полный пример блога. Нам нужно будет получить пост по его идентификатору, а также перечислить все посты для заданного тега. Определите следующие функции внутри контекста `Blog`:

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

## Отображение вашего контента

Теперь, когда у нас есть способ получить все наши посты и теги, для отображения блога необходима обвязка в виде маршрутов, контроллеров, представлений и шаблонов, как мы обычно это делаем в приложении Phoenix. Для этого примера мы сделаем все просто: перечислим все посты и получим пост по его идентификатору. Читателю остается в качестве упражнения перечислить посты по тегу и расширить макет недавними постами.

### Маршрутизация

Определите следующие маршруты в `lib/nimble_school_web/router.ex`:

```elixir
scope "/", NimbleSchoolWeb do
  pipe_through :browser

  get "/blog", BlogController, :index
  get "/blog/:id", BlogController, :show
end
```

### Контроллер

В файле`lib/nimble_school_web/controllers/blog_controller.ex` создайте контроллер для постов:

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

### Отображение

Создайте вспомогательный модуль, необходимый для рендеринга представлений в
`lib/nimble_school_web/controllers/blog_html.ex`.
На данный момент модуль будет иметь следующий вид:

```elixir
defmodule NimbleSchoolWeb.BlogHTML do
  use NimbleSchoolWeb, :html

  embed_templates "blog_html/*"
end
```

### Шаблон

Наконец, создайте HTML-файлы для отображения контента. В файле `lib/nimble_school_web/controllers/blog_html/index.html.heex` определите шаблон для отображения списка блог-постов:

```html
<h1>Все посты</h1>

<%= for post <- @posts do %>
  <div id="{post.id}" style="margin-bottom: 3rem;">
    <h2>
      <.link href={~p"/blog/#{post.id}"}><%= post.title %></.link>
    </h2>

    <p>
      <time><%= post.date %></time> by <%= post.author %>
    </p>

    <p>
      Теги <%= Enum.join(post.tags, ", ") %>
    </p>

    <%= raw post.description %>
  </div>
<% end %>
```

И создайте файл `lib/nimble_school_web/controllers/blog_html/show.html.heex` для отображения одного блог-поста:

```html
<.link href={~p"/blog"}>← Все посты</.link>

<h1><%= @post.title %></h1>

<p>
  <time><%= @post.date %></time> by <%= @post.author %>
</p>

<p>
  Тэги <%= Enum.join(@post.tags, ", ") %>
</p>

<%= raw @post.body %>
```

### Просмотр ваших постов

Вы готовы к работе!

Запустите веб-сервер с помощью команды `iex -S mix phx.server` и откройте страницу [http://localhost:4000/blog](http://localhost:4000/blog), чтобы увидеть ваш новый блог в действии!

## Расширение метаданных

NimblePublisher очень гибок, когда дело доходит до определения структуры и метаданных наших постов. Например, предположим, что мы хотим добавить ключ `:published`, чтобы пометить посты, и показывать только те, где этот ключ `true`.

Нам просто нужно добавить ключ `:published` в структуру `Post`, а также в метаданные постов. В модуле `Blog` мы можем определить:

```elixir
def all_posts, do: @posts

def published_posts, do: Enum.filter(all_posts(), &(&1.published == true))

def recent_posts(num \\ 5), do: Enum.take(published_posts(), num)
```

## Подсветка синтаксиса

NimblePublisher использует библиотеку Makeup для подсветки синтаксиса. Вам нужно будет сгенерировать классы CSS для стилей, которые вы предпочитаете из перечисленных [здесь](https://hexdocs.pm/makeup/Makeup.Styles.HTML.StyleMap.html).

Например, мы будем использовать `:tango_style`. Из сеанса `iex -S mix` вызовите:

```elixir
Makeup.stylesheet(:tango_style, "makeup") |> IO.puts()
```

И поместите сгенерированные CSS-классы в свои таблицы стилей.

## Отображение другого контента

NimblePublisher также можно использовать для создания других контекстов публикации с другой структурой.

Например, мы могли бы управлять коллекцией часто задаваемых вопросов (FAQ). В этом случае нам, вероятно, не понадобятся даты или авторы, и более простая структура с `:id`, `:question` и `:answer` была бы просто замечательной.

Мы могли бы разместить наши файлы с контентом в другой директории, например:

```
/priv/faqs/is-there-a-free-trial.md
/priv/faqs/when-did-it-start.md
```

И мы могли бы определить нашу структуру `Faq` и построить функцию в `lib/nimble_school/faqs/faq.ex` следующим образом:

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

Наш контекст `Faqs` в `lib/nimble_school/faqs/faqs.ex` будет выглядеть примерно так:

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

## Исходный код для примера блога

Код этого примера вы можете найти в [https://github.com/jaimeiniesta/nimble_school](https://github.com/jaimeiniesta/nimble_school)
