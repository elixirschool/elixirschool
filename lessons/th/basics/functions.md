---
version: 1.0.0
title: ฟังก์ชัน(Functions)
---

ใน Elixir และ functional language ตัวอื่นๆ ฟังก์ชันมีความสำคัญอันดับแรกๆ ในบทเรียนนี้จะเรียนรู้เกี่ยวกับประเภทของฟังก์ชั่นใน Elixir ว่าแตกต่างกันอย่างไร?และวิธีการใช้


{% include toc.html %}

## ฟังก์ชันไม่ระบุตัวตน (Anonymous Function)

เช่นเดียวกับชื่อของมัน Anonymous Function ไม่มีชื่อ ดังนั้นเราเห็นในบทเรียน `Enum` เหล่านี้มักจะถูกส่งผ่านไปยังฟังก์ชันอื่น ๆ  ในการกำหนด Anonymous Function ใน Elixir เราต้องใช้ `fn` และ` end`เป็นคำหลัก ภายในเหล่านี้เราสามารถกำหนดจำนวน parameter และฟังก์ชันแยกออกจากกันด้วย `->`

ลองดูตัวอย่างเบื้องต้น:

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### การเขียนย่อด้วยสัญลักษณ์ &

การใช้ Anonymous Functions ใน Elixir สามารถเขียนเพื่อย่อ ได้ตามตัวอย่าง :

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

เราอาจคาดเดาได้แล้ว ในรูปแบบนี้ เราสามารถสร้าง parameter ของตัวเองได้เช่น "& 1", "& 2", "& 3" เป็นต้น

## การจับคู่รูปแบบ (Pattern Matching)

Pattern matching ไม่จำกัดเฉพาะตัวแปรใน Elixir มันสามารถใช้กับลายเซ็นต์ฟังก์ชันที่เราจะเห็นในส่วนนี้

Elixir ใช้ pattern matching เพื่อระบุชุดแรกของ parameter ที่ตรงกับและเรียกใช้ตัวที่เกี่ยวข้อง:

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
1
iex> handle_result.({:ok, some_result})
Handling result...
:ok
iex> handle_result.({:error})
An error has occurred!
```

## ฟังก์ชันที่มีชื่อ (Named Function)

เราสามารถกำหนดฟังก์ชันที่มีชื่อเพื่อให้เราสามารถอ้างอิงได้ในภายหลัง Named Function จะถูกกำหนดไว้ภายในโมดูลโดยใช้คำสั่ง`def` เราจะเรียนรู้เพิ่มเติมเกี่ยวกับ Modules ในบทเรียนต่อไป เพราะตอนนี้เรามุ่งเน้นไปที่ Named Function เท่านั้น

ฟังก์ชั่นที่กำหนดไว้ภายในโมดูลมีให้ใช้กับโมดูลอื่น ๆ สำหรับการใช้งาน  โดยเป็นประโยชน์โดยเฉพาะการสร้าง block ใน Elixir:

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```
 ถ้าฟังก์ชันทั้งหมดครอบคลุมในบรรทัดเดียว เราสามารถย่อลงได้อีกด้วยคำสั้ง`do:`:

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

คุณมีความรู้เกี่ยวกับ pattern matching อย่างคราวๆ แล้ว ลองใช้การเรียกซ้ำของ named function:

```elixir
defmodule Length do
  def of([]), do: 0
  def of([_ | tail]), do: 1 + of(tail)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### การตั้งชื่อฟังก์ชันและ Arity

เราได้กล่าวไว้ก่อนหน้านี้ว่าฟังก์ชันจะถูกตั้งชื่อโดยการรวมกันของชื่อและ arity (จำนวน argument) ซึ่งหมายความว่าคุณสามารถทำสิ่งต่างๆเช่นนี้:

```elixir
defmodule Greeter2 do
  def hello(), do: "Hello, anonymous person!"   # hello/0
  def hello(name), do: "Hello, " <> name        # hello/1
  def hello(name1, name2), do: "Hello, #{name1} and #{name2}"
                                                # hello/2
end

iex> Greeter2.hello()
"Hello, anonymous person!"
iex> Greeter2.hello("Fred")
"Hello, Fred"
iex> Greeter2.hello("Fred", "Jane")
"Hello, Fred and Jane"
```

เราระบุ function names ไว้บน comment แล้ว ครั้งแรกมีการดำเนินการโดยไม่มี argument หรือที่รู้กันคือ`hello/0`;ครั้งที่สองมีการดำเนินการโดยใส่ 1 argument โดยรู้กันคือ `hello/1`และซึ่่งๆแตกต่างจากฟังก์ชันทำให้เกิด overloads ในภาษาอื่นบางภาษา เหล่านี้เป็นความคิดของ _different_ functions จากแต่ละอื่น ๆ (Pattern matching, อธิบายเพียงไม่กี่นาทีที่ผ่านมา, ใช้เฉพาะเมื่อมีคำจำกัดความหลายคำสำหรับนิยามฟังก์ชันด้วยจำนวน _same_ ของอาร์กิวเมนต์)

### ฟังก์ชันเฉพาะตัว (Private Function)

เมื่อเราไม่ต้องการให้โมดูลอื่น ๆ เข้าถึงฟังก์ชันที่เฉพาะเจาะจง เราสามารถทำ Private Functions ได้  Private function สามารถเรียกได้จากภายในโมดูลเท่านั้น เรากำหนดมันใน Elixir ด้วยคำสั้ง `defp`:

```elixir
defmodule Greeter do
  def hello(name), do: phrase <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### Guard

เราเรียนอย่างสั้นเรื่อง guards ในบทเรียน [Control Structures](../control-structures), ตอนนี้เราจะดูว่าเราสามารถนำไปใช้กับ named function ได้อย่างไร เมื่อ Elixir ได้จับคู่กับฟังก์ชั่นใด ๆ แล้ว Guard ที่มีอยู่จะได้รับการทดสอบ.

ในตัวอย่างต่อไปนี้เรามีสองฟังก์ชันที่มีลายเซ็นเดียวกันเราต้องพึ่งพา Guards เพื่อระบุว่าจะใช้ชนิดของ argument ตามที่ได้:

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase() <> name
  end

  defp phrase, do: "Hello, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"
```

### Default Argument

ถ้าเราต้องการค่า Default สำหรับ argument เราใช้ `argument \\ value` syntax:

```elixir
defmodule Greeter do
  def hello(name, language_code \\ "en") do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello("Sean", "en")
"Hello, Sean"

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.hello("Sean", "es")
"Hola, Sean"
```

เมื่อเรารวมตัวอย่าง Guards ของเรากับ argument เริ่มต้นเราจะเจอปัญหา ลองดูสิ่งที่อาจมีลักษณะดังนี้:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code \\ "en") when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) iex:31: definitions with multiple clauses and default values require a header. Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b) do ... end

เขียนได้อีกแบบ:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end

def hello/2 has multiple clauses and defines defaults in one or more clauses
    iex:31: (module)
```

Elixir ไม่สามารถ argument เริ่มต้นในฟังก์ชั่นการจับคู่หลายอันอาจทำให้เกิดความสับสน ในการจัดการนี้เราเพิ่มหัวฟังก์ชันด้วย argument เริ่มต้นของเรา:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en")
  def hello(names, language_code) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code) when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "es"
"Hola, Sean, Steve"
```
