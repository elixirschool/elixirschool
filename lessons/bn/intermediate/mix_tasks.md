%{
  version: "1.2.1",
  title: "কাস্টম মিক্স টাস্ক",
  excerpt: """
  এলিক্সির প্রোজেক্টে মিক্স দিয়ে নিজস্ব টাস্ক তৈরি করা।
  """
}
---

## সূচনা  

নিজস্ব কাস্টম মিক্স টাস্ক দিয়ে এলিক্সির এপ্লিকেশন এর ফাংশনালিটি বাড়ানো বেশ জনপ্রিয়। 
এই অধ্যায়ে আমরা কিভাবে আমাদের প্রয়োজন অনুযায়ী মিক্স টাস্ক তৈরি করতে হয় তা জানবো তার আগে, প্রচলিত কিছু মিক্স টাস্কের উদাহরণ দেখা যাকঃ 

```shell
$ mix phx.new my_phoenix_app

* creating my_phoenix_app/config/config.exs
* creating my_phoenix_app/config/dev.exs
* creating my_phoenix_app/config/prod.exs
* creating my_phoenix_app/config/prod.secret.exs
* creating my_phoenix_app/config/test.exs
* creating my_phoenix_app/lib/my_phoenix_app.ex
* creating my_phoenix_app/lib/my_phoenix_app/endpoint.ex
* creating my_phoenix_app/test/views/error_view_test.exs
...
```

উপরের শেল কমান্ড থেকে আমরা দেখতে পাচ্ছি যে, ফিনিক্স ফ্রেইমওয়ার্ক কাস্টম মিক্স টাস্ক দিয়ে প্রজেক্ট তৈরির কাজটি করে থাকে। 
আমরা যদি আমাদের প্রোজেক্টের জন্য এমন কিছু করি তাহলে কেমন হয়? এলিক্সির মিক্স ট্যাস্ক দিয়ে এ ধরনের কাজ করতে দেয় খুব সহজেই। 

## সেটআপ 

চলুন, একটি খুব ছোট মিক্স অ্যাপ্লিকেশান তৈরি করি।
 
```shell
$ mix new hello

* creating README.md
* creating .formatter.exs
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/hello.ex
* creating test
* creating test/test_helper.exs
* creating test/hello_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

cd hello
mix test

Run "mix help" for more commands.
```

এখন, উপরিউক্ত কমান্ড থেকে সদ্য তৈরি করা **lib/hello.ex** ফাইলের মডিউলে একটি ফাংশন তৈরি করি যা "Hello, World!" আউটপুট দিবে 

```elixir
defmodule Hello do
  @doc """
  Output's `Hello, World!` everytime.
  """
  def say do
    IO.puts("Hello, World!")
  end
end
```

## কাস্টম মিক্স টাস্ক বর্ণনা 

এবার আমাদের কাস্টম মিক্স টাস্ক তৈরি করি। 
একটি নতুন ডিরেক্টরি ও ফাইল তৈরি করি **hello/lib/mix/tasks/hello.ex** 
ঐ ফাইলটিতে, নিচের ৭ লাইনের এলিক্সির কোডটি লিখি। 

```elixir
defmodule Mix.Tasks.Hello do
  @moduledoc "The hello mix task: `mix help hello`"
  use Mix.Task

  @shortdoc "Simply calls the Hello.say/0 function."
  def run(_) do
    # calling our Hello.say() function from earlier
    Hello.say()
  end
end
```

লক্ষ্য করি, আমরা কিন্তু `defmodule` স্টেটমেন্ট এর শুরুতেই `Mix.Tasks` এবং যে নামটি কমান্ডলাইনে ব্যবহার করতে চাই তা লিখেছি। 
২য় লাইনে, `use Mix.Task` এর মাধ্যমে `Mix.Task` বিহেভিয়রকে আমাদের নেইমস্পেইসে আনা হয়। 
এর পরে, আমরা `run` ফাংশনটি বানাই যা (আপাতত) কোন আর্গুমেন্ট নেয় না। 
এই ফাংশনের ভেতরে আমরা `Hello` মডিউল এবং `say` ফাংশন ব্যবহার করেছি। 

## এপ্লিকেশন লোড করা 

মিক্স অটোমেটিকালি এপ্লিকেশন স্টার্ট বা এর ডিপেন্ডেন্সীগুলো লোড করে না যা বেশীরভাগ মিক্স টাস্কের ব্যবহার এ প্রভাব ফেলে না। কিন্তু কেমন হবে যদি আমরা এক্টো ব্যবহার করে ডাটাবেস এর সাথে ইন্টারেক্ট করতে চাই? সেক্ষেত্রে, আমাদের খেয়াল রাখতে হবে Ecto.Repo যে এপ এ আছে তা চালু হয়েছে। আমরা দুইভাবে এটা মোকাবেলা করতে পারিঃ নির্দিষ্ট ভাবে কোনো এপ স্টার্ট করে অথবা আমাদের এপ্লিকেশন স্টার্ট করে যেটা বাকি সব এপগুলোকে চালু করবে।  

চলুন, আমাদের এপ্লিকেশন এবং এর ডিপেন্ডেন্সীগুলো চালু করার জন্যে, কিভাবে আমরা মিক্স টাস্ককে আপডেট করতে পারি তা দেখিঃ 

```elixir
defmodule Mix.Tasks.Hello do
  @moduledoc "The hello mix task: `mix help hello`"
  use Mix.Task

  @shortdoc "Simply calls the Hello.say/0 function."
  def run(_) do
    # This will start our application
    Mix.Task.run("app.start")

    Hello.say()
  end
end
```

## মিক্স টাস্ক রান করা 

এবার আমাদের মিক্স টাস্কটি রান করা যাক। 
আমরা প্রোজেক্ট ডিরেক্টরি থেকে এই কমান্ডটি রান করতে পারি। 
কমান্ড লাইন থেকে `mix hello` রান করলে নিচের মতো আউটপুট দেখতে পাবো-  

```shell
$ mix hello
Hello, World!
```

মিক্স কিন্তু বেশ বন্ধুসুলভ! 
মানুষ মাত্রই ভুল এটা সে জানে, কাজেই যদি কখনো বানান ভুল করেন আপনার কমান্ডটি লিখার সময় তাহলে ফাজি স্ট্রিং ম্যাচিংয়ের মাধ্যমে আপনাকে মিক্স রিকমেন্ড করবে যেমন- 

```shell
$ mix hell
** (Mix) The task "hell" could not be found. Did you mean "hello"?
```

আপনি কি খেয়াল করেছেন, আমরা আমাদের টাস্ক মডিউলে  `@shortdoc` নামক একটি নতুন অ্যাট্রিবিউট দেখেছি? যখন আমরা আমাদের এপ্লিকেশন শিপ করবো তখন এটা কাজে লাগবে, যখন ইউজার টার্মিনাল থেকে `mix help` রান করবে তখন এর উত্তরে দিবে। 

```shell
$ mix help

mix app.start         # Starts all registered apps
...
mix hello             # Simply calls the Hello.say/0 function.
...
```

নোটঃ নতুন টাস্ক `mix help` এর আউটপুটে আসার জন্যে, আমাদের কোডকে অবশ্যই কম্পাইলড হতে হবে।
আমরা এটা `mix compile` কমান্ড রান করে করতে পারি অথবা টাস্ক রান করেও করতে পারি অর্থাৎ `mix hello` রান করে, যেটা আমাদের জন্যে কম্পাইলেশন ট্রিগার করবে। 

