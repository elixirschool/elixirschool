%{
  version: "1.0.1",
  title: "প্যাটার্ন ম্যাচিং",
  excerpt: """
  এলিক্সিরের সবচেয়ে শক্তিশালী বৈশিষ্ট্যের মধ্যে একটি হল প্যাটার্ন ম্যাচিং। এর মাধ্যমে আমরা ভ্যালু, ডাটা স্ট্রাকচার, এমনকি ফাংশনকে ম্যাচ করতে পারি। এই অধ্যায়ে আমরা প্যাটার্ন ম্যাচিং শুরু করতে যাচ্ছি।
  """
}
---

## ম্যাচ অপারেটর 

এলিক্সিরে `=` অপারেটর আসলে ম্যাচিংয়ের জন্য ব্যবহৃত হয়। একে আমরা তুলনা করতে পারি বীজগণিতের সমান চিহ্নের সাথে। এটি সম্পূর্ণ এক্সপ্রেশানকে একটি সমীকরণে পরিণত করে এবং বামপক্ষের সাথে ডানপক্ষ মিলিয়ে থাকে। যদি সমান চিহ্নের দুই পাশ মিলে যায়, তাহলে সেই সমীকরণের মান রিটার্ন করা হয়, অন্যথায় এরর। দেখা যাক- 

```elixir
iex> x = 1
1
```

এবার কিছু সাধারণ ম্যাচ দেখা যাক- 

```elixir
iex> 1 = x
1
iex> 2 = x
** (MatchError) no match of right hand side value: 1
```

আমাদের পরিচিত কিছু কালেকশনের উপর ম্যাচ যেভাবে কাজ করে- 

```elixir
# Lists
iex> list = [1, 2, 3]
[1, 2, 3]
iex> [1, 2, 3] = list
[1, 2, 3]
iex> [] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

iex> [1 | tail] = list
[1, 2, 3]
iex> tail
[2, 3]
iex> [2|_] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

# Tuples
iex> {:ok, value} = {:ok, "Successful!"}
{:ok, "Successful!"}
iex> value
"Successful!"
iex> {:ok, value} = {:error}
** (MatchError) no match of right hand side value: {:error}
```

## পিন অপারেটর

আমরা দেখলাম ম্যাচ অপারেটর অ্যাসাইনমেন্টের কাজ কওরে যখন বামপক্ষে কোন ভেরিয়েবল থাকে। তবে কোন কোন ক্ষেত্রে আমরা তা নাও চাইতে পারি, বরং সেই ভেরিয়েবলের মানের সাথে ম্যাচিং করতে চাইতে পারি। এই আচরণের জন্য ব্যবহৃত হয় পিন অপারেটর- `^`

যখন আমরা কোন ভেরিয়েবলকে পিন করি তখন সেই ভেরিয়েবলের তৎকালীন মান ব্যবহৃত হয় ম্যাচের জন্যে, নতুন মান অ্যাসাইন করা হয় না। নীচে এর উদাহরণ দেয়া হয়েছে- 

```elixir
iex> x = 1
1
iex> ^x = 2
** (MatchError) no match of right hand side value: 2
iex> {x, ^x} = {2, 1}
{2, 1}
iex> x
2
```

এলিক্সির ১.২ থেকে আমরা ম্যাপ কী ও ফাংশন ক্লজের উপরও পিন ব্যবহার করতে পারি-

```elixir
iex> key = "hello"
"hello"
iex> %{^key => value} = %{"hello" => "world"}
%{"hello" => "world"}
iex> value
"world"
iex> %{^key => value} = %{:hello => "world"}
** (MatchError) no match of right hand side value: %{hello: "world"}
```

ফাংশন ক্লজের  উপর পিনের অ্যাপ্লিকেশানের উদাহরণ- 

```elixir
iex> greeting = "Hello"
"Hello"
iex> greet = fn
...>   (^greeting, name) -> "Hi #{name}"
...>   (greeting, name) -> "#{greeting}, #{name}"
...> end
#Function<12.54118792/2 in :erl_eval.expr/5>
iex> greet.("Hello", "Sean")
"Hi Sean"
iex> greet.("Mornin'", "Sean")
"Mornin', Sean"
```
