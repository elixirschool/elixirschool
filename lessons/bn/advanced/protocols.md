%{
  version: "1.0.1",
  title: "প্রোটোকল",
  excerpt: """
  এই অধ্যায়ে, আমরা প্রোটোকল কি এবং কিভাবে এলিক্সিরে প্রোটোকল ব্যবহার করা হয় তা দেখবো।
  """
}
---

## প্রোটোকল 
তো কি এই প্রোটোকল? 
এলিক্সিরে পলিমরফিজম করার উপায় হলো প্রোটোকল।
নতুন তৈরি টাইপস এর জন্যে কোনো এপিআই এর বর্ধন এরল্যাং এ প্রচুর কষ্টসাধ্য। 
তাই, এটা থেকে মুক্তি পেতে এলিক্সিরে ফাংশনকে তার ভ্যালু এর টাইপের ভিত্তিতে ডাইনামিকালি ডিসপ্যাচ করা হয়।
এলিক্সিরে অনেক গুলো বিল্ট-ইন প্রোটোকল রয়েছে, উদাহরণঃ আগের অধ্যায়গুলোতে আমরা `to_string/1` নামের যে ফাংশনটি দেখেছি তা `String.Chars` প্রোটোকল থেকেই এসেছে।
চলুন তবে, `to_string/1` ফাংশনটির একটি উদাহরণ দেখা যাক:

```elixir
iex> to_string(5)
"5"
iex> to_string(12.4)
"12.4"
iex> to_string("foo")
"foo"
```

দেখতেই পাচ্ছেন, আমরা বিভিন্ন টাইপস এ ফাংশনটি কল করে দেখতে পেয়েছি এটা সবগুলো টাইপস এর জন্যেই কাজ করেছে।
কেমন হবে যদি আমরা `to_string/1` ফাংশনটি টাপল এর জন্যে ব্যবহার করি (অথবা এমন অন্য কোন টাইপের জন্যে যেটা `String.Chars` ইমপ্লিমেন্ট করে নি)?
দেখা যাক:

```elixir
to_string({:foo})
** (Protocol.UndefinedError) protocol String.Chars not implemented for {:foo}
    (elixir) lib/string/chars.ex:3: String.Chars.impl_for!/1
    (elixir) lib/string/chars.ex:17: String.Chars.to_string/1
```

আমরা দেখতে পাচ্ছি, টাপলের জন্যে এর কোন ইমপ্লিমেন্টেশান পাওয়া যায় নি তাই প্রোটোকল এরর দেখাচ্ছে।
পরবর্তী অংশে আমরা টাপলের জন্যে `String.Chars` প্রোটোকলটি ইমপ্লিমেন্ট করবো।

## প্রোটোকল ইমপ্লিমেন্ট 

আমরা দেখতে পেলাম  টাপলের জন্যে `to_string/1` ফাংশনটি ইমপ্লিমেন্ট করা হয়নি। চলুন, এটা ইমপ্লিমেন্ট করি।
ইমপ্লিমেন্টেশান এর জন্যে প্রথমে, আমরা প্রোটোকল এর সাথে `defimpl` ব্যবহার করব, এবং আমাদের টাইপ এর সাথে `:for` অপশনটি প্রদান করবো।  
চলুন দেখি, এটা দেখতে কেমন হতে পারে:

```elixir
defimpl String.Chars, for: Tuple do
  def to_string(tuple) do
    interior =
      tuple
      |> Tuple.to_list()
      |> Enum.map(&Kernel.to_string/1)
      |> Enum.join(", ")

    "{#{interior}}"
  end
end
```

আমরা যদি এটাকে IEx এ কপি করি তবে, আমরা এখন টাপলের জন্যে কোন ধরণের এরর ছাড়াই `to_string/1` ফাংশনটি ব্যবহার করতে পারবো:

```elixir
iex> to_string({3.14, "apple", :pie})
"{3.14, apple, pie}"
```

কিভাবে প্রোটোকল ইমপ্লিমেন্ট করতে হয় তা দেখলাম, কিন্তু কিভাবে আমরা নতুন প্রোটোকল তৈরি করতে পারি?
আমাদের উদাহরণস্বরূপ, আমরা `to_atom/1` ফাংশন তৈরি করবো। 
চলুন দেখা যাক, `defprotocol` ব্যবহার করে কিভাবে এটা করা যায়:

```elixir
defprotocol AsAtom do
  def to_atom(data)
end

defimpl AsAtom, for: Atom do
  def to_atom(atom), do: atom
end

defimpl AsAtom, for: BitString do
  defdelegate to_atom(string), to: String
end

defimpl AsAtom, for: List do
  defdelegate to_atom(list), to: List
end

defimpl AsAtom, for: Map do
  def to_atom(map), do: List.first(Map.keys(map))
end
```

এখানে, আমরা `to_atom/1` ফাংশন গ্রহণ করে এমন একটি প্রোটোকল তৈরি করেছি, এবং কিছু টাইপস এর জন্যে এর ইমপ্লিমেন্টেশান করেছি।
প্রোটোকলতো তৈরি হলো, এবার এটাকে IEx এ ব্যবহার করা যাক:

```elixir
iex> import AsAtom
AsAtom
iex> to_atom("string")
:string
iex> to_atom(:an_atom)
:an_atom
iex> to_atom([1, 2])
:"\x01\x02"
iex> to_atom(%{foo: "bar"})
:foo
```

লক্ষ্যণীয় বিষয় হলো,অভ্যন্তরে স্ট্রাক্ট আসলে ম্যাপ হলেও, তারা ম্যাপ এর সাথে প্রোটোকল ইমপ্লিমেন্টেশান শেয়ার করে না।
তারা যেহেতু এনুমারেবল নয়, তাই তাদের একসেস ও করা যায় না।

আমরা দেখলাম, প্রোটোকল হলো পলিমরফিজম করার অন্যতম হাতিয়ার।
