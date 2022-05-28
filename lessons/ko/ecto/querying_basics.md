%{
  version: "1.2.1",
  title: "Querying",
  excerpt: """
  """
}
---

이 단원에서는 `Friends` 애플리케이션을 [이전 단원](/ko/lessons/ecto/associations)에서 준비한 영화-카탈로그 도메인을 이어서 만들어보겠습니다.

## Ecto.Repo로 DB 레코드 조회

이전 단원에서 Ecto의 "레포지토리"는 Postgres 데이터베이스 같은 데이터 저장소에 매핑된다고 했었습니다.
데이터베이스와의 모든 상호작용은 이 레포지토리를 통해 이뤄집니다.

`Friends.Repo`의 함수들을 사용하여 간단한 쿼리들을 직접 실행해볼 수 있습니다.

### ID로 레코드 조회 

데이터베이스에서 레코드를 ID로 조회하기 위해 `Repo.get/3` 함수를 사용할 수 있습니다. 이 함수는 2개의 인자로 "쿼리가능한(queryable)" 자료구조와 조회할 레코드의 ID를 받습니다. 레코드를 찾았다면 해당 구조체를 반환하고, 아니면 `nil`을 반환합니다.

예제를 한번 봅시다. 아래와 같이 ID가 1인 영화를 조회합니다.

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

`Repo.get/3`에 전달하는 첫 번째 인자는 `Movie` 모듈입니다. `Movie`는 "쿼리가능"합니다. 모듈이 `Ecto.Schema`를 사용하고 자료구조를 스키마로 정의하고 있기 때문입니다. 그러면 `Movie`가 `Ecto.Queryable` 프로토콜에 접근할 수 있는데, 이 프로토콜은 자료 구조를 `Ecto.Query`로 전환합니다. Ecto 쿼리는 레포지토리에서 데이터를 조회할 때 쓰입니다. 쿼리에 관해서는 추후 좀 더 알아보겠습니다.

### 속성으로 레코드 조회 

주어진 조건을 만족하는 레코드를 조회하는 것도 `Repo.get_by/3` 함수로 가능합니다. 이 함수는 2개의 인자로 "쿼리가능한" 자료구조와 쿼리할 절을 요구합니다. `Repo.get_by/3`은 레포지토리에서 받은 결과 하나를 반환합니다. 예제를 보겠습니다.

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

더 복잡한 쿼리를 작성하거나 특정 조건을 만족하는 _모든_ 레코드를 조회하고 싶다면 `Ecto.Query` 모듈을 사용해야 합니다.

## Ecto.Query로 쿼리 작성하기

`Ecto.Query` 모듈에서 제공하는 Query DSL로 애플리케이션 레포지토리에서 데이터를 조회하는 쿼리를 작성할 수 있습니다.

### Ecto.Query.from/2와 키워드 기반 쿼리

`Ecto.Query.from/2` 매크로로 쿼리를 만들 수 있습니다. 이 함수는 인자로 표현식 하나와 옵셔널 인자로 키워드 리스트를 받습니다. 레포지토리에서 모든 영화를 조회하는 가장 단순한 쿼리를 만들어 봅시다.

```elixir
iex> import Ecto.Query
iex> query = from(Movie)
#Ecto.Query<from m0 in Friends.Movie>
```

쿼리를 실행하기 위해 `Repo.all/2` 함수를 사용합니다. 이 함수는 필수 인자인 Ecto 쿼리를 가지고 쿼리 조건을 충족하는 모든 레코드를 반환합니다.

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

#### from과 바인딩없는 쿼리

위 예제는 SQL문의 가장 흥미로운 부분이 빠졌습니다. 보통은 특정 필드만 쿼리하거나 특정 조건으로 필터링하여 쿼리하는 경우가 많습니다. 모든 영화 중에 `Ready Player One` 제목을 가진 영화만 조회하되 `title`과 `tagline`필드만 불러옵시다.

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

반환된 구조체는 `tagline`과 `title` 필드만 값이 들어있음에 유의하세요. 이는 `select:` 부분의 결과입니다.

이런 쿼리는 바인딩이 필요없을정도로 간단하므로 바인딩없는 쿼리라 불립니다.

#### 쿼리의 바인딩 

지금까지 `Ecto.Queryable` 프로토콜을 구현한 모듈 하나(예: `Movie`)를 `from` 매크로의 첫 번째 인자로 사용했습니다. 하지만 다음처럼 `in` 표현식도 사용가능합니다.

```elixir
iex> query = from(m in Movie)
#Ecto.Query<from m0 in Friends.Movie>
```

이 경우 `m`을 _바인딩_ 이라고 표현합니다. 바인딩을 사용하면 쿼리의 다른 부분에서 모듈들을 참조할수 있어 매우 유용합니다. 영화의 제목 필드만 선택하고 `id`가 `2`보다 작은 영화들만 조회해봅시다.

```elixir
iex> query = from(m in Movie, where: m.id < 2, select: m.title)
#Ecto.Query<from m0 in Friends.Movie, where: m0.id < 2, select: m0.title>

iex> Repo.all(query)
SELECT m0."title" FROM "movies" AS m0 WHERE (m0."id" < 2) []
["Ready Player One"]
```

여기서 쿼리의 출력이 변경된것에 주목하세요. `select:` 부분에서 *표현식*을 바인딩과 사용함으로써 선택된 필드들이 반환될 형태를 정확하게 명시할 수 있습니다. 예를 들면 다음처럼 튜플로 반환시킬 수 있습니다.

```elixir
iex> query = from(m in Movie, where: m.id < 2, select: {m.title})

iex> Repo.all(query)
[{"Ready Player One"}]
```

처음엔 바인딩없는 간단한 쿼리로 시작하고 데이터 구조를 참조해야할 때 바인딩을 쓰는것이 좋습니다. 쿼리의 바인딩에 관한 더 많은 정보는 [Ecto 공식 문서](https://hexdocs.pm/ecto/Ecto.Query.html#module-query-expressions)를 참고하세요.


### 매크로기반 쿼리 

위 예제에서 쿼리를 작성하기위해 `from`매크로 안에서 `select:`와 `where:`같은 키워드를 사용하는걸 *키워드기반 쿼리*라고 합니다. 쿼리를 조합하는 다른 방법은 매크로 기반 쿼리입니다. Ecto는 `select/3`이나 `where/3`같은 각 키워드에 해당하는 매크로들을 제공합니다. 각 매크로는 *쿼리가능한* 값과 *명시된 바인딩 리스트* 그리고 키워드문에 썼던 동일한 표현식을 인자로 받습니다.

```elixir
iex> query = select(Movie, [m], m.title)
#Ecto.Query<from m0 in Friends.Movie, select: m0.title>

iex> Repo.all(query)
SELECT m0."title" FROM "movies" AS m0 []
["Ready Player One"]
```

매크로의 좋은점은 파이프로 깔끔하게 연결된다는 점입니다.

```elixir
iex> Movie \
...>  |> where([m], m.id < 2) \
...>  |> select([m], {m.title}) \
...>  |> Repo.all
[{"Ready Player One"}]
```

위 iex에서 다음줄에 이어서 작성하기 위해 `\` 문자를 썼음에 유의하세요.

### 보간(Interpolated)값과 where 사용

where절 안에서 보간값이나 Elixir 표현식을 사용하기 위해 핀 연산자 `^`이 필요합니다. 이것은 핀 꽂듯이 값을 변수에 고정해서 변수가 재 바인딩 되지 않고 해당 값을 가리키게 합니다.

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

### 첫 레코드나 마지막 레코드 조회 

`Ecto.Query.first/2`나 `Ecto.Query.last/2` 함수로 레포지토리에서 첫 레코드나 마지막 레코드만 불러올수 있습니다.

우선 `first/2` 함수를 이용해 쿼리 표현식을 작성합니다.

```elixir
iex> first(Movie)
#Ecto.Query<from m0 in Friends.Movie, order_by: [asc: m0.id], limit: 1>
```

그런 다음 결과를 얻기 위해 `Repo.one/2` 함수에 쿼리를 전달합니다.

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

`Ecto.Query.last/2` 함수도 똑같이 사용합니다.

```elixir
iex> Movie |> last() |> Repo.one()
```

## 연관 데이터 쿼리 

### 프리로드 

`belongs_to`, `has_many`, `has_one` 매크로로 정의된 연관 레코드에 접근 가능하게 하기 위해 연관된 스키마를 _프리로드_ 해야합니다.

한 영화에 연관된 배우들을 요청하려고 할 때 어떤일이 발생하는지 보겠습니다.

```elixir
iex> movie = Repo.get(Movie, 1)
iex> movie.actors
%Ecto.Association.NotLoaded<association :actors is not loaded>
```

프리로드 하지 않고서는 연관된 배우들에 접근할 수 없습니다. Ecto로 레코드를 프리로드하는 몇가지 방법이 있습니다.

#### 두 쿼리로 프리로드 

다음 쿼리는 연관 레코드를 _별개의_ 쿼리로 프리로드 합니다.

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

위 코드라인에서 두 데이터베이스 쿼리를 실행했음을 알 수 있습니다. 하나는 모든 영화를, 다른 하나는 해당 영화들의 ID로 연관된 모든 배우들을 조회했습니다.


#### 한 쿼리로 프리로드하기 
다음처럼 하면 데이터베이스 쿼리를 줄일 수 있습니다.

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

이렇게하면 데이터베이스 호출이 한번만 됩니다. 또한 영화와 연관된 배우들 둘 다에 대해 한 쿼리에서 필드 선택과 필터링이 가능합니다. 예를 들어 `join` 문을 써서 모든 영화중에 연관된 배우들이 특정 조건만 만족하는 영화들만 조회할 수 있습니다.

```elixir
Repo.all from m in Movie,
  join: a in assoc(m, :actors),
  where: a.name == "John Wayne",
  preload: [actors: a]
```

join문에 대해서는 조금 뒤에 더 살펴보겠습니다.

#### 조회된 레코드 프리로드 

데이터베이스에서 이미 쿼리되어 나온 레코드의 연관 스키마도 프리로드 할 수 있습니다.

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
  ], # actors are LOADED!!
  characters: [],
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

이제 영화의 배우들을 다음처럼 요청합니다.

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

### Join문 사용하기

`Ecto.Query.join/5` 함수를 이용해 join문을 포함한 쿼리를 실행할 수 있습니다.

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

`on` 표현식은 키워드 리스트도 쓸 수 있습니다.

```elixir
from m in Movie,
  join: c in Character,
  on: [id: c.movie_id], # keyword list
  where: c.name == "Wade Watts",
  select: {m.title, c.name}
```

위 예제에서 `m in Movie`로 Ecto 스키마를 조인했습니다. Ecto query에도 조인할 수 있습니다. 영화 테이블에 1에서 5까지의 숫자로 된 "별점"을 나타내는 `stars` 컬럼이 있다고 해봅시다.

```elixir
movies = from m in Movie, where: [stars: 5]
from c in Character,
  join: ^movies,
  on: [id: c.movie_id], # keyword list
  where: c.name == "Wade Watts",
  select: {m.title, c.name}
```

Ecto Query DSL은 복잡한 데이터베이스 쿼리를 만드는 데 필요한 모든 것을 제공하는 강력한 도구입니다. 이 단원에서는 쿼리를 시작하는데 필요한 기본 초석 정도를 소개했습니다.
