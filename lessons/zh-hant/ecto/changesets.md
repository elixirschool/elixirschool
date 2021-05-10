%{
  version: "1.2.2",
  title: "變更集 (Changesets)",
  excerpt: """
  為了插入、更新或刪除資料庫中的資料，`Ecto.Repo.insert/2`、`update/2` 和 `delete/2` 需要一個變更集作為它們的第一個參數。但什麼是變更集？

幾乎每個開發者都熟悉的工作是檢查輸入的資料是否存在潛在錯誤 - 我們希望在嘗試將資料用於目的之前確保資料處於正確的狀態。

Ecto 提供一個完整的解決方案，以 `Changeset` 模組的形式處理資料更改和資料結構。
在本課程中，將探討此功能，並在將資料長久保存到資料庫之前了解如何驗證資料的完整性。
  """
}
---

## 建立第一個變更集

現在來看一個空的 `%Changeset{}` 結構體：

```elixir
iex> %Ecto.Changeset{}
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: nil, valid?: false>
```

如你所見，它有一些可能有用的欄位，但它們目前都是空的。

為了使變更集真正有用，當建立它時，需要提供資料的藍圖。
什麼樣的資料藍圖是比用於建立定義欄位和類型的結構描述(schema)更好？

現在來使用上一課中的 `Friends.Person` 結構描述：

```elixir
defmodule Friends.Person do
  use Ecto.Schema

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

要使用 `Person` 結構描述建立變更集，將使用 `Ecto.Changeset.cast/3`：

```elixir
iex> Ecto.Changeset.cast(%Friends.Person{name: "Bob"}, %{}, [:name, :age])
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Person<>,
 valid?: true>
```

第一個參數是原始資料 - 在這個範例中為一個初始的 `%Friends.Person{}` 結構體。
Ecto 足夠聰明，可以根據結構體本身找到結構描述。
第二個參數是想要做出的改變 - 只是一張空映射。
第三個參數是使 `cast/3` 特殊的原因：它是允許通過的欄位列表，這使我們能夠控制哪些欄位可以更改並保護其餘欄位。

```elixir
iex> Ecto.Changeset.cast(%Friends.Person{name: "Bob"}, %{"name" => "Jack"}, [:name, :age])
%Ecto.Changeset<
  action: nil,
  changes: %{name: "Jack"},
  errors: [],
  data: %Friends.Person<>,
  valid?: true
>

iex> Ecto.Changeset.cast(%Friends.Person{name: "Bob"}, %{"name" => "Jack"}, [])
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Person<>,
 valid?: true>
```

可以在第二次更改時看到如何忽略新 name，因新 name 未被明確允許。

一個 `cast/3` 的替代是 `change/2` 函數，它不能像 `cast/3` 這樣篩選更改。
不過當進行更改來源是可信任或手動處理資料時，它非常有用。

現在可以建立變更集，但由於沒有驗證，因此將接受對 Person 中 name 的任何更改，最終會得到一個空的 name：

```elixir
iex> Ecto.Changeset.change(%Friends.Person{name: "Bob"}, %{"name" => ""})
%Ecto.Changeset<
  action: nil,
  changes: %{name: nil},
  errors: [],
  data: %Friends.Person<>,
  valid?: true
>
```

Ecto 說變更集是有效的，但實際上，我們不想允許空名稱。現在來解決這個問題！

## 驗證

Ecto 附帶了許多內建的驗證函數來幫助我們。

我們將經常使用 `Ecto.Changeset`，所以現在將 `Ecto.Changeset` 匯入 `person.ex` 模組，該模組也包含結構描述：

```elixir
defmodule Friends.Person do
  use Ecto.Schema
  import Ecto.Changeset

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

現在可以直接使用 `cast/3` 函數。

為結構描述提供一個或多個變更集建立函數是很平常的。現在建立一個接受結構體、更改的映射並回傳變更集的函數：

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
end
```

現在可以確保 `name` 始終存在：

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name])
  |> validate_required([:name])
end
```

當呼用 `Friends.Person.changeset/2` 函數並傳遞一個空的 name 時，變更集將不再有效，甚至會包含有用的錯誤消息。
註：在 `iex` 中工作時不要忘記執行 `recompile()` ，否則它將無法獲取你在程式碼中所做的更改。

```elixir
iex> Friends.Person.changeset(%Friends.Person{}, %{"name" => ""})
%Ecto.Changeset<
  action: nil,
  changes: %{},
  errors: [name: {"can't be blank", [validation: :required]}],
  data: %Friends.Person<>,
  valid?: false
>
```

如果你嘗試使用上面變更集執行 `Repo.insert(changeset)`，將收到 `{:error, changeset}` 回傳相同的錯誤，因此不必每次都檢查 `changeset.valid?`。
如果有的話，更容易嘗試執行插入、更新或刪除，且處理錯誤。

除了 `validate_required/2` 之外，還有 `validate_length/3`，它需要一些額外的選項：

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> validate_required([:name])
  |> validate_length(:name, min: 2)
end
```

如果傳遞一個由單個字元組成的名稱，可以嘗試猜測結果是什麼！

```elixir
iex> Friends.Person.changeset(%Friends.Person{}, %{"name" => "A"})
%Ecto.Changeset<
  action: nil,
  changes: %{name: "A"},
  errors: [
    name: {"should be at least %{count} character(s)",
     [count: 2, validation: :length, kind: :min, type: :string]}
  ],
  data: %Friends.Person<>,
  valid?: false
>
```

你可能會驚訝於錯誤訊息包含含義模糊的 `%{count}` - 這是為了幫助翻譯成其他語言；如果想直接向使用者顯示錯誤，可以使用 [`traverse_errors/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#traverse_errors/2)使它們成為人類可讀的 - 查看文件中提供的範例。

`Ecto.Changeset` 中其他的內建驗證器是：

+ validate_acceptance/3
+ validate_change/3 & /4
+ validate_confirmation/3
+ validate_exclusion/4 & validate_inclusion/4
+ validate_format/4
+ validate_number/3
+ validate_subset/4

可以在 [這裡](https://hexdocs.pm/ecto/Ecto.Changeset.html#summary)找到完整的清單，並詳細說明如何使用。

### 自訂驗證

雖然內建驗證器涵蓋了廣泛的使用案例，但你可能仍需要一些不同的。

到目前為止使用的每個 `validate_` 函數都接受並回傳一個 `%Ecto.Changeset{}`，因此可以輕鬆地插入自己的函數。

例如，可以確保只允許使用虛構的人物名稱：

```elixir
@fictional_names ["Black Panther", "Wonder Woman", "Spiderman"]
def validate_fictional_name(changeset) do
  name = get_field(changeset, :name)

  if name in @fictional_names do
    changeset
  else
    add_error(changeset, :name, "is not a superhero")
  end
end
```

上面介紹了兩個新的輔助函數： [`get_field/3`](https://hexdocs.pm/ecto/Ecto.Changeset.html#get_field/3) 和 [`add_error/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#add_error/4)。從函數名稱就幾乎無需解釋它們能做的事，但仍建議查看連結內文件。

總是回傳一個 `%Ecto.Changeset{}` 是好習慣，因為可以使用 `|>` 運算子，以便之後加入更多驗證：

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> validate_required([:name])
  |> validate_length(:name, min: 2)
  |> validate_fictional_name()
end
```

```elixir
iex> Friends.Person.changeset(%Friends.Person{}, %{"name" => "Bob"})
%Ecto.Changeset<
  action: nil,
  changes: %{name: "Bob"},
  errors: [name: {"is not a superhero", []}],
  data: %Friends.Person<>,
  valid?: false
>
```

好，它能動了！但是，實際上沒有必要自己實現這個函數 - 可以使用 `validate_inclusion/4`；仍然，你可以看到如何加入自己的 errors，這些應該是很有用的。

## 以程式方式加入變更

有時會希望手動對變更集匯入更改。為此目的存在 `put_change/3` helper。

不要讓 `name` 欄位為必填，讓我們允許使用者在沒有名字的情況下註冊，並稱之為 "Anonymous"。
需要的函數看起來很熟悉 - 它接受並回傳一個變更集，就像之前介紹的 `validate_fictional_name/1` 一樣：

```elixir
def set_name_if_anonymous(changeset) do
  name = get_field(changeset, :name)

  if is_nil(name) do
    put_change(changeset, :name, "Anonymous")
  else
    changeset
  end
end
```

只有使用者在應用程式中註冊時，才能將使用者名稱設定為 "Anonymous"；要做到這一點，將建立一個新的變更集建立函數：

```elixir
def registration_changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> set_name_if_anonymous()
end
```

現在不必傳遞 `name` 且 `Anonymous` 會自動設定，就如預期的那樣：

```elixir
iex> Friends.Person.registration_changeset(%Friends.Person{}, %{})
%Ecto.Changeset<
  action: nil,
  changes: %{name: "Anonymous"},
  errors: [],
  data: %Friends.Person<>,
  valid?: true
>
```

具有特定職責的變更集建立函數 (如 `registration_changeset/2`) 並不罕見 - 有時需要靈活地僅執行某些驗證或篩選特定參數。
上面的函數可以在專用的 `sign_up/1` helper 中其他地方使用：

```elixir
def sign_up(params) do
  %Friends.Person{}
  |> Friends.Person.registration_changeset(params)
  |> Repo.insert()
end
```

## 結論

在本課程中有很多使用案例和功能並沒有涉及到，例如 [無結構描述變更集](https://hexdocs.pm/ecto/Ecto.Changeset.html#module-schemaless-changesets) 它可以用來驗證 _任何_ 資料；或依著變更集([`prepare_changes/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#prepare_changes/2))處理副作用；或使用關聯(associations)和嵌入(embeds)。
可能會在未來的進階課程中介紹這些內容，但在此刻 - 我們鼓勵瀏覽 [Ecto Changeset 文件](https://hexdocs.pm/ecto/Ecto.Changeset.html) 以獲得更多資訊。
