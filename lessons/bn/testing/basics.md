---
version: 1.2.0
title: টেস্টিং  
---

সফটওয়ার ডেভেলপ করার একটি গুরুত্বপূর্ণ অংশ হলো টেস্টিং। 
এই অধ্যায়ে আমরা এক্সইউনিট ব্যবহার করে কিভাবে আমাদের এলিক্সির কোড টেস্ট করা যায় এবং এর কিছু বেস্ট প্র্যাকটিস দেখবো।

{% include toc.html %}

## ExUnit

এক্সইউনিট হলো এলিক্সির এর বিল্ট-ইন টেস্ট ফ্রেইমওয়ার্ক, আমাদের কোডকে পুঙ্খানুপুঙ্খভাবে টেস্ট করার জন্যে প্রয়োজনীয় সবকিছুই এতে রয়েছে। 
শুরু করার আগে, আমাদের খেয়াল রাখতে হবে টেস্ট এর জন্যে লেখা কোডগুলো এলিক্সির স্ক্রিপ্ট আকারে সম্পাদনা করা হয়, তাই আমাদের `.exs` ফাইল এক্সটেনশন ব্যবহার করতে হবে।
এবং টেস্ট শুরুর আগে সাধারণত `test/test_helper.exs` নামের একটি ফাইলে `ExUnit.start()` লিখে এক্সইউনিটকে চালু করতে হবে।   

আগের অধ্যায়ে যখন আমরা উদাহরণস্বরূপ একটি প্রজেক্ট তৈরি করেছিলাম তখন, মিক্স আমাদের জন্যে একটি সাধারণ উদাহরণ টেস্ট কোড লিখে দিয়েছিলো, যা আমরা `test/example_test.exs` গিয়ে দেখে নিতে পারিঃ

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :world
  end
end
```

আমাদের প্রজেক্টের টেস্টগুলো রান করার জন্যে আমরা `mix test` ব্যবহার করতে পারি। 
আমরা যদি এটা রান করি তবে, নিচের আউটপুটের মতোই একটি আউটপুট দেখতে পাবোঃ  

```shell
..

Finished in 0.03 seconds
2 tests, 0 failures
```

টেস্ট আউটপুটে দুটি ডট(..) কেন? এর কারণ হলো, মিক্স `test/example_test.exs` এর সাথে সাথে `lib/example.ex` ফাইলেও একটি ডকটেস্ট সংযোজন করেঃ

```elixir
defmodule Example do
  @moduledoc """
  Documentation for Example.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Example.hello
      :world

  """
  def hello do
    :world
  end
end
```

### assert

যদি আপনি এর আগে কখনো টেস্ট কোড লিখে থাকেন তবে হতে পারে আপনি ইতোমধ্যেই `assert` এর সাথে পরিচিত। তাছাড়া কিছু ফ্রেমওয়ার্ক এ `should` বা `expect` এর কাজও অনেকটা একই রকম।

আমরা `assert` ম্যাক্রো ব্যবহার করে, একটি এক্সপ্রেশন সত্য কিনা তা টেস্ট করি। 
যদি সত্য না হয় সেক্ষেত্রে একটি এরর তৈরি হয় এবং টেস্ট ফেইল হয়। 
আসুন উদাহরণের টেস্টটি ফেইল হওয়ার জন্যে আমরা টেস্ট কোডে কিছু পরিবর্তন করে `mix test` রান করিঃ

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :word
  end
end
```

এখন আমরা ভিন্ন রকমের একটা আউটপুট দেখতে পাবোঃ

```shell
  1) test greets the world (ExampleTest)
     test/example_test.exs:5
     Assertion with == failed
     code:  assert Example.hello() == :word
     left:  :world
     right: :word
     stacktrace:
       test/example_test.exs:6 (test)

.

Finished in 0.03 seconds
2 tests, 1 failures
```

এক্সইউনিট আমাদের ঠিক কোন জায়গাতে ভুল হয়েছে, টেস্ট কি ভ্যালু আশা করেছিলো এবং কি ভ্যালু সে আসলেে পেয়েছে তা বলে দিবে।

### refute

`unless` আর `if` যেমন ঠিক তেমনই হলো `refute` আর `assert` .
`refute` ব্যবহার করবেন তখনই, যখন আপনি কোন স্টেটমেন্ট মিথ্যা এটা নিশ্চিত করতে চাইবেন।

### assert_raise

কখনো কখনো কোডে ঠিকমতো এরর তৈরি হচ্ছে কি না সেটা assert করে নিশ্চিত হতে হয়। 
আমরা `assert_raise` ব্যাবহার করে এটা করতে পারি। 
আগামীতে প্লাগের অধ্যায়ে, আমরা এর একটি উদাহরণ দেখতে পাবো। 

### assert_receive

এলিক্সির এপ্লিকেশনে অনেক actors/processes থাকে যারা একে অপরকে মেসেজ আদান প্রদান করে। তো এমন ক্ষেত্রে আপনি মেসেজ ঠিকমতো পাঠানো হচ্ছে কিনা তা টেস্ট করতে চাইবেন। 
যেহেতু এলিক্সির এর এক্সইউনিট একটি নিজস্ব প্রসেস এর মধ্যে চলে তাই এটি অন্য যে কোন প্রসেসের মতই মেসেজ গ্রহণ করতে পারে, আসুন `assert_received` ম্যাক্রো দিয়ে তা টেস্ট করে দেখিঃ 

```elixir
defmodule SendingProcess do
  def run(pid) do
    send(pid, :ping)
  end
end

defmodule TestReceive do
  use ExUnit.Case

  test "receives ping" do
    SendingProcess.run(self())
    assert_received :ping
  end
end
```

`assert_received` মেসেজ এর জন্য অপেক্ষা করেনা, তবে আমরা `assert_receive` এর সাথে একটি টাইম আউট নির্ধারণ করে দিতে পারি।

### capture_io and capture_log

এপ্লিকেশন এর আউটপুট ক্যাপচার করার জন্যে আমরা `ExUnit.CaptureIO` ব্যবহার করতে পারি মূল এপ্লিকেশনে কোন পরিবর্তন না করেই। 
আমরা শুধু আউটপুট দেয়া ফাংশনটি পাস করলেই হবেঃ

```elixir
defmodule OutputTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "outputs Hello World" do
    assert capture_io(fn -> IO.puts("Hello World") end) == "Hello World\n"
  end
end
```

`ExUnit.CaptureLog` যেভাবে কাজ করে তা অনেকটা `Logger` এ আউটপুট ক্যাপচার করার মত।

## Test Setup

কিছু কিছু ক্ষেত্রে, টেস্ট করার আগে কিছু সেটআপ করে নিতে হয়। 
এটা করার জন্য আমরা `setup` এবং `setup_all` ম্যাক্রো ব্যবহার করতে পারি। 
প্রত্যেক টেস্ট রান করার আগে `setup` রান হবে আর স্যুটের শুরুতে `setup_all` রান হবে শুধু একবার। 
সাধারণত এরা `{:ok, state}` এর একটি টুপল রিটার্ন করে। আর, এই স্টেট আমাদের টেস্ট থেকে এক্সেস করা যাবে।

এই উদাহরণের জন্য আমরা `setup_all` ব্যাবহার করার জন্যেে আমাদের কোডে পরিবর্তন করবোঃ

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  setup_all do
    {:ok, recipient: :world}
  end

  test "greets", state do
    assert Example.hello() == state[:recipient]
  end
end
```

## Mocking

এলিক্সির এ মকিং করবো কি না এর সাধারণ উত্তর হলোঃ করবেন না।  
আপনি হয়তো আপনার সহজাত প্রেরণা থেকে মকিং করতে চাইতে পারেন, কিন্তু এলিক্সির কমিউনিটি মকিং করা থেকে সবাইকে নিরুৎসাহিত করতে আপ্রাণ চেষ্টা করে, এবং এটা তারা যুক্তিসংগত কারণেই করে থাকে। 

এ বিষয়ে বিস্তারিত জানতে এই [অসাধারণ আর্টিকেলটি](http://blog.plataformatec.com.br/2015/10/mocks-and-explicit-contracts/) পড়ে ফেলুুুন। 
সারমর্ম হলো, টেস্টিং এর জন্যে ডিপেন্ডেন্সীগুলো মক(এখানে মক হলো *ক্রিয়াপদ*) না করে, এপ্লিকেশনের বাইরের কোডগুলোর জন্যে আলাদা ইন্টারফেস(বিহেবিওরস) তৈরি করার মাধ্যমে আপনার টেস্টিং এর জন্যে লেখা ক্লায়েন্ট কোডে মক (মক হলো বিশেষ্য) ব্যবহারে অনেক বেশী সুবিধা লাভ করা যায়।

এপ্লিকেশনে কোডের ইমপ্লিমেন্টেশন সুইচ করার জন্য অন্যতম উপায় হলো, মডিউল কে আর্গুমেন্ট আকারে পাস করা এবং একটি ডিফল্ট ভ্যলু ব্যবহার করা। 
যদি এতে কাজ না হয় তো আমরা বিল্ট ইন কনফিগারেশন ব্যাবহার করতে পারি। 
আমাদের কোন স্পেশাল মকিং লাইব্রেরির দরকার নাই। দরকার শুধু বিহেবিওরস আর কলব্যাক এর।
