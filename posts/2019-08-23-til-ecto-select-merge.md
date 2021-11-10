%{
  author: "Kate Travers",
  author_link: "https://github.com/ktravers",
  date: ~D[2019-08-23],
  tags: ["ecto", "TIL"],
  title: "TIL How to Select Merge with Ecto.Query",
  excerpt: """
  Before you reach for adding another association to your schema, consider using `Ecto.Query#select_merge/3` with a virtual field instead.
  """
}

---

Working with Elixir and Ecto, I've run into scenarios where I needed to retrieve data from a table plus maybe a field or two from an unassociated table. In the past, whenever this happened, I'd usually spin up something I wasn't totally satisfied with -- maybe updating the schema(s), breaking it up into multiple queries, or building a multi-select statement if I was feeling fancy.

Happily, today I learned there's a better way. You can accomplish that same end result in a single query expression with `Ecto.Query#select_merge/3`.

Let's run through an example to see it in action.

## Setup

Say you work at a school with an admissions department, and you've been tasked with displaying an event log showing all the events related to a given admission, organized into three columns: 1) date, 2) action taken, and 3) who the action was taken by.

| Date     | Action           | Taken By         |
|----------|------------------|------------------|
| 8/1/2019 | Student Admitted | Albus Dumbledore |


To start with, we have an `AdmissionEvent` schema that looks like this:

```elixir
defmodule Registrar.Tracking.AdmissionEvent do
  use Ecto.Schema

  schema "admission_events" do
    field(:action, :string)
    field(:admission_id, :integer)
    field(:admitter_uuid, Ecto.UUID)
    field(:occurred_at, :naive_datetime)
  end
end
```

...and a User schema that looks like this:

```elixir
defmodule Registrar.User do
  use Ecto.Schema

  schema "users" do
    field(:uuid, Ecto.UUID)
    field(:full_name, :string)
  end
end
```

...and just for the sake of completeness, a super simple Admission schema:

```elixir
defmodule Registrar.Admission do
  use Ecto.Schema

  schema "admission" do
    field(:admittee_uuid, Ecto.UUID)
    field(:admitter_uuid, Ecto.UUID)
    field(:admitted_at, :naive_datetime)
  end
end
```

The problem here is the admitter's full name lives on `User`, which isn't currently associated with `AdmissionEvent`. So if we did a straight-forward select query, we'd end up with the admission events we need to populate the table, but not the admitters' full names.

```elixir
defmodule Registrar.Tracking.AdmissionEvent do
  use Ecto.Schema
  import Ecto.Query, only: [from: 2]
  alias Registrar.Admission
  alias Registrar.Tracking.AdmissionEvent

  schema "admission_events" do
    field(:action, :string)
    field(:admission_id, :integer)
    field(:admitter_uuid, Ecto.UUID)
    field(:occurred_at, :naive_datetime)
  end

  def for_admission(query \\ AdmissionEvent, %Admission{} = admission) do
    from(ae in query,
      where: ae.admission_id == ^admission.id,
      order_by: [desc: ae.occurred_at]
    )
  end
end
```

```elixir
# Taking our query function for a spin...

iex> admission = Repo.get(Admission, 1)
iex> AdmissionEvent.for_admission(admission) |> Repo.all()
[
  %Registrar.Tracking.AdmissionEvent{
    __meta__: %Ecto.Schema.Metadata<:loaded, "admission_events">,
    action: "Student Admitted",
    admission_id: 3,
    admitter_uuid: "7edd4d7f-a790-41f9-b4ef-16f1dc3b33ea",
    id: 1,
    occurred_at: ~N[2019-07-29 02:22:18]
  }
]
```

So, how do we want to go about getting the full name? We've got lots of options to choose from, but for this post, we'll compare two: one folks might reach for first (adding an association and preloading the data) and one we'll hopefully reach for more often moving forward (`Ecto.Query#select_merge/3`).

## Option 1: Add an Association and Preload the Data

If we associate User and AdmissionEvent, then we can preload the associated User record and read the full name directly from there.

```elixir
defmodule Registrar.Tracking.AdmissionEvent do
  use Ecto.Schema
  import Ecto.Query, only: [from: 2]
  alias Registrar.Tracking.AdmissionEvent
  alias Registrar.User

  schema "admission_events" do
    field(:action, :string)
    field(:admission_id, :integer)
    field(:admitter_uuid, Ecto.UUID)
    field(:occurred_at, :naive_datetime)

    # New association
    belongs_to(:admitter, User, foreign_key: :uuid)
  end
end

defmodule Registrar.User do
  use Ecto.Schema
  alias Registrar.Tracking.AdmissionEvent

  schema "users" do
    field(:uuid, Ecto.UUID)
    field(:full_name, :string)

    # New association
    has_many(:admission_events, AdmissionEvent)
  end
end
```

```elixir
# Trying out our new association...

iex> admission = Repo.get(Admission, 1)
iex> events = AdmissionEvent.for_admission(admission) |> Repo.all() |> Repo.preload(:admitter)
[
  %Registrar.Tracking.AdmissionEvent{
    __meta__: %Ecto.Schema.Metadata<:loaded, "admission_events">,
    action: "Student Admitted",
    admission_id: 3,
    admitter: %Registrar.User{
      __meta__: %Ecto.Schema.Metadata<:loaded, "users">,
      id: 1,
      name: "Albus Dumbledore",
      uuid: "7edd4d7f-a790-41f9-b4ef-16f1dc3b33ea"
    },
    admitter_uuid: "7edd4d7f-a790-41f9-b4ef-16f1dc3b33ea",
    id: 1,
    occurred_at: ~N[2019-07-29 02:22:18]
  }
]
iex> event = List.first(events)
iex> event.admitter.name
"Albus Dumbledore"
```

This approach gets the job done, but it's a little heavy. We only need the admitter's full name, so why retrieve an entire `User` struct? You can also see how this pattern could lead to a super cluttered User schema. Right now it has many `admission_events`, but soon it could have many `application_events`, `interview_events`, `billing_events`, etc.

## Option 2: ✨ Select Merge ✨

`Ecto.Query#select_merge/3` gives us an option that's much more succinct and precise. Check out this slickness:

```elixir
defmodule Registrar.Tracking.AdmissionEvent do
  use Ecto.Schema
  import Ecto.Query, only: [from: 2]
  alias Registrar.Admission
  alias Registrar.User
  alias Registrar.Tracking.AdmissionEvent

  schema "admission_events" do
    field(:action, :string)
    field(:admission_id, :integer)
    field(:admitter_uuid, Ecto.UUID)
    field(:occurred_at, :naive_datetime)

    ###### STEP ONE #######
    #  Add Virtual Field  #
    #######################
    field(:admitter_name, :string, virtual: true)
  end

  def for_admission(query \\ AdmissionEvent, %Admission{} = admission) do
    from(ae in query,
      where: ae.admission_id == ^admission.id,
      order_by: [desc: ae.occurred_at],

      #### STEP TWO ####
      #  Join on User  #
      ##################
      join: u in User,
      on: ae.admitter_uuid == u.uuid,

      ############ STEP THREE #############
      #  Select Merge into Virtual Field  #
      #####################################
      select_merge: %{admitter_name: u.full_name}
    )
  end
end
```

```elixir
# Trying out select merge...

iex> admission = Repo.get(Admission, 1)
iex> AdmissionEvent.for_admission(admission) |> Repo.all()
[
  %Registrar.Tracking.AdmissionEvent{
    __meta__: %Ecto.Schema.Metadata<:loaded, "admission_events">,
    action: "Student Admitted",
    admission_id: 3,
    admitter_name: "Albus Dumbledore",
    id: 1,
    occurred_at: ~N[2019-07-29 02:22:18]
  }
]
iex> event = List.first(events)
iex> event.admitter_name
"Albus Dumbledore"
```

By adding a virtual field and populating it with `select_merge`, we end up with a much lighter-weight solution. We get exactly the data we need without adding any new associations, keeping our schemas decoupled. Plus we have a pattern to follow that's a little more extensible moving forward, should we need to introduce event logs for different types of events.

## Summary

`Ecto.Query#select_merge/3` allows us to populate a virtual field directly within a select query, giving us all kinds of flexibility when it comes to designing schemas and composing queries.

10/10 Would compose again

## Resources

- [Docs](https://hexdocs.pm/ecto/Ecto.Query.html#select_merge/3)
- [Source code](https://github.com/elixir-ecto/ecto/blob/master/lib/ecto/query.ex#L1168-L1209)
