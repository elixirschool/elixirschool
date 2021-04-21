%{
  version: "1.0.1",
  title: "Basics",
  excerpt: """
  Ecto - официальный проект от создателей Elixir. Это оболочка, которая предоставляет возможность коммуникации с базой данных. Ecto позволяет создавать миграции, объявлять модели, вносить и обновлять данные, а также посылать запросы к ним.
  """
}
---

## Установка

Для начала необходимо добавить Ecto и адаптер для базы данных в файл `mix.exs`, который находится в нашем проекте. Список поддерживаемых адаптеров для баз данных можно найти в [Usage](https://github.com/elixir-lang/ecto/blob/master/README.md#usage) секции README для Ecto. В примере мы используем PostgreSQL:

```elixir
defp deps do
  [{:ecto, "~> 1.0"}, {:postgrex, ">= 0.0.0"}]
end
```

После этого добавим Ecto и адаптер в список приложений.

```elixir
def application do
  [applications: [:ecto, :postgrex]]
end
```

### Репозиторий

Создадим репозиторий для проекта - оболочку для базы данных. Для этого выполним команду `mix ecto.gen.repo -r FriendsApp.Repo`. Репозиторий находится в `lib/<project name>/repo.ex`.

```elixir
defmodule FriendsApp.Repo do
  use Ecto.Repo, otp_app: :example_app
end
```

### Супервизор

После создания репозитория, необходимо создать дерево надзора. Файл находится в `lib/<project name>.ex`.

Важно, чтобы мы настроили репозиторий, как супервизор с помощью `supervisor/3` метода, а не `worker/3`. Если создать приложение с флагом `--sup`, большинство нужного кода для нас уже будет сгенерировано.

```elixir
defmodule FriendsApp.App do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(FriendsApp.Repo, [])
    ]

    opts = [strategy: :one_for_one, name: FriendsApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```
Чтобы узнать больше о супервизорах советуем посетить урок [Супервизоры](../../advanced/otp-supervisors).

### Настройка

Чтобы настроить Ecto, необходимо добавить конфигурацию в файл `config/config.exs`. В конфигурации необходимо указать репозиторий, адаптер, базу данных и информацию об аккаунте.

```elixir
config :example_app, FriendsApp.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "example_app",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
```

## Mix задачи

Ecto включает в себя `mix` задачи для работы с базой данных:

```shell
mix ecto.create         # Создать хранилище для репозитория.
mix ecto.drop           # Удалить хранилище для репозитория.
mix ecto.gen.migration  # Сгенерировать новую миграцию для репозитория.
mix ecto.gen.repo       # Сгенерировать новый репозиторий.
mix ecto.migrate        # Запустить миграции для репозитория.
mix ecto.rollback       # Откатить миграции из репозитория.
```

## Миграции

Лучший способ создать миграцию - использовать команду mix ecto.gen.migration <название_миграции>. Это похоже на создание миграций в ActiveRecord.

Давайте рассмотрим, как выглядит миграция для таблицы `users`:

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

Ecto по умолчанию создает первичный автоинкрементируемый ключ под названием id. Также по умолчанию используется `change/0` callback, но для большего контроля можно использовать `up/0` и `down/0`.

Вы уже могли догадаться, что при добавлении `timestamps` к миграции у Вас появляется возможность создать и управлять полями `inserted_at` и `updated_at`.

Следующим шагом будет запуск только что созданной миграции с помощью команды `mix ecto.migrate`.

Дополнительную информацию о миграциях Вы можете найти в главе [Ecto Миграции](http://hexdocs.pm/ecto/Ecto.Migration.html#content).

## Модели

Теперь, имея миграцию, можно двигаться дальше, к модели. Модели определяют структуру(schema), вспомогательные методы(helper methods) и набор изменений. Набор изменений объяснен в следующей главе.

Рассмотрим как выглядит модель для нашей миграции:

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
Структура, заданная в нашей модели, очень похожа на код в самой миграции. Дополнительно к полям базы данных мы также добавили 2 виртуальных поля. Виртуальные поля не сохраняются в базу данных, но могут быть полезными для валидаций. Примеры виртуальных полей можно найти здесь [Набор изменений](#section-15).

## Запросы

Перед тем как посылать запросы к репозиторию, необходимо импортировать Query API. Для начала нам понадобится только один метод из библиотеки `from/2`:

```elixir
import Ecto.Query, only: [from: 2]
```

Официальную документацию можно найти перейдя по ссылке [Ecto запросы](http://hexdocs.pm/ecto/Ecto.Query.html).

### Основы

Ecto предоставляет мощный язык запросов. Запрос для поиска всех пользователей, аккаунты которых приняты, будет выглядеть так:

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

Кроме `all/2`, Repo предоставляет различные callback-функции, такие как `one/2`, `get/3`, `insert/2`, и `delete/2`. Список всех функций можно найти в официальной документации [Ecto.Repo#callbacks](http://hexdocs.pm/ecto/Ecto.Repo.html#callbacks).

### Количество

Если мы хотим посчитать количество пользователей, подтвердивших учётные записи, мы можем использовать `count/1`:

```elixir
query =
  from(
    u in User,
    where: u.confirmed == true,
    select: count(u.id)
  )
```

Также с помощью функции `count/2` можно считать уникальные значения:

```elixir
query =
  from(
    u in User,
    where: u.confirmed == true,
    select: count(u.id, :distinct)
  )
```

### Группировка

Для того, чтобы сгруппировать всех пользователей по статусу, можно добавить опцию `group_by`:

```elixir
query =
  from(
    u in User,
    group_by: u.confirmed,
    select: [u.confirmed, count(u.id)]
  )

Repo.all(query)
```

### Сортировка

Сортировка пользователей по дате создания записи в базе данных:

```elixir
query =
  from(
    u in User,
    order_by: u.inserted_at,
    select: [u.username, u.inserted_at]
  )

Repo.all(query)
```

Сортировка по убыванию(`DESC`):

```elixir
query =
  from(
    u in User,
    order_by: [desc: u.inserted_at],
    select: [u.username, u.inserted_at]
  )
```

### Объединение

Допустим, каждый пользователь имеет свой профайл. Давайте найдем все профайлы утвержденных пользователей:

```elixir
query =
  from(
    p in Profile,
    join: u in assoc(p, :user),
    where: u.confirmed == true
  )
```

### Фрагменты

Иногда, когда нам необходимы специфические функции базы данных, Query API недостаточно. В таких случаях следует использовать функцию `fragment/1`:

```elixir
query =
  from(
    u in User,
    where: fragment("downcase(?)", u.username) == ^username,
    select: u
  )
```

Примеры построения различных запросов можно найти здесь [Ecto.Query.API](http://hexdocs.pm/ecto/Ecto.Query.API.html).

## Набор изменений

В предыдущем параграфе мы увидели как извлечь необходимую информацию из базы данных, а что насчет добавления и обновления записей? Для этого нам необходим набор изменений (Changesets).

Набор изменений выполняет функции фильтрации, валидации, и поддержки ограничений при изменении модели.

Давайте используем пример набора изменений для создания аккаунта для пользователя. Для начала необходимо обновить модель:

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

Таким образом, мы улучшили функцию `changeset/2`, а также добавили три новые вспомогательные функции: `validate_password_confirmation/1`, `password_mismatch_error/1` и `password_incorrect_error/1`.

По названию можно догадаться, что функция `changeset/2` создает новый набор изменений. В теле функции используем функцию `cast/4`, которая трансформирует данные параметры в набор изменений, который состоит из обязательных и необязательных полей. Далее происходит валидация длины пароля, находящегося в наборе изменений. После этого, используя созданную нами функцию, мы можем проверить, что подтверждение пароля является таким же как и сам пароль, а также проверить уникальность имени пользователя. В конце, обновим пароль в базе данных. Для этого используем функцию `put_change/3`, которая обновит значение в наборе изменений.

Использование `User.changeset/2` довольно просто:

```elixir
alias FriendsApp.{User, Repo}

pw = "passwords should be hard"

changeset =
  User.changeset(%User{}, %{
    username: "doomspork",
    email: "sean@seancallan.com",
    password: pw,
    password_confirmation: pw
  })

case Repo.insert(changeset) do
  {:ok, model}        -> # Inserted with success
  {:error, changeset} -> # Something went wrong
end
```

И это все! Теперь Вы готовы обновлять записи в базе данных.
