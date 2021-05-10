%{
  version: "1.0.1",
  title: "IEx হেল্পার",
  excerpt: """
  
  """
}
---

## সূচনা 

এলিক্সিরে কাজ করার সময়ে `IEx` আপনার সবচেয়ে গুরুত্বপূর্ণ সঙ্গী। এটি একটি `REPL (Read Evaluate Print Loop)` তবে এর অনেক বীল্ট-ইন সুবিধা রয়েছে যা আপনার এলিক্সির একপেরিয়েন্সকে সম্রিদ্ধ করবে। IEx এর  কিছু প্রয়োজনীয় বীল্ট-ইন হেল্পারের বর্ণনা এই অধ্যায়ে আমরা দিব। 

### অটোকমপ্লিট 

শেলে কাজ করার সময়ে আমরা প্রায়েই নতুন একটি মডিউলের সম্মুখীন হতে পারি যার সম্পর্কে আমাদের ধারণা নেই অথবা কম। আমরা একটি মডিউলের নামের শেষে একটি ডট (`.`) এবং তারপর ট্যাব প্রেস করে লিস্ট পেতে পারি সেই মডিউলের সদস্যের (ফাংশন, ম্যাক্রো ইত্যাদি)। 

```elixir
iex> Map. # press Tab
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
replace!/3           replace/3            split/2
take/2               to_list/1            update!/3
update/4             values/1
```

### `.iex.exs`

প্রতিবার IEx শুরু হওয়ার সময়ে `.iex.exs` কনফিগারেশান ফাইলটি খুঁজে নেয় কি কি লোড করতে হবে তার জন্য। যদি কারেন্ট ডিরেক্টরিতে তা না থাকে, তাহলে তা খুঁজবে ইউজারের হোম ডিরেক্টরিতে (`~/.iex.exs`) 

কনফিগারেশান অপশন ও কোড যা এই ফাইলে ডিফাইন করা হবে তা আমাদের `IEx` সেশানে পাওয়া যাবে সেশান শুরু করা মাত্রই। যেমন আমরা যদি নীচের মত করে কিছু ফাংশন বর্ণনা করি `.iex.exs` ফাইলে, তাহলে আমরা যতবার `IEx` খুলব, ততবার এই ফাংশনগুলিকে সরাসরি পাব। 

```elixir
defmodule IExHelpers do
  def whats_this?(term) when is_nil(term), do: "Type: Nil"
  def whats_this?(term) when is_binary(term), do: "Type: Binary"
  def whats_this?(term) when is_boolean(term), do: "Type: Boolean"
  def whats_this?(term) when is_atom(term), do: "Type: Atom"
  def whats_this?(_term), do: "Type: Unknown"
end
```

এখন থেকে `IEx` সেশানে `IExHelpers` মডিউল আমাদের কাছে থাকবে ব্যবহারের জন্য। তাহলে `IEx` এর একটি সেশান খুলে দেখা যাক- 

```elixir
$ iex
{{ site.erlang.OTP }} [{{ site.erlang.erts }}] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex> IExHelpers.whats_this?("a string")
"Type: Binary"
iex> IExHelpers.whats_this?(%{})
"Type: Unknown"
iex> IExHelpers.whats_this?(:test)
"Type: Atom"
```

দেখতেই পাচ্ছি যে আমাদের আলাদাভাবে `IExHelpers` কে `require` অথবা `import` করা লাগেনি। সরাসরিই পেয়ে গিয়েছি। 

### `h`

`h` সম্ভবত সবচেয়ে গুরুতপূর্ন হেল্পারগুলোর মধ্যে একটি। এলিক্সির ডকুমেন্টেশানের জন্য ল্যাঙ্গুয়েজ প্রদত্ত সুবিধা দিয়ে থাকে যার ফলে যে কোন কোডের ডকুমেন্টেশান আমরা এই কমান্ড দিয়ে পেতে পারি। 

```elixir
iex> h Enum
                                      Enum

Provides a set of algorithms that enumerate over enumerables according to the
Enumerable protocol.

┃ iex> Enum.map([1, 2, 3], fn(x) -> x * 2 end)
┃ [2, 4, 6]

Some particular types, like maps, yield a specific format on enumeration. For
example, the argument is always a {key, value} tuple for maps:

┃ iex> map = %{a: 1, b: 2}
┃ iex> Enum.map(map, fn {k, v} -> {k, v * 2} end)
┃ [a: 2, b: 4]

Note that the functions in the Enum module are eager: they always start the
enumeration of the given enumerable. The Stream module allows lazy enumeration
of enumerables and provides infinite streams.

Since the majority of the functions in Enum enumerate the whole enumerable and
return a list as result, infinite streams need to be carefully used with such
functions, as they can potentially run forever. For example:

┃ Enum.each Stream.cycle([1, 2, 3]), &IO.puts(&1)
```

এখন এই কমান্ড ও পূর্ববর্ণীত অটোকমপ্লিট কমান্ড একত্রিত করে আমরা যে কোন মডিউলের সাথে সহজেই পরিচিত হতে পারি। 

মনে করুন আমরা জীবনে প্রথমবারের মত ম্যাপ `Map` দেখেছি। একটু এক্সপ্লোর করা যাক একে- 

```elixir
iex> h Map
                                      Map

A set of functions for working with maps.

Maps are key-value stores where keys can be any value and are compared using
the match operator (===). Maps can be created with the %{} special form defined
in the Kernel.SpecialForms module.

iex> Map.
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
split/2              take/2               to_list/1
update!/3            update/4             values/1

iex> h Map.merge/2
                             def merge(map1, map2)

Merges two maps into one.

All keys in map2 will be added to map1, overriding any existing one.

If you have a struct and you would like to merge a set of keys into the struct,
do not use this function, as it would merge all keys on the right side into the
struct, even if the key is not part of the struct. Instead, use
Kernel.struct/2.

Examples

┃ iex> Map.merge(%{a: 1, b: 2}, %{a: 3, d: 4})
┃ %{a: 3, b: 2, d: 4}
```

দেখাই যাচ্ছে যে আমরা শুধুমাত্র মডিউলের ফাংশন না, বরং প্রতিটি ফাংশনের ডকুমেন্টেশান (উদাহরণসহ) দেখতে পাচ্ছি `h` এর মাধ্যমে। 

### `i`

আমাদের সদ্য পরিচিত হওয়া `h` এর ব্যবহার করা যাক এবং এর মাধ্যমে  `i` সম্পর্কে পরিচিত হওয়া যাক- 

```elixir
iex> h i

                                  def i(term)

Prints information about the given data type.

iex> i Map
Term
  Map
Data type
  Atom
Module bytecode
  /usr/local/Cellar/elixir/1.3.3/bin/../lib/elixir/ebin/Elixir.Map.beam
Source
  /private/tmp/elixir-20160918-33925-1ki46ng/elixir-1.3.3/lib/elixir/lib/map.ex
Version
  [9651177287794427227743899018880159024]
Compile time
  no value found
Compile options
  [:debug_info]
Description
  Use h(Map) to access its documentation.
  Call Map.module_info() to access metadata.
Raw representation
  :"Elixir.Map"
Reference modules
  Module, Atom
```

এখন আমাদের হাতে রয়েছে আরও কিছু তথ্য ম্যাপ সম্পর্কে, যেমন এর সোর্স কোডের লোকেশান এবং এর রেফারেন্সকৃত মডিউলসমূহ। এটি অনেক কাজে আসে যখন আমরা কাস্টম অথবা বহিরাগত ডেটা টাইপ অথবা নতুন ফাংশন নিয়ে কাজ করি তখন। 

নীচে কিছু তথ্য দেয়া হল যা আমরা পেতে পারি `i` এর মাধ্যমে- 

- এর অ্যাটম ডেটা টাইপ
- সোর্স কোড এর অবস্থান 
- ভার্সন ও কম্পাইল অপশান 
- সাধারণ বর্ণনা 
- কিভাবে অ্যাক্সেস করা যায় 
- আর কি কি মডিউলকে এটি রেফার করে 

না জেনে কাজ করা থেকে অনেক সুবিধা পাব আমরা যদি আমরা এই হেল্পারটি থেকে আমাদের ফাংশন অথবা মডিউল ঘাটতে পারি। 

### `r`

`IEx` সেশান খোলা অবস্থায় আমরা যদি কোন মডিউলকে পুনঃকম্পাইল করতে চাই তাহলে এই হেল্পারের আশ্রয় নিব। ধরুন আমরা `IEx` আওতাধীন কোন মডিউলের কিছু কোড চেঞ্জ করেছি (ফাংশন অ্যাড করেছি) এবং এই নতুন ফাংশন রান করতে চাই ওই `IEx` এ। তাহলে আমরা এডিটরে চেঞ্জ ও সেভ করে অতঃপর খোলা `IEx` সেশানে গিয়ে লিখব- 

```elixir
iex> r MyProject
warning: redefining module MyProject (current version loaded from _build/dev/lib/my_project/ebin/Elixir.MyProject.beam)
  lib/my_project.ex:1

{:reloaded, MyProject, [MyProject]}
```

### `t`

`t` হেল্পারের মাধ্যমে আমরা একটি মডিউলের টাইপ সম্পর্কে জানতে পারি। 

```elixir
iex> t Map
@type key() :: any()
@type value() :: any()
```

আমরা জানলাম যে ম্যাপ (`Map`) "কী"ও "ভ্যালু" টাইপকে ডিফাইন করে থাকে। 

আর যদি আমরা ম্যাপ এর সোর্স কোড দেখি- 

```elixir
defmodule Map do
# ...
  @type key :: any
  @type value :: any
# ...
```

এটি একটি সহজ উদাহরণ যা দেখায় যে প্রতি ইম্লিমেন্টেশানের কী ও ভ্যালু যে কোন টাইপের হতে পারে।

উপরিউক্ত সকল বীল্ট-ইন ফিচারের মাধ্যমে আমরা সহজেই আমাদের কোড সম্পর্কে জানতে পারব এবং আরও ভালভাবে জানতে পারব যে এলিক্সির কিভাবে কাজ করে। `IEx` অত্যন্ত শক্তিশালী একটি টুল যার দ্বারা প্রোগ্রামাররা সক্ষম হয় অনেক কিছু সরাসরি দেখে নিতে কোন এডিটর না খুলেই। এর মাধ্যমে আমরা এলিক্সির কোডকে আরও সহজে এক্সপ্লোর করতে ও শিখতে পারি। 
