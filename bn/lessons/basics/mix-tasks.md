---
version: 1.0.1
title: মিক্স টাস্ক 
---

মিক্স দিয়ে নিজস্ব টাস্ক তৈরি করা হবে এই অধ্যায়ের মূল বিষয়। 

{% include toc.html %}

## সূচনা  

প্রচলিত কিছু মিক্স টাস্কের উদাহরণ দেখা যাক- 

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

উপরের শেল কমান্ড থেকে আমরা দেখতে পাচ্ছি যে, ফিনিক্স ফ্রেইমওয়ার্ক কাস্টম মিক্স টাস্ক দিয়ে প্রজেক্ট সৃষ্টির কাজটি করে থাকে। আমরা যদি আমাদের প্রোজেক্টের জন্য এমন কিছু করই তাহলে কেমন হয়? এলিক্সির মিক্স ট্যাস্ক দিয়ে এ ধরনের কাজ করতে দেয় খুব সহজেই। 

## সেটআপ 

একটি খুব ছোট মিক্স অ্যাপ্লিকেশান তৈরি করি।
 
```shell
$ mix new hello

* creating README.md
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

উপরিউক্ত কমান্ড থেকে সদ্য তৈরি করা **lib/hello.ex** ফাইলের মডিউলে একটি ফাংশন তৈরি করি যা  "Hello, World!" আউটপুট দিবে- 

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

এবার আমাদের কাস্টম মিক্স টাস্ক তৈরি করি। **`mix/tasks`** নামক একটি নতুন ডিরেক্টরি তৈরি করি ও এতে **hello.ex** নামের একটি ফাইল বানাই (**hello/lib/mix/tasks/hello.ex** হয়ে যাবে ফাইলের অন্তিম লোকেশান)। ফাইলটিতে নিম্নক্ত লাইনগুলি লিখি। 

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Simply runs the Hello.say/0 command."
  def run(_) do
    # calling our Hello.say() function from earlier
    Hello.say()
  end
end
```

আমরা কিন্তু `defmodule` স্টেটমেন্ট এ `Mix.Tasks` অ্যাড করেছি মডিউল নামের পূর্বে। আর মডিউলের মূল নাম হল যে নামে আমরা কমান্ড লাইনে আমাদের টাস্ককে ডাকতে চাই সেটি। এবার লক্ষ্য করি `use Mix.Task` এর দিকে- এর মাধ্যমে `Mix.Task` বিহেভিয়রকে আমাদের নেইমস্পেইসে আনা হয়। অবশেষে আমরা `run` ফাংশনটি বানাই যা (আপাতত) কোন আর্গুমেন্ট নেয় না। এই ফাংশনের ভেতরে আমরা `Hello.say/0` ব্যবহার করেছি। 

## মিক্স টাস্ক রান করা 

এবার আমাদের মিক্স টাস্কটি রান করা যাক। মিক্সে প্রোজেক্টের টপ লেভেল ডিরেক্টরিতে থাকলে এই কমান্ডটি রান করবে। কাজেই, কমান্ড লাইন থেকে `mix hello` রান করে পাই-  

```shell
$ mix hello
Hello, World!
```

মিক্স কিন্তু আবার বেশ স্মার্ট। যদি কখনো বানান ভুল করেন আপনার কমান্ডটি লিখার সময় তাহলে ফাজি স্ট্রিং ম্যাচিংয়ের মাধ্যমে আপনাকে মিক্স রিকমেন্ড করবে যেমন- 

```shell
$ mix hell
** (Mix) The task "hell" could not be found. Did you mean "hello"?
```

`@shortdoc` নামক একটি নতুন অ্যাট্রিবিউট দেখেছি আমরা আমাদের টাস্ক মডিউলে। এর কাজ হল সেই মেসেজকে বলে দেওয়া যা আমাদের কমান্ড `mix help` এর উত্তরে দিবে। 

```shell
$ mix help

mix app.start         # Starts all registered apps
...
mix hello             # Simply calls the Hello.say/0 function.
...
```
