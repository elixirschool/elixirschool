---
version: 1.3.0
title: Ecto
---

Ecto 是一個官方 Elixir 專案，提供資料庫封裝 (wrapper) 和整合查詢語言。
通過 Ecto，能夠建立遷移 (migration)、定義結構描述 (schema)、插入 (insert) 和更新 (update) 記錄並查詢 (query)。

{% include toc.html %}

## 安裝 (Setup)

以 supervision tree 建立一個新的應用程式：

```shell
$ mix new example_app --sup
$ cd example_app
```

開始時需要在專案的 `mix.exs` 中包含 Ecto 和資料庫轉接器 (adapter)。可以在 Ecto README 的 [Usage](https://github.com/elixir-lang/ecto/blob/master/README.md#usage) 章節找到支援的資料庫轉接器清單。

關於範例，將使用 PostgreSQL：

```elixir
defp deps do
  [{:ecto, "~> 2.2"}, {:postgrex, ">= 0.0.0"}]
end
```

接著使用以下指令獲取相依關係 (dependencies)

```shell
$ mix deps.get
```

### 存放庫 (Repository)

最後需要建立專案的存放庫也就是資料庫封裝。可以通過 `mix ecto.gen.repo -r ExampleApp.Repo` 工作來完成。接下來的章節將會介紹 Ecto mix 工作指令。Repo 檔案可以在 `lib/<project name>/repo.ex` 中找到：

```elixir
defmodule ExampleApp.Repo do
  use Ecto.Repo, otp_app: :example_app
end
```

### Supervisor

一旦建立了 Repo 檔案，就需要設置 supervisor tree，這通常會在 `lib/<project name>.ex` 中找到。將 Repo 加入到 `children` 列表中：

```elixir
defmodule ExampleApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      ExampleApp.Repo
    ]

    opts = [strategy: :one_for_one, name: ExampleApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

有關 supervisor 的更多資訊，請查閱 [OTP Supervisors](../../advanced/otp-supervisors) 課程。

### 設定

要設定 Ecto，需要在 `config/config.exs` 中加入一段程式碼。在這裡，將指定存放庫、轉接器、資料庫和帳號資訊：

```elixir
config :example_app, ExampleApp.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "example_app",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
```

## Mix 工作指令

Ecto 包含許多用於處理資料庫的有用 mix 工作指令：

```shell
mix ecto.create         # Create the storage for the repo
mix ecto.drop           # Drop the storage for the repo
mix ecto.gen.migration  # Generate a new migration for the repo
mix ecto.gen.repo       # Generate a new repository
mix ecto.migrate        # Run migrations up on a repo
mix ecto.rollback       # Rollback migrations from a repo
```

## 遷移 (Migrations)

建立遷移的最佳方式是 `mix ecto.gen.migration <name>` 工作指令。如果你通曉 ActiveRecord，這些將看起來很熟悉。

現在先看一下一個 users table 的遷移：

```elixir
defmodule ExampleApp.Repo.Migrations.CreateUser do
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

預設情況下，Ecto 會建立一個名為 `id` 的自動遞增主鍵 (primary key)。這裡正在使用預設的 `change/0`  回呼函數，但是如果需要更精細的控制，Ecto 也支援 `up/0` 和 `down/0`。

正如已經猜到的那樣，為遷移加入 `timestamps` 將能建立和管理 `inserted_at` 和 `updated_at` 。

要應用新遷移請執行 `mix ecto.migrate`。

有關遷移的更多資訊，請參閱 [Ecto.Migration](http://hexdocs.pm/ecto/Ecto.Migration.html#content) 章節。

## 結構描述 (Schemas)

現在有了遷移，可以繼續到結構描述 (Schema)。結構描述是一個模組，它定義了底層資料庫表格的映射 (mapping)、欄位 (fields)、輔助函數 (helper functions) 和變更集 (changesets)。下面的章節中將介紹變更集的更多部分。 

現在來看看我們遷移的結構描述大概長什麼樣：

```elixir
defmodule ExampleApp.User do
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
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:username)
  end
end
```

我們定義的結構描述幾乎是代表在遷移中指定的內容。除了資料庫欄位，還包括兩個虛擬欄位。虛擬欄位不會儲存到資料庫，但對驗證 (validation) 等事情可能很有用。將在 [Changesets](#changesets) 章節看到虛擬欄位的實際應用。

## 查詢 (Querying)

在要可以查詢存放庫之前，需要匯入 Query API。目前只需要匯入 `from/2`：

```elixir
import Ecto.Query, only: [from: 2]
```

官方文件可以在 [Ecto.Query](http://hexdocs.pm/ecto/Ecto.Query.html) 這裡找到。

### 基礎

Ecto 提供了一個優秀的查詢用 DSL，能夠使我們清楚地表達查詢語法。要找到所有已認證帳號的使用者名稱，可以使用如下所示的內容：

```elixir
alias ExampleApp.{Repo, User}

query =
  from(
    u in User,
    where: u.confirmed == true,
    select: u.username
  )

Repo.all(query)
```

除了 `all/2`，Repo 還提供了一些回呼，包括 `one/2`、 `get/3`、 `insert/2` 和 `delete/2`。

完整的回呼清單可以在 [Ecto.Repo#callbacks](http://hexdocs.pm/ecto/Ecto.Repo.html#callbacks) 中找到。

### Count

如果要計算已認證帳號的使用者數量，可以使用 `count/1`：

```elixir
query =
  from(
    u in User,
    where: u.confirmed == true,
    select: count(u.id)
  )
```

有 `count/2` 函數計算給定條目中的不同值：

```elixir
query =
  from(
    u in User,
    where: u.confirmed == true,
    select: count(u.id, :distinct)
  )
```

### Group By

要按照認證狀態對使用者進行分組，可以加上 `group_by` 選項：

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

依照使用者的建立日期排序：

```elixir
query =
  from(
    u in User,
    order_by: u.inserted_at,
    select: [u.username, u.inserted_at]
  )

Repo.all(query)
```

依照 `DESC` 排序：

```elixir
query =
  from(
    u in User,
    order_by: [desc: u.inserted_at],
    select: [u.username, u.inserted_at]
  )
```

### Joins

假設存在一個與使用者相關的設定檔，現在來搜尋所有已認證帳號的設定檔：

```elixir
query =
  from(
    p in Profile,
    join: u in assoc(p, :user),
    where: u.confirmed == true
  )
```

### Fragments

有時，像是需要特定的資料庫函數時，僅 Query API 是不夠的。為此目的存在 `fragment/1` 函數：

```elixir
query =
  from(
    u in User,
    where: fragment("downcase(?)", u.username) == ^username,
    select: u
  )
```

其他查詢範例可以在 [Ecto.Query.API](http://hexdocs.pm/ecto/Ecto.Query.API.html)模組描述中找到。

## 變更集 (Changesets)

在前一節中，學習了如何檢索資料，但是如何插入和更新資料？為此，需要變更集 (Changesets)。

當更改結構描述時，變更集負責篩選 (filtering)、驗證 (validating) 和維護約束 (constraints)。

在這個範例中，重點將放在建立使用者帳戶的變更集上。開始時，需要更新結構描述：

```elixir
defmodule ExampleApp.User do
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
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
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

我們改善了 `changeset/2` 函數並加入了三個新的輔助函數：`validate_password_confirmation/1`、`password_mismatch_error/1` 和 `password_incorrect_error/1`。

顧名思義， `changeset/2` 建立了一個新的變更集。
其中使用 `cast/3` 將參數從一組必要欄位和可選欄位轉換為變更集。
接著驗證必要欄位的存在。下一步，將驗證變更集的密碼長度，使用我們自己的函數來驗證確認密碼吻合，並驗證使用者名稱的唯一性。最後更新實際密碼的資料庫欄位。為此使用 `put_change/3` 來更新變更集中的值。

使用 `User.changeset/2` 則是相對直覺的：

```elixir
alias ExampleApp.{User,Repo}

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

就這樣！現在已經準備好來儲存一些資料了。