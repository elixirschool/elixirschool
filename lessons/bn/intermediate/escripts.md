%{
  version: "1.0.2",
  title: "এক্সিকিউটেবল",
  excerpt: """
  এক্সিকিউটেবল তৈরি করার জন্যে আমরা ই-স্ক্রিপ্ট ব্যবহার করবো।
  এরল্যাং ইন্সটল করা থাকলেই, ই-স্ক্রিপ্ট দিয়ে তৈরি করা এক্সিকিউটেবল যেকোনো সিস্টেমে রান করা যায়।
  """
}
---

## ভূমিকা

ই-স্ক্রিপ্ট দিয়ে এক্সিকিউটেবল তৈরি করার জন্যে আমাদেরকে শুধুমাত্র কয়েকটা জিনিস করতে হবেঃ `main/1` ফাংশন ইমপ্লিমেন্ট করা এবং মিক্সফাইল আপডেট করা।
শুরুতে আমরা একটা মডিউল তৈরি করবো যেটা এক্সিকিউটেবল এর জন্যে এন্ট্রি পয়েন্ট হিসেবে কাজ করবে।
এই মডিউলেই আমরা `main/1` ফাংশনটি ইমপ্লিমেন্ট করবোঃ

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    # Do stuff
  end
end
```

এর পরে, আমাদের কে মিক্সফাইল আপডেট করতে হবে যাতে, `:main_module` কোনটি তা বলে দিতে পারি এবং এর সাথে `:escript` অপশনটি যুক্ত করতে পারিঃ

```elixir
defmodule ExampleApp.Mixproject do
  def project do
    [app: :example_app, version: "0.0.1", escript: escript()]
  end

  defp escript do
    [main_module: ExampleApp.CLI]
  end
end
```

## পারসিং আর্গুমেন্ট

আমাদের এপ্লিকেশনতো সেটআপ করা হলো, এবার আমরা কমান্ড লাইন আর্গুমেন্ট কিভাবে পার্স করতে হয় তা দেখবো।
এর জন্যে, আমরা এলিক্সির এর `OptionParser.parse/2` ফাংশনটি ব্যবহার করবো এবং এর সাথে `:switches` অপশনটি যুক্ত করবো যাতে করে আমাদের ফ্ল্যাগ বুলিয়ান তা নির্দেশ করা যায়ঃ

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    args
    |> parse_args()
    |> response()
    |> IO.puts()
  end

  defp parse_args(args) do
    {opts, word, _} =
      args
      |> OptionParser.parse(switches: [upcase: :boolean])

    {opts, List.to_string(word)}
  end

  defp response({opts, word}) do
    if opts[:upcase], do: String.upcase(word), else: word
  end
end
```

## বিল্ডিং

এপ্লকিশেনকে ই-স্ক্রিপ্ট ব্যবহার করার জন্যে কনফিগার করে ফেললেই,মিক্স আমাদের এক্সিকিউটেবল বানানো খুবই সহজ ও আরামদায়ক করে দিবেঃ  

```bash
mix escript.build
```

আসুন, এটা কে টেস্ট করে দেখা যাকঃ

```bash
$ ./example_app --upcase Hello
HELLO

$ ./example_app Hi
Hi
```

ব্যস এটুকুই!
এরই সাথে, প্রথমবারের মতো আমাদের ই-স্ক্রিপ্ট ব্যবহার করে এলিক্সির এক্সিকিউটেবল তৈরি করা সমাপ্ত হলো।
