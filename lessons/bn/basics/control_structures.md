%{
  version: "1.0.2",
  title: "কন্ট্রোল স্ট্রাকচার",
  excerpt: """
  এই অধ্যায়ে আমরা এলিক্সিরে ব্যবহৃত কন্ট্রোল স্ট্রাকচার নিয়ে কথা বলব।
  """
}
---

## `if` ও `unless`

`if/2` বহুল ব্যবহৃত একটি কন্ট্রোল স্ট্রাকচার যা প্রায় সমস্ত ল্যাঙ্গুয়েজেই রয়েছে। কিছু কিছু ল্যাঙ্গুয়েজ যেমন রুবী ও পার্লে এর উল্টো তথা `unless/2` এর ব্যবস্থা রয়েছে। এলিক্সিরে `if/2` ও `unless/2` অন্যান্য ল্যাঙ্গুয়েজের মতই মূলত কাজ করে কিন্তু এরা ল্যাঙ্গুয়েজের কোন গঠন নয়, বরং ম্যাক্রো। এরা কিভাবে কাজ করে তা জানতে ভিজিট করুন [কার্নেল মডিউল](https://hexdocs.pm/elixir/Kernel.html) পেইজটিতে।


জেনে রাখা ভাল যে এলিক্সিরে "ফলসি" ভ্যালু মাত্র দুইটি- `nil` এবং `false`। এই ফলসি ভ্যালুর উপর নির্ভর করে কন্ট্রোল স্ট্রাকচারের পাস অথবা ফেইল করা। 

```elixir
iex> if String.valid?("Hello") do
...>   "Valid string!"
...> else
...>   "Invalid string."
...> end
"Valid string!"

iex> if "a string value" do
...>   "Truthy"
...> end
"Truthy"
```

`unless/2` আর `if/2` এর কার্যপ্রণালি একই, তবে `unless/2` শুধু "ফলসি" ভ্যালুকেই গ্রুহণ করে।

```elixir
iex> unless is_integer("hello") do
...>   "Not an Int"
...> end
"Not an Int"
```

## `case`

একাধিক প্যাটার্নের সাথে ম্যাচ করতে হলে আমরা `case` ব্যবহার করব। 

```elixir
iex> case {:ok, "Hello World"} do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```

শেষের `_` ভেরিয়েবল গুরুত্বপূর্ণ এই স্ট্রাকচারে। অন্য কেউ না ম্যাচ করতে পারলে এর আওতাধীন লজিক কাজ করে। একে ছাড়া এরর রেইজড হবে যদি উপরের কেউ ম্যাচ করতে না পারে।  

```elixir
iex> case :even do
...>   :odd -> "Odd"
...> end
** (CaseClauseError) no case clause matching: :even

iex> case :even do
...>   :odd -> "Odd"
...>   _ -> "Not Odd"
...> end
"Not Odd"
```

`_` কে আপনি `else` হিসেবে চিন্তা করতে পারেন। অর্থাৎ অন্য সব কন্ডিশানকে যারা ফেইল করে, তাদের এরা ম্যাচ করে। 

`case` যেহেতু প্যাটার্ন ম্যাচ করে কাজেই প্যাটার্নের সমস্ত নিয়ম এর উপর প্রযোজ্য। যেমন কোন ভেরিয়েবলের সাথে ম্যাচ করতে চাইলে `^` অর্থাৎ পিন অপারেটর ব্যবহার করতে হয়। 

```elixir
iex> pie = 3.14 
 3.14
iex> case "cherry pie" do
...>   ^pie -> "Not so tasty"
...>   pie -> "I bet #{pie} is tasty"
...> end
"I bet cherry pie is tasty"
```

`case` এর আরেকটি ফিচার হল গার্ডের ব্যবহার। 

_এই উদাহরণটি সরাসরি এলিক্সিরের অফিসিয়াল ডকুমেন্টেশান থেকে নেয়া [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#case) গাইড থেকে।_

```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "Will match"
...>   _ ->
...>     "Won't match"
...> end
"Will match"
```

আরও জানতে হলে অফিসিয়াল ডকুমেন্টেশানের [Expressions allowed in guard clauses](https://hexdocs.pm/elixir/guards.html#list-of-allowed-expressions) চ্যাপ্টারটি দেখুন।

## `cond`

যখন আমরা একাধিক কন্ডিশানের সাথে আমাদের ম্যাচিং করতে হবে তখন `cond` ব্যবহার করব যা অন্যান্য ল্যাঙ্গুয়েজের `else if`, `elsif`, `elif` ইত্যাদির মত করে কাজ করে। 

_এই উদাহরণটি সরাসরি এলিক্সিরের অফিসিয়াল ডকুমেন্টেশান থেকে নেয়া [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#case) গাইড থেকে।_

```elixir
iex> cond do
...>   2 + 2 == 5 ->
...>     "This will not be true"
...>   2 * 2 == 3 ->
...>     "Nor this"
...>   1 + 1 == 2 ->
...>     "But this will"
...> end
"But this will"
```

`case` এর মত `cond` ও এরর রেইজ করবে যদি কোন ম্যাচ পাওয়া না যায়। `case` এর `_` এর সমকক্ষ হিসেবে আমরা `true` ব্যবহার করতে পারি যা ফলব্যাক হিসেবে কাজ করবে যখন কোন কন্ডিশান না মিলে।

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```

## `with`

কখনো কখনো  আমরা এমন পরিস্থিতিতে পরি যখন `case` স্টেটমেন্ট এর ক্লোজগুলি সুন্দর মত পাইপ করা যায় না এবং নেস্টেড হয়ে যায়। `with` এক্সপ্রেশানের আবির্ভাব হয়েছে এই ধরণের অবস্থা হ্যান্ডল করার জন্য। এটি হল `with` কী-ওয়ার্ড, সংশ্লিষ্ট জেনারেটরসমূহ এবং একটি এক্সপ্রেশানের সমন্বয়।  

জেনারেটর নিয়ে আমরা লিস্ট কম্প্রিহেনশান অধ্যায়ে কথা বলব। আপাতত এতটুকু জেনে রাখি যে এরা প্যাটার্ন ম্যাচিং দিয়ে `<-` এর ডান হাতের এক্সপ্রেশানকে কম্পেয়ার করে বাম হাতের এক্সপ্রেশানের সাথে। 

`with` এর একটি সহজ উদাহরণ দিয়ে শুরু করা যাক- 

```elixir
iex> user = %{first: "Sean", last: "Callan"}
%{first: "Sean", last: "Callan"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
"Callan, Sean"
```

কোন এক্সপ্রেশান ম্যাচ করতে সক্ষম না হলে ম্যাচ না হওয়া ভ্যালু রিটার্ন করা হয়।  

```elixir
iex> user = %{first: "doomspork"}
%{first: "doomspork"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
:error
```

`with` ছাড়া ব্যবহৃত একটি উদাহরণ দিয়ে দেখা যাক কিভাবে `with` আমাদের উপকারে আসে- 

```elixir
case Repo.insert(changeset) do
  {:ok, user} ->
    case Guardian.encode_and_sign(user, :token, claims) do
      {:ok, jwt, full_claims} ->
        important_stuff(jwt, full_claims)

      error ->
        error
    end

  error ->
    error
end
```

এবার রিফ্যাক্টর করে `with` কে নিয়ে আসা যাক- 

```elixir
with {:ok, user} <- Repo.insert(changeset),
     {:ok, jwt, full_claims} <- Guardian.encode_and_sign(user, :token, claims),
     do: important_stuff(jwt, full_claims)
```

উপরিউক্ত কোডটি যেমন ছোট তেমনি বোধগম্য। 

এলিক্সির ১.৩ থেকে `with` স্টেটমেন্টে `else` কে আনা হয়েছে। 

```elixir
import Integer

m = %{a: 1, c: 3}

a =
  with {:ok, res} <- Map.fetch(m, :a),
       true <- is_even(res) do
    IO.puts("Divided by 2 it is #{div(res, 2)}")
  else
    :error -> IO.puts("We don't have this item in map")
    _ -> IO.puts("It's not odd")
  end
```

এটি আমাদের `case` এর মত প্যাটার্ন ম্যাচিং কার্যপ্রণালী প্রদান করে যা গ্রহণ করে প্রথম সেই ভ্যালু যা ম্যাচড হয়নি।  



