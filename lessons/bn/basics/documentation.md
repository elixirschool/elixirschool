%{
  version: "1.0.3",
  title: "ডকুমেন্টেশান",
  excerpt: """
  আপনার কোডকে ডকুমেন্ট করুন।
  """
}
---

## অ্যানোটেশান

আপনার কোডে কতটুকু কমেন্টিং করবেন এবং ভাল ডকুমেন্টেশানের মাপকাঠি কী তা নিয়ে যুক্তিতর্কের শেষ নেই। কিন্তু একটা বিষয়ে সকলে একমত যে ডকুমেন্টেশানের গুরুত্ব অপরিসীম। এলিক্সিরের কোর ডেভেলপাররা এটি আগেই বুঝতে পেরেছিলেন যার ফলে ল্যাঙ্গুয়েজটিতে ডকুমেন্টেশানের হরেক রকমের ব্যবস্থা। ডকুমেন্টেশান এলিক্সিরে *প্রথম শ্রেণীর নাগরিক* এবং ডকুমেন্টেশান প্রণালীকে আরামদায়ক করার জন্য রয়েছে বহু ধরণের ব্যবস্থা তথা মডিউল ও ফাংশন।

এলিক্সিরের তিনটি প্রধান ডকুমেন্টেশান ব্যবস্থা হল-

  - `#` - ইনলাইন ডকুমেন্টেশানের জন্য
  - `@moduledoc` - মডিউল ডকুমেন্টেশানের জন্য
  - `@doc` - ফাংশন ডকুমেন্টেশানের জন্য

### ইনলাইন ডকুমেন্টেশান

ডকুমেন্টেশানের সহজতম উপায় হল ইনলাইন কমেন্টিং। রুবি, পাইথন, পার্ল ইত্যাদির মত `#` দিয়ে এলিক্সিরের ইনলাইন কমেন্ট ব্যবহৃত হয়ে থাকে। একে আপনি পাউন্ড অথবা হ্যাশ ডাকতে পারেন।

নীচের এলিক্সির স্ক্রিপ্টটি দেখি-

```elixir
# Outputs 'Hello, chum.' to the console.
IO.puts("Hello, " <> "chum.")
```

এলিক্সির কোড রান করার সময়ে স্ক্রিপ্টটি `#` পরবর্তী সমস্ত কথা বাদ দিয়ে দেয়। কিন্তু যদি আপনি ঠিকমত কমেন্ট করেন তাহলে আপনার কোডে কী হচ্ছে তা অন্যান্য প্রোগ্রামাররা বুঝতে পারবে। তবে, অযথা কমেন্ট না করাই ভাল কারণ তা পরবর্তীতে বিরক্তির কারণ হয়ে দাঁড়াবে। দরকার বুঝে সংক্ষিপ্ত ভাষায় ইনলাইন কমেন্ট করাই উত্তম।

### মডিউল ডকুমেন্টেশান
`@moduledoc` অ্যানোটেটরের মাধ্যমে আমরা মডিউল লেভেলে ইনলাইন ডকুমেন্টেশান করতে পারি। এটি সাধারণত `defmodule` ডিক্লেয়ারের পরপরই অবস্থান করে। নীচে এমন একটি এক লাইনের কমেন্ট দেখুন-

```elixir
defmodule Greeter do
  @moduledoc """
  Provides a function `hello/1` to greet a human
  """

  def hello(name) do
    "Hello, " <> name
  end
end
```

আমরা এই মডিউলকে অ্যাক্সেস করতে পারি `IEx` এ গিয়ে `h` কমান্ডের সাহায্যে।

```elixir
iex> c("greeter.ex", ".")
[Greeter]

iex> h Greeter

                Greeter

Provides a function hello/1 to greet a human
```

### ফাংশন ডকুমেন্টেশান

মডিউলের মত ফাংশনকেও আমরা ডকুমেন্ট করতে পারি যার কার্যপ্রনালি মোটামটি একই রকম। এর জন্য আমাদের `@doc` এর সহায়তা নিতে হবে যা ঠিক ফাংশন ডেফিনিসানের উপরে অবস্থান করে।

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

পুনরায় `IEx` চালু করে `h` কমান্ড দিয়ে আমরা একে দেখতে পারব। উল্লেখ্য শুধু ফাংশনের ডকুমেন্টেশান দেখতে চাইলে আমরা `h` এর পর ফাংশনের নাম (মডিউলসহ, ডটের মাধ্যমে) লিখব।

```elixir
iex> c("greeter.ex")
[Greeter]

iex> h Greeter.hello

                def hello(name)

Prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"

iex>
```

দেখুন কিভাবে আমরা মার্কআপ ব্যবহার করতে পারি ডকুমেন্টেশানিয় কমেন্টের ভেতর। আবার টার্মিনাল তা রেন্ডারও করে। শুধু তাই না, এক্সডকের (`ExDoc`) মাধ্যমে আমরা এহেন ডকুমেন্টেশানকে এইচটিএমএল পেইজে রেন্ডার করতে পারব যা আমাদের পরবর্তী আলোচনার বিষয়বস্তু।

**দ্রষ্টব্য:** `@spec` অ্যানোটেশান দিয়ে আমরা কোডের স্ট্যাটিক অ্যানালাইসিস করতে পারি। <!-- TODO: Remove this as a comment, once advanced/typespec  is translated:
[স্পেসিফিকেইশান ও টাইপ-স্পেক](../../advanced/typespec) নামক অধ্যায়ে এই বিষয়ে আমরা আরও জানব। -->

## এক্সডক

এলিক্সিরের অফিসিয়াল প্রোজেক্টসমূহের একটি হল এক্সডক। এর কাজ হল এলিক্সির প্রোজেক্টের সংশ্লিষ্ট **এইচটিএমএল ও অনলাইন ডকুমেন্টেশান** জেনারেট করা। একে [গিটহাব](https://github.com/elixir-lang/ex_doc) এ পাওয়া যাবে।

চলুন এক্সডক নিয়ে কাজ করি। প্রথম ধাপ- একটি মিক্স প্রোজেক্ট তৈরি-

```bash
$ mix new greet_everyone

* creating README.md
* creating .gitignore
* creating .formatter.exs
* creating mix.exs
* creating lib
* creating lib/greet_everyone.ex
* creating test
* creating test/test_helper.exs
* creating test/greet_everyone_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd greet_everyone
    mix test

Run "mix help" for more commands.

$ cd greet_everyone

```

এবার পূর্বের কোডগুলিকে `lib/greeter.ex` নামক ফাইলে কপি করি এবং চেক করে নেই যে সবকিছু ঠিকঠাক মত চলে। যেহেতু এবার মিক্স নিয়ে কাজ করছি তাই মিক্সসহ `IEx` চালু করা যাক (`iex -S mix` কমান্ড থেকে )-

```bash
iex> h Greeter.hello

                def hello(name)

Prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"
```

### ইন্সটল

যদি উপরের সমস্ত ধাপ ঠিকমত চলে তাহলে এবার আমরা অগ্রসর হতে পারি এক্সডক ইন্সটলেশানের দিকে। মিক্সের `mix.exs` ফাইলে দুটি ডিপেন্ডেন্সি (`:earmark` ও `:ex_doc`) প্রথমে যুক্ত করি।

```elixir
  def deps do
    [{:earmark, "~> 0.1", only: :dev},
    {:ex_doc, "~> 0.11", only: :dev}]
  end
```

`only: :dev` যুগলের উদ্দেশ্য হল এরা প্রোডাকশানের সময়ে ডাউনলোডকৃত হবে না। এদের কাজ শুধু ডকুমেন্টেশান তৈরিতে সহায়তা করা। কিন্তু `Earmark` কেন? এর কাজ হল মার্কডাউন পার্স করা যা আমাদের কমেন্টে ব্যবহৃত হয় এবং সুন্দরভাবে ফর্ম্যাটেড হয় সেয় কমেন্টগুলি ডকুমেন্টেশান আকারে।

কিন্তু বলে রাখা উচিৎ যে আপনি শুধু `Earmark` এ সীমাবদ্ধ না। অন্যান্য মার্কআপ টুল আপনি ব্যবহার করতে পারেন যেমন `Pandoc`, `Hoedown`, `Cmark` ইত্যাদি, যদিও কিছু কনফিগারেশান করতে হবে আপনাকে। এ সম্পর্কে জানতে [এইখানে](https://github.com/elixir-lang/ex_doc#changing-the-markdown-tool) ভিজিট করুন।

এই টিউটোরিয়ালে আমরা `Earmark` ব্যবহার করব।


### ডক জেনারাশান

প্রথমে আমাদের ডিপেন্ডেন্সিকে ডাউনলোড করে নেই এবং এর পর `mix docs` নামক কমান্ড ব্যবহার করলেই জানা যাবে কোথায় তা জেনারেট হয়েছে।

```bash
$ mix deps.get # gets ExDoc + Earmark.
$ mix docs # makes the documentation.

Docs successfully generated.
View them at "doc/index.html".
```

If everything went to plan, you should see a similar message as to the output message in the above example. Let's now look inside our Mix project and we should see that there is another directory called **doc/**. Inside is our generated documentation. If we visit the index page in our browser we should see the following:

![ExDoc Screenshot 1](/images/documentation_1.png)

We can see that Earmark has rendered our Markdown and ExDoc is now displaying it in a useful format.

![ExDoc Screenshot 2](/images/documentation_2.png)

We can now deploy this to GitHub, our own website, or more commonly [HexDocs](https://hexdocs.pm/).

## বেস্ট প্র্যাকটিস

ল্যাঙ্গুয়েজের বেস্ট প্র্যাকটিস তালিকায় ডকুমেন্টেশান উল্লেখযোগ্য একটি বিষয়। এলিক্সির একটি নতুন ল্যাঙ্গুয়েজ হবার ফলে এর বেস্ট প্র্যাকটিস তালিকা এখনো ক্রমবর্ধ্মান এবং প্রতি নিয়ত সুগঠিত হচ্ছে, আর যুক্ত হচ্ছে নতুন নতুন প্র্যাকটিস, কমিউনিটির এক্সপিরিয়েন্সের সাথে সাথে। তারপরও কমিউনিটি নির্মিত একটি গাইডলাইনের সন্ধান পাবেন এইখানে- [The Elixir Style Guide](https://github.com/niftyn8/elixir_style_guide)। যাই হোক, এলিক্সির ডকুমেন্টেশানের জন্য বেস্ট প্র্যাকটিসের কিছু তালিকে নিম্নরূপ-

  - সব সময়ে মডিউলদের ডকুমেন্ট করবেন।

```elixir
defmodule Greeter do
  @moduledoc """
  This is good documentation.
  """

end
```

  - যদি আপনি কোন মডিউলকে ডকুমেন্ট করতে না চান তবে তাকে ব্ল্যাংক না রেখে, `false` দিয়ে অ্যানোটেট করুন।

```elixir
defmodule Greeter do
  @moduledoc false

end
```

 - মডিউল ডকুমেন্টেশানে কোন ফাংশনকে রেফার করলে তার নাম ব্যাকটিক দিয়ে আবদ্ধ করুন-

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 - `@moduledoc` থেকে এক লাইন নীচ দিয়ে কোড শুরু করুন।

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  alias Goodbye.bye_bye
  # and so on...

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 - `IEx` এবং `ExDoc` এ সুন্দরভাবে রেন্ডার করতে চাইলে মার্ক ডাউন ব্যবহার করুন ডকুমেন্টেশান অ্যানোটেশানের ভেতর।

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

 - চেষ্টা করুন ডকুমেন্টেশানে কিছু কোডের উদাহরণ দেওয়ার। এতে আপনার ডকুমেন্টেশানের পাঠক যে উপকৃত হবেন তাই শুধু না, বরং `ExUnit.DocTest` এর মাধ্যমে আপনি ওই কোডের টেস্টিংও করতে পারবেন যেখানে আপনার কমেন্টের দেওয়া কোড ও এর আউটপুট (যা `IEx` সেশানে প্রাপ্ত ইনপুট/আউটপুট ফরম্যাটিংয়ের মত) এর যথার্থতা যাচাই করবে। আরও জানুন অফিসিয়াল ডকুমেন্টেশান থেকে [ExUnit.DocTest]: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html
