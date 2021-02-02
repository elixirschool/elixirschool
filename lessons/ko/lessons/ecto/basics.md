%{
  version: "1.2.0",
  title: "Basics",
  excerpt: """
  Ecto는 공식적인 Elixir 프로젝트로 데이터베이스를 감싸는 부분과 종합적인 질의 언어를 제공합니다. Ecto를 사용하면 마이그레이션의 생성과 모델의 정의, 레코드의 추가와 삭제, 그리고 질의를 할 수 있게 됩니다.
  """
}
---

## 설정하기

슈퍼바이저 트리를 포함해서 새 애플리케이션을 생성합니다.

```shell
$ mix new example_app --sup
$ cd example_app
```

우선 Ecto와 데이터베이스 어댑터를 프로젝트의 `mix.exs`에 추가해야 합니다. 지원하는 데이터베이스 어댑터의 목록은 Ecto의 README에 있는 [Usage](https://github.com/elixir-lang/ecto/blob/master/README.md#usage)에서 확인할 수 있습니다. 이 예제에서는 PostgreSQL을 사용합니다.

```elixir
defp deps do
  [{:ecto, "~> 2.2"}, {:postgrex, ">= 0.0.0"}]
end
```

아래 명령어를 통해 의존성 있는 라이브러리를 가져옵니다.

```shell
$ mix deps.get
```

### 저장소

마지막으로 프로젝트의 저장소, 다시 말해 데이터베이스를 감싸는 부분을 생성해야 합니다. 이는 `mix ecto.gen.repo -r FriendsApp.Repo` 태스크로 생성할 수 있습니다. 다른 mix 태스크에 대해서는 나중에 알아보겠습니다. 생성된 저장소(Repo 모듈)는 `lib/<project name>/repo.ex`에 저장됩니다.

```elixir
defmodule FriendsApp.Repo do
  use Ecto.Repo, otp_app: :example_app
end
```

### 슈퍼바이저

Repo를 생성한 뒤에는 슈퍼바이저 트리를 설정해야 합니다. 이는 보통 `lib/<project name>.ex`에 있습니다. Repo를 `children` 목록에 추가해 주세요:

```elixir
defmodule FriendsApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      FriendsApp.Repo
    ]

    opts = [strategy: :one_for_one, name: FriendsApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

슈퍼바이저에 대한 더 자세한 정보는 [OTP 슈퍼바이저](../../advanced/otp-supervisors) 수업을 확인해주세요.

### 설정

Ecto를 설정하려면 `config/config.exs`에 정보를 추가해야 합니다. 여기에서는 저장소나 어댑터, 데이터베이스, 계정 정보를 저장합니다.

```elixir
config :example_app, FriendsApp.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "example_app",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
```

## Mix 태스크

Ecto에는 데이터베이스와 작업할 때에 도움이 되는 Mix 태스크들이 존재합니다.

```shell
mix ecto.create         # 저장소에 공간을 생성합니다
mix ecto.drop           # 저장소의 공간을 삭제합니다
mix ecto.gen.migration  # 저장소의 새로운 마이그레이션을 생성합니다
mix ecto.gen.repo       # 새로운 저장소를 생성합니다
mix ecto.migrate        # 저장소의 마이그레이션을 실행합니다
mix ecto.rollback       # 저장소의 마이그레이션을 롤백합니다
```

## 마이그레이션

마이그레이션을 생성하는 가장 좋은 방법은 `mix ecto.gen.migration <name>` 태스크를 사용하는 것입니다. ActiveRecord를 사용해 보셨으면 무척 친숙할 것입니다.

사용자 테이블의 마이그레이션을 확인해봅시다.

```elixir
defmodule FriendsApp.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:username, :string, unique: true)
      add(:encrypted_password, :string, null: false)
      add(:email, :string)
      add(:confirmed, :boolean, default: false)

      timestamps
    end

    create(unique_index(:users, [:username], name: :unique_usernames))
  end
end
```

초기 상태에서 Ecto는 자동으로 증가하는 기본키 `id`를 생성합니다. 이 예제에서는 표준적인 `change/0` 콜백을 사용하지만, Ecto에는 보다 세밀한 제어가 필요하다면 Ecto에는 `up/0`과 `down/0`도 지원하고 있습니다.

`timestamps`를 마이그레이션에 추가하면 추측하신 대로, `created_at`과 `updated_at`을 생성하고 관리합니다.

이 새로운 마이그레이션을 적용하려면 `mix ecto.migrate`를 실행해주세요.

마이그레이션의 더 자세한 정보는 Ecto 문서의 [Ecto.Migration](http://hexdocs.pm/ecto/Ecto.Migration.html#content)을 참고해주세요.

## 스키마

마이그레이션이 생성되었으므로 이제 스키마로 넘어갑시다. 스키마는 내부의 데이터베이스 테이블과 그 필드와의 매핑, 헬퍼 메소드, 그리고 changeset을 정의하는 모듈입니다. changeset에 대해서는 뒤에서 다룹니다.

우선 마이그레이션을 위한 스키마가 어떤 것인지 확인해보죠.

```elixir
defmodule FriendsApp.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:username, :string)
    field(:encrypted_password, :string)
    field(:email, :string)
    field(:confirmed, :boolean, default: false)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)

    timestamps
  end

  @required_fields ~w(username encrypted_password email)
  @optional_fields ~w()

  def changeset(user, params \\ :empty) do
    user
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:username)
  end
end
```

정의된 스키마는 마이그레이션에 기술했던 것과 밀접하게 표현됩니다. 여기에서는 데이터베이스의 필드 이외에도 2개의 가상 필드가 추가되어 있습니다. 가상 필드는 데이터베이스에는 저장되지 않습니다만, 검증과 같은 작업에서 도움이 됩니다. 가상 필드에 대해서는 [Changeset](#changeset)에서 살펴봅니다.

## 질의

저장소에 질의하기 위해서는 질의 API를 가져와야 합니다만, 여기에서는 `from/2`만을 가져오는 것으로 충분합니다.

```elixir
import Ecto.Query, only: [from: 2]
```

질의 API의 공식 문서는 [Ecto.Query](http://hexdocs.pm/ecto/Ecto.Query.html)에서 찾아보실 수 있습니다.

### 기본

Ecto은 멋진 질의 DSL을 제공하고 있으며, 질의를 이해하기 쉬운 형태로 표현할 수 있습니다. 모든 승인된 계정의 사용자 이름을 검색하는 경우, 다음과 같은 질의를 사용할 수 있을 겁니다.

```elixir
alias FriendsApp.{Repo, User}

query =
  from(
    u in User,
    where: u.confirmed == true,
    select: u.username
  )

Repo.all(query)
```

`all/2`뿐 아니라 Repo는 `one/2`나 `get/3`, `insert/2`, `delete/2`를 포함하는 많은 콜백을 제공하고 있습니다. 모든 콜백의 목록은 [Ecto.Repo#callbacks](http://hexdocs.pm/ecto/Ecto.Repo.html#callbacks)에서 확인하실 수 있습니다.

### Count

승인된 사용자의 숫자를 세고 싶은 경우에 `count/1`을 사용할 수 있습니다.

```elixir
query =
  from(
    u in User,
    where: u.confirmed == true,
    select: count(u.id)
  )
```

주어진 엔트리에서 유일한 값만을 세는 `count/2` 함수도 있습니다.

```elixir
query =
  from(
    u in User,
    where: u.confirmed == true,
    select: count(u.id, :distinct)
  )
```

### Group By

사용자들을 승인 상태별로 묶고 싶은 경우에는 `group_by` 옵션을 추가하세요.

```elixir
query =
  from(
    u in User,
    group_by: u.confirmed,
    select: [u.confirmed, count(u.id)]
  )

Repo.all(query)
```

### Order By

사용자를 작성일 순서로 정렬하려면 이렇게 하시면 됩니다.

```elixir
query =
  from(
    u in User,
    order_by: u.inserted_at,
    select: [u.username, u.inserted_at]
  )

Repo.all(query)
```

`DESC`로 정렬하려면 이렇게 하세요.

```elixir
query =
  from(
    u in User,
    order_by: [desc: u.inserted_at],
    select: [u.username, u.inserted_at]
  )
```

### 조인

사용자에 연관된 프로필이 있다고 가정하고, 모든 승인된 계정의 프로필을 검색해보죠.

```elixir
query =
  from(
    p in Profile,
    join: u in assoc(p, :user),
    where: u.confirmed == true
  )
```

### Fragment

때때로, 예를 들어 특정 데이터베이스에서만 사용 가능한 함수를 쓰고 싶은 경우 등, 질의 API로는 충분하지 않은 경우가 있습니다. `fragment/1` 함수는 이럴 때 사용할 수 있습니다.

```elixir
query =
  from(
    u in User,
    where: fragment("downcase(?)", u.username) == ^username,
    select: u
  )
```

[phoenix-examples/ecto_query_library](https://github.com/phoenix-examples/ecto_query_library)에서 더 많은 질의 예제를 확인할 수 있습니다.

## Changeset

앞에서는 데이터를 검색하는 방법에 대해서 배웠습니다. 그렇다면 추가나 변경을 해야 하는 경우에는 어떻게 하면 좋을까요? 이럴 때 Changeset이 필요합니다.

Changeset은 스키마를 변경할 때 필터나 검증, 제약 조건의 유지를 담당합니다.

아래의 예시에서는 사용자 계정을 생성할 때의 Changeset을 살펴보겠습니다. 우선, 스키마를 변경해야 합니다.

```elixir
defmodule FriendsApp.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Comeonin.Bcrypt, only: [hashpwsalt: 1]

  schema "users" do
    field(:username, :string)
    field(:encrypted_password, :string)
    field(:email, :string)
    field(:confirmed, :boolean, default: false)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)

    timestamps
  end

  @required_fields ~w(username email password password_confirmation)
  @optional_fields ~w()

  def changeset(user, params \\ :empty) do
    user
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:password, min: 8)
    |> validate_password_confirmation()
    |> unique_constraint(:username, name: :email)
    |> put_change(:encrypted_password, hashpwsalt(params[:password]))
  end

  defp validate_password_confirmation(changeset) do
    case get_change(changeset, :password_confirmation) do
      nil ->
        password_incorrect_error(changeset)

      confirmation ->
        password = get_field(changeset, :password)
        if confirmation == password, do: changeset, else: password_mismatch_error(changeset)
    end
  end

  defp password_mismatch_error(changeset) do
    add_error(changeset, :password_confirmation, "Passwords does not match")
  end

  defp password_incorrect_error(changeset) do
    add_error(changeset, :password, "is not valid")
  end
end
```

`changeset/2` 함수를 약간 개선하고, 3개의 새 헬퍼 함수를 추가했습니다. `validate_password_confirmation/1`, `password_mismatch_error/1`, 그리고 `password_incorrect_error/1`입니다.

이름에서도 추측할 수 있듯이, `changeset/2`는 새로운 changeset을 생성합니다. 내부에서 `cast/4`를 통해 필수 또는 옵션인 인자들을 changeset으로 변환합니다. 다음으로 changeset의 비밀번호의 길이를 검증하고, 비밀번호와 확인용 비밀번호가 일치하는지를 확인한 뒤, 사용자의 이름이 유일한지 검증합니다. 마지막으로 데이터베이스에 실제로 저장될 비밀번호 필드를 변경합니다. changeset의 값을 변경하기 위해서 `put_change/3`을 사용했습니다.

`User.changeset/2`는 비교적 간단하게 사용할 수 있습니다.

```elixir
alias FriendsApp.{User,Repo}

pw = "passwords should be hard"
changeset = User.changeset(%User{}, %{username: "doomspork",
                    email: "sean@seancallan.com",
                    password: pw,
                    password_confirmation: pw})

case Repo.insert(changeset) do
  {:ok, record}       -> # Inserted with success
  {:error, changeset} -> # Something went wrong
end
```
끝입니다! 이제 데이터를 저장할 수 있게 되었습니다.
