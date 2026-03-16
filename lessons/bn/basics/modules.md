%{
  version: "1.0.2",
  title: "মডিউল",
  excerpt: """
  অভিজ্ঞতা থেকে আমরা জানি যে এক ফাইল ও স্কোপে সমস্ত ফাংশন রাখা ঠিক না। এই অধ্যায়ে আমরা আলোচনা করব কিভাবে কিছু ফাংশনকে একত্রিত করা যায় এবং এরপর একটি বিশেষ ম্যাপ, স্ট্রাক্ট নিয়ে কথা বলব যা আমাদের কোড সংগঠনকে আরও সুগঠিত রাখতে সাহায্য করবে।
  """
}
---

## মডিউল

মডিউল হল সর্বোত্তম উপায় আমাদের ফাংশনকে নেইমস্পেসে সুগঠিত করে রাখার। ফাংশন গ্রুপিং ছাড়াও তারা "নামসহ" এবং প্রাইভেট ফাংশন বানাতে দেয় যা আমরা পূর্ববর্তী অধ্যায়ে শিখেছি।

একটি বেসিক উদাহরণ দেখা যাক-

``` elixir
defmodule Example do
  def greeting(name) do
    "Hello #{name}."
  end
end

iex> Example.greeting "Sean"
"Hello Sean."
```

এলিক্সিরে মডিউল নেস্টিং করা সম্ভব-

```elixir
defmodule Example.Greetings do
  def morning(name) do
    "Good morning #{name}."
  end

  def evening(name) do
    "Good night #{name}."
  end
end

iex> Example.Greetings.morning "Sean"
"Good morning Sean."
```

### মডিউল আট্রিবিউট

মডিউল আট্রিবিউট এলিক্সিরের সবচেয়ে বেশী ব্যবহৃত কনস্ট্যান্ট। একটি উদাহরণ দেখা যাক-

```elixir
defmodule Example do
  @greeting "Hello"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

উল্লেখ্য এলিক্সির এর কিছু রিজার্ভড আট্রিবিউট রয়েছে। এর মধ্যে তিনটি কমন আট্রিবিউট হল-

+ `moduledoc` — মডিউলকে ডকুমেন্ট করে
+ `doc` — ফাংশন ও ম্যাক্রো ডকুমেন্টেশানের জন্য ব্যবহৃত
+ `behaviour` — OTP অথবা ইউজার ডিফাইন্ড বিহেভিয়ার তৈরি করতে সাহায্য করে

## স্ট্রাক্ট

স্ট্রাক্ট হচ্ছে বিশেষ এক প্রকার ম্যাপ যার রয়েছে পূর্ববর্ণীত কী এবং ডিফল্ট ভ্যালু। একটি স্ট্রাক্ট অবশ্যই ব্যবহৃত হয় মডিউলের ভেতর এবং ওই মডিউলের নামই হয়ে থাকে স্ট্রাক্টের নাম। অনেক ক্ষেত্রেই দেখা পাওয়া যায় এমন মডিউলের যার কেবল মাত্র একটি মাত্র সদস্যই রয়েছে যা হল এর স্ট্রাক্ট।

`defstruct` দিয়ে আমরা স্ট্রাক্ট ডিফাইন করে থাকি, সাথে বলে দেই এর ফিল্ড সমূহ (কী-ওয়ার্ড লিস্টের মাধ্যমে) এবং ডিফল্ট ভ্যালুসমূহ-

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

এবার কিছু স্ট্রাক্ট তৈরি করা যাক-

```elixir
iex> %Example.User{}
%Example.User<name: "Sean", roles: [], ...>

iex> %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [], ...>

iex> %Example.User{name: "Steve", roles: [:manager]}
%Example.User<name: "Steve", roles: [:manager]>
```

স্ট্রাক্টকে আমরা ঠিক ম্যাপের মতই আপডেট করতে পারি-

```elixir
iex> steve = %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [...], ...>
iex> sean = %{steve | name: "Sean"}
%Example.User<name: "Sean", roles: [...], ...>
```

স্ট্রাক্টকে আপনি ম্যাপের সাথে ম্যাচ করাতে পারেন-

```elixir
iex> %{name: "Sean"} = sean
%Example.User<name: "Sean", roles: [...], ...>
```

## কম্পোজিশান

আমরা স্ট্রাক্ট ও মডিউল তৈরি করতে পারি। এবার আমরা দেখব কিভাবে কম্পোজিশানের মাধ্যমে আমরা বিদ্যমান ফাংশনালিটি যোগ করতে পারি। এলিক্সিরে তা বেশ কয়েকভাবে করা যায়-

### alias

`alias` দিয়ে আমরা মডিউল নাম আলিয়াসিং করতে পারি। যা এলিক্সিরে অনেক ব্যবহৃত হয়।

```elixir
defmodule Sayings.Greetings do
  def basic(name), do: "Hi, #{name}"
end

defmodule Example do
  alias Sayings.Greetings

  def greeting(name), do: Greetings.basic(name)
end

# অ্যালিয়াস ছাড়া

defmodule Example do
  def greeting(name), do: Sayings.Greetings.basic(name)
end
```

যদি দুটি অ্যালিয়াস একই নামের হয় অথবা আমরা কোন অ্যালিয়াসকে ভিন্ন নাম দিতে চাই তাহলে আমরা `:as` অপশন ব্যবহার করব।

```elixir
defmodule Example do
  alias Sayings.Greetings, as: Hi

  def print_message(name), do: Hi.basic(name)
end
```

একাধিক মডিউলকে একসাথে অ্যালিয়াস করা যায় যেমন-

```elixir
defmodule Example do
  alias Sayings.{Greetings, Farewells}
end
```

### import

অ্যালিয়াস না করে যদি আমরা সরাসরি ফাংশন ও ম্যাক্রো ইম্পোর্ট করতে চাই তাহলে `import/1` ব্যবহার করব।

```elixir
iex> last([1, 2, 3])
** (CompileError) iex:9: undefined function last/1
iex> import List
nil
iex> last([1, 2, 3])
3
```

#### ফিল্টারিং

ইম্পোর্ট করলে সমস্ত ফাংশন ও ম্যাক্রো চলে আসে, কিন্তু আমরা `:only` ও `:except` এর মাধ্যমে ইম্পোর্টকৃত ফাংশন অথবা ম্যাক্রোর উপর ফিল্টার করতে পারি-

বিশেষ কিছু ফাংশন ও ম্যাক্রো ইম্পোর্ট করতে হলে তাদের নাম/অ্যারিটি যুগলকে `:only` ও `:except` কে জানিয়ে দিতে হবে। নীচে একটি উদাহরণ দেখান হয়েছে যেখানে শুধু `last/1` কে ইম্পোর্ট করা হয়েছে-

```elixir
iex> import List, only: [last: 1]
iex> first([1, 2, 3])
** (CompileError) iex:13: undefined function first/1
iex> last([1, 2, 3])
3
```

আর যদি আমরা `last/1` ছাড়া বাকি সব ইম্পোর্ট করতে চাই তাহলে-

```elixir
iex> import List, except: [last: 1]
nil
iex> first([1, 2, 3])
1
iex> last([1, 2, 3])
** (CompileError) iex:3: undefined function last/1
```

নাম/অ্যারিটি যুগলকে `:only` ও `:except` কেই শুধু না, `:functions` আর `:macros` কে দিয়ে আমরা ফিল্টার করতে পারি যে শুধু ফাংশনকে নিব নাকি ম্যাক্রোকে-

```elixir
import List, only: :functions
import List, only: :macros
```

### require

কম ব্যবহৃত হলেও `require/2` গুরুত্বপূর্ণ। `require/2` এর মাধ্যমে আমরা নির্দেশ দেই যেন উল্লেখিত মডিউলটি অবশ্যই কম্পাইলড হয়। ম্যাক্রো আনয়নের সময়ে এটি ব্যবহার করা হয়-

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff()
end
```

লোড না করে ম্যাক্রো ব্যবহার করলে এরর পেতে হবে।

### use

ইউজ ম্যাক্রো একটি বিশেষ ম্যাক্রো `__using__/1` কে কল করে।

```elixir
# lib/use_import_require/use_me.ex
defmodule UseImportRequire.UseMe do
  defmacro __using__(_) do
    quote do
      def use_test do
        IO.puts("use_test")
      end
    end
  end
end
```

এরপর আমরা এই লাইনকে `UseImportRequire` এ ব্যবহার করতে পারি।

```elixir
use UseImportRequire.UseMe
```

`UseImportRequire.UseMe` একটি ফাংশন `use_test/0` কে ডিফাইন করে `__using__/1` ম্যাক্রোর মাধ্যমে।

ইউজ এই একটি কাজই করে। `__using__` ম্যাক্রো প্রায়শ ব্যবহৃত হয় অ্যালিয়াস, রিকুয়ার, অথবা ইম্পোর্ট কল করতে। এটি দ্বারা মডিউল কিভাবে, কি কি ফাংশন কিভাবে ব্যবহার করবে তার পলিসি স্থাপন করা যায়। `__using__/1` দিয়ে অন্যান্য মডিউল এমনকি সাব-মডিউলকেও রেফার করা যায়।

ফিনিক্স ফ্রেমওয়ার্ক `__using__/1` এর ব্যবহার দিয়ে বারংবার অ্যালিয়াস ও ইম্পোর্ট কল করা থেকে প্রোগ্রামারকে বিরত রাখে।

`Ecto.Migration` মডিউলের একটি ছোট উদাহরণ নীচে দেয়া হয়েছে-

```elixir
defmacro __using__(_) do
  quote location: :keep do
    import Ecto.Migration
    @disable_ddl_transaction false
    @before_compile Ecto.Migration
  end
end
```

`Ecto.Migration.__using__/1` ম্যাক্রো একটি ইম্পোর্ট ব্যবহার করে যার ফলে যখন আমরা `use Ecto.Migration` লিখি তখন আমরাও `import Ecto.Migration` ব্যবহার করে ফেলি।

আবারো বলা হচ্ছে- ইউজ ম্যাক্রো শুধুমাত্র ওই মডিউলের `__using__/1` কল করে। ভালভাবে বুঝতে হলে পড়ে নিন `__using__/1` এর ডকুমেন্টেশান।

**নোট**: `quote`, `alias`, `use`, `require` হল ম্যাক্রো যা মেটাপ্রোগ্রামিংয়ের সময়ে ব্যবহৃত হয়।
<!-- TODO: Add link we advanced/metaprogramming is translated
[মেটাপ্রোগ্রামিংয়ের](/bn/lessons/advanced/metaprogramming) সময়ে ব্যবহৃত হয়। -->
