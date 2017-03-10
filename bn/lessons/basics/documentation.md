---
layout: page
title: ডকুমেন্টেশান 
category: basics
order: 11
lang: bn
---

আপনার কোডকে ডকুমেন্ট করুন।

{% include toc.html %}

## অ্যানোটেশান 

আপনার কোডে কতটুকু কমেন্টিং করবেন এবং ভাল ডকুমেন্টেশানের মাপকাঠি কী তা নিয়ে যুক্তিতর্কের শেষ নেই। কিন্তু একটা বিষয়ে সকলে একমত যে ডকুমেন্টেশানের গুরুত্ব অপরিসীম। এলিক্সিরের কোর ডেভেলপাররা এটি আগেই বুঝতে পেরেছিলেন যার ফলে ল্যাঙ্গুয়েজটিতে ডকুমেন্টেশানের হরেক রকমের ব্যবস্থা। ডকুমেন্টেশান এলিক্সিরে *প্রথম শ্রেণীর নাগরিক* এবং ডকুমেন্টেশান প্রণালীকে আরামদায়ক করার জন্য রয়েছে বহু ধরণের ব্যবস্থা তথা মডিউল ও ফাংশন। 

এলিক্সিরের তিনটি প্রধান ডকুমেন্টেশান ব্যবস্থা হল- 

  - `#` - ইনলাইন ডকুমেন্টেশানের জন্য 
  - `@moduledoc` - মডিউল ডকুমেন্টেশানের জন্য 
  - `@doc` - ফাংশন ডকুমেন্টেশানের জন্য

### ইনলাইন ডকুমেন্টেশান 

ডকুমেন্টেশানের সহজতম উপায় হল ইনলাইন কমেন্টিং। রুবি, পাইথন, পার্ল ইত্যাদির মত `#` দিয়ে এলিক্সিরের ইনলাইন কমেন্ট ব্যবহৃত হয়ে থাকে। একে আপনি পাউন্ড অথবা হ্যাশ ডাকতে পারেন। 

নীচের এলিক্সির স্ক্রিপ্টটি দেখি- 

```elixir
# Outputs 'Hello, chum.' to the console.
IO.puts "Hello, " <> "chum."
```
এলিক্সির কোড রান করার সময়ে স্ক্রিপ্টটি `#` পরবর্তী সমস্ত কথা বাদ দিয়ে দেয়। কিন্তু যদি আপনি ঠিকমত কমেন্ট করেন তাহলে আপনার কোডে কী হচ্ছে তা অন্যান্য প্রোগ্রামাররা বুঝতে পারবে। তবে, অযথা কমেন্ট না করাই ভাল কারণ তা পরবর্তীতে বিরক্তির কারণ হয়ে দাঁড়াবে। দরকার বুঝে সংক্ষিপ্ত ভাষায় ইনলাইন কমেন্ট করাই উত্তম। 

### মডিউল ডকুমেন্টেশান 

The `@moduledoc` annotator allows for inline documentation at a module level. It typically sits just under the `defmodule` declaration at the top of a file. The below example shows a one line comment within the `@moduledoc` decorator.

```elixir
defmodule Greeter do
  @moduledoc """
  Provides a function `hello/1` to greet a human
  """

  def hello(name) do
    "Hello, " <> name
  end
end
```

We (or others) can access this module documentation using the `h` helper function within IEx.

```elixir
iex> c("greeter.ex")
[Greeter]

iex> h Greeter

                Greeter

Provides a function hello/1 to greet a human
```

### ফাংশন ডকুমেন্টেশান 

Just as Elixir gives us the ability for module level annotation, it also enables similar annotations for documenting functions. The `@doc` annotator allows for inline documentation at a function level. The `@doc` annotator sits just above the function it is annotating.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t) :: String.t
  def hello(name) do
    "Hello, " <> name
  end
end
```

If we kick into IEx again and use the helper command (`h`) on the function prepended with the module name, we should see the following:

```elixir
iex> c("greeter.ex")
[Greeter]

iex> h Greeter.hello

                def hello(name)

Prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"

iex>
```

Notice how you can use markup within our documentation and the terminal will render it? Apart from really being cool and a novel addition to Elixir's vast ecosystem, it gets much more interesting when we look at ExDoc to generate HTML documentation on the fly.

**Note:** the `@spec` annotation is used to static analysis of code. To learn more about it, check out the [Specifications and types](../../advanced/typespec) lesson.

## এক্সডক 

ExDoc is an official Elixir project that can be found on [GitHub](https://github.com/elixir-lang/ex_doc). It produces **HTML (HyperText Markup Language) and online documentation** for Elixir projects. First let's create a Mix project for our application:

```bash
$ mix new greet_everyone

* creating README.md
* creating .gitignore
* creating mix.exs
* creating config
* creating config/config.exs
* creating lib
* creating lib/greet_everyone.ex
* creating test
* creating test/test_helper.exs
* creating test/greet_everyone_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd greet_everyone
    mix test

Run "mix help" for more commands.

$ cd greet_everyone

```

Now copy and paste the code from the `@doc` annotator lesson into a file called `lib/greeter.ex` and make sure everything is still working from the command line. Now that we are working within a Mix project we need to start IEx a little differently using the `iex -S mix` command sequence:

```bash
iex> h Greeter.hello

                def hello(name)

Prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"
```

### ইন্সটল 

Assuming all is well and we're seeing the output above, we are now ready to set up ExDoc. In the `mix.exs` file, add the two required dependencies to get started: `:earmark` and `:ex_doc`.

```elixir
  def deps do
    [{:earmark, "~> 0.1", only: :dev},
    {:ex_doc, "~> 0.11", only: :dev}]
  end
```

We specify the `only: :dev` key-value pair as we don't want to download and compile these dependencies in a production environment. But why Earmark? Earmark is a Markdown parser for the Elixir programming language that ExDoc utilizes to turn our documentation within `@moduledoc` and `@doc` to beautiful looking HTML.

It is worth noting at this point that you are not forced to use Earmark. You can change the markup tool to others such as Pandoc, Hoedown, or Cmark; however you will need to do a little more configuration which you can read about [here](https://github.com/elixir-lang/ex_doc#changing-the-markdown-tool). For this tutorial, we'll just stick with Earmark.

### ডক জেনারাশান 

Carrying on, from the command line run the following two commands:

```bash
$ mix deps.get # gets ExDoc + Earmark.
$ mix docs # makes the documentation.

Docs successfully generated.
View them at "doc/index.html".
```

If everything went to plan, you should see a similar message as to the output message in the above example. Let's now look inside our Mix project and we should see that there is another directory called **doc/**. Inside is our generated documentation. If we visit the index page in our browser we should see the following:

![ExDoc Screenshot 1]({{ site.url }}/assets/documentation_1.png)

We can see that Earmark has rendered our Markdown and ExDoc is now displaying it in a useful format.

![ExDoc Screenshot 2]({{ site.url }}/assets/documentation_2.png)

We can now deploy this to GitHub, our own website, or more commonly [HexDocs](https://hexdocs.pm/).

## বেস্ট প্র্যাকটিস 

Adding documentation should be added within the Best practices guidelines of the language. Since Elixir is a fairly young language many standards are still to be discovered as the ecosystem grows. The community, however, tried to establish best practices. To read more about best practices see [The Elixir Style Guide](https://github.com/niftyn8/elixir_style_guide).

  - Always document a module.

```elixir
defmodule Greeter do
  @moduledoc """
  This is good documentation.
  """

end
```

  - If you do not intend to document a module, **do not** leave it blank. Consider annotating the module `false`, like so:

```elixir
defmodule Greeter do
  @moduledoc false

end
```

 - When referring to functions within module documentation, use backticks like so:

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  def hello(name) do
    IO.puts "Hello, " <> name
  end
end
```

 - Separate any and all code one line under the `@moduledoc` as so:

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  alias Goodbye.bye_bye
  # and so on...

  def hello(name) do
    IO.puts "Hello, " <> name
  end
end
```

 - Use markdown within functions that will make it easier to read either via IEx or ExDoc.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t) :: String.t
  def hello(name) do
    "Hello, " <> name
  end
end
```

 - Try to include some code examples in your documentation. This also allows you to generate automatic tests from the code examples found in a module, function, or macro with [ExUnit.DocTest][]. In order to do that, you need to invoke the `doctest/1` macro from your test case and write your examples according to some guidelines as detailed in the [official documentation][ExUnit.DocTest].

[ExUnit.DocTest]: http://elixir-lang.org/docs/stable/ex_unit/ExUnit.DocTest.html
