%{
  version: "1.2.3",
  title: "Changesets",
  excerpt: """
  In order to insert, update or delete data from the database, `Ecto.Repo.insert/2`, `update/2` and `delete/2` require a changeset as their first parameter. But what are changesets?

  A familiar task for almost every developer is checking input data for potential errors — we want to make sure that data is in the right state, before we attempt to use it for our purposes.

Ecto provides a complete solution for working with data changes in the form of the `Changeset` module and data structure.
  In this lesson we're going to explore this functionality and learn how to verify data's integrity, before we persist it to the database.
  """
}
---

## Creating your first changeset

Let's look at an empty `%Changeset{}` struct:

```elixir
iex> %Ecto.Changeset{}
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: nil, valid?: false>
```

As you can see, it has some potentially useful fields, but they are all empty.

For a changeset to be truly useful, when we create it, we need to provide a blueprint of what the data is like.
What better blueprint for our data than the schemas we've created that define our fields and types?

Let's use our `Friends.Person` schema from the previous lesson:

```elixir
defmodule Friends.Person do
  use Ecto.Schema

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

To create a changeset using the `Person` schema, we are going to use `Ecto.Changeset.cast/3`:

```elixir
iex> Ecto.Changeset.cast(%Friends.Person{name: "Bob"}, %{}, [:name, :age])
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Person<>,
 valid?: true>
```

The first parameter is the original data — an initial `%Friends.Person{}` struct in this case.
Ecto is smart enough to find the schema based on the struct itself.
Second in order are the changes we want to make — just an empty map.
The third parameter is what makes `cast/3` special: it is a list of fields allowed to go through, which gives us the ability to control what fields can be changed and safe-guard the rest.

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

You can see how the new name was ignored the second time, where it was not explicitly allowed.

An alternative to `cast/3` is the `change/2` function, which doesn't have the ability to filter changes like `cast/3`.
It is useful when you trust the source making the changes or when you work with data manually.

Now we can create changesets, but since we do not have validation, any changes to person's name will be accepted, so we can end up with an empty name:

```elixir
iex> Ecto.Changeset.change(%Friends.Person{name: "Bob"}, %{name: ""})
#Ecto.Changeset<
  action: nil,
  changes: %{name: ""},
  errors: [],
  data: #Friends.Person<>,
  valid?: true
>
```

Ecto says the changeset is valid, but actually, we do not want to allow empty names. Let's fix this!

## Validations

Ecto comes with a number of built-in validation functions to help us.

We're going to use `Ecto.Changeset` a lot, so let's import `Ecto.Changeset` into our `person.ex` module, which also contains our schema:

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

Now we can use the `cast/3` function directly.

It is common to have one or more changeset creator functions for a schema. Let's make one that accepts a struct, a map of changes, and returns a changeset:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
end
```

Now we can ensure that `name` is always present:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> validate_required([:name])
end
```

When we call the `Friends.Person.changeset/2` function and pass an empty name, the changeset will be no longer valid, and will even contain a helpful error message.
Note: do not forget to run `recompile()` when working in `iex`, otherwise it won't pick up the changes you make in code.

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

If you attempt to do `Repo.insert(changeset)` with the changeset above, you will receive `{:error, changeset}` back with the same error, so you do not have to check `changeset.valid?` yourself every time.
It is easier to attempt performing insert, update or delete, and process the error afterwards if there is one.

Apart from `validate_required/2`, there is also `validate_length/3`, that takes some extra options:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> validate_required([:name])
  |> validate_length(:name, min: 2)
end
```

You can try and guess what the result would be if we pass a name that consists of a single character!

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

You may be surprised that the error message contains the cryptic `%{count}` — this is to aid translation to other languages; if you want to display the errors to the user directly, you can make them human readable using [`traverse_errors/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#traverse_errors/2) — take a look at the example provided in the docs.

Some of the other built-in validators in `Ecto.Changeset` are:

+ validate_acceptance/3
+ validate_change/3 & /4
+ validate_confirmation/3
+ validate_exclusion/4 & validate_inclusion/4
+ validate_format/4
+ validate_number/3
+ validate_subset/4

You can find the full list with details how to use them [here](https://hexdocs.pm/ecto/Ecto.Changeset.html#summary).

### Custom validations

Although the built-in validators cover a wide range of use cases, you may still need something different.

Every `validate_` function we used so far accepts and returns an `%Ecto.Changeset{}`, so we can easily plug our own.

For example, we can make sure that only fictional character names are allowed:

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

It is a good practice to always return an `%Ecto.Changeset{}`, so you can use the `|>` operator and make it easy to add more validations later:

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

Great, it works! However, there was really no need to implement this function ourselves — the `validate_inclusion/4` function could be used instead; still, you can see how you can add your own errors which should come useful.

## Adding changes programmatically

Sometimes you want to introduce changes to a changeset manually. The `put_change/3` helper exists for this purpose.

Rather than making the `name` field required, let's allow users to sign up without a name, and call them "Anonymous".
The function we need will look familiar — it accepts and returns a changeset, just like the `validate_fictional_name/1` we introduced earlier:

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

```elixir
def registration_changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> set_name_if_anonymous()
end
```

Now we don't have to pass a `name` and `Anonymous` would be automatically set, as expected:

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

Having changeset creator functions that have a specific responsibility (like `registration_changeset/2`) is not uncommon — sometimes you need the flexibility to perform only certain validations or filter specific parameters.
The function above could be then used in a dedicated `sign_up/1` helper elsewhere:

```elixir
def sign_up(params) do
  %Friends.Person{}
  |> Friends.Person.registration_changeset(params)
  |> Repo.insert()
end
```

## Conclusion

There are a lot of use cases and functionality that we did not cover in this lesson, such as [schemaless changesets](https://hexdocs.pm/ecto/Ecto.Changeset.html#module-schemaless-changesets) that you can use to validate _any_ data; or dealing with side-effects alongside the changeset ([`prepare_changes/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#prepare_changes/2)) or working with associations and embeds.
We may cover these in a future, advanced lesson, but in the meantime — we encourage to explore [Ecto Changeset's documentation](https://hexdocs.pm/ecto/Ecto.Changeset.html) for more information.
