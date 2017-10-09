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

บางทีเราก็จำเป็นที่จะต้องใช้ `iex` กับ context ของ application เรา โอ้ขอบคุณสวรรค์ Mix ช่วยให้เราทำเรื่องนี้ได้ง่าย เราสามารถเริ่ม `iex` session ใหม่ด้วย context ของเราด้วยคำสั่ง

```bash
$ iex -S mix
```

รัน `iex` ด้วยวิธีนี้จะโหลด application ของคุณและ dependencies ต่างๆเข้าไปใน runtime ปัจจุบัน

## Compilation

Mix นั้นฉลาดและจะ compile ตามการแก้ไขของคุณเมื่อจำเป็น แต่การ compile โปรเจคของคุณเองก็ยังคงเป็นสิ่งจำเป็นอยู่ ในส่วนนี้เราจะพูดถึงการจะ compile project ของเราอย่างไร และกระบวนการ compile นั้นทำอะไรบ้าง

การ compile Mix project เราแค่ต้องรันคำสั่ง `mix compile` ใน base directory ของเรา

```bash
$ mix compile
```

โปรเจคเรายังไม่มีอะไรมากดังนั้นผลลัพธ์เลยยังไม่มีอะไรน่าตื่นเต้นเท่าไหร่แต่มันควรจะเสร็จสมบูรณ์

```bash
Compiled lib/example.ex
Generated example app
```

เมื่อเรา compile โปรเจค Mix จะสร้าง directory `_build` ขึ้นมาสำหรับเก็บของที่ถูก compile ถ้าเราเข้าไปดูใน `_build` เราจะเจอกับ application ของเราที่ถูก compile แล้ว: `example.app`

## Managing Dependencies

ตอนนี้โปรเจคของเรายังไม่มี dependencies ดังนั้นเราจะใส่ dependencies เข้าไปและ fetching มันลงมา

การจะเพิ่ม dependency เข้าไป อย่างแรกเราต้องเพิ่มเข้าไปในไฟล์ `mix.exs` ของเราในส่วน `deps` ลิสของ dependency ของเราจะถูกระบุอยู่ในรูปของ tuples ด้วยค่าที่ต้องการสองค่าและค่าเสริมอีกหนึ่งค่า ซึ่งก็คือ: ชื่อของ package ในรูปของ atom, เวอร์ชั่นในรูปของ string และสุดท้ายคือ options ที่ใส่หรือไม่ใส่ก็ได้

สำหรับตัวอย่างสามารถดูได้จากโปรเจคที่มี dependencies เช่น [phoenix_slim](https://github.com/doomspork/phoenix_slim):

```elixir
def deps do
  [{:phoenix, "~> 1.1 or ~> 1.2"},
   {:phoenix_html, "~> 2.3"},
   {:cowboy, "~> 1.0", only: [:dev, :test]},
   {:slime, "~> 0.14"}]
end
```

จากที่คุณได้เห็นจาก dependencies ข้างบน `cowboy` dependency นั้นจำเป็นแค่ตอน development และ test

เมื่อเราประกาศ dependencies ของเราเสร็จเราก็เหลืออีกหนึ่งขึ้นตอน fetching มัน ซึ่งจะเหมือนกับ `bundle install`

```bash
$ mix deps.get
```

แค่นั้นเอง! เมื่อเราประกาศและ fetched dependencies ของโปรเจคเราแล้ว ตอนนี้เราก็พร้อมที่จะเพิ่ม dependencies เมื่อไหร่ก็ตามที่ต้องการ

## Environments

Mix นั้นเหมือนกับ Bundler ตรงที่รองรับ environments หลายๆแบบ โดย environments ที่มีมาให้ในตัวเลยมีสามแบบ

+ `:dev` — environment พื้นฐาน
+ `:test` — ถูกใช้โดย `mix test` เราจะพูดถึงในบทถัดๆไป
+ `:prod` — ใช้เมื่อเราเอา application ของเราขึ้น production

สามารถอ่านค่า environment ปัจจุบันได้จาก `Mix.env` และแน่นอน environment สามารถเปลี่ยนได้ผ่าน environment variable `MIX_ENV`

```bash
$ MIX_ENV=prod mix compile
```
