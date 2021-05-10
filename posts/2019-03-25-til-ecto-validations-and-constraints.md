%{
  author: "Prince Wilson",
  author_link: "https://github.com/maxcell",
  date: ~D[2019-03-25],
  tags: ["ecto", "til"],
  title: "TIL Ecto Constraints and Validations",
  excerpt: """
  Let's take a look at how Ecto handles these two ways of ensuring data integrity
  """
}

---

Developers want to create the best applications they can for their users. In the process, they want to make sure to give good feedback to their users when data doesn't get saved into the database. In Elixir, there is a great tool on top of the database that helps -- Ecto! It can put validations and constraints onto specific fields to ensure data integrity.

However, did you know they are differences between validations and constraints? I didn't. In the process of building a side project, I ran into the problem a few times! Let's discuss the purpose of each approach and see the differences between them. We'll dive into **why we need each** towards the end.

## Data Integrity is Rule #1

> Data Integrity is the maintenance of, and the assurance of the accuracy and consistency of, data over its entire lifecycle
> - [Wikipedia](https://en.wikipedia.org/wiki/Data_integrity)

So we're building a super cool app with users that can login and logout. We'd probably have some schema like this:

```elixir
# Using Phoenix 1.4 with Contexts but still applies all the same
defmodule MyCoolWebApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :display_name, :string
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true

    timestamps()
  end
end
```

Inside of our schema, we'd want to describe the `changeset`. Ecto.Changesets allow us to filter, cast, validate, and constrain the structs created by our schema that represents the database records. Let's take a look at a changeset that _only_ casts:

```elixir
def changeset(user, attrs) do
  user
  |> cast(attrs, [:display_name, :email, :password])
end
```

If this was all we had, we might have a few headaches come our way. It is very easy to prematurely submit a form without filling all the fields out. Potentially, now the user's profile has a lovely email or password of `nil`, or worse `""`, in the database. This would suck, for the user(s) and the developer(s).

So in order to fix, we'd use a validation!

### Validations

Many of the validations we have in Ecto will be executed without needing to interact with the database. That means the validation will be executed prior to the attempt of inserting or updating something in the database. If we wanted to insert a new user into our database, we'd first want to make sure there is data inside of the changeset.

Let's add the [`validate_required/3`](https://hexdocs.pm/ecto/Ecto.Changeset.html#validate_required/3) into our `changeset`:

```elixir
def changeset(user, attrs) do
  user
  |> cast(attrs, [:display_name, :email, :password])
  |> validate_required([:display_name, :email, :password])
end
```

And for free, Ecto adds descriptive errors to our changeset:

```elixir
iex> %User{} |> User.changeset(%{})
%Ecto.Changeset<
  action: nil,
  changes: %{},
  errors: [
    display_name: {"can't be blank", [validation: :required]},
    email: {"can't be blank", [validation: :required]},
    password: {"can't be blank", [validation: :required]}
  ],
  data: %MyCoolWebApp.Accounts.User<>,
  valid?: false
>
```

There are a ton of validations out there that can enhance your app! Take a look at the documentation for [Ecto.Changeset](https://hexdocs.pm/ecto/Ecto.Changeset.html#summary). In the next section, we'll look at why we need to apply constraints and how to use them.

### Constraints

If we use validations, why would we also need constraints? Let's think about many apps that we use. When we sign up for an application, are we allowed to signup with the same email as another user? (Hint: the answer should always be no.)

So why couldn't we just have a validation for uniqueness? Remember that, by definition validations are executed _prior to checking the database_. If we were to have a validation for uniqueness, that would mean everything is unique even if you're adding duplicates since it doesn't look at the database.

A constraint is a rule that is enforced **by the database**. Your application will run through Ecto.Changeset's validations first without interacting with the database. Then it will execute any constraints by checking the database.

Let's add our first constraint to enforce a user's unique email!

```elixir
user
|> cast(attrs, [:display_name, :email, :password])
|> validate_required([:display_name, :email, :password])
|> unique_constraint(:email)
```

If we try to add the user to our database, all looks good the first time:

```elixir
iex> user = %User{}
iex> attrs = %{display_name: "prince", email: "prince@test.com", password: "super_secret"}
iex> user |> User.changeset(attrs) |> Repo.insert()
{:ok,
 %MyCoolWebApp.Accounts.User{
   __meta__: %Ecto.Schema.Metadata<:loaded, "users">,
   display_name: "prince",
   email: "prince@test.com",
   id: 1,
   inserted_at: ~N[2019-03-18 01:41:34],
   password: "super_secret",
   password_hash: "$argon2i$v=19$m=65536,t=6,p=1$bhjgmBs9/gYcM2L5Z5sL/g$Z+4D7NIaauU+jwhdYRY4hz0adUdhjAJK6CwYk1AOJdE",
   updated_at: ~N[2019-03-18 01:41:34]
 }}
```

We want to make sure no duplicates get saved, so let's try sending the same thing again:

```elixir
iex> user = %User{}
iex> attrs = %{display_name: "prince", email: "prince@test.com", password: "super_secret"}
iex> user |> User.changeset(attrs) |> Repo.insert()
{:ok,
 %MyCoolWebApp.Accounts.User{
   __meta__: %Ecto.Schema.Metadata<:loaded, "users">,
   display_name: "prince",
   email: "prince@test.com",
   id: 2,
   inserted_at: ~N[2019-03-18 01:43:57],
   password: "super_secret",
   password_hash: "$argon2i$v=19$m=65536,t=6,p=1$H+Fq/IPW+M0YPHOZxMs13Q$ne+jDkwfcOigT8TKDIBYJjVwNdaNkzF/hc7YcRXRItY",
   updated_at: ~N[2019-03-18 01:43:57]
 }}
```

That's weird. It didn't show us an error? That's because Ecto doesn't know it is an error. In fact,
it saved the record to the database thinking that it was safe! If you add a constraint to your `changeset/3`, you **must** enforce the constraint at a database level for it to properly throw the uniqueness error. So for our `unique_constraint`, we need to make sure to create a `unique_index` for the email field. Even though you wrote `unique_constraint` in the `changeset/3`, it doesn't check for that constraint unless there is a `unique_index` applied to the database.

So we need to create and run the migration:

```elixir
defmodule MyCoolWebApp.Repo.Migrations.UpdateUniqueEmailsToUsers do
  use Ecto.Migration

  def change do
    create unique_index(:users, [:email])
  end
end
```

```bash
$ mix ecto.migrate
```

Now if we try again we'll see that our record did not get saved:

```elixir
iex> user = %User{}
iex> attrs = %{display_name: "prince", email: "prince@test.com", password: "super_secret"}
iex> user |> User.changeset(attrs) |> Repo.insert()
{:error,
 %Ecto.Changeset<
   action: :insert,
   changes: %{
     display_name: "prince",
     email: "prince@test.com",
     password: "super_secret",
     password_hash: "$argon2i$v=19$m=65536,t=6,p=1$b6gWjyTiL+JGV6Gz3DjE6A$5m67mfrU/y9YV7adpJ5GXb4+Uh7ley1H3Dz88gCJ4K8"
   },
   errors: [
     email: {"has already been taken",
      [constraint: :unique, constraint_name: "users_email_index"]}
   ],
   data: %MyCoolWebApp.Accounts.User<>,
   valid?: false
 >}
```

Now we have an application that makes sure that no two users can share the same email! Constraints are important to ensure that at a database level the data still has integrity.

One caveat to talk about is that where validations can be checked simultaneously, constraints fail one-by-one. If your table has several constraints and each gets violated, your database will only give you an error to the first one it notices. It would be best to catch as much as you can in validations first before applying the constraints.

### Validation, Constraint, or Both?

Validations and constraints have the same goal of making sure that your data has integrity. Two good questions we should ask ourselves when considering each:

1. Are you trying to prevent bad data from being written to your database? Then you **must** have a constraint.
2. Are you preventing user errors in the app that they can fix themselves? You can use a validation.

We need both when we need to check the data in different ways to ensure that integrity. In this example, we needed to check if the user sent non-empty data before we saved to the database and we also wanted to make sure that they didn't have any duplicate data. They can't know they had a user in our database with that email, so we have a constraint. However, they can fix a field they forgot to fill in, so we have a validation.

### Conclusion

Ecto is a powerful tool for developers to make it easier to interface with the database. However, it is so important for us to understand what it is doing for us so that we use it properly. As you're thinking of your database design, make sure to start off and think about the validations and constraints you need to enforce!
