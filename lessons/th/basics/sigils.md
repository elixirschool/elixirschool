%{
  version: "1.0.2",
  title: "Sigils",
  excerpt: """
  การใช้งานและสร้าง Sigils
  """
}
---

## Sigils Overview

ใน Elixir คุณสามารถแสดงผลและจัดการกับตัวอักษรต่างๆได้ในอีก syntax หนึ่งได้ โดยใช้ sigils 
การใช้งาน Sigil นั้นจะเริ่มโดยการใช้สัญลักษณ์ตัวหนอน `~` และตามด้วยตัวอักษรหนึ่งตัว ซึ่ง Elixir core นั้นมี sigil เบื้องต้นบางส่วนพร้อมสำหรับการใข้งานอยู่แล้ว แต่คุณก็สามารถสร้าง sigil ของตัวเองได้เช่นกัน

Sigils เบื้องต้นที่มีให้ใช้งาน:

  - `~C` จะสร้าง list ของ character โดยที่ **ไม่มี** การ escaping หรือ interpolation
  - `~c` จะสร้าง list ของ character โดยที่ **มี** การ escaping หรือ interpolation
  - `~R` จะสร้าง regular Expression โดยที่ **ไม่มี** การ escaping หรือ interpolation
  - `~r` จะสร้าง regular Expression โดยที่ **มี** การ escaping หรือ interpolation
  - `~S` จะสร้าง string โดยที่ **ไม่มี** การ escaping หรือ interpolation
  - `~s` จะสร้าง string โดยที่ **มี** การ escaping หรือ interpolation
  - `~W` จะสร้าง list ของ word โดยที่ **ไม่มี** การ escaping หรือ interpolation
  - `~w` จะสร้าง list ของ word โดยที่ **มี** การ escaping หรือ interpolation
  - `~N` จะสร้าง struct ประเภท `NaiveDateTime`
  - `~U` จะสร้าง struct ประเภท `DateTime` (ตั้งแต่ Elixir 1.9.0)

สำหรับ delimiters มีได้ดังนี้:

  - `<...>` A pair of pointy brackets
  - `{...}` A pair of curly brackets
  - `[...]` A pair of square brackets
  - `(...)` A pair of parentheses
  - `|...|` A pair of pipes
  - `/.../` A pair of forward slashes
  - `"..."` A pair of double quotes
  - `'...'` A pair of single quotes

### Char List

Sigil `~c` และ `~C` ใช้สำหรับสร้าง list ของ character
อย่างเช่นในตัวอย่างต่อไปนี้

```elixir
iex> ~c/2 + 7 = #{2 + 7}/
'2 + 7 = 9'

iex> ~C/2 + 7 = #{2 + 7}/
'2 + 7 = \#{2 + 7}'
```

จะเห็นได้ว่าสำหรับ sigil `~c` (ตัวพิมพ์เล็ก) นั้น มีการคำนวณและแทนค่าตัวแปร ในขณะที่ sigil `~C` (ตัวพิมพ์ใหญ๋) ไม่ได้ทำเช่นนั้น และคืนค่า charlists ตรงๆ ออกมา.
ข้อสังเกตุ: การใช้ตัวพิมพ์ใหญ่และตัวพิมพ์เล็กใน sigil จะเป็นแนวการใช้งานของ sigil ที่มาพร้อมกับ Elixir

### Regular Expressions

Sigil `~r` และ `~R` ใช้สำหรับการสร้าง Regular Expressions.
เราสามารถสร้างเพื่อใช้งานทันที หรือเพื่อใช้งานในฟังก์ชันต่างๆของ `Regex`.
อย่างเช่นในตัวอย่างต่อไปนี้

```elixir
iex> re = ~r/elixir/
~r/elixir/

iex> "Elixir" =~ re
false

iex> "elixir" =~ re
true
```

จะเห็นได้ว่า ในการทดสอบความเท่ากันอันแรกนั้นพบว่า `Elixir` นั้นไม่ match กับ Regular Expression เนื่องจากเรื่องของตัวพิมพ์ใหญ่พิมพ์เล็ก
ที่เป็นเช่นนี้เพราะ Elixir นั้นรองรับ Regular Expression แบบ Perl Compatible Regular Expressions (PCRE) จึงจำเป็นต้องเพิ่ม `i` ต่อท้าย sigil ในตอนสร้าง เพื่อให้ regular expression นั้นไม่เป็น case sensitivity


```elixir
iex> re = ~r/elixir/i
~r/elixir/i

iex> "Elixir" =~ re
true

iex> "elixir" =~ re
true
```

นอกจากนี้ Elixir ได้มี [Regex](https://hexdocs.pm/elixir/Regex.html) API ให้เรียกใช้งาน ซึ่งสร้างขึ้นบน regular expression library ของ Erlang 
เมื่อทำการใช้ `Regex.split/2` คู่กับ Regex sigil

```elixir
iex> string = "100_000_000"
"100_000_000"

iex> Regex.split(~r/_/, string)
["100", "000", "000"]
```

อย่างที่เห็นว่า string `"100_000_000"` ได้ถูกแบ่งโดย underscore เนื่องจาก sigil `~r/_/` ที่สร้างขึ้น และฟังก์ชัน `Regex.split` ได้ทำการ return เป็น list ออกมา


### String

Sigil `~s` และ `~S` ใช้สำหรับการสร้างข้อมูล string
อย่างเช่นในตัวอย่างต่อไปนี้

```elixir
iex> ~s/the cat in the hat on the mat/
"the cat in the hat on the mat"

iex> ~S/the cat in the hat on the mat/
"the cat in the hat on the mat"
```

ถ้าดูจากตัวอย่างข้างต้นนี้ คุณอาจจะไม่เห็นความแตกต่าง แต่จริงๆแล้ว ความแตกต่างนั้นเหมือนกับ Sigil ของ Character List ซึ่งก็คือการ escaping และ interpolation
ดังเช่นตัวอย่างถัดไป

```elixir
iex> ~s/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir school"

iex> ~S/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir \#{String.downcase \"SCHOOL\"}"
```

### Word List

Sigil word list มีประโยชน์ในบางสถานการณ์
มันสามารถลดเวลา ลดการพิมพ์ และลดความซับซ้อนของใน codebase ของคุณได้
อย่างเช่นตัวอย่างต่อไปนี้

```elixir
iex> ~w/i love elixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love elixir school/
["i", "love", "elixir", "school"]
```

จะเห็นได้ว่า สิ่งที่อยู่ใน delimiter นั้นถูกคั่นและตัดด้วย whitespace ออกมาเป็น list
แต่ผลลัพธ์ของสองตัวอย่างข้างต้นนั้นไม่มีความแตกต่าง นั่นก็เป็นเพราะการใช้ sigil สำหรับการ escaping และ interpolation นั่นเอง ดังเช่นตัวอย่างถัดไป

```elixir
iex> ~w/i love #{'e'}lixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love #{'e'}lixir school/
["i", "love", "\#{'e'}lixir", "school"]
```

### NaiveDateTime

Sigil [NaiveDateTime](https://hexdocs.pm/elixir/NaiveDateTime.html) สามารถใช้เพื่อสร้าง struct `DateTime` ที่**ไม่มี** timezone

ในส่วนใหญ่ เราควรจะหลีกเลี่ยงการสร้าง struct `NaiveDateTime` โดยตรง 
แต่จะมีประโชน์มากสำหรับกรณีที่ใช้เพื่อการทำ Pattern Matching เช่น

```elixir
iex> NaiveDateTime.from_iso8601("2015-01-23 23:50:07") == {:ok, ~N[2015-01-23 23:50:07]}
```

### DateTime

Sigil [DateTime](https://hexdocs.pm/elixir/DateTime.html) สามารถใช้เพื่อสร้าง struct `DateTime` **พร้อมกับ** UTC timezone เนื่องจากเป็น UTC timezone นั้น เมื่อทำการเปรียบเทียบกับ `DateTime` string ที่อาจจะอยู่กันคนละ timezone จึงจำเป็นต้องมี offset (หน่วยวินาที) เพื่อใช้ในการเปรียบเทียบเพิ่มเติม

ตัวอย่างดังนี้

```elixir
iex> DateTime.from_iso8601("2015-01-23 23:50:07Z") == {:ok, ~U[2015-01-23 23:50:07Z], 0}
iex> DateTime.from_iso8601("2015-01-23 23:50:07-0600") == {:ok, ~U[2015-01-24 05:50:07Z], -21600}
```

## Creating Sigils

หนึ่งในเป้าหมายหลักของ Elixir คือการทำภาษานี้ให้เป็น extendable programming language (ภาษาที่สามารถต่อขยายได้) มันจึงง่ายที่จะสามารถพัฒนา sigil ขึ้นมาเพื่อตอบโจทย์การใช้งานใหม่ๆ ได้

ในตัวอย่างนี้ จะทำการสร้าง sigil เพื่อทำการแปลง string ให้เป็นตัวพิมพ์ใหญ่ทั้งหมด
และเนื่องจากใน Elixir core นั้นมีฟังก์ชั่น `String.upcase/1` อยู่แล้ว เราจะทำการครอบฟังก์ชันดังกล่าวด้วย sigil ที่สร้างขึ้น

```elixir

iex> defmodule MySigils do
...>   def sigil_p(string, []), do: String.upcase(string)
...> end

iex> import MySigils
nil

iex> ~p/elixir school/
ELIXIR SCHOOL
```

ในขั้นตอนแรกแรก เราทำการสร้าง module ที่มีชื่อว่า `MySigils` และทำการสร้างฟังก์ชัน `sigil_p` ขึ้นมา โดย คำต่อท้าย `_p` ใน ฟังก์ชัน `sigil_p` แสดงว่าเราจะทำการกำหนดให้ `p` เป็น character ที่ต่อจากตัวหนอน `~` เนื่องจากไม่มี sigil `~p` อยู่ในปัจจุบัน โดยที่ฟังก์ชันที่สร้างขึ้นนั้นต้องรับ 2 arguments คือ input และ list
