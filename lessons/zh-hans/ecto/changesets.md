%{
  version: "1.2.2",
  title: "Changesets",
  excerpt: """
  为了往数据库中插入，更新或是删除数据，`Ecto.Repo.insert/2`, `update/2` 和 `delete/2` 都需要一个 changeset 作为它的第一个参数，那么什么是 changesets 呢?

几乎每个开发人员都熟悉的一个任务是检查输入数据是否存在潜在的错误 - 这是因为我们希望在尝试将数据用于我们的目的之前确保数据是处于正确的状态。

Ecto 提供了一个有关数据更改的完整解决方案，Ecto 将相关的函数和数据结构集合在 `Changeset` 模块中。 在本节课程中，我们将学习 `Changeset` 有关的功能，以及如何在将数据保存到数据库之前校验数据的完整性相关的知识。
  """
}
---

## 创建你的第一个 changeset

首先让我们来看一个空的 `%Changeset{}` 结构是什么样：

```elixir
iex> %Ecto.Changeset{}
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: nil, valid?: false>
```

正如你所看到的，它有一些可能有用的字段，但它们都是空的。

为了使 changeset 真正有用，当我们创建它时，我们需要提供一个数据的大致结构。有什么比我们创建的 schema 更准确地描述需要使用的字段及其类型的数据结构呢？

让我们使用前面课程的 `Friends.Person` Schema：

```elixir
defmodule Friends.Person do
  use Ecto.Schema

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

要利用 `Person` 的 Schema 创建 changeset 的话，我们需要使用 `Ecto.Changeset.cast/3`

```elixir
iex> Ecto.Changeset.cast(%Friends.Person{name: "Bob"}, %{}, [:name, :age])
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Person<>,
 valid?: true>
 ```

第一个参数是原始数据 - 在这个例子下是为空的 `％Friends.Person{}` 结构。 Ecto 非常聪明，可以根据结构本身找到对应的 Schema。 第二个参数是我们想要做出的更新 - 这里是一个空的 map 结构。 第三个参数是 `cast/3` 特别的原因: 它包含了允许通过的字段列表，这使我们能够控制哪些字段可以更改，并保护剩下的字段。

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

您可以看到第二次的更新忽略了新的 name 值，因为这里没有允许 name 字段。

`cast/3` 函数的一个替代方案是 `change/2` 函数，但它不能像 `cast/3` 那样过滤一些更改。 当您信任进行更改的源数据或手动处理数据时，就可以使用这个函数。

现在我们可以创建 changesets，但由于我们没有校验，对 name 所做的任何更改都会被 Ecto 接受，所以我们最终可能会得到一个值为空的 name：

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

Ecto 认为这个 changeset 是合法的 （`valid?: true`)，但实际上，我们不希望用户名字为空。 下面我们来解决这个问题。

## 校验

Ecto 附带了许多内置的校验函数来帮助我们。

接下来，我们会大量使用 `Ecto.Changeset` 提供的校验函数，所以让我们将 `Ecto.Changeset` 导入到包含了 schema 的 `person.ex` 模块中：

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

现在我们可以直接使用 `cast/3` 函数了。

通常情况下我们会为 Schema 创建一个或多个 changeset 构造函数。 让我们创建一个接受结构，变更映射并返回 changeset 的函数：

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
end
```

现在我们可以确保 `name` 始终存在：

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name])
  |> validate_required([:name])
end
```

当我们调用 `Friends.Person.changeset/2` 函数并传递一个值为空的 name 时，changeset 将不再有效，还会包含有用的错误消息。 注意：在 `iex` 中调用时不要忘记运行 `recompile()` 命令，否则它将无法获取您在代码中所做的更改。

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

如果您尝试使用上面的changeset执行 `Repo.insert(changeset)`，您将收到 `{:error，changeset}` 返回相同的错误，因此您不必每次都自己检查 `changeset.valid?`。这让尝试执行插入，更新或删除，以及处理错误的操作变得容易，假如有错误的话。

除了 `validate_required/2` 之外，还有一个需要额外参数的 `validate_length/3` 函数：

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> validate_required([:name])
  |> validate_length(:name, min: 2)
end
```

您可以猜一下如果我们传单个字符的 name，结果会是什么！

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

您可能会奇怪为什么错误消息包含了神秘的 `％{count}` 符号 - 这是为了辅助翻译成其他语言; 如果你想直接向用户显示错误，你可以使用 [`traverse_errors/2`] (https://hexdocs.pm/ecto/Ecto.Changeset.html#traverse_errors/2)使它们成为用户可读的信息 - 你可以查看文档中提供的示例。

下面是 `Ecto.Changeset` 中的一些其他内置的 validators：

+ validate_acceptance/3
+ validate_change/3 & /4
+ validate_confirmation/3
+ validate_exclusion/4 & validate_inclusion/4
+ validate_format/4
+ validate_number/3
+ validate_subset/4

完整的 validators 列表以及它们的详细用法您可以 [在这儿](https://hexdocs.pm/ecto/Ecto.Changeset.html#summary) 找到

### 自定义校验

尽管内置校验函数涵盖了广泛的场景，但您可能仍然需要不同的校验。

到目前为止我们使用的每个 `validate_` 函数都接收并返回一个 `％Ecto.Changeset{}` ，因此我们可以轻松地插入自己的函数。

比如，我们可以确保只允许虚构的角色名称能通过检查：

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

上面我们引入了两个新的辅助函数：[`get_field/3`](https://hexdocs.pm/ecto/Ecto.Changeset.html#get_field/3) 和 [`add_error/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#add_error/4)。 尽管他们的作用你看函数名就应该能猜到，但我还是建议您看一下文档。

总是返回一个 `％Ecto.Changeset{}` 是一个好习惯，所以你可以使用 `|>` 运算符，以便以后添加更多校验：

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

非常棒！ 但是，实际上我们没有必要自己实现这个功能 - `validate_inclusion/4` 函数完全可以代替它; 您可以看到如何添加一些有用的自定义错误。

## 以编程方式添加更改

有时您希望手动对 changeset 引入更改。 `put_change/3` 的存在就是帮助你实现这个目的的。

为了不让 `name` 字段成为必需，让我们允许用户在没有名字的情况下注册，并称之为 "匿名"。 我们需要的函数看起来很熟悉 - 它接受并返回一个 changeset，就像我们之前介绍的 `validate_fictional_name/1` 一样：


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

只有在我们的应用程序中注册时，我们才能将用户名设置为 `匿名` ; 要做到这一点，我们将创建一个新的 changeset 函数：


```elixir
def registration_changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> set_name_if_anonymous()
end
```

现在我们不必传递 `name`，`Anonymous` 将按预期自动设置：

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

具有特定职责的 changeset 创建函数（如 `registration_changeset/2` ）并不罕见 - 有时您需要灵活地仅执行某些校验或过滤特定参数。 上面的函数可以在其他地方，比如 `sign_up/1` 函数中使用：

```elixir
def sign_up(params) do
  %Friends.Person{}
  |> Friends.Person.registration_changeset(params)
  |> Repo.insert()
end
```

## 结语

我们在本课中没有涉及很多用例和功能，例如您可以使用的 [schemaless changesets](https://hexdocs.pm/ecto/Ecto.Changeset.html#module-schemaless-changesets) 校验 _任何_ 数据; 或单独处理 changeset 的副作用( [`prepare_changes/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#prepare_changes/2) )，或使用关联和嵌入。 我们可能会在未来的高级课程中介绍这些内容，但与此同时 - 我们鼓励探索 [Ecto Changeset的文档](https://hexdocs.pm/ecto/Ecto.Changeset.html) 以获取更多信息。
