---
version: 1.0.1
title: การจับคู่รูปแบบ (Pattern Matching)
redirect_from:
  - /lessons/basics/pattern-matching/
---

การจับคู่รูปแบบเป็นส่วนที่ทรงพลังส่วนหนึ่งของ Elixir มันทำให้เราสามารถจับคู่ค่าต่าง ๆ ได้ เช่น ค่าของตัวแปร, โครงสร้างข้อมูล หรือแม้แต่ฟังก์ชัน ในบทเรียนนี้เราจะได้เริ่มเรียนรู้วิธีการใช้งาน การจับคู่รูปแบบ กัน

{% include toc.html %}

## เครื่องหมายการจับคู่

เครื่องหมาย `=` ใน Elixir จริง ๆ แล้วมันคือ เครื่องหมายการจับคู่ เปรียบได้กับเครื่องหมาย "เท่ากับ" ในพีชคณิต การเขียนมันลงไปจะทำให้ Expression ทั้งหมดกลายเป็นสมการ และทำให้ Elixir ทำการจับคู่ค่าทางซ้ายกับค่าทางขวาทันที ถ้าจับคู่สำเร็จ มันก็จะคืนค่าของสมการนั้นออกมา แต่ถ้าไม่สำเร็จ มันก็จะโยนเออเรอร์ออกมาแทน เราลองมาดูตัวอย่างกัน:

```elixir
iex> x = 1
1
```

คราวนี้ลองทำการจับคู่อย่างง่าย

```elixir
iex> 1 = x
1
iex> 2 = x
** (MatchError) no match of right hand side value: 1
```

ลองจับคู่กับ Collections ที่เรียนมา

```elixir
# Lists
iex> list = [1, 2, 3]
iex> [1, 2, 3] = list
[1, 2, 3]
iex> [] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

iex> [1 | tail] = list
[1, 2, 3]
iex> tail
[2, 3]
iex> [2 | _] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

# Tuples
iex> {:ok, value} = {:ok, "Successful!"}
{:ok, "Successful!"}
iex> value
"Successful!"
iex> {:ok, value} = {:error}
** (MatchError) no match of right hand side value: {:error}
```

## เครื่องหมายการปักหมุด

เครื่องหมายการจับคู่แสดงให้เห็นถึงการกำหนดค่า เมื่อฝั่งซ้ายของการจับคู่มีตัวแปรอยู่ได้ ในบางครั้งตัวแปรอาจจะมีค่าอยู่แล้วทำให้ไม่สามารถ กำหนดค่าลงไปได้ สำหรับสถานการณ์แบบนี้ เราก็มีสิ่งที่เรียกว่า เครื่องหมายการปักหมุด เข้ามาช่วย `^`

เมื่อเราปักหมู่ให้กับตัวแปร เราจับคู่ให้กับค่าที่มีอยู่แล้วแทนที่จะผูกมันกับค่าใหม่ ลองมาดูตัวอย่างกันว่ามันทำงานอย่างไร:

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

Elixir 1.2 ได้รองรับการใช้เครื่องหมายการปักหมุดใน map keys และ ฟังก์ชัน:

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

ตัวอย่างการปักหมุดในฟังก์ชัน:

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
