%{
  version: "1.1.1",
  title: "ডেট টাইম",
  excerpt: """
  এলিক্সিরে সময় সংক্রান্ত কাজ করা 
  """
}
---

## টাইম

এলিক্সিরের বেশ কিছু মডিউল সময় নিয়ে কাজ করে থাকে। 
শুরুতেই কিভাবে, বর্তমান সময় নির্ণয় করতে হয় তা দেখা যাকঃ 

```elixir
iex> Time.utc_now
~T[19:39:31.056226]
```

লক্ষ্য করুন, আমরা একটি সিজিল পেয়েছি যেটা দিয়ে আমরা `Time` স্ট্রাক্ট ও তৈরি করতে পারিঃ

```elixir
iex> ~T[19:39:31.056226]
~T[19:39:31.056226]
```

সিজিল সম্পর্কে বিস্তারিত জানতে [সিজিলের চ্যাপ্টারটি দেখুন](/bn/lessons/basics/sigils).
স্ট্রাক্ট এর বিভিন্ন অংশ গুলো খুব সহজেই দেখা যায়ঃ

```elixir
iex> t = ~T[19:39:31.056226]
~T[19:39:31.056226]
iex> t.hour
19
iex> t.minute
39
iex> t.day
** (KeyError) key :day not found in: ~T[19:39:31.056226]
```

এখানে একটা কিন্তু আছেঃ আপনি হয়তো ইতোমধ্যে খেয়াল করেছেন, এই স্ট্রাক্টটি তে শুধু সময় আছে, কোনো দিন/মাস/বছর এর ডেটা নাই।

## ডেট

`Time` এর বিপরীতে, একটি `Date` স্ট্রাক্ট এ বর্তমান তারিখ সম্পর্কিত তথ্য থাকে, কিন্তু কোন সময় সংক্রান্ত তথ্য থাকে নাঃ 

```elixir
iex> Date.utc_today
~D[2028-10-21]
```

এছাড়াও, তারিখ নিয়ে কাজ করার জন্যে বেশ কিছু প্রয়োজনীয় ফাংশনও এতে বিদ্যমানঃ

```elixir
iex> {:ok, date} = Date.new(2020, 12,12)
{:ok, ~D[2020-12-12]}
iex> Date.day_of_week date
6
iex> Date.leap_year? date
true
```

`day_of_week/1` একটি তারিখ সপ্তাহের কোন দিনে আছে তা নির্ণয় করে। 
এক্ষেত্রে, এটা শনিবার। 
`leap_year?/1` বছরটি অধিবর্ষ কি না তা চেক করে। 
অন্যান্য ফাংশনগুলো সম্পর্কে বিস্তারিত জানতে [ডকুমেন্টেশন](https://hexdocs.pm/elixir/Date.html) পড়ুন।

## নাইভডেটটাইম

তারিখ এবং সময় একই সাথে বিদ্যমান থাকে এমন দুটি স্ট্রাক্ট এলিক্সিরে পাওয়া যায়ঃ 
এর প্রথমটি হলো `NaiveDateTime`.
অসুবিধা হলো, এতে কোন টাইমজোন সাপোর্ট নাইঃ 

```elixir
iex(15)> NaiveDateTime.utc_now
~N[2029-01-21 19:55:10.008965]
```

কিন্তু, এটিতে বর্তমান সময় এবং তারিখ দুটোই আছে, সুতরাং আপনি চাইলে সময় যোগ করে দেখতে পারেন। উদাহরণঃ

```elixir
iex> NaiveDateTime.add(~N[2018-10-01 00:00:14], 30)
~N[2018-10-01 00:00:44]
```

## ডেটটাইম 

দ্বিতীয়টি হলো `DateTime`, যা আপনি হয়তো ইতোমধ্যে এ সেকশান এর নাম দেখেই অনুমান করে ফেলেছেন। 
`NaiveDateTime` এর মতো এর কোনো বাধা নেই, এটার সময় এবং তারিখ দুটোই আছে, এবং টাইমজোনও সাপোর্ট করে।
কিন্তু টাইমজোন সতর্কতার সাথে ব্যবহার করতে হবে, অফিশিয়াল ডকুমেন্টেশনে বলা আছেঃ

> Many functions in this module require a time zone database. By default, it uses the default time zone database returned by `Calendar.get_time_zone_database/0`, which defaults to `Calendar.UTCOnlyTimeZoneDatabase` which only handles "Etc/UTC" datetimes and returns `{:error, :utc_only_time_zone_database}` for any other time zone.

দ্রষ্টব্য, শুধুমাত্র টাইমজোন যুক্ত করে নাইভডেটটাইম থেকে ডেটটাইম ইন্সট্যান্স তৈরি করা সম্ভবঃ

```elixir
iex> DateTime.from_naive(~N[2016-05-24 13:26:08.003], "Etc/UTC")
{:ok, #DateTime<2016-05-24 13:26:08.003Z>}
```

## টাইমজোন 

পূর্বের অধ্যায়ের বর্ণনা অনুযায়ী, এলিক্সির এ সাধারণভাবে, কোনো টাইমজোন তথ্য থাকে না।
এই সমস্যা সমাধানে, আমাদেরকে [টিজেডডাটা](https://github.com/lau/tzdata) প্যাকেজটি ইন্সটল ও সেট আপ করে নিতে হবে। 
ইন্সটল করার পরে, আপনাকে গ্লোবাল কনফিগারেশন সেট করে নিতে হবে, যাতে এলিক্সির টিজেডডাটা কে টাইমজোন ডাটাবেস হিসেবে ব্যবহার করেঃ

```elixir
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
```

চলুন, এবার তবে প্যারিস টাইমজোনে সময় তৈরি করে, সেটা নিউ ইয়র্ক সময়ে রূপান্তর করা যাকঃ 

```elixir
iex> paris_datetime = DateTime.from_naive!(~N[2019-01-01 12:00:00], "Europe/Paris")
#DateTime<2019-01-01 12:00:00+01:00 CET Europe/Paris>
iex> {:ok, ny_datetime} = DateTime.shift_zone(paris_datetime, "America/New_York")
{:ok, #DateTime<2019-01-01 06:00:00-05:00 EST America/New_York>}
iex> ny_datetime
#DateTime<2019-01-01 06:00:00-05:00 EST America/New_York>
```

দেখতেই পাচ্ছেন, প্যারিস সময় ১২ঃ০০ থেকে ৬ঃ০০ এ পরিবর্তিত হয়েছে, যেটা সঠিক- দুটো শহরের সময় ব্যবধান আসলেই ৬ ঘণ্টা। 

ব্যস এটুকুই! আপনি যদি অন্যান্য এডভান্সড ফাংশন নিয়ে কাজ করতে চান, তবে আপনি চাইলেই [টাইম](https://hexdocs.pm/elixir/Time.html), [ডেট](https://hexdocs.pm/elixir/Date.html), [ডেটটাইম](https://hexdocs.pm/elixir/DateTime.html) এবং [নাইভডেটটাইম](https://hexdocs.pm/elixir/NaiveDateTime.html) এর ডকুমেন্টেশান পড়ে দেখতে পারেন। 
এছাড়াও, আপনার [টাইমএক্স](https://github.com/bitwalker/timex) এবং [ক্যালেন্ডার](https://github.com/lau/calendar) মডিউলগুলোও দেখা উচিত যেগুলো এলিক্সির এর সময় সংক্রান্ত মডিউল গুলোর মধ্যে অন্যতম।
