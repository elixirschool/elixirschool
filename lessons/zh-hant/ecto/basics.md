%{
  version: "2.4.0",
  title: "基礎",
  excerpt: """
  Ecto 是一個官方 Elixir 專案，提供資料庫封裝 (wrapper) 和整合查詢語言。通過 Ecto，能夠建立遷移 (migration)、定義結構描述 (schema)、插入 (insert) 和更新記錄 (update) 並查詢 (query)。
  """
}
---

### 轉接器

Ecto 經由使用轉接器支援不同的資料庫，幾個轉接器的範例如下：

* PostgreSQL
* MySQL
* SQLite

在本課程中，將會設定 Ecto 來使用 PostgreSQL 轉接器。

### 入門

在本課程中，將涵蓋 Ecto 的三個部分：

* 存放庫 — 提供資料庫的界面，包括連線部分 (connection)
* 遷移 — 一種建立、修改和刪除資料庫表格和索引的機制
* 結構描述 — 表示資料庫表格項目的專用結構

首先，將使用 supervision 樹建立一個應用程式。

```shell
$ mix new friends --sup
$ cd friends
```

將 ecto 和 postgrex 套件相依關係添加到 `mix.exs` 檔案中。

```elixir
  defp deps do
    [
      {:ecto_sql, "~> 3.2"},
      {:postgrex, "~> 0.15"}
    ]
  end
```

使用以下指令擷取相依關係

```shell
$ mix deps.get
```

#### 建立存放庫 (Repository)

Ecto 中的存放庫映射到資料儲存，例如 Postgres 資料庫。
所有與資料庫的交流都將使用此存放庫完成。

通過執行以下指令設置存放庫：

```shell
$ mix ecto.gen.repo -r Friends.Repo
```

這會在 `config/config.exs` 中建立連接到包含要使用轉接器的資料庫的所需配置。
這是 `Friends` 應用程式的配置檔案

```elixir
config :friends, Friends.Repo,
  database: "friends_repo",
  username: "postgres",
  password: "",
  hostname: "localhost"
```

這將配置 Ecto 如何連接到資料庫。

同時它還在 `lib/friends/repo.ex` 中建立了一個 `Friends.Repo` 模組。

```elixir
defmodule Friends.Repo do
  use Ecto.Repo, 
    otp_app: :friends,
    adapter: Ecto.Adapters.Postgres
end
```

我們將使用 `Friends.Repo` 模組來查詢資料庫。同時也告訴模組在 `:friends` 應用程式中尋找其資料庫配置資訊。並且選擇了 `Ecto.Adapters.Postgres` 轉接器。

接下來，將在 `lib/friends/application.ex` 中的應用程式 supervision 樹中將 `Friends.Repo` 設定為 supervisor。
這將在應用程式啟動時啟動 Ecto 處理程序。

```elixir
  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      Friends.Repo,
    ]

  ...
```

之後還需要在 `config/config.exs` 檔案中加入下面這一行：

```elixir
config :friends, ecto_repos: [Friends.Repo]
```

這將允許應用程式從命令列執行 ecto mix 指令。

現在儲存庫已經配置完成！
可以使用以下指令在 postgres 中建立資料庫：

```shell
$ mix ecto.create
```

Ecto 將使用 `config/config.exs` 檔案中的資訊來確定如何連接到 Postgres 以及如何命名資料庫。

如果收到任何錯誤訊息，請確保配置的資料正確並且 postgres 實例有在運行。

### 遷移 (Migrations)

為了在 postgres 資料庫中建立和修改表格，Ecto 為此提供了遷移。
每個遷移都描述了要對資料庫執行的一組操作，比如要建立或更新的表格。

由於資料庫還未有任何表格，將需要建立一個遷移來加入這些表格。
在 Ecto 中約定 (convention) 是命名表格為複數，因此對於應用程式，需要一個 `people` 表格，將從那裡開始使用遷移。

建立遷移的最佳方法是執行 mix `ecto.gen.migration <name>`，所以在範例中將使用：

```shell
$ mix ecto.gen.migration create_people
```

這會在 `priv/repo/migrations` 資料夾內生成一個檔案名中含有時間戳記的新檔案。
如果導引到該目錄並開啟遷移，應該會看到如下內容：

```elixir
defmodule Friends.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do

  end
end
```

從修改 `change/0` 函數著手以建立一個帶有 `name` 和 `age` 的新 `people` 表格：

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

可以看到在上面同時還定義了欄 (column) 的資料型別。
此外，還包括 `null: false` 和 `default: 0` 作為選項。

現在跳到 shell 並執行遷移：

```shell
$ mix ecto.migrate
```

### 結構描述 (Schemas)

目前已經建立了初始表格，現在需要告訴 Ecto 更多關於如何通過結構描述進行操作的部分。
結構描述是定義映射到底層資料庫表格欄位的模組。

雖然 Ecto 偏愛命名資料格表格為複數，不過結構描述通常是單數的，因此將與表格一起建立一個 `Person` 結構描述。

現在於 `lib/friends/person.ex` 中建立所要的新結構描述：

```elixir
defmodule Friends.Person do
  use Ecto.Schema

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

在這裡可以看到 `Friends.Person` 模組告訴 Ecto 這個結構描述與 `people` 表格有關，我們有兩欄 (column)： `name` 是一字串，而 `age`，一個預設為 `0` 的整數。

現在通過開啟 `iex` 並建立一個新 person 來瞧瞧結構描述：

```shell
iex> %Friends.Person{}
%Friends.Person{age: 0, name: nil}
```

正如預期的那樣，得到一個新的 `Person` 並使用了 `age` 的預設值。
現在來建立一個 "真正的" person：

```shell
iex> person = %Friends.Person{name: "Tom", age: 11}
%Friends.Person{age: 11, name: "Tom"}
```

由於結構描述只是結構體(structs)，所以能夠像以前習慣那樣與資料進行互動：

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

同樣地，可以更新結構描述就像在 Elixir 的任何其他映射或結構體上做的一樣：

```elixir
iex> %{person | age: 18}
%Friends.Person{age: 18, name: "Tom"}
iex> Map.put(person, :name, "Jerry")
%Friends.Person{age: 11, name: "Jerry"}
```

在關於變更集的下一課程中，將了解如何驗證資料變更以及如何將它們保存到資料庫中。