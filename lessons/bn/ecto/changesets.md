%{
  version: "1.2.2",
  title: "চেইঞ্জসেট",
  excerpt: """
  ডাটাবেসে ডাটা, ইনসার্ট, আপডেট অথবা ডিলেট করতে ব্যবহৃত `Ecto.Repo.insert/2`, `update/2` এবং `delete/2` ফাংশনগুলোর প্রথম প্যরামিটার হিসেবে চেইঞ্জসেট লাগে, কিন্তু কি এই চেইঞ্জসেট?
  
  ইনপুট ডাটা তে কোনো এরর আছে কি না এটা পরীক্ষা করে দেখা প্রত্যেক ডেভেলপারের নিত্যদিনের কাজের অংশ — আমাদের ডাটাগুলো ব্যবহারের আগে আমরা ডাটাগুলো সঠিক অবস্থায় আছে তা নিশ্চিত করতে চাই।

  এক্টো `Changeset` মডিউল এবং ডাটা স্ট্রাকচারের মাধ্যমে এক্টো আমাদেরকে চেইঞ্জিং ডাটা নিয়ে কাজ করার একটা পরিপূর্ণ সমাধান প্রদান করে।   
  এই অধ্যায়ে আমরা এই ফাংশনালিটিটি দেখবো এবং কিভাবে ডাটাবেসে ডাটা রাখার আগে, ডাটা ইন্টেগ্রিটি যাচাই করতে হয় তা শিখবো। 
  """
}
---

## প্রথম চেইঞ্জসেট তৈরি

চলুন, একটা ফাঁকা চেইঞ্জসেট স্ট্রাক্ট `%Changeset{}` দেখা যাক:

```elixir
iex> %Ecto.Changeset{}
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: nil, valid?: false>
```

দেখতে পাচ্ছেন, এর কিছু ব্যবহারযোগ্য ফিল্ড আছে, কিন্তু ঐগুলো সবই বর্তমানে ফাঁকা।

চেইঞ্জসেটকে সত্যিকার অর্থে ব্যবহারযোগ্য করতে হলে আমরা যখন এটাকে তৈরী করি, তখন আমাদের ডাটা দেখতে কেমন হবে তার একটা নীল নকশা দিয়ে দিতে হবে।
আমাদের ডাটার জন্যে স্কিমা থেকে ভালো নীল নকশা আর কি হতে পারে যেটা ফিল্ডস এবং টাইপস গুলো উল্লেখ করে?

চলুন, আগের অধ্যায়ে তৈরি করা `Friends.Person` স্কিমাটি ব্যবহার করা যাক:

```elixir
defmodule Friends.Person do
  use Ecto.Schema

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

`Person` স্কিমাটি ব্যবহার করে চেইঞ্জসেট তৈরি করতে আমরা `Ecto.Changeset.cast/3` ফাংশনটি ব্যবহার করবো:

```elixir
iex> Ecto.Changeset.cast(%Friends.Person{name: "Bob"}, %{}, [:name, :age])
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Person<>,
 valid?: true>
```

এখানে, প্রথম প্যারামিটার হবে মূল ডাটা — আর স্ট্রাক্ট হলো প্রারম্ভিক `%Friends.Person{}`।
এক্টো স্ট্রাক্ট এর ভিত্তিতে নিজে নিজেই স্কিমা খুঁজে নিতে সক্ষম।
দ্বিতীয় প্যারামিটারে আমরা কি চেইঞ্জগুলো করতে চাচ্ছি তা দিবো - এই ক্ষেত্রে শুধুমাত্র একটা ফাঁকা ম্যাপ।
তৃতীয় প্যারামিটারটি `cast/3` বিশেষ: এটা হলো যে ফিল্ডগুলো চেইঞ্জ হবে তাদের তালিকা, এর ফলে আমরা কোন ফিল্ড গুলো চেইঞ্জ হবে সেটা নিয়ন্ত্রণ করে বাকি ফিল্ডগুলোকে নিরাপত্তা প্রদান করতে পারি।

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

দেখতেই পাচ্ছেন কিভাবে দ্বিতীয়বারে নতুন নামটি ইগনোর করা হয়েছে, যেখানে আমরা এটা চেইঞ্জ হবে তা বিশেষভাবে উল্লেখ করে দেই নি।

`cast/3` এর পরিবর্তে আমরা `change/2` ফাংশনটিও ব্যবহার করতে পারি যেটার `cast/3` এর মতো চেইঞ্জগুলো ফিল্টার করতে পারে না।
এটা তখনই ব্যবহার করা উচিত, যখন আপনি নিশ্চিত যে চেইঞ্জগুলো নির্ভরযোগ্য উৎস থেকে করা হচ্ছে অথবা আপনি নিজেই ম্যানুয়ালি ডাটা নিয়ে কাজ করছেন।

আমরা তো চেইঞ্জসেট তৈরি করতে শিখেছি, কিন্তু আমাদের যেহেতু কোনো ভ্যালিডেশান নেই, মানুষের নামের যেকোনো চেইঞ্জই গ্রহণ করা হবে, তাই আমরা ফাঁকা নামও পেতে পারি:

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

এক্টো বলছে, চেইঞ্জসেটটি ভ্যালিড, কিন্তু আসলে আমরা ফাঁকা নাম অনুমোদন করতে চাই না, চলুন এটা ঠিক করা যাক!

## ভ্যালিডেশান

ভ্যালিডেশান এর জন্যে এক্টোতে অনেকগুলো বিল্ট-ইন ফাংশন রয়েছে।

আমরা `Ecto.Changeset` অনেক ব্যবহার করব, তাই আমরা `Ecto.Changeset` কে আমাদের `person.ex` মডিউলে ইম্পোর্ট করব, যেটাতে আমাদের স্কিমাও রয়েছে:

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

এখন, আমরা `cast/3` ফাংশনটি সরাসরি ব্যবহার করতে পারি।

একটি স্কিমার এক বা একাধিক চেইঞ্জসেট ক্রিয়েটর ফাংশন থাকতে পারে। চলুন, একটি ক্রিয়েটর ফাংশন তৈরি করি যেটা একটি স্ট্রাক্ট ও চেইঞ্জের ম্যাপ নেয় এবং চেইঞ্জসেট রিটার্ন করে:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
end
```

এখন, চেইঞ্জসেটে সবসময় নাম থাকবে তা আমরা নিশ্চিত করতে পারি:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> validate_required([:name])
end
```

যখন আমরা `Friends.Person.changeset/2` ফাংশনটিকে ফাঁকা নাম দিয়ে কল করি, তখন চেইঞ্জসেট আর ভ্যালিড থাকবে না, তাই এটা একটা এরর মেসেজ দেখিয়ে সাহায্য করবে।
নোট: `iex` এ কাজ করার সময় `recompile()` রান করতে ভুলবেন না, না হলে কোডের পরিবর্তনগুলো দেখতে পাবেন না।

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

উপরে উল্লেখিত চেইঞ্জসেট দিয়ে যদি আপনি `Repo.insert(changeset)` করতে চান, তাহলে আপনি একই এররটি এবং সাথে `{:error, changeset}` রিসিভ করবেন, তাই আপনাকে প্রতিবারেই `changeset.valid?` ব্যবহার করা লাগবে না।
সরাসরি, ইনসার্ট, আপডেট ও ডিলিট করার চেষ্টা করে কোনো এরর পেলে সেটা প্রসেস করাই সহজতর।

`validate_required/2` ছাড়াও, `validate_length/3` নামের একটি ফাংশন রয়েছে, যেটা কিছু অতিরিক্ত অপশন নিতে পারে:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> validate_required([:name])
  |> validate_length(:name, min: 2)
end
```

যদি আমরা একটা মাত্র ক্যারেক্টার বিশিষ্ট নাম প্রদান করি, তাহলে আপনি চেষ্টা করে রেজাল্টটি কি হবে তা অনুমান করে ফেলতে পারেন! 

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

আপনি হয়তো আশ্চর্য হচ্ছেন, এরর মেসেজে বিদঘুটে `%{count}` দেখে — এটা অন্যান্য ল্যাংগুয়েজে ট্রান্সলেশান সহজ করার জন্যেই বিদ্যমান; আপনি যদি সরাসরি ইউজারকে এরর দেখাতে চান, সেক্ষেত্রে আপনি এটাকে [`traverse_errors/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#traverse_errors/2) ব্যবহার করে মানুষের পড়ার উপযুক্ত করতে তুলতে পারেন — ডকুমেন্টে উল্লেখিত উদাহরণটি দেখে নিন।

এছাড়াও, `Ecto.Changeset` আরও কিছু বিল্ট-ইন ভ্যালিডেটর নিম্নে দেয়া হলো:

+ validate_acceptance/3
+ validate_change/3 & /4
+ validate_confirmation/3
+ validate_exclusion/4 & validate_inclusion/4
+ validate_format/4
+ validate_number/3
+ validate_subset/4

[এখানে](https://hexdocs.pm/ecto/Ecto.Changeset.html#summary), পুরো তালিকাটি দেখতে এবং কিভাবে ব্যবহার করতে হয় তা জানতে পারবেন।

### কাস্টম ভ্যালিডেশান

যদিও বিল্ট-ইন ভ্যালিডেটরগুলো বড় পরিসরের ইউজ কেইস কভার করে, তবুও আপনার হয়তো অন্যরকম কিছু লাগতে পারে।

এতক্ষণ পর্যন্ত আমাদের ব্যবহার করা প্রতিটা `validate_` ফাংশনই `%Ecto.Changeset{}` গ্রহণ ও রিটার্ন করে, তাই আমরা সহজেই আমাদের নিজেদেরটি প্লাগ করতে পারি।

উদাহরণস্বরূপ, শুধুমাত্র কাল্পনিক চরিত্র এর নামই গ্রহণ করা হবে তা আমরা নিশ্চিত করতে পারি:

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

উপরে, আমরা দুইটি নতুন হেল্পার ফাংশন ব্যবহার করেছি: [`get_field/3`](https://hexdocs.pm/ecto/Ecto.Changeset.html#get_field/3) এবং [`add_error/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#add_error/4)। নাম দেখেই হয়তো এদের কাজ অনুমান করতে পেরেছেন তবুও, আমি আপনাকে ডকুমেন্টেশানের লিঙ্কগুলোতে ঢুঁ মেরে আসার অনুরোধ করবো।

সবসময় `%Ecto.Changeset{}` রিটার্ন করাই উত্তম, তাহলে আপনি `|>` অপারেটর ব্যবহার করতে পারবেন, সুতরাং নতুন নতুন ভ্যালিডেশান যোগ করতে সুবিধা হবে।

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

দারুণ, এটা কাজ করেছে! কিন্তু, আমাদের এই ফাংশন নিজেদের ইমপ্লিমেন্ট করার প্রয়োজন ছিলো না — আমরা চাইলেই `validate_inclusion/4` ব্যবহার করতে পারতাম; যাই হোক, আপনি দেখতে পাচ্ছেন কিভাবে আপনি নিজের এরর দেখাতে পারেন এটা পরবর্তীতে কাজে দিবে।

## প্রোগ্রামেটিকালি চেইঞ্জ যোগ 

অনেক সময়, আপনি হয়তো চেইঞ্জসেটে ম্যানুয়ালি চেইঞ্জ যোগ করতে চাইবেন। এর জন্যে `put_change/3` হেল্পার ফাংশনটি ব্যবহার করতে পারেন।

`name` ফিল্ডটিকে রিকুয়েরড না করে, চলুন ইউজারকে নাম ছাড়াই সাইন আপ করার সুযোগ দিই, এবং তাদের "Anonymous" নামে ডাকি।
আমাদের যে ফাংশনটি দরকার তা পরিচিত মনে হতে পারে — কিছুক্ষণ আগের `validate_fictional_name/1` ফাংশনের মতোই এটা চেইঞ্জসেট গ্রহণ ও রিটার্ন করে:

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

আমরা চাইলে, শুধুমাত্র যখন ইউজার আমাদের অ্যাপ্লিকেশনে রেজিস্টার করে তখনই তাদের নাম "Anonymous" সেট করতে পারি; এটা করতে হলে, আমাদের নতুন একটি চেইঞ্জসেট ক্রিয়েটর ফাংশন তৈরি করিতে হবে:

```elixir
def registration_changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> set_name_if_anonymous()
end
```

এখন `Anonymous` স্বয়ংক্রিয়ভাবেই সেট হয়ে যাবে, আমাদের আর `name` দিতে হবে না:

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

কিছু নির্দিষ্ট দায়িত্ব পালন করে (যেমন `registration_changeset/2`) এমন ক্রিয়েটর ফাংশন অহরহই দেখা যায় — অনেক সময় আপনার কিছু নির্দিষ্ট ভ্যালিডেশান করতে হতে পারে অথবা নির্দিষ্ট প্যারামিটার ফিল্টার করার সক্ষমতা লাগতে পারে।
উপরের ফাংশনটি তখন `sign_up/1` হেল্পারে অন্য কোথাও ব্যবহৃত হতে পারে:

```elixir
def sign_up(params) do
  %Friends.Person{}
  |> Friends.Person.registration_changeset(params)
  |> Repo.insert()
end
```

## উপসংহার

এছাড়াও এখনো অনেক গুলো ফাংশনালিটি এবং ইউজ কেইস বাকী রয়ে গেছে যেগুলো আমরা এই অধ্যায়ে কভার করি নি, যেমনঃ [স্কিমালেস চেইঞ্জসেট](https://hexdocs.pm/ecto/Ecto.Changeset.html#module-schemaless-changesets) যেটা আপনি _যেকোনো_ ডাটা ভ্যালিডেট করতে ব্যবহার করতে পারেন; অথবা চেইঞ্জসেট এর সাথে সাথে এর সাইড-ইফেক্টগুলোর মোকাবেলা করতে পারেন ([`prepare_changes/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#prepare_changes/2)) বা এসোসিয়েশান অথবা এমবেড নিয়ে কাজ করতে পারেন।
এগুলো হয়তো আমরা এডভান্সড অধ্যায়গুলোতে পরবর্তীতে কভার করতে পারি, কিন্তু এর মধ্যে — আরও বিস্তারিত জানতে [এক্টোর চেইঞ্জসেট ডকুমেন্টেশান](https://hexdocs.pm/ecto/Ecto.Changeset.html) পড়ার আমন্ত্রণ জানাচ্ছি।
