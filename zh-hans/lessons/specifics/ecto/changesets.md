---
version: 1.0.0
title: Changesets
---

In order to insert, update or delete data from the database, `Ecto.Repo.insert/2`, `update/2` and `delete/2` require a changeset as their first parameter. What are changesets?

为了往数据库中插入，更新或是删除数据，`Ecto.Repo.insert/2`, `update/2` and `delete/2` 需要一个 changeset 作为它的第一个参数，那么什么是 changesets 呢 

A familiar task for almost every developer is checking input data for potential errors — we want to make sure that data is in the right state, before we attempt to use it for our purposes.

几乎每个开发人员都熟悉的一个任务是检查输入数据是否存在潜在错误 - 我们希望在我们尝试将数据用于我们的目的之前确保数据是处于正确的状态。

Ecto provides a complete solution for working with data changes in the form of the `Changeset` module and data structure. In this lesson we're going to explore this functionality and learn how to verify data's integrity, before we persist it to the database.

Ecto提供了一个完整的解决方案，用于以“Changeset”模块和数据结构的形式处理数据更改。 在本节课程中，我们将探讨此功能，并在将数据持久保存到数据库之前了解如何验证数据的完整性。

{% include toc.html %}

## Creating your first changeset  创建你的第一个 changeset

Let's look at an empty `%Changeset{}` struct:

让我们首先看一下一个空的 `%Changeset{}` 结构：

```elixir
iex> %Ecto.Changeset{}
#Ecto.Changeset<action: nil, changes: %{}, errors: [], data: nil, valid?: false>
```

As you can see, it has some potentially useful fields, but they are all empty.

正如你所看到的，它有一些可能有用的字段，但它们都是空的。

For a changeset to be truly useful, when we create it, we need to provide a blueprint of what the data is like. `Ecto.Schema` is exactly that — a blueprint of all fields and their types. Let's look at a simple schema for a user:

为了使变更集真正有用，当我们创建它时，我们需要提供数据的蓝图。 `Ecto.Schema`就是这样 - 所有字段指及其类型的蓝图。 让我们看一下用户的简单模式：

```elixir
defmodule User do
  use Ecto.Schema

  schema "users" do
    field(:name, :string)
  end
end
```

To create a changeset using the `User` schema, we are going to use `Ecto.Changeset.cast/4`:

要使用`User`模式创建变更集，我们将使用`Ecto.Changeset.cast / 4`

```elixir
iex> Ecto.Changeset.cast(%User{name: "Bob"}, %{}, [:name])
#Ecto.Changeset<action: nil, changes: %{}, errors: [], data: #User<>,
 valid?: true>
 ```

 The first parameter is the original data — an empty `%User{}` struct in this case. Ecto is smart enough to find the schema based on the struct itself. Second in order are the changes we want to make — just an empty map. The third parameter is what makes `cast/4` special: it is a list of fields allowed to go through, which gives us the ability to control what fields can be changed and safe-guard the rest.

第一个参数是原始数据 - 在这种情况下为空的'％User {}`结构。 Ecto非常聪明，可以根据结构本身找到模式。 其次是我们想要做出的改变 - 只是一张空地图。 第三个参数是使`cast / 4`特殊的原因：它是允许通过的字段列表，这使我们能够控制哪些字段可以更改并保护其余字段。

 ```elixir
 iex> Ecto.Changeset.cast(%User{name: "Bob"}, %{"name" => "Jack"}, [:name])
 #Ecto.Changeset<
  action: nil,
  changes: %{name: "Jack"},
  errors: [],
  data: #User<>,
  valid?: true
>

iex> Ecto.Changeset.cast(%User{name: "Bob"}, %{"name" => "Jack"}, [])
#Ecto.Changeset<action: nil, changes: %{}, errors: [], data: #User<>,
 valid?: true>
```

You can see how the new email was ignored the second time, where it was not explicitly allowed.

您可以看到第二次忽略新电子邮件的方式，而未明确允许这样做。

An alternative to `cast/4` is the `change/2` function, which doesn't have the ability to filter changes like `cast/4`. It is useful when you trust the source making the changes or when you work with data manually.

`cast / 4`的替代是`change / 2`函数，它不能过滤像'cast / 4`这样的变化。 当您信任进行更改的源或手动处理数据时，它非常有用。

Now we can create changesets, but since we do not have validation, any changes to user's name will be accepted, so we can end up with an empty name:

现在我们可以创建变更集，但由于我们没有验证，因此将接受对用户名称的任何更改，因此我们最终会得到一个空名称：

```elixir
iex> Ecto.Changeset.cast(%User{name: "Bob"}, %{"name" => ""}, [:name])
#Ecto.Changeset<
 action: nil,
 changes: %{name: ""},
 errors: [],
 data: #User<>,
 valid?: true
>
```

Ecto says the changeset is valid, but actually, we do not want to allow empty names. Let's fix this!

Ecto说变更集是有效的，但实际上，我们不想允许空名称。 我们来解决这个问题！

## Validations 验证

Ecto comes with a number of built-in validation functions to help us.
Ecto附带了许多内置的验证功能来帮助我们。

We're going to use `Ecto.Changeset` a lot, so let's import `Ecto.Changeset` into our `user.ex` module, which also contains our schema:
我们将使用`Ecto.Changeset`，所以让我们将`Ecto.Changeset`导入到我们的`user.ex`模块中，该模块还包含我们的模式：

```elixir
defmodule User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:name, :string)
  end
end
```

Now we can use the `cast/4` function directly.
现在我们可以直接使用 `cast/4` 函数了

It is common to have one or more changeset creator functions for a schema. Let's make one that accepts a struct, a map of changes, and returns a changeset:

通常为模式提供一个或多个变更集创建函数。 让我们创建一个接受结构，变更映射并返回变更集的变量：

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name])
end
```

Now we can ensure that `name` is always present:
现在我们可以确保`name`始终存在：

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name])
  |> validate_required([:name])
end
```

When we call the `User.changeset/2` function and pass an empty name, the changeset will be no longer valid, and will even contain a helpful error message. Note: do not forget to run `recompile()` when working in `iex`, otherwise it won't pick up the changes you make in code.

当我们调用`User.changeset / 2`函数并传递一个空 name 时，changeset将不再有效，甚至会包含有用的错误消息。 注意：在`iex` 中工作时不要忘记运行`recompile（）`，否则它将无法获取您在代码中所做的更改。

```elixir
iex> User.changeset(%User{}, %{"name" => ""})
#Ecto.Changeset<
  action: nil,
  changes: %{},
  errors: [name: {"can't be blank", [validation: :required]}],
  data: #GalileoWeb.User<>,
  valid?: false
>
```

If you attempt to do `Repo.insert(changeset)` with the changeset above, you will receive `{:error, changeset}` back with the same error, so you do not have to check `changeset.valid?` yourself every time. It is easier to attempt performing insert, update or delete, and process the error afterwards if there is one.

如果您尝试使用上面的changeset执行`Repo.insert（changeset）`，您将收到`{:error，changeset}`返回相同的错误，因此您不必每次都检查`changeset.valid？`。z这让尝试执行插入，更新或删除的操作变得容易，然后处理错误假如有错误的话。

Apart from `validate_required/2`, there is also `validate_length/3`, that takes some extra options:

除了`validate_required/2`之外，还有`validate_length/3`，它需要一些额外的选项：

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name])
  |> validate_required([:name])
  |> validate_length(:name, min: 2)
end
```

You can try and guess what the result would be if we pass a name that consists of a single character!
您可以尝试猜一下如果我们传递一个由单个字符组成的名称，结果会是什么！

```elixir
iex> User.changeset(%User{}, %{"name" => "A"})
#Ecto.Changeset<
  action: nil,
  changes: %{name: "A"},
  errors: [
    name: {"should be at least %{count} character(s)",
     [count: 2, validation: :length, min: 2]}
  ],
  data: #GalileoWeb.User<>,
  valid?: false
>
```

You may be surprised that the error message contains the cryptic `%{count}` — this is to aid translation to other languages; if you want to display the errors to the user directly, you can make them human readable using [`traverse_errors/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#traverse_errors/2) — take a look at the example provided in the docs.

您可能会惊讶于错误消息包含神秘的“％{count}” - 这是为了帮助翻译其他语言; 如果你想直接向用户显示错误，你可以使用[`traverse_errors/2`]（https://hexdocs.pm/ecto/Ecto.Changeset.html#traverse_errors/2）使它们成为人类可读的 - 取一个 查看文档中提供的示例。

Some of the other built-in validators in `Ecto.Changeset` are:
`Ecto.Changeset`中的一些其他内置的validators：

+ validate_acceptance/3
+ validate_change/3 & /4
+ validate_confirmation/3
+ validate_exclusion/4 & validate_inclusion/4
+ validate_format/4
+ validate_number/3
+ validate_subset/4

You can find the full list with details how to use them [here](https://hexdocs.pm/ecto/Ecto.Changeset.html#summary).
您可以[在这儿](https://hexdocs.pm/ecto/Ecto.Changeset.html#summary)找到完整列表，其中包含如何使用它们的详细信息

### Custom validations 自定义验证

Although the built-in validators cover a wide range of use cases, you may still need something different.
尽管内置验证器涵盖了广泛的用例，但您可能仍然需要不同的东西。
Every `validate_` function we used so far accepts and returns an `%Ecto.Changeset{}`, so we can easily plug our own.

到目前为止我们使用的每个`validate_`函数都接受并返回一个`％Ecto.Changeset {}`，因此我们可以轻松地插入自己的函数。

For example, we can make sure that only fictional character names are allowed:
比如，我们可以确保只允许虚构的角色名称：

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

Above we introduced two new helper functions: [`get_field/3`](https://hexdocs.pm/ecto/Ecto.Changeset.html#get_field/3) and [`add_error/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#add_error/4). What they do is almost self-explanatory, but I encourage you to check the links to the documentation.

上面我们介绍了两个新的辅助函数：[`get_field/3`](https://hexdocs.pm/ecto/Ecto.Changeset.html#get_field/3)和[`add_error/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#add_error/4)。 他们所做的几乎是不言自明的，但我还是建议您看一下文档。

It is a good practice to always return an `%Ecto.Changeset{}`, so you can use the `|>` operator and make it easy to add more validations later:
总是返回一个`％Ecto.Changeset{}`是一个好习惯，所以你可以使用`|>`运算符，以便以后添加更多验证：

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name])
  |> validate_required([:name])
  |> validate_length(:name, min: 2)
  |> validate_fictional_name()
end
```

```elixir
iex> User.changeset(%User{}, %{"name" => "Bob"})
#Ecto.Changeset<
  action: nil,
  changes: %{first_name: "Bob"},
  errors: [name: {"is not a superhero", []}],
  data: #GalileoWeb.User<>,
  valid?: false
>
```

Great, it works! However, there was really no need to implement this function ourselves — the `validate_inclusion/4` function could be used instead; still, you can see how you can add your own errors which should come useful.

非常棒！ 但是，实际上我们没有必要自己实现这个功能-可以使用`validate_inclusion/4`函数代替; 您可以看到如何添加一些有用的自定义错误。

## Adding changes programatically 以编程方式添加更改

Sometimes you want to introduce changes to a changeset manually. The `put_change/3` helper exists for this purpose.
有时您希望手动对changeset引入更改。 `put_change/3`的存在可以帮助你实现这个目的。

Rather than making the `name` field required, let's allow users to sign up without a name, and call them "Anonymous". The function we need will look familiar — it accepts and returns a changeset, just like the `validate_fictional_name/1`  we introduced earlier:

为了不让`name`字段成为必需，让我们允许用户在没有名字的情况下注册，并称之为“匿名”。 我们需要的函数看起来很熟悉 - 它接受并返回一个changeset，就像我们之前介绍的`validate_fictional_name/1`一样：


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

We can set user's name as "Anonymous" only when they register in our application; to do this, we are going to create a new changeset creator function:
只有在我们的应用程序中注册时，我们才能将用户名设置为“匿名”; 要做到这一点，我们将创建一个新的changeset创建函数：


```elixir
def registration_changeset(struct, params) do
  struct
  |> cast(params, [:name])
  |> set_name_if_anonymous()
end
```

Now we don't have to pass a `name` and `Anonymous` would be automatically set, as expected:
现在我们不必传递`name`，`Anonymous`将按预期自动设置：

```elixir
iex> User.registration_changeset(%User{}, %{})
#Ecto.Changeset<
  action: nil,
  changes: %{name: "Anonymous"},
  errors: [],
  data: #GalileoWeb.User<>,
  valid?: true
>
```

Having changeset creator functions that have a specific responsibility (like `registration_changeset/2`) is not uncommon — sometimes you need the flexibility to perform only certain validations or filter specific parameters. The function above could be then used in a dedicated `sign_up/1` helper elsewhere:
具有特定职责的changeset创建函数（如`registration_changeset/2`）并不罕见 - 有时您需要灵活地仅执行某些验证或过滤特定参数。 上面的函数可以在其他地方的专用`sign_up/1`函数中使用：

```elixir
def sign_up(params) do
  %User{}
  |> User.registration_changeset(params)
  |> Repo.insert()
end
```

## Conclusion 结论

There a lot of use cases and functionality that we did not cover in this lesson, such as [schemaless changesets](https://hexdocs.pm/ecto/Ecto.Changeset.html#module-schemaless-changesets) that you can use to validate _any_ data; or dealing with side-effects alongside the changeset ([`prepare_changes/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#prepare_changes/2)) or working with associations and embeds. We may cover these in a future, advanced lesson, but in the meantime — we encourage to explore [Ecto Changeset's documentation](https://hexdocs.pm/ecto/Ecto.Changeset.html) for more information.

我们在本课中没有涉及很多用例和功能，例如您可以使用的[schemaless changesets](https://hexdocs.pm/ecto/Ecto.Changeset.html#module-schemaless-changesets)验证 _any_ 数据; 或单独处理changeset的副作用([`prepare_changes/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#prepare_changes/2))，或使用关联和嵌入。 我们可能会在未来的高级课程中介绍这些内容，但与此同时 - 我们鼓励探索[Ecto Changeset的文档](https://hexdocs.pm/ecto/Ecto.Changeset.html)以获取更多信息。