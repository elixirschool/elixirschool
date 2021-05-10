---
version: 1.2.2
title: Связи
---

В этом уроке мы рассмотрим, как использовать Ecto для определения связей и работы с ассоциациями между схемами.

{% include toc.html %}

## Настройка

Начнём с приложения `Friends`, которое уже использовалось в предыдущих уроках. [Здесь](../basics) можно вспомнить, о чём идёт речь.

## Типы ассоциаций

Между схемами в Ecto можно объявить три типа связей. Рассмотрим их и узнаем, как работать с каждым из них.

### Belongs To/Has Many

Добавим несколько новых сущностей в приложение, чтобы пользователи могли начать каталогизировать свои любимые фильмы. Начнём с добавления двух схем: `Movie` и `Character`. Добавим двухстороннюю связь между ними: у фильма есть много героев (has many), и каждый герой принадлежит какому-то одному фильму (belongs to).

#### Миграция Has Many

Сгенерируем миграцию для схемы `Movie`:

```console
mix ecto.gen.migration create_movies
```

Откроем файл сгенерированной миграции и определим содержимое функции `change` для создания таблицы `movies` со всеми нужными атрибутами:

```elixir
# priv/repo/migrations/*_create_movies.exs
defmodule Friends.Repo.Migrations.CreateMovies do
  use Ecto.Migration

  def change do
    create table(:movies) do
      add :title, :string
      add :tagline, :string
    end
  end
end
```

#### Схема для связи Has Many

Добавим модель для нашей миграции со связью между фильмами и героями:

```elixir
# lib/example/movie.ex
defmodule Friends.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Friends.Character
  end
end
```

Макрос `has_many/3` не делает ничего в самой базе данных. Вместо этого он использует ключ (`foreign key`) связанной схемы `characters` для получения героев, связанных с этим фильмом. Этот макрос позволяет в дальнейшем использовать синтаксис `movie.characters`.

#### Миграция для создания связи Belongs To

Теперь можно создать миграцию и схемы `Character`. Герой относится к фильму — определим миграцию и схему, описывающие эту связь.

Сначала опишем миграцию:

```console
mix ecto.gen.migration create_characters
```

Для описания факта принадлежности героя к фильму нужна колонка `movie_id` в таблице `characters`. Используем эту колонку как `foreign key`. Это можно сделать с помощью следующей строки внутри функции `create_table/1`:

```elixir
add :movie_id, references(:movies)
```
После добавления этой строки миграция должна выглядеть вот так:

```elixir
# priv/migrations/*_create_characters.exs
defmodule Friends.Repo.Migrations.CreateCharacters do
  use Ecto.Migration

  def change do
    create_table(:characters) do
      add :name, :string
      add :movie_id, references(:movies)
    end
  end
end
```

#### Схема для связи Belongs To

В схеме также нужно определить эту связь между героем и фильмом:

```elixir
# lib/example/character.ex

defmodule Friends.Character do
  use Ecto.Schema

  schema "characters" do
    field :name, :string
    belongs_to :movie, Friends.Movie
  end
end
```

Давайте ближе посмотрим на то, как работает макрос `belongs_to/3`. Кроме объявления поля `movie_id` в таблице `characters`, этот макрос также даёт нам возможность доступа к связанным фильмам (`movies`) _через_ героев (`characters`). Эта функциональность использует `movie_id` для получения фильма, когда мы его запрашиваем. Также это позволит нам вызывать `character.movie`.

Теперь можно запустить миграции:

```console
mix ecto.migrate
```

### Belongs To/Has One

Допустим, что у фильма есть один дистрибьютор. К примеру, Netflix является дистрибьютором эксклюзивного для их платформы фильма Bright.

Определим миграцию и схему `Distributor` со связью `belongs to`. Для начала создадим миграцию:

```console
mix ecto.gen.migration create_distributors
```

Добавим создание поля `movie_id` в таблице `distributors` вместе с уникальным индексом, который позволит фильму иметь только одного дистрибьютора:

```elixir
# priv/repo/migrations/*_create_distributors.exs

defmodule Friends.Repo.Migrations.CreateDistributors do
  use Ecto.Migration

  def change do
    create table(:distributors) do
      add :name, :string
      add :movie_id, references(:movies)
    end

    create unique_index(:distributors, [:movie_id])
  end
end
```

Схема `Distributor` должна также запускать макрос `belongs_to/3` для дальнейшего использования `distributor.movie` и нахождения фильмов этого дистрибьютора по этому ключу.

```elixir
# lib/friends/distributor.ex

defmodule Friends.Distributor do
  use Ecto.Schema

  schema "distributors" do
    field :name, :string
    belongs_to :movie, Friends.Movie
  end
end
```

Следующим шагом мы добавим связь в схему `Movie`:

```elixir
# lib/friends/movie.ex

defmodule Friends.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Friends.Character
    has_one :distributor, Friends.Distributor # I'm new!
  end
end
```

Макрос `has_one/3` работает так же, как и `has_many/3`. Он даёт возможность работать с переданной структурой с помощью вызова `movie.distributor`.

Теперь можно запустить миграции:

```console
mix ecto.migrate
```

### Many To Many

Допустим, что у фильма есть много актёров и актёр может принадлежать нескольким фильмам. Создадим промежуточную таблицу, которая включает в себя ссылки и на актёров, и на фильмы для хранения данных этой связи.

Сначала создадим миграцию для актёров `Actors`:

```console
mix ecto.gen.migration create_actors
```

Определим миграцию:

```elixir
# priv/migrations/*_create_actors.ex

defmodule Friends.Repo.Migrations.Actors do
  use Ecto.Migration

  def change do
    create table(:actors) do
      add :name, :string
    end
  end
end
```

Создадим миграцию для промежуточной таблицы:

```console
mix ecto.gen.migration create_movies_actors
```

Определим таблицу, как имеющую два `foreign key`. Также добавим уникальный индекс для проверки уникальности данных:

```elixir
# priv/migrations/*_create_movies_actors.ex

defmodule Friends.Repo.Migrations.CreateMoviesActors do
  use Ecto.Migration

  def change do
    create table(:movies_actors) do
      add :movie_id, references(:movies)
      add :actor_id, references(:actors)
    end

    create unique_index(:movies_actors, [:movie_id, :actor_id])
  end
end
```

Следующим шагом добавим макрос `many_to_many` в схему `Movie`:

```elixir
# lib/friends/movie.ex

defmodule Friends.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Friends.Character
    has_one :distributor, Friends.Distributor
    many_to_many :actors, Friends.Actor, join_through: "movies_actors" # I'm new!
  end
end
```

Также добавим в схему `Actor` тот же самый макрос `many_to_many`:

```elixir
# lib/friends/actor.ex

defmodule Friends.Actor do
  use Ecto.Schema

  schema "actors" do
    field :name, :string
    many_to_many :movies, Friends.Movie, join_through: "movies_actors"
  end
end
```

И после всех изменений запустим миграции:

```console
mix ecto.migrate
```

## Сохранение связанных данных

Способ сохранения данных зависит от того, какая именно связь между этими объектами. Начнём с `belongs to/has many`.

### Belongs To

#### Сохранение с помощью `Ecto.build_assoc/3`

Со связью `belongs to`, можно использовать метод Ecto `build_assoc/3`.

[`build_assoc/3`](https://hexdocs.pm/ecto/Ecto.html#build_assoc/3) принимает три параметра:

* Структуру, которую мы хотим сохранить.
* Название связи.
* Любые атрибуты, которые мы также хотим задать связанной записи.

Создадим фильм и героя, участвующего в нём. Начнём с записи фильма:

```elixir
iex> alias Friends.{Movie, Character, Repo}
iex> movie = %Movie{title: "Ready Player One", tagline: "Something about video games"}

%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:built, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: nil,
  tagline: "Something about video games",
  title: "Ready Player One"
}

iex> movie = Repo.insert!(movie)
```

Теперь создадим связанного героя и сохраним его в базу данных:

```elixir
iex> character = Ecto.build_assoc(movie, :characters, %{name: "Wade Watts"})
%Friends.Character{
  __meta__: %Ecto.Schema.Metadata<:built, "characters">,
  id: nil,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Wade Watts"
}
iex> Repo.insert!(character)
%Friends.Character{
  __meta__: %Ecto.Schema.Metadata<:loaded, "characters">,
  id: 1,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Wade Watts"
}
```

Стоит отметить, что так как в `Movie` макрос `has_many/3` определяет, что в фильме несколько `:characters`, то именно такое название мы передаем в `build_assoc/3` вторым параметром. Можно также увидеть, что мы создали героя, у которого свойство `movie_id` правильно установлено в идентификатор связанного фильма.

Для использования `build_assoc/3` для сохранения дистрибьютора, воспользуемся тем же подходом передачи названия связи во втором аргументе:

```elixir
iex> distributor = Ecto.build_assoc(movie, :distributor, %{name: "Netflix"})
%Friends.Distributor{
  __meta__: %Ecto.Schema.Metadata<:built, "distributors">,
  id: nil,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Netflix"
}
iex> Repo.insert!(distributor)
%Friends.Distributor{
  __meta__: %Ecto.Schema.Metadata<:loaded, "distributors">,
  id: 1,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Netflix"
}
```

### Many to Many

#### Сохранение с помощью `Ecto.Changeset.put_assoc/4`

Подход, использованный ранее с `build_assoc/3`, не сработает со связью многие-ко-многим, так как ни у таблицы актёров, ни у таблицы фильмов нет полей для этой связи. Вместо этого нужно использовать функцию `put_assoc/4`.

Допустим, что фильм уже сохранен в базу данных ранее, и создадим запись для актёра:

```elixir
iex> alias Friends.Actor
iex> actor = %Actor{name: "Tyler Sheridan"}
%Friends.Actor{
  __meta__: %Ecto.Schema.Metadata<:built, "actors">,
  id: nil,
  movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
  name: "Tyler Sheridan"
}
iex> actor = Repo.insert!(actor)
%Friends.Actor{
  __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
  id: 1,
  movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
  name: "Tyler Sheridan"
}
```

Теперь мы готовы связать фильм и актёра с помощью промежуточной таблицы.

Сначала для работы с наборами изменений, нужно убедиться, что структура `movie` загрузила данные связанных структур. Чуть позже также рассмотрим предзагрузку данных. Сейчас будет достаточно понимать, что таким образом можно предзагрузить данные связанных таблиц:

```elixir
iex> movie = Repo.preload(movie, [:distributor, :characters, :actors])
%Friends.Movie{
 __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [],
  characters: [
    %Friends.Character{
      __meta__: #Ecto.Schema.Metadata<:loaded, "characters">,
      id: 1,
      movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
      movie_id: 1,
      name: "Wade Watts"
    }
  ],
  distributor: %Friends.Distributor{
    __meta__: #Ecto.Schema.Metadata<:loaded, "distributors">,
    id: 1,
    movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
    movie_id: 1,
    name: "Netflix"
  },
  id: 1,
  tagline: "Something about video game",
  title: "Ready Player One"
}
```

Следующим шагом создадим набор изменений для записи фильма:

```elixir
iex> movie_changeset = Ecto.Changeset.change(movie)
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Movie<>,
 valid?: true>
```

Теперь передадим набор изменений в качестве первого аргумента в [`Ecto.Changeset.put_assoc/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#put_assoc/4):

```elixir
iex> movie_actors_changeset = movie_changeset |> Ecto.Changeset.put_assoc(:actors, [actor])
%Ecto.Changeset<
  action: nil,
  changes: %{
    actors: [
      %Ecto.Changeset<action: :update, changes: %{}, errors: [],
       data: %Friends.Actor<>, valid?: true>
    ]
  },
  errors: [],
  data: %Friends.Movie<>,
  valid?: true
>
```

Это создаст новый набор изменений, который отображает добавление этих актёров в список актёров выбранного фильма.

И в качестве финального штриха, сохраним этот набор изменений:

```elixir
iex> Repo.update!(movie_actors_changeset)
%Friends.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Friends.Actor{
      __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
      id: 1,
      movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Tyler Sheridan"
    }
  ],
  characters: [
    %Friends.Character{
      __meta__: #Ecto.Schema.Metadata<:loaded, "characters">,
      id: 1,
      movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
      movie_id: 1,
      name: "Wade Watts"
    }
  ],
  distributor: %Friends.Distributor{
    __meta__: #Ecto.Schema.Metadata<:loaded, "distributors">,
    id: 1,
    movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
    movie_id: 1,
    name: "Netflix"
  },
  id: 1,
  tagline: "Something about video game",
  title: "Ready Player One"
}
```

Можно увидеть, что этот вызов вернул запись фильма с актёром, предзагруженным в `movie.actors`.

Тот же подход может использоваться для создания актёра, связанного с имеющимся фильмом. Вместо передачи сохраненной записи актёра можно передать структуру, описывающую создаваемого актёра:

```elixir
iex> changeset = movie_changeset |> Ecto.Changeset.put_assoc(:actors, [%{name: "Gary"}])
%Ecto.Changeset<
  action: nil,
  changes: %{
    actors: [
      %Ecto.Changeset<
        action: :insert,
        changes: %{name: "Gary"},
        errors: [],
        data: %Friends.Actor<>,
        valid?: true
      >
    ]
  },
  errors: [],
  data: %Friends.Movie<>,
  valid?: true
>
iex>  Repo.update!(changeset)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Friends.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
      id: 2,
      movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Gary"
    }
  ],
  characters: [],
  distributor: nil,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Можно увидеть, что новый актёр был создан с идентификатором 2 и переданными ему атрибутами.

В следующем уроке мы увидим, как искать по связанным записям.
