%{
  version: "1.0.3",
  title: "মেটাপ্রোগ্রামিং",
  excerpt: """
  মেটাপ্রোগ্রামিং হলো কোড ব্যবহার করে কোড লেখার একটি প্রক্রিয়া।
  এলিক্সির এ, এটা আমাদের প্রয়োজনানুযায়ী ল্যাংগুয়েজ এর বর্ধন এবং ডাইনামিকভাবে কোড এর পরিবর্তনের সুবিধাদি দিয়ে থাকে।
  শুরুতে আমরা, এলিক্সির এর অভ্যন্তরীণ প্রতিরূপ, তারপর কিভাবে এটাকে পরিবর্তন করা যায়,এবং সব শেষে কিভাবে আমরা এ সবকিছু পরিবর্ধনে কাজে লাগানো যায় তা দেখবো।
  
  সতর্কতা: মেটাপ্রোগ্রামিং খুবই জটিল এবং এটা শুধুমাত্র যখন প্রয়োজন তখনই ব্যবহার করা উচিত।
  এর অতিরিক্ত ব্যবহার প্রায় প্রতি ক্ষেত্রেই, জটিল কোড এর সৃষ্টি করে যেটা বুঝা ও ডিবাগ করা অনেক কঠিন।
  """
}
---

## কো'ট (Quote)

মেটাপ্রোগ্রামিং এর প্রথম ধাপই হলো, কিভাবে এক্সপ্রেশান লেখা হয় তা বুঝতে শেখা।
এলিক্সিরে, এবস্ট্র্যাক্ট সিনট্যাক্স ট্রি (AST) বা কোড এর অভ্যন্তরীণ প্রতিরূপ, টাপলের সাহায্যে প্রণীত।
টাপলগুলোর তিনটি অংশ: ফাংশনের নাম, মেটাডাটা, এবং ফাংশনের আর্গুমেন্ট।

এই অভ্যন্তরীণ কাঠামোগুলো দেখার জন্যে, এলিক্সির এ `quote/2` নামের একটি ফাংশন রয়েছে।
`quote/2` ফাংশনটি ব্যবহার করে আমরা এলিক্সির কোডকে এর অভ্যন্তরীণ প্রতিরূপে রূপান্তর করতে পারি:

```elixir
iex> quote do: 42
42
iex> quote do: "Hello"
"Hello"
iex> quote do: :world
:world
iex> quote do: 1 + 2
{:+, [context: Elixir, import: Kernel], [1, 2]}
iex> quote do: if value, do: "True", else: "False"
{:if, [context: Elixir, import: Kernel],
 [{:value, [], Elixir}, [do: "True", else: "False"]]}
```

লক্ষ্য করেছেন কি, প্রথম তিনটি কোন টাপল রিটার্ন করেনি? সর্বমোট পাঁচটি লিটারেল আছে যেগুলো যখন কো'ট করা হয় তখন টাপল রিটার্ন করে না:

```elixir
iex> :atom
:atom
iex> "string"
"string"
iex> 1 # All numbers
1
iex> [1, 2] # Lists
[1, 2]
iex> {"hello", :world} # 2 element tuples
{"hello", :world}
```

## আনকো'ট(Unquote)

আমরা কিভাবে কোড এর অভ্যন্তরীণ কাঠামো পেতে হয় তা শিখলাম, কিন্তু আমরা কিভাবে এটাকে পরিবর্তন করতে পারি? নতুন কোন ভ্যালু অথবা নতুন কোড যোগ করতে আমরা `unquote/1` ব্যবহার করি।
যখন আমরা কোনো এক্সপ্রেশানকে আনকো'ট করি, তখন এটা মূল্যায়ন করে তবেই AST তে ঢুকানো হয়।
`unquote/1` এর ব্যবহার দেখতে, চলুন কিছু উদাহরণ দেখা যাক:

```elixir
iex> denominator = 2
2
iex> quote do: divide(42, denominator)
{:divide, [], [42, {:denominator, [], Elixir}]}
iex> quote do: divide(42, unquote(denominator))
{:divide, [], [42, 2]}
```

প্রথম উদাহরণে, আমাদের ভ্যারিয়েবল `denominator` কো'ট করা ছিলো, তাই আমাদের AST তে এই ভ্যারিয়েবলকে পেতে একটা টাপল রয়েছে।
`unquote/1` উদাহরণে পাওয়া কোডটিতে টাপল এর পরিবর্তে `denominator` এর ভ্যালু পেয়েছি।

## ম্যাক্রো

যদি আমরা `quote/2` এবং `unquote/1` বুঝতে সক্ষম হয়, তাহলে আমরা এবার ম্যাক্রো শেখার জন্যে প্রস্তুত।
আমাদের মনে রাখতে হবে, ম্যাক্রো মেটাপ্রোগ্রামিং এর ন্যায় কদাচিৎ অর্থাৎ খুব কমই ব্যবহার করা উচিত।

সহজ ভাষায়, ম্যাক্রো হলো স্পেশাল ফাংশন যেগুলো ডিজাইন করা হয়েছে কো'ট করা এক্সপ্রেশান রিটার্ন করার জন্যে, যেগুলো আমরা এপ্লিকেশন কোডে যোগ করবো।
ম্যাক্রোকে ফাংশন কলের মতো না ভেবে এর পরিবর্তে কো'ট করা এক্সপ্রেশান চিন্তা করা যেতে পারে।
ম্যাক্রোর সাথে সাথে আমাদের এলিক্সির এর পরিবর্ধনের জন্যে এবং ডাইনামিকভাবে এপ্লিকেশানে কোড যোগ করার জন্যে যা যা প্রয়োজনীয় তার সবই পাওয়া হলো।

আমরা `defmacro/2` দিয়ে ম্যাক্রো তৈরি করা শুরু করি, যা এলিক্সিরের অন্যান্য অংশের মতোই, নিজেও একটি ম্যাক্রো (এটা মাথায় রাখুন)।
উদাহরণস্বরূপ, আমরা `unless` ইমপ্লিমেন্ট করবো ম্যাক্রো আকারে।
মনে রাখতে হবে, আমাদের ম্যাক্রোকে অবশ্যই কো'ট করা এক্সপ্রেশান রিটার্ন করতে হবে:

```elixir
defmodule OurMacro do
  defmacro unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end
```

চলুন, আমাদের মডিউলকে রিকয়ার করি এবং তৈরি করা ম্যাক্রোটাকে কাজে লাগাই:

```elixir
iex> require OurMacro
nil
iex> OurMacro.unless true, do: "Hi"
nil
iex> OurMacro.unless false, do: "Hi"
"Hi"
```

যেহেতু, ম্যাক্রো আমাদের এপ্লিকেশানে কোড এর পরিবর্তে বসে, কখন এবং কি কম্পাইল হবে তা আমরা নিয়ন্ত্রণ করতে পারি।
`Logger` মডিউলে এর একটি উদাহরণ পেতে পারি।
যদি লগিং বন্ধ করা থাকে, তখন এপ্লিকেশানে কোনো কোড যোগ করা হয় না ফলে এপ্লিকেশানে লগিং এর কোনো ফাংশন কল বা চিহ্ন থাকে না।
এটা অন্যান্য ল্যাংগুয়েজ থেকে সম্পূর্ণ আলাদা যেখানে ফাংশন কলের বোঝা থেকে যায়, যদিও ইমপ্লিমেন্টেশানটি NOP।

এটা দেখতে, আমরা একটা একদম সাদামাটা লগার তৈরি করবো, যেটাকে চালু অথবা বন্ধ করা যাবে:

```elixir
defmodule Logger do
  defmacro log(msg) do
    if Application.get_env(:logger, :enabled) do
      quote do
        IO.puts("Logged message: #{unquote(msg)}")
      end
    end
  end
end

defmodule Example do
  require Logger

  def test do
    Logger.log("This is a log message")
  end
end
```

লগিং চালু করা থাকলে, আমাদের `test` ফাংশনটি নিচে প্রদত্ত কোড প্রদান করবে:

```elixir
def test do
  IO.puts("Logged message: #{"This is a log message"}")
end
```

আর লগিং বন্ধ থাকলে কোডটি দেখতে নিচের মতো হবে:

```elixir
def test do
end
```

## ডিবাগিং

আচ্ছা, আমরা তো কিভাবে `quote/2`, `unquote/1` ব্যবহার করতে হয় এবং ম্যাক্রো লিখতে হয় তা জানলাম।
কিন্তু, কেমন হবে যদি আপনার অনেক বড় সাইজের একটা কো'ট করা কোড বুঝতে হয়? এক্ষেত্রে, আপনি `Macro.to_string/2` ব্যবহার করতে পারেন।
নিম্নের উদাহরণটি দেখুন:

```elixir
iex> Macro.to_string(quote(do: foo.bar(1, 2, 3)))
"foo.bar(1, 2, 3)"
```

এবং, যখন আপনি ম্যাক্রো থেকে উৎপন্ন হওয়া কোডগুলো দেখতে চাইবেন, তখন আপনি চাইলে `Macro.expand/2` এবং `Macro.expand_once/2` ব্যবহার করতে পারেন, এই ফাংশনগুলো ম্যাক্রোকে তার কো'ট করা কোডে রূপান্তর করে।
এখানে, প্রথমটি ক্ষেত্রবিশেষে কয়েকবার রূপান্তর করে, কিন্তু পরেরটি করে শুধুমাত্র একবার।
উদাহরণস্বরূপ, আগের উদাহরণের `unless` কে পরিবর্তন করা যাক:

```elixir
defmodule OurMacro do
  defmacro unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end

require OurMacro

quoted =
  quote do
    OurMacro.unless(true, do: "Hi")
  end
```

```elixir
iex> quoted |> Macro.expand_once(__ENV__) |> Macro.to_string |> IO.puts
if(!true) do
  "Hi"
end
```

যদি আমরা একই কোডে `Macro.expand/2` ব্যবহার করি, তবে এটা অনেক কৌতূহলউদ্দীপক।

```elixir
iex> quoted |> Macro.expand(__ENV__) |> Macro.to_string |> IO.puts
case(!true) do
  x when x in [false, nil] ->
    nil
  _ ->
    "Hi"
end
```

আপনার হয়তো মনে আছে, আমরা বলেছিলাম এলিক্সিরে `if` ও একটি ম্যাক্রো, এখানে আমরা দেখতে পাচ্ছি, এটা অভ্যন্তরীণ `case` স্টেটমেন্ট এ রূপান্তরিত হয়েছে।

### প্রাইভেট ম্যাক্রো

যদিও এটার ব্যবহার খুব একটা প্রচলিত নয়, তবে, এলিক্সির কিন্তু  প্রাইভেট ম্যাক্রোও সাপোর্ট করে।
প্রাইভেট ম্যাক্রো তৈরি করা হয় `defmacrop` এর মাধ্যমে। এই ম্যাক্রো গুলো শুধুমাত্র যে মডিউলে লেখা হয়েছে সে মডিউল থেকেই ব্যবহার করা যায়।
প্রাইভেট ম্যাক্রোকে যে কোড এ এর ব্যবহার করা হবে, তার আগে লিখতে হয়।

### ম্যাক্রো হাইজিন

কলার কন্টেক্সট এর সাথে রূপান্তরিত ম্যাক্রো কিভাবে ইন্টারেক্ট করে সে প্রক্রিয়াকে ম্যাক্রো হাইজিন বলে।
সাধারণত, এলিক্সির এর ম্যাক্রোগুলো হাইজেনিক। ফলে কন্টেক্সট এর সাথে কনফ্লিক্ট করে না:

```elixir
defmodule Example do
  defmacro hygienic do
    quote do: val = -1
  end
end

iex> require Example
nil
iex> val = 42
42
iex> Example.hygienic
-1
iex> val
42
```

কিন্তু যদি আপনি `val` এর ভ্যালু পরিবর্তন করতে চান তাহলে? সেক্ষেত্রে, আমরা চাইলে `var!/2` ব্যবহার করতে পারি যেটা ভ্যারিয়েবলকে আনহাইজেনিক হিসেবে চিহ্নিত করে।
চলুন তবে, আমাদের উদাহরণে আরেকটি ম্যাক্রো যুক্ত করা যাক যেটা `var!/2` কে কাজে লাগাবে:

```elixir
defmodule Example do
  defmacro hygienic do
    quote do: val = -1
  end

  defmacro unhygienic do
    quote do: var!(val) = -1
  end
end
```

আসুন, তারা কন্টেক্সট এর সাথে কিভাবে ইণ্টারেক্ট করে তা তুলনা করা যাক:

```elixir
iex> require Example
nil
iex> val = 42
42
iex> Example.hygienic
-1
iex> val
42
iex> Example.unhygienic
-1
iex> val
-1
```

আমাদের ম্যাক্রোতে `var!/2` যুক্ত করে আমরা `val` এর ভ্যালু পরিবর্তন করেছি, এটাকে ম্যাক্রোতে পাস না করেই।
নন-হাইজেনিক ম্যাক্রো এর ব্যবহার একদমই অল্প রাখা উচিত।
`var!/2` এর ব্যবহারের কারণে আমরা ভ্যারিয়েবল রেজলুশান কনফ্লিক্ট এর ঝুঁকি বাড়িয়েছি।

### বাইন্ডিং

আমরা `unquote/1` ব্যবহারোপযোগিতা কভার করেছি, কিন্তু এ ছাড়াও আরও ভ্যালু প্রবেশ করানোর আরও একটি উপায় আছে তা হলোঃ বাইন্ডিং।

ভ্যারিয়েবল বাইন্ডিং এর মাধ্যমে আমরা চাইলে ম্যাক্রোতে অনেকগুলো ভ্যারিয়েবল যুক্ত করতে পারি, এবং এটাও নিশ্চিত করতে পারি যে তারা কোন ধরণের এক্সিডেন্টাল রিভ্যালুয়েশান ছাড়াই শুধুমাত্র একবারই আনকো'ট হয়েছে।
বাউন্ড ভ্যারিয়েবলগুলো ব্যবহার করার জন্যে আমাদেরকে `quote/2` এর `bind_quoted` অপশনে একটি কিওয়ার্ড লিস্ট প্রদান করতে হবে।
`bind_quoted` এর সুবিধা এবং রিভ্যালুয়েশান ইস্যু দেখার জন্যে, চলুন একটা উদাহরণ দেখি।
শুরুতে, আমরা শুধুমাত্র একটি ম্যাক্রো ব্যবহার করবো যেটা একটি এক্সপ্রেশানকে দুইবার আউটপুট দেয়:

```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote do
      IO.puts(unquote(expr))
      IO.puts(unquote(expr))
    end
  end
end
```

আমরা আমাদের নতুন ম্যাক্রোটি পরীক্ষার জন্যে এটাকে বর্তমান সিস্টেম এর সময় প্রদান করবো।
আমরা দুটি আউটপুট আশা করতে পারি:

```elixir
iex> Example.double_puts(:os.system_time)
1450475941851668000
1450475941851733000
```

সময় দুটো ভিন্ন ভিন্ন! কি হচ্ছে এখানে? একই এক্সপ্রেশানে `unquote/1` একের অধিকবার ব্যবহারের ফলে রিভ্যালুয়েশান হয়েছে, ফলে পরিণতি অপ্রত্যাশিত।
চলুন, আমাদের উদাহরণকে `bind_quoted` ব্যবহার করে হালনাগাদ করে দেখা যাক কি হয়:

```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote bind_quoted: [expr: expr] do
      IO.puts(expr)
      IO.puts(expr)
    end
  end
end

iex> require Example
nil
iex> Example.double_puts(:os.system_time)
1450476083466500000
1450476083466500000
```

`bind_quoted` ব্যবহারের ফলে আমরা আমাদের প্রত্যাশিত রেজাল্ট পেলাম: একই সময় দুই বার আউটপুট হয়েছে।

`quote/2`, `unquote/1`, এবং `defmacro/2` কভার করার মাধ্যমে, এখন আমাদের প্রয়োজনানুযায়ী এলিক্সিরকে বর্ধনের জন্যে দরকারী সবগুলো টুলই আয়ত্ত করা হয়েছে।
