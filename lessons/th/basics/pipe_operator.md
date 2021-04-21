%{
  version: "1.0.1",
  title: "Pipe Operator",
  excerpt: """
  pipe operator `|>` นั้นใช้สำหรับส่งผลลัพธ์ของ expression ไปเป็น argument ตัวแรกของ expression ถัดไป
  """
}
---

## บทนำ

การเรียก function ซ้อนกันเข้าไปหลายๆ ชั้น นั้นทำให้โปรแกรมเราดูรก และยากที่จะทำความเข้าใจ อย่างเช่นในตัวอย่างต่อไปนี้


```elixir
foo(bar(baz(new_function(other_function()))))
```

ตรงนี้ เราส่งผลลัพธ์ของ `other_function/0` ไป `new_function/1`, และ `new_function/1` ไป `baz/1`, `baz/1` ไป `bar/1`, และสุดท้าย ผลลัพธ์ของ `bar/1` ไป `foo/1`
เพื่อช่วยให้เราจัดการกับความยุ่งเหยิงของ syntax ดังกล่าว Elixir จึงมอบ pipe operator ให้กับเรา ซึ่งมีหน้าหน้าตาแบบนี้ `|>` โดยมันจะ *รับผลลัพธ์จาก expression หนึ่งๆ แล้วส่งมันต่อไป*
ลองมาดู code snippet ด้านบนที่นำมาเขียนใหม่โดยใช้ pipe operator กันดีกว่า

```elixir
other_function() |> new_function() |> baz() |> bar() |> foo()
```

เจ้า pipe นั้น รับผลลัพธ์จากด้านซ้าย แล้วส่งมันต่อไปทางด้านขวามือ

## ตัวอย่าง

สำหรับตัวอย่างชุดนี้ เราจะใช้ String module ของ Elixir

- Tokenize String (อย่างง่าย)

```elixir
iex> "Elixir rocks" |> String.split()
["Elixir", "rocks"]
```

- ทำให้เป็นอักษรใหญ่ทุกๆ token

```elixir
iex> "Elixir rocks" |> String.upcase() |> String.split()
["ELIXIR", "ROCKS"]
```

- ตรวจสอบว่าจบด้วยอะไร

```elixir
iex> "elixir" |> String.ends_with?("ixir")
true
```

## Best Practices

ถ้า arity ของ function นั้นมากกว่า 1 แล้ว เราควรจะใส่วงเล็บด้วย ถึงแม้ว่ามันจะไม่มีปัญหากับ Elixir เอง แต่ก็อาจจะมีปัญหากับ programmer คนอื่นๆ ที่อาจจะเข้าใจ code ของเราผิดๆ และมันก็มีปัญหากับ pipe operator ด้วย ตัวอย่างเช่น ถ้าเราเอาตัวอย่างที่สามของเรามา แล้วเอาวงเล็บออกจาก `String.ends_with?/2` แล้ว เราจะเจอคำเตือนดังนี้

```shell
iex> "elixir" |> String.ends_with? "ixir"
warning: parentheses are required when piping into a function call. For example:

  foo 1 |> bar 2 |> baz 3

is ambiguous and should be written as

  foo(1) |> bar(2) |> baz(3)

true
```
