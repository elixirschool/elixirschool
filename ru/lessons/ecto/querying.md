---
version: 1.0.3
title: Язык запросов
---

{% include toc.html %}

В этом уроке мы будем работать над приложением `Example` для каталогизации фильмов из [предыдущего урока](./associations).

## Получение записей из `Ecto.Repo`

Напомним, что репозиторием в Ecto называется хранилище данных, такое как наша база данных Postgres.
Всё взаимодействие с базой будет происходить посредством этого репозитория.

Для начала мы можем выполнять простые запросы напрямую через `Example.Repo` с помощью пары полезных функций.

### Получение записей по ID

Мы можем использовать функцию `Repo.get/3`, чтобы получить запись из базы по ID. Эта функция принимает два обязательных аргумента: структуру данных, пригодную для запросов, и ID искомой записи. В качестве результата она возвращает запись в виде структуры, если таковая была найдена. В противном случае возвращается `nil`.

В примере ниже мы получаем фильм с ID = 1:

```elixir
iex> alias Example.{Repo, Movie}
iex> Repo.get(Movie, 1)
%Example.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Обратите внимание, что первый аргумент, передаваемый в `Repo.get/3`, – это наш модуль `Movie`. Мы называем `Movie` "пригодным для запросов", потому что он определяет схему данных при помощи `Ecto.Schema`. За счёт этого `Movie` получает доступ к протоколу `Ecto.Queryable`. Этот протокол позволяет преобразовывать структуры данных в запросы `Ecto.Query`, которые затем используются для получения данных через репозиторий. Дальше мы подробнее остановимся на запросах.

### Получение записей по атрибуту

Мы также можем получать данные по заданным критериям при помощи функции `Repo.get_by/3`. Она принимает два значения: подходящую структуру и условие для запроса. `Repo.get_by/3` в качестве результата возвращает одну запись из репозитория. Вот пример:

```elixir
iex> alias Example.Repo
iex> alias Example.Movie
iex> Repo.get_by(Movie, title: "Ready Player One")
%Example.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Однако если нам нужно использовать более сложные запросы, либо получать _все_ подходящие под условие записи, нам понадобится модуль `Ecto.Query`.

## Написание запросов с `Ecto.Query`

Модуль `Ecto.Query` предоставляет собственный язык написания запросов для репозиториев.

### Создание запросов при помощи `Ecto.Query.from/2`

Запрос можно создавать при помощи функции `Ecto.Query.from/2`. Она принимает два аргумента: выражение и ключевой список. Создадим запрос для получения всех фильмов из нашего репозитория:

```elixir
import Ecto.Query
query = from(m in Movie, select: m)
#Ecto.Query<from m in Example.Movie, select: m>
```

Чтобы выполнить запрос, воспользуемся функцией `Repo.all/2`. Она принимает Ecto-запрос в качестве обязательного аргумента и возвращает все записи, удовлетворяющие условиям.

```elixir
iex> Repo.all(query)

14:58:03.187 [debug] QUERY OK source="movies" db=1.7ms decode=4.2ms
[
  %Example.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

#### Конструирование FROM с ключевым запросом

В примере выше мы передаём в макрос `from/2` в качестве аргумента *ключевой запрос* `select: m`. Он *ключевой* в том смысле, что составлен при помощи ключевого списка. При использовании `from` с таким запросом первый аргумент может быть двух типов:

* Выражение с `in` (например: `m in Movie`)
* Модуль, поддерживающий протокол `Ecto.Queryable` (например: `Movie`)

Вторым аргументом будет наш `select` в виде ключевого списка.

#### Конструирование FROM при помощи выражения

FROM-запрос можно также сконструировать при помощи выражения с использованием функции `select/3`. Первый аргумент обязательно должен быть модулем, реализующим протокол `Ecto.Queryable` (всё тот же `Movie`). Второй – список "псевдонимов" для модуля, и, наконец, третий – в каком виде мы хотим получить результат:

```elixir
iex> query = select(Movie, [m], m)
%Ecto.Query<from m in Example.Movie, select: m>
iex> Repo.all(query)

06:16:20.854 [debug] QUERY OK source="movies" db=0.9ms
[
  %Example.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

Имеет смысл использование выражение в случае, когда нам _не нужно_ обращаться к переданной структуре в другой части запроса, например, условия. В примере выше всё именно так – мы _не_ пытаемся получить только фильмы, удовлетворяющие какому-то условию. Таким образом, нет никакой необходимости использовать `in` и, соответственно, ключевой запрос.

### Использование `select`

Функция `Ecto.Query.select/3` используется для составления SELECT-части запроса. Если мы хотим получить только определенные поля, можно перечислить их в виде списка атомов или указания на ключи структуры. Вот пример первого подхода:

```elixir
iex> query = select(Movie, [:title])
%Ecto.Query<from m in Example.Movie, select: [:title]>
iex> Repo.all(query)

15:15:25.842 [debug] QUERY OK source="movies" db=1.3ms
[
  %Example.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: nil,
    tagline: nil,
    title: "Ready Player One"
  }
]
```

Обратите внимание, что мы _не_ использовали `in` в первом аргументе в функции `from`. Это потому, что нам не пришлось обращаться к полям структуры — мы просто передали список атомов в `select`.

Такой подход вернёт структуру, в которой будет заполнено только указанное поле — `title`.

Второй подход работает немного иначе. В этот раз нам _придётся_ использовать `in` для того, чтобы сослаться на структуру и указать поле `title`:

```elixir
iex(15)> query = from(m in Movie, select: m.title)
%Ecto.Query<from m in Example.Movie, select: m.title>
iex(16)> Repo.all(query)

15:06:12.752 [debug] QUERY OK source="movies" db=4.5ms queue=0.1ms
["Ready Player One"]
```

Обратите внимание, что теперь в качестве результата мы получили список значений.

### Использование `where`

Выражение `where` используется для составления WHERE-части запроса. В случае нескольких выражений они будут объединены при помощи `WHERE AND` в языке SQL.

```elixir
iex> query = from(m in Movie, where: m.title == "Ready Player One")
%Ecto.Query<from m in Example.Movie, where: m.title == "Ready Player One">
iex> Repo.all(query)

15:18:35.355 [debug] QUERY OK source="movies" db=4.1ms queue=0.1ms
[
  %Example.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

Можно комбинировать `where` и `select`:

```elixir
iex> query = from(m in Movie, where: m.title == "Ready Player One", select: m.tagline)
%Ecto.Query<from m in Example.Movie, where: m.title == "Ready Player One", select: m.tagline>
iex> Repo.all(query)

15:19:11.904 [debug] QUERY OK source="movies" db=4.1ms
["Something about video games"]
```

### Интерполяция в `where`

Чтобы интерполировать значения в наших `where`, необходимо использовать `^` или, как его ещё называют, оператор фиксации (pin). Это позволяет нам  _зафиксировать_ значение в переменной и обратиться к нему после, вместо того, чтобы перезаписать переменную.

```elixir
iex> title = "Ready Player One"
"Ready Player One"
iex> query = from(m in Movie, where: m.title == ^title, select: m.tagline)
%Ecto.Query<from m in Example.Movie, where: m.title == ^"Ready Player One",
 select: m.tagline>
iex> Repo.all(query)

15:21:46.809 [debug] QUERY OK source="movies" db=3.8ms
["Something about video games"]
```

### Получение первой и последней записей

Можно получить первую или последнюю запись из репозитория при помощи функций `Ecto.Query.first/2` и `Ecto.Query.last/2`.

Для начала сконструируем запрос при помощи функции `first/2`:

```elixir
iex> first(Movie)
%Ecto.Query<from m in Example.Movie, order_by: [desc: m.id], limit: 1>
```

Потом передадим его в `Repo.one/2`, чтобы получить результат:

```elixir
iex> Movie |> first() |> Repo.one()

06:36:14.234 [debug] QUERY OK source="movies" db=3.7ms
%Example.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Функция `Ecto.Query.last/2` используется аналогично:

```elixir
iex> Movie |> last() |> Repo.one()
```

## Получение связанных данных

### Предзагрузка

Чтобы иметь доступ к записям, связанным при помощи макросов `belongs_to`, `has_many` и `has_one`, нам нужно _предзагрузить_ соответствующие схемы.

Давайте посмотрим, что случится, если мы попытаемся получить актёров из фильма:

```elixir
iex> movie = Repo.get(Movie, 1)
iex> movie.actors
%Ecto.Association.NotLoaded<association :actors is not loaded>
```

Без предзагрузки этого сделать _не получится_. Существует несколько способов выполнить предзагрузку в Ecto.

#### Предзагрузка двумя запросами

Следующий запрос предзагрузит связанные записи _отдельным_ запросом.

```elixir
iex> Repo.all(from m in Movie, preload: [:actors])

13:17:28.354 [debug] QUERY OK source="movies" db=2.3ms queue=0.1ms
13:17:28.357 [debug] QUERY OK source="actors" db=2.4ms
[
  %Example.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Example.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Bob"
      },
      %Example.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 2,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Gary"
      }
    ],
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

Видно, что код выше сделал _два_ запроса к базе данных. Один для всех фильмов, и ещё один для актёров, связанных с фильмами с определёнными ID.


#### Предзагрузка одним запросом
Можно избавиться от лишнего запроса следующим способом:

```elixir
iex> query = from(m in Movie, join: a in assoc(m, :actors), preload: [actors: a])
iex> Repo.all(query)

13:18:52.053 [debug] QUERY OK source="movies" db=3.7ms
[
  %Example.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Example.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Bob"
      },
      %Example.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 2,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Gary"
      }
    ],
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

Как видим, это позволило вместить всё в один запрос к базе. Это также позволит нам фильтровать в одном запросе как фильмы, так и актёров. Например, при помощи `join` можно получить все фильмы, где актёры удовлетворяют определённому условию. Что-то в этом роде:

```elixir
Repo.all from m in Movie,
  join: a in assoc(m, :actors),
  where: a.name == "John Wayne",
  preload: [actors: a]
```

Подробнее на `join` остановимся чуть дальше.

#### Предзагрузка уже полученных записей

Мы также можем предзагрузить связанные схемы для записей, уже полученных из базы.

```elixir
iex> movie = Repo.get(Movie, 1)
%Example.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>, # actors are NOT LOADED!!
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
iex> movie = Repo.preload(movie, :actors)
%Example.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Example.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
      id: 1,
      movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Bob"
    },
    %Example.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
      id: 2,
      movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Gary"
    }
  ], # актёры ЗАГРУЖЕНЫ!!
  characters: [],
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Теперь можно получить актёров фильма:

```elixir
iex> movie.actors
[
  %Example.Actor{
    __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
    id: 1,
    movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Bob"
  },
  %Example.Actor{
    __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
    id: 2,
    movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Gary"
  }
]
```

### Использование операции соединения

Функция `Ecto.Query.join/5` позволяет создавать запросы с операциями соединения.

```elixir
iex> query = from m in Movie,
              join: c in Character,
              on: m.id == c.movie_id,
              where: c.name == "Video Game Guy",
              select: {m.title, c.name}
iex> Repo.all(query)
15:28:23.756 [debug] QUERY OK source="movies" db=5.5ms
[{"Ready Player One", "Video Game Guy"}]
```

Выражение `on` также может быть в виде ключевого списка:

```elixir
from m in Movie,
  join: c in Character,
  on: [id: c.movie_id], # ключевой список
  where: c.name == "Video Game Guy",
  select: {m.title, c.name}
```

В примере выше мы выполняем соединение с Ecto-схемой — `m in Movie`. Но мы также можем соединять с Ecto-запросом. Предположим, что в нашей таблице с фильмами есть столбец `stars`, где мы храним среднюю оценку фильма в "звёздах" — от одной до пяти.

```elixir
movies = from m in Movie, where: [stars: 5]
from c in Character,
  join: ^movies,
  on: [id: c.movie_id], # ключевой список
  where: c.name == "Video Game Guy",
  select: {m.title, c.name}
```

Язык запросов Ecto — мощный инструмент, обладающий всем необходимым для построения даже самых сложных запросов к базам данных. В этом уроке мы познакомились с базовыми элементами, необходимыми для конструирования запросов.
