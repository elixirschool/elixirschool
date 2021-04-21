---
version: 1.2.0
title: Язык запросов
---

{% include toc.html %}

В этом уроке мы будем работать над приложением `Friends` для каталогизации фильмов из [предыдущего урока](./associations).

## Получение записей из `Ecto.Repo`

Напомним, что "репозиторием" в Ecto называется хранилище данных, такое как наша база данных Postgres.
Всё взаимодействие с базой будет происходить посредством этого репозитория.

Для начала мы можем выполнять простые запросы напрямую через `Friends.Repo` с помощью пары полезных функций.

### Получение записей по ID

Мы можем использовать функцию `Repo.get/3`, чтобы получить запись из базы по ID. Эта функция принимает два обязательных аргумента: структуру данных, пригодную для запросов, и ID искомой записи. В качестве результата она возвращает запись в виде структуры, если таковая была найдена. В противном случае возвращается `nil`.

В примере ниже мы получаем фильм с ID = 1:

```elixir
iex> alias Friends.{Repo, Movie}
iex> Repo.get(Movie, 1)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Обратите внимание, что первый аргумент, передаваемый в `Repo.get/3`, – это наш модуль `Movie`. Мы называем `Movie` "пригодным для запросов", потому что он определяет схему данных при помощи `Ecto.Schema`. За счёт этого `Movie` реализует протокол `Ecto.Queryable`. Этот протокол позволяет преобразовывать структуры данных в запросы `Ecto.Query`, которые затем используются для получения данных из репозитория. Дальше мы подробнее остановимся на запросах.

### Получение записей по атрибуту

Мы также можем получать данные по заданным критериям при помощи функции `Repo.get_by/3`. Она принимает два значения: подходящую структуру и условие для запроса. `Repo.get_by/3` в качестве результата возвращает одну запись из репозитория. Вот пример:

```elixir
iex> Repo.get_by(Movie, title: "Ready Player One")
%Friends.Movie{
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

Модуль `Ecto.Query` предоставляет собственный язык написания запросов для доступа к данным репозиториев.

### Создание запросов при помощи `Ecto.Query.from/2`

Запрос можно создавать при помощи макроса `Ecto.Query.from/2`. Эта функция принимает два аргумента: выражение и необязательный ключевой список. Попробуем создать максимально простой запрос для получения всех фильмов из нашего репозитория:

```elixir
iex> import Ecto.Query
iex> query = from(Movie)
#Ecto.Query<from m0 in Friends.Movie>
```

Чтобы выполнить запрос, воспользуемся функцией `Repo.all/2`. Она принимает структуру запроса Ecto в качестве обязательного аргумента и возвращает все записи, удовлетворяющие условиям.

```elixir
iex> Repo.all(query)

14:58:03.187 [debug] QUERY OK source="movies" db=1.7ms decode=4.2ms
[
  %Friends.Movie{
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

#### Запросы без привязок

Пример выше не включает в себя самую мякотку языка SQL. Очень часто мы хотим получить из базы только определённые поля или отфильтровать записи по какому-то критерию. Давайте получим только значения полей `title` и `tagline` всех фильмов с названием `"Ready Player One"`:

```elixir
iex> query = from(Movie, where: [title: "Ready Player One"], select: [:title, :tagline])
#Ecto.Query<from m0 in Friends.Movie, where: m0.title == "Ready Player One",
 select: [:title, :tagline]>

iex> Repo.all(query)
SELECT m0."title", m0."tagline" FROM "movies" AS m0 WHERE (m0."title" = 'Ready Player One') []
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    id: nil,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

Обратите внимание, что в результирующих структурах заполнены только поля `tagline` и `title` – это прямое следствие использования блока `select:`.

Запросы вроде этого называют *запросами без привязки* (bindingless), потому что они достаточно просты и не нуждаются в привязках.

#### Привязки в запросах

До этого момента в качестве первого аргумента макроса `from` мы использовали исключительно модуль, реализующий протокол `Ecto.Queryable` (т.е. `Movie`). Но помимо него, мы могли бы использовать особое выражение с `in`:

```elixir
iex> query = from(m in Movie)
#Ecto.Query<from m0 in Friends.Movie>
```

В этом случае мы называем `m` *привязкой*. Привязки нам очень пригодятся, т.к. с их помощью можно ссылаться на структуру в других частях запроса. Например, мы можем достать из базы названия всех фильмов с `id` меньше `2`:

```elixir
iex> query = from(m in Movie, where: m.id < 2, select: m.title)
#Ecto.Query<from m0 in Friends.Movie, where: m0.id < 2, select: m0.title>

iex> Repo.all(query)
SELECT m0."title" FROM "movies" AS m0 WHERE (m0."id" < 2) []
["Ready Player One"]
```

Очень важный момент здесь это как изменился результат выполнения запроса. Использование *выражения* с привязкой в `select:` части запроса позволяет нам явным образом указать, в каком виде мы хотим получить данные. С таким же успехом мы можем попросить функцию вернуть нам кортеж:

```elixir
iex> query = from(m in Movie, where: m.id < 2, select: {m.title})

iex> Repo.all(query)
[{"Ready Player One"}]
```

В целом хорошей идеей будет всегда начинать с простого запроса и добавлять привязки только когда появляется необходимость сослаться на структуру. Больше про привязки в запросах можно прочитать в [документации](https://hexdocs.pm/ecto/Ecto.Query.html#module-query-expressions)


### Запросы на основе макросов

В предыдущих примерах, чтобы сконструировать запрос, мы использовали ключи `select:` и `where:` в параметрах макроса `from`. Про такой способ говорят, что он *основан на ключах* (keyword-based). Но существует также ещё один способ конструировать запросы – основанный на макросах. Ecto предоставляет макросы для каждого ключевого слова, например `select/3` или `where/3`. Каждый макрос принимает сущность, пригодную для запросов, *явный список привязок* и точно такое же выражение, какое мы использовали бы в предыдущем подходе:

```elixir
iex> query = select(Movie, [m], m.title)
#Ecto.Query<from m0 in Friends.Movie, select: m0.title>

iex> Repo.all(query)
SELECT m0."title" FROM "movies" AS m0 []
["Ready Player One"]
```

Что хорошо в макросах, так это то, что они отлично объединяются в конвейер:

```elixir
iex> Movie \
...>  |> where([m], m.id < 2) \
...>  |> select([m], {m.title}) \
...>  |> Repo.all
[{"Ready Player One"}]
```

Обратите внимание, чтобы продолжить запись после разрыва строки, используйте символ `\`.

### Интерполяция в `where`

Чтобы интерполировать значения в WHERE-части запроса, необходимо использовать `^` или, как его ещё называют, оператор фиксации (pin). Это позволяет нам  _зафиксировать_ значение в переменной и обратиться к нему после, вместо того, чтобы перезаписать переменную.

```elixir
iex> title = "Ready Player One"
"Ready Player One"
iex> query = from(m in Movie, where: m.title == ^title, select: m.tagline)
%Ecto.Query<from m in Friends.Movie, where: m.title == ^"Ready Player One",
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
#Ecto.Query<from m0 in Friends.Movie, order_by: [asc: m0.id], limit: 1>
```

Потом передадим его в `Repo.one/2`, чтобы получить результат:

```elixir
iex> Movie |> first() |> Repo.one()

SELECT m0."id", m0."title", m0."tagline" FROM "movies" AS m0 ORDER BY m0."id" LIMIT 1 []
%Friends.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
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
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Tyler Sheridan"
      },
      %Friends.Actor{
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

Видно, что код выше сделал _два_ запроса к базе данных. Один для всех фильмов, и ещё один для актёров, связанных с фильмами, с определёнными ID.


#### Предзагрузка одним запросом
Можно избавиться от лишнего запроса следующим способом:

```elixir
iex> query = from(m in Movie, join: a in assoc(m, :actors), preload: [actors: a])
iex> Repo.all(query)

13:18:52.053 [debug] QUERY OK source="movies" db=3.7ms
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Tyler Sheridan"
      },
      %Friends.Actor{
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
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>, # actors are NOT LOADED!!
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
iex> movie = Repo.preload(movie, :actors)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Friends.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
      id: 1,
      movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Tyler Sheridan"
    },
    %Friends.Actor{
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
  %Friends.Actor{
    __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
    id: 1,
    movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Tyler Sheridan"
  },
  %Friends.Actor{
    __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
    id: 2,
    movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Gary"
  }
]
```

### Использование операции соединения

Функция `Ecto.Query.join/5` позволяет создавать запросы с использованием SQL-оператора `JOIN`.

```elixir
iex> alias Friends.Character
iex> query = from m in Movie,
              join: c in Character,
              on: m.id == c.movie_id,
              where: c.name == "Wade Watts",
              select: {m.title, c.name}
iex> Repo.all(query)
15:28:23.756 [debug] QUERY OK source="movies" db=5.5ms
[{"Ready Player One", "Wade Watts"}]
```

Выражение `on` также может быть в виде ключевого списка:

```elixir
from m in Movie,
  join: c in Character,
  on: [id: c.movie_id], # ключевой список
  where: c.name == "Wade Watts",
  select: {m.title, c.name}
```

В примере выше мы выполняем соединение с Ecto-схемой — `m in Movie`. Но мы также можем соединять с Ecto-запросом. Предположим, что в нашей таблице с фильмами есть столбец `stars`, где мы храним среднюю оценку фильма в "звёздах" — от одной до пяти.

```elixir
movies = from m in Movie, where: [stars: 5]
from c in Character,
  join: ^movies,
  on: [id: c.movie_id], # ключевой список
  where: c.name == "Wade Watts",
  select: {m.title, c.name}
```

Язык запросов Ecto — мощный инструмент, обладающий всем необходимым для построения даже самых сложных запросов к базам данных. В этом уроке мы познакомились с базовыми элементами, необходимыми для конструирования запросов.
