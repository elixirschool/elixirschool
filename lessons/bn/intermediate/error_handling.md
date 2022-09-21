%{
  version: "1.1.0",
  title: "এরর হ্যান্ডলিং",
  excerpt: """
  যদিও `{:error, reason}` টাপলটি রিটার্ন করাই বেশী জনপ্রিয়, তবে, এলিক্সির এক্সেপশন সাপোর্ট করে। এই অধ্যায়ে, আমরা দেখবো কিভাবে এরর হ্যান্ডল করা যায় এবং এর জন্যে তৈরি বিভিন্ন মেকানিজম গুলো।
  
  সাধারণত, এলিক্সিরে রীতি হলো একটা ফাংশন তৈরি করা (`example/1`) যেটা `{:ok, result}` এবং `{:error, reason}` রিটার্ন করে এবং আরেকটা আলাদা ফাংশন (`example!/1`) যেটা সরাসরি `result` অথবা এরর দেখায়।
  
এই অধ্যায়ে, আমরা পরেরটা আলোচনা করবো।
  """
}
---

## সাধারণ রীতি

এই মুহূর্তে, এলিক্সির কমিউনিটি এরর রিটার্ন করার কিছু সাধারণ রীতি মেনে চলেঃ

* যে এরর গুলো ফাংশনের রেগুলার অপারেশন এর অংশ (যেমনঃ ইউজার ভুল টাইপের ডেট এন্ট্রি করলো), সে ফাংশনগুলো প্রয়োজনমতো `{:ok, result}` এবং `{:error, reason}` রিটার্ন করে।
* যে এরর গুলো নরমাল অপারেশন এর অংশ নয় (যেমনঃ কনফিগারেশন ডেটা পার্স করতে না পারা)। সে ক্ষেত্রে এক্সেপশন ছুড়ে দেয়া।

আমরা সাধারণত, স্ট্যান্ডার্ড এরর ফলো হ্যান্ডল করি [প্যাটার্ন ম্যাচিং](/bn/lessons/basics/pattern_matching) ব্যবহার করে, কিন্তু এই অধ্যায়ে, আমরা দ্বিতীয় কেইসে ফোকাস করবো অর্থাৎ এক্সেপশনে খেয়াল করবো।

অনেক সময়, পাবলিক এপিআইগুলোতে, আপনি দ্বিতীয় আরেকটি ভার্সনের ফাংশন পেতে পারেন ! চিহ্ন সমেত (example!/1) যেটা সরাসরি রেসাল্ট রিটার্ন করে অথবা এরর ছুড়ে দেয়।

## এরর হ্যান্ডলিং

আমাদের এরর হ্যান্ডল করার আগে, এরর তৈরি করতে পারতে হবে,এর জন্যে সবচেয়ে সহজ উপায় হলোঃ `raise/1`

```elixir
iex> raise "Oh no!"
** (RuntimeError) Oh no!
```

যদি আমরা টাইপ এবং মেসেজ বলে দিতে চাই, তবে, আমাদের `raise/2` ব্যবহার করতে হবেঃ

```elixir
iex> raise ArgumentError, message: "the argument value is invalid"
** (ArgumentError) the argument value is invalid
```

যখন আমরা জানি যে এরর হতে পারে, তখন আমরা সে এরর কে হ্যান্ডল করতে `try/rescue` এবং প্যাটার্ন ম্যাচিং ব্যবহার করতে পারিঃ

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> end
An error occurred: Oh no!
:ok
```

একটি সিঙ্গেল রেস্কিউ দিয়ে অনেকগুলো এরর কে ম্যাচ করাও সম্ভবঃ

```elixir
try do
  opts
  |> Keyword.fetch!(:source_file)
  |> File.read!()
rescue
  e in KeyError -> IO.puts("missing :source_file option")
  e in File.Error -> IO.puts("unable to read source file")
end
```

## আফটার

অনেক সময়, `try/rescue` ব্যবহার এর সময় এরর হউক বা না হউক, আমাদের কিছু একশান নেয়ার প্রয়োজন হতে পারে।
সে জন্যে আছে `try/after`।
যদি আপনি রুবি এর সাথে পরিচিত থাকেন, তবে, এটা অনেকটাই `begin/rescue/ensure` এর মতো অথবা জাভা এর `try/catch/finally` এর মতোঃ

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> after
...>   IO.puts "The end!"
...> end
An error occurred: Oh no!
The end!
:ok
```

এটা সাধারণত ফাইলস অথবা কানেকশনের সাথে ব্যবহার করা হয় যেগুলো ক্লোজ করতে হয়ঃ

```elixir
{:ok, file} = File.open("example.json")

try do
  # Do hazardous work
after
  File.close(file)
end
```

## নিউ এররস

যদিও এলিক্সির বিল্ট ইন অনেক টাইপের এরর প্রদান করে যেমন `RuntimeError`, আমাদের যদি প্রয়োজন হয় তবে আমরা চাইলে আমাদের নিজেদের এরর টাইপও তৈরি করতে পারি।
`defexception/1` ম্যাক্রো ব্যবহার করে নিউ বা নতুন এরর তৈরি করা একদমই সহজ, যেটা আমাদের সুবিধার জন্যে `:message` অপশনটি একসেপ্ট করে যার সাহায্যে ডিফল্ট এরর মেসেজ সেট করা যায়ঃ

```elixir
defmodule ExampleError do
  defexception message: "an example error has occurred"
end
```

চলুন, আমাদের নতুন এররটি প্রয়োগ করে দেখা যাকঃ

```elixir
iex> try do
...>   raise ExampleError
...> rescue
...>   e in ExampleError -> e
...> end
%ExampleError{message: "an example error has occurred"}
```

## থ্রোস

এছাড়াও, এলিক্সিরে এরর নিয়ে কাজ করার অন্য আরেকটা উপায় হলো `throw` এবং `catch`।
ব্যবহারিক ক্ষেত্রে, এর ব্যবহার অপ্রতুল এবং নতুন এলিক্সির কোডে এর কদাচিৎ ব্যবহার হয়ে থাকে, তবে যাই হোক, এদের জানা এবং বুঝা আবশ্যক।

`throw/1` ফাংশনটি আমাদের এক্সিকিউশন থেকে বেরিয়ে যাওয়ার উপায় বাতলে দেয় এর সাথে সাথে আমরা একটি নির্দিষ্ট ভ্যালু `catch` করে ব্যবহারও করতে পারিঃ

```elixir
iex> try do
...>   for x <- 0..10 do
...>     if x == 5, do: throw(x)
...>     IO.puts(x)
...>   end
...> catch
...>   x -> "Caught: #{x}"
...> end
0
1
2
3
4
"Caught: 5"
```

আগেই উল্লেখ করা হয়েছে, সাধারণত লাইব্রেরী যদি পর্যাপ্ত এপিআই দিতে ব্যর্থ হয় সে সমস্ত ক্ষেত্রবিশেষ ছাড়া `throw/catch` খুবই কমই ব্যবহৃত হয়ে থাকে।

## এক্সিটিং

`exit` হলো এলিক্সিরের প্রদত্ত সর্বশেষ এরর মেকানিজম।
প্রসেসের মৃত্যুতে এক্সিট সিগনাল এর উৎপত্তি হয়ে থাকে, এটি এলিক্সিরের ফল্ট টলারেন্স এর অন্যতম অংশ হিসেবে বিবেচিত।

`exit/1` ব্যবহার করে আমরা আমাদের ইচ্ছানুযায়ী এক্সিট করতে পারিঃ

```elixir
iex> spawn_link fn -> exit("oh no") end
** (EXIT from #PID<0.101.0>) evaluator process exited with reason: "oh no"
```

যদিও `try/catch` ব্যবহার করে এক্সিট কে ক্যাচ করা যায়, তবে এরূপ ব্যবহার _অত্যধিক_ অপ্রতুল।
প্রায় সব ক্ষেত্রেই, সুপারভাইজারকে এক্সিট প্রসেস করতে দেয়ায় বুদ্ধিমানের কাজঃ

```elixir
iex> try do
...>   exit "oh no!"
...> catch
...>   :exit, _ -> "exit blocked"
...> end
"exit blocked"
```
