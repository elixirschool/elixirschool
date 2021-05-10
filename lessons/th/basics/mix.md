%{
  version: "1.0.2",
  title: "Mix",
  excerpt: """
  ก่อนที่เราจะดำดิ่งลึกลงไปในโลกของ Elixir มากกว่านี้ เราต้องมารู้จักกับ Mix กันก่อน ถ้าคุณคุ้นเคยกับ Ruby ตัว Mix เองก็คือ Bundler, RubyGems และ Rake รวมกัน ซึ่ง Mix เองเป็นส่วนสำคัญของโปรเจค Elixir ทุกโปรเจค และในบทเรียนนี้เราจะได้พบกับบางฟีเจอร์เจ๋งๆของ Mix หากต้องการดูความสามารถของ Mix ทั้งหมดให้รันคำสั่ง `mix help`

จนถึงตอนนี้เราทำทุกอย่างอยู่บน `iex` เท่านั้นซึ่งมีข้อจำกัดอยู่ การจะสร้างอะไรขึ้นมาเพื่อใช้งานจริงๆ เราจำเป็นต้องแบ่งโค้ดของเราออกเป็นหลายๆไฟล์ เพื่อที่จะสามารถจัดการได้ง่าย ซึ่ง Mix เองสามารถช่วยให้เราทำแบบนั้นได้
  """
}
---

## New Projects

เมื่อเราจะสร้างโปรเจค Elixir ใหม่ mix ช่วยทำให้ชีวิตเราง่ายขึ้นด้วยคำสั่ง `mix new` โดยคำสั่งนี้จะสร้าง folder ของโปรเจค และโค้ด boilerplate ที่จำเป็นต้องใช้ เรามาเริ่มกันเลยดีกว่า

```bash
$ mix new example
```

จาก output เราจะเห็นว่า Mix ได้สร้าง folder และไฟล์ boilerplate จำนวนนึงให้เรา:

```bash
* creating README.md
* creating .gitignore
* creating .formatter.exs
* creating mix.exs
* creating lib
* creating lib/example.ex
* creating test
* creating test/test_helper.exs
* creating test/example_test.exs
```

ในบทนี้เราจะเน้นไปที่ไฟล์ `mix.exs` ไฟล์นี้เราสามารถ configure application ของเรา, dependency, environment, และ version เมื่อเปิดไฟล์ `mix.exs` ใน editor ที่คุณชอบ คุณจะเจอโค้ดหน้าตาแบบนี้ (comments ถูกลบออกเผื่อให้กระชับขึ้น):

```elixir
defmodule Example.Mix do
  use Mix.Project

  def project do
    [
      app: :example,
      version: "0.0.1",
      elixir: "~> 1.0",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    []
  end
end
```

ส่วนแรกที่เราจะมาดูกันคือ `project` ในส่วนนี้เราจะระบุชื่อ application ของเรา (`app`), ระบุ version (`version`), Elixir version (`elixir`) และ dependency (`deps`)

ส่วน `application` จะถูกใช้ตอนสร้างไฟล์ของ application ซึ่งเราจะพูดถึงถัดไป

## Interactive

บางทีเราก็จำเป็นที่จะต้องใช้ `iex` กับ context ของ application เรา โอ้ขอบคุณสวรรค์ Mix ช่วยให้เราทำเรื่องนี้ได้ง่าย เราสามารถเริ่ม `iex` session ใหม่ด้วย context ของเราด้วยคำสั่ง

```bash
$ cd example
$ iex -S mix
```

รัน `iex` ด้วยวิธีนี้จะโหลด application ของคุณและ dependency ต่างๆเข้าไปใน runtime ปัจจุบัน

## Compilation

Mix นั้นฉลาดและจะ compile เมื่อคุณแก้ไขหรือจำเป็นต้อง compile ใหม่ แต่การ compile โปรเจคได้เอง ก็ยังคงเป็นสิ่งจำเป็นอยู่ ในส่วนนี้เราจะพูดถึงวิธี compile เอง และเมื่อ compile มันจะเกิดอะไรขึ้นบ้าง

การ compile โปรเจค Mix เราแค่ต้องรันคำสั่ง `mix compile` ใน base directory ของเรา

```bash
$ mix compile
```

โปรเจคเรายังไม่มีอะไรมากดังนั้นผลลัพธ์เลยยังไม่มีอะไรน่าตื่นเต้นเท่าไหร่และมันควรจะเสร็จสมบูรณ์ดี

```bash
Compiled lib/example.ex
Generated example app
```

เมื่อเรา compile โปรเจค Mix จะสร้าง directory `_build` ขึ้นมาสำหรับเก็บของที่ถูก compile ถ้าเราเข้าไปดูใน `_build` เราจะเจอกับ application ของเราที่ถูก compile แล้ว: `example.app`

## Managing Dependencies

ตอนนี้โปรเจคของเรายังไม่มี dependency ดังนั้นเราจะใส่ dependency เข้าไปและ fetch มันลงมา

การจะเพิ่ม dependency เข้าไป อย่างแรกเราต้องเพิ่มเข้าไปในไฟล์ `mix.exs` ของเรา ในส่วน `deps` ซึ่งลิสต์ของ dependency จะถูกระบุอยู่ในรูปของ tuples ด้วยค่าที่จำเป็นสองค่าและค่าเสริมอีกหนึ่งค่า ซึ่งก็คือ: ชื่อของ package ในรูปของ atom, เวอร์ชั่นในรูปของ string และสุดท้ายคือ options ที่ใส่หรือไม่ใส่ก็ได้

สำหรับตัวอย่างสามารถดูได้จากโปรเจคที่มี dependency เช่น [phoenix_slim](https://github.com/doomspork/phoenix_slim):

```elixir
def deps do
  [
    {:phoenix, "~> 1.1 or ~> 1.2"},
    {:phoenix_html, "~> 2.3"},
    {:cowboy, "~> 1.0", only: [:dev, :test]},
    {:slime, "~> 0.14"}
  ]
end
```

จากที่คุณได้เห็นจาก dependency ข้างบน `cowboy` นั้นจำเป็นแค่ตอน development และ test

เมื่อเราประกาศ dependency ของเราเสร็จเราก็เหลืออีกหนึ่งขึ้นตอนคือ fetch มัน ซึ่งเหมือนกับ `bundle install`

```bash
$ mix deps.get
```

แค่นั้นเอง! เมื่อเราประกาศและ fetch dependency ของโปรเจคเราแล้ว ตอนนี้เราก็พร้อมที่จะเพิ่ม dependency เมื่อไหร่ก็ตามที่เราต้องการ

## Environments

Mix นั้นเหมือนกับ Bundler ตรงที่รองรับ environments หลายๆแบบ โดย environments ที่มีมาให้ในตัวเลยมีสามแบบ

+ `:dev` — environment พื้นฐาน
+ `:test` — ถูกใช้โดย `mix test` เราจะพูดถึงในบทถัดๆไป
+ `:prod` — ใช้เมื่อเราเอา application ของเราขึ้น production

สามารถอ่านค่า environment ปัจจุบันได้จาก `Mix.env` และแน่นอน environment สามารถเปลี่ยนได้ผ่าน environment variable `MIX_ENV`

```bash
$ MIX_ENV=prod mix compile
```
