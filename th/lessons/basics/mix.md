---
version: 1.0.0
title: Mix
redirect_from:
  - /lessons/basics/mix/
---

ก่อนที่เราจะดำดิ่งลึกลงไปในโลกของ Elixir มากกว่านี้ เราต้องมารู้จักกับ Mix กันก่อน ถ้าคุณคุ้นเคยกับ Ruby ตัว Mix เองคือ Bundler, RubyGems และ Rake รวมกัน ซึ่งเป็นส่วนสำคัญของโปรเจค Elixir ทุกโปรเจคและในบทเรียนนี้เราจะได้พบกับฟีเจอร์เจ๋งๆของ Mix บางส่วน หากต้องการดูความสามารถของ Mix ทั้งหมดให้รัน `mix help`

จนถึงตอนนี้ เราทำทุกอย่างอยู่บน `iex` เท่านั้น ซึ่งก็มีข้อจำกัดอยู่ การจะสร้างอะไรขึ้นมาเพื่อใช้งานจริงๆ เราจำเป็นต้องแบ่งโค้ดเราออกเป็นหลายๆไฟล์เพื่อที่จะจัดการได้ง่าย Mix ช่วยให้เราทำแบบนั้นได้กับ projects

{% include toc.html %}

## New Projects

เมื่อเราจะสร้างโปรเจค Elixir ใหม่ mix ช่วยทำให้ชีวิตเราง่ายขึ้นด้วยคำสั่ง `mix new` โดยคำสั่งนี้จะสร้างโครงสร้าง project folder และโค้ด boilerplate ที่จำเป็นต้องใช้ มาเริ่มกันเลยดีกว่า

```bash
$ mix new example
```

จาก output เราจะเห็นว่า Mix ได้สร้าง directory และไฟล์ boilerplate จำนวนนึงให้เรา:

```bash
* creating README.md
* creating .gitignore
* creating mix.exs
* creating config
* creating config/config.exs
* creating lib
* creating lib/example.ex
* creating test
* creating test/test_helper.exs
* creating test/example_test.exs
```

ในบทนี้เราจะโฟกันกันไปที่ไฟล์ `mix.exs` ในไฟล์นี้เรา configure application ของเรา, dependencies, environment, และ version เปิดไฟล์ใน editor ที่คุณชอบแล้วคุณจะเจอโค้ดหน้าตาแบบนี้ (comments ถูกลบออกเผื่อให้กระชับขึ้น):

```elixir
defmodule Example.Mixfile do
  use Mix.Project

  def project do
    [app: :example,
     version: "0.0.1",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    []
  end
end
```

ส่วนแรกที่เราจะมาดูกันคือ `project` ในส่วนนี้เราก็จะระบุชื่อ application ของเรา (`app`) ระบุ version (`version`) Elixir version (`elixir`) และสุดท้าย dependencies (`deps`)

ส่วน `application` จะถูกใช้ตอนสร้างไฟล์ของ application ซึ่งเราจะพูดถึงต่กันอีกที

## Interactive

It may be necessary to use `iex` within the context of our application.  Thankfully for us, Mix makes this easy.  We can start a new `iex` session:

```bash
$ iex -S mix
```

Starting `iex` this way will load your application and dependencies into the current runtime.

## Compilation

Mix is smart and will compile your changes when necessary, but it may still be necessary to explicitly compile your project.  In this section we'll cover how to compile our project and what compilation does.

To compile a Mix project we only need to run `mix compile` in our base directory:

```bash
$ mix compile
```

There isn't much to our project so the output isn't too exciting but it should complete successfully:

```bash
Compiled lib/example.ex
Generated example app
```

When we compile a project Mix creates a `_build` directory for our artifacts.  If we look inside `_build` we will see our compiled application: `example.app`.

## Managing Dependencies

Our project doesn't have any dependencies but will shortly, so we'll go ahead and cover defining dependencies and fetching them.

To add a new dependency we need to first add it to our `mix.exs` in the `deps` section.  Our dependency list is comprised of tuples with two required values and one optional: the package name as an atom, the version string, and optional options.

For this example let's look at a project with dependencies, like [phoenix_slim](https://github.com/doomspork/phoenix_slim):

```elixir
def deps do
  [{:phoenix, "~> 1.1 or ~> 1.2"},
   {:phoenix_html, "~> 2.3"},
   {:cowboy, "~> 1.0", only: [:dev, :test]},
   {:slime, "~> 0.14"}]
end
```

As you probably discerned from the dependencies above, the `cowboy` dependency is only necessary during development and test.

Once we've defined our dependencies there is one final step: fetching them.  This is analogous to `bundle install`:

```bash
$ mix deps.get
```

That's it!  We've defined and fetched our project dependencies.  Now we're prepared to add dependencies when the time comes.

## Environments

Mix, much like Bundler, supports differing environments.  Out of the box mix works with three environments:

+ `:dev` — The default environment.
+ `:test` — Used by `mix test`. Covered further in our next lesson.
+ `:prod` — Used when we ship our application to production.

The current environment can be accessed using `Mix.env`.  As expected, the environment can be changed via the `MIX_ENV` environment variable:

```bash
$ MIX_ENV=prod mix compile
```
