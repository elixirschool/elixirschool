%{
  version: "1.1.1",
  title: "কনকারেন্সী",
  excerpt: """
  এলিক্সিরের কনকারেন্সী সাপোর্ট এর অন্যতম আকর্ষণ। 
  এরল্যাং এর ভি এম (BEAM) কারণে, এলিক্সিরে কনকারেন্সী আরও সহজতর হয়েছে।   
  কঙ্কারেন্সী মডেল এক্টরস এর উপর ভরসা করে, যা একটি কন্টেইন্ড প্রসেস। এটা অন্যান্য প্রসেস এর সাথে কমিউনিকেট করে মেসেজ পাসিং এর মাধ্যমে। 

  এই অধ্যায়ে, আমরা এলিক্সিরের বিল্ট ইন কনকারেন্সী মডিউল গুলো দেখবো। 
  এর পরের অধ্যায়ে, আমরা ওটিপি এবং বিহেভিওর সম্পর্কে জানবো যা এটা ইমপ্লিমেন্ট করে। 
  """
}
---

## প্রসেস

এরল্যাং ভি এম এর প্রসেস গুলো অনেক হালকা এবং সব সিপিউতেই রান হয়। 
যদিও তারা দেখতে অনেকটা ন্যাটিভ থ্রেডস এর মতো, তবে তারা আরও সরল এছাড়া একটি এলিক্সির এপ্লিকেশনে হাজার হাজার কনকারেন্ট প্রসেস থাকাটা অলীক নয়।

`spawn` ব্যবহার করে খুব সহজেই নতুন প্রসেস তৈরি করা যায়, যা একটা এননিমাস অথবা নেমড ফাংশন নেয়। 
যখন আমরা একটা নতুন প্রসেস তৈরি করি তখন এটা একটা _প্রসেস আইডেন্টিফায়ার_ রিটার্ন করে, সংক্ষেপে PID, যা দিয়ে প্রসেসটিকে আমাদের এপ্লিকেশনের মধ্যে চিহ্নিত করা যায়।

শুরু করার জন্যে, আমরা একটা মডিউল এবং ফাংশন তৈরি করবো রান করার জন্যেঃ

```elixir
defmodule Example do
  def add(a, b) do
    IO.puts(a + b)
  end
end

iex> Example.add(2, 3)
5
:ok
```

ফাংশনটি এসিনক্রোনাস ভাবে রান করার জন্যে আমরা ব্যবহার করবো `spawn/3`:

```elixir
iex> spawn(Example, :add, [2, 3])
5
#PID<0.80.0>
```

### মেসেজ পাসিং

প্রসেস গুলো নিজেদের মধ্যে কথা বলার জন্যে, মেসেজ পাসিং ব্যবহার করে থাকে। 
মূলতঃ দুইটা কম্পোনেন্ট এর সাহায্যেঃ `send/2` এবং `receive`
`send/2` ফাংশনের সাহায্যে আমরা PID ব্যবহার করে মেসেজ পাঠাতে পারি। 
মেসেজ পেতে আমরা, `receive` ফাংশন ব্যবহার করি যাতে মেসেজ ম্যাচ করা যায়। 
কোনো মিল না পাওয়া গেলে এক্সিকিউশন বন্ধ না হয়ে বরং চলতেই থাকে, অবিরত।  

```elixir
defmodule Example do
  def listen do
    receive do
      {:ok, "hello"} -> IO.puts("World")
    end

    listen()
  end
end

iex> pid = spawn(Example, :listen, [])
#PID<0.108.0>

iex> send pid, {:ok, "hello"}
World
{:ok, "hello"}

iex> send pid, :ok
:ok
```

আপনি হয়তো লক্ষ্য করেছেন, `listen/0` ফাংশনটি রিকারসিভ। এই কারণে প্রসেস গুলো অনেকগুলো মেসেজ হ্যান্ডল করতে সমর্থ হয়। 
রিকারশন ছাড়া, আমাদের প্রসেস প্রথম মেসেজ পাওয়ার পরেই শেষ হয়ে যেতো। 

### প্রসেস লিঙ্কিং 

`spawn` এর একটি সমস্যা হলো প্রসেস ক্র্যাশ করলে তা জানা যায় না।
এটা জানতে আমাদের `spawn_link` এর সাহায্যে প্রসেসকে লিংক করতে হবে।
দুইটি লিংকড প্রসেস একে অপরের এক্সিট নোটিফিকেশন পেয়ে থাকেঃ

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)
end

iex> spawn(Example, :explode, [])
#PID<0.66.0>

iex> spawn_link(Example, :explode, [])
** (EXIT from #PID<0.57.0>) evaluator process exited with reason: :kaboom
```

কখনো কখনো আমরা চাই না, আমাদের বর্তমান প্রসেস কোনো লিঙ্কড প্রসেসের কারণে ক্র্যাশ করুক।
এ জন্যে আমাদের `Process.flag/2` ব্যবহার করে এক্সিটকে আটকাতে হবে। 
এটা এরল্যাং এর [process_flag/2](http://erlang.org/doc/man/erlang.html#process_flag-2) ফাংশনটি ব্যবহার করে `trap_exit` ফ্ল্যাগটি পাওয়ার জন্যে। যখন এই ফ্ল্যাগটি পাওয়া যায় (`trap_exit` যখন `true` হয়), তখন টাপল মেসেজ আকারে এক্সিট সিগন্যাল পাওয়া যায়ঃ `{:EXIT, from_pid, reason}`। 

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)

  def run do
    Process.flag(:trap_exit, true)
    spawn_link(Example, :explode, [])

    receive do
      {:EXIT, _from_pid, reason} -> IO.puts("Exit reason: #{reason}")
    end
  end
end

iex> Example.run
Exit reason: kaboom
:ok
```

### প্রসেস মনিটরিং

কেমন হয় যদি, আমরা দুটি প্রসেস লিংক না করেই মেসেজ আদান প্রদান করতে চাই? এটা করতে আমরা `spawn_monitor` ব্যবহার করতে পারি।
যখন আমরা প্রসেসকে মনিটর করি তখন আমরা প্রসেস ক্র্যাশ করলেই মেসেজ পেতে পারি বর্তমান প্রসেস ক্র্যাশ না করে কিংবা ট্র্যাপ এক্সিট ব্যবহার না করে।

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)

  def run do
    spawn_monitor(Example, :explode, [])

    receive do
      {:DOWN, _ref, :process, _from_pid, reason} -> IO.puts("Exit reason: #{reason}")
    end
  end
end

iex> Example.run
Exit reason: kaboom
:ok
```

## এজেন্টস 

এজেন্টস ব্যাকগ্রাউন্ড প্রসেস এর স্টেট মেইন্টেইন করার জন্যে একধরণের এবস্ট্র্যাকশন। 
আমাদের এপ্লিকেশন এবং নোডের মধ্যে থাকা প্রসেস থেকেই আমরা তাদেরকে এক্সেস করতে পারি।
এজেন্ট এর স্টেট ফাংশনের রিটার্ন ভ্যালু দ্বারা নির্ধারিত হয়ঃ

```elixir
iex> {:ok, agent} = Agent.start_link(fn -> [1, 2, 3] end)
{:ok, #PID<0.65.0>}

iex> Agent.update(agent, fn (state) -> state ++ [4, 5] end)
:ok

iex> Agent.get(agent, &(&1))
[1, 2, 3, 4, 5]
```

PID ব্যবহার না করেও,শুধুমাত্র এজেন্টের নাম ব্যবহার করেও কোনো এজেন্টকে এক্সেস করা যায়ঃ 

```elixir
iex> Agent.start_link(fn -> [1, 2, 3] end, name: Numbers)
{:ok, #PID<0.74.0>}

iex> Agent.get(Numbers, &(&1))
[1, 2, 3]
```

## টাস্কস 

টাস্কস হলো ফাংশনকে ব্যাকগ্রাউন্ডে রান করে পরবর্তীতে এর রিটার্ন ভ্যালু পাওয়ার একটি পন্থা।
এপ্লিকেশন এর এক্সিকিউশন ব্লক না করেই ব্যয়বহুল অপারেশন করতে টাস্কস এর ব্যবহার অতুলনীয়।

```elixir
defmodule Example do
  def double(x) do
    :timer.sleep(2000)
    x * 2
  end
end

iex> task = Task.async(Example, :double, [2000])
%Task{
  owner: #PID<0.105.0>,
  pid: #PID<0.114.0>,
  ref: #Reference<0.2418076177.4129030147.64217>
}

# Do some work

iex> Task.await(task)
4000
```
