---
version: 1.0.1
title: ফাংশন 
---

এলিক্সির এবং অন্যান্য ফাংশনাল ল্যাঙ্গুয়েজে ফাংশন হল প্রথম শ্রেণীর নাগরিক। এই অধ্যায়ে আমরা এলিক্সিরের বিভিন্ন ধরণের ফাংশন নিয়ে কথা বলব এবং আলোচনা করব এদের পার্থক্য ও ব্যবহার নিয়ে। 

{% include toc.html %}

## নামহীন ফাংশন (Anonymous Function)

নাম থেকেই বুঝা যাচ্ছে যে নামহীন ফাংশনের কোন নাম নেই। যেমনটি আমরা দেখেছিলাম `Enum` অধ্যায়ে, এরা প্রায়েই ব্যবহৃত হয় অন্যান্য ফাংশনে। এলিক্সিরে এই ধরনের নামহীন ফাংশন বানাতে হলে আমাদের দুইটি কী-ওয়ার্ড লাগবে- `fn` ও `end`। এদের মাধ্যমে আমরা যে কোন প্যারামিটার লিস্ট ও ফাংশন বডিকে ডিফাইন করতে পারি তাদের `->` দিয়ে আলাদা করে। 

একটি সাধারণ উদাহরণ দেখা যাক- 

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### `&` শর্ট-হ্যান্ড  

নামহীন ফাংশন এতটাই ব্যবহৃত হয় যে এলিক্সির একটি শর্টকাট দিয়ে থাকে তাদের তৈরি করার জন্য- 

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

দেখেই বুঝা যাচ্ছে যে প্যারামিটার হিসেবে ব্যবহৃত হয় `&1`, `&2`, `&3` ইত্যাদি। 

## প্যাটার্ন ম্যাচিং 

শুধুমাত্র বেরিয়েবলের ক্ষেত্রেই নয়, ফাংশন বানানোর সময়েও প্যাটার্ন ম্যাচিং কাজে আসে। 

এলিক্সির প্যাটার্ন ম্যাচিংয়ের মাধ্যমে প্রথম সারির প্যারামিটার মিলিয়ে থাকে সংশ্লিষ্ট বডির সাথে- 

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
1
iex> handle_result.({:ok, some_result})
Handling result...
:ok
iex> handle_result.({:error})
An error has occurred!
```

## নেইমড ফাংশন 

নামহীন ফাংশন তো দেখলাম, এবার নামওয়ালা ফাংশন তথা নেইমড ফাংশন দেখা যাক। এলিক্সিরে নেইমড ফাংশন ব্যবহৃত হয় মডিউলের ভেতর, `def` কী-ওয়ার্ডের মধ্য দিয়ে। আগামী অধ্যায়ে আমরা মডিউল নিয়ে কথা বলব, তাই আপাতত শুধু ফাংশনের দিকে আলোকপাত করা যাক। 

এক মডিউলের ভেতর সৃষ্ট ফাংশন অন্যান্য মডিউলে ব্যবহারযোগ্য। এটি এলিক্সিরের একটি বেশ প্রয়োজনীয় বিল্ডিং ব্লক। 

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

যদি আমাদের ফাংশন শুধু এক লাইনের হয়ে থাকে, তবে আমরা একে সংক্ষিপ্ত করতে পারি `do:` এর মাধ্যমে। 

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

প্যাটার্ন ম্যাচিংয়ের জ্ঞান দিয়ে চলুন রিকারসনের একটি উদাহরণ দেখি আমরা, নেইমড ফাংশনের মাধ্যমে- 

```elixir
defmodule Length do
  def of([]), do: 0
  def of([_ | tail]), do: 1 + of(tail)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### ফাংশন নামকরণ ও অ্যারিটি 

আমরা আগেই বলেছি যে এলিক্সিরে ফাংশনের পরিচয়  হল তার নাম ও অ্যারিটির জুটি। এর মানে আপনি নিম্নবর্ণিত কাজ করতে পারেন- 

```elixir
defmodule Greeter2 do
  def hello(), do: "Hello, anonymous person!"   # hello/0
  def hello(name), do: "Hello, " <> name        # hello/1
  def hello(name1, name2), do: "Hello, #{name1} and #{name2}"
                                                # hello/2
end

iex> Greeter2.hello()
"Hello, anonymous person!"
iex> Greeter2.hello("Fred")
"Hello, Fred"
iex> Greeter2.hello("Fred", "Jane")
"Hello, Fred and Jane"
```

ফাংশনের নামগুলো আমরা কমেন্টে দিয়েছি। ফাংশনের প্রথম রূপ কোন প্যারামিটার নেয় না, তাই এটি পরিচিত হবে `hello/0` হিসেবে; দ্বিতীয়টি একটি আর্গুমেন্ট নেয় বিধায় একে আমরা ডাকব `hello/1`। অন্যান্য ল্যাঙ্গুয়েজের ফাংশন ওভারলোডিংয়ের মত নয় এরা, এরা আসলে ভিন্ন ভিন্ন ফাংশন। 

প্যাটার্ন ম্যাচিং শুধুমাত্র তখনি ব্যবহৃত হয় যখন একাধিক প্যাটার্ন সম-আর্গুমেন্ট বিশিষ্ট ফাংশনের উপর ব্যবহৃত হয়। 

### প্রাইভেট ফাংশন 

যদি আমরা কোন ফাংশনকে শুধুমাত্র তার নিজস্ব মডিউলে ব্যবহার করতে চাই (অন্য মডিউল থেকে নয়) তখন আমরা তাদের প্রাইভেট হিসেবে ঘোষণা করব। এলিক্সিরে আমরা `defp` দিয়ে প্রাইভেট ফাংশন তৈরি করি। 

```elixir
defmodule Greeter do
  def hello(name), do: phrase <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### গার্ড 

[কন্ট্রোল স্ট্রাকচার](../control-structures) অধ্যায়ে আমরা গার্ড নিয়ে কিছু কথা বলেছিলাম। এখন আমরা দেখব কি করে এদেরকে নেইমড ফাংশনে ব্যবহার করা হয়। 

এলিক্সির যখনি কোন ফাংশন ম্যাচ করে, এরপর সংশ্লিষ্ট গার্ড চেক করা হবে। 

নীচের ফাংশন দুইটি একই প্যাটার্ন ফলো করে, কিন্তু এদের মধ্যে পার্থক্য করা হয় গার্ডের ভিন্নতা (যেমন আর্গুমেন্ট টাইপ) দিয়ে। 

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase() <> name
  end

  defp phrase, do: "Hello, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"
```

### ডিফল্ট আর্গুমেন্ট 

আমরা ডিফল্ট আর্গুমেন্ট প্রদান করি `argument \\ value` সিনট্যাক্স দিয়ে:

```elixir
defmodule Greeter do
  def hello(name, language_code \\ "en") do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello("Sean", "en")
"Hello, Sean"

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.hello("Sean", "es")
"Hola, Sean"
```

যখন আমরা গার্ড ও ডিফল্ট আর্গুমেন্টের সমন্বয় সাধন করি তখন একটি সমস্যার সৃষ্টি হয়। সেটা কী তা দেখা যাক- 

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code \\ "en") when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) iex:31: definitions with multiple clauses and default values require a header. Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b) do ... end

one should write:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end

def hello/2 has multiple clauses and defines defaults in one or more clauses
    iex:31: (module)
```

এলিক্সির ডিফল্ট আর্গুমেন্ট ও একাধিক ম্যাচিং ফাংশনকে একত্রে ব্যবহার করতে দেয় না, কারণ তা কিছু কনফিউসনের সৃষ্টি করে। এ ধরনের সমাধানের জন্য আমরা একটি ফাংশন হেড অ্যাড করব আমাদের ডিফল্ট আর্গুমেন্টের সাথে- 

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en")

  def hello(names, language_code) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code) when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "es"
"Hola, Sean, Steve"
```
