---
version: 1.0.1
title: การจับคู่รูปแบบ (Pattern Matching)
redirect_from:
  - /lessons/basics/pattern-matching/
---

Pattern Matching เป็นส่วนที่ทรงพลังมากส่วนนึงของ Elixir มันทำให้เราสามารถเปรียบเทียบค่า, โครงสร้างข้อมูล หรือแม้แต่ฟังก์ชันได้ ในบทนี้เราจะมาดูกันว่า Pattern Matching มันใช้งานอย่างไร

{% include toc.html %}

## Match Operator

ใน Elixir เครื่องหมาย `=` จริง ๆ แล้วมันคือ เครื่องหมายการจับคู่ (Match Operator)  เปรียบได้กับเครื่องหมาย "เท่ากับ" ในพีชคณิต การใช้เครื่องหมาย `=` จะทำให้ Expression นั้น ๆ กลายเป็นสมการ และทำให้ Elixir ทำการจับคู่ค่าฝ่ังซ้ายกับค่าฝั่งขวาทันที ถ้าสำเร็จ มันก็จะคืนค่าของสมการนั้นออกมา แต่ถ้าไม่สำเร็จ มันก็จะคืนค่าเออเรอร์ออกมาแทน เราลองมาดูตัวอย่างกัน:

```elixir
iex> x = 1
1
```

คราวนี้ลองทำการจับคู่ดู

```elixir
iex> 1 = x
1
iex> 2 = x
** (MatchError) no match of right hand side value: 1
```

ลองจับคู่กับ Collections ที่เราเพิ่งเรียนมา

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

## Pin Operator

เครื่องหมายการจับคู่ (match operator) ใช้สำหรับการกำหนดค่าให้กับฝั่งซ้ายรวมถึงตัวแปรด้วย ในบางสถานการณ์เราอาจจะไม่ต้องการให้ตัวแปรนี้ถูกกำหนดค่าใหม่ ซึ่งสามารถทำได้ด้วย Pin operator `^`

เมื่อเรา pin ตัวแปรนั่นแปลว่าเราทำให้ตัวแปรนั้นมีค่าเป็นค่าเดิมที่มันมีอยู่แล้ว แทนที่จะผูกค่าใหม่ มาดูตัวอย่างกันดีกว่า

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
