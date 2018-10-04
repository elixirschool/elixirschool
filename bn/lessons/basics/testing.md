---
version: 1.0.1
title: Testing
---

সফটওয়ার ডেভেলপমেন্ট এ টেস্টিং একটি গুঁড়ত্তপূর্ণ ভূমিকা রাখে। এই অধ্যায়ে আমরা দেখব কিভাবে এলিক্সির ল্যাঙ্গুয়েজ এ এক্সইউনিট ব্যবহার করে টেস্ট করা যায় এবং এগুলো করবার কিছু বেস্ট প্র্যাকটিস।

{% include toc.html %}

## ExUnit

এলিক্সির এর বিল্ট ইন একটা টেস্ট ফ্রেমওয়ার্ক আছে এবং এটিতে টেস্ট কোড লিখবার জন্য সবকিছু দিয়ে দেয়া আছে। শুরু করবার আগে বলে নেয়া ভাল যে , টেস্ট কোড ফাইল গুলো এলিক্সির স্ক্রিপ্ট ফাইল আকারে কাজ করে তাই আমাদের `.exs` ফাইল এক্সটেনশন ব্যবহার করতে হবে। এবং টেস্ট কোড চালানোর আগে `test/test_helper.exs` ফাইলে `ExUnit.start()` লিখে এক্সইউনিট শুরু করে দিয়ে আস্তে হবে।

এর আগের অধ্যায়ে যখন আমরা একটি example প্রোজেক্ট তৈরি করেছিলাম তখনি মিক্স আমাদের প্রজেক্টে সাধারণ কিছু টেস্ট কোড তৈরি করে দিয়েছিল। এগুলো আমরা পাবো , `test/example_test.exs` এই খানেঃ

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "the truth" do
    assert 1 + 1 == 2
  end
end
```

এখন আমরা `mix test` চালাতে পারি এবং টেস্ট কোড এর আউটপুট দেখতে পারি।

```shell
Finished in 0.03 seconds (0.02s on load, 0.01s on tests)
1 tests, 0 failures
```

### assert

যদি আপনি এর আগে কখনো টেস্ট কোড লিখে থাকেন তাহলে আপনি `assert` এর সাথে পরিচিত আছেন । অন্যান্য ফ্রেমওয়ার্ক গুলিতে এটিকে লিখে `should` বা `expect` দিয়ে।

`assert` ম্যাক্রো ব্যবহার করে আমরা একটি এক্সপ্রেশন সত্যি কিনা সেটি যাচাই করি। যদি সত্যি না হয় সেক্ষেত্রে একটি এরর তৈরি হয় এবং টেস্ট ফেইল হয়। আসুন আমরা আমাদের টেস্ট টিকে ফেইল করানোর জন্য কিছু জিনিস পরিবর্তন করি এবং `mix test` দিয়ে সেটি চালাই।

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "the truth" do
    assert 1 + 1 == 3
  end
end
```

এখন আমরা আসলে একটু ভিন্ন রকম আউটপুট দেখতে পাবো।
```shell
  1) test the truth (ExampleTest)
     test/example_test.exs:5
     Assertion with == failed
     code: 1 + 1 == 3
     lhs:  2
     rhs:  3
     stacktrace:
       test/example_test.exs:6

......

Finished in 0.03 seconds (0.02s on load, 0.01s on tests)
1 tests, 1 failures
```

এক্সইউনিট আমাদের বলবে আসলে ঠিক কোন জায়গাতে ভুল হয়েছে এবং আসলে কই হবার কথা ছিল এবং কোন ভয়ালু ষে পেয়েছে।
### refute

`refute` হল অনেকটা `unless` এর মতন। আমরা `refute` ব্যাবহার করে কোন স্টেটমেন্ট এর ভুল ফলাফল আশা করতে পারি।

### assert_raise

মাঝে মাঝে এমনটা দরকার হয় যে আসলে আমাদের assert একটি এররে তৈরি করবে। এমনটা দরকার হলে আমরা `assert_raise` ব্যাবহার করতে পারি। আমরা এর একটি উদাহরণ দেখতে পাবো আগামী অধ্যায়ে যা কিনা প্লাগ নিয়ে আলোচনা করেছে।

### assert_receive

এলিক্সির এপ্লিকেশন এ অনেক actors/processes থাকে যা কিনা একে অপরকে মেসেজ আদান প্রদান করে। তো এমন ক্ষেত্রে আমরা চেক করতে পারি যে আসলেই আমাদের মেসেজ পাঠানো হয়েছে কিনা। যেহেতু এলিক্সির এর এক্স ইউনিট আলাদা একটি নিজস্ব প্রসেস এ চলে তাই এটি মেসেজ গ্রহণ করতে পারে আর যে কোন প্রসেস এর মতন আর এটি আমরা চেক করতে পারি , `assert_received` ম্যাক্রো দিয়ে।

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

`assert_received` মেসেজ এর জন্য অপেক্ষা করে না । তবে আমরা `assert_receive` দিয়ে টাইম আউট নির্ধারণ করে দিতে পারি।

### capture_io and capture_log

এপ্লিকেশন এর আউটপুট কয়াপচার করবার জন্য আমরা `ExUnit.CaptureIO` ব্যাবহার করতে পারি এপ্লিকেশন পরিবর্তন না করেই। আমরা শুধু ফাংশন টি দিলেই হবে।

```elixir
defmodule OutputTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "outputs Hello World" do
    assert capture_io(fn -> IO.puts("Hello World") end) == "Hello World\n"
  end
end
```

`ExUnit.CaptureLog` অনেকটা `Logger` মতন করে কাজ করে।

## Test Setup

কিছু ইন্সট্যানস এ এটি আসলেই দরকার হয়ে পরে যে আমরা একটি সেটআপ চালাবো টেস্ট চালানোর আগে। এই কাজটি করবার জন্য আমরা `setup` এবং `setup_all` ম্যাক্রো ব্যবহার করবো। `setup` প্রত্যেক টেস্ট এর আগে চলবে আর `setup_all` চলবে শুধু একবার। ধরে নেয়া হয় এরা একটি tuple `{:ok, state}` রিটার্ন করে। আর এই state আমাদের টেস্ট এ থাকে।

এখানে উদাহরণের জন্য আমরা শুধু `setup_all` ব্যাবহার করেছি।

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  setup_all do
    {:ok, number: 2}
  end

  test "the truth", state do
    assert 1 + 1 == state[:number]
  end
end
```

## Mocking

এলিক্সির এ মকিং কে ব্যাবহার করতে নিষেধ করা হয়। কোন সময় এটি আপণী করতে চাইলেউ এলিক্সির কমুইনিটি মকিং কে না বলে একটি ভাল কারণে।

আরঊ জানবার জন্য আপনি দেখতে পারেন [excellent article](http://blog.plataformatec.com.br/2015/10/mocks-and-explicit-contracts/) । এই গিস্টে আসলে বলা হচ্ছে যে , মকিং বাদ দিয়ে (mock as a *verb*) আমরা আরও ভাল কাজ করবো যদি আমরা ইন্টারফেছ গুলিকে তৈরি করে নেই যেগুলো আমাদের এপ্লিকেশন এর বাইরে আছে এবং মক কে (as a *noun*) ব্যাবহার করি আমাদের ক্লায়েন্ট কোড কে টেস্ট করবার জন্য।

এপ্লিকেশনে কোডের ইমপ্লিমেন্টেশন পরিবর্তন করবার জন্য , উপযুক্ত উপায় হল মডিউল কে আর্গুমেন্ট আকারে পাস করা এবং একটি ডিফল্ট ভ্যলু ব্যবহার করা। যদি এতে কাজ না হয় তো আমরা বিল্ট ইন কনফিগারেশন ব্যাবহার করতে পারি যাতে করে এই মক ইমপ্লিমেন্টেশন গুলো করা যায়। আমাদের কোন আলাদা মকিং লাইব্রেরি এর দরকার নেই । শুধু আচরণ গুলি এবং কলব্যাক গুলি হলেই কাজ হয়ে যাবে।
