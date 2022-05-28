%{
  version: "1.2.2",
  title: "어소시에이션",
  excerpt: """
  이 단원에서는 Ecto로 스키마 사이의 어소시에이션(Associations)을 정의하는 방법을 배워보겠습니다.
  """
}
---

## 준비 

이전 단원의 데모 앱 `Friends`에서 시작하겠습니다. 준비를 위해 빠르게 복습이 필요하면 [여기](/en/lessons/ecto/basics)를 참고하세요.

## 어소시에이션들의 타입 

스키마 간에 정의할 수 있는 어소시에이션의 종류는 3가지입니다. 각 관계가 무엇이고 어떻게 구현하는지 살펴보겠습니다.

### 종속(Belongs To) 관계/일대다(Has Many) 관계

즐겨보는 영화의 카탈로그를 만들 수 있도록 Friends 앱의 도메인 모델에 몇 가지 새로운 엔티티를 추가합니다. 우선 `Movie`와 `Character` 두 스키마를 추가합니다. 이 스키마들 사이에 "일대다/종속" 관계를 구현할 것인데, 영화(movie)는 복수의 등장인물(character)을 가지며 등장인물 하나는 한 영화에 종속되도록 합니다.

#### 일대다 관계 마이그레이션 

`Movie`의 마이그레이션을 생성합니다.

```console
mix ecto.gen.migration create_movies
```

새로 생성된 마이그레이션 파일을 열고 `change` 함수를 선언하여 몇몇 속성을 가진 `movies` 테이블을 만들도록 합니다.

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

#### 일대다 관계 스키마 

영화와 등장인물 사이에 "일대다" 관계를 지정하는 스키마를 추가합니다.

```elixir
# lib/friends/movie.ex
defmodule Friends.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Friends.Character
  end
end
```

`has_many/3` 매크로는 데이터베이스 자체에 아무것도 추가하지 않습니다. 그저 연관된 스키마인 `characters`의 외래키를 이용해 영화에 연관된 등장인물을 이용할 수 있게 합니다. 즉 `movie.characters`처럼 사용할 수 있습니다.

#### 종속 관계 마이그레이션 

이제 `Character` 마이그레이션과 스키마를 만들 준비가 되었습니다. 한 등장인물은 한 영화에 종속되므로 이 관계를 나타내는 마이그레이션과 스키마를 정의합니다.

먼저 마이그레이션을 생성합니다.

```console
mix ecto.gen.migration create_characters
```

영화에 종속되는 등장인물을 정의하기 위해서는, `movie_id` 컬럼을 가지는 `characters` 테이블이 필요합니다. 이 컬럼은 외래 키로써 동작해야 합니다. 이를 위해 `create table/1` 함수에 다음 한줄을 추가하면 됩니다.

```elixir
add :movie_id, references(:movies)
```

그러면 마이그레이션이 다음과 같습니다.

```elixir
# priv/migrations/*_create_characters.exs
defmodule Friends.Repo.Migrations.CreateCharacters do
  use Ecto.Migration

  def change do
    create table(:characters) do
      add :name, :string
      add :movie_id, references(:movies)
    end
  end
end
```

#### 종속 관계 스키마

마찬가지로 스키마는 등장인물과 영화 사이의 "종속" 관계를 정의해야 합니다.

```elixir
# lib/friends/character.ex

defmodule Friends.Character do
  use Ecto.Schema

  schema "characters" do
    field :name, :string
    belongs_to :movie, Friends.Movie
  end
end
```

`belongs_to/3` 매크로가 무엇을 하는지 자세히 보겠습니다. 스키마에 외래 키 `movie_id`를 추가하는것 외에도, 이 매크로는 `characters`를 통해 연관된 `movies` 스키마에 접근하는 기능을 제공합니다. 외래 키를 사용하여 등장인물을 쿼리할 때 등장인물과 관련된 영화를 이용할 수 있습니다. 즉 `character.movie` 처럼 사용할 수 있습니다.

이제 마이그레이션을 실행할 준비가 되었네요.

```console
mix ecto.migrate
```

### 종속 관계/일대다 관계 

한 영화에 한 배급사가 있다고 가정해보겠습니다. 예를 들어 Netflix는 "Bright" 영화의 배급사입니다.

"종속" 관계로 `Distributor` 마이그레이션 및 스키마를 정의할 것입니다. 우선 마이그레이션을 생성해 보겠습니다.

```console
mix ecto.gen.migration create_distributors
```

생성한 `distributors` 테이블 마이그레이션에 외래 키 `movie_id`와 영화의 배급사가 1명인 것을 나타내는 유니크 인덱스를 추가할 필요가 있습니다.

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

그리고 `Distributor` 스키마는 `belongs_to/3` 매크로를 사용하여 `distributor.movie`를 호출했을 때 위에서의 외래 키를 가지고 한 배급사와 관련된 영화를 조회할 수 있도록 해야 합니다.

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

다음으로 `Movie` 스키마에 "일대일" 관계를 추가하겠습니다.

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

`has_one/3` 매크로는 `has_many/3`와 유사한 기능입니다. 연관 스키마의 외래키로 해당 영화의 배급사를 찾아서 보여줍니다. `movie.distributor`처럼 쓸 수 있습니다.

마이그레이션을 실행해봅시다.

```console
mix ecto.migrate
```

### 다대다 관계 

한 영화가 많은 배우를 가지고 있고 한 배우는 여러 영화에 속해있다고 해봅시다. 이 관계를 구현하려면 영화와 배우를 _둘 다_ 참조하는 조인 테이블을 만들어야 합니다.

우선 `Actors` 마이그레이션을 만듭니다.

```console
mix ecto.gen.migration create_actors
```

마이그레이션을 정의합니다.

```elixir
# priv/migrations/*_create_actors.ex

defmodule Friends.Repo.Migrations.CreateActors do
  use Ecto.Migration

  def change do
    create table(:actors) do
      add :name, :string
    end
  end
end
```

조인 테이블 마이그레이션을 생성합시다.

```console
mix ecto.gen.migration create_movies_actors
```

마이그레이션에 두 개의 외래키를 가진 테이블을 정의했습니다. 또한 유니크 인덱스를 추가해 한 배우는 한 영화와 하나의 쌍으로만 묶이도록 합니다.

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

그 다음 `many_to_many` 매크로를 `Movie` 스키마에 추가합시다.

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

마지막으로 `Actor` 스키마에도 역시 `many_to_many` 매크로를 정의합니다.

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

마이그레이션을 실행합니다.

```console
mix ecto.migrate
```

## 연관 데이터 저장 

어떤 레코드를 연관 데이터와 함께 저장하는 방법은 어떤 관계 속성이냐에 달려있습니다. "종속 관계/일대다 관계"부터 시작해봅시다.

### 종속 관계 

#### Ecto.build_assoc/3 이용한 저장

"종속 관계" 에서는 Ecto의 `build_assoc/3` 함수를 사용할 수 있습니다.

[`build_assoc/3`](https://hexdocs.pm/ecto/Ecto.html#build_assoc/3)는 다음 3가지 인자를 받습니다.

* 저장할 레코드의 구조체
* 어소시에이션의 이름
* 저장할 연관 레코드에 할당할 속성들

영화 하나와 연관된 등장인물을 저장해봅시다. 먼저 영화 레코드를 하나 생성합니다.

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

이제 연관된 등장인물을 만들고 데이터베이스에 삽입합니다.

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

`Movie` 스키마의 `has_many/3` 매크로가 한 영화가 여러 `:characters`를 가지고 있다고 명시하기 때문에 `build_assoc/3`의 두 번째 인자로 `:characters`를 넘긴다는걸 기억하세요. 생성한 등장인물이 그와 연관된 영화의 ID인 `move_id`가 올바르게 설정되었음을 알 수 있습니다.

한 영화의 연관 배급사를 `build_assoc/3` 으로 저장하기 위해 영화의 배급사 관계 이름을 두 번째 인자로 넘깁니다.

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

### 다대다 관계 

#### Ecto.Changeset.put_assoc/4 이용한 저장

다대다 관계에는 `build_assoc/3`를 쓰지 않습니다. 영화나 배우 테이블 둘다 외래키가 없기 떄문입니다. 그 대신, Ecto Changeset과 `put_assoc/4` 함수를 이용하겠습니다.

위에서 생성한 영화 레코드를 사용한다고 가정하고, 배우 레코드를 생성합시다.

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

이제 영화를 조인 테이블을 통해 배우와 연결할 준비가 됐습니다.

우선 유의해야할 점은 체인지셋을 사용하려면 `movie` 구조체가 연관 데이터를 프리로드한 상태여야 합니다. 데이터를 프리로드하는건 추후에 자세히 다뤄보겠습니다. 일단 지금은 다음과 같이 어소시에이션들을 프리로드할 수 있다는 것만 알아두세요.

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

다음은 영화 레코드의 체인지셋을 생성합니다.

```elixir
iex> movie_changeset = Ecto.Changeset.change(movie)
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Movie<>,
 valid?: true>
```

이제 [`Ecto.Changeset.put_assoc/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#put_assoc/4)에 그 체인지셋을 첫번째 인자로 전달합니다.

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

이것은 새로운 체인지셋을 반환하는데, 주어진 영화 레코드의 actors 필드에 배우 목록을 추가하는 변경사항을 보여줍니다.

마지막으로 주어진 영화와 배우 레코드를 최신 체인지셋을 사용해 업데이트합니다.

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

이렇게 하면 영화 레코드에 새 배우 레코드가 적절히 연결되고 `movie.actors`에 프리로드된 상태로 보여집니다.

같은 방식으로 주어진 영화에 연결된 또다른 배우를 생성 할 수 있습니다. 미리 _저장된_ 배우를 `put_assoc/4`에 넘기는 대신, 생성하고자 하는 새 배우의 속성들이 들어있는 맵을 전달해도 됩니다.

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

새 배우가 ID "2"로 생성되었고 지정했던 속성들이 잘 들어있습니다.

다음 섹션에서는 연관된 레코드를 어떻게 쿼리하는지 배워보겠습니다.
