%{
  version: "2.4.0",
  title: "Basics",
  excerpt: """
  Ecto는 공식적인 Elixir 프로젝트로 데이터베이스를 감싸는 부분과 종합적인 질의 언어를 제공합니다. Ecto를 사용하면 마이그레이션의 생성과 모델의 정의, 레코드의 추가와 삭제, 그리고 질의를 할 수 있게 됩니다.
  """
}
---

### 어댑터

Ecto는 어댑터를 이용해 서로 다른 데이터베이스를 지원합니다. 몇 가지 어댑터는 다음과 같습니다.

* PostgreSQL
* MySQL
* SQLite

이 단원에서는 Ecto가 PostgreSQL 어댑터를 사용하도록 설정하겠습니다.

### 시작하기

이 단원의 과정에서 Ecto의 3가지 파트를 다룰 것입니다.

* 레포지토리 - 커넥션을 포함한 데이터베이스의 인터페이스 제공
* 마이그레이션 — 데이터베이스 테이블과 인덱스의 생성, 변경, 삭제 매커니즘
* 스키마 — 데이터베이스 테이블 엔트리를 나타내는 특정 구조체

시작해보자면 슈퍼비전 트리를 포함한 새 애플리케이션을 생성합니다.

```shell
$ mix new friends --sup
$ cd friends
```

ecto와 postgrex 패키지를 `mix.exs` 파일의 의존성 목록에 추가합니다.

```elixir
  defp deps do
    [
      {:ecto_sql, "~> 3.2"},
      {:postgrex, "~> 0.15"}
    ]
  end
```

아래 명령어를 통해 의존성 있는 라이브러리를 가져옵니다.

```shell
$ mix deps.get
```

#### 레포지토리 생성

Ecto의 레포지토리는 Postgres 데이터베이스같은 데이터 저장소라 할 수 있습니다.
데이터베이스와의 모든 커뮤니케이션은 이 레포지토리를 이용해서 이루어집니다.

다음 명령어를 실행하여 레포지토리를 설정합니다.

```shell
$ mix ecto.gen.repo -r Friends.Repo
```

위 명령어로 사용할 어댑터를 포함하여 데이터베이스에 연결하기 위해 필요한 설정들이 `config/config.exs`에 생성됩니다.
이것이 `Friends` 애플리케이션의 설정 파일입니다.

```elixir
config :friends, Friends.Repo,
  database: "friends_repo",
  username: "postgres",
  password: "",
  hostname: "localhost"
```

이렇게 Ecto가 데이터베이스에 연결할 방법을 구성합니다. 연결하고자 하는 데이터베이스와 일치하는 인증정보를 입력해야 합니다.

또한 `Friends.Repo` 모듈이 `lib/friends/repo.ex` 파일에 생성됩니다.

```elixir
defmodule Friends.Repo do
  use Ecto.Repo, 
    otp_app: :friends,
    adapter: Ecto.Adapters.Postgres
end
```

`Friends.Repo` 모듈을 사용하여 데이터베이스에 쿼리할 것입니다. 또한 데이터베이스 설정 정보는 `:friends` Elixir 애플리케이션에서 찾도록 하고 어댑터는 `Ecto.Adapters.Postgres`로 선택했습니다.

이제 `Friends.Repo`를 하나의 슈퍼바이저로 `lib/friends/application.ex` 파일 안의 애플리케이션 슈퍼비전 트리에 넣으세요.
그러면 애플리케이션 시작시 Ecto 프로세스를 띄우게 됩니다.

```elixir
  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      Friends.Repo,
    ]

  ...
```

그런 다음 `config/config.exs` 파일에 다음과 같이 추가해야 합니다.

```elixir
config :friends, ecto_repos: [Friends.Repo]
```

이렇게 하면 ecto mix 명령어를 커맨드라인에서 실행할 수 있습니다.

레포지토리의 설정을 마쳤습니다!
이제 다음 명령어로 postgres 안에 데이터베이스를 생성해봅시다.

```shell
$ mix ecto.create
```

Ecto는 `config/config.exs` 파일 안의 정보로 Postgres와 연결할 방법과 데이터베이스에 전달할 이름을 판단하게 됩니다.

오류가 뜬다면 설정 정보가 올바른지, postgres가 구동중인지 확인해주세요.

### 마이그레이션

Ecto에서 postgres 데이터베이스의 테이블을 생성하거나 변경하는 방법은 마이그레이션입니다.
각 마이그레이션은 어떤 테이블을 생성하거나 변경할지와 같은, 데이터베이스에 실행할 액션들을 나타냅니다.

지금 우리의 데이터베이스는 아무 테이블도 없는 상태입니다. 테이블 생성을 위한 마이그레이션을 추가해 보겠습니다.
Ecto에서는 관례적으로 테이블 이름에 복수형을 쓰고 있습니다. 우선 `people` 테이블을 마이그레이션으로 생성해보겠습니다.

마이그레이션을 생성하는 가장 좋은 방법은 `ecto.gen.migration <name>` 믹스 태스크를 사용하는 것입니다. 다음과 같이 실행해 봅시다.

```shell
$ mix ecto.gen.migration create_people
```

`priv/repo/migrations` 폴더에 타임스탬프가 포함된 이름으로 새 파일이 하나 생성됩니다.
폴더로 가서 마이그레이션을 열어보면 다음과 같은 내용을 볼 수 있습니다.

```elixir
defmodule Friends.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do

  end
end
```

`change/0` 함수를 수정해서 `people` 테이블을 생성하고 `name`과 `age` 필드를 추가해봅시다.

```elixir
defmodule Friends.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do
    create table(:people) do
      add :name, :string, null: false
      add :age, :integer, default: 0
    end
  end
end
```

보시다시피 컬럼의 데이터 타입도 정의했습니다.
추가로 옵션값 `null: false`와 `default: 0`을 설정했습니다.

shell에서 마이그레이션을 실행해봅시다.

```shell
$ mix ecto.migrate
```

### 스키마

이제 생성한 테이블을 Ecto의 스키마를 통해 더 자세히 다뤄보겠습니다.
스키마는 데이터베이스 테이블 필드들의 매핑을 정의하는 모듈입니다.

Ecto에서 데이터베이스 테이블 이름으로는 복수형을 선호하지만 스키마 이름은 보통 단수형입니다. 여기서는 앞서 만든 테이블에 사용할 `Person` 스키마를 만들어보겠습니다.

`lib/friends/person.ex` 파일에 스키마를 만들어 봅시다.

```elixir
defmodule Friends.Person do
  use Ecto.Schema

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

`Friends.Person` 모듈은 Ecto로 이 스키마가 `people` 테이블과 연결되고 두 컬럼을 가졌음을 정의했는데, `name` 컬럼은 string이고 `age` 컬럼은 integer 타입이며 기본값은 `0`입니다.

`iex -S mix`를 열고 새로운 person 하나를 생성해 스키마가 만들어진걸 보겠습니다.

```elixir
iex> %Friends.Person{}
%Friends.Person{age: 0, name: nil}
```

기대한대로 새 `Person` 하나를 얻었고 `age`는 기본값이 들어가 있습니다.
제대로 된 person을 만들어 봅시다.

```elixir
iex> person = %Friends.Person{name: "Tom", age: 11}
%Friends.Person{age: 11, name: "Tom"}
```

스키마는 그저 구조체라서 보통의 구조체처럼 상호작용 할수 있습니다.

```elixir
iex> person.name
"Tom"
iex> Map.get(person, :name)
"Tom"
iex> %{name: name} = person
%Friends.Person{age: 11, name: "Tom"}
iex> name
"Tom"
```

비슷하게 보통 Elixir map이나 구조체처럼 변경도 가능합니다.

```elixir
iex> %{person | age: 18}
%Friends.Person{age: 18, name: "Tom"}
iex> Map.put(person, :name, "Jerry")
%Friends.Person{age: 18, name: "Jerry"}
```

Changeset에 대한 다음 단원에서는 데이터 변경 사항을 검증하는 방법과 데이터베이스에 저장하는지 살펴보겠습니다.
